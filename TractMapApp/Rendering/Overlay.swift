import MapKit

class Overlay: MKPolygonRenderer {
    
    /// Maps color names to UIColor
    private func colorFromName(_ name: String) -> UIColor {
        switch name.lowercased() {
        case "lightgray": return .lightGray
        case "darkgray": return .darkGray
        case "black": return .black
        default: return .gray
        }
    }

    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        guard let path = self.path else {
            print("Path missing")
            return
        }

        // Check if overlay provides expected properties
        if let polygon = self.overlay as? MKPolygon,
           let extendedProperties = polygon.getExtendedProperties() {
            
            let fillColor = UIColor(
                red: extendedProperties["FillClrR"] as? CGFloat ?? 0.5,
                green: extendedProperties["FillClrG"] as? CGFloat ?? 0.5,
                blue: extendedProperties["FillClrB"] as? CGFloat ?? 0.5,
                alpha: extendedProperties["FillOp"] as? CGFloat ?? 0.5
            )
            
            let strokeColor = colorFromName(extendedProperties["StrkClr"] as? String ?? "gray")
            let strokeOpacity = extendedProperties["StrkOp"] as? CGFloat ?? 1.0
            let strokeWeight = extendedProperties["StrkWt"] as? CGFloat ?? 1.0

            context.setFillColor(fillColor.cgColor)
            context.setStrokeColor(strokeColor.withAlphaComponent(strokeOpacity).cgColor)
            context.setLineWidth(strokeWeight)
            
            // Ensure paths are filled and stroked
            context.addPath(path)
            context.fillPath()
            context.addPath(path)
            context.strokePath()
            
            if let lblLat = extendedProperties["LblLat"] as? CLLocationDegrees,
               let lblLng = extendedProperties["LblLng"] as? CLLocationDegrees {
                let labelCoordinate = CLLocationCoordinate2D(latitude: lblLat, longitude: lblLng)
                let labelPoint = MKMapPoint(labelCoordinate)
                
                if mapRect.contains(labelPoint) {
                    let screenPoint = self.point(for: labelPoint)
                    drawLabel(polygon.title ?? "Untitled", at: screenPoint, fontSize: 14.0, in: context)
                }
            }
        } else {
            // Default for polygons with no properties
            context.setFillColor(UIColor.blue.withAlphaComponent(0.2).cgColor)
            context.setStrokeColor(UIColor.lightGray.cgColor)
            context.setLineWidth(1.0)
            
            context.addPath(path)
            context.fillPath()
            context.addPath(path)
            context.strokePath()
        }
    }

    private func drawLabel(_ text: String, at point: CGPoint, fontSize: CGFloat, in context: CGContext) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: fontSize),
            .foregroundColor: UIColor.black
        ]
        
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let textSize = attributedString.size()
        let textRect = CGRect(x: point.x - textSize.width / 2,
                              y: point.y - textSize.height / 2,
                              width: textSize.width,
                              height: textSize.height)
        
        UIGraphicsPushContext(context)
        attributedString.draw(in: textRect)
        UIGraphicsPopContext()
    }
}
