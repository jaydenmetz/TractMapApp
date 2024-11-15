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

            let nonUserAnnotations = uiView.annotations.filter { !($0 is MKUserLocation) }
            if nonUserAnnotations.count != annotations.count || !nonUserAnnotations.elementsEqual(annotations, by: { $0.coordinate.isEqual(to: $1.coordinate) && $0.title == $1.title }) {
                uiView.removeAnnotations(nonUserAnnotations)
                uiView.addAnnotations(annotations)
                print("[DEBUG - updateUIView] Updated annotations. Non-user removed: \(nonUserAnnotations.count), added: \(annotations.count)")
            }

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

            print("[DEBUG - updateUIView] Final overlays count: \(uiView.overlays.count), annotations count: \(uiView.annotations.count)")

            context.coordinator.adjustAnnotationLabels(for: uiView)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self, onOverlayTapped: onOverlayTapped)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        var onOverlayTapped: (MKPolygon, MKMapView) -> Void
        private let minFontSize: CGFloat = 6
        private let maxFontSize: CGFloat = 30

        init(_ parent: MapView, onOverlayTapped: @escaping (MKPolygon, MKMapView) -> Void) {
            self.parent = parent
            self.onOverlayTapped = onOverlayTapped
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polygon = overlay as? MKPolygon {
                let renderer = MKPolygonRenderer(polygon: polygon)
                renderer.fillColor = UIColor.gray.withAlphaComponent(0.3)
                renderer.strokeColor = .black
                renderer.lineWidth = 1
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

        func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
            print("[DEBUG] Visible region changed. Adjusting labels...")
            adjustAnnotationLabels(for: mapView)
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard annotation !== mapView.userLocation else { return nil }

            let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "LabelAnnotation") ?? MKAnnotationView(annotation: annotation, reuseIdentifier: "LabelAnnotation")
            annotationView.annotation = annotation
            annotationView.canShowCallout = false

            annotationView.subviews.forEach { $0.removeFromSuperview() }

            let label = UILabel()
            label.text = annotation.title ?? ""
            label.textColor = .black
            label.sizeToFit()
            annotationView.addSubview(label)
            label.center = CGPoint(x: annotationView.bounds.midX, y: -label.bounds.height / 2)
            return annotationView
        }

        func adjustAnnotationLabels(for mapView: MKMapView) {
            for annotation in mapView.annotations {
                guard let annotationView = mapView.view(for: annotation) as? MKAnnotationView,
                      let label = annotationView.subviews.first as? UILabel else {
                    print("[DEBUG] Skipping annotation - annotation view or label missing for '\(annotation.title ?? "Unknown")'")
                    continue
                }
                
                // Find a matching overlay
                guard let overlay = parent.overlays.first(where: { ($0 as? MKPolygon)?.title == annotation.title }) as? MKPolygon else {
                    print("[DEBUG] Skipping annotation - no matching overlay for '\(annotation.title ?? "Unknown")'")
                    continue
                }

                let overlayBoundingMapRect = overlay.boundingMapRect
                
                // Convert to screen rect for accurate placement
                let topLeftMapPoint = MKMapPoint(x: overlayBoundingMapRect.minX, y: overlayBoundingMapRect.minY)
                let bottomRightMapPoint = MKMapPoint(x: overlayBoundingMapRect.maxX, y: overlayBoundingMapRect.maxY)

                let topLeftScreenPoint = mapView.convert(topLeftMapPoint.coordinate, toPointTo: mapView)
                let bottomRightScreenPoint = mapView.convert(bottomRightMapPoint.coordinate, toPointTo: mapView)

                let overlayBoundingRect = CGRect(
                    origin: topLeftScreenPoint,
                    size: CGSize(
                        width: abs(bottomRightScreenPoint.x - topLeftScreenPoint.x),
                        height: abs(bottomRightScreenPoint.y - topLeftScreenPoint.y)
                    )
                )

                let maxWidth = overlayBoundingRect.width * 0.9
                let maxHeight = overlayBoundingRect.height * 0.9

                print("[DEBUG] Max Width: \(maxWidth), Max Height: \(maxHeight) for '\(annotation.title ?? "Unknown")'")

                var fontSize = maxFontSize
                while fontSize > minFontSize {
                    let testLabel = UILabel()
                    testLabel.font = UIFont.boldSystemFont(ofSize: fontSize)
                    testLabel.text = label.text
                    testLabel.sizeToFit()

                    if testLabel.frame.width <= maxWidth && testLabel.frame.height <= maxHeight {
                        break
                    }
                    fontSize -= 1
                }

                print("[DEBUG] Font Size for '\(annotation.title ?? "Unknown")': \(fontSize)")

                label.font = UIFont.boldSystemFont(ofSize: fontSize)
                label.sizeToFit()

                if fontSize < minFontSize {
                    label.isHidden = true
                    print("[DEBUG] Hidden: Label too small for '\(annotation.title ?? "Unknown")'")
                } else {
                    label.isHidden = false
                    print("[DEBUG] Visible: Label adjusted for '\(annotation.title ?? "Unknown")'")
                }
            }
        }
    }
}
