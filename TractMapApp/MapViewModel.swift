//
//  MapViewModel.swift
//  TractMapApp
//
//  Created by Jayden Metz on 11/7/24.
//

import SwiftUI
import MapKit
import CoreLocation

class MapViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var visibleRegion: MKCoordinateRegion?
    @Published var overlays: [MKPolygon] = [] // Displayed overlays
    @Published var showAllOverlays = false // Toggle for all overlays
    @Published var currentLocation: CLLocationCoordinate2D? // Current location coordinate

    private var geoJSONOverlays: [MKPolygon] = [] // Store all GeoJSON overlays
    private var locationManager = CLLocationManager()
    private var isOverlaysLoaded = false // Prevent loading multiple times
    private var hasSetInitialLocation = false // Track whether initial location has been set

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    func loadGeoJSONOverlays() {
        guard !isOverlaysLoaded else {
            print("Overlays already loaded.")
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            guard let filePath = Bundle.main.url(forResource: "MLS Regional Neighborhoods", withExtension: "geojson") else {
                print("GeoJSON file not found.")
                return
            }

            do {
                let data = try Data(contentsOf: filePath)
                print("GeoJSON file loaded successfully: \(filePath)")

                let features = try MKGeoJSONDecoder().decode(data)
                for feature in features {
                    if let geoFeature = feature as? MKGeoJSONFeature {
                        self.processFeature(geoFeature)
                    }
                }

                DispatchQueue.main.async {
                    print("GeoJSON Overlays Loaded: \(self.geoJSONOverlays.count) polygons.")
                    self.isOverlaysLoaded = true
                    self.updateFilteredOverlays()
                }
            } catch {
                print("Failed to parse GeoJSON at \(filePath): \(error.localizedDescription)")
            }
        }
    }

    private func processFeature(_ geoFeature: MKGeoJSONFeature) {
        guard let propertiesData = geoFeature.properties else {
            print("No properties found for feature.")
            return
        }

        do {
            if let properties = try JSONSerialization.jsonObject(with: propertiesData, options: []) as? [String: Any] {
                for geometry in geoFeature.geometry {
                    if let polygon = geometry as? MKPolygon {
                        polygon.title = properties["LblVal"] as? String
                        self.geoJSONOverlays.append(polygon)
                        print("Polygon added: \(polygon.title ?? "Unknown")")
                    } else if let multiPolygon = geometry as? MKMultiPolygon {
                        self.processMultiPolygon(multiPolygon, properties: properties)
                    } else {
                        print("Unsupported geometry type: \(type(of: geometry))")
                    }
                }
            } else {
                print("Failed to decode properties as dictionary.")
            }
        } catch {
            print("Error decoding properties: \(error.localizedDescription)")
        }
    }

    private func processMultiPolygon(_ multiPolygon: MKMultiPolygon, properties: [String: Any]) {
        for polygon in multiPolygon.polygons {
            polygon.title = properties["LblVal"] as? String
            self.geoJSONOverlays.append(polygon)
            print("Polygon from MultiPolygon added: \(polygon.title ?? "Unknown")")
        }
    }

    func updateFilteredOverlays() {
        DispatchQueue.main.async {
            if self.showAllOverlays {
                self.overlays = self.geoJSONOverlays
                print("Displaying all overlays: \(self.overlays.count) polygons.")
            } else {
                self.overlays.removeAll()
                print("Hiding all overlays.")
            }
        }
    }

    func toggleAllOverlays() {
        showAllOverlays.toggle()
        updateFilteredOverlays()
    }

    func centerToCurrentLocation() {
        guard let currentLocation = locationManager.location else {
            print("Current location unavailable.")
            return
        }
        updateVisibleRegion(with: currentLocation.coordinate)
    }

    private func updateVisibleRegion(with coordinate: CLLocationCoordinate2D) {
        DispatchQueue.main.async {
            self.visibleRegion = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
            print("Updated visible region to: \(coordinate.latitude), \(coordinate.longitude)")
        }
    }

    func centerMap(on polygon: MKPolygon) {
        let boundingMapRect = polygon.boundingMapRect
        let edgePadding = UIEdgeInsets(top: 25, left: 25, bottom: 25, right: 25)

        DispatchQueue.main.async {
            let mapView = MKMapView()
            let fittedRegion = mapView.mapRectThatFits(boundingMapRect, edgePadding: edgePadding)
            self.visibleRegion = MKCoordinateRegion(fittedRegion)
            print("Centered to overlay: \(polygon.title ?? "Unknown")")
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        // Update current location
        self.currentLocation = location.coordinate

        // Set initial visible region on the first location update
        if !hasSetInitialLocation {
            hasSetInitialLocation = true
            updateVisibleRegion(with: location.coordinate)
        }
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            print("Location access denied or restricted.")
        default:
            break
        }
    }
}
