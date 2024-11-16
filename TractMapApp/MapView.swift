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

        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        DispatchQueue.main.async {
            if recenterTrigger {
                uiView.setRegion(region, animated: true)
                recenterTrigger = false
            }

            let currentOverlaysSet = Set(uiView.overlays.map { ObjectIdentifier($0) })
            let newOverlaysSet = Set(overlays.map { ObjectIdentifier($0) })

            let overlaysToRemove = uiView.overlays.filter { !newOverlaysSet.contains(ObjectIdentifier($0)) }
            uiView.removeOverlays(overlaysToRemove)
            print("Removed overlays: \(overlaysToRemove.map { $0.description })")

            let overlaysToAdd = overlays.filter { !currentOverlaysSet.contains(ObjectIdentifier($0)) }
            uiView.addOverlays(overlaysToAdd)
            print("Added overlays: \(overlaysToAdd.map { $0.description })")

            print("Current overlays count: \(uiView.overlays.count)")
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self, onOverlayTapped: onOverlayTapped)
    }
}
