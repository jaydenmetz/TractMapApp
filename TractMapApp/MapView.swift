//
//  MapView.swift
//  TractMapApp
//
//  Created by Jayden Metz on 11/7/24.
//

import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    var overlays: [MKOverlay]
    var onRegionChange: (MKCoordinateRegion) -> Void
    @Binding var recenterTrigger: Bool // Change from Bool to Binding<Bool>

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.setRegion(region, animated: false)
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        if recenterTrigger { // Observe the binding for changes
            uiView.setRegion(region, animated: true)
            DispatchQueue.main.async {
                recenterTrigger = false // Reset the trigger
            }
        }
        
        let currentOverlays = uiView.overlays
        let overlaysToRemove = currentOverlays.filter { overlay in
            !overlays.contains { $0 === overlay }
        }
        let overlaysToAdd = overlays.filter { overlay in
            !currentOverlays.contains { $0 === overlay }
        }

        uiView.removeOverlays(overlaysToRemove)
        uiView.addOverlays(overlaysToAdd)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self, onRegionChange: onRegionChange)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        var onRegionChange: (MKCoordinateRegion) -> Void

        init(_ parent: MapView, onRegionChange: @escaping (MKCoordinateRegion) -> Void) {
            self.parent = parent
            self.onRegionChange = onRegionChange
        }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            onRegionChange(mapView.region)
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polygon = overlay as? MKPolygon {
                let renderer = MKPolygonRenderer(polygon: polygon)
                renderer.fillColor = UIColor.blue.withAlphaComponent(0.2)
                renderer.strokeColor = .blue
                renderer.lineWidth = 1
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}
