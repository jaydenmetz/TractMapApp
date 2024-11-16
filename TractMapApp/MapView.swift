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

            let currentOverlaysSet = Set(uiView.overlays.map { ObjectIdentifier($0) })
            let newOverlaysSet = Set(overlays.map { ObjectIdentifier($0) })

            let overlaysToRemove = uiView.overlays.filter { !newOverlaysSet.contains(ObjectIdentifier($0)) }
            uiView.removeOverlays(overlaysToRemove)
            print("Removed overlays: \(overlaysToRemove.map { $0.description })")

            let overlaysToAdd = overlays.filter { !currentOverlaysSet.contains(ObjectIdentifier($0)) }
            uiView.addOverlays(overlaysToAdd)
            print("Added overlays: \(overlaysToAdd.map { $0.description })")

            print("Current overlays count: \(uiView.overlays.count)")
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
                let renderer = TextPolygonRenderer(polygon: polygon)
                renderer.title = polygon.title // Pass title to custom renderer

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

        private func renderTextInsidePolygon(_ renderer: MKPolygonRenderer, title: String) {
            // Get the current graphics context
            guard let context = UIGraphicsGetCurrentContext() else {
                print("Failed to render text: Missing graphics context.")
                return
            }

            // Calculate the centroid of the polygon
            let polygon = renderer.polygon
            let points = polygon.points()
            let pointCount = polygon.pointCount

            var xSum: CGFloat = 0
            var ySum: CGFloat = 0

            for i in 0..<pointCount {
                let point = points[i]
                let mapPoint = MKMapPoint(x: point.x, y: point.y)
                let cgPoint = renderer.point(for: mapPoint)
                xSum += cgPoint.x
                ySum += cgPoint.y
            }

            let centroid = CGPoint(x: xSum / CGFloat(pointCount), y: ySum / CGFloat(pointCount))

            // Define text attributes
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center

            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10),
                .paragraphStyle: paragraphStyle,
                .foregroundColor: UIColor.black
            ]

            // Measure the text size
            let textSize = (title as NSString).size(withAttributes: attributes)
            let textRect = CGRect(
                x: centroid.x - textSize.width / 2,
                y: centroid.y - textSize.height / 2,
                width: textSize.width,
                height: textSize.height
            )

            // Draw the text
            context.saveGState()
            title.draw(in: textRect, withAttributes: attributes)
            context.restoreGState()

            print("Rendered text '\(title)' at centroid: \(centroid)")
        }

        @objc func handleTap(_ gestureRecognizer: UITapGestureRecognizer) {
            guard let mapView = gestureRecognizer.view as? MKMapView else { return }
            let tapPoint = gestureRecognizer.location(in: mapView)
            let tapCoordinate = mapView.convert(tapPoint, toCoordinateFrom: mapView)

            for overlay in mapView.overlays {
                if let polygon = overlay as? MKPolygon,
                   let renderer = mapView.renderer(for: polygon) as? MKPolygonRenderer,
                   renderer.path?.contains(renderer.point(for: MKMapPoint(tapCoordinate))) == true {
                    print("Tapped polygon with title: \(polygon.title ?? "No Title")")
                    onOverlayTapped(polygon, mapView)
                    return
                }
            }
            print("No polygon tapped.")
        }
    }
}

class TextPolygonRenderer: MKPolygonRenderer {
    var title: String?

    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        super.draw(mapRect, zoomScale: zoomScale, in: context)

        guard let title = title else { return }

        // Calculate the centroid of the polygon in map coordinates
        let polygon = self.polygon
        let points = polygon.points()
        let pointCount = polygon.pointCount

        var area: Double = 0
        var xSum: Double = 0
        var ySum: Double = 0

        for i in 0..<pointCount {
            let current = points[i].coordinate
            let next = points[(i + 1) % pointCount].coordinate

            let areaStep = current.latitude * next.longitude - next.latitude * current.longitude
            area += areaStep
            xSum += (current.latitude + next.latitude) * areaStep
            ySum += (current.longitude + next.longitude) * areaStep
        }

        area *= 0.5
        xSum /= (6 * area)
        ySum /= (6 * area)

        let centroidCoordinate = CLLocationCoordinate2D(latitude: xSum, longitude: ySum)
        let centroidPoint = self.point(for: MKMapPoint(centroidCoordinate))

        // Define text attributes
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12 / zoomScale),
            .paragraphStyle: paragraphStyle,
            .foregroundColor: UIColor.black
        ]

        // Measure the text size
        let textSize = (title as NSString).size(withAttributes: attributes)
        let textRect = CGRect(
            x: centroidPoint.x - textSize.width / 2,
            y: centroidPoint.y - textSize.height / 2,
            width: textSize.width,
            height: textSize.height
        )

        // Draw the text
        context.saveGState()
        UIGraphicsPushContext(context)
        title.draw(in: textRect, withAttributes: attributes)
        UIGraphicsPopContext()
        context.restoreGState()

        print("Rendered text '\(title)' at centroid: \(centroidCoordinate)")
    }
}
