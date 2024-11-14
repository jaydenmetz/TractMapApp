import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    var overlays: [MKOverlay]
    var annotations: [MKPointAnnotation]
    @Binding var recenterTrigger: Bool
    var onOverlayTapped: (MKPolygon, MKMapView) -> Void
    @Binding var selectedPolygon: MKPolygon?

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.setRegion(region, animated: false)

        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleTap(_:)))
        mapView.addGestureRecognizer(tapGesture)

        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        DispatchQueue.main.async {
            if recenterTrigger {
                print("[DEBUG - updateUIView] Recenter triggered with region: \(region)")
                uiView.setRegion(region, animated: true)
                recenterTrigger = false
            }

            // Remove only non-user annotations and re-add necessary ones
            let nonUserAnnotations = uiView.annotations.filter { !($0 is MKUserLocation) }
            if nonUserAnnotations.count != annotations.count || !nonUserAnnotations.elementsEqual(annotations, by: { $0.coordinate.isEqual(to: $1.coordinate) && $0.title == $1.title }) {
                uiView.removeAnnotations(nonUserAnnotations)
                uiView.addAnnotations(annotations)
                print("[DEBUG - updateUIView] Updated annotations. Non-user removed: \(nonUserAnnotations.count), added: \(annotations.count)")
            }

            // Overlay logic
            let currentOverlaysSet = Set(uiView.overlays.map { ObjectIdentifier($0) })
            let newOverlaysSet = Set(overlays.map { ObjectIdentifier($0) })

            let overlaysToRemove = uiView.overlays.filter { !newOverlaysSet.contains(ObjectIdentifier($0)) }
            if !overlaysToRemove.isEmpty {
                uiView.removeOverlays(overlaysToRemove)
                print("[DEBUG - updateUIView] Removed overlays count: \(overlaysToRemove.count)")
            }

            let overlaysToAdd = overlays.filter { !currentOverlaysSet.contains(ObjectIdentifier($0)) }
            if !overlaysToAdd.isEmpty {
                uiView.addOverlays(overlaysToAdd)
                print("[DEBUG - updateUIView] Added overlays count: \(overlaysToAdd.count)")
            }

            // Log final counts
            print("[DEBUG - updateUIView] Final overlays count: \(uiView.overlays.count), annotations count: \(uiView.annotations.count)")
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self, onOverlayTapped: onOverlayTapped)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        var onOverlayTapped: (MKPolygon, MKMapView) -> Void

        init(_ parent: MapView, onOverlayTapped: @escaping (MKPolygon, MKMapView) -> Void) {
            self.parent = parent
            self.onOverlayTapped = onOverlayTapped
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polygon = overlay as? MKPolygon {
                let renderer = MKPolygonRenderer(polygon: polygon)

                guard let subtitle = polygon.subtitle else {
                    renderer.fillColor = UIColor.gray.withAlphaComponent(0.3)
                    renderer.strokeColor = .black
                    renderer.lineWidth = 1
                    return renderer
                }

                let properties = subtitle.split(separator: ";").reduce(into: [String: Double]()) { result, component in
                    let keyValue = component.split(separator: ":")
                    if keyValue.count == 2, let key = keyValue.first, let value = Double(keyValue.last!) {
                        result[String(key)] = value
                    }
                }

                renderer.fillColor = UIColor(
                    red: CGFloat(properties["FillClrR"] ?? 0.5),
                    green: CGFloat(properties["FillClrG"] ?? 0.5),
                    blue: CGFloat(properties["FillClrB"] ?? 0.5),
                    alpha: CGFloat(properties["FillOp"] ?? 0.3)
                )
                renderer.strokeColor = UIColor.black.withAlphaComponent(CGFloat(properties["StrkOp"] ?? 1))
                renderer.lineWidth = CGFloat(properties["StrkWt"] ?? 1)

                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }

        @objc func handleTap(_ gestureRecognizer: UITapGestureRecognizer) {
            guard let mapView = gestureRecognizer.view as? MKMapView else { return }
            let tapPoint = gestureRecognizer.location(in: mapView)
            let tapCoordinate = mapView.convert(tapPoint, toCoordinateFrom: mapView)

            for overlay in mapView.overlays {
                if let polygon = overlay as? MKPolygon,
                   let renderer = mapView.renderer(for: polygon) as? MKPolygonRenderer,
                   renderer.path?.contains(renderer.point(for: MKMapPoint(tapCoordinate))) == true {
                    print("[DEBUG] Polygon tapped: \(polygon.title ?? "Unknown")")
                    onOverlayTapped(polygon, mapView)
                    return
                }
            }
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard annotation !== mapView.userLocation else { return nil }

            let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "LabelAnnotation") ?? MKAnnotationView(annotation: annotation, reuseIdentifier: "LabelAnnotation")
            annotationView.annotation = annotation
            annotationView.canShowCallout = false

            // Remove any existing subviews to prevent duplication
            annotationView.subviews.forEach { $0.removeFromSuperview() }

            let label = UILabel()
            label.text = annotation.title ?? ""
            label.textColor = .black
            label.font = UIFont.boldSystemFont(ofSize: 12)
            label.sizeToFit()
            annotationView.addSubview(label)
            label.center = CGPoint(x: annotationView.bounds.midX, y: -label.bounds.height / 2)
            print("[DEBUG - Annotation View] Added label '\(label.text ?? "Unknown")' at center: \(label.center)")

            return annotationView
        }
    }
}
