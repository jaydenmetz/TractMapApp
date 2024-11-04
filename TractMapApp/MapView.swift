//
//  MapView.swift
//  TractMapApp
//
//  Created by Jayden Metz on 10/31/24.
//

import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    @EnvironmentObject var viewModel: MapViewModel

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.setRegion(viewModel.region, animated: true)

        // Remove existing annotations and add centroids
        mapView.removeAnnotations(mapView.annotations)
        let centroidAnnotations = viewModel.overlays.map { overlay in
            let annotation = MKPointAnnotation()
            annotation.coordinate = overlay.centroid
            annotation.title = overlay.name
            return annotation
        }
        mapView.addAnnotations(centroidAnnotations)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView

        init(_ parent: MapView) {
            self.parent = parent
        }

        // Implement additional MKMapViewDelegate methods if needed
    }
}
