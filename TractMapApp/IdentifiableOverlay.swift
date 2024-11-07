//
//  IdentifiableOverlay.swift
//  TractMapApp
//
//  Created by Jayden Metz on 11/6/24.
//

import Foundation
import MapKit

struct IdentifiableOverlay: Identifiable, Hashable {
    let id = UUID()
    let overlay: MKOverlay
    let name: String
    let lblLat: Double
    let lblLng: Double

    static func == (lhs: IdentifiableOverlay, rhs: IdentifiableOverlay) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
