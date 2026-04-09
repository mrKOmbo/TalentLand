//
//  VenueDetailView.swift
//  Atenea
//
//  Coppel Brand Toolkit 2024 — Venue detail modal
//

import SwiftUI
import MapKit

struct VenueDetailView: View {
    let venue: WorldCupVenue
    @Binding var isPresented: Bool
    @State private var funFactsExpanded = false
    @State private var matchesExpanded = true
    @State private var dragOffset: CGFloat = 0
    var onDismiss: (() -> Void)?
    var onGetDirections: (() -> Void)?

    private func openInMaps() {
        let coordinate = venue.coordinate
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = venue.name
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .center) {
                // Background overlay
                Color.coppelDarkBlue.opacity(0.5)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isPresented = false
                            onDismiss?()
                        }
                    }
                    .zIndex(0)

                // Panel
                VStack(spacing: 0) {
                    // Soccer ball pin
                    VStack(spacing: 0) {
                        ZStack {
                            Circle()
                                .fill(venue.primaryColor)
                                .frame(width: 48, height: 48)

                            Circle()
                                .stroke(Color.white, lineWidth: 3)
                                .frame(width: 48, height: 48)

                            Image(systemName: "soccerball.circle.fill")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .offset(y: 12)

                        Rectangle()
                            .fill(venue.primaryColor)
                            .frame(width: 3, height: 12)
                    }
                    .zIndex(10)

                    // Card content
                    VStack(spacing: 0) {
                        // Header — venue color background
                        ZStack {
                            venue.primaryColor

                            VStack(spacing: 8) {
                                // Drag handle
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white.opacity(0.5))
                                    .frame(width: 50, height: 5)
                                    .padding(.top, 10)
                                    .padding(.bottom, 10)
                                    .gesture(
                                        DragGesture()
                                            .onChanged { value in
                                                if value.translation.height > 0 {
                                                    dragOffset = value.translation.height
                                                }
                                            }
                                            .onEnded { value in
                                                if value.translation.height > 100 {
                                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                                        isPresented = false
                                                        onDismiss?()
                                                    }
                                                    dragOffset = 0
                                                } else {
                                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                                        dragOffset = 0
                                                    }
                                                }
                                            }
                                    )

                                VStack(spacing: 6) {
                                    Text(venue.name)
                                        .font(.system(size: 22, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(2)
                                        .minimumScaleFactor(0.8)

                                    HStack(spacing: 6) {
                                        Image(systemName: "mappin.circle.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white.opacity(0.9))
                                        Text("\(venue.city), \(venue.country)")
                                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                                            .foregroundColor(.white.opacity(0.95))
                                    }

                                    // Capacity and inauguration capsules
                                    HStack(spacing: 16) {
                                        HStack(spacing: 5) {
                                            Image(systemName: "person.3.fill")
                                                .font(.system(size: 11))
                                            Text(venue.capacity)
                                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(
                                            Capsule()
                                                .fill(Color.white.opacity(0.2))
                                        )

                                        HStack(spacing: 5) {
                                            Image(systemName: "calendar")
                                                .font(.system(size: 11))
                                            Text(venue.inauguration)
                                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(
                                            Capsule()
                                                .fill(Color.white.opacity(0.2))
                                        )
                                    }
                                    .foregroundColor(.white.opacity(0.9))

                                    // Get directions button — coppelYellow CTA
                                    Button(action: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            isPresented = false
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            onGetDirections?()
                                        }
                                    }) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "location.fill")
                                                .font(.system(size: 14, weight: .semibold))
                                            Text(LocalizedString("venue.howToGet"))
                                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                        }
                                        .foregroundColor(Color.coppelDarkBlue)
                                        .frame(maxWidth: 200)
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .fill(Color.coppelYellow)
                                        )
                                    }
                                    .padding(.top, 10)
                                }
                                .padding(.horizontal, 14)
                                .padding(.bottom, 8)
                            }
                        }

                        // Scrollable content — white/beige light background
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 16) {
                                // Matches section
                                VStack(spacing: 0) {
                                    Button(action: {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                            matchesExpanded.toggle()
                                        }
                                    }) {
                                        HStack(spacing: 10) {
                                            Image(systemName: "soccerball.circle.fill")
                                                .font(.system(size: 18))
                                                .foregroundColor(Color.coppelBlue)

                                            Text(LocalizedString("venue.matches"))
                                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                                .foregroundColor(Color.coppelDarkBlue)

                                            Text("\(venue.matches.count)")
                                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 4)
                                                .background(
                                                    Capsule()
                                                        .fill(Color.coppelBlue)
                                                )

                                            Spacer()

                                            Image(systemName: matchesExpanded ? "chevron.up" : "chevron.down")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(Color.coppelDarkGrey)
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 14)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.white)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(Color.coppelBeige, lineWidth: 1)
                                                )
                                        )
                                        .padding(.horizontal, 12)
                                    }
                                    .buttonStyle(PlainButtonStyle())

                                    if matchesExpanded {
                                        VStack(spacing: 10) {
                                            ForEach(Array(venue.matches.prefix(3).enumerated()), id: \.element.id) { index, match in
                                                CompactMatchCard(match: match, color: venue.primaryColor, index: index + 1)
                                            }
                                            if venue.matches.count > 3 {
                                                Text(String(format: LocalizedString("venue.moreMatches"), venue.matches.count - 3))
                                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                                    .foregroundColor(Color.coppelDarkGrey)
                                                    .padding(.vertical, 6)
                                                    .padding(.horizontal, 16)
                                                    .background(
                                                        Capsule()
                                                            .fill(Color.coppelBeige)
                                                    )
                                            }
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.top, 10)
                                        .transition(.opacity.combined(with: .move(edge: .top)))
                                    }
                                }

                                // Fun facts section
                                VStack(spacing: 0) {
                                    Button(action: {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                            funFactsExpanded.toggle()
                                        }
                                    }) {
                                        HStack(spacing: 10) {
                                            Image(systemName: "lightbulb.fill")
                                                .font(.system(size: 18))
                                                .foregroundColor(Color.coppelYellow)

                                            Text(LocalizedString("venue.funFacts"))
                                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                                .foregroundColor(Color.coppelDarkBlue)

                                            Text("\(venue.funFacts.count)")
                                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 4)
                                                .background(
                                                    Capsule()
                                                        .fill(Color.coppelBlue)
                                                )

                                            Spacer()

                                            Image(systemName: funFactsExpanded ? "chevron.up" : "chevron.down")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(Color.coppelDarkGrey)
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 14)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.white)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(Color.coppelBeige, lineWidth: 1)
                                                )
                                        )
                                        .padding(.horizontal, 12)
                                    }
                                    .buttonStyle(PlainButtonStyle())

                                    if funFactsExpanded {
                                        VStack(spacing: 10) {
                                            ForEach(Array(venue.funFacts.prefix(2).enumerated()), id: \.offset) { index, fact in
                                                CompactFunFactCard(fact: fact, index: index + 1, color: venue.primaryColor)
                                            }
                                            if venue.funFacts.count > 2 {
                                                Text(String(format: LocalizedString("venue.moreFacts"), venue.funFacts.count - 2))
                                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                                    .foregroundColor(Color.coppelDarkGrey)
                                                    .padding(.vertical, 6)
                                                    .padding(.horizontal, 16)
                                                    .background(
                                                        Capsule()
                                                            .fill(Color.coppelBeige)
                                                    )
                                            }
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.top, 10)
                                        .transition(.opacity.combined(with: .move(edge: .top)))
                                    }
                                }

                                Color.clear.frame(height: 4)
                            }
                            .padding(.top, 12)
                        }
                        .frame(maxHeight: 280)
                        .background(Color.coppelBeige.opacity(0.5))

                        // Close button
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                isPresented = false
                                onDismiss?()
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16))
                                Text(LocalizedString("venue.close"))
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(Color.coppelDarkBlue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.coppelBeige)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color.white)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color.white)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.coppelBeige, lineWidth: 1)
                    )
                    .shadow(color: Color.coppelDarkBlue.opacity(0.2), radius: 20, x: 0, y: 8)
                }
                .frame(maxWidth: 380, maxHeight: 620)
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
                .offset(y: dragOffset)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(1)
            }
        }
    }
}

// MARK: - Match card — light Coppel theme
struct CompactMatchCard: View {
    let match: WorldCupMatch
    let color: Color
    let index: Int

    var body: some View {
        HStack(spacing: 10) {
            // Match number
            ZStack {
                Circle()
                    .fill(Color.coppelBlue)
                    .frame(width: 38, height: 38)

                Text("\(index)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(match.stage)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(Color.coppelBlue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(Color.coppelBlue.opacity(0.10))
                    )

                Text(match.date)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.coppelDarkBlue)

                if match.time != "Por definir" {
                    Text(match.time)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(Color.coppelDarkGrey)
                }

                if match.teams != "Por definir" {
                    Text(match.teams)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(Color.coppelDarkGrey)
                        .lineLimit(1)
                }
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.coppelBeige, lineWidth: 1)
                )
        )
        .shadow(color: Color.coppelDarkBlue.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Fun fact card — light Coppel theme
struct CompactFunFactCard: View {
    let fact: String
    let index: Int
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.coppelYellow.opacity(0.2))
                    .frame(width: 32, height: 32)

                Text("\(index)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color.coppelDarkBlue)
            }
            .padding(.top, 2)

            Text(fact)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(Color.coppelDarkBlue)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(3)

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.coppelBeige, lineWidth: 1)
                )
        )
        .shadow(color: Color.coppelDarkBlue.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    ZStack {
        Color.coppelBeige
            .ignoresSafeArea()

        VenueDetailView(
            venue: WorldCupVenue.allVenues[1],
            isPresented: .constant(true)
        )
    }
}
