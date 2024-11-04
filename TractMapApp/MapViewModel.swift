//
//  MapViewModel.swift
//  TractMapApp
//
//  Created by Jayden Metz on 10/31/24.
//

import MapKit
import SwiftUI
import CoreLocation

class MapViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.41546, longitude: -119.10914),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @Published var overlays: [IdentifiableOverlay] = []

    private let locationManager = CLLocationManager()
    private var allOverlays: [IdentifiableOverlay] = []
    private var lastLoadedRegion: MKCoordinateRegion?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    func loadGeoJSON() {
        guard let url = Bundle.main.url(forResource: "Tract_Maps_6055401279109136306", withExtension: "geojson") else {
            print("GeoJSON file not found")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let features = try MKGeoJSONDecoder().decode(data).compactMap { $0 as? MKGeoJSONFeature }
            
            for feature in features {
                if let polygon = feature.geometry.first as? MKPolygon {
                    if let properties = feature.properties,
                       let tractData = try? JSONSerialization.jsonObject(with: properties, options: []) as? [String: Any],
                       let tractName = tractData["TRACT_NAME"] as? String {
                        let centroid = calculateCentroid(of: polygon)
                        let overlay = IdentifiableOverlay(overlay: polygon, name: tractName, centroid: centroid)
                        allOverlays.append(overlay)
                    }
                }
            }
            
            loadVisibleOverlays(for: region)
        } catch {
            print("Error loading or decoding GeoJSON:", error)
        }
    }

    func loadVisibleOverlaysIfNeeded(for region: MKCoordinateRegion) {
        guard let lastRegion = lastLoadedRegion else {
            loadVisibleOverlays(for: region)
            lastLoadedRegion = region
            return
        }
        
        let thresholdDistance = 0.05

        if regionHasChangedSignificantly(from: lastRegion, to: region, threshold: thresholdDistance) {
            loadVisibleOverlays(for: region)
            lastLoadedRegion = region
        }
    }

    private func regionHasChangedSignificantly(from oldRegion: MKCoordinateRegion, to newRegion: MKCoordinateRegion, threshold: CLLocationDegrees) -> Bool {
        let deltaLatitude = abs(oldRegion.center.latitude - newRegion.center.latitude)
        let deltaLongitude = abs(oldRegion.center.longitude - newRegion.center.longitude)
        return deltaLatitude > threshold || deltaLongitude > threshold
    }

    private func loadVisibleOverlays(for region: MKCoordinateRegion) {
        let visibleMapRect = mapRect(for: region)
        
        overlays = allOverlays.filter { overlay in
            if let polygon = overlay.overlay as? MKPolygon {
                return visibleMapRect.intersects(polygon.boundingMapRect)
            }
            return false
        }
    }

    private func calculateCentroid(of polygon: MKPolygon) -> CLLocationCoordinate2D {
        var xSum: Double = 0
        var ySum: Double = 0
        var area: Double = 0

        let points = polygon.points()
        let pointCount = polygon.pointCount

        for i in 0..<pointCount {
            let point1 = points[i]
            let point2 = points[(i + 1) % pointCount]

            let latitude1 = point1.coordinate.latitude
            let longitude1 = point1.coordinate.longitude
            let latitude2 = point2.coordinate.latitude
            let longitude2 = point2.coordinate.longitude

            let a = latitude1 * longitude2 - latitude2 * longitude1
            xSum += (latitude1 + latitude2) * a
            ySum += (longitude1 + longitude2) * a
            area += a
        }

        area *= 0.5
        let centroidLatitude = xSum / (6 * area)
        let centroidLongitude = ySum / (6 * area)

        return CLLocationCoordinate2D(latitude: centroidLatitude, longitude: centroidLongitude)
    }

    private func mapRect(for region: MKCoordinateRegion) -> MKMapRect {
        let topLeft = MKMapPoint(CLLocationCoordinate2D(
            latitude: region.center.latitude + region.span.latitudeDelta / 2,
            longitude: region.center.longitude - region.span.longitudeDelta / 2))
        
        let bottomRight = MKMapPoint(CLLocationCoordinate2D(
            latitude: region.center.latitude - region.span.latitudeDelta / 2,
            longitude: region.center.longitude + region.span.longitudeDelta / 2))
        
        return MKMapRect(
            origin: MKMapPoint(x: min(topLeft.x, bottomRight.x), y: min(topLeft.y, bottomRight.y)),
            size: MKMapSize(width: abs(topLeft.x - bottomRight.x), height: abs(topLeft.y - bottomRight.y))
        )
    }
}

// Extension to add `contains` method to MKCoordinateRegion
extension MKCoordinateRegion {
    func contains(region: MKCoordinateRegion) -> Bool {
        let maxLatitude = center.latitude + span.latitudeDelta / 2
        let minLatitude = center.latitude - span.latitudeDelta / 2
        let maxLongitude = center.longitude + span.longitudeDelta / 2
        let minLongitude = center.longitude - span.longitudeDelta / 2

        let regionMaxLatitude = region.center.latitude + region.span.latitudeDelta / 2
        let regionMinLatitude = region.center.latitude - region.span.latitudeDelta / 2
        let regionMaxLongitude = region.center.longitude + region.span.longitudeDelta / 2
        let regionMinLongitude = region.center.longitude - region.span.longitudeDelta / 2

        return regionMinLatitude >= minLatitude && regionMaxLatitude <= maxLatitude &&
               regionMinLongitude >= minLongitude && regionMaxLongitude <= maxLongitude
    }
}
