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

        // Ensure no duplicate gesture recognizers
        mapView.gestureRecognizers?.forEach { mapView.removeGestureRecognizer($0) }
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

        // Efficiently update overlays without duplicates
        let currentOverlaysSet = Set(uiView.overlays.map { ObjectIdentifier($0) })
        let newOverlaysSet = Set(overlays.map { ObjectIdentifier($0) })

        let overlaysToRemove = uiView.overlays.filter { !newOverlaysSet.contains(ObjectIdentifier($0)) }
        let overlaysToAdd = overlays.filter { !currentOverlaysSet.contains(ObjectIdentifier($0)) }

        print("Before Update: \(uiView.overlays.count) overlays on map")
        print("Adding \(overlaysToAdd.count) overlays, Removing \(overlaysToRemove.count) overlays")

        uiView.removeOverlays(overlaysToRemove)
        uiView.addOverlays(overlaysToAdd)

        print("After Update: \(uiView.overlays.count) overlays on map")
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
                    print("Creating renderer for: \(title)")
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
                    print("Polygon title is nil")
                    renderer.fillColor = UIColor.gray.withAlphaComponent(0.5)
                }

                renderer.strokeColor = .black
                renderer.lineWidth = 2
                return renderer
            }

            return MKOverlayRenderer(overlay: overlay)
        }

        @objc func handleTap(_ gestureRecognizer: UITapGestureRecognizer) {
            guard let mapView = gestureRecognizer.view as? MKMapView else { return }
            let tapPoint = gestureRecognizer.location(in: mapView)
            let tapCoordinate = mapView.convert(tapPoint, toCoordinateFrom: mapView)

            for overlay in mapView.overlays {
                if let polygon = overlay as? MKPolygon,
                   let renderer = mapView.renderer(for: polygon) as? MKPolygonRenderer,
                   renderer.path?.contains(renderer.point(for: MKMapPoint(tapCoordinate))) == true {
                    print("Tapped on overlay: \(polygon.title ?? "Unknown")")
                    break
                }
            }
        }
    }
}
