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
            latitudeDelta: max(0.001, abs(span.latitudeDelta)),
            longitudeDelta: max(0.001, abs(span.longitudeDelta))
        )

        return MKCoordinateRegion(center: clampedCenter, span: clampedSpan)
    }
}

private var annotationLoadedKey: UInt8 = 0

extension MKPolygon {
    var annotationLoaded: Bool {
        get {
            return objc_getAssociatedObject(self, &annotationLoadedKey) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(self, &annotationLoadedKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
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

extension MKPolygon {
    var fillColorComponents: UIColor {
        guard let subtitle = self.subtitle else {
            print("Error: Subtitle missing.")
            return UIColor.gray.withAlphaComponent(0.5)
        }

        print("Parsing subtitle:", subtitle) // Debugging subtitle content

        let properties = subtitle
            .split(separator: ";")
            .reduce(into: [String: CGFloat]()) { dict, pair in
                let components = pair.split(separator: ":")
                if components.count == 2,
                   let key = components.first?.trimmingCharacters(in: .whitespaces),
                   let value = Double(components.last!.trimmingCharacters(in: .whitespaces)) {
                    dict[key] = CGFloat(value)
                }
            }

        if let fillR = properties["FillClrR"],
           let fillG = properties["FillClrG"],
           let fillB = properties["FillClrB"],
           (0.0...1.0).contains(fillR),
           (0.0...1.0).contains(fillG),
           (0.0...1.0).contains(fillB) {
            return UIColor(red: fillR, green: fillG, blue: fillB, alpha: 0.5)
        } else {
            print("Error: Missing or invalid color components. Defaulting to gray.")
            return UIColor.gray.withAlphaComponent(0.5)
        }
    }
}

// Utility extension for parsing polygon color
extension String {
    func getFillColor() -> (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)? {
        let components = self.split(separator: ";").reduce(into: [String: String]()) { dict, pair in
            let keyValue = pair.split(separator: ":")
            if keyValue.count == 2 {
                dict[String(keyValue[0])] = String(keyValue[1])
            }
        }

        guard
            let redString = components["FillClrR"],
            let greenString = components["FillClrG"],
            let blueString = components["FillClrB"],
            let alphaString = components["FillOp"],
            let red = Double(redString),
            let green = Double(greenString),
            let blue = Double(blueString),
            let alpha = Double(alphaString)
        else {
            return nil
        }

        return (red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: CGFloat(alpha))
    }
}
