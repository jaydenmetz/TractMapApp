//
//  MapView.swift
//  TractMapApp
//
//  Created by Jayden Metz on 11/7/24.
//

import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    var overlays: [MKOverlay]
    var onRegionChange: (MKCoordinateRegion) -> Void
    @Binding var recenterTrigger: Bool

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.setRegion(region, animated: false)
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        if recenterTrigger {
            uiView.setRegion(region, animated: true)
            DispatchQueue.main.async {
                recenterTrigger = false
            }
        }

        let currentOverlays = uiView.overlays
        let overlaysToRemove = currentOverlays.filter { overlay in
            !overlays.contains { $0 === overlay }
        }
        let overlaysToAdd = overlays.filter { overlay in
            !currentOverlays.contains { $0 === overlay }
        }

        uiView.removeOverlays(Array(overlaysToRemove))
        uiView.addOverlays(Array(overlaysToAdd))
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self, onRegionChange: onRegionChange)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        var onRegionChange: (MKCoordinateRegion) -> Void

        init(_ parent: MapView, onRegionChange: @escaping (MKCoordinateRegion) -> Void) {
            self.parent = parent
            self.onRegionChange = onRegionChange
        }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            onRegionChange(mapView.region)
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polygon = overlay as? MKPolygon {
                let renderer = MKPolygonRenderer(polygon: polygon)
                
                // Debugging and color setting logic
                if let title = polygon.title {
                    print("Polygon title: \(title)")
                    switch title {
                    case "The Northwest":
                        print("Setting color for The Northwest")
                        renderer.fillColor = UIColor(red: 0.67, green: 0.83, blue: 0.45, alpha: 0.5) // Greenish
                    case "North Bakersfield":
                        print("Setting color for North Bakersfield")
                        renderer.fillColor = UIColor(red: 0.68, green: 0.77, blue: 0.94, alpha: 0.5) // Blueish
                    case "Central Bakersfield":
                        print("Setting color for Central Bakersfield")
                        renderer.fillColor = UIColor(red: 0.97, green: 0.77, blue: 0.51, alpha: 0.5) // Orange
                    case "The Northeast":
                        print("Setting color for The Northeast")
                        renderer.fillColor = UIColor(red: 0.68, green: 0.95, blue: 0.75, alpha: 0.5) // Light green
                    case "East Bakersfield":
                        print("Setting color for East Bakersfield")
                        renderer.fillColor = UIColor(red: 0.87, green: 0.76, blue: 0.96, alpha: 0.5) // Purple
                    case "South Bakersfield":
                        print("Setting color for South Bakersfield")
                        renderer.fillColor = UIColor(red: 0.93, green: 0.87, blue: 0.67, alpha: 0.5) // Yellowish
                    case "The Southeast":
                        print("Setting color for The Southeast")
                        renderer.fillColor = UIColor(red: 0.84, green: 0.94, blue: 0.66, alpha: 0.5) // Lime
                    case "The Southwest":
                        print("Setting color for The Southwest")
                        renderer.fillColor = UIColor(red: 0.66, green: 0.77, blue: 0.94, alpha: 0.5) // Sky Blue
                    default:
                        print("Default color applied")
                        renderer.fillColor = UIColor.gray.withAlphaComponent(0.5) // Default gray
                    }
                } else {
                    print("Polygon title is nil")
                    renderer.fillColor = UIColor.gray.withAlphaComponent(0.5)
                }

                renderer.strokeColor = .black
                renderer.lineWidth = 2
                return renderer
            }
            
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}
