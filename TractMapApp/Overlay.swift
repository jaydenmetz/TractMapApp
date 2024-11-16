import MapKit

class Overlay: MKPolygonRenderer {
    var title: String?

    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        super.draw(mapRect, zoomScale: zoomScale, in: context)

        guard let title = title else {
            print("No title provided.")
            return
        }

        let polygon = self.polygon
        let points = polygon.points()
        let pointCount = polygon.pointCount

        // Calculate centroid
        var area: CGFloat = 0
        var xSum: CGFloat = 0
        var ySum: CGFloat = 0

        for i in 0..<pointCount {
            let current = points[i]
            let next = points[(i + 1) % pointCount]
            let currentPoint = MKMapPoint(x: current.x, y: current.y)
            let nextPoint = MKMapPoint(x: next.x, y: next.y)
            let a = CGFloat(currentPoint.x * nextPoint.y - nextPoint.x * currentPoint.y)
            area += a
            xSum += (CGFloat(currentPoint.x) + CGFloat(nextPoint.x)) * a
            ySum += (CGFloat(currentPoint.y) + CGFloat(nextPoint.y)) * a
        }

        guard area != 0 else {
            print("Area is zero, cannot calculate centroid.")
            return
        }

        area *= 0.5
        let centroidMapPoint = MKMapPoint(x: xSum / (6 * area), y: ySum / (6 * area))
        let viewPoint = self.point(for: centroidMapPoint)

        print("Centroid in view coordinates: \(viewPoint)")

        // Adjust font size based on zoomScale, with a fixed base size
        let baseFontSize: CGFloat = 48
        let scaledFontSize = baseFontSize / zoomScale
        let fontSize = max(10, scaledFontSize) // Ensure a minimum readable size

        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: fontSize),
            .foregroundColor: UIColor.black,
            .backgroundColor: UIColor.white
        ]

        let textSize = title.size(withAttributes: attributes)
        let textRect = CGRect(
            x: viewPoint.x - textSize.width / 2,
            y: viewPoint.y - textSize.height / 2,
            width: textSize.width,
            height: textSize.height
        )

        // Ensure rendering only if text is within visible bounds
        if mapRect.contains(centroidMapPoint) {
            UIGraphicsPushContext(context)
            title.draw(in: textRect, withAttributes: attributes)
            UIGraphicsPopContext()
        }

        // Adjust line width dynamically based on zoomScale
        let baseLineWidth: CGFloat = 1.0
        let scaledLineWidth = baseLineWidth / zoomScale
        

        print("Rendered text '\(title)' at \(viewPoint) with dynamic font size \(fontSize) and line width \(scaledLineWidth).")
    }
}
