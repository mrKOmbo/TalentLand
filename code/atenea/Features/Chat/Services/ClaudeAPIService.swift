//
//  ClaudeAPIService.swift
//  Atenea
//
//  Servicio para integración con Claude API
//

import Foundation
import MapKit
internal import Combine

class ClaudeAPIService: ObservableObject {

    // MARK: - Properties

    private let apiKey: String
    private let apiURL = "https://api.anthropic.com/v1/messages"
    private let model = "claude-sonnet-4-5-20250929"  // Modelo actualizado

    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - Initialization

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    // MARK: - Public Methods

    /// Envía un mensaje a Claude y retorna la respuesta
    func sendMessage(_ message: String, conversationHistory: [ChatMessage] = []) async throws -> String {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        defer {
            Task { @MainActor in
                isLoading = false
            }
        }

        // Construir request
        guard let url = URL(string: apiURL) else {
            throw ClaudeAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")

        // Construir mensajes de la conversación
        var messages: [[String: Any]] = []

        // Agregar historial de conversación
        for msg in conversationHistory {
            messages.append([
                "role": msg.isUser ? "user" : "assistant",
                "content": msg.text
            ])
        }

        // Agregar mensaje actual
        messages.append([
            "role": "user",
            "content": message
        ])

        // Construir body del request
        let requestBody: [String: Any] = [
            "model": model,
            "max_tokens": 2048,
            "messages": messages,
            "system": """
            Eres un asistente de viaje inteligente integrado en la app Atenea para el Mundial 2026.
            Tu trabajo es ayudar a los usuarios a descubrir lugares, restaurantes, atracciones y más.

            IMPORTANTE: Cuando menciones lugares específicos, SIEMPRE incluye las coordenadas en este formato:
            [LUGAR: Nombre del lugar | LAT: latitud | LON: longitud]

            Ejemplo de respuesta correcta:
            "Te recomiendo visitar estos lugares:

            🌮 [LUGAR: Tacos El Güero | LAT: 19.4326 | LON: -99.1332] - Los mejores tacos al pastor

            🏛️ [LUGAR: Museo Frida Kahlo | LAT: 19.3551 | LON: -99.1620] - Casa Azul imperdible"

            REGLAS:
            1. Usa coordenadas reales y precisas
            2. Incluye el formato [LUGAR:...] para CADA lugar que menciones
            3. Mantén la respuesta concisa pero informativa
            4. Usa emojis para hacerlo amigable
            5. Máximo 3-4 lugares por respuesta
            """
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        // Hacer request
        let (data, response) = try await URLSession.shared.data(for: request)

        // Verificar respuesta HTTP
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClaudeAPIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            // Intentar parsear error de la API
            if let errorResponse = try? JSONDecoder().decode(ClaudeErrorResponse.self, from: data) {
                throw ClaudeAPIError.apiError(errorResponse.error.message)
            }
            throw ClaudeAPIError.httpError(httpResponse.statusCode)
        }

        // Parsear respuesta
        let apiResponse = try JSONDecoder().decode(ClaudeAPIResponse.self, from: data)

        // Extraer texto de la respuesta
        guard let textContent = apiResponse.content.first(where: { $0.type == "text" }) else {
            throw ClaudeAPIError.noTextInResponse
        }

        return textContent.text
    }

    /// Realiza un análisis contextual avanzado (UltraThink) y retorna recomendaciones personalizadas
    func performUltraThinkAnalysis(
        userLocation: CLLocationCoordinate2D?,
        locationName: String?,
        currentTime: Date = Date(),
        weatherCondition: String? = nil,
        userPreferences: String? = nil
    ) async throws -> UltraThinkAnalysis {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        defer {
            Task { @MainActor in
                isLoading = false
            }
        }

        // Construir contexto
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        let currentTimeString = timeFormatter.string(from: currentTime)

        let hour = Calendar.current.component(.hour, from: currentTime)
        let timeOfDay = hour < 12 ? "mañana" : (hour < 18 ? "tarde" : "noche")

        var contextParts: [String] = []
        contextParts.append("Hora actual: \(currentTimeString) (\(timeOfDay))")

        if let location = userLocation, let name = locationName {
            contextParts.append("Ubicación: \(name) (Lat: \(location.latitude), Lon: \(location.longitude))")
        } else if let location = userLocation {
            contextParts.append("Coordenadas: Lat: \(location.latitude), Lon: \(location.longitude)")
        }

        if let weather = weatherCondition {
            contextParts.append("Clima: \(weather)")
        }

        if let preferences = userPreferences {
            contextParts.append("Preferencias del usuario: \(preferences)")
        }

        let contextString = contextParts.joined(separator: "\n")

        // Construir prompt especializado
        let ultraThinkPrompt = """
        Realiza un análisis contextual PROFUNDO y genera recomendaciones personalizadas basadas en:

        \(contextString)

        IMPORTANTE: Responde ÚNICAMENTE con un objeto JSON válido en este formato exacto:

        {
          "contextSummary": "Breve análisis del contexto actual del usuario",
          "recommendations": [
            {
              "title": "Nombre de la recomendación",
              "description": "Descripción detallada y atractiva",
              "category": "restaurant|cafe|activity|worldCup|culture|entertainment|nature|shopping|nightlife|sports",
              "location": {
                "name": "Nombre del lugar",
                "latitude": 19.4326,
                "longitude": -99.1332,
                "address": "Dirección completa"
              },
              "contextualReason": "Por qué recomiendas esto específicamente ahora (contexto, hora, clima)",
              "priority": 5,
              "suggestedTime": "Horario sugerido",
              "tags": ["tag1", "tag2", "tag3"],
              "estimatedDuration": "Duración estimada",
              "weatherRelevance": "Si aplica al clima actual"
            }
          ],
          "timeContext": "\(timeOfDay)",
          "weatherContext": "\(weatherCondition ?? "No disponible")"
        }

        REGLAS CRÍTICAS:
        1. Genera EXACTAMENTE 8-12 recomendaciones variadas de DIFERENTES categorías
        2. Considera PROFUNDAMENTE el contexto: hora del día, ubicación, clima
        3. Usa coordenadas REALES y PRECISAS de lugares que existan
        4. Priority: 1-5 (5 = máxima relevancia contextual)
        5. Las categorías DEBEN ser exactamente una de las listadas
        6. contextualReason debe explicar POR QUÉ es relevante AHORA
        7. NO agregues texto adicional, SOLO el JSON
        8. Asegúrate de que el JSON sea válido y parseable
        9. Incluye variedad: restaurantes, cafés, bares (nightlife), actividades, cultura, etc.
        """

        // Enviar request
        guard let url = URL(string: apiURL) else {
            throw ClaudeAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")

        let requestBody: [String: Any] = [
            "model": model,
            "max_tokens": 6144,  // Más tokens para 8-12 recomendaciones
            "messages": [
                [
                    "role": "user",
                    "content": ultraThinkPrompt
                ]
            ],
            "system": """
            Eres UltraThink, un sistema de IA avanzado especializado en análisis contextual profundo.
            Tu trabajo es analizar múltiples factores (ubicación, hora, clima, contexto) y generar
            recomendaciones extremadamente personalizadas y relevantes.

            SIEMPRE respondes en formato JSON estructurado, sin texto adicional.
            """
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        // Hacer request
        let (data, response) = try await URLSession.shared.data(for: request)

        // Verificar respuesta HTTP
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClaudeAPIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(ClaudeErrorResponse.self, from: data) {
                throw ClaudeAPIError.apiError(errorResponse.error.message)
            }
            throw ClaudeAPIError.httpError(httpResponse.statusCode)
        }

        // Parsear respuesta de Claude
        let apiResponse = try JSONDecoder().decode(ClaudeAPIResponse.self, from: data)

        guard let textContent = apiResponse.content.first(where: { $0.type == "text" }) else {
            throw ClaudeAPIError.noTextInResponse
        }

        // Extraer JSON de la respuesta (puede venir con markdown)
        let responseText = textContent.text
        let jsonString = extractJSON(from: responseText)

        // Decodificar respuesta JSON
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw ClaudeAPIError.invalidResponse
        }

        let ultraThinkResponse = try JSONDecoder().decode(UltraThinkJSONResponse.self, from: jsonData)

        // Convertir a UltraThinkAnalysis
        let recommendations = ultraThinkResponse.recommendations.map { rec in
            UltraThinkRecommendation(
                title: rec.title,
                description: rec.description,
                category: RecommendationCategory(rawValue: rec.category) ?? .activity,
                location: rec.location.map { loc in
                    LocationInfo(
                        name: loc.name,
                        latitude: loc.latitude,
                        longitude: loc.longitude,
                        address: loc.address
                    )
                },
                contextualReason: rec.contextualReason,
                priority: rec.priority,
                suggestedTime: rec.suggestedTime,
                tags: rec.tags,
                estimatedDuration: rec.estimatedDuration,
                weatherRelevance: rec.weatherRelevance
            )
        }

        let analysis = UltraThinkAnalysis(
            contextSummary: ultraThinkResponse.contextSummary,
            recommendations: recommendations,
            timestamp: currentTime,
            userLocation: userLocation.map { loc in
                LocationInfo(
                    name: locationName ?? "Ubicación actual",
                    latitude: loc.latitude,
                    longitude: loc.longitude,
                    address: nil
                )
            },
            weatherContext: ultraThinkResponse.weatherContext,
            timeContext: ultraThinkResponse.timeContext
        )

        return analysis
    }

    /// Simula la respuesta de un comerciante usando Claude (fallback cuando no hay BLE peer)
    func generateMerchantReply(
        timbre: TimbreEvent,
        merchantEmoji: String,
        merchantCategory: String
    ) async throws -> (type: TimbreResponseType, message: String, minutes: Int?) {
        guard let url = URL(string: apiURL) else { throw ClaudeAPIError.invalidURL }

        let userMessage: String
        switch timbre.type {
        case .ring: userMessage = "Un cliente quiere comprar"
        case .question: userMessage = timbre.message ?? "Un cliente tiene una pregunta"
        case .hurry: userMessage = "Un cliente pide que vayas rápido"
        case .message: userMessage = timbre.message ?? "Un cliente te envió un mensaje"
        }

        let prompt = """
        Eres \(merchantEmoji) \(timbre.merchantName), vendedor ambulante de \(merchantCategory) en CDMX.
        El cliente \(timbre.clientName) te envió: "\(userMessage)".
        Responde de forma breve y natural como el vendedor.
        Responde SOLO con JSON válido, sin texto adicional:
        {"response":"on_my_way"|"wait_here"|"busy"|"closed","message":"mensaje corto","minutes":null}
        minutes debe ser un número entero (1-20) si vas en camino, o null si no aplica.
        """

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "model": model,
            "max_tokens": 128,
            "messages": [["role": "user", "content": prompt]]
        ])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw ClaudeAPIError.httpError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }

        let apiResponse = try JSONDecoder().decode(ClaudeAPIResponse.self, from: data)
        guard let text = apiResponse.content.first(where: { $0.type == "text" })?.text else {
            throw ClaudeAPIError.noTextInResponse
        }

        let jsonStr = extractJSON(from: text)
        guard let jsonData = jsonStr.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let responseStr = json["response"] as? String,
              let responseType = TimbreResponseType(rawValue: responseStr),
              let message = json["message"] as? String else {
            return (.onMyWay, "¡Ya voy para allá!", 5)
        }

        let minutes = json["minutes"] as? Int
        return (responseType, message, minutes)
    }

    /// Extrae JSON de una respuesta que puede contener markdown
    private func extractJSON(from text: String) -> String {
        // Buscar JSON entre bloques de código markdown
        if let range = text.range(of: "```json\\s*", options: .regularExpression) {
            var jsonText = String(text[range.upperBound...])
            if let endRange = jsonText.range(of: "```") {
                jsonText = String(jsonText[..<endRange.lowerBound])
            }
            return jsonText.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Buscar JSON entre llaves
        if let startRange = text.range(of: "{"),
           let endRange = text.range(of: "}", options: .backwards) {
            let jsonText = String(text[startRange.lowerBound...endRange.upperBound])
            return jsonText.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - UltraThink JSON Models

struct UltraThinkJSONResponse: Codable {
    let contextSummary: String
    let recommendations: [UltraThinkJSONRecommendation]
    let timeContext: String
    let weatherContext: String?
}

struct UltraThinkJSONRecommendation: Codable {
    let title: String
    let description: String
    let category: String
    let location: UltraThinkJSONLocation?
    let contextualReason: String
    let priority: Int
    let suggestedTime: String?
    let tags: [String]
    let estimatedDuration: String?
    let weatherRelevance: String?
}

struct UltraThinkJSONLocation: Codable {
    let name: String
    let latitude: Double
    let longitude: Double
    let address: String?
}

// MARK: - API Models

struct ClaudeAPIResponse: Codable {
    let id: String
    let type: String
    let role: String
    let content: [ContentBlock]
    let model: String
    let stopReason: String?

    enum CodingKeys: String, CodingKey {
        case id, type, role, content, model
        case stopReason = "stop_reason"
    }
}

struct ContentBlock: Codable {
    let type: String
    let text: String
}

struct ClaudeErrorResponse: Codable {
    let error: ClaudeError
}

struct ClaudeError: Codable {
    let type: String
    let message: String
}

// MARK: - Errors

enum ClaudeAPIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case apiError(String)
    case noTextInResponse

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL de API inválida"
        case .invalidResponse:
            return "Respuesta inválida del servidor"
        case .httpError(let code):
            return "Error HTTP: \(code)"
        case .apiError(let message):
            return message
        case .noTextInResponse:
            return "No se recibió texto en la respuesta"
        }
    }
}

// MARK: - ChatMessage Model (usado en conversationHistory)

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
}
