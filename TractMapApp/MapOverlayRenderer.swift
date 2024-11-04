//
//  MapOverlayRenderer.swift
//  TractMapApp
//
//  Created by Jayden Metz on 10/31/24.
//
import MapKit

class MapOverlayRenderer: MKOverlayRenderer {
    var overlayWithCentroid: IdentifiableOverlay?

    init(overlay: MKOverlay, overlayWithCentroid: IdentifiableOverlay? = nil) {
        self.overlayWithCentroid = overlayWithCentroid
        super.init(overlay: overlay)
    }

    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        // Custom drawing logic here

        if let overlayWithCentroid = overlayWithCentroid {
            // Example: Draw a point at the centroid
            let point = point(for: MKMapPoint(overlayWithCentroid.centroid))
            let radius: CGFloat = 5.0
            context.setFillColor(UIColor.red.cgColor)
            context.addEllipse(in: CGRect(x: point.x - radius, y: point.y - radius, width: 2 * radius, height: 2 * radius))
            context.fillPath()
        }
    }
}
