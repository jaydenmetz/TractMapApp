import Foundation
import MapKit
import CoreLocation

extension String {
    func getPolygonProperties() -> (fillColorR: CGFloat, fillColorG: CGFloat, fillColorB: CGFloat, fillOpacity: CGFloat, strokeColorName: String, strokeWeight: CGFloat, strokeOpacity: CGFloat)? {
        let components = self.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: ";")
        var properties = [String: String]()
        
        for component in components {
            let parts = component.split(separator: ":", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            if parts.count == 2 {
                properties[parts[0]] = parts[1]
            } else {
                print("Malformed component: \(component)") // Debugging malformed part
            }
        }
        
        guard let fillColorR = properties["FillClrR"].flatMap({ CGFloat(Double($0) ?? 0.0) }),
              let fillColorG = properties["FillClrG"].flatMap({ CGFloat(Double($0) ?? 0.0) }),
              let fillColorB = properties["FillClrB"].flatMap({ CGFloat(Double($0) ?? 0.0) }),
              let fillOpacity = properties["FillOp"].flatMap({ CGFloat(Double($0) ?? 0.0) }),
              let strokeColorName = properties["StrkClr"],
              let strokeWeight = properties["StrkWt"].flatMap({ CGFloat(Double($0) ?? 0.0) }),
              let strokeOpacity = properties["StrkOp"].flatMap({ CGFloat(Double($0) ?? 0.0) }) else {
            print("Failed to parse all required properties for subtitle: \(self)")
            return nil
        }
        
        return (fillColorR, fillColorG, fillColorB, fillOpacity, strokeColorName, strokeWeight, strokeOpacity)
    }
}

extension MKPolygon: Identifiable {
    public var id: String {
        self.title ?? UUID().uuidString
    }
}

extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

extension MKCoordinateRegion {
    func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
        let latitudeWithinBounds = (center.latitude - span.latitudeDelta / 2) <= coordinate.latitude
            && coordinate.latitude <= (center.latitude + span.latitudeDelta / 2)
        let longitudeWithinBounds = (center.longitude - span.longitudeDelta / 2) <= coordinate.longitude
            && coordinate.longitude <= (center.longitude + span.longitudeDelta / 2)
        return latitudeWithinBounds && longitudeWithinBounds
    }
}

extension MKCoordinateRegion {
    func toMKMapRect() -> MKMapRect {
        let topLeft = MKMapPoint(CLLocationCoordinate2D(
            latitude: center.latitude + span.latitudeDelta / 2,
            longitude: center.longitude - span.longitudeDelta / 2
        ))
        let bottomRight = MKMapPoint(CLLocationCoordinate2D(
            latitude: center.latitude - span.latitudeDelta / 2,
            longitude: center.longitude + span.longitudeDelta / 2
        ))

        return MKMapRect(
            origin: MKMapPoint(x: min(topLeft.x, bottomRight.x), y: min(topLeft.y, bottomRight.y)),
            size: MKMapSize(width: abs(topLeft.x - bottomRight.x), height: abs(topLeft.y - bottomRight.y))
        )
    }
}

extension MKPolygon {
    /// Parses the subtitle string to extract polygon properties.
    func getExtendedProperties() -> [String: Any]? {
        guard let subtitle = self.subtitle else {
            print("Subtitle is missing for polygon titled: \(self.title ?? "Unknown")")
            return nil
        }
        
        var properties: [String: Any] = [:]
        
        let keyValuePairs = subtitle.split(separator: ";")
        for pair in keyValuePairs {
            let keyValue = pair.split(separator: ":")
            guard keyValue.count == 2 else { continue }
            
            let key = String(keyValue[0])
            let value = String(keyValue[1])
            
            // Handle known keys and convert to correct types
            switch key {
            case "StrkClr":
                properties["StrkClr"] = value
            case "StrkWt":
                properties["StrkWt"] = CGFloat(Double(value) ?? 1.0)
            case "StrkOp":
                properties["StrkOp"] = CGFloat(Double(value) ?? 1.0)
            case "FillClrR":
                properties["FillClrR"] = CGFloat(Double(value) ?? 0.5)
            case "FillClrG":
                properties["FillClrG"] = CGFloat(Double(value) ?? 0.5)
            case "FillClrB":
                properties["FillClrB"] = CGFloat(Double(value) ?? 0.5)
            case "FillOp":
                properties["FillOp"] = CGFloat(Double(value) ?? 0.3)
            case "LblVal":
                properties["LblVal"] = value
            case "LblLat":
                properties["LblLat"] = CLLocationDegrees(Double(value) ?? 0.0)
            case "LblLng":
                properties["LblLng"] = CLLocationDegrees(Double(value) ?? 0.0)
            case "FntSiz":
                properties["FntSiz"] = CGFloat(Double(value) ?? 12.0)
            case "z":
                properties["Z"] = Int(value) ?? 0
            default:
                print("Unknown property key: \(key)")
            }
        }
        
        return properties
    }
}
