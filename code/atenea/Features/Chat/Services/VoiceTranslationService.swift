//
//  VoiceTranslationService.swift
//  atenea
//
//  Servicio de traducción de voz en tiempo real vendedor↔turista
//  Pipeline: SFSpeechRecognizer → Translation → AVSpeechSynthesizer
//  Todo funciona on-device sin internet (iOS 17.4+)
//

import Foundation
import Speech
import AVFoundation
import NaturalLanguage
internal import Combine

// MARK: - Translation Message

struct TranslationMessage: Identifiable {
    let id = UUID()
    let originalText: String
    let translatedText: String
    let sourceLanguage: String
    let targetLanguage: String
    let isFromMerchant: Bool
    let timestamp: Date
}

// MARK: - Voice Translation Service

class VoiceTranslationService: NSObject, ObservableObject {
    static let shared = VoiceTranslationService()

    // Estado
    @Published var isListening = false
    @Published var currentTranscription = ""
    @Published var lastTranslation = ""
    @Published var streamingTranslation = ""
    @Published var isTranslating = false
    @Published var isSpeaking = false
    @Published var messages: [TranslationMessage] = []
    @Published var errorMessage: String?

    // Feature 3: Sugerencias inteligentes
    @Published var currentSuggestions: [String] = []
    @Published var suggestionsForMerchant = false

    // Feature 7: Auto-detección de idioma
    @Published var isAutoDetectEnabled = true
    @Published var detectedLanguageLabel: String?
    @Published private(set) var isMerchantSpeakingPublic = true

    // Config
    var merchantLanguage = "es-MX"
    var touristLanguage = "en-US"

    // Speech Recognition
    private var audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var speechRecognizer: SFSpeechRecognizer?

    // Text-to-Speech
    private let synthesizer = AVSpeechSynthesizer()

    // Silence detection
    private var silenceTimer: Timer?
    private var lastTranscriptionUpdate: Date?
    private var isMerchantSpeaking = true

    // Cache de traducciones (respuesta instantánea para frases repetidas)
    private var translationCache: [String: String] = [:]
    private let languageRecognizer = NLLanguageRecognizer()
    private let maxContextMessages = 5

    // MARK: - Quick Phrases (Feature 2)

    struct QuickPhrase: Identifiable {
        let id = UUID()
        let text: String
        let emoji: String
    }

    static let merchantPhrases: [QuickPhrase] = [
        QuickPhrase(text: "¿Qué le damos?", emoji: "🤔"),
        QuickPhrase(text: "¿Picoso o no?", emoji: "🌶️"),
        QuickPhrase(text: "Son 20 pesos", emoji: "💰"),
        QuickPhrase(text: "¡Provecho!", emoji: "😊"),
        QuickPhrase(text: "Se acabó", emoji: "❌"),
        QuickPhrase(text: "Ahorita le preparo", emoji: "👨‍🍳"),
        QuickPhrase(text: "Con todo", emoji: "✅"),
        QuickPhrase(text: "¿Algo más?", emoji: "➕"),
    ]

    static let touristPhrases: [QuickPhrase] = [
        QuickPhrase(text: "How much?", emoji: "💵"),
        QuickPhrase(text: "Not spicy", emoji: "🚫"),
        QuickPhrase(text: "Delicious!", emoji: "😋"),
        QuickPhrase(text: "Card?", emoji: "💳"),
        QuickPhrase(text: "To go", emoji: "🥡"),
        QuickPhrase(text: "What do you recommend?", emoji: "⭐"),
        QuickPhrase(text: "One more please", emoji: "☝️"),
        QuickPhrase(text: "Thank you!", emoji: "🙏"),
    ]

    private override init() {
        super.init()
    }

    // MARK: - Permisos

    func requestPermissions(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                if status == .authorized {
                    AVAudioApplication.requestRecordPermission { granted in
                        DispatchQueue.main.async {
                            completion(granted)
                        }
                    }
                } else {
                    completion(false)
                }
            }
        }
    }

    // MARK: - Iniciar escucha

    func startListening(asMerchant: Bool) {
        stopListening()

        isMerchantSpeaking = asMerchant
        let locale = Locale(identifier: asMerchant ? merchantLanguage : touristLanguage)

        guard let recognizer = SFSpeechRecognizer(locale: locale), recognizer.isAvailable else {
            errorMessage = "Reconocimiento de voz no disponible para \(locale.identifier)"
            return
        }

        speechRecognizer = recognizer

        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let request = recognitionRequest else { return }

            request.shouldReportPartialResults = true
            if #available(iOS 13, *) {
                request.requiresOnDeviceRecognition = true
            }

            recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
                guard let self = self else { return }

                if let result = result {
                    let text = result.bestTranscription.formattedString
                    DispatchQueue.main.async {
                        self.currentTranscription = text
                        self.lastTranscriptionUpdate = Date()
                    }

                    // Detectar silencio — si no hay cambios en 1.5s, traducir
                    self.resetSilenceTimer()

                    if result.isFinal {
                        self.processTranscription(text)
                    }
                }

                if error != nil {
                    self.stopListening()
                }
            }

            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
                self?.recognitionRequest?.append(buffer)
            }

            audioEngine.prepare()
            try audioEngine.start()

            DispatchQueue.main.async {
                self.isListening = true
                self.currentTranscription = ""
                self.errorMessage = nil
            }

        } catch {
            errorMessage = "Error al iniciar: \(error.localizedDescription)"
        }
    }

    // MARK: - Parar escucha

    func stopListening() {
        silenceTimer?.invalidate()
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil

        DispatchQueue.main.async {
            self.isListening = false
        }
    }

    // MARK: - Silence Detection

    private func resetSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            let text = self.currentTranscription
            if !text.isEmpty {
                self.stopListening()
                self.processTranscription(text)
            }
        }
    }

    // MARK: - Traducción

    // MARK: - Quick Phrase (Feature 2) — entrada pública

    func sendQuickPhrase(_ text: String, asMerchant: Bool) {
        if isListening { stopListening() }
        isMerchantSpeaking = asMerchant
        isMerchantSpeakingPublic = asMerchant
        processTranscription(text)
    }

    // MARK: - Suggestion tap (Feature 3)

    func sendSuggestion(_ text: String) {
        let forMerchant = suggestionsForMerchant
        currentSuggestions = []
        sendQuickPhrase(text, asMerchant: forMerchant)
    }

    // MARK: - Traducción (Feature 4: contexto, Feature 7: auto-detect)

    private func processTranscription(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        // Feature 7: Auto-detectar idioma antes de traducir
        if isAutoDetectEnabled {
            autoDetectLanguage(text)
        }

        let sourceCode = isMerchantSpeaking ? merchantLanguage : touristLanguage
        let targetCode = isMerchantSpeaking ? touristLanguage : merchantLanguage
        let fromMerchant = isMerchantSpeaking

        // Feature 4: Cache key incluye hash de contexto
        let contextHash = messages.suffix(2).map { String($0.id.uuidString.prefix(4)) }.joined()
        let cacheKey = "\(sourceCode)|\(targetCode)|\(text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines))|\(contextHash)"
        if let cached = translationCache[cacheKey] {
            addMessage(original: text, translated: cached, source: sourceCode, target: targetCode, fromMerchant: fromMerchant)
            speak(cached, language: targetCode)
            generateSuggestionsLocal(after: text, fromMerchant: fromMerchant)
            return
        }

        Task {
            await MainActor.run {
                self.isTranslating = true
                self.streamingTranslation = ""
                self.currentSuggestions = []
            }

            let translated: String
            if APIConfiguration.shared.hasClaudeAPIKey {
                translated = await translateWithClaude(text, from: sourceCode, to: targetCode)
            } else {
                translated = LocalTranslationDictionary.translate(text, from: sourceCode, to: targetCode)
            }

            translationCache[cacheKey] = translated

            await MainActor.run {
                self.isTranslating = false
                self.streamingTranslation = ""
            }

            addMessage(original: text, translated: translated, source: sourceCode, target: targetCode, fromMerchant: fromMerchant)
            speak(translated, language: targetCode)

            // Feature 3: Sugerencias — local instantáneo + Claude async
            generateSuggestionsLocal(after: text, fromMerchant: fromMerchant)
            Task { await generateSuggestionsClaude(after: text, fromMerchant: fromMerchant) }
        }
    }

    private func addMessage(original: String, translated: String, source: String, target: String, fromMerchant: Bool) {
        let message = TranslationMessage(
            originalText: original, translatedText: translated,
            sourceLanguage: source, targetLanguage: target,
            isFromMerchant: fromMerchant, timestamp: Date()
        )
        DispatchQueue.main.async {
            self.messages.append(message)
            self.lastTranslation = translated
            self.currentTranscription = ""
        }
    }

    // MARK: - Feature 7: Auto-detect idioma

    private func autoDetectLanguage(_ text: String) {
        guard text.split(separator: " ").count >= 2 else { return }

        languageRecognizer.reset()
        languageRecognizer.processString(text)

        guard let dominant = languageRecognizer.dominantLanguage else { return }
        let hypotheses = languageRecognizer.languageHypotheses(withMaximum: 3)
        let confidence = hypotheses[dominant] ?? 0
        guard confidence > 0.6 else { return }

        let detected = dominant.rawValue
        let merchantBase = merchantLanguage.components(separatedBy: "-").first ?? "es"
        let touristBase = touristLanguage.components(separatedBy: "-").first ?? "en"

        if detected == merchantBase {
            isMerchantSpeaking = true
            isMerchantSpeakingPublic = true
            DispatchQueue.main.async { self.detectedLanguageLabel = "Español 🇲🇽" }
        } else if detected == touristBase {
            isMerchantSpeaking = false
            isMerchantSpeakingPublic = false
            let name = Self.langName(touristLanguage)
            DispatchQueue.main.async { self.detectedLanguageLabel = name }
        }
    }

    // MARK: - Feature 3: Sugerencias locales (instantáneas)

    private func generateSuggestionsLocal(after text: String, fromMerchant: Bool) {
        let lowered = text.lowercased()
        var sugs: [String] = []

        if fromMerchant {
            // Sugerencias para el turista
            if lowered.contains("picoso") || lowered.contains("picante") {
                sugs = ["Yes please", "Not spicy", "A little"]
            } else if lowered.contains("qué le damos") || lowered.contains("qué va a llevar") || lowered.contains("qué le sirvo") {
                sugs = ["What do you recommend?", "Tacos please", "What's popular?"]
            } else if lowered.contains("pesos") || lowered.contains("cuesta") || lowered.contains("son ") {
                sugs = ["OK, I'll take it", "Too expensive", "Can I pay with card?"]
            } else if lowered.contains("algo más") || lowered.contains("algo mas") {
                sugs = ["No, that's all", "One more", "Water please"]
            } else if lowered.contains("provecho") {
                sugs = ["Thank you!", "Delicious!", "Very good!"]
            }
        } else {
            // Sugerencias para el vendedor
            if lowered.contains("how much") || lowered.contains("cuánto") || lowered.contains("cuanto") {
                sugs = ["Son 20 pesos", "Son 15 pesos", "Son 30 pesos"]
            } else if lowered.contains("recommend") || lowered.contains("popular") {
                sugs = ["Los de pastor", "Pruebe los esquites", "Quesadilla de queso"]
            } else if lowered.contains("card") || lowered.contains("tarjeta") {
                sugs = ["Sí, aceptamos", "Solo efectivo", "También con teléfono"]
            } else if lowered.contains("thank") || lowered.contains("delicious") || lowered.contains("good") {
                sugs = ["¡Provecho!", "¡Gracias a usted!", "¡Que le vaya bien!"]
            }
        }

        if !sugs.isEmpty {
            DispatchQueue.main.async {
                self.suggestionsForMerchant = !fromMerchant
                self.currentSuggestions = sugs
            }
        }
    }

    // MARK: - Feature 3: Sugerencias Claude (async, reemplaza locales)

    private func generateSuggestionsClaude(after text: String, fromMerchant: Bool) async {
        guard APIConfiguration.shared.hasClaudeAPIKey else { return }

        let targetRole = fromMerchant ? "tourist" : "vendor"
        let targetLang = fromMerchant ? touristLanguage : merchantLanguage
        let langName = Self.langName(targetLang)

        let contextLines = messages.suffix(4).map {
            "\($0.isFromMerchant ? "Vendor" : "Tourist"): \($0.originalText)"
        }.joined(separator: "\n")

        let prompt = """
        Street food conversation in Mexico City:
        \(contextLines)

        Suggest 3 short replies the \(targetRole) might say next, in \(langName).
        Return ONLY a JSON array: ["reply1","reply2","reply3"]
        """

        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(APIConfiguration.shared.claudeAPIKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.timeoutInterval = 5

        let body: [String: Any] = [
            "model": "claude-haiku-4-5-20251001",
            "max_tokens": 100,
            "messages": [["role": "user", "content": prompt]],
            "system": "Return ONLY a JSON array of 3 short strings. No explanation."
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
                  let apiResponse = try? JSONDecoder().decode(ClaudeAPIResponse.self, from: data),
                  let textContent = apiResponse.content.first(where: { $0.type == "text" }) else { return }

            let jsonText = textContent.text.trimmingCharacters(in: .whitespacesAndNewlines)
            if let jsonData = jsonText.data(using: .utf8),
               let arr = try? JSONDecoder().decode([String].self, from: jsonData), arr.count >= 2 {
                await MainActor.run {
                    self.suggestionsForMerchant = !fromMerchant
                    self.currentSuggestions = Array(arr.prefix(3))
                }
            }
        } catch { }
    }

    // MARK: - Traducción con Claude API (streaming + contexto)

    private func translateWithClaude(_ text: String, from source: String, to target: String) async -> String {
        let apiKey = APIConfiguration.shared.claudeAPIKey
        let srcName = Self.langName(source)
        let tgtName = Self.langName(target)

        // Feature 4: Construir contexto de conversación
        let recentMessages = messages.suffix(maxContextMessages)
        var contextBlock = ""
        if !recentMessages.isEmpty {
            let lines = recentMessages.map {
                let role = $0.isFromMerchant ? "Vendor" : "Tourist"
                let original = String($0.originalText.prefix(80))
                let translated = String($0.translatedText.prefix(80))
                return "\(role): \"\(original)\" → \"\(translated)\""
            }
            contextBlock = "\nRecent conversation:\n" + lines.joined(separator: "\n") + "\n"
        }

        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            return LocalTranslationDictionary.translate(text, from: source, to: target)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.timeoutInterval = 8

        let systemPrompt = """
        You are a real-time translator for street food vendors and tourists in Mexico City (World Cup 2026).
        Rules:
        - Return ONLY the translated text. No quotes, no explanations.
        - For Mexican food with no direct translation, keep the original name and add a brief description in parentheses. Example: "tacos de canasta (soft steamed basket tacos)".
        - Common foods like tacos, quesadillas, tamales can stay as-is.
        - Be casual, friendly, natural. Translate the FULL sentence idiomatically.
        - Use conversation context to resolve pronouns and references (e.g. "two more" = "dos más de esos").
        \(contextBlock)
        """

        let body: [String: Any] = [
            "model": "claude-haiku-4-5-20251001",
            "max_tokens": 200,
            "stream": true,
            "messages": [["role": "user", "content": "\(srcName) → \(tgtName): \(text)"]],
            "system": systemPrompt
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (bytes, response) = try await URLSession.shared.bytes(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return LocalTranslationDictionary.translate(text, from: source, to: target)
            }

            var fullText = ""
            for try await line in bytes.lines {
                guard line.hasPrefix("data: ") else { continue }
                let jsonStr = String(line.dropFirst(6))
                if jsonStr == "[DONE]" { break }

                guard let data = jsonStr.data(using: .utf8),
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let type = json["type"] as? String else { continue }

                if type == "content_block_delta",
                   let delta = json["delta"] as? [String: Any],
                   let chunk = delta["text"] as? String {
                    fullText += chunk
                    let current = fullText
                    await MainActor.run { self.streamingTranslation = current }
                }
            }

            let result = fullText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !result.isEmpty { return result }
        } catch { }

        return LocalTranslationDictionary.translate(text, from: source, to: target)
    }

    private static func langName(_ code: String) -> String {
        let p = code.components(separatedBy: "-").first ?? code
        return ["es": "Spanish", "en": "English", "ja": "Japanese", "ko": "Korean",
                "de": "German", "fr": "French", "pt": "Portuguese", "zh": "Chinese",
                "ar": "Arabic", "it": "Italian", "ru": "Russian", "tr": "Turkish"][p] ?? "English"
    }

    // MARK: - Text-to-Speech

    func speak(_ text: String, language: String) {
        synthesizer.stopSpeaking(at: .immediate)

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        utterance.pitchMultiplier = 1.0
        utterance.preUtteranceDelay = 0.2

        DispatchQueue.main.async {
            self.isSpeaking = true
        }

        synthesizer.speak(utterance)

        // Marcar como terminado después de un delay estimado
        let estimatedDuration = Double(text.count) * 0.06
        DispatchQueue.main.asyncAfter(deadline: .now() + estimatedDuration + 0.5) { [weak self] in
            self?.isSpeaking = false
        }
    }

    // MARK: - Limpiar

    func clearMessages() {
        messages.removeAll()
        currentTranscription = ""
        lastTranslation = ""
    }
}

// MARK: - Diccionario de Traducción Local (offline, demo-ready)

struct LocalTranslationDictionary {
    // Frases comunes del comercio ambulante: español ↔ inglés/japonés/coreano/etc.
    private static let esEn: [String: String] = [
        // Saludos
        "hola": "hello",
        "buenos días": "good morning",
        "buenas tardes": "good afternoon",
        // Preguntas comunes
        "qué le damos": "what would you like",
        "qué va a llevar": "what would you like to order",
        "le pongo salsa": "would you like salsa",
        "picoso o no picoso": "spicy or not spicy",
        "para llevar o aquí": "to go or for here",
        "algo más": "anything else",
        // Productos
        "tacos al pastor": "al pastor tacos",
        "tacos de suadero": "suadero tacos",
        "tacos de bistec": "steak tacos",
        "quesadilla": "quesadilla",
        "tamales": "tamales",
        "tamales de verde": "green tamales",
        "tamales de mole": "mole tamales",
        "elote": "corn on the cob",
        "esquites": "corn in a cup",
        "agua de horchata": "horchata water",
        "agua de jamaica": "hibiscus water",
        "agua de limón": "lemonade",
        // Precios
        "son": "that will be",
        "pesos": "pesos",
        "cuesta": "costs",
        // Respuestas
        "sí hay": "yes we have it",
        "no hay": "sorry, we don't have it",
        "se acabó": "we're sold out",
        "ahorita le preparo": "I'll prepare it right now",
        "está bien": "alright",
        "gracias": "thank you",
        "provecho": "enjoy your meal",
        "que le vaya bien": "have a nice day",
    ]

    private static let enEs: [String: String] = [
        "hello": "hola",
        "hi": "hola",
        "good morning": "buenos días",
        "how much": "cuánto cuesta",
        "how much is this": "cuánto cuesta esto",
        "how much are the tacos": "cuánto cuestan los tacos",
        "i want": "quiero",
        "i would like": "me gustaría",
        "one please": "uno por favor",
        "two please": "dos por favor",
        "three please": "tres por favor",
        "no spicy": "sin picante",
        "spicy": "con picante",
        "to go": "para llevar",
        "for here": "para aquí",
        "thank you": "gracias",
        "thanks": "gracias",
        "delicious": "delicioso",
        "very good": "muy bueno",
        "what do you recommend": "qué me recomiendas",
        "what is this": "qué es esto",
        "water": "agua",
        "do you accept card": "aceptan tarjeta",
        "do you take credit card": "aceptan tarjeta de crédito",
        "where is the bathroom": "dónde está el baño",
        "can i pay with my phone": "puedo pagar con mi teléfono",
    ]

    static func translate(_ text: String, from source: String, to target: String) -> String {
        let lowered = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // Seleccionar diccionario
        let dict: [String: String]
        if source.hasPrefix("es") && target.hasPrefix("en") {
            dict = esEn
        } else if source.hasPrefix("en") && target.hasPrefix("es") {
            dict = enEs
        } else {
            // Para otros idiomas, intentar vía inglés como puente
            if source.hasPrefix("es") {
                let english = findBestMatch(lowered, in: esEn)
                return english ?? "[Traducción: \(text)]"
            } else {
                let spanish = findBestMatch(lowered, in: enEs)
                return spanish ?? "[Traducción: \(text)]"
            }
        }

        // Buscar coincidencia exacta o parcial
        return findBestMatch(lowered, in: dict) ?? "[Traducción: \(text)]"
    }

    private static func findBestMatch(_ text: String, in dict: [String: String]) -> String? {
        // Exacta
        if let exact = dict[text] { return exact }

        // Contiene
        for (key, value) in dict.sorted(by: { $0.key.count > $1.key.count }) {
            if text.contains(key) {
                let remaining = text.replacingOccurrences(of: key, with: "").trimmingCharacters(in: .whitespaces)
                if remaining.isEmpty {
                    return value
                }
                return "\(value) \(remaining)"
            }
        }

        // Palabras clave
        let words = text.components(separatedBy: " ")
        var translated: [String] = []
        for word in words {
            if let match = dict[word] {
                translated.append(match)
            } else {
                translated.append(word) // Mantener original si no hay traducción
            }
        }
        let result = translated.joined(separator: " ")
        return result == text ? nil : result
    }
}
