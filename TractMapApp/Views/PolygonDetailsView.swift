import SwiftUI
import MapKit

public struct PolygonDetailsView: View {
    let polygon: MKPolygon
    @State private var cardPosition: CardPosition = .collapsed
    @State private var dragOffset: CGFloat = 0

    public var body: some View {
        VStack {
            HandleBar(title: polygon.title ?? "Selected Polygon")

            if let subtitle = polygon.subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .padding([.bottom])
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(radius: 5)
        .offset(y: computedOffset())
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation.height
                }
                .onEnded { _ in
                    updateCardPosition()
                    dragOffset = 0
                }
        )
    }

    private func computedOffset() -> CGFloat {
        let baseOffset: CGFloat
        switch cardPosition {
        case .collapsed:
            baseOffset = UIScreen.main.bounds.height - 150
        case .half:
            baseOffset = UIScreen.main.bounds.height / 2
        case .expanded:
            baseOffset = 100
        }
        return baseOffset + dragOffset
    }

    private func updateCardPosition() {
        withAnimation {
            if dragOffset > 50 {
                cardPosition = cardPosition == .half ? .collapsed : .half
            } else if dragOffset < -50 {
                cardPosition = cardPosition == .half ? .expanded : .half
            }
        }
    }
}

enum CardPosition {
    case collapsed
    case half
    case expanded
}
