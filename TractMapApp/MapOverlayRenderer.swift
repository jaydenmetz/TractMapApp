//
//  MapOverlayRenderer.swift
//  TractMapApp
//
//  Created by Jayden Metz on 10/31/24.
//

import Foundation
import MapKit

class MapOverlayRenderer: MKOverlayRenderer {
    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        guard let overlay = overlay as? IdentifiableOverlay else { return }

        let path = UIBezierPath(rect: rect(for: overlay.overlay.boundingMapRect))
        context.setLineWidth(overlay.overlay.boundingMapRect.width / zoomScale)
        UIColor.blue.setStroke()
        context.addPath(path.cgPath)
        context.strokePath()
    }
}
