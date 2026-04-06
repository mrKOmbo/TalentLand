//
//  UltraThinkViewModel.swift
//  Atenea
//
//  ViewModel para manejar recomendaciones contextuales avanzadas con Claude
//

import Foundation
import MapKit
internal import Combine

@MainActor
class UltraThinkViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var currentAnalysis: UltraThinkAnalysis?
    @Published var isAnalyzing: Bool = false
    @Published var errorMessage: String?
    @Published var selectedRecommendation: UltraThinkRecommendation?

    // MARK: - Properties

    private let claudeService: ClaudeAPIService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init() {
        self.claudeService = ClaudeAPIService(apiKey: APIConfiguration.shared.claudeAPIKey)
    }

    // MARK: - Public Methods

    /// Genera un nuevo análisis contextual
    func generateAnalysis(
        userLocation: CLLocationCoordinate2D?,
        locationName: String? = nil,
        weatherCondition: String? = nil,
        userPreferences: String? = nil
    ) async {
        isAnalyzing = true
        errorMessage = nil

        do {
            let analysis = try await claudeService.performUltraThinkAnalysis(
                userLocation: userLocation,
                locationName: locationName,
                currentTime: Date(),
                weatherCondition: weatherCondition,
                userPreferences: userPreferences
            )

            currentAnalysis = analysis
            isAnalyzing = false

        } catch {
            errorMessage = error.localizedDescription
            isAnalyzing = false
        }
    }

    /// Refresca el análisis con el contexto actual
    func refreshAnalysis(
        userLocation: CLLocationCoordinate2D?,
        locationName: String? = nil,
        weatherCondition: String? = nil
    ) async {
        await generateAnalysis(
            userLocation: userLocation,
            locationName: locationName,
            weatherCondition: weatherCondition
        )
    }

    /// Selecciona una recomendación específica
    func selectRecommendation(_ recommendation: UltraThinkRecommendation) {
        selectedRecommendation = recommendation
    }

    /// Limpia la recomendación seleccionada
    func clearSelection() {
        selectedRecommendation = nil
    }

    /// Limpia el análisis actual
    func clearAnalysis() {
        currentAnalysis = nil
        errorMessage = nil
        selectedRecommendation = nil
    }

    /// Obtiene recomendaciones filtradas por categoría
    func recommendations(for category: RecommendationCategory) -> [UltraThinkRecommendation] {
        guard let analysis = currentAnalysis else { return [] }
        return analysis.recommendations.filter { $0.category == category }
    }

    /// Obtiene recomendaciones ordenadas por prioridad
    func topRecommendations(limit: Int = 3) -> [UltraThinkRecommendation] {
        guard let analysis = currentAnalysis else { return [] }
        return Array(analysis.recommendations.sorted { $0.priority > $1.priority }.prefix(limit))
    }

    /// Verifica si hay una API key válida
    func hasValidAPIKey() -> Bool {
        return !APIConfiguration.shared.claudeAPIKey.isEmpty
    }

    /// Obtiene el contexto actual como string para mostrar
    func getContextDescription() -> String {
        guard let analysis = currentAnalysis else { return "" }

        var parts: [String] = []

        if let location = analysis.userLocation {
            parts.append("📍 \(location.name)")
        }

        parts.append("🕐 \(analysis.timeContext.capitalized)")

        if let weather = analysis.weatherContext {
            parts.append("🌤️ \(weather)")
        }

        return parts.joined(separator: " • ")
    }
}
