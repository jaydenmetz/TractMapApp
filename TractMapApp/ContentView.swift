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
                        viewModel.centerMap(on: polygon)
                        recenterTrigger.toggle() // Trigger map region update
                    }
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
