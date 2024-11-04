//
//  ContentView.swift
//  TractMapApp
//
//  Created by Jayden Metz on 10/31/24.
//

import SwiftUI
import MapKit

struct ContentView: View {
    @ObservedObject private var mapViewModel = MapViewModel()
    @State private var selectedOverlay: IdentifiableOverlay? = nil

    var body: some View {
        ZStack {
            MapView(
                overlays: $mapViewModel.overlays,
                initialRegion: mapViewModel.region,
                onRegionChange: { newRegion in
                    mapViewModel.loadVisibleOverlaysIfNeeded(for: newRegion)
                },
                onOverlayTapped: { overlay in
                    withAnimation {
                        selectedOverlay = overlay
                    }
                }
            )
            .onAppear {
                mapViewModel.loadGeoJSON()
            }
            
            if let overlay = selectedOverlay {
                OverlayDetailView(overlay: overlay) {
                    withAnimation {
                        selectedOverlay = nil // Dismiss the card when tapped
                    }
                }
                .transition(.move(edge: .bottom))
            }
        }
    }
}

#Preview {
    ContentView()
}
