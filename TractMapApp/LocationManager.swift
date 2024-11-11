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
    @Published var lastLocation: CLLocationCoordinate2D? // Updated location

    private var hasSetInitialLocation = false // Flag to check if the initial location is set

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    func requestCurrentLocation() {
        hasSetInitialLocation = false // Allow manual reset of current location if requested
        locationManager.startUpdatingLocation()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }

        if !hasSetInitialLocation {
            lastLocation = newLocation.coordinate
            print("Initial location set to: \(newLocation.coordinate.latitude), \(newLocation.coordinate.longitude)")

            // Stop updating location after getting the initial location
            hasSetInitialLocation = true
            locationManager.stopUpdatingLocation()
        } else {
            print("Location updated: \(newLocation.coordinate.latitude), \(newLocation.coordinate.longitude)")
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user's location: \(error.localizedDescription)")
    }
}
