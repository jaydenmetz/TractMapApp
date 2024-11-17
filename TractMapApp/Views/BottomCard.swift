import SwiftUI
import MapKit

struct BottomCard: View {
    var polygon: MKPolygon?
    @Binding var cardPosition: CGFloat

    var body: some View {
        VStack {
            HandleBar(title: polygon?.title ?? "Demo") // Pass the title here
            if let polygon = polygon {
                Text(polygon.title ?? "No Title Provided")
                    .font(.headline)
                    .padding()
            } else {
                Text("Select a region for more details")
                    .padding()
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(radius: 5)
    }
}

struct HandleBar: View {
    let title: String

    var body: some View {
        VStack(spacing: 8) {
            Capsule()
                .frame(width: 40, height: 5)
                .foregroundColor(.gray)
                .padding(.top, 5)

            Text(title) // Display the title
                .font(.headline)
                .foregroundColor(.black)
                .padding()
        }
    }
}

struct CardContent: View {
    var polygon: MKPolygon?

    var body: some View {
        if let polygon = polygon {
            PolygonDetailsView(polygon: polygon)
        } else {
            Text("Select a region for more details")
                .padding()
        }
    }
}

