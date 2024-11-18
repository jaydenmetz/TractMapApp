//
//  HashableCoordinate.swift
//  TractMapApp
//
//  Created by Jayden Metz on 11/18/24.
//


import MapKit

struct HashableCoordinate: Hashable {
    let latitude: Double
    let longitude: Double

    init(coordinate: CLLocationCoordinate2D) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
    }

    func toCoordinate() -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// Hashable implementation
extension HashableCoordinate {
    static func == (lhs: HashableCoordinate, rhs: HashableCoordinate) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(latitude)
        hasher.combine(longitude)
    }
}