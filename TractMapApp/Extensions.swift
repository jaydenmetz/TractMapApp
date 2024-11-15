import MapKit
import ObjectiveC


extension MKCoordinateRegion {
    init(_ rect: MKMapRect) {
        let center = CLLocationCoordinate2D(
            latitude: rect.midY.convertToLatitude(),
            longitude: rect.midX.convertToLongitude()
        )
        let span = MKCoordinateSpan(
            latitudeDelta: rect.size.height.convertToLatitudeDelta(),
            longitudeDelta: rect.size.width.convertToLongitudeDelta()
        )
        self.init(center: center, span: span)
    }
}

extension Double {
    func convertToLatitude() -> CLLocationDegrees {
        MKMapPoint(x: 0, y: self).coordinate.latitude
    }

    func convertToLongitude() -> CLLocationDegrees {
        MKMapPoint(x: self, y: 0).coordinate.longitude
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

extension MKCoordinateRegion {
    func clampedToValidRange() -> MKCoordinateRegion {
        let clampedCenter = CLLocationCoordinate2D(
            latitude: min(max(center.latitude, -90.0), 90.0),
            longitude: min(max(center.longitude, -180.0), 180.0)
        )

        let clampedSpan = MKCoordinateSpan(
            latitudeDelta: max(0.001, abs(span.latitudeDelta)), // Prevent negative or too small values
            longitudeDelta: max(0.001, abs(span.longitudeDelta))
        )

        return MKCoordinateRegion(center: clampedCenter, span: clampedSpan)
    }
}

private var annotationDisplayedKey: UInt8 = 0

extension MKPolygon {
    var annotationDisplayed: Bool {
        get {
            objc_getAssociatedObject(self, &annotationDisplayedKey) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(self, &annotationDisplayedKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

extension CLLocationCoordinate2D {
    func isEqual(to other: CLLocationCoordinate2D) -> Bool {
        return self.latitude == other.latitude && self.longitude == other.longitude
    }
}

extension MKMapView {
    func convertToCoordinateRegion(from mapRect: MKMapRect) -> MKCoordinateRegion {
        let topLeft = MKMapPoint(x: mapRect.minX, y: mapRect.minY).coordinate
        let bottomRight = MKMapPoint(x: mapRect.maxX, y: mapRect.maxY).coordinate

        let center = CLLocationCoordinate2D(
            latitude: (topLeft.latitude + bottomRight.latitude) / 2,
            longitude: (topLeft.longitude + bottomRight.longitude) / 2
        )

        let span = MKCoordinateSpan(
            latitudeDelta: abs(topLeft.latitude - bottomRight.latitude),
            longitudeDelta: abs(topLeft.longitude - bottomRight.longitude)
        )

        return MKCoordinateRegion(center: center, span: span)
    }
}
