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
                    if translator.isListening { listeningIndicator }
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

    // MARK: - Control Area

    private var controlArea: some View {
        VStack(spacing: 20) {
            // Toggle vendedor/turista
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
