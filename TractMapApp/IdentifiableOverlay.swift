//
//  IdentifiableOverlay.swift
//  TractMapApp
//
//  Created by Jayden Metz on 10/31/24.
//

import MapKit

struct IdentifiableOverlay: Identifiable, Equatable {
    let id = UUID()
    let overlay: MKOverlay
    let name: String
    let centroid: CLLocationCoordinate2D

    static func ==(lhs: IdentifiableOverlay, rhs: IdentifiableOverlay) -> Bool {
        return lhs.id == rhs.id
    }
}
