//
//  UltraThinkRecommendationsView.swift
//  Atenea
//
//  Vista modal completa para mostrar recomendaciones contextuales avanzadas
//

import SwiftUI
import MapKit

struct UltraThinkRecommendationsView: View {
    @Binding var isPresented: Bool
    @StateObject private var viewModel = UltraThinkViewModel()

    var onNavigateToLocation: ((CLLocationCoordinate2D, String) -> Void)?
    var onShowDirections: ((CLLocationCoordinate2D, String) -> Void)?
    var userLocation: CLLocationCoordinate2D?

    @State private var showAPIKeyAlert = false
    @State private var selectedRecommendation: UltraThinkRecommendation?

    var body: some View {
        NavigationView {
            ZStack {
                // Fondo con degradado
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.05, blue: 0.15),
                        Color(red: 0.1, green: 0.1, blue: 0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                if viewModel.isAnalyzing {
                    loadingView
                } else if let error = viewModel.errorMessage {
                    errorView(error: error)
                } else if let analysis = viewModel.currentAnalysis {
                    analysisContentView(analysis: analysis)
                } else {
                    initialView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text(LocalizedString("ultrathink.title"))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .alert(LocalizedString("ultrathink.apiKeyRequired"), isPresented: $showAPIKeyAlert) {
                Button(LocalizedString("action.close"), role: .cancel) {
                    isPresented = false
                }
            } message: {
                Text(LocalizedString("ultrathink.apiKeyMessage"))
            }
        }
        .onAppear {
            if viewModel.hasValidAPIKey() {
                Task {
                    await generateInitialAnalysis()
                }
            } else {
                showAPIKeyAlert = true
            }
        }
    }

    // MARK: - Initial View

    private var initialView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "brain.head.profile")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .blue, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .purple.opacity(0.5), radius: 20)

            Text(LocalizedString("ultrathink.title"))
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text(LocalizedString("ultrathink.advancedAnalysis"))
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.7))

            Spacer()

            Button(action: {
                Task {
                    await generateInitialAnalysis()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16))
                    Text(LocalizedString("ultrathink.generateRecommendations"))
                        .font(.system(size: 18, weight: .semibold))
                    Image(systemName: "sparkles")
                        .font(.system(size: 16))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: .purple.opacity(0.5), radius: 10, x: 0, y: 5)
            }
            .buttonStyle(ActionButtonPressStyle())
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(x: 1.5, y: 1.5)
                .tint(.white)

            Text(LocalizedString("ultrathink.analyzingContext"))
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white.opacity(0.9))

            Text(LocalizedString("ultrathink.analyzingSubtitle"))
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    // MARK: - Error View

    private func errorView(error: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)

            Text(LocalizedString("ultrathink.errorGenerating"))
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.white)

            Text(error)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button(action: {
                Task {
                    await generateInitialAnalysis()
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14))
                    Text(LocalizedString("ultrathink.retry"))
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Color.blue, Color.blue.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(14)
                .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(ActionButtonPressStyle())
        }
    }

    // MARK: - Analysis Content View

    private func analysisContentView(analysis: UltraThinkAnalysis) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                contextHeaderView(analysis: analysis)
                contextSummaryCard(summary: analysis.contextSummary)

                Text(LocalizedString("ultrathink.recommendations"))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)

                ForEach(analysis.recommendations.sorted(by: { $0.priority > $1.priority })) { recommendation in
                    RecommendationCard(
                        recommendation: recommendation,
                        onTap: {
                            selectedRecommendation = recommendation
                        },
                        onNavigate: {
                            if let location = recommendation.location {
                                onNavigateToLocation?(location.coordinate, recommendation.title)
                                isPresented = false
                            }
                        },
                        onDirections: {
                            if let location = recommendation.location {
                                onShowDirections?(location.coordinate, recommendation.title)
                                isPresented = false
                            }
                        }
                    )
                    .padding(.horizontal, 20)
                }

                refreshButton
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
            }
            .padding(.top, 20)
        }
    }

    // MARK: - Context Header

    private func contextHeaderView(analysis: UltraThinkAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "location.fill")
                    .foregroundColor(.cyan)
                if let location = analysis.userLocation {
                    Text(location.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }
            }

            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.orange)
                    Text(analysis.timeContext.capitalized)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }

                if let weather = analysis.weatherContext {
                    HStack(spacing: 6) {
                        Image(systemName: "cloud.sun.fill")
                            .foregroundColor(.yellow)
                        Text(weather)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Context Summary Card

    private func contextSummaryCard(summary: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "brain")
                    .foregroundColor(.purple)
                Text(LocalizedString("ultrathink.contextAnalysis"))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }

            Text(summary)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
                .lineSpacing(4)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
    }

    // MARK: - Refresh Button

    private var refreshButton: some View {
        Button(action: {
            Task {
                await generateInitialAnalysis()
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 15, weight: .semibold))
                Text(LocalizedString("ultrathink.refreshAnalysis"))
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [
                        Color.purple.opacity(0.6),
                        Color.purple.opacity(0.4)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Color.purple.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(ActionButtonPressStyle())
    }

    // MARK: - Helper Methods

    private func generateInitialAnalysis() async {
        let locationName = await getLocationName(for: userLocation)
        let weatherInfo = getWeatherContext(for: userLocation)

        await viewModel.generateAnalysis(
            userLocation: userLocation,
            locationName: locationName,
            weatherCondition: weatherInfo,
            userPreferences: nil
        )
    }

    private func getWeatherContext(for coordinate: CLLocationCoordinate2D?) -> String {
        guard let coordinate = coordinate else {
            return "Clima templado"
        }

        let calendar = Calendar.current
        let month = calendar.component(.month, from: Date())
        let hour = calendar.component(.hour, from: Date())

        // Determinar si es zona tropical, templada o fría basado en latitud
        let latitude = abs(coordinate.latitude)

        var baseWeather = ""
        var temperature = ""
        var condition = ""

        // Determinar clima base por latitud
        if latitude < 23.5 {
            // Zona tropical
            if month >= 5 && month <= 10 {
                baseWeather = "Temporada de lluvias"
                condition = "Posibles lluvias por la tarde"
            } else {
                baseWeather = "Temporada seca"
                condition = "Clima soleado"
            }
            temperature = "Temperatura cálida (25-30°C)"
        } else if latitude < 40 {
            // Zona templada
            if month >= 6 && month <= 8 {
                baseWeather = "Verano"
                temperature = "Temperatura cálida (20-28°C)"
                condition = "Clima mayormente soleado"
            } else if month >= 12 || month <= 2 {
                baseWeather = "Invierno"
                temperature = "Temperatura fresca (10-18°C)"
                condition = "Clima fresco"
            } else if month >= 3 && month <= 5 {
                baseWeather = "Primavera"
                temperature = "Temperatura agradable (15-23°C)"
                condition = "Clima templado"
            } else {
                baseWeather = "Otoño"
                temperature = "Temperatura fresca (12-20°C)"
                condition = "Clima fresco"
            }
        } else {
            // Zona fría
            if month >= 6 && month <= 8 {
                baseWeather = "Verano corto"
                temperature = "Temperatura fresca (12-20°C)"
                condition = "Clima fresco"
            } else {
                baseWeather = "Temporada fría"
                temperature = "Temperatura baja (0-10°C)"
                condition = "Clima frío"
            }
        }

        // Ajustar por hora del día
        var timeWeather = ""
        if hour >= 6 && hour < 12 {
            timeWeather = "Mañana clara"
        } else if hour >= 12 && hour < 18 {
            timeWeather = "Tarde"
        } else if hour >= 18 && hour < 21 {
            timeWeather = "Atardecer"
        } else {
            timeWeather = "Noche"
        }

        return "\(baseWeather). \(temperature). \(condition). \(timeWeather)."
    }

    private func getLocationName(for coordinate: CLLocationCoordinate2D?) async -> String? {
        guard let coordinate = coordinate else { return nil }

        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let placemark = placemarks.first {
                return placemark.locality ?? placemark.administrativeArea ?? LocalizedString("ultrathink.currentLocation")
            }
        } catch {
            print("Error geocoding: \(error)")
        }

        return LocalizedString("ultrathink.currentLocation")
    }
}

// MARK: - Recommendation Card

struct RecommendationCard: View {
    let recommendation: UltraThinkRecommendation
    let onTap: () -> Void
    let onNavigate: () -> Void
    let onDirections: () -> Void

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(recommendation.category.emoji)
                    .font(.system(size: 32))

                VStack(alignment: .leading, spacing: 4) {
                    Text(recommendation.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)

                    Text(recommendation.category.rawValue)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                priorityBadge
            }

            // Description
            Text(recommendation.description)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
                .lineSpacing(4)

            // Contextual Reason
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                    .font(.system(size: 14))

                Text(recommendation.contextualReason)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.yellow.opacity(0.9))
                    .lineSpacing(3)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.yellow.opacity(0.1))
            )

            // Additional Info
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    if let time = recommendation.suggestedTime {
                        infoRow(icon: "clock", text: time, color: .orange)
                    }

                    if let duration = recommendation.estimatedDuration {
                        infoRow(icon: "timer", text: duration, color: .blue)
                    }

                    if let location = recommendation.location {
                        infoRow(icon: "mappin.circle", text: location.name, color: .cyan)
                    }

                    // Tags
                    if !recommendation.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(recommendation.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(
                                            Capsule()
                                                .fill(Color.white.opacity(0.15))
                                        )
                                }
                            }
                        }
                    }
                }
                .padding(.top, 8)
            }

            // Action Buttons
            if recommendation.location != nil {
                HStack(spacing: 10) {
                    Button(action: onNavigate) {
                        HStack(spacing: 6) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 13))
                            Text(LocalizedString("ultrathink.viewOnMap"))
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [Color.blue, Color.blue.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: Color.blue.opacity(0.3), radius: 6, x: 0, y: 3)
                    }
                    .buttonStyle(ActionButtonPressStyle())

                    Button(action: onDirections) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                                .font(.system(size: 13))
                            Text(LocalizedString("ultrathink.directions"))
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [Color.green, Color.green.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: Color.green.opacity(0.3), radius: 6, x: 0, y: 3)
                    }
                    .buttonStyle(ActionButtonPressStyle())
                }
            }

            // Expand/Collapse Button
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 6) {
                    Spacer()
                    Text(isExpanded ? LocalizedString("ultrathink.showLess") : LocalizedString("ultrathink.showMore"))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                }
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                )
            }
            .buttonStyle(ActionButtonPressStyle())
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.12),
                            Color.white.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
        )
    }

    private var priorityBadge: some View {
        HStack(spacing: 4) {
            ForEach(0..<recommendation.priority, id: \.self) { _ in
                Image(systemName: "star.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.yellow)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.yellow.opacity(0.2))
        )
    }

    private func infoRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 12))
                .frame(width: 20)

            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.9))
        }
    }
}

// MARK: - Button Styles

struct ActionButtonPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? CGFloat(0.95) : CGFloat(1.0))
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Preview

struct UltraThinkRecommendationsView_Previews: PreviewProvider {
    static var previews: some View {
        UltraThinkRecommendationsView(
            isPresented: .constant(true),
            onNavigateToLocation: { _, _ in },
            onShowDirections: { _, _ in }
        )
    }
}
