//
//  ContentView.swift
//  TractMapApp
//
//  Created by Jayden Metz on 10/31/24.
//

import SwiftUI
import MapKit

import SwiftUI
import MapKit

struct ContentView: View {
    @ObservedObject var viewModel = MapViewModel()

    var body: some View {
        VStack {
            Map(coordinateRegion: $viewModel.region,
                interactionModes: .all,
                showsUserLocation: true,
                annotationItems: viewModel.annotations) { annotation in
                MapAnnotation(coordinate: annotation.coordinate) {
                    Text(annotation.title ?? "")
                        .font(.caption)
                        .foregroundColor(.black)
                        .padding(5)
                        .background(Color.white)
                        .clipShape(Capsule())
                }
            }
            .edgesIgnoringSafeArea(.all)
        }
    }
}

#Preview {
    ContentView()
}
