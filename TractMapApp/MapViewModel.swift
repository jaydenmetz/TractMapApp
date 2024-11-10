//
//  MapViewModel.swift
//  TractMapApp
//
//  Created by Jayden Metz on 11/7/24.
//

import MapKit
import SwiftUI

class MapViewModel: ObservableObject {
    @Published var visibleRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    @Published var overlays: [IdentifiableOverlayLabel] = []
    
    private var geoJSONOverlays: [MKPolygon] = []

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
            .map { MapOverlayView(overlay: someOverlay) }

        DispatchQueue.main.async {
            self.overlays = visibleOverlays
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

extension MKCoordinateRegion {
    func contains(coordinate: CLLocationCoordinate2D) -> Bool {
        let minLat = center.latitude - span.latitudeDelta / 2
        let maxLat = center.latitude + span.latitudeDelta / 2
        let minLng = center.longitude - span.longitudeDelta / 2
        let maxLng = center.longitude + span.longitudeDelta / 2

        return (minLat...maxLat).contains(coordinate.latitude) &&
               (minLng...maxLng).contains(coordinate.longitude)
    }
}
