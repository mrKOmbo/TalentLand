//
//  VenuesListView.swift
//  atenea
//
//  Coppel Brand Toolkit 2024 — FIFA World Cup 2026 venues
//

import SwiftUI
import MapKit

struct VenuesListView: View {
    @State private var selectedCountry: String = "All"
    @State private var selectedVenue: WorldCupVenue?
    @State private var showVenueDetail = false
    @Environment(\.dismiss) private var dismiss

    let countries = ["All", "Mexico", "USA", "Canada"]

    var filteredVenues: [WorldCupVenue] {
        if selectedCountry == "All" {
            return WorldCupVenue.allVenues
        } else {
            return WorldCupVenue.allVenues.filter { $0.country == selectedCountry }
        }
    }

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color.coppelDarkBlue)
                            .frame(width: 40, height: 40)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("FIFA 2026")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(Color.coppelDarkBlue)

                        Text("\(filteredVenues.count) venues")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.gray)
                    }

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                // Country Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(countries, id: \.self) { country in
                            filterChip(country: country, isSelected: selectedCountry == country) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedCountry = country
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 12)

                // Venues List
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredVenues, id: \.id) { venue in
                            venueCard(venue) {
                                selectedVenue = venue
                                showVenueDetail = true
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }

            // Detail Modal
            if showVenueDetail, let venue = selectedVenue {
                VenueDetailView(
                    venue: venue,
                    isPresented: $showVenueDetail,
                    onDismiss: { selectedVenue = nil },
                    onGetDirections: {
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
    }

    private func filterChip(country: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(country)
                .font(.system(size: 14, weight: isSelected ? .semibold : .medium, design: .rounded))
                .foregroundColor(isSelected ? .white : Color(red: 0.05, green: 0.09, blue: 0.33))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(isSelected ? Color(red: 0.11, green: 0.26, blue: 0.91) : Color.gray.opacity(0.1))
                )
        }
    }

    private func venueCard(_ venue: WorldCupVenue, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                // Top with gradient
                ZStack(alignment: .topTrailing) {
                    venue.gradient
                        .frame(height: 100)
                        .clipShape(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                        )
                        .overlay(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.black.opacity(0.2),
                                    Color.clear
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .clipShape(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                            )
                        )

                    HStack(spacing: 4) {
                        Image(systemName: "flag.fill")
                            .font(.system(size: 10, weight: .bold))

                        Text(venue.country)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.3))
                    )
                    .padding(10)

                    VStack(spacing: 4) {
                        Text(venue.name)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)

                        HStack(spacing: 4) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 10))

                            Text(venue.city)
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(.white.opacity(0.9))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 30)
                }

                // Details
                VStack(spacing: 10) {
                    HStack(spacing: 12) {
                        HStack(spacing: 6) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color.coppelBlue)

                            Text(venue.capacity)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color.coppelDarkBlue)
                                .lineLimit(1)
                        }

                        Spacer(minLength: 0)

                        HStack(spacing: 6) {
                            Image(systemName: "calendar.circle.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color.coppelYellow)

                            Text(venue.inauguration)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color.coppelDarkBlue)
                                .lineLimit(1)
                        }

                        Spacer(minLength: 0)

                        HStack(spacing: 6) {
                            Image(systemName: "soccerball.circle.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color.coppelGreen)

                            Text("\(venue.matches.count)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color.coppelDarkBlue)
                        }
                    }
                    .padding(.horizontal, 14)

                    HStack(spacing: 8) {
                        Text("View details")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))

                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(Color(red: 0.11, green: 0.26, blue: 0.91))
                    .padding(.horizontal, 14)
                }
                .padding(.vertical, 12)
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.systemBackground))
                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    NavigationView {
        VenuesListView()
    }
}
