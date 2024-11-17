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

            // Extract color properties from subtitle or polygon metadata
            if let fillColor = parseFillColor(from: polygon.subtitle) {
                renderer.fillColor = UIColor(
                    red: fillColor.red,
                    green: fillColor.green,
                    blue: fillColor.blue,
                    alpha: fillColor.alpha
                )
            } else {
                renderer.fillColor = UIColor.systemBlue.withAlphaComponent(0.3)
            }
            renderer.lineWidth = 1.0
            renderer.strokeColor = UIColor.lightGray

            print("Polygon subtitle: \(polygon.subtitle ?? "No Subtitle")")
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

    private func parseFillColor(from subtitle: String?) -> (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)? {
        guard let subtitle = subtitle else { return nil }

        let components = subtitle.split(separator: ";")
        var red: CGFloat?
        var green: CGFloat?
        var blue: CGFloat?
        var alpha: CGFloat?

        for component in components {
            let keyValue = component.split(separator: ":")
            guard keyValue.count == 2 else { continue }

            let key = keyValue[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let value = CGFloat((keyValue[1] as NSString).floatValue)

            switch key {
            case "FillClrR": red = value
            case "FillClrG": green = value
            case "FillClrB": blue = value
            case "FillOp": alpha = value
            default: break
            }
        }

        if let red = red, let green = green, let blue = blue, let alpha = alpha {
            return (red, green, blue, alpha)
        }
        return nil
    }
}
