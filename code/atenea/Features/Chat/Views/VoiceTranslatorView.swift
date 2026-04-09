//
//  VoiceTranslatorView.swift
//  atenea
//
//  Interfaz de traducción de voz en tiempo real vendedor↔turista
//  El vendedor habla en español → el turista escucha en su idioma
//  El turista habla en su idioma → el vendedor escucha en español
//

import SwiftUI

struct VoiceTranslatorView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var translator = VoiceTranslationService.shared
    @State private var permissionGranted = false
    @State private var selectedTouristLanguage = "en-US"
    @State private var isMerchantMode = true // true = vendedor habla, false = turista habla
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
                LinearGradient(
                    colors: [Color(hex: "#0A0A1A"), Color(hex: "#0D1B2A")],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Language pair header
                    languageHeader

                    // Messages
                    messagesArea

                    // Current transcription
                    if translator.isListening {
                        listeningIndicator
                    }

                    // Control area
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
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showLanguagePicker = true } label: {
                        Image(systemName: "globe")
                            .font(.system(size: 18))
                            .foregroundColor(.cyan)
                    }
                }
            }
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
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
        }
    }

    // MARK: - Language Header

    private var languageHeader: some View {
        HStack(spacing: 16) {
            // Vendedor
            VStack(spacing: 4) {
                Text("🇲🇽")
                    .font(.system(size: 28))
                Text(LocalizedString("translator.spanish"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isMerchantMode ? Color.orange.opacity(0.15) : Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(isMerchantMode ? Color.orange.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
            )

            // Swap button
            Image(systemName: "arrow.left.arrow.right")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.cyan)

            // Turista
            VStack(spacing: 4) {
                let lang = availableLanguages.first { $0.code == selectedTouristLanguage }
                Text(lang?.flag ?? "🌍")
                    .font(.system(size: 28))
                Text(lang?.name ?? "English")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(!isMerchantMode ? Color.cyan.opacity(0.15) : Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(!isMerchantMode ? Color.cyan.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    // MARK: - Messages Area

    private var messagesArea: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 12) {
                    if translator.messages.isEmpty {
                        emptyState
                    }

                    ForEach(translator.messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
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
                .frame(height: 40)

            Image(systemName: "waveform.and.mic")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.15))

            Text(LocalizedString("translator.tapMicToSpeak"))
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.3))
                .multilineTextAlignment(.center)

            Text(LocalizedString("translator.merchantSpeaksSpanish"))
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.2))
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Listening Indicator

    private var listeningIndicator: some View {
        HStack(spacing: 10) {
            // Waveform animation
            ForEach(0..<5, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(isMerchantMode ? Color.orange : Color.cyan)
                    .frame(width: 4, height: CGFloat.random(in: 8...24))
                    .animation(
                        .easeInOut(duration: 0.3)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.1),
                        value: pulseAnimation
                    )
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(translator.currentTranscription.isEmpty ? LocalizedString("translator.listening") : translator.currentTranscription)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .lineLimit(2)

                Text(isMerchantMode ? LocalizedString("translator.speakInSpanish") : LocalizedString("translator.speakInYourLanguage"))
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .fill((isMerchantMode ? Color.orange : Color.cyan).opacity(0.08))
                )
        )
        .padding(.horizontal, 20)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Control Area

    private var controlArea: some View {
        VStack(spacing: 16) {
            // Toggle merchant/tourist
            HStack(spacing: 12) {
                ModeButton(
                    label: LocalizedString("translator.merchant"),
                    emoji: "🇲🇽",
                    isActive: isMerchantMode,
                    color: .orange
                ) { isMerchantMode = true }

                ModeButton(
                    label: LocalizedString("translator.tourist"),
                    emoji: availableLanguages.first { $0.code == selectedTouristLanguage }?.flag ?? "🌍",
                    isActive: !isMerchantMode,
                    color: .cyan
                ) { isMerchantMode = false }
            }

            // Big mic button
            Button {
                if translator.isListening {
                    translator.stopListening()
                } else {
                    translator.startListening(asMerchant: isMerchantMode)
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(translator.isListening
                              ? (isMerchantMode ? Color.orange : Color.cyan)
                              : Color.white.opacity(0.1))
                        .frame(width: 72, height: 72)

                    if translator.isListening {
                        Circle()
                            .fill((isMerchantMode ? Color.orange : Color.cyan).opacity(0.3))
                            .frame(width: 72, height: 72)
                            .scaleEffect(CGFloat(pulseAnimation ? 1.4 : 1.0))
                    }

                    Image(systemName: translator.isListening ? "stop.fill" : "mic.fill")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(translator.isListening ? .white : .white.opacity(0.7))
                }
            }

            if translator.isSpeaking {
                HStack(spacing: 6) {
                    Image(systemName: "speaker.wave.3.fill")
                        .font(.system(size: 12))
                    Text(LocalizedString("translator.playingTranslation"))
                        .font(.system(size: 12))
                }
                .foregroundColor(.green)
                .transition(.opacity)
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [.clear, Color(hex: "#0A0A1A")],
                startPoint: .top,
                endPoint: .bottom
            )
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
                        HStack {
                            Text(lang.flag)
                                .font(.system(size: 24))
                            Text(lang.name)
                                .foregroundColor(.primary)
                            Spacer()
                            if selectedTouristLanguage == lang.code {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.cyan)
                            }
                        }
                    }
                }
            }
            .navigationTitle(LocalizedString("translator.touristLanguage"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(LocalizedString("translator.done")) { showLanguagePicker = false }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Message Bubble

private struct MessageBubble: View {
    let message: TranslationMessage

    var body: some View {
        VStack(alignment: message.isFromMerchant ? .leading : .trailing, spacing: 6) {
            // Sender label
            HStack(spacing: 4) {
                Text(message.isFromMerchant ? "🇲🇽 \(LocalizedString("translator.merchantLabel"))" : "🌍 \(LocalizedString("translator.touristLabel"))")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.4))

                Text(message.timestamp, style: .time)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.3))
            }

            // Original text
            Text(message.originalText)
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.6))
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.05))
                )

            // Translated text (highlighted)
            HStack(spacing: 6) {
                Image(systemName: "arrow.right")
                    .font(.system(size: 10))
                    .foregroundColor(message.isFromMerchant ? .cyan : .orange)

                Text(message.translatedText)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill((message.isFromMerchant ? Color.cyan : Color.orange).opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                (message.isFromMerchant ? Color.cyan : Color.orange).opacity(0.2),
                                lineWidth: 0.5
                            )
                    )
            )
        }
        .frame(maxWidth: .infinity, alignment: message.isFromMerchant ? .leading : .trailing)
    }
}

// MARK: - Mode Button

private struct ModeButton: View {
    let label: String
    let emoji: String
    let isActive: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(emoji)
                    .font(.system(size: 16))
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(isActive ? .white : .white.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isActive ? color.opacity(0.2) : Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(isActive ? color.opacity(0.4) : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
