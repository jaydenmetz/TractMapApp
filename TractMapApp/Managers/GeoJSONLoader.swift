import Foundation
import MapKit

class GeoJSONLoader {
    
    /// Parses GeoJSON data into an array of MKPolygon objects, supporting both Polygons and MultiPolygons.
    /// Adds annotations for label coordinates directly to the provided map view.
    /// - Parameters:
    ///   - data: The GeoJSON data.
    ///   - mapView: The MKMapView to add annotations to.
    /// - Returns: An array of MKPolygon objects.
    static func parseGeoJSON(data: Data, mapView: MKMapView) -> [MKPolygon] {
        var polygons: [MKPolygon] = []

        do {
            let geoJSONObjects = try MKGeoJSONDecoder().decode(data)
            print("Successfully decoded GeoJSON. Objects count: \(geoJSONObjects.count)")

            for item in geoJSONObjects {
                guard let feature = item as? MKGeoJSONFeature else { continue }

                for geometry in feature.geometry {
                    print("Geometry type: \(type(of: geometry))") // Debugging the geometry type

                    switch geometry {
                    case let polygon as MKPolygon:
                        handlePolygon(polygon, from: feature, to: &polygons, mapView: mapView)
                    case let multiPolygon as MKMultiPolygon:
                        for subPolygon in multiPolygon.polygons {
                            handlePolygon(subPolygon, from: feature, to: &polygons, mapView: mapView)
                        }
                    default:
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

    /// Configures and appends a polygon to the list. Adds an annotation if label coordinates exist.
    /// - Parameters:
    ///   - polygon: The MKPolygon to configure.
    ///   - feature: The MKGeoJSONFeature containing properties.
    ///   - polygons: The array to append the configured polygon to.
    ///   - mapView: The MKMapView to add annotations to.
    private static func handlePolygon(_ polygon: MKPolygon, from feature: MKGeoJSONFeature, to polygons: inout [MKPolygon], mapView: MKMapView) {
        guard let propertiesData = feature.properties,
              let propertiesDict = try? JSONSerialization.jsonObject(with: propertiesData, options: []) as? [String: Any] else {
            print("Failed to decode properties for polygon.")
            return
        }

        configurePolygon(polygon, with: propertiesDict, mapView: mapView)
        polygons.append(polygon)
    }

    /// Configures an MKPolygon with its associated properties and adds an annotation if label coordinates are provided.
    /// - Parameters:
    ///   - polygon: The MKPolygon to configure.
    ///   - properties: A dictionary of properties.
    ///   - mapView: The MKMapView to add annotations to.
    private static func configurePolygon(_ polygon: MKPolygon, with properties: [String: Any], mapView: MKMapView) {
        polygon.title = properties["LblVal"] as? String

        // Initialize subtitle with all relevant properties, including z-index, label coordinates, and font size
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

        // Add label details to subtitle if available
        if let lblLat = properties["LblLat"] as? CLLocationDegrees,
           let lblLng = properties["LblLng"] as? CLLocationDegrees {
            subtitleComponents.append("LblLat:\(lblLat)")
            subtitleComponents.append("LblLng:\(lblLng)")
            
            // Add an annotation at the label coordinates
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: lblLat, longitude: lblLng)
            annotation.title = polygon.title
            mapView.addAnnotation(annotation)
        }
        if let fontSize = properties["FntSiz"] as? CGFloat {
            subtitleComponents.append("FntSiz:\(fontSize)")
        }

        polygon.subtitle = subtitleComponents.joined(separator: ";")
        print("Configured polygon with subtitle: \(polygon.subtitle ?? "None")")
    }
}
