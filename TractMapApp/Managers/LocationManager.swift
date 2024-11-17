//
//  LocationManager.swift
//  TractMapApp
//
//  Created by Jayden Metz on 11/10/24.
//

import Foundation
import CoreLocation

class LocationManager: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    @Published var lastLocation: CLLocationCoordinate2D? // Provide the latest location

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    func requestCurrentLocation() {
        locationManager.startUpdatingLocation()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        lastLocation = newLocation.coordinate
        print("Location updated: \(newLocation.coordinate.latitude), \(newLocation.coordinate.longitude)")
        
        // Stop updating if only one-shot request is needed
        locationManager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get location: \(error.localizedDescription)")
    }
}
