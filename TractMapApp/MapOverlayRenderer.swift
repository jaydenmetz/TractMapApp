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

        func mapView(_ mapView: MKMapView, didSelect annotationView: MKAnnotationView) {
            print("Annotation selected: \(annotationView.annotation?.title ?? "Unknown")")
        }

        func mapView(_ mapView: MKMapView, didSelect overlay: MKOverlay) {
            if let polygon = overlay as? MKPolygon {
                print("Overlay selected in didSelect: \(polygon.title ?? "Unknown")")
                onSelectOverlay(polygon)
            } else {
                print("Non-polygon overlay selected")
            }
        }

        func mapView(_ mapView: MKMapView, didDeselect overlay: MKOverlay) {
            if let polygon = overlay as? MKPolygon {
                print("Overlay deselected: \(polygon.title ?? "Unknown")")
            }
        }

        func centerMapOnOverlay(mapView: MKMapView, polygon: MKPolygon) {
            print("Centering map on overlay: \(polygon.title ?? "Unknown")")
            let boundingRect = polygon.boundingMapRect
            let edgePadding = UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50)
            let region = mapView.mapRectThatFits(boundingRect, edgePadding: edgePadding)
            mapView.setRegion(MKCoordinateRegion(region), animated: true)
        }
    }
}

struct OverlayLabel: Identifiable {
    let id = UUID()
    var coordinate: CLLocationCoordinate2D
    var text: String
}
