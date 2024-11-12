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
    @Published var visibleRegion: MKCoordinateRegion? // Optional for delayed setting
    @Published var overlays: [MKPolygon] = [] // Updated incrementally

    private var geoJSONOverlays: [MKPolygon] = []
    private var locationManager = CLLocationManager()

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        loadGeoJSONOverlays()
    }

    func loadGeoJSONOverlays() {
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
                print("GeoJSON Overlays Loaded: \(self.geoJSONOverlays.count) polygons.")
            } catch {
                print("Failed to parse GeoJSON: \(error)")
            }
        }
    }

    private func processFeature(_ geoFeature: MKGeoJSONFeature) {
        var newPolygons: [MKPolygon] = []

        for geometry in geoFeature.geometry {
            if let polygon = geometry as? MKPolygon {
                configurePolygonTitle(polygon, propertiesData: geoFeature.properties)
                newPolygons.append(polygon)
            } else if let multiPolygon = geometry as? MKMultiPolygon {
                for polygon in multiPolygon.polygons {
                    configurePolygonTitle(polygon, propertiesData: geoFeature.properties)
                    newPolygons.append(polygon)
                }
            }
        }

        DispatchQueue.main.async {
            self.overlays.append(contentsOf: newPolygons)
            self.geoJSONOverlays.append(contentsOf: newPolygons)
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
            self.overlays = visibleOverlays
            print("Updated visible overlays: \(visibleOverlays.count)")
        }
    }

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

    // New Center Function to Focus on Selected Overlay
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

extension MKMapRect {
    init(region: MKCoordinateRegion) {
        let topLeft = CLLocationCoordinate2D(
            latitude: region.center.latitude + region.span.latitudeDelta / 2,
            longitude: region.center.longitude - region.span.longitudeDelta / 2
        )
        let bottomRight = CLLocationCoordinate2D(
            latitude: region.center.latitude - region.span.latitudeDelta / 2,
            longitude: region.center.longitude + region.span.longitudeDelta / 2
        )

        let topLeftPoint = MKMapPoint(topLeft)
        let bottomRightPoint = MKMapPoint(bottomRight)

        self = MKMapRect(
            origin: MKMapPoint(x: min(topLeftPoint.x, bottomRightPoint.x),
                               y: min(topLeftPoint.y, bottomRightPoint.y)),
            size: MKMapSize(width: abs(topLeftPoint.x - bottomRightPoint.x),
                            height: abs(topLeftPoint.y - bottomRightPoint.y))
        )
    }
}
