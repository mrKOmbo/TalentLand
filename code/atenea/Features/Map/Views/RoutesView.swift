//
//  RoutesView.swift
//  atenea
//
//  Vista de rutas guardadas y favoritas
//

import SwiftUI

struct RoutesView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            Text(LocalizedString("routes.title"))
                .font(.system(size: 24, weight: .bold))

            Text(LocalizedString("routes.savedRoutes"))
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

#Preview {
    RoutesView()
}
