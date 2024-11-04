//
//  MapView.swift
//  TractMapApp
//
//  Created by Jayden Metz on 10/31/24.
//

import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    @Binding var overlays: [IdentifiableOverlay]
    var initialRegion: MKCoordinateRegion
    var onRegionChange: (MKCoordinateRegion) -> Void
    var onOverlayTapped: (IdentifiableOverlay) -> Void // Callback for overlay tap

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.setRegion(initialRegion, animated: true)
        
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleTap(_:)))
        mapView.addGestureRecognizer(tapGesture)
        
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations)

        mapView.addOverlays(overlays.map { $0.overlay })

        for overlay in overlays {
            let annotation = MKPointAnnotation()
            annotation.coordinate = overlay.centroid
            annotation.title = overlay.name
            mapView.addAnnotation(annotation)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self, onRegionChange: onRegionChange, onOverlayTapped: onOverlayTapped)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        var onRegionChange: (MKCoordinateRegion) -> Void
        var onOverlayTapped: (IdentifiableOverlay) -> Void

        init(_ parent: MapView, onRegionChange: @escaping (MKCoordinateRegion) -> Void, onOverlayTapped: @escaping (IdentifiableOverlay) -> Void) {
            self.parent = parent
            self.onRegionChange = onRegionChange
            self.onOverlayTapped = onOverlayTapped
        }

        @objc func handleTap(_ gestureRecognizer: UITapGestureRecognizer) {
            let mapView = gestureRecognizer.view as! MKMapView
            let tapPoint = gestureRecognizer.location(in: mapView)
            let coordinate = mapView.convert(tapPoint, toCoordinateFrom: mapView)

            for overlay in mapView.overlays {
                if let polygonRenderer = mapView.renderer(for: overlay) as? MKPolygonRenderer,
                   polygonRenderer.path.contains(CGPoint(x: tapPoint.x, y: tapPoint.y)) {
                    if let identifiableOverlay = parent.overlays.first(where: {
                        if let polygon = $0.overlay as? MKPolygon {
                            return polygon.boundingMapRect.origin.x == overlay.boundingMapRect.origin.x &&
                                   polygon.boundingMapRect.origin.y == overlay.boundingMapRect.origin.y &&
                                   polygon.boundingMapRect.size.width == overlay.boundingMapRect.size.width &&
                                   polygon.boundingMapRect.size.height == overlay.boundingMapRect.size.height
                        }
                        return false
                    }) {
                        onOverlayTapped(identifiableOverlay) // Trigger the callback with the overlay details
                    }
                    break
                }
            }
        }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            onRegionChange(mapView.region)
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polygon = overlay as? MKPolygon {
                let renderer = MKPolygonRenderer(polygon: polygon)
                renderer.strokeColor = .blue
                renderer.lineWidth = 2
                renderer.fillColor = UIColor.blue.withAlphaComponent(0.2)
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            let identifier = "CustomAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)

            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = false

                let label = UILabel()
                label.text = annotation.title ?? ""
                label.backgroundColor = UIColor.white.withAlphaComponent(0.7)
                label.textColor = UIColor.black
                label.textAlignment = .center
                label.font = UIFont.systemFont(ofSize: 12)
                label.sizeToFit()

                annotationView?.addSubview(label)
                label.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    label.centerXAnchor.constraint(equalTo: annotationView!.centerXAnchor),
                    label.centerYAnchor.constraint(equalTo: annotationView!.centerYAnchor)
                ])
            } else {
                annotationView?.annotation = annotation
            }

            return annotationView
        }
    }
}
