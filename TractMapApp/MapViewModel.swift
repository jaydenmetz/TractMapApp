//
//  MapViewModel.swift
//  TractMapApp
//
//  Created by Jayden Metz on 10/31/24.
//

import Foundation
import MapKit
import SwiftUI

class MapViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.41546, longitude: -119.10914),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    @Published var overlays: [IdentifiableOverlay] = []
    @Published var annotations: [MKAnnotation] = [] // Change this to [MKAnnotation] to match expected type.

    private let locationManager = CLLocationManager()

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        loadOverlays()
    }

    func loadOverlays() {
        guard let url = Bundle.main.url(forResource: "MLS Neighborhoods", withExtension: "geojson") else {
            print("GeoJSON file not found")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let features = try MKGeoJSONDecoder().decode(data).compactMap { $0 as? MKGeoJSONFeature }

            for feature in features {
                if let polygon = feature.geometry.first as? MKPolygon,
                   let properties = feature.properties,
                   let json = try? JSONSerialization.jsonObject(with: properties) as? [String: Any],
                   let lblVal = json["LblVal"] as? String,
                   let lblLat = json["LblLat"] as? Double,
                   let lblLng = json["LblLng"] as? Double {

                    let overlay = IdentifiableOverlay(
                        overlay: polygon,
                        name: lblVal,
                        lblLat: lblLat,
                        lblLng: lblLng
                    )
                    overlays.append(overlay)

                    let annotation = IdentifiableAnnotation(
                        coordinate: CLLocationCoordinate2D(latitude: lblLat, longitude: lblLng),
                        title: lblVal
                    )
                    annotations.append(annotation)
                }
            }
        } catch {
            print("Error loading GeoJSON: \(error)")
        }
    }
}
