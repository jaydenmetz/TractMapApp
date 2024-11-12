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
    @Published var overlays: [MKPolygon] = []
    
    private var geoJSONOverlays: Set<MKPolygon> = [] // Use Set to avoid duplicates
    private var locationManager = CLLocationManager()
    private var isOverlaysLoaded = false // Ensure loading only once
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        loadGeoJSONOverlays()
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
                let features = try MKGeoJSONDecoder().decode(data)
                
                for feature in features {
                    if let geoFeature = feature as? MKGeoJSONFeature {
                        self.processFeature(geoFeature)
                    }
                }
                
                DispatchQueue.main.async {
                    print("GeoJSON Overlays Loaded: \(self.geoJSONOverlays.count) polygons.")
                    self.overlays = Array(self.geoJSONOverlays) // Sync overlays for map
                    self.isOverlaysLoaded = true
                }
            } catch {
                print("Failed to parse GeoJSON: \(error)")
            }
        }
    }
    
    private func processFeature(_ geoFeature: MKGeoJSONFeature) {
        for geometry in geoFeature.geometry {
            if let polygon = geometry as? MKPolygon {
                addUniqueOverlay(polygon, propertiesData: geoFeature.properties)
            } else if let multiPolygon = geometry as? MKMultiPolygon {
                for polygon in multiPolygon.polygons {
                    addUniqueOverlay(polygon, propertiesData: geoFeature.properties)
                }
            }
        }
    }
    
    private func addUniqueOverlay(_ polygon: MKPolygon, propertiesData: Data?) {
        configurePolygonTitle(polygon, propertiesData: propertiesData)
        
        if !geoJSONOverlays.contains(where: { $0.boundingMapRect == polygon.boundingMapRect }) {
            geoJSONOverlays.insert(polygon)
        }
    }
    
    private func configurePolygonTitle(_ polygon: MKPolygon, propertiesData: Data?) {
        if let propertiesData = propertiesData,
           let properties = try? JSONSerialization.jsonObject(with: propertiesData, options: []) as? [String: Any],
           let title = properties["LblVal"] as? String {
            polygon.title = title
        } else {
            polygon.title = "Unknown"
        }
        print("Polygon added with title: \(polygon.title ?? "nil")")
    }
    
    func updateVisibleContent(for region: MKCoordinateRegion) {
        let visibleMapRect = MKMapRect(region: region)
        let visibleOverlays = geoJSONOverlays.filter { $0.boundingMapRect.intersects(visibleMapRect) }
        
        DispatchQueue.main.async {
            self.overlays = Array(visibleOverlays)
            print("Updated visible overlays: \(visibleOverlays.count)")
        }
    }
    
    // Center Functions and Location Handling remain unchanged
    func centerToCurrentLocation() {
        if let currentLocation = locationManager.location {
            DispatchQueue.main.async {
                self.visibleRegion = MKCoordinateRegion(
                    center: currentLocation.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
                print("Centered to current location: \(currentLocation.coordinate.latitude), \(currentLocation.coordinate.longitude)")
            }
        } else {
            print("Current location unavailable.")
        }
    }

    func centerMap(on polygon: MKPolygon) {
        let boundingMapRect = polygon.boundingMapRect
        let edgePadding = UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50)
        
        DispatchQueue.main.async {
            let mapView = MKMapView()
            let region = mapView.mapRectThatFits(boundingMapRect, edgePadding: edgePadding)
            self.visibleRegion = MKCoordinateRegion(region)
            print("Centered to overlay: \(polygon.title ?? "Unknown")")
        }
    }

    // CLLocationManagerDelegate methods
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        if visibleRegion == nil { // Only set the initial location if visibleRegion is not set
            DispatchQueue.main.async {
                self.visibleRegion = MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
                print("Initial location set to: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user's location: \(error.localizedDescription)")
    }
}
