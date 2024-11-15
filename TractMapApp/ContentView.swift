import SwiftUI
import MapKit

struct ContentView: View {
    @StateObject private var viewModel = MapViewModel()
    @State private var recenterTrigger = false
    @State private var selectedPolygon: MKPolygon?
    @State private var showingLayerOptions = false

    var body: some View {
        ZStack {
            if let region = viewModel.visibleRegion {
                MapView(
                    region: regionBinding,
                    overlays: viewModel.overlays,
                    annotations: viewModel.annotations,
                    recenterTrigger: $recenterTrigger,
                    onOverlayTapped: { polygon, mapView in
                        selectedPolygon = polygon
                        viewModel.centerMap(on: polygon, mapView: mapView)
                        recenterTrigger.toggle()
                    },
                    selectedPolygon: $selectedPolygon
                )
                .edgesIgnoringSafeArea(.all)
            } else {
                Text("Loading map...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            buttonsAndDropdownOverlay()
        }
        .onAppear {
            viewModel.loadGeoJSONOverlays()
        }
    }

    private var regionBinding: Binding<MKCoordinateRegion> {
        Binding(
            get: { viewModel.visibleRegion ?? MKCoordinateRegion() },
            set: { viewModel.visibleRegion = $0 }
        )
    }

    private func buttonsAndDropdownOverlay() -> some View {
        GeometryReader { _ in
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
                            .padding(.trailing, 20)
                            .padding(.bottom, 20)
                    }
                }
            }
        }
    }

    private var dropdownMenu: some View {
        VStack(spacing: 5) {
            HStack {
                Text("Regional Neighborhoods")
                    .font(.caption)
                    .foregroundColor(.black)
                Spacer()
                if viewModel.showAllOverlays {
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
                viewModel.toggleAllOverlays()
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
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
