//
//  IdentifiableOverlay.swift
//  TractMapApp
//
//  Created by Jayden Metz on 10/31/24.
//

import Foundation
import MapKit

struct IdentifiableOverlay: Identifiable {
    let id = UUID()
    let overlay: MKOverlay
    let name: String
    let centroid: CLLocationCoordinate2D
}
