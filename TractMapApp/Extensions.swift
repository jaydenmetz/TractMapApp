import MapKit

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
