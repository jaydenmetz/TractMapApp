import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    var overlays: [MKOverlay]
    @Binding var recenterTrigger: Bool
    var onOverlayTapped: (MKPolygon) -> Void
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
            if self.recenterTrigger {
                print("[DEBUG - updateUIView] Recenter triggered with region: \(self.region)")
                uiView.setRegion(self.region, animated: true)
                self.recenterTrigger = false
            }

            let currentOverlaysSet = Set(uiView.overlays.map { ObjectIdentifier($0) })
            let newOverlaysSet = Set(self.overlays.map { ObjectIdentifier($0) })

            let overlaysToRemove = uiView.overlays.filter { !newOverlaysSet.contains(ObjectIdentifier($0)) }
            let overlaysToAdd = self.overlays.filter { !currentOverlaysSet.contains(ObjectIdentifier($0)) }

            if !overlaysToRemove.isEmpty {
                print("[DEBUG - updateUIView] Removing overlays count: \(overlaysToRemove.count)")
                uiView.removeOverlays(overlaysToRemove)
            }

            if !overlaysToAdd.isEmpty {
                print("[DEBUG - updateUIView] Adding overlays count: \(overlaysToAdd.count)")
                uiView.addOverlays(overlaysToAdd)
            }

            print("[DEBUG - updateUIView] Final overlays count: \(uiView.overlays.count)")
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self, onOverlayTapped: onOverlayTapped)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        var onOverlayTapped: (MKPolygon) -> Void

        init(_ parent: MapView, onOverlayTapped: @escaping (MKPolygon) -> Void) {
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

                let fillColor = UIColor(
                    red: CGFloat(properties["FillClrR"] ?? 0.5),
                    green: CGFloat(properties["FillClrG"] ?? 0.5),
                    blue: CGFloat(properties["FillClrB"] ?? 0.5),
                    alpha: CGFloat(properties["FillOp"] ?? 0.3)
                )
                renderer.fillColor = fillColor
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
                    print("[DEBUG - handleTap] Polygon tapped: \(polygon.title ?? "Unknown")")
                    onOverlayTapped(polygon)
                    return
                }
            }
        }
    }
}
