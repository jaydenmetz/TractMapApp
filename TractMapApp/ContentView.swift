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
    @State private var region: MKCoordinateRegion?

    var body: some View {
        ZStack {
            if let region = region {
                MapView(region: Binding(get: { region }, set: { self.region = $0 }), overlays: [])
            } else {
                Text("Loading map...")
            }

            Button(action: {
                locationManager.requestCurrentLocation()
            }) {
                Image(systemName: "location.fill")
                    .padding()
                    .background(Color.white.opacity(0.8))
                    .clipShape(Circle())
                    .shadow(radius: 5)
            }
            .padding()
            .position(x: UIScreen.main.bounds.width - 50, y: UIScreen.main.bounds.height - 100)
        }
        .onReceive(locationManager.$lastLocation) { newLocation in
            if let currentLocation = newLocation {
                region = MKCoordinateRegion(
                    center: currentLocation,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
                print("Region centered to initial location.")
            }
        }
    }
}
