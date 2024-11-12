//
//  ContentView.swift
//  TractMapApp
//
//  Created by Jayden Metz on 10/31/24.
//

import SwiftUI
import MapKit

struct ContentView: View {
    @StateObject private var viewModel = MapViewModel()
    @State private var recenterTrigger = false
    @State private var selectedPolygon: MKPolygon? // Added to track the selected polygon

    var body: some View {
        ZStack {
            if let region = viewModel.visibleRegion {
                MapView(
                    region: Binding(
                        get: { viewModel.visibleRegion ?? MKCoordinateRegion() },
                        set: { viewModel.visibleRegion = $0 }
                    ),
                    overlays: viewModel.overlays,
                    recenterTrigger: $recenterTrigger,
                    onOverlayTapped: { polygon in
                        selectedPolygon = polygon // Update the selected polygon
                        viewModel.centerMap(on: polygon)
                        recenterTrigger.toggle() // Trigger map region update
                    },
                    selectedPolygon: $selectedPolygon // Pass selected polygon binding
                )
                .edgesIgnoringSafeArea(.all)
            } else {
                Text("Loading map...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        viewModel.centerToCurrentLocation()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { // Prevent immediate reset
                            recenterTrigger.toggle()
                        }
                    }) {
                        Image(systemName: "location.fill")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            viewModel.loadGeoJSONOverlays()
        }
    }
}
