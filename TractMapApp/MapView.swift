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
    @Binding var recenterTrigger: Bool
    var onOverlayTapped: (MKPolygon) -> Void
    @Binding var selectedPolygon: MKPolygon?
    
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
            print("Recenter trigger activated with region: \(region)")
            uiView.setRegion(region, animated: true)
            DispatchQueue.main.async {
                recenterTrigger = false
            }
        }
        
        let currentOverlaysSet = Set(uiView.overlays.map { ObjectIdentifier($0) })
        let newOverlaysSet = Set(overlays.map { ObjectIdentifier($0) })
        
        let overlaysToRemove = uiView.overlays.filter { !newOverlaysSet.contains(ObjectIdentifier($0)) }
        let overlaysToAdd = overlays.filter { !currentOverlaysSet.contains(ObjectIdentifier($0)) }
        
        overlaysToRemove.forEach { overlay in
            print("Removing overlay: \(overlay)")
        }
        overlaysToAdd.forEach { overlay in
            print("Adding overlay: \(overlay)")
        }
        
        uiView.removeOverlays(overlaysToRemove)
        uiView.addOverlays(overlaysToAdd)
        
        print("Updated overlays. Added: \(overlaysToAdd.count), Removed: \(overlaysToRemove.count)")
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self, onOverlayTapped: onOverlayTapped)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        var onOverlayTapped: (MKPolygon) -> Void
        
        init(_ parent: MapView, onOverlayTapped: @escaping (MKPolygon) -> Void) {
            self.parent = parent
            self.onOverlayTapped = onOverlayTapped
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polygon = overlay as? MKPolygon {
                let renderer = MKPolygonRenderer(polygon: polygon)
                let isSelected = parent.selectedPolygon == polygon
                renderer.fillColor = rendererColor(for: polygon.title ?? "Unknown", selected: isSelected)
                print("Rendering polygon: \(polygon.title ?? "Unknown"), isSelected: \(isSelected)")
                renderer.strokeColor = .black
                renderer.lineWidth = 2
                return renderer
            }
            print("Unknown overlay type: \(type(of: overlay))")
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
                    
                    if let currentlySelected = parent.selectedPolygon {
                        print("Currently selected polygon: \(currentlySelected.title ?? "None")")
                        
                        if currentlySelected == polygon {
                            print("Tapped overlay is already selected.")
                            return
                        }
                        
                        // Deselect the previous polygon
                        print("Deselecting previous overlay: \(currentlySelected.title ?? "Unknown")")
                        parent.selectedPolygon = nil
                        mapView.removeOverlay(currentlySelected)
                        mapView.addOverlay(currentlySelected) // Redraw deselected
                    }
                    
                    // Select the new polygon
                    parent.selectedPolygon = polygon
                    mapView.removeOverlay(polygon)
                    mapView.addOverlay(polygon) // Redraw selected
                    print("Newly selected polygon: \(polygon.title ?? "Unknown")")
                    
                    return
                }
            }
            print("Tapped outside of polygons.")
        }
        
        private func rendererColor(for title: String, selected: Bool) -> UIColor {
            switch title {
            case "The Northwest":
                return UIColor(red: 0.79, green: 0.95, blue: 0.77, alpha: selected ? 0.9 : 0.5)
            case "North Bakersfield":
                return UIColor(red: 0.88, green: 0.75, blue: 0.99, alpha: selected ? 0.9 : 0.5)
            case "Central Bakersfield":
                return UIColor(red: 0.92, green: 0.87, blue: 0.87, alpha: selected ? 0.9: 0.5)
            case "The Northeast":
                return UIColor(red: 0.77, green: 0.91, blue: 0.89, alpha: selected ? 0.9: 0.5)
            case "East Bakersfield":
                return UIColor(red: 0.77, green: 0.91, blue: 0.89, alpha: selected ? 0.9: 0.5)
            case "South Bakersfield":
                return UIColor(red: 0.78, green: 0.87, blue: 0.84, alpha: selected ? 0.9: 0.5)
            case "The Southeast":
                return UIColor(red: 0.93, green: 0.98, blue: 0.76, alpha: selected ? 0.9: 0.5)
            case "The Southwest":
                return UIColor(red: 0.88, green: 0.94, blue: 0.77, alpha: selected ? 0.9: 0.5)
            default:
                return UIColor.gray.withAlphaComponent(selected ? 0.9: 0.5)
            }
        }
    }
}
