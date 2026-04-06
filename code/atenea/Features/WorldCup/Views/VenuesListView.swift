//
//  VenuesListView.swift
//  Atenea
//
//  Created by Claude on 10/29/25.
//

import SwiftUI
import MapKit

struct VenuesListView: View {
    @State private var selectedCountry: String = "Todos"
    @State private var selectedVenue: WorldCupVenue?
    @State private var showVenueDetail = false
    @Environment(\.dismiss) private var dismiss

    let countries = ["Todos", "México", "USA", "Canadá"]

    var filteredVenues: [WorldCupVenue] {
        if selectedCountry == "Todos" {
            return WorldCupVenue.allVenues
        } else {
            return WorldCupVenue.allVenues.filter { $0.country == selectedCountry }
        }
    }

    var body: some View {
        ZStack {
            // Fondo degradado
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "#1a1a2e"),
                    Color(hex: "#16213e")
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                ZStack {
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(
                                    Circle()
                                        .fill(Color.white.opacity(0.1))
                                )
                        }
                        Spacer()
                    }

                    VStack(spacing: 4) {
                        Text("Sedes FIFA 2026")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                        Text("\(filteredVenues.count) estadios")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 15)

                // Filtros de país
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(countries, id: \.self) { country in
                            CountryFilterChip(
                                country: country,
                                isSelected: selectedCountry == country,
                                action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedCountry = country
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 20)

                // Lista de sedes
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredVenues, id: \.id) { venue in
                            VenueCard(venue: venue) {
                                selectedVenue = venue
                                showVenueDetail = true
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }

            // Modal de detalle
            if showVenueDetail, let venue = selectedVenue {
                VenueDetailView(
                    venue: venue,
                    isPresented: $showVenueDetail,
                    onDismiss: {
                        selectedVenue = nil
                    },
                    onGetDirections: {
                        // Abrir Apple Maps como fallback
                        let coordinate = venue.coordinate
                        let placemark = MKPlacemark(coordinate: coordinate)
                        let mapItem = MKMapItem(placemark: placemark)
                        mapItem.name = venue.name
                        mapItem.openInMaps(launchOptions: [
                            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
                        ])
                    }
                )
                .transition(.opacity)
            }
        }
        .navigationBarHidden(true)
    }
}

// Chip de filtro de país
struct CountryFilterChip: View {
    let country: String
    let isSelected: Bool
    let action: () -> Void

    var flagEmoji: String {
        switch country {
        case "México": return "🇲🇽"
        case "USA": return "🇺🇸"
        case "Canadá": return "🇨🇦"
        default: return "🌎"
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(flagEmoji)
                    .font(.system(size: 16))
                Text(country)
                    .font(.system(size: 14, weight: isSelected ? .bold : .medium))
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.7))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ?
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hex: "#00a8ff"),
                                Color(hex: "#0097e6")
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ) :
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.1),
                                Color.white.opacity(0.05)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        isSelected ? Color.clear : Color.white.opacity(0.2),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: isSelected ? Color(hex: "#00a8ff").opacity(0.3) : .clear,
                radius: 8,
                x: 0,
                y: 4
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Tarjeta de sede
struct VenueCard: View {
    let venue: WorldCupVenue
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                // Header con gradiente de colores de la sede
                ZStack(alignment: .topTrailing) {
                    venue.gradient
                        .frame(height: 120)
                        .overlay(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.black.opacity(0.3),
                                    Color.clear
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    // Badge de país
                    HStack(spacing: 4) {
                        Image(systemName: "flag.fill")
                            .font(.system(size: 10))
                        Text(venue.country)
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.3))
                            .background(
                                Capsule()
                                    .fill(.ultraThinMaterial)
                            )
                    )
                    .padding(12)

                    // Nombre del estadio (centrado)
                    VStack(spacing: 4) {
                        Text(venue.name)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)

                        HStack(spacing: 4) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 11))
                            Text(venue.city)
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(.white.opacity(0.9))
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                }

                // Información del estadio
                VStack(spacing: 12) {
                    HStack(spacing: 20) {
                        // Capacidad
                        VStack(spacing: 4) {
                            Image(systemName: "person.3.fill")
                                .font(.system(size: 16))
                                .foregroundColor(venue.primaryColor)
                            Text(venue.capacity)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                        }

                        Divider()
                            .frame(height: 30)
                            .background(Color.white.opacity(0.2))

                        // Inauguración
                        VStack(spacing: 4) {
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 16))
                                .foregroundColor(venue.primaryColor)
                            Text(venue.inauguration)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                        }

                        Divider()
                            .frame(height: 30)
                            .background(Color.white.opacity(0.2))

                        // Partidos
                        VStack(spacing: 4) {
                            Image(systemName: "soccerball.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(venue.primaryColor)
                            Text("\(venue.matches.count) partidos")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal, 20)

                    // Botón de ver más
                    HStack {
                        Text("Ver detalles")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(venue.primaryColor)
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(venue.primaryColor)
                    }
                    .padding(.bottom, 4)
                }
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 0)
                        .fill(Color.white.opacity(0.05))
                )
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: venue.primaryColor.opacity(0.2), radius: 10, x: 0, y: 5)
            .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    NavigationView {
        VenuesListView()
    }
}
