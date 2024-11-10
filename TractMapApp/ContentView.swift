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
    
    var body: some View {
        MapView(region: $viewModel.visibleRegion, overlays: viewModel.overlays)
            .onAppear {
                viewModel.loadGeoJSONOverlays()
            }
    }
}

#Preview {
    ContentView()
}
