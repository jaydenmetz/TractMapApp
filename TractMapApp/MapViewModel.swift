import SwiftUI
import MapKit
import CoreLocation
import Combine

class MapViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var visibleRegion: MKCoordinateRegion?
    @Published var overlays: [MKPolygon] = []
    @Published var showAllOverlays = false
    @Published var currentLocation: CLLocationCoordinate2D?

    private var geoJSONOverlays: [MKPolygon] = []
    private var locationManager = LocationManager()
    private var isOverlaysLoaded = false
    private var hasSetInitialLocation = false
    private var cancellables = Set<AnyCancellable>()

    override init() {
        super.init()
        locationManager.$lastLocation
            .compactMap { $0 }
            .sink { [weak self] newLocation in
                self?.handleLocationUpdate(newLocation)
            }
            .store(in: &cancellables)
    }

    func loadGeoJSONOverlays() {
        guard !isOverlaysLoaded else { return }

        DispatchQueue.global(qos: .userInitiated).async {
            guard let filePath = Bundle.main.url(forResource: "Corrected_MLS_Regional_Neighborhoods_No_FillClr", withExtension: "geojson") else {
                print("GeoJSON file not found.")
                return
            }

            do {
                let data = try Data(contentsOf: filePath)
                let features = try MKGeoJSONDecoder().decode(data)
                for feature in features {
                    if let geoFeature = feature as? MKGeoJSONFeature {
                        self.processFeature(geoFeature)
                    }
                }

                DispatchQueue.main.async {
                    self.isOverlaysLoaded = true
                    self.updateFilteredOverlays()
                }
            } catch {
                print("Failed to parse GeoJSON: \(error.localizedDescription)")
            }
        }
    }

    private func processFeature(_ geoFeature: MKGeoJSONFeature) {
        guard let propertiesData = geoFeature.properties else { return }

        do {
            if let properties = try JSONSerialization.jsonObject(with: propertiesData, options: []) as? [String: Any] {
                for geometry in geoFeature.geometry {
                    if let polygon = geometry as? MKPolygon {
                        self.addPolygon(polygon, properties: properties)
                    } else if let multiPolygon = geometry as? MKMultiPolygon {
                        self.processMultiPolygon(multiPolygon, properties: properties)
                    } else {
                        print("[DEBUG - processFeature] Unsupported geometry type: \(type(of: geometry))")
                    }
                }
            }
        } catch {
            print("Error decoding properties: \(error.localizedDescription)")
        }
    }

    private func processMultiPolygon(_ multiPolygon: MKMultiPolygon, properties: [String: Any]) {
        for polygon in multiPolygon.polygons {
            self.addPolygon(polygon, properties: properties)
        }
    }

    private func addPolygon(_ polygon: MKPolygon, properties: [String: Any]) {
        polygon.title = properties["LblVal"] as? String

        if let fillRed = properties["FillClrR"] as? Double,
           let fillGreen = properties["FillClrG"] as? Double,
           let fillBlue = properties["FillClrB"] as? Double,
           let fillOpacity = properties["FillOp"] as? Double,
           let strokeOpacity = properties["StrkOp"] as? Double,
           let strokeWeight = properties["StrkWt"] as? Double {
            
            polygon.subtitle = """
            FillClrR:\(fillRed);FillClrG:\(fillGreen);FillClrB:\(fillBlue);FillOp:\(fillOpacity);StrkOp:\(strokeOpacity);StrkWt:\(strokeWeight)
            """
        }

        geoJSONOverlays.append(polygon)
        print("[DEBUG - addPolygon] Added polygon: \(polygon.title ?? "Unknown")")
    }

    func updateFilteredOverlays() {
        DispatchQueue.main.async {
            self.overlays = self.showAllOverlays ? self.geoJSONOverlays : []
            print("[DEBUG - updateFilteredOverlays] Current visible overlays count: \(self.overlays.count)")
        }
    }

    func toggleAllOverlays() {
        showAllOverlays.toggle()
        updateFilteredOverlays()
    }

    func centerToCurrentLocation() {
        locationManager.requestCurrentLocation()
    }

    private func updateVisibleRegion(with coordinate: CLLocationCoordinate2D) {
        DispatchQueue.main.async {
            self.visibleRegion = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
            print("[DEBUG - updateVisibleRegion] Updated region to: \(coordinate.latitude), \(coordinate.longitude)")
        }
    }

    func centerMap(on polygon: MKPolygon) {
        let rect = polygon.boundingMapRect
        DispatchQueue.main.async {
            let rawRegion = MKCoordinateRegion(rect)
            let clampedRegion = rawRegion.clampedToValidRange() // Validate and clamp

            self.visibleRegion = clampedRegion
            
            print("[DEBUG - centerMap] Clamped region: \(clampedRegion)")
        }
    }

    private func handleLocationUpdate(_ newLocation: CLLocationCoordinate2D) {
        currentLocation = newLocation
        if !hasSetInitialLocation {
            hasSetInitialLocation = true
            updateVisibleRegion(with: newLocation)
        }
        print("[DEBUG - handleLocationUpdate] Location updated to: \(newLocation.latitude), \(newLocation.longitude)")
    }
}
