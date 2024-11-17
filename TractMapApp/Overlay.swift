import MapKit

class Overlay: MKPolygonRenderer {
    
    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        super.draw(mapRect, zoomScale: zoomScale, in: context)
        
        guard let path = self.path else {
            print("No valid path for polygon.")
            return
        }
        
        // Set fill color based on polygon subtitle
        if let subtitle = polygon.subtitle,
           let fillColorComponents = subtitle.getFillColor() {
            print("Setting fill color: R:\(fillColorComponents.red), G:\(fillColorComponents.green), B:\(fillColorComponents.blue), A:\(fillColorComponents.alpha)")
            context.setFillColor(UIColor(
                red: fillColorComponents.red,
                green: fillColorComponents.green,
                blue: fillColorComponents.blue,
                alpha: fillColorComponents.alpha
            ).cgColor)
        } else {
            print("Using default blue color.")
            context.setFillColor(UIColor.systemBlue.withAlphaComponent(0.3).cgColor)
        }
        
        // Fill the polygon
        context.addPath(path)
        context.fillPath()
        
        // Adjust line width based on zoomScale for better scaling appearance
        let lineWidth = max(1.0, 2.0 / zoomScale)
        
        // Draw the gray border with dynamic line width
        context.setStrokeColor(UIColor.lightGray.cgColor)
        context.setLineWidth(lineWidth)
        context.addPath(path)
        context.strokePath()
        
        print("Polygon rendered with fill and stroke. Line width: \(lineWidth).")
    }
}
