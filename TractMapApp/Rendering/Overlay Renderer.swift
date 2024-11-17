import MapKit

class Overlay: MKPolygonRenderer {
    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        super.draw(mapRect, zoomScale: zoomScale, in: context)
        
        guard let path = self.path else {
            print("No valid path for polygon.")
            return
        }

        // Set colors from subtitle data
        if let subtitle = polygon.subtitle, let properties = subtitle.getPolygonProperties() {
            context.setFillColor(UIColor(
                red: properties.fillColorR,
                green: properties.fillColorG,
                blue: properties.fillColorB,
                alpha: properties.fillOpacity
            ).cgColor)
            
            context.setStrokeColor(UIColor(named: properties.strokeColorName)?.cgColor ?? UIColor.gray.cgColor)
            context.setLineWidth(properties.strokeWeight)
            context.setAlpha(properties.strokeOpacity)
        } else {
            print("Setting Default color for polygon titled: \(polygon.title ?? "Unknown")")
            context.setFillColor(UIColor.blue.withAlphaComponent(0.2).cgColor) // Default fallback
            context.setStrokeColor(UIColor.gray.cgColor)
            context.setLineWidth(1.0)
        }

        // Fill and stroke
        context.addPath(path)
        context.fillPath()
        context.addPath(path)
        context.strokePath()
    }
}
