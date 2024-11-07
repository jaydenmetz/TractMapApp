//
//  MapView.swift
//  TractMapApp
//
//  Created by Jayden Metz on 10/31/24.
//

import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    @ObservedObject var viewModel: MapViewModel

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.region = viewModel.region
        mapView.showsUserLocation = true

        mapView.addAnnotations(viewModel.allAnnotations)
        viewModel.selectedOverlays.forEach { mapView.addOverlay($0.overlay) }
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.region = viewModel.region
        mapView.removeOverlays(mapView.overlays)
        viewModel.selectedOverlays.forEach { mapView.addOverlay($0.overlay) }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView

        init(_ parent: MapView) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            let renderer = MKPolygonRenderer(overlay: overlay)
            renderer.fillColor = .blue.withAlphaComponent(0.4)
            renderer.strokeColor = .blue
            renderer.lineWidth = 2
            return renderer
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "Annotation")
            annotationView.canShowCallout = true
            return annotationView
        }
    }
}
