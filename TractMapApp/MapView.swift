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
    var onUserInteraction: ((Bool) -> Void)? = nil // Callback for user interaction

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true // Show current location
        mapView.setRegion(region, animated: false)
        
        // Gesture Recognizers for detecting interaction
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleUserInteraction))
        panGesture.delegate = context.coordinator
        mapView.addGestureRecognizer(panGesture)

        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleUserInteraction))
        pinchGesture.delegate = context.coordinator
        mapView.addGestureRecognizer(pinchGesture)
        
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        if !context.coordinator.isUserInteracting {
            if !regionsAreEqual(uiView.region, region) {
                uiView.setRegion(region, animated: true)
            }
        }
        
        uiView.removeOverlays(uiView.overlays)
        uiView.addOverlays(overlays)
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    private func regionsAreEqual(_ lhs: MKCoordinateRegion, _ rhs: MKCoordinateRegion) -> Bool {
        lhs.center.latitude == rhs.center.latitude &&
        lhs.center.longitude == rhs.center.longitude &&
        lhs.span.latitudeDelta == rhs.span.latitudeDelta &&
        lhs.span.longitudeDelta == rhs.span.longitudeDelta
    }

    class Coordinator: NSObject, MKMapViewDelegate, UIGestureRecognizerDelegate {
        var parent: MapView
        var isUserInteracting = false

        init(_ parent: MapView) {
            self.parent = parent
        }

        @objc func handleUserInteraction(gestureRecognizer: UIGestureRecognizer) {
            if gestureRecognizer.state == .began || gestureRecognizer.state == .changed {
                isUserInteracting = true
                parent.onUserInteraction?(true)
            } else if gestureRecognizer.state == .ended {
                isUserInteracting = false
                parent.onUserInteraction?(false)
            }
        }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            guard !isUserInteracting else { return }  // Prevent recentering during user interaction
            DispatchQueue.main.async {
                self.parent.region = mapView.region
            }
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polygon = overlay as? MKPolygon {
                let renderer = MKPolygonRenderer(polygon: polygon)
                renderer.fillColor = UIColor.red.withAlphaComponent(0.5)
                renderer.strokeColor = .black
                renderer.lineWidth = 1
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}
