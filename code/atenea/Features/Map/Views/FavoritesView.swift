//
//  FavoritesView.swift
//  atenea
//
//  Ultra-modern favorites view with glassmorphism design
//

import SwiftUI

struct FavoriteStation: Identifiable {
    let id = UUID()
    let name: String
    let line: String
    let lineColor: Color
    let distance: String
}

struct FavoritesView: View {
    @Environment(\.dismiss) var dismiss
    @State private var favoriteStations: [FavoriteStation] = [
        FavoriteStation(name: "Zócalo", line: "2", lineColor: Color(red: 0.0, green: 0.35, blue: 0.87), distance: "2.3 km"),
        FavoriteStation(name: "Balderas", line: "1", lineColor: Color(red: 0.95, green: 0.40, blue: 0.65), distance: "1.8 km"),
        FavoriteStation(name: "Universidad", line: "3", lineColor: Color(red: 0.67, green: 0.71, blue: 0.18), distance: "5.1 km"),
    ]
    @State private var showEmptyState = false

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.95, green: 0.97, blue: 1.0),
                    Color(red: 0.98, green: 0.95, blue: 1.0)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            if favoriteStations.isEmpty && showEmptyState {
                emptyStateView
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Favoritos")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundStyle(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.orange, Color.yellow]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )

                                Text("\(favoriteStations.count) estaciones guardadas")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.gray)
                            }

                            Spacer()

                            Button(action: {
                                dismiss()
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 40, height: 40)
                                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)

                                    Image(systemName: "xmark")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                        // Quick Stats
                        HStack(spacing: 12) {
                            statCard(
                                icon: "star.fill",
                                title: "Total",
                                value: "\(favoriteStations.count)",
                                gradient: [Color.orange, Color.yellow]
                            )

                            statCard(
                                icon: "clock.fill",
                                title: "Recientes",
                                value: "3",
                                gradient: [Color.blue, Color.cyan]
                            )

                            statCard(
                                icon: "location.fill",
                                title: "Cercanas",
                                value: "2",
                                gradient: [Color.green, Color.mint]
                            )
                        }
                        .padding(.horizontal, 20)

                        // Favorites List
                        VStack(spacing: 12) {
                            ForEach(favoriteStations) { station in
                                favoriteStationCard(station: station)
                            }
                        }
                        .padding(.horizontal, 20)

                        // Add More Button
                        Button(action: {
                            // Add action
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 24, weight: .bold))

                                Text("Agregar Estación")
                                    .font(.system(size: 17, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.orange, Color.yellow]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: Color.orange.opacity(0.4), radius: 12, x: 0, y: 6)
                        }
                        .padding(.horizontal, 20)

                        Spacer(minLength: 40)
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Components

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.orange.opacity(0.3),
                                Color.yellow.opacity(0.15),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 40,
                            endRadius: 100
                        )
                    )
                    .frame(width: 180, height: 180)
                    .blur(radius: 20)

                // Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.orange, Color.yellow]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .shadow(color: Color.orange.opacity(0.4), radius: 20, x: 0, y: 10)

                    Image(systemName: "star.fill")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(.white)
                }
            }

            VStack(spacing: 12) {
                Text("Sin Favoritos")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text("Marca tus estaciones favoritas\npara acceso rápido")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }

            Button(action: {
                dismiss()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18, weight: .bold))

                    Text("Explorar Estaciones")
                        .font(.system(size: 17, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.orange, Color.yellow]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: Color.orange.opacity(0.4), radius: 12, x: 0, y: 6)
            }
        }
        .padding(20)
    }

    private func statCard(icon: String, title: String, value: String, gradient: [Color]) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: gradient.map { $0.opacity(0.15) }),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: gradient),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)

            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
        )
    }

    private func favoriteStationCard(station: FavoriteStation) -> some View {
        HStack(spacing: 16) {
            // Line indicator
            ZStack {
                // Glow effect
                Circle()
                    .fill(station.lineColor.opacity(0.3))
                    .frame(width: 56, height: 56)
                    .blur(radius: 8)

                Circle()
                    .fill(station.lineColor)
                    .frame(width: 50, height: 50)
                    .shadow(color: station.lineColor.opacity(0.5), radius: 8, x: 0, y: 4)
                    .overlay(
                        Text(station.line)
                            .font(.system(size: 20, weight: .black))
                            .foregroundColor(.white)
                    )
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(station.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)

                HStack(spacing: 8) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.gray)

                    Text(station.distance)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            VStack(spacing: 8) {
                Button(action: {
                    // Navigate action
                }) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.blue.opacity(0.15), Color.cyan.opacity(0.1)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 40, height: 40)

                        Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.blue, Color.cyan]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }

                Button(action: {
                    // Remove from favorites
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        if let index = favoriteStations.firstIndex(where: { $0.id == station.id }) {
                            favoriteStations.remove(at: index)
                        }
                    }
                }) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.red, Color.pink]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
        )
    }
}

#Preview {
    FavoritesView()
}
