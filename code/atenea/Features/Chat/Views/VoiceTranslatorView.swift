//
//  VoiceTranslatorView.swift
//  atenea
//
//  Interfaz de traducción de voz en tiempo real vendedor↔turista
//  Coppel Brand Toolkit 2024
//

import SwiftUI

struct VoiceTranslatorView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var translator = VoiceTranslationService.shared
    @State private var permissionGranted = false
    @State private var selectedTouristLanguage = "en-US"
    @State private var isMerchantMode = true
    @State private var showLanguagePicker = false
    @State private var pulseAnimation = false

    let availableLanguages: [(code: String, name: String, flag: String)] = [
        ("en-US", "English", "🇺🇸"),
        ("ja-JP", "日本語", "🇯🇵"),
        ("ko-KR", "한국어", "🇰🇷"),
        ("de-DE", "Deutsch", "🇩🇪"),
        ("fr-FR", "Français", "🇫🇷"),
        ("pt-BR", "Português", "🇧🇷"),
        ("zh-Hans-CN", "中文", "🇨🇳"),
        ("ar-SA", "العربية", "🇸🇦"),
        ("it-IT", "Italiano", "🇮🇹"),
        ("ru-RU", "Русский", "🇷🇺"),
        ("tr-TR", "Türkçe", "🇹🇷"),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                // Fondo Coppel — blanco limpio
                Color.white
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    languageHeader
                    messagesArea

                    // Sugerencias inteligentes (Feature 3)
                    if !translator.currentSuggestions.isEmpty {
                        suggestionsBar
                    }

                    // Estado de escucha / traducción
                    if translator.isListening {
                        listeningIndicator
                    } else if translator.isTranslating {
                        translatingIndicator
                    }

                    // Frases rápidas (Feature 2) — solo cuando idle
                    if !translator.isListening && !translator.isTranslating {
                        quickPhrasesBar
                    }

                    controlArea
                }
            }
            .navigationTitle(LocalizedString("translator.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(Color(hex: "#4A4A4A"))
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showLanguagePicker = true } label: {
                        Image(systemName: "globe")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(hex: "#1C42E8"))
                    }
                }
            }
            .toolbarBackground(Color.white, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: $showLanguagePicker) {
                languagePickerSheet
            }
            .onAppear {
                translator.requestPermissions { granted in
                    permissionGranted = granted
                }
                translator.touristLanguage = selectedTouristLanguage
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    pulseAnimation = true
                }
            }
            .onChange(of: selectedTouristLanguage) { _, newValue in
                translator.touristLanguage = newValue
            }
            .onChange(of: translator.isMerchantSpeakingPublic) { _, newValue in
                if translator.isAutoDetectEnabled {
                    withAnimation(.spring(response: 0.3)) {
                        isMerchantMode = newValue
                    }
                }
            }
        }
    }

    // MARK: - Language Header

    private var languageHeader: some View {
        HStack(spacing: 12) {
            // Vendedor
            VStack(spacing: 6) {
                Text("🇲🇽")
                    .font(.system(size: 32))
                Text(LocalizedString("translator.spanish"))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: "#081754"))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isMerchantMode ? Color(hex: "#FFAE43").opacity(0.12) : Color(hex: "#EEE8E3").opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(isMerchantMode ? Color(hex: "#FFAE43").opacity(0.5) : Color.clear, lineWidth: 1.5)
                    )
            )

            // Swap
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isMerchantMode.toggle()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(Color(hex: "#1C42E8").opacity(0.08))
                        .frame(width: 40, height: 40)

                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(hex: "#1C42E8"))
                }
            }

            // Turista
            VStack(spacing: 6) {
                let lang = availableLanguages.first { $0.code == selectedTouristLanguage }
                Text(lang?.flag ?? "🌍")
                    .font(.system(size: 32))
                Text(lang?.name ?? "English")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: "#081754"))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(!isMerchantMode ? Color(hex: "#1CA8F7").opacity(0.12) : Color(hex: "#EEE8E3").opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(!isMerchantMode ? Color(hex: "#1CA8F7").opacity(0.5) : Color.clear, lineWidth: 1.5)
                    )
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white)
    }

    // MARK: - Messages Area

    private var messagesArea: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 16) {
                    if translator.messages.isEmpty {
                        emptyState
                    }

                    ForEach(translator.messages) { message in
                        TranslatorMessageBubble(message: message)
                            .id(message.id)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(Color(hex: "#EEE8E3").opacity(0.3))
            .onChange(of: translator.messages.count) { _, _ in
                if let last = translator.messages.last {
                    withAnimation {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
                .frame(height: 48)

            ZStack {
                Circle()
                    .fill(Color(hex: "#1C42E8").opacity(0.06))
                    .frame(width: 88, height: 88)

                Image(systemName: "waveform.and.mic")
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(Color(hex: "#1C42E8").opacity(0.35))
            }

            Text(LocalizedString("translator.tapMicToSpeak"))
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(Color(hex: "#4A4A4A"))
                .multilineTextAlignment(.center)

            Text(LocalizedString("translator.merchantSpeaksSpanish"))
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundColor(Color(hex: "#4A4A4A").opacity(0.6))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
    }

    // MARK: - Listening Indicator

    private var listeningIndicator: some View {
        let activeColor = isMerchantMode ? Color(hex: "#FFAE43") : Color(hex: "#1CA8F7")

        return HStack(spacing: 12) {
            // Waveform
            HStack(spacing: 3) {
                ForEach(0..<5, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(activeColor)
                        .frame(width: 4, height: CGFloat.random(in: 8...24))
                        .animation(
                            .easeInOut(duration: 0.3)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.1),
                            value: pulseAnimation
                        )
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(translator.currentTranscription.isEmpty ? LocalizedString("translator.listening") : translator.currentTranscription)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(Color(hex: "#081754"))
                    .lineLimit(2)

                Text(isMerchantMode ? LocalizedString("translator.speakInSpanish") : LocalizedString("translator.speakInYourLanguage"))
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(Color(hex: "#4A4A4A"))
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(activeColor.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(activeColor.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Translating Indicator

    private var translatingIndicator: some View {
        HStack(spacing: 10) {
            ProgressView()
                .tint(Color(hex: "#1C42E8"))

            VStack(alignment: .leading, spacing: 2) {
                if translator.streamingTranslation.isEmpty {
                    Text("Traduciendo...")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(Color(hex: "#1C42E8"))
                } else {
                    Text(translator.streamingTranslation)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: "#081754"))
                        .lineLimit(3)
                }
            }
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(hex: "#1C42E8").opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color(hex: "#1C42E8").opacity(0.15), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Quick Phrases (Feature 2)

    private var quickPhrasesBar: some View {
        let phrases = isMerchantMode
            ? VoiceTranslationService.merchantPhrases
            : VoiceTranslationService.touristPhrases
        let activeColor = isMerchantMode ? Color(hex: "#FFAE43") : Color(hex: "#1CA8F7")

        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(phrases) { phrase in
                    Button {
                        translator.sendQuickPhrase(phrase.text, asMerchant: isMerchantMode)
                    } label: {
                        HStack(spacing: 5) {
                            Text(phrase.emoji)
                                .font(.system(size: 13))
                            Text(phrase.text)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(Color(hex: "#081754"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(activeColor.opacity(0.08))
                                .overlay(
                                    Capsule()
                                        .strokeBorder(activeColor.opacity(0.25), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(translator.isTranslating || translator.isSpeaking)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
        }
        .animation(.easeInOut(duration: 0.2), value: isMerchantMode)
    }

    // MARK: - Smart Suggestions (Feature 3)

    private var suggestionsBar: some View {
        let color = translator.suggestionsForMerchant ? Color(hex: "#FFAE43") : Color(hex: "#1CA8F7")
        let label = translator.suggestionsForMerchant ? "Sugerir al vendedor:" : "Sugerir al turista:"

        return VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: "#4A4A4A").opacity(0.5))
                .padding(.leading, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(translator.currentSuggestions, id: \.self) { suggestion in
                        Button {
                            withAnimation { translator.sendSuggestion(suggestion) }
                        } label: {
                            Text(suggestion)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(Color(hex: "#081754"))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(color.opacity(0.1))
                                        .overlay(
                                            Capsule()
                                                .strokeBorder(color.opacity(0.3), lineWidth: 1)
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 8)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring(response: 0.3), value: translator.currentSuggestions)
    }

    // MARK: - Control Area (Feature 7: Auto-detect toggle)

    private var controlArea: some View {
        VStack(spacing: 20) {
            // Feature 7: Auto-detect o toggle manual
            if translator.isAutoDetectEnabled {
                HStack(spacing: 8) {
                    Image(systemName: "waveform.badge.magnifyingglass")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "#1C42E8"))
                    Text("Auto-Detect")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "#081754"))

                    if let detected = translator.detectedLanguageLabel {
                        Text("· \(detected)")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(Color(hex: "#0ABF4F"))
                            .transition(.opacity)
                    }

                    Spacer()

                    Button {
                        translator.isAutoDetectEnabled = false
                    } label: {
                        Text("Manual")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(hex: "#4A4A4A"))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(Color(hex: "#EEE8E3")))
                    }
                }
            } else {
                VStack(spacing: 10) {
                    HStack(spacing: 12) {
                        TranslatorModeButton(
                            label: LocalizedString("translator.merchant"),
                            emoji: "🇲🇽",
                            isActive: isMerchantMode,
                            color: Color(hex: "#FFAE43")
                        ) { isMerchantMode = true }

                        TranslatorModeButton(
                            label: LocalizedString("translator.tourist"),
                            emoji: availableLanguages.first { $0.code == selectedTouristLanguage }?.flag ?? "🌍",
                            isActive: !isMerchantMode,
                            color: Color(hex: "#1CA8F7")
                        ) { isMerchantMode = false }
                    }

                    Button {
                        translator.isAutoDetectEnabled = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "waveform.badge.magnifyingglass")
                                .font(.system(size: 11))
                            Text("Activar Auto-Detect")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                        }
                        .foregroundColor(Color(hex: "#1C42E8"))
                    }
                }
            }

            // Botón micrófono grande
            Button {
                if translator.isListening {
                    translator.stopListening()
                } else {
                    translator.startListening(asMerchant: isMerchantMode)
                }
            } label: {
                let activeColor = isMerchantMode ? Color(hex: "#FFAE43") : Color(hex: "#1CA8F7")

                ZStack {
                    // Pulse ring
                    if translator.isListening {
                        Circle()
                            .fill(activeColor.opacity(0.15))
                            .frame(width: 88, height: 88)
                            .scaleEffect(CGFloat(pulseAnimation ? 1.3 : 1.0))
                    }

                    // Main circle
                    Circle()
                        .fill(translator.isListening ? activeColor : Color(hex: "#1C42E8"))
                        .frame(width: 72, height: 72)
                        .shadow(
                            color: (translator.isListening ? activeColor : Color(hex: "#1C42E8")).opacity(0.3),
                            radius: 16, x: 0, y: 8
                        )

                    Image(systemName: translator.isListening ? "stop.fill" : "mic.fill")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            .accessibilityLabel(translator.isListening ? LocalizedString("translator.stopListening") : LocalizedString("translator.startListening"))

            // Speaking indicator
            if translator.isSpeaking {
                HStack(spacing: 8) {
                    Image(systemName: "speaker.wave.3.fill")
                        .font(.system(size: 13, weight: .semibold))
                    Text(LocalizedString("translator.playingTranslation"))
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                }
                .foregroundColor(Color(hex: "#0ABF4F"))
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .background(
            Color.white
                .shadow(color: Color(hex: "#081754").opacity(0.06), radius: 16, x: 0, y: -8)
        )
    }

    // MARK: - Language Picker

    private var languagePickerSheet: some View {
        NavigationStack {
            List {
                ForEach(availableLanguages, id: \.code) { lang in
                    Button {
                        selectedTouristLanguage = lang.code
                        showLanguagePicker = false
                    } label: {
                        HStack(spacing: 14) {
                            Text(lang.flag)
                                .font(.system(size: 28))

                            Text(lang.name)
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(Color(hex: "#081754"))

                            Spacer()

                            if selectedTouristLanguage == lang.code {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(Color(hex: "#1C42E8"))
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle(LocalizedString("translator.touristLanguage"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(LocalizedString("translator.done")) { showLanguagePicker = false }
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "#1C42E8"))
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Message Bubble (Coppel style)

private struct TranslatorMessageBubble: View {
    let message: TranslationMessage

    private var accentColor: Color {
        message.isFromMerchant ? Color(hex: "#FFAE43") : Color(hex: "#1CA8F7")
    }

    var body: some View {
        VStack(alignment: message.isFromMerchant ? .leading : .trailing, spacing: 8) {
            // Sender + time
            HStack(spacing: 6) {
                Text(message.isFromMerchant ? "🇲🇽 \(LocalizedString("translator.merchantLabel"))" : "🌍 \(LocalizedString("translator.touristLabel"))")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(accentColor)

                Text(message.timestamp, style: .time)
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundColor(Color(hex: "#4A4A4A").opacity(0.5))
            }

            // Original text
            Text(message.originalText)
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundColor(Color(hex: "#4A4A4A"))
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(hex: "#EEE8E3").opacity(0.6))
                )

            // Translated text
            HStack(spacing: 8) {
                Image(systemName: "arrow.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(accentColor)

                Text(message.translatedText)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: "#081754"))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(accentColor.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(accentColor.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .frame(maxWidth: .infinity, alignment: message.isFromMerchant ? .leading : .trailing)
    }
}

// MARK: - Mode Button (Coppel style)

private struct TranslatorModeButton: View {
    let label: String
    let emoji: String
    let isActive: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(emoji)
                    .font(.system(size: 18))
                Text(label)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(isActive ? Color(hex: "#081754") : Color(hex: "#4A4A4A"))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isActive ? color.opacity(0.12) : Color(hex: "#EEE8E3").opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(isActive ? color.opacity(0.4) : Color.clear, lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
