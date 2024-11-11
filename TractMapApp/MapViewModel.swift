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
    @Published var visibleRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // Default location (San Francisco)
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    @Published var overlays: [MKPolygon] = []
    
    private var geoJSONOverlays: [MKPolygon] = []
    private var locationManager = CLLocationManager()
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    func loadGeoJSONOverlays() {
        guard let filePath = Bundle.main.url(forResource: "MLS Regional Neighborhoods", withExtension: "geojson") else {
            print("GeoJSON file not found.")
            return
        }

        do {
            let data = try Data(contentsOf: filePath)
            let features = try MKGeoJSONDecoder().decode(data)
            
            for feature in features {
                if let geoFeature = feature as? MKGeoJSONFeature {
                    for geometry in geoFeature.geometry {
                        if let polygonOverlay = geometry as? MKPolygon {
                            geoJSONOverlays.append(polygonOverlay)
                        }
                    }
                }
            }
        } catch {
            print("Failed to parse GeoJSON: \(error)")
        }
    }

    func updateVisibleContent(for region: MKCoordinateRegion) {
        let visibleMapRect = MKMapRect(region: region)
        
        let visibleOverlays = geoJSONOverlays.filter { $0.boundingMapRect.intersects(visibleMapRect) }

        DispatchQueue.main.async {
            self.overlays = visibleOverlays
        }
    }

    // CLLocationManagerDelegate methods
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async {
            self.visibleRegion.center = location.coordinate
        }
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
