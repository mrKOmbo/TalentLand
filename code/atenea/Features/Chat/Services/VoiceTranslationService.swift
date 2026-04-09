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

    private func processTranscription(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let sourceCode = isMerchantSpeaking ? merchantLanguage : touristLanguage
        let targetCode = isMerchantSpeaking ? touristLanguage : merchantLanguage
        let fromMerchant = isMerchantSpeaking

        // Cache: respuesta instantánea si ya tradujimos esto
        let cacheKey = "\(sourceCode)|\(targetCode)|\(text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines))"
        if let cached = translationCache[cacheKey] {
            addMessage(original: text, translated: cached, source: sourceCode, target: targetCode, fromMerchant: fromMerchant)
            speak(cached, language: targetCode)
            return
        }

        Task {
            await MainActor.run {
                self.isTranslating = true
                self.streamingTranslation = ""
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

    // MARK: - Traducción con Claude API (streaming)

    private func translateWithClaude(_ text: String, from source: String, to target: String) async -> String {
        let apiKey = APIConfiguration.shared.claudeAPIKey
        let srcName = Self.langName(source)
        let tgtName = Self.langName(target)

        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            return LocalTranslationDictionary.translate(text, from: source, to: target)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.timeoutInterval = 8

        let body: [String: Any] = [
            "model": "claude-haiku-4-5-20251001",
            "max_tokens": 200,
            "stream": true,
            "messages": [["role": "user", "content": "\(srcName) → \(tgtName): \(text)"]],
            "system": """
            You are a real-time translator for street food vendors and tourists in Mexico City (World Cup 2026).
            Rules:
            - Return ONLY the translated text. No quotes, no explanations.
            - For Mexican food with no direct translation, keep the original name and add a brief description in parentheses. Example: "tacos de canasta (soft steamed basket tacos)", "huitlacoche (corn truffle mushroom)", "tlacoyo (stuffed oval corn cake)".
            - Common foods like tacos, quesadillas, tamales can stay as-is — tourists know them.
            - Be casual, friendly, natural. Translate the FULL sentence idiomatically.
            """
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
        } catch {
            // Fallback silencioso
        }

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
