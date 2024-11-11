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
                        renderer.fillColor = UIColor(red: 0.79, green: 0.95, blue: 0.77, alpha: 0.5) // #c9f1c4
                    case "North Bakersfield":
                        print("Setting color for North Bakersfield")
                        renderer.fillColor = UIColor(red: 0.88, green: 0.75, blue: 0.99, alpha: 0.5) // #e1c0fc
                    case "Central Bakersfield":
                        print("Setting color for Central Bakersfield")
                        renderer.fillColor = UIColor(red: 0.92, green: 0.87, blue: 0.87, alpha: 0.5) // #eadedd
                    case "The Northeast":
                        print("Setting color for The Northeast")
                        renderer.fillColor = UIColor(red: 0.77, green: 0.91, blue: 0.89, alpha: 0.5) // #c5e7e4
                    case "East Bakersfield":
                        print("Setting color for East Bakersfield")
                        renderer.fillColor = UIColor(red: 0.77, green: 0.91, blue: 0.89, alpha: 0.5) // #c5e7e4
                    case "South Bakersfield":
                        print("Setting color for South Bakersfield")
                        renderer.fillColor = UIColor(red: 0.78, green: 0.87, blue: 0.84, alpha: 0.5) // #c8ded7
                    case "The Southeast":
                        print("Setting color for The Southeast")
                        renderer.fillColor = UIColor(red: 0.93, green: 0.98, blue: 0.76, alpha: 0.5) // #eefac1
                    case "The Southwest":
                        print("Setting color for The Southwest")
                        renderer.fillColor = UIColor(red: 0.88, green: 0.94, blue: 0.77, alpha: 0.5) // #e1f0c5
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
