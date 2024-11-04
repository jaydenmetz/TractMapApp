//
//  Item.swift
//  TractMapApp
//
//  Created by Jayden Metz on 11/1/24.
//

import Foundation
import CoreLocation

struct Item: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    let centroid: CLLocationCoordinate2D // Optional if it represents a center point for the item
}
