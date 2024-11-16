import MapKit

class Coordinator: NSObject, MKMapViewDelegate {
    var parent: MapView
    var onOverlayTapped: (MKPolygon, MKMapView) -> Void

    init(_ parent: MapView, onOverlayTapped: @escaping (MKPolygon, MKMapView) -> Void) {
        self.parent = parent
        self.onOverlayTapped = onOverlayTapped
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polygon = overlay as? MKPolygon {
            let renderer = Overlay(polygon: polygon)
            renderer.title = polygon.title // Pass title to custom renderer
            
            // Check if subtitle contains fill color components
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
}
