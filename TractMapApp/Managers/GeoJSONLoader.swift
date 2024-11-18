import Foundation
import MapKit

class GeoJSONLoader {
    /// Parses GeoJSON data into an array of MKPolygon objects, supporting both Polygons and MultiPolygons.
    /// - Parameter data: The GeoJSON data.
    /// - Returns: An array of MKPolygon objects.
    static func parseGeoJSON(data: Data) -> [MKPolygon] {
        var polygons: [MKPolygon] = []

        do {
            let geoJSONObjects = try MKGeoJSONDecoder().decode(data)
            print("Successfully decoded GeoJSON. Objects count: \(geoJSONObjects.count)")

            for item in geoJSONObjects {
                guard let feature = item as? MKGeoJSONFeature else { continue }

                for geometry in feature.geometry {
                    print("Geometry type: \(type(of: geometry))") // Debugging the geometry type

                    if let polygon = geometry as? MKPolygon {
                        handlePolygon(polygon, from: feature, to: &polygons)
                    } else if let multiPolygon = geometry as? MKMultiPolygon {
                        for subPolygon in multiPolygon.polygons {
                            handlePolygon(subPolygon, from: feature, to: &polygons)
                        }
                    } else {
                        print("Skipping unsupported geometry type: \(geometry)")
                    }
                }
            }
        } catch {
            print("Error parsing GeoJSON: \(error.localizedDescription)")
        }

        print("Parsed Overlays Count: \(polygons.count)")
        return polygons
    }

    /// Configures and appends a polygon to the list.
    /// - Parameters:
    ///   - polygon: The MKPolygon to configure.
    ///   - feature: The MKGeoJSONFeature containing properties.
    ///   - polygons: The array to append the configured polygon to.
    private static func handlePolygon(_ polygon: MKPolygon, from feature: MKGeoJSONFeature, to polygons: inout [MKPolygon]) {
        if let propertiesData = feature.properties,
           let propertiesDict = try? JSONSerialization.jsonObject(with: propertiesData, options: []) as? [String: Any] {
            configurePolygon(polygon, with: propertiesDict)
            polygons.append(polygon)
        } else {
            print("Failed to decode properties for polygon.")
        }
    }

    /// Configures an MKPolygon with its associated properties.
    /// - Parameters:
    ///   - polygon: The MKPolygon to configure.
    ///   - properties: A dictionary of properties.
    private static func configurePolygon(_ polygon: MKPolygon, with properties: [String: Any]) {
        polygon.title = properties["LblVal"] as? String

        // Initialize subtitle with all relevant properties, including z-index
        var subtitleComponents = [String]()
        
        if let strokeColorName = properties["StrkClr"] as? String {
            subtitleComponents.append("StrkClr:\(strokeColorName)")
        }
        if let strokeWeight = properties["StrkWt"] as? CGFloat {
            subtitleComponents.append("StrkWt:\(strokeWeight)")
        }
        if let strokeOpacity = properties["StrkOp"] as? CGFloat {
            subtitleComponents.append("StrkOp:\(strokeOpacity)")
        }
        if let fillColorR = properties["FillClrR"] as? CGFloat {
            subtitleComponents.append("FillClrR:\(fillColorR)")
        }
        if let fillColorG = properties["FillClrG"] as? CGFloat {
            subtitleComponents.append("FillClrG:\(fillColorG)")
        }
        if let fillColorB = properties["FillClrB"] as? CGFloat {
            subtitleComponents.append("FillClrB:\(fillColorB)")
        }
        if let fillOpacity = properties["FillOp"] as? CGFloat {
            subtitleComponents.append("FillOp:\(fillOpacity)")
        }
        if let zIndex = properties["Z"] as? Int {
            subtitleComponents.append("z:\(zIndex)")
            polygon.accessibilityLabel = "z:\(zIndex)" // Retain for sorting logic
            print("Set z-index \(zIndex) for polygon with title: \(polygon.title ?? "Unknown Title")")
        } else {
            print("No z-index provided for polygon: \(polygon.title ?? "Unknown Title")")
        }

        // Set subtitle
        polygon.subtitle = subtitleComponents.joined(separator: ";")
        print("Configured polygon with subtitle: \(polygon.subtitle ?? "None")")
    }
}
