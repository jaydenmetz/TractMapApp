//
//  MKCoordinateRegion+Equatable.swift
//  TractMapApp
//
//  Created by Jayden Metz on 11/8/24.
//

import UIKit
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

extension MKCoordinateRegion {
    init(clamping region: MKCoordinateRegion) {
        let centerLatitude = min(max(region.center.latitude, -90.0), 90.0)
        let centerLongitude = min(max(region.center.longitude, -180.0), 180.0)
        let latitudeDelta = max(0.0001, min(region.span.latitudeDelta, 180.0))
        let longitudeDelta = max(0.0001, min(region.span.longitudeDelta, 360.0))
        
        print("Clamping Region: Center (\(centerLatitude), \(centerLongitude)), Span (\(latitudeDelta), \(longitudeDelta))")
        
        self.init(
            center: CLLocationCoordinate2D(latitude: centerLatitude, longitude: centerLongitude),
            span: MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        )
    }
}

extension MKCoordinateRegion {
    init(_ rect: MKMapRect) {
        let center = CLLocationCoordinate2D(
            latitude: rect.origin.y + rect.size.height / 2,
            longitude: rect.origin.x + rect.size.width / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: rect.size.height / MKMapSize.world.height * 180,
            longitudeDelta: rect.size.width / MKMapSize.world.width * 360
        )
        self.init(center: center, span: span)
    }
}

extension MKCoordinateRegion {
    func clampedToValidRange() -> MKCoordinateRegion {
        let clampedLatitude = min(max(center.latitude, -90.0), 90.0)
        let clampedLongitude = min(max(center.longitude, -180.0), 180.0)

        let clampedLatitudeDelta = max(0.0001, min(span.latitudeDelta, 180.0))
        let clampedLongitudeDelta = max(0.0001, min(span.longitudeDelta, 360.0))

        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: clampedLatitude, longitude: clampedLongitude),
            span: MKCoordinateSpan(latitudeDelta: clampedLatitudeDelta, longitudeDelta: clampedLongitudeDelta)
        )
    }

    func isValid() -> Bool {
        return center.latitude >= -90 && center.latitude <= 90 &&
               center.longitude >= -180 && center.longitude <= 180 &&
               span.latitudeDelta > 0 && span.latitudeDelta <= 180 &&
               span.longitudeDelta > 0 && span.longitudeDelta <= 360
    }
}

extension Double {
    func convertToLatitude() -> CLLocationDegrees {
        return MKMapPoint(x: 0, y: self).coordinate.latitude
    }

    func convertToLongitude() -> CLLocationDegrees {
        return MKMapPoint(x: self, y: 0).coordinate.longitude
    }

    func convertToLatitudeDelta() -> CLLocationDegrees {
        let south = MKMapPoint(x: 0, y: self)
        let north = MKMapPoint(x: 0, y: 0)
        return south.coordinate.latitude - north.coordinate.latitude
    }

    func convertToLongitudeDelta() -> CLLocationDegrees {
        let east = MKMapPoint(x: self, y: 0)
        let west = MKMapPoint(x: 0, y: 0)
        return east.coordinate.longitude - west.coordinate.longitude
    }
}

extension CALayer {
    func applyShadow(color: UIColor = .black, radius: CGFloat = 4, opacity: Float = 0.5, offset: CGSize = CGSize(width: 0, height: 2)) {
        shadowColor = color.cgColor
        shadowRadius = radius
        shadowOpacity = opacity
        shadowOffset = offset
        masksToBounds = false
    }
}

extension UILabel {
    func applyGradientBackground(colors: [UIColor]) {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = colors.map { $0.cgColor }
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.frame = bounds
        gradientLayer.cornerRadius = layer.cornerRadius
        layer.insertSublayer(gradientLayer, at: 0)
    }
}


extension MKCoordinateRegion {
    func withPadding(multiplier: CGFloat) -> MKCoordinateRegion {
        return MKCoordinateRegion(
            center: self.center,
            span: MKCoordinateSpan(
                latitudeDelta: self.span.latitudeDelta * multiplier,
                longitudeDelta: self.span.longitudeDelta * multiplier
            )
        )
    }
}
