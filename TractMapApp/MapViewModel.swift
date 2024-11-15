import SwiftUI
import MapKit
import Combine

class MapViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var visibleRegion: MKCoordinateRegion?
    @Published var overlays: [MKPolygon] = []
    @Published var annotations: [MKPointAnnotation] = []
    @Published var showAllOverlays = false
    @Published var currentLocation: CLLocationCoordinate2D?

    private var geoJSONOverlays: [MKPolygon] = []
    private var geoJSONAnnotations: [MKPointAnnotation] = []
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
                print("Failed to load GeoJSON: \(error)")
            }
        }
    }

    private func processFeature(_ geoFeature: MKGeoJSONFeature) {
        guard let propertiesData = geoFeature.properties else { return }

        do {
            if let properties = try JSONSerialization.jsonObject(with: propertiesData, options: []) as? [String: Any] {
                
                if let lblVal = properties["LblVal"] as? String,
                   let lblLat = properties["LblLat"] as? Double,
                   let lblLng = properties["LblLng"] as? Double {
                    
                    let annotation = MKPointAnnotation()
                    annotation.coordinate = CLLocationCoordinate2D(latitude: lblLat, longitude: lblLng)
                    annotation.title = lblVal
                    geoJSONAnnotations.append(annotation)
                }

                for geometry in geoFeature.geometry {
                    if let polygon = geometry as? MKPolygon {
                        self.addPolygon(polygon, properties: properties)
                    } else if let multiPolygon = geometry as? MKMultiPolygon {
                        self.processMultiPolygon(multiPolygon, properties: properties)
                    }
                }
            }
        } catch {
            print("Failed to process GeoJSON feature: \(error)")
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
    }

    func updateFilteredOverlays() {
        DispatchQueue.main.async {
            if self.showAllOverlays {
                self.overlays = self.geoJSONOverlays

                self.annotations = self.geoJSONAnnotations.filter { annotation in
                    if let matchingOverlay = self.geoJSONOverlays.first(where: { $0.title == annotation.title }),
                       !matchingOverlay.annotationLoaded {
                        matchingOverlay.annotationLoaded = true
                        return true
                    }
                    return false
                }
            } else {
                self.overlays.removeAll()
                
                self.geoJSONOverlays.forEach { overlay in
                    overlay.annotationLoaded = false
                }
                
                self.annotations.removeAll()
            }
        }
    }

    func toggleAllOverlays() {
        showAllOverlays.toggle()
        updateFilteredOverlays()
    }

    func centerToCurrentLocation() {
        locationManager.requestCurrentLocation()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            guard let location = self.currentLocation else { return }
            self.visibleRegion = MKCoordinateRegion(
                center: location,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }
    }

    private func updateVisibleRegion(with coordinate: CLLocationCoordinate2D) {
        DispatchQueue.main.async {
            self.visibleRegion = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }
    }

    func centerMap(on polygon: MKPolygon, mapView: MKMapView) {
        let rect = polygon.boundingMapRect
        let padding: CGFloat = 10.0

        DispatchQueue.main.async {
            let paddedRect = mapView.mapRectThatFits(rect, edgePadding: UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding))
            let adjustedRegion = MKCoordinateRegion(paddedRect)
            var safeRegion = adjustedRegion
            safeRegion.span.latitudeDelta = abs(adjustedRegion.span.latitudeDelta)
            safeRegion.span.longitudeDelta = abs(adjustedRegion.span.longitudeDelta)
            self.visibleRegion = safeRegion
        }
    }

    private func handleLocationUpdate(_ newLocation: CLLocationCoordinate2D) {
        currentLocation = newLocation
        if !hasSetInitialLocation {
            hasSetInitialLocation = true
            updateVisibleRegion(with: newLocation)
        }
    }
}
