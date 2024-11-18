import Foundation
import MapKit
import Combine

class MapViewModel: ObservableObject {
    @Published var lastLocation: CLLocationCoordinate2D?
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
    @Published var regionUpdateTrigger = UUID()

    private var locationManager: LocationManager
    private var cancellables: Set<AnyCancellable> = []

    init() {
        locationManager = LocationManager()
        bindToLocationUpdates()
    }

    private func bindToLocationUpdates() {
        locationManager.$lastLocation
            .sink { [weak self] location in
                guard let self = self else { return }
                self.lastLocation = location
                self.updateVisibleRegionIfNeeded()
            }
            .store(in: &cancellables)
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
        if let currentLocation = lastLocation {
            visibleRegion = MKCoordinateRegion(
                center: currentLocation,
                span: MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001)
            )
            print("Centered on current location: \(currentLocation)")
        } else {
            print("Current location not available.")
        }
    }

    func selectPolygon(_ polygon: MKPolygon) {
        selectedPolygon = polygon
    }

    func centerMap(on polygon: MKPolygon, mapView: MKMapView) {
        let mapRect = polygon.boundingMapRect
        let padding: CGFloat = 10

        // Calculate the visible portion of the screen
        let screenHeight = UIScreen.main.bounds.height
        let topHalfHeight = screenHeight / 2

        let edgePadding = UIEdgeInsets(
            top: padding,
            left: padding,
            bottom: screenHeight - topHalfHeight + padding,
            right: padding
        )

        let adjustedMapRect = mapView.mapRectThatFits(mapRect, edgePadding: edgePadding)

        // Update the visible region
        visibleRegion = mapView.regionThatFits(MKCoordinateRegion(adjustedMapRect))
    }
    
    private func updateVisibleRegionIfNeeded() {
        guard let currentLocation = lastLocation,
              visibleRegion == nil || !isLocationInVisibleRegion(currentLocation) else { return }
        centerToCurrentLocation()
    }

    private func isLocationInVisibleRegion(_ location: CLLocationCoordinate2D) -> Bool {
        guard let region = visibleRegion else { return false }

        let latRange = (region.center.latitude - region.span.latitudeDelta / 2)...(region.center.latitude + region.span.latitudeDelta / 2)
        let lonRange = (region.center.longitude - region.span.longitudeDelta / 2)...(region.center.longitude + region.span.longitudeDelta / 2)

        return latRange.contains(location.latitude) && lonRange.contains(location.longitude)
    }
}
