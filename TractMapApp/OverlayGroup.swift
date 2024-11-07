//
//  OverlayGroup.swift
//  TractMapApp
//
//  Created by Jayden Metz on 11/6/24.
//

import Foundation

struct OverlayGroup: Identifiable {
    let id = UUID()
    let name: String
    let overlays: [IdentifiableOverlay]
}
