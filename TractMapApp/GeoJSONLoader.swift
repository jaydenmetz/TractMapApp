import Foundation
import MapKit

class GeoJSONLoader {
    static func parseGeoJSON(data: Data) -> [MKPolygon] {
        var polygons: [MKPolygon] = []

        do {
            let geoJSONObjects = try MKGeoJSONDecoder().decode(data)
            for item in geoJSONObjects {
                if let feature = item as? MKGeoJSONFeature {
                    for geometry in feature.geometry {
                        if let polygon = geometry as? MKPolygon {
                            if let propertiesData = feature.properties,
                               let propertiesDict = try? JSONSerialization.jsonObject(with: propertiesData, options: []) as? [String: Any],
                               let label = propertiesDict["LblVal"] as? String {
                                polygon.title = label
                                polygons.append(polygon)
                            }
                        }
                    }
                }
            }
        } catch {
            print("Error parsing GeoJSON: \(error)")
        }

        return polygons
    }
}
