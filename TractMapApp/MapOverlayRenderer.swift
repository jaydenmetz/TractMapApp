//
//  MapOverlayRenderer.swift
//  TractMapApp
//
//  Created by Jayden Metz on 11/8/24.
//

import SwiftUI
import MapKit

struct MapOverlay: View {
    @Binding var region: MKCoordinateRegion
    var overlays: [MKOverlay]
    var annotations: [OverlayLabel] // For labels on overlays
    
    var body: some View {
        Map(coordinateRegion: $region, interactionModes: .all, showsUserLocation: true, annotationItems: annotations) { annotation in
            MapAnnotation(coordinate: annotation.coordinate) {
                Text(annotation.text)
                    .font(.caption)
                    .foregroundColor(.black)
                    .padding(4)
                    .background(Color.white.opacity(0.7))
                    .cornerRadius(5)
            }
        }
        .overlay( // Add overlay separately
            MapOverlayView(overlays: overlays)
        )
    }
}

struct MapOverlayView: UIViewRepresentable {
    var overlays: [MKOverlay]
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.removeOverlays(mapView.overlays)
        mapView.addOverlays(overlays)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polygon = overlay as? MKPolygon {
                let renderer = MKPolygonRenderer(polygon: polygon)
                renderer.fillColor = UIColor.blue.withAlphaComponent(0.2)
                renderer.strokeColor = .blue
                renderer.lineWidth = 1.0
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}

struct OverlayLabel: Identifiable {
    let id = UUID()
    var coordinate: CLLocationCoordinate2D
    var text: String
}
