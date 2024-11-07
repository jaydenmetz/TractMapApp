//
//  ContentView.swift
//  TractMapApp
//
//  Created by Jayden Metz on 10/31/24.
//

import SwiftUI
import MapKit

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    
    // State for the map's camera position
    @State private var cameraPosition = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // Default to San Francisco
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )

    var body: some View {
        ZStack {
            Map(position: $cameraPosition) {
                // Use an Annotation for the user's current location
                if let location = locationManager.currentLocation {
                    Annotation("Current Location", coordinate: location.coordinate) {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 12, height: 12)
                    }
                }
            }
            .mapControls {
                MapUserLocationButton() // Add a button to recenter on the user's location
                MapCompass() // Add a compass control
            }
            .ignoresSafeArea()
            .onAppear {
                locationManager.requestLocation() // Request the user's location on appear
            }
            .onChange(of: locationManager.currentLocation) { newLocation in
                if let location = newLocation {
                    updateCameraPosition(location)
                }
            }

            // Show a message if location access is denied
            if locationManager.authorizationStatus == .denied || locationManager.authorizationStatus == .restricted {
                Text("Location access denied. Please enable it in Settings.")
                    .padding()
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(10)
                    .padding()
            }
        }
    }

    // Update the camera position to center on the user's location
    private func updateCameraPosition(_ location: CLLocation) {
        cameraPosition = .region(
            MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
