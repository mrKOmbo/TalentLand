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

    private func countryDisplayName(_ country: String) -> String {
        switch country {
        case "All": return LocalizedString("venue.allCountries")
        case "Mexico": return LocalizedString("venue.mexico")
        case "USA": return LocalizedString("venue.usa")
        case "Canada": return LocalizedString("venue.canada")
        default: return country
        }
    }

    var filteredVenues: [WorldCupVenue] {
        if selectedCountry == "All" {
            return WorldCupVenue.allVenues
        } else {
            return WorldCupVenue.allVenues.filter { $0.country == selectedCountry }
        }
    }

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header — coppelDarkBlue background, coppelYellow headline
                VStack(spacing: 0) {
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color.coppelYellow)
                                .frame(width: 44, height: 44)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(LocalizedString("venue.fifa2026"))
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(Color.coppelYellow)

                            Text(String(format: LocalizedString("venue.venueCount"), filteredVenues.count))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }

                        Spacer()

                        Image(systemName: "soccerball")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color.coppelYellow)
                            .frame(width: 44, height: 44)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .background(Color.coppelDarkBlue)

                // Country filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(countries, id: \.self) { country in
                            filterChip(country: countryDisplayName(country), isSelected: selectedCountry == country) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedCountry = country
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 12)
                .background(Color.coppelBeige)

                // Venues list
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

            // Detail modal
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
                .font(.system(size: 14, weight: isSelected ? .bold : .medium, design: .rounded))
                .foregroundColor(isSelected ? .white : Color.coppelDarkBlue)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(isSelected ? Color.coppelBlue : Color.white)
                )
        }
    }

    private func venueCard(_ venue: WorldCupVenue, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                // Top color bar with venue name
                ZStack(alignment: .topTrailing) {
                    // Solid color bar (no diagonal gradients)
                    venue.primaryColor
                        .frame(height: 100)
                        .clipShape(
                            UnevenRoundedRectangle(
                                topLeadingRadius: 16,
                                bottomLeadingRadius: 0,
                                bottomTrailingRadius: 0,
                                topTrailingRadius: 16
                            )
                        )

                    // Country badge
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
                            .fill(Color.coppelDarkBlue.opacity(0.6))
                    )
                    .padding(10)

                    // Venue name centered
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
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.white.opacity(0.9))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 30)
                }

                // Details section
                VStack(spacing: 10) {
                    HStack(spacing: 12) {
                        HStack(spacing: 6) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color.coppelBlue)

                            Text(venue.capacity)
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(Color.coppelDarkBlue)
                                .lineLimit(1)
                        }

                        Spacer(minLength: 0)

                        HStack(spacing: 6) {
                            Image(systemName: "calendar.circle.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color.coppelYellow)

                            Text(venue.inauguration)
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(Color.coppelDarkBlue)
                                .lineLimit(1)
                        }

                        Spacer(minLength: 0)

                        HStack(spacing: 6) {
                            Image(systemName: "soccerball.circle.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color.coppelGreen)

                            Text("\(venue.matches.count)")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(Color.coppelDarkBlue)
                        }
                    }
                    .padding(.horizontal, 14)

                    HStack(spacing: 8) {
                        Text(LocalizedString("venue.viewDetails"))
                            .font(.system(size: 13, weight: .bold, design: .rounded))

                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(Color.coppelBlue)
                    .padding(.horizontal, 14)
                }
                .padding(.vertical, 12)
                .background(Color.white)
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.coppelBeige, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color.coppelDarkBlue.opacity(0.08), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    NavigationView {
        VenuesListView()
    }
}
