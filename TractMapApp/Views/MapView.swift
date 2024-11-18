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
            if recenterTrigger {
                print("Recentering map to region: \(region)")
                if !areRegionsEqual(uiView.region, region) {
                    uiView.setRegion(region, animated: true)
                }
                recenterTrigger = false
            } else if !areRegionsEqual(uiView.region, region) {
                print("Animating to new region.")
                uiView.setRegion(region, animated: true)
            } else {
                print("Region unchanged; skipping animation.")
            }
        }
            // Overlays logic remains unchanged
            updateOverlays(uiView)

            // Annotations comparison and update
            updateAnnotations(uiView)

            print("Current overlays count: \(uiView.overlays.count)")
            print("Current annotations count: \(uiView.annotations.count)")
    }

    func updateOverlays(_ mapView: MKMapView) {
        // Sort overlays by z-index in descending order (highest z on top)
        let sortedOverlays = overlays.sorted {
            let z1 = extractZIndex(from: $0) ?? 0
            let z2 = extractZIndex(from: $1) ?? 0
            return z1 > z2
        }

        let currentOverlaysSet = Set(mapView.overlays.map { ObjectIdentifier($0) })
        let newOverlaysSet = Set(sortedOverlays.map { ObjectIdentifier($0) })

        let overlaysToRemove = mapView.overlays.filter { !newOverlaysSet.contains(ObjectIdentifier($0)) }
        let overlaysToAdd = sortedOverlays.filter { !currentOverlaysSet.contains(ObjectIdentifier($0)) }

        if !overlaysToRemove.isEmpty {
            print("Removing \(overlaysToRemove.count) overlays.")
            mapView.removeOverlays(overlaysToRemove)
        }

        if !overlaysToAdd.isEmpty {
            print("Adding \(overlaysToAdd.count) overlays.")
            mapView.addOverlays(overlaysToAdd)
        }
    }

    private func extractZIndex(from overlay: MKOverlay) -> Int? {
        guard let polygon = overlay as? MKPolygon,
              let label = polygon.accessibilityLabel,
              let zString = label.split(separator: ":").last,
              let zIndex = Int(zString) else { return nil }
        return zIndex
    }

    func updateAnnotations(_ mapView: MKMapView) {
        let currentAnnotations = Set(mapView.annotations.map { HashableCoordinate(coordinate: $0.coordinate) })
        let newAnnotations = Set(annotations.map { HashableCoordinate(coordinate: $0.coordinate) })

        if currentAnnotations != newAnnotations {
            mapView.removeAnnotations(mapView.annotations)
            mapView.addAnnotations(annotations)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        print("Coordinator created.")
        return Coordinator(self, selectedPolygon: $selectedPolygon, onOverlayTapped: onOverlayTapped)
    }

    func areRegionsEqual(_ region1: MKCoordinateRegion, _ region2: MKCoordinateRegion, tolerance: Double = 0.0001) -> Bool {
        let centerDiff = abs(region1.center.latitude - region2.center.latitude) < tolerance &&
                         abs(region1.center.longitude - region2.center.longitude) < tolerance
        let spanDiff = abs(region1.span.latitudeDelta - region2.span.latitudeDelta) < tolerance &&
                       abs(region1.span.longitudeDelta - region2.span.longitudeDelta) < tolerance
        return centerDiff && spanDiff
    }
}
