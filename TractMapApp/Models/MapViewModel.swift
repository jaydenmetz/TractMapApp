import Foundation
import MapKit

class MapViewModel: ObservableObject {
    @Published var overlays: [MKOverlay] = []
    @Published var annotations: [MKPointAnnotation] = []
    @Published var visibleRegion: MKCoordinateRegion?
    @Published var selectedPolygon: MKPolygon?
    @Published var showRegionalNeighborhoods = false {
        didSet { loadGeoJSONIfNeeded() }
    }
    @Published var showNeighborhoods = false {
        didSet { loadGeoJSONIfNeeded() }
    }
    @Published var showSubdivisions = false {
        didSet { loadGeoJSONIfNeeded() }
    }

    func loadGeoJSONIfNeeded() {
        overlays = []
        if showRegionalNeighborhoods {
            overlays.append(contentsOf: loadOverlays(from: "Regional Neighborhoods"))
        }
        if showNeighborhoods {
            overlays.append(contentsOf: loadOverlays(from: "Neighborhoods"))
        }
        if showSubdivisions {
            overlays.append(contentsOf: loadOverlays(from: "Subdivisions"))
        }
        print("Updated overlays count: \(overlays.count)")
    }

    private func loadOverlays(from fileName: String) -> [MKPolygon] {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "geojson"),
              let data = try? Data(contentsOf: url) else {
            print("Failed to load \(fileName).geojson")
            return []
        }

        let loadedPolygons = GeoJSONLoader.parseGeoJSON(data: data)
        print("\(fileName): Loaded \(loadedPolygons.count) overlays.")
        return loadedPolygons
    }

    func centerToCurrentLocation() {
        if let currentLocation = LocationManager().lastLocation {
            visibleRegion = MKCoordinateRegion(
                center: currentLocation,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }
    }

    func selectPolygon(_ polygon: MKPolygon) {
        selectedPolygon = polygon
    }

    func centerMap(on polygon: MKPolygon, mapView: MKMapView) {
        let boundingRect = polygon.boundingMapRect
        mapView.setVisibleMapRect(boundingRect, edgePadding: UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50), animated: true)
    }
}
