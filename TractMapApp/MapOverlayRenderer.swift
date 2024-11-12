//
//  MapOverlayRenderer.swift
//  TractMapApp
//

import SwiftUI
import MapKit

struct MapOverlay: View {
    @Binding var region: MKCoordinateRegion
    var overlays: [MKOverlay]
    var annotations: [OverlayLabel]

    @State private var selectedOverlayTitle: String? = nil
    @State private var showPopup = false

    var body: some View {
        ZStack {
            Map(coordinateRegion: $region, interactionModes: .all, showsUserLocation: true, annotationItems: annotations) { annotation in
                MapAnnotation(coordinate: annotation.coordinate) {
                    Text(annotation.text)
                        .font(.caption)
                        .foregroundColor(.black)
                        .padding(4)
                        .background(Color.white.opacity(0.7))
                        .cornerRadius(5)
                }
            }
            .overlay(
                MapOverlayView(overlays: overlays, onSelectOverlay: { polygon in
                    selectedOverlayTitle = polygon.title
                    showPopup = true
                    print("Overlay selected: \(polygon.title ?? "Unknown")")
                })
            )

            if showPopup, let title = selectedOverlayTitle {
                VStack {
                    Spacer()
                    Text("Overlay Selected: \(title)")
                        .font(.headline)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                        .shadow(radius: 4)
                        .padding()
                    Button("Dismiss") {
                        showPopup = false
                        print("Popup dismissed for overlay: \(title)")
                    }
                }
                .transition(.slide)
            }
        }
    }
}

struct MapOverlayView: UIViewRepresentable {
    var overlays: [MKOverlay]
    var onSelectOverlay: (MKPolygon) -> Void

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true

        // Add tap gesture recognizer for overlay taps
        let tapRecognizer = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleTap(_:)))
        mapView.addGestureRecognizer(tapRecognizer)
        
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        print("Updating MapView with overlays...")

        let existingOverlays = Set(mapView.overlays.map { ObjectIdentifier($0) })
        let newOverlays = Set(overlays.map { ObjectIdentifier($0) })

        let overlaysToRemove = mapView.overlays.filter { !newOverlays.contains(ObjectIdentifier($0)) }
        let overlaysToAdd = overlays.filter { !existingOverlays.contains(ObjectIdentifier($0)) }

        mapView.removeOverlays(overlaysToRemove)
        mapView.addOverlays(overlaysToAdd)

        print("Overlays updated: \(overlaysToAdd.count) added, \(overlaysToRemove.count) removed")
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(onSelectOverlay: onSelectOverlay)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var onSelectOverlay: (MKPolygon) -> Void

        init(onSelectOverlay: @escaping (MKPolygon) -> Void) {
            self.onSelectOverlay = onSelectOverlay
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polygon = overlay as? MKPolygon {
                let renderer = MKPolygonRenderer(polygon: polygon)
                renderer.fillColor = UIColor.blue.withAlphaComponent(0.3)
                renderer.strokeColor = .blue
                renderer.lineWidth = 1.5
                print("Renderer created for overlay: \(polygon.title ?? "Unknown")")
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }

        @objc func handleTap(_ gestureRecognizer: UITapGestureRecognizer) {
            guard let mapView = gestureRecognizer.view as? MKMapView else { return }
            let point = gestureRecognizer.location(in: mapView)
            let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
            
            for overlay in mapView.overlays {
                if let polygon = overlay as? MKPolygon, polygon.contains(coordinate) {
                    print("Tapped on overlay: \(polygon.title ?? "Unknown")")
                    onSelectOverlay(polygon)
                    break
                }
            }
        }
    }
}

extension MKPolygon {
    func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
        let mapPoint = MKMapPoint(coordinate)
        let renderer = MKPolygonRenderer(polygon: self)
        let point = renderer.point(for: mapPoint)
        return renderer.path.contains(point)
    }
}

struct OverlayLabel: Identifiable {
    let id = UUID()
    var coordinate: CLLocationCoordinate2D
    var text: String
}
