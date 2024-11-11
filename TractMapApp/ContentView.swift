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
                    region: .constant(region),
                    overlays: viewModel.overlays,
                    onRegionChange: { newRegion in
                        viewModel.updateVisibleContent(for: newRegion)
                    },
                    recenterTrigger: $recenterTrigger
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
                        recenterTrigger.toggle()
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
