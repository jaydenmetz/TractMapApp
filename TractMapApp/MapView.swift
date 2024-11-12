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
        
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleTap(_:)))
        mapView.addGestureRecognizer(tapGesture)
        
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        if recenterTrigger {
            uiView.setRegion(region, animated: true)
            DispatchQueue.main.async {
                recenterTrigger = false
            }
        }

        // Efficient overlay updates
        let currentOverlaysSet = Set(uiView.overlays.map { ObjectIdentifier($0) })
        let newOverlaysSet = Set(overlays.map { ObjectIdentifier($0) })

        let overlaysToRemove = uiView.overlays.filter { !newOverlaysSet.contains(ObjectIdentifier($0)) }
        let overlaysToAdd = overlays.filter { !currentOverlaysSet.contains(ObjectIdentifier($0)) }

        uiView.removeOverlays(overlaysToRemove)
        uiView.addOverlays(overlaysToAdd)

        print("MapView updated: \(overlaysToAdd.count) overlays added, \(overlaysToRemove.count) removed")
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
                
                if let title = polygon.title {
                    #if DEBUG
                    debugPrint("Polygon title (debug): \(title)")
                    #endif
                    switch title {
                    case "The Northwest": renderer.fillColor = UIColor(red: 0.79, green: 0.95, blue: 0.77, alpha: 0.5)
                    case "North Bakersfield": renderer.fillColor = UIColor(red: 0.88, green: 0.75, blue: 0.99, alpha: 0.5)
                    case "Central Bakersfield": renderer.fillColor = UIColor(red: 0.92, green: 0.87, blue: 0.87, alpha: 0.5)
                    case "The Northeast": renderer.fillColor = UIColor(red: 0.77, green: 0.91, blue: 0.89, alpha: 0.5)
                    case "East Bakersfield": renderer.fillColor = UIColor(red: 0.77, green: 0.91, blue: 0.89, alpha: 0.5)
                    case "South Bakersfield": renderer.fillColor = UIColor(red: 0.78, green: 0.87, blue: 0.84, alpha: 0.5)
                    case "The Southeast": renderer.fillColor = UIColor(red: 0.93, green: 0.98, blue: 0.76, alpha: 0.5)
                    case "The Southwest": renderer.fillColor = UIColor(red: 0.88, green: 0.94, blue: 0.77, alpha: 0.5)
                    default: renderer.fillColor = UIColor.gray.withAlphaComponent(0.5)
                    }
                } else {
                    debugPrint("Polygon title is nil")
                    renderer.fillColor = UIColor.gray.withAlphaComponent(0.5)
                }

                renderer.strokeColor = .black
                renderer.lineWidth = 2
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }

        // Gesture Handling
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            let point = gesture.location(in: gesture.view)
            guard let mapView = gesture.view as? MKMapView else { return }

            let mapCoordinate = mapView.convert(point, toCoordinateFrom: mapView)
            let mapPoint = MKMapPoint(mapCoordinate) // Convert to MKMapPoint

            for overlay in mapView.overlays {
                if let renderer = mapView.renderer(for: overlay) as? MKPolygonRenderer,
                   let polygon = overlay as? MKPolygon,
                   renderer.path?.contains(renderer.point(for: mapPoint)) == true {
                    print("Tapped overlay: \(polygon.title ?? "Unknown")")
                }
            }
        }
    }
}
