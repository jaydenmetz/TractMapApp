import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    var overlays: [MKOverlay]
    var annotations: [MKPointAnnotation]
    @Binding var recenterTrigger: Bool
    var onOverlayTapped: (MKPolygon, MKMapView) -> Void
    @Binding var selectedPolygon: MKPolygon?

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.setRegion(region, animated: false)
        mapView.mapType = .mutedStandard

        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleTap(_:)))
        mapView.addGestureRecognizer(tapGesture)

        print("MKMapView created and configured.")
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        DispatchQueue.main.async {
            // Update region if recentering is triggered
            if recenterTrigger {
                print("Recentering map to region: \(region)")
                uiView.setRegion(region, animated: true)
                recenterTrigger = false
            }

            // Handle overlays
            let currentOverlaysSet = Set(uiView.overlays.map { ObjectIdentifier($0) })
            let newOverlaysSet = Set(overlays.map { ObjectIdentifier($0) })

            let overlaysToRemove = uiView.overlays.filter { !newOverlaysSet.contains(ObjectIdentifier($0)) }
            let overlaysToAdd = overlays.filter { !currentOverlaysSet.contains(ObjectIdentifier($0)) }

            if !overlaysToRemove.isEmpty {
                print("Removing \(overlaysToRemove.count) overlays.")
                uiView.removeOverlays(overlaysToRemove)
            }

            if !overlaysToAdd.isEmpty {
                print("Adding \(overlaysToAdd.count) overlays.")
                uiView.addOverlays(overlaysToAdd)
            }

            // Handle annotations by comparing coordinates manually
            let currentAnnotations = uiView.annotations.map { $0.coordinate }
            let newAnnotations = annotations.map { $0.coordinate }

            // Compare annotations only when coordinates differ
            if currentAnnotations != newAnnotations {
                print("Updating annotations. Removing \(uiView.annotations.count) and adding \(annotations.count).")
                uiView.removeAnnotations(uiView.annotations)
                uiView.addAnnotations(annotations)
            }

            // Log current map status
            print("Current overlays count: \(uiView.overlays.count)")
            print("Current annotations count: \(uiView.annotations.count)")
        }
    }

    func makeCoordinator() -> Coordinator {
        print("Coordinator created.")
        return Coordinator(self, selectedPolygon: $selectedPolygon, onOverlayTapped: onOverlayTapped)
    }
}
