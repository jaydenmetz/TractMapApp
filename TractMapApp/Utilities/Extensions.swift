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

        print("Parsed properties: \(properties)") // Debug parsed properties
        
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
