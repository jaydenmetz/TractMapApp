import SwiftUI
import MapKit

public struct PolygonDetailsView: View {
    let polygon: MKPolygon

    public var body: some View {
        VStack {
            Text(polygon.title ?? "No Title Provided")
                .font(.headline)
                .padding()
            
            if let subtitle = polygon.subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .padding([.bottom])
            }

            Spacer()
        }
        .frame(maxHeight: .infinity)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(radius: 5)
    }
}
