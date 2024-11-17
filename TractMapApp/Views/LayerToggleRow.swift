//
//  LayerToggleRow.swift
//  TractMapApp
//
//  Created by Jayden Metz on 11/16/24.
//

import SwiftUI

struct LayerToggleRow: View {
    let label: String
    let isSelected: Bool
    let toggleAction: () -> Void

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.black)
            Spacer()
            if isSelected {
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
            toggleAction()
        }
    }
}
