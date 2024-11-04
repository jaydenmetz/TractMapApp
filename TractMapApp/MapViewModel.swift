//
//  MapViewModel.swift
//  TractMapApp
//
//  Created by Jayden Metz on 10/31/24.
//

import Foundation
import MapKit
import CoreLocation

class MapViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    @Published var overlays: [IdentifiableOverlay] = []

    private var locationManager = CLLocationManager()

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }

    func checkLocationAuthorization() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        region.center = location.coordinate
    }

    func addOverlay(_ overlay: MKOverlay, name: String) {
        let centroid = calculateCentroid(for: overlay)
        let identifiableOverlay = IdentifiableOverlay(overlay: overlay, name: name, centroid: centroid)
        overlays.append(identifiableOverlay)
    }

    private func calculateCentroid(for overlay: MKOverlay) -> CLLocationCoordinate2D {
        if let polygon = overlay as? MKPolygon {
            let coordinates = polygon.points()
            let count = polygon.pointCount
            var latitudeSum: CLLocationDegrees = 0
            var longitudeSum: CLLocationDegrees = 0
            
            for i in 0..<count {
                let coordinate = coordinates[i].coordinate
                latitudeSum += coordinate.latitude
                longitudeSum += coordinate.longitude
            }

            return CLLocationCoordinate2D(
                latitude: latitudeSum / Double(count),
                longitude: longitudeSum / Double(count)
            )
        }

        // Default to overlay's center coordinate if not a polygon
        return overlay.coordinate
    }
}
