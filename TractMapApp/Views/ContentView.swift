import SwiftUI
import MapKit

struct ContentView: View {
    @ObservedObject private var viewModel = MapViewModel()
    @StateObject private var locationManager = LocationManager()
    @State private var recenterTrigger = false
    @State private var showingLayerOptions = false

    // Define the positions
    private let topPosition: CGFloat = UIScreen.main.bounds.height * 0.05
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
                        get: { region },
                        set: { viewModel.visibleRegion = $0 }
                    ),
                    overlays: viewModel.overlays,
                    annotations: viewModel.annotations,
                    recenterTrigger: $recenterTrigger,
                    onOverlayTapped: { polygon, mapView in
                        viewModel.selectPolygon(polygon)
                        viewModel.centerMap(on: polygon, mapView: mapView)
                        recenterTrigger.toggle()
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
                viewModel.visibleRegion = MKCoordinateRegion(
                    center: location,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
            }
        }
    }

    private func updateRegionToUserLocation() {
        if let userLocation = locationManager.lastLocation {
            viewModel.visibleRegion = MKCoordinateRegion(
                center: userLocation,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        } else {
            locationManager.requestCurrentLocation()
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
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    recenterTrigger.toggle()
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
}
