//
//  OverlayDetailView.swift
//  TractMapApp
//
//  Created by Jayden Metz on 10/31/24.
//

import SwiftUI

struct OverlayDetailView: View {
    let overlay: IdentifiableOverlay
    let onDismiss: () -> Void

    var body: some View {
        VStack {
            Spacer()
            VStack {
                Text(overlay.name)
                    .font(.headline)
                    .padding(.top)

                Text("Additional details about \(overlay.name) go here.")
                    .font(.subheadline)
                    .padding()

                Button(action: onDismiss) {
                    Text("Dismiss")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.bottom)
            }
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(radius: 10)
            .padding()
        }
        .edgesIgnoringSafeArea(.bottom)
    }
}
