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
        mapView.mapType = .mutedStandard
        
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleTap(_:)))
        mapView.addGestureRecognizer(tapGesture)

        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        DispatchQueue.main.async {
            if recenterTrigger {
                uiView.setRegion(region, animated: true)
                recenterTrigger = false
            }

            let nonUserAnnotations = uiView.annotations.filter { !($0 is MKUserLocation) }
            if nonUserAnnotations.count != annotations.count || !nonUserAnnotations.elementsEqual(annotations, by: { $0.coordinate.isEqual(to: $1.coordinate) && $0.title == $1.title }) {
                uiView.removeAnnotations(nonUserAnnotations)
                uiView.addAnnotations(annotations)
                print("Added new annotations.")
            }

            let currentOverlaysSet = Set(uiView.overlays.map { ObjectIdentifier($0) })
            let newOverlaysSet = Set(overlays.map { ObjectIdentifier($0) })

            let overlaysToRemove = uiView.overlays.filter { !newOverlaysSet.contains(ObjectIdentifier($0)) }
            uiView.removeOverlays(overlaysToRemove)

            let overlaysToAdd = overlays.filter { !currentOverlaysSet.contains(ObjectIdentifier($0)) }
            uiView.addOverlays(overlaysToAdd)

            print("Updated overlays.")

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                context.coordinator.adjustAnnotationLabels(for: uiView)
            }
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

                if let subtitle = polygon.subtitle,
                   let fillColorComponents = subtitle.getFillColor() {
                    renderer.fillColor = UIColor(
                        red: fillColorComponents.red,
                        green: fillColorComponents.green,
                        blue: fillColorComponents.blue,
                        alpha: fillColorComponents.alpha
                    )
                } else {
                    renderer.fillColor = UIColor.gray.withAlphaComponent(0.5)
                }

                renderer.strokeColor = UIColor.black.withAlphaComponent(1.0)
                renderer.lineWidth = 2
                return renderer
            }

            return MKOverlayRenderer(overlay: overlay)
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard !(annotation is MKUserLocation) else { return nil }

            let reuseIdentifier = "CustomAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier)

            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
                annotationView?.isEnabled = false
                annotationView?.canShowCallout = false

                let label = UILabel()
                label.textAlignment = .center
                label.numberOfLines = 0
                label.font = UIFont.boldSystemFont(ofSize: 12)
                label.backgroundColor = .clear
                label.tag = 100
                annotationView?.addSubview(label)
            } else {
                annotationView?.annotation = annotation
            }

            annotationView?.image = nil

            guard let label = annotationView?.viewWithTag(100) as? UILabel else {
                print("Failed to find label for annotation: \(annotation.title ?? "Unknown").")
                return annotationView
            }

            label.text = annotation.title ?? ""
            label.sizeToFit()
            label.center = CGPoint(x: annotationView!.bounds.midX, y: annotationView!.bounds.midY)

            print("Created/updated annotation view for: \(annotation.title ?? "Unknown")")
            return annotationView
        }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            adjustAnnotationLabels(for: mapView)
        }

        @objc func handleTap(_ gestureRecognizer: UITapGestureRecognizer) {
            guard let mapView = gestureRecognizer.view as? MKMapView else { return }
            let tapPoint = gestureRecognizer.location(in: mapView)
            let tapCoordinate = mapView.convert(tapPoint, toCoordinateFrom: mapView)

            for overlay in mapView.overlays {
                if let polygon = overlay as? MKPolygon,
                   let renderer = mapView.renderer(for: polygon) as? MKPolygonRenderer,
                   renderer.path?.contains(renderer.point(for: MKMapPoint(tapCoordinate))) == true {
                    onOverlayTapped(polygon, mapView)
                    return
                }
            }
        }

        func adjustAnnotationLabels(for mapView: MKMapView) {
            print("adjustAnnotationLabels called.")
            print("Overlays count: \(mapView.overlays.count)")
            print("Annotations count: \(mapView.annotations.count)")

            for annotation in mapView.annotations {
                guard let annotationView = mapView.view(for: annotation) as? MKAnnotationView else {
                    print("No annotation view found for annotation: \(annotation.title ?? "Unknown"). Skipping.")
                    continue
                }

                guard let polygon = mapView.overlays.compactMap({ $0 as? MKPolygon }).first(where: {
                    $0.subtitle == annotation.subtitle
                }) else {
                    print("No matching polygon found for annotation: \(annotation.title ?? "Unknown") with subtitle: \(annotation.subtitle ?? "None"). Skipping.")
                    continue
                }

                print("Adjusting label for annotation: \(annotation.title ?? "Unknown") matching polygon with subtitle: \(polygon.subtitle ?? "None")")

                guard let label = annotationView.subviews.first(where: { $0.tag == 100 }) as? UILabel else {
                    print("No label found in annotation view for annotation: \(annotation.title ?? "Unknown"). Skipping.")
                    continue
                }

                let mapRect = polygon.boundingMapRect
                let centerPoint = mapView.convert(MKMapPoint(polygon.coordinate).coordinate, toPointTo: annotationView)

                let fontSize = max(8, min(mapView.visibleMapRect.width / 50, 18))
                label.text = annotation.title ?? ""
                label.font = UIFont.boldSystemFont(ofSize: fontSize)
                label.textAlignment = .center
                label.center = centerPoint
                label.isHidden = fontSize < 8 || mapRect.size.width < 200
            }
        }
    }
}
