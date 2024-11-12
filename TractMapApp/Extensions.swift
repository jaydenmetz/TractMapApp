//
//  MKCoordinateRegion+Equatable.swift
//  TractMapApp
//
//  Created by Jayden Metz on 11/8/24.
//

import MapKit

extension MKCoordinateRegion: Equatable {
    public static func == (lhs: MKCoordinateRegion, rhs: MKCoordinateRegion) -> Bool {
        return lhs.center.latitude == rhs.center.latitude &&
               lhs.center.longitude == rhs.center.longitude &&
               lhs.span.latitudeDelta == rhs.span.latitudeDelta &&
               lhs.span.longitudeDelta == rhs.span.longitudeDelta
    }
}

extension MKMapRect: Equatable {
    public static func == (lhs: MKMapRect, rhs: MKMapRect) -> Bool {
        return lhs.origin.x == rhs.origin.x &&
               lhs.origin.y == rhs.origin.y &&
               lhs.size.width == rhs.size.width &&
               lhs.size.height == rhs.size.height
    }
}

extension MKMapRect {
    init(region: MKCoordinateRegion) {
        let topLeft = CLLocationCoordinate2D(
            latitude: region.center.latitude + region.span.latitudeDelta / 2,
            longitude: region.center.longitude - region.span.longitudeDelta / 2
        )
        let bottomRight = CLLocationCoordinate2D(
            latitude: region.center.latitude - region.span.latitudeDelta / 2,
            longitude: region.center.longitude + region.span.longitudeDelta / 2
        )

        let topLeftPoint = MKMapPoint(topLeft)
        let bottomRightPoint = MKMapPoint(bottomRight)

        self = MKMapRect(
            origin: MKMapPoint(x: min(topLeftPoint.x, bottomRightPoint.x),
                               y: min(topLeftPoint.y, bottomRightPoint.y)),
            size: MKMapSize(width: abs(topLeftPoint.x - bottomRightPoint.x),
                            height: abs(topLeftPoint.y - bottomRightPoint.y))
        )
    }
}

