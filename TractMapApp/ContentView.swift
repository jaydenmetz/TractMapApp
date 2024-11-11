//
//  ContentView.swift
//  TractMapApp
//
//  Created by Jayden Metz on 10/31/24.
//

import SwiftUI
import MapKit

struct ContentView: View {
    @StateObject private var viewModel = MapViewModel() // Correctly initialize the view model

    var body: some View {
        ZStack {
            MapView(
                region: $viewModel.visibleRegion,
                overlays: viewModel.overlays,
                onRegionChange: { newRegion in
                    viewModel.updateVisibleContent(for: newRegion)
                }
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        viewModel.centerToCurrentLocation() // Snap to current location
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
            viewModel.loadGeoJSONOverlays() // Load overlays once on launch
        }
    }
}
