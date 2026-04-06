//
//  AskClaudeIntent.swift
//  Atenea
//
//  Intent para hacer preguntas al asistente AI Claude
//  Uso: "Hey Siri, pregúntale a Atenea dónde comer cerca del Estadio Azteca"
//       "Hey Siri, en Atenea, ¿qué hacer en Ciudad de México?"
//

import Foundation
import AppIntents
import CoreLocation

/// Intent to ask questions to Claude AI
struct AskClaudeIntent: AppIntent {
    static var title: LocalizedStringResource = "Ask Assistant"
    static var description = IntentDescription("Ask a question to Atenea's AI assistant about places, restaurants and more")

    static var openAppWhenRun: Bool = false // Can respond without opening the app

    @Parameter(title: "Question", description: "What do you want to know?", requestValueDialog: IntentDialog("What would you like to ask Atenea?"))
    var question: String

    static var parameterSummary: some ParameterSummary {
        Summary("Ask Atenea: \(\.$question)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Validate question is not empty
        guard !question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .result(
                dialog: IntentDialog(stringLiteral: "I didn't receive a question. What would you like to know about the 2026 World Cup?")
            )
        }

        // Get API key
        guard let apiKey = getClaudeAPIKey() else {
            return .result(
                dialog: IntentDialog(stringLiteral: "Could not connect to the assistant. Please configure your API key in the app.")
            )
        }

        // Create Claude service
        let claudeService = ClaudeAPIService(apiKey: apiKey)

        do {
            // Send question to Claude
            let response = try await claudeService.sendMessage(question)

            print("🤖 [APP INTENT] Question answered: \(question)")

            // Clean response from coordinate markers if any
            let cleanResponse = cleanResponseForVoice(response)

            return .result(dialog: IntentDialog(stringLiteral: cleanResponse))

        } catch {
            print("❌ [APP INTENT] Error querying Claude: \(error)")

            let errorMessage: String
            if let claudeError = error as? ClaudeAPIError {
                errorMessage = "An error occurred: \(claudeError.localizedDescription)"
            } else {
                errorMessage = "Could not get a response at this time. Please try again later."
            }

            return .result(dialog: IntentDialog(stringLiteral: errorMessage))
        }
    }

    // Helper function to get API key
    private func getClaudeAPIKey() -> String? {
        // Try to get from UserDefaults first
        if let apiKey = UserDefaults.standard.string(forKey: "claudeAPIKey"), !apiKey.isEmpty {
            return apiKey
        }

        // Try to get from Info.plist
        if let apiKey = Bundle.main.object(forInfoDictionaryKey: "ClaudeAPIKey") as? String, !apiKey.isEmpty {
            return apiKey
        }

        return nil
    }

    // Clean Claude's response to make it more voice-friendly
    private func cleanResponseForVoice(_ response: String) -> String {
        var cleaned = response

        // Remove place markers [LUGAR:... | LAT:... | LON:...]
        let pattern = "\\[LUGAR:[^\\]]+\\]"
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let range = NSRange(cleaned.startIndex..., in: cleaned)
            cleaned = regex.stringByReplacingMatches(in: cleaned, options: [], range: range, withTemplate: "")
        }

        // Replace multiple emojis
        // (Optional: you might want to keep emojis for Siri to read)

        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

/// Intent to request recommendations near a location
struct GetRecommendationsIntent: AppIntent {
    static var title: LocalizedStringResource = "Nearby Recommendations"
    static var description = IntentDescription("Get recommendations for places near you or near a stadium")

    static var openAppWhenRun: Bool = false

    @Parameter(title: "Place Type", description: "What are you looking for?", default: .restaurants)
    var placeType: PlaceTypeEnum

    @Parameter(title: "Near", description: "Reference location (optional)")
    var nearVenue: VenueEntity?

    static var parameterSummary: some ParameterSummary {
        When(\.$nearVenue, .hasAnyValue) {
            Summary("Recommend \(\.$placeType) near \(\.$nearVenue)")
        } otherwise: {
            Summary("Recommend \(\.$placeType) near me")
        }
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Get API key
        guard let apiKey = getClaudeAPIKey() else {
            return .result(
                dialog: IntentDialog(stringLiteral: "Could not connect to the assistant. Please configure the app first.")
            )
        }

        // Build question
        let question: String
        if let venue = nearVenue {
            question = "Recommend the best \(placeType.rawValue) near \(venue.name) in \(venue.city), \(venue.country). Give me a maximum of 3 options with coordinates."
        } else {
            question = "Recommend the best \(placeType.rawValue) in a typical city of the 2026 World Cup. Give me a maximum of 3 options."
        }

        // Create Claude service
        let claudeService = ClaudeAPIService(apiKey: apiKey)

        do {
            let response = try await claudeService.sendMessage(question)

            print("🤖 [APP INTENT] Recommendations obtained for \(placeType.rawValue)")

            let cleanResponse = cleanResponseForVoice(response)
            return .result(dialog: IntentDialog(stringLiteral: cleanResponse))

        } catch {
            print("❌ [APP INTENT] Error getting recommendations: \(error)")
            return .result(
                dialog: IntentDialog(stringLiteral: "Could not get recommendations at this time. Please try again later.")
            )
        }
    }

    private func getClaudeAPIKey() -> String? {
        if let apiKey = UserDefaults.standard.string(forKey: "claudeAPIKey"), !apiKey.isEmpty {
            return apiKey
        }
        if let apiKey = Bundle.main.object(forInfoDictionaryKey: "ClaudeAPIKey") as? String, !apiKey.isEmpty {
            return apiKey
        }
        return nil
    }

    private func cleanResponseForVoice(_ response: String) -> String {
        var cleaned = response
        let pattern = "\\[LUGAR:[^\\]]+\\]"
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let range = NSRange(cleaned.startIndex..., in: cleaned)
            cleaned = regex.stringByReplacingMatches(in: cleaned, options: [], range: range, withTemplate: "")
        }
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Enums

/// Types of places that can be searched
enum PlaceTypeEnum: String, AppEnum {
    case restaurants = "restaurants"
    case cafes = "cafés"
    case bars = "bars"
    case attractions = "tourist attractions"
    case museums = "museums"
    case parks = "parks"
    case shopping = "shopping centers"
    case hotels = "hotels"

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Place Type"

    static var caseDisplayRepresentations: [PlaceTypeEnum: DisplayRepresentation] = [
        .restaurants: DisplayRepresentation(title: "Restaurants", subtitle: "Places to eat"),
        .cafes: DisplayRepresentation(title: "Cafés", subtitle: "Coffee shops"),
        .bars: DisplayRepresentation(title: "Bars", subtitle: "Nightlife"),
        .attractions: DisplayRepresentation(title: "Attractions", subtitle: "Tourist places"),
        .museums: DisplayRepresentation(title: "Museums", subtitle: "Art and culture"),
        .parks: DisplayRepresentation(title: "Parks", subtitle: "Outdoor spaces"),
        .shopping: DisplayRepresentation(title: "Shopping", subtitle: "Shopping centers"),
        .hotels: DisplayRepresentation(title: "Hotels", subtitle: "Accommodation"),
    ]
}
