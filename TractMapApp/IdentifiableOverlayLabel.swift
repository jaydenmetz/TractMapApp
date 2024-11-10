//
//  OverlayLabel.swift
//  TractMapApp
//
//  Created by Jayden Metz on 11/7/24.
//

import MapKit

struct IdentifiableOverlayLabel: Identifiable {
    let id = UUID()  // Unique identifier for each overlay
    let overlay: MKOverlay
    let coordinate: CLLocationCoordinate2D
    let text: String

    init(overlay: MKOverlay, coordinate: CLLocationCoordinate2D, text: String) {
        self.overlay = overlay
        self.coordinate = coordinate
        self.text = text
    }
}
