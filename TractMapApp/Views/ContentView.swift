import SwiftUI
import MapKit

struct ContentView: View {
    @ObservedObject private var viewModel = MapViewModel()
    @StateObject private var locationManager = LocationManager()
    @State private var recenterTrigger = false
    @State private var showingLayerOptions = false

    // Define the positions
    private let topPosition: CGFloat = UIScreen.main.bounds.height * 0.15
    private let halfwayPosition: CGFloat = UIScreen.main.bounds.height * 0.5
    private let bottomPosition: CGFloat = UIScreen.main.bounds.height * 0.85

    @State private var cardPosition: CGFloat = UIScreen.main.bounds.height * 0.85
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        ZStack {
            // Map view
            if let region = viewModel.visibleRegion {
                MapView(
                    region: Binding(
                        get: { viewModel.visibleRegion ?? MKCoordinateRegion() },
                        set: { newRegion in
                            if !areRegionsEqual(region1: newRegion, region2: viewModel.visibleRegion) {
                                viewModel.visibleRegion = newRegion
                            }
                        }
                    ),
                    overlays: viewModel.overlays.sorted(by: {
                        (extractZIndex(from: $0) ?? 0) > (extractZIndex(from: $1) ?? 0)
                    }),
                    annotations: viewModel.annotations,
                    recenterTrigger: $recenterTrigger,
                    onOverlayTapped: { polygon, mapView in
                        viewModel.selectPolygon(polygon)
                        viewModel.centerMap(on: polygon, mapView: mapView)
                        recenterTrigger.toggle()
                        showingLayerOptions = false
                        withAnimation {
                            cardPosition = halfwayPosition
                        }
                    },
                    selectedPolygon: $viewModel.selectedPolygon
                )
                .edgesIgnoringSafeArea(.all)
            } else {
                Text("Loading map...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // Bottom card
            BottomCard(polygon: viewModel.selectedPolygon, cardPosition: $cardPosition)
                .offset(y: max(cardPosition + dragOffset, topPosition))
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            dragOffset = gesture.translation.height
                        }
                        .onEnded { _ in
                            withAnimation {
                                if dragOffset > 50 {
                                    cardPosition = cardPosition == halfwayPosition ? bottomPosition : halfwayPosition
                                } else if dragOffset < -50 {
                                    cardPosition = cardPosition == halfwayPosition ? topPosition : halfwayPosition
                                }
                                dragOffset = 0
                            }
                        }
                )

            // Buttons and dropdown
            buttonsAndDropdownOverlay()
                .offset(y: cardPosition - UIScreen.main.bounds.height + 75 + dragOffset)
        }
        .onAppear {
            viewModel.loadGeoJSONIfNeeded()
            updateRegionToUserLocation()
        }
        .onReceive(locationManager.$lastLocation) { newLocation in
            if let location = newLocation {
                handleLocationUpdate(location)
            }
        }
    }

    private func areRegionsEqual(region1: MKCoordinateRegion?, region2: MKCoordinateRegion?) -> Bool {
        guard let region1 = region1, let region2 = region2 else { return false }
        let epsilon = 0.00001
        return abs(region1.center.latitude - region2.center.latitude) < epsilon &&
               abs(region1.center.longitude - region2.center.longitude) < epsilon &&
               abs(region1.span.latitudeDelta - region2.span.latitudeDelta) < epsilon &&
               abs(region1.span.longitudeDelta - region2.span.longitudeDelta) < epsilon
    }
    
    private func updateRegionToUserLocation() {
        if let userLocation = locationManager.lastLocation {
            viewModel.visibleRegion = MKCoordinateRegion(
                center: userLocation,
                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005) // Zoomed-in view
            )
        } else {
            locationManager.startContinuousLocationUpdates()
        }
    }

    private func handleLocationUpdate(_ location: CLLocationCoordinate2D) {
        if viewModel.selectedPolygon == nil {
            guard let currentRegion = viewModel.visibleRegion else {
                viewModel.visibleRegion = MKCoordinateRegion(
                    center: location,
                    span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                )
                return
            }

            let visibleMapRect = currentRegion.toMKMapRect()
            let currentLocationPoint = MKMapPoint(location)

            if !visibleMapRect.contains(currentLocationPoint) {
                withAnimation {
                    viewModel.visibleRegion = MKCoordinateRegion(
                        center: location,
                        span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                    )
                }
            }
        }
    }

    private func buttonsAndDropdownOverlay() -> some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                VStack(alignment: .trailing) {
                    if showingLayerOptions {
                        Spacer()
                        dropdownMenu
                            .frame(width: 180)
                            .padding(.trailing, 15)
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                    buttonStack
                }
            }
        }
    }

    private var dropdownMenu: some View {
        VStack(spacing: 5) {
            toggleButton(label: "Regional Neighborhoods", isOn: $viewModel.showRegionalNeighborhoods)
            toggleButton(label: "Neighborhoods", isOn: $viewModel.showNeighborhoods)
            toggleButton(label: "Subdivisions", isOn: $viewModel.showSubdivisions)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
    }

    private func toggleButton(label: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.black)
            Spacer()
            if isOn.wrappedValue {
                Image(systemName: "checkmark.square.fill")
                    .foregroundColor(.blue)
            } else {
                Image(systemName: "square")
                    .foregroundColor(.gray)
            }
        }
        .contentShape(Rectangle())
        .padding(5)
        .background(Color.white)
        .cornerRadius(8)
        .onTapGesture {
            isOn.wrappedValue.toggle()
        }
    }

    private var buttonStack: some View {
        VStack(spacing: 15) {
            Button(action: {
                withAnimation {
                    showingLayerOptions.toggle()
                }
            }) {
                Image(systemName: "map")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.green)
                    .clipShape(Circle())
                    .shadow(radius: 4)
            }

            Button(action: {
                viewModel.centerToCurrentLocation()
                locationManager.startContinuousLocationUpdates()
                
                withAnimation {
                    cardPosition = bottomPosition
                }
            }) {
                Image(systemName: "location.fill")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .clipShape(Circle())
                    .shadow(radius: 4)
            }
        }
        .fixedSize()
    }

    private func extractZIndex(from overlay: MKOverlay) -> Int? {
        guard let polygon = overlay as? MKPolygon,
              let subtitle = polygon.subtitle,
              let zString = subtitle.split(separator: ";").first(where: { $0.starts(with: "z:") })?.split(separator: ":").last,
              let zIndex = Int(zString) else { return nil }
        return zIndex
    }
}
