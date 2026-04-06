//
//  AISearchView.swift
//  Atenea
//
//  Created by Claude on 10/13/25.
//

import SwiftUI
import MapKit

struct AISearchView: View {
    @Binding var isPresented: Bool
    var selectedCategory: String?
    var onNavigateToLocation: (CLLocationCoordinate2D, String, Double) -> Void
    var onShowDirections: (CLLocationCoordinate2D, String) -> Void
    var userLocation: CLLocationCoordinate2D?

    @State private var messageText: String = ""
    @FocusState private var isMessageFocused: Bool
    @State private var dragOffset: CGFloat = 0
    @GestureState private var isDragging = false
    @State private var sheetState: SheetState = .full
    @State private var showContent: Bool = false
    @State private var showHistoryModal: Bool = false
    @State private var showMemorySettings: Bool = false
    @State private var showAPIKeySettings: Bool = false
    @State private var showContext: Bool = false
    @State private var keyboardHeight: CGFloat = 0

    @State private var chatMessages: [ChatMessage] = []
    @StateObject private var claudeService = ClaudeAPIService(apiKey: APIConfiguration.shared.claudeAPIKey)
    @State private var showAPIKeyAlert: Bool = false

    enum SheetState {
        case medium
        case full

        func height(for screenHeight: CGFloat) -> CGFloat {
            switch self {
            case .medium: return min(screenHeight * 0.65, 600)
            case .full: return screenHeight - 50
            }
        }
    }

    var body: some View {
        baseContentView
            .overlay(modalsOverlay)
            .alert(String(localized: "ai.api.required"), isPresented: $showAPIKeyAlert) {
                Button(String(localized: "ai.api.configure"), role: .none) {
                    showAPIKeySettings = true
                }
                Button(String(localized: "action.cancel"), role: .cancel) { }
            } message: {
                Text(String(localized: "ai.api.requiredDesc"))
            }
            .onAppear(perform: handleAppear)
            .onDisappear(perform: handleDisappear)
    }

    private var baseContentView: some View {
        ZStack {
            Color.black.opacity(0.001)
                .ignoresSafeArea()

            mainContentView
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    @ViewBuilder
    private var modalsOverlay: some View {
        if showHistoryModal {
            HistoryView(isPresented: $showHistoryModal)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(1000)
        }

        if showMemorySettings {
            MemorySettingsView(isPresented: $showMemorySettings)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(1001)
        }

        if showAPIKeySettings {
            APIKeySettingsView(isPresented: $showAPIKeySettings)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(1002)
        }

        if showContext {
            UltraThinkRecommendationsView(
                isPresented: $showContext,
                onNavigateToLocation: { coordinate, name in
                    // Cerrar el modal de Context
                    showContext = false

                    // Cerrar el chat también
                    isPresented = false

                    // Navegar a la ubicación en el mapa
                    onNavigateToLocation(coordinate, name, 16)
                },
                onShowDirections: { coordinate, name in
                    // Cerrar el modal de Context
                    showContext = false

                    // Cerrar el chat también
                    isPresented = false

                    // Mostrar direcciones
                    onShowDirections(coordinate, name)
                },
                userLocation: userLocation
            )
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .zIndex(1003)
        }
    }

    private func handleAppear() {
        // Agregar mensaje de bienvenida si está vacío
        if chatMessages.isEmpty {
            chatMessages.append(ChatMessage(text: String(localized: "ai.search.greeting"), isUser: false))
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: 0.35)) {
                showContent = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            isMessageFocused = true
        }

        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                withAnimation(.easeOut(duration: 0.25)) {
                    keyboardHeight = keyboardFrame.height
                }
            }
        }

        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
            withAnimation(.easeOut(duration: 0.25)) {
                keyboardHeight = 0
            }
        }
    }

    private func handleDisappear() {
        showContent = false
        isMessageFocused = false

        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    private var mainContentView: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Handle bar - indicador de que es un modal
                VStack(spacing: 0) {
                    Capsule()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 36, height: 5)
                        .padding(.top, 8)
                        .padding(.bottom, 12)
                }

                headerView

                headerButtons
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                    .animation(.easeOut(duration: 0.3).delay(0.15), value: showContent)

                chatMessagesArea
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 30)
                    .animation(.easeOut(duration: 0.4).delay(0.2), value: showContent)

                Spacer(minLength: 100)

                chatInputBar
                    .padding(.horizontal, 16)
                    .padding(.bottom, keyboardHeight > 0 ? keyboardHeight : geometry.safeAreaInsets.bottom + 16)
                    .opacity(showContent ? 1 : 0)
                    .animation(.easeOut(duration: 0.25), value: keyboardHeight)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(
                ZStack {
                    // Gradiente de fondo
                    LinearGradient(
                        colors: [
                            Color(red: 0.05, green: 0.05, blue: 0.1),
                            Color.black
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    // Efecto de glassmorphism sutil en la parte superior
                    VStack {
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.05),
                                Color.white.opacity(0.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 200)

                        Spacer()
                    }
                }
            )
            .clipShape(RoundedCorner(radius: 30, corners: [.topLeft, .topRight]))
            .shadow(color: Color.black.opacity(0.5), radius: 30, x: 0, y: -10)
            .shadow(color: Color(hex: "#00D084").opacity(0.1), radius: 50, x: 0, y: -20)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .ignoresSafeArea(.container, edges: .top)
    }

    private var headerView: some View {
        HStack(alignment: .center, spacing: 12) {
            // Título con gradiente
            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "ai.search.title"))
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, Color.white.opacity(0.9)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Text(String(localized: "ai.search.poweredBy"))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Botón cerrar con glassmorphism mejorado
            Button(action: {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    isPresented = false
                }

                // Haptic feedback
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            }) {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 40, height: 40)

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.1),
                                    Color.white.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)

                    Circle()
                        .strokeBorder(
                            Color.white.opacity(0.3),
                            lineWidth: 0.5
                        )
                        .frame(width: 40, height: 40)

                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(ScaleButtonStyleSimple())
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 16)
    }

    private var headerButtons: some View {
        HStack(spacing: 8) {
            historyButton
            contextButton

            Spacer()

            apiSettingsButton
            memoryButton
        }
    }

    private var historyButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                showHistoryModal = true
            }

            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }) {
            HStack(spacing: 8) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 14, weight: .semibold))
                    .symbolEffect(.bounce, value: showHistoryModal)
                Text(String(localized: "ai.search.history"))
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
        .buttonStyle(ColorfulChipButtonStyle(
            isActive: showHistoryModal,
            gradient: LinearGradient(
                colors: [Color.blue, Color.purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        ))
    }

    private var apiSettingsButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                showAPIKeySettings = true
            }

            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }) {
            ZStack {
                // Background con gradiente
                Circle()
                    .fill(
                        APIConfiguration.shared.hasClaudeAPIKey ?
                        LinearGradient(
                            colors: [Color.green, Color(red: 0.0, green: 0.8, blue: 0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [Color(white: 0.25), Color(white: 0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)

                // Brillo superior
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.4),
                                Color.white.opacity(0.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 40, height: 40)

                // Border
                Circle()
                    .strokeBorder(
                        Color.white.opacity(APIConfiguration.shared.hasClaudeAPIKey ? 0.4 : 0.2),
                        lineWidth: 1
                    )
                    .frame(width: 40, height: 40)

                // Icono
                Image(systemName: APIConfiguration.shared.hasClaudeAPIKey ? "key.fill" : "key")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .symbolEffect(.bounce, value: APIConfiguration.shared.hasClaudeAPIKey)
            }
            .shadow(
                color: APIConfiguration.shared.hasClaudeAPIKey ? Color.green.opacity(0.5) : Color.clear,
                radius: 12,
                x: 0,
                y: 6
            )
        }
    }

    private var memoryButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                showMemorySettings = true
            }

            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }) {
            ZStack {
                // Background con gradiente
                Circle()
                    .fill(
                        showMemorySettings ?
                        LinearGradient(
                            colors: [Color.purple, Color.pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [Color(white: 0.25), Color(white: 0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)

                // Brillo superior
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.4),
                                Color.white.opacity(0.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 40, height: 40)

                // Border
                Circle()
                    .strokeBorder(
                        Color.white.opacity(showMemorySettings ? 0.4 : 0.2),
                        lineWidth: 1
                    )
                    .frame(width: 40, height: 40)

                // Icono
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .symbolEffect(.bounce, value: showMemorySettings)
            }
            .shadow(
                color: showMemorySettings ? Color.purple.opacity(0.5) : Color.clear,
                radius: 12,
                x: 0,
                y: 6
            )
        }
    }

    private var contextButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                showContext = true
            }

            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .semibold))
                    .symbolEffect(.bounce, value: showContext)
                Text(String(localized: "ai.search.context"))
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
        .buttonStyle(ColorfulChipButtonStyle(
            isActive: showContext,
            gradient: LinearGradient(
                colors: [Color.cyan, Color.teal],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        ))
    }

    private var chatMessagesArea: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    if !chatMessages.isEmpty {
                        ForEach(chatMessages) { message in
                            ChatBubble(message: message) { place in
                                isMessageFocused = false

                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    isPresented = false
                                }

                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    onShowDirections(place.coordinate, place.name)
                                }
                            }
                            .id(message.id)
                        }
                    }

                    if claudeService.isLoading {
                        HStack(spacing: 12) {
                            ProgressView()
                                .tint(Color(hex: "#00D084"))
                                .scaleEffect(CGFloat(0.9))

                            Text(String(localized: "ai.search.thinking"))
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 14)
                        .background(
                            ZStack {
                                Capsule(style: .continuous)
                                    .fill(.ultraThinMaterial)

                                Capsule(style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(hex: "#00D084").opacity(0.15),
                                                Color(hex: "#00D084").opacity(0.05)
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )

                                Capsule(style: .continuous)
                                    .strokeBorder(
                                        Color(hex: "#00D084").opacity(0.3),
                                        lineWidth: 0.5
                                    )
                            }
                            .shadow(color: Color(hex: "#00D084").opacity(0.2), radius: 12, x: 0, y: 6)
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
            .onChange(of: chatMessages.count) { _, _ in
                if let lastMessage = chatMessages.last {
                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    private var chatInputBar: some View {
        HStack(spacing: 10) {
            // Campo de texto con liquid glass
            TextField("", text: $messageText, prompt: Text(String(localized: "ai.search.placeholder")).foregroundColor(.secondary))
                .font(.system(size: 16))
                .foregroundStyle(.primary)
                .focused($isMessageFocused)
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(
                    // Liquid glass effect
                    ZStack {
                        // Base material
                        Capsule(style: .continuous)
                            .fill(.ultraThickMaterial)

                        // Gradiente de luz superior
                        Capsule(style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.25),
                                        Color.white.opacity(0.1),
                                        Color.white.opacity(0.05)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )

                        // Border highlight
                        Capsule(style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(isMessageFocused ? 0.5 : 0.3),
                                        Color.white.opacity(0.2),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.5
                            )
                    }
                    .shadow(color: isMessageFocused ? Color.blue.opacity(0.2) : Color.black.opacity(0.12), radius: 16, x: 0, y: 8)
                    .shadow(color: Color.black.opacity(0.08), radius: 2, x: 0, y: 1)
                )
                .onSubmit {
                    sendMessage()
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isMessageFocused)

            // Botón enviar premium
            Button(action: {
                sendMessage()

                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            }) {
                ZStack {
                    // Gradiente vibrante
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)

                    // Brillo superior
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 44, height: 44)

                    // Icono
                    Image(systemName: "arrow.up")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .symbolEffect(.bounce, value: messageText.isEmpty)
                }
                .shadow(color: messageText.isEmpty ? Color.clear : Color.blue.opacity(0.5), radius: 16, x: 0, y: 8)
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
            }
            .disabled(messageText.isEmpty || claudeService.isLoading)
            .opacity(messageText.isEmpty ? 0.5 : 1.0)
            .scaleEffect(messageText.isEmpty ? CGFloat(0.95) : CGFloat(1.0))
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: messageText.isEmpty)
        }
    }

    private func sendMessage() {
        guard !messageText.isEmpty else { return }

        guard APIConfiguration.shared.hasClaudeAPIKey else {
            showAPIKeyAlert = true
            return
        }

        let userMessage = messageText
        messageText = ""

        chatMessages.append(ChatMessage(text: userMessage, isUser: true))

        Task {
            do {
                let response = try await claudeService.sendMessage(userMessage, conversationHistory: chatMessages.filter { !$0.isUser || $0.text != userMessage })

                await MainActor.run {
                    chatMessages.append(ChatMessage(text: response, isUser: false))
                }
            } catch {
                await MainActor.run {
                    chatMessages.append(ChatMessage(
                        text: "Lo siento, hubo un error al procesar tu mensaje: \(error.localizedDescription)",
                        isUser: false
                    ))
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct ModernChipButtonStyle: ButtonStyle {
    let isActive: Bool
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                Group {
                    if isActive {
                        // Activo: Gradiente vibrante
                        ZStack {
                            Capsule(style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [color, color.opacity(0.85)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )

                            Capsule(style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.3),
                                            Color.white.opacity(0.0)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )

                            Capsule(style: .continuous)
                                .strokeBorder(
                                    Color.white.opacity(0.4),
                                    lineWidth: 1
                                )
                        }
                        .shadow(color: color.opacity(0.5), radius: 12, x: 0, y: 6)
                    } else {
                        // Inactivo: Glassmorphism
                        ZStack {
                            Capsule(style: .continuous)
                                .fill(.ultraThinMaterial)

                            Capsule(style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.2),
                                            Color.white.opacity(0.05)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )

                            Capsule(style: .continuous)
                                .strokeBorder(
                                    Color.white.opacity(0.3),
                                    lineWidth: 0.5
                                )
                        }
                        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                    }
                }
            )
            .scaleEffect(configuration.isPressed ? CGFloat(0.95) : CGFloat(1.0))
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct ColorfulChipButtonStyle: ButtonStyle {
    let isActive: Bool
    let gradient: LinearGradient

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                Group {
                    if isActive {
                        // Activo: Gradiente vibrante personalizado
                        ZStack {
                            Capsule(style: .continuous)
                                .fill(gradient)

                            Capsule(style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.4),
                                            Color.white.opacity(0.0)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )

                            Capsule(style: .continuous)
                                .strokeBorder(
                                    Color.white.opacity(0.5),
                                    lineWidth: 1
                                )
                        }
                        .shadow(color: Color.white.opacity(0.3), radius: 16, x: 0, y: 8)
                        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                    } else {
                        // Inactivo: Glassmorphism con tono del gradiente
                        ZStack {
                            Capsule(style: .continuous)
                                .fill(.ultraThinMaterial)

                            Capsule(style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.15),
                                            Color.white.opacity(0.05)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )

                            Capsule(style: .continuous)
                                .strokeBorder(
                                    Color.white.opacity(0.3),
                                    lineWidth: 0.5
                                )
                        }
                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                    }
                }
            )
            .scaleEffect(configuration.isPressed ? CGFloat(0.95) : CGFloat(1.0))
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct ChatBubble: View {
    let message: ChatMessage
    var onPlaceSelected: ((PlaceLocation) -> Void)?
    @State private var appeared: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            if message.isUser {
                Spacer(minLength: 60)
            }

            if message.isUser {
                // Mensaje del usuario con gradiente vibrante
                Text(message.text)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 13)
                    .background(
                        ZStack {
                            // Gradiente principal
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "#C8FF00"), Color(hex: "#00D084")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )

                            // Brillo superior sutil
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.35),
                                            Color.white.opacity(0.0)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )

                            // Border sutil
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .strokeBorder(
                                    Color.white.opacity(0.3),
                                    lineWidth: 0.5
                                )
                        }
                        .shadow(color: Color(hex: "#00D084").opacity(0.25), radius: 12, x: 0, y: 6)
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    )
            } else {
                // Mensaje de Claude con glassmorphism
                ClaudeMessageView(message: message.text) { place in
                    onPlaceSelected?(place)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 13)
                .background(
                    ZStack {
                        // Base material
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(.ultraThinMaterial)

                        // Gradiente sutil
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.12),
                                        Color.white.opacity(0.06),
                                        Color.white.opacity(0.03)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        // Border de cristal
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.2),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.5
                            )
                    }
                    .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 6)
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                )
            }

            if !message.isUser {
                Spacer(minLength: 60)
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                appeared = true
            }
        }
    }
}

// MARK: - History View

struct HistoryView: View {
    @Binding var isPresented: Bool
    @State private var searchHistoryText: String = ""
    @FocusState private var isHistorySearchFocused: Bool

    // Datos de ejemplo del historial
    @State private var searchHistory: [SearchHistoryItem] = [
        SearchHistoryItem(query: "Restaurantes mexicanos cerca", timestamp: Date().addingTimeInterval(-3600)),
        SearchHistoryItem(query: "Estadio Azteca dirección", timestamp: Date().addingTimeInterval(-7200)),
        SearchHistoryItem(query: "Mejores tacos en Guadalajara", timestamp: Date().addingTimeInterval(-86400)),
        SearchHistoryItem(query: "Transporte público CDMX", timestamp: Date().addingTimeInterval(-172800)),
        SearchHistoryItem(query: "Hoteles cerca del estadio", timestamp: Date().addingTimeInterval(-259200)),
        SearchHistoryItem(query: "Clima en Monterrey", timestamp: Date().addingTimeInterval(-345600)),
        SearchHistoryItem(query: "Vuelos a Toronto", timestamp: Date().addingTimeInterval(-432000))
    ]

    var filteredHistory: [SearchHistoryItem] {
        if searchHistoryText.isEmpty {
            return searchHistory
        } else {
            return searchHistory.filter { $0.query.localizedCaseInsensitiveContains(searchHistoryText) }
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            isPresented = false
                        }
                    }

                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 50)

                    VStack(spacing: 0) {
                        // Header
                        HStack {
                            Button(action: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    isPresented = false
                                }
                            }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(
                                        Circle()
                                            .fill(Color(white: 0.15))
                                    )
                            }

                            Spacer()

                            Text(String(localized: "ai.history.title"))
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)

                            Spacer()

                            Button(action: {
                                withAnimation {
                                    searchHistory.removeAll()
                                }
                            }) {
                                Image(systemName: "trash")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding(12)
                                    .background(
                                        Circle()
                                            .fill(Color(white: 0.15))
                                    )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 16)

                        // Buscador
                        HStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.5))

                            TextField("", text: $searchHistoryText, prompt: Text(String(localized: "ai.history.searchPlaceholder")).foregroundColor(.white.opacity(0.3)))
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .focused($isHistorySearchFocused)

                            if !searchHistoryText.isEmpty {
                                Button(action: {
                                    searchHistoryText = ""
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(white: 0.12))
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)

                        // Lista
                        ScrollView {
                            VStack(spacing: 0) {
                                if filteredHistory.isEmpty {
                                    VStack(spacing: 16) {
                                        Image(systemName: searchHistoryText.isEmpty ? "clock" : "magnifyingglass")
                                            .font(.system(size: 48))
                                            .foregroundColor(.white.opacity(0.3))
                                            .padding(.top, 60)

                                        Text(searchHistoryText.isEmpty ? String(localized: "ai.history.empty") : String(localized: "ai.history.noResults"))
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.white.opacity(0.7))

                                        Text(searchHistoryText.isEmpty ? String(localized: "ai.history.emptyDesc") : String(localized: "ai.history.tryAnother"))
                                            .font(.system(size: 14))
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                } else {
                                    ForEach(filteredHistory) { item in
                                        HistoryItemRow(item: item) {
                                            print("📝 Búsqueda seleccionada: \(item.query)")
                                        } onDelete: {
                                            withAnimation {
                                                if let index = searchHistory.firstIndex(where: { $0.id == item.id }) {
                                                    searchHistory.remove(at: index)
                                                }
                                            }
                                        }

                                        if item.id != filteredHistory.last?.id {
                                            Divider()
                                                .background(Color.white.opacity(0.1))
                                                .padding(.leading, 60)
                                        }
                                    }
                                }
                            }
                            .padding(.bottom, 30)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: geometry.size.height - 50)
                    .background(Color.black)
                    .clipShape(
                        RoundedCorner(radius: 30, corners: [.topLeft, .topRight])
                    )
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isHistorySearchFocused = true
            }
        }
    }
}

// MARK: - Search History Item

struct SearchHistoryItem: Identifiable {
    let id = UUID()
    let query: String
    let timestamp: Date

    var formattedTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        formatter.locale = Locale(identifier: "es")
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}

// MARK: - History Item Row

struct HistoryItemRow: View {
    let item: SearchHistoryItem
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: "#00D084"))
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.query)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)

                    Text(item.formattedTime)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.5))
                }

                Spacer()

                Button(action: onDelete) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.4))
                        .padding(8)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Memory Settings View

struct MemorySettingsView: View {
    @Binding var isPresented: Bool

    @State private var favoriteFoods: Set<String> = ["Mexican", "Italian", "Japanese", "Thai"]
    @State private var coffeePreference: String? = "Local Coffee Shops"
    @State private var dietaryRestrictions: Set<String> = ["No Restrictions"]
    @State private var specialConsiderations: Set<String> = []
    @State private var measurementUnit: String = "Kilometers"
    @State private var showProfileView: Bool = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            isPresented = false
                        }
                    }

                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 50)

                    VStack(spacing: 0) {
                        // Header
                        HStack {
                            Spacer()

                            Button(action: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    showProfileView = true
                                }
                            }) {
                                Circle()
                                    .fill(Color(white: 0.15))
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(.white.opacity(0.7))
                                    )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 16)

                        Text("Update your Memory")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 24)

                        ScrollView {
                            VStack(spacing: 32) {
                                MemorySection(
                                    title: "Favorite Foods",
                                    subtitle: "Let us know what types of foods you like most so we can show you more relevant suggestions faster."
                                ) {
                                    VStack(spacing: 0) {
                                        MemoryCheckboxItem(emoji: "🍝", title: "Italian", isSelected: favoriteFoods.contains("Italian")) {
                                            toggleSelection(&favoriteFoods, "Italian")
                                        }
                                        MemoryCheckboxItem(emoji: "🌮", title: "Mexican", isSelected: favoriteFoods.contains("Mexican")) {
                                            toggleSelection(&favoriteFoods, "Mexican")
                                        }
                                        MemoryCheckboxItem(emoji: "🍱", title: "Japanese", isSelected: favoriteFoods.contains("Japanese")) {
                                            toggleSelection(&favoriteFoods, "Japanese")
                                        }
                                        MemoryCheckboxItem(emoji: "🇨🇳", title: "Chinese", isSelected: favoriteFoods.contains("Chinese")) {
                                            toggleSelection(&favoriteFoods, "Chinese")
                                        }
                                        MemoryCheckboxItem(emoji: "🫒", title: "Mediterranean", isSelected: favoriteFoods.contains("Mediterranean")) {
                                            toggleSelection(&favoriteFoods, "Mediterranean")
                                        }
                                        MemoryCheckboxItem(emoji: "🇹🇭", title: "Thai", isSelected: favoriteFoods.contains("Thai")) {
                                            toggleSelection(&favoriteFoods, "Thai")
                                        }
                                        MemoryCheckboxItem(emoji: "🐌", title: "French", isSelected: favoriteFoods.contains("French")) {
                                            toggleSelection(&favoriteFoods, "French")
                                        }
                                        MemoryCheckboxItem(emoji: "🍔", title: "American", isSelected: favoriteFoods.contains("American")) {
                                            toggleSelection(&favoriteFoods, "American")
                                        }
                                        MemoryCheckboxItem(emoji: "🥙", title: "Middle Eastern", isSelected: favoriteFoods.contains("Middle Eastern")) {
                                            toggleSelection(&favoriteFoods, "Middle Eastern")
                                        }
                                        MemoryCheckboxItem(emoji: "🍜", title: "Vietnamese", isSelected: favoriteFoods.contains("Vietnamese")) {
                                            toggleSelection(&favoriteFoods, "Vietnamese")
                                        }
                                        MemoryCheckboxItem(emoji: "🇰🇷", title: "Korean", isSelected: favoriteFoods.contains("Korean")) {
                                            toggleSelection(&favoriteFoods, "Korean")
                                        }
                                    }
                                }

                                MemorySection(
                                    title: "Coffee Shop Preferences",
                                    subtitle: "Any special considerations that would make your search experience much better?"
                                ) {
                                    VStack(spacing: 0) {
                                        MemoryCheckboxItem(emoji: "👨‍💼", title: "Large Chains (e.g. \"Starbucks\")", isSelected: coffeePreference == "Large Chains") {
                                            coffeePreference = coffeePreference == "Large Chains" ? nil : "Large Chains"
                                        }
                                        MemoryCheckboxItem(emoji: "😊", title: "Local Coffee Shops", isSelected: coffeePreference == "Local Coffee Shops") {
                                            coffeePreference = coffeePreference == "Local Coffee Shops" ? nil : "Local Coffee Shops"
                                        }
                                    }
                                }

                                MemorySection(
                                    title: "Dietary Considerations",
                                    subtitle: "Add any dietary preferences, so you get the right better follow up question suggestions."
                                ) {
                                    VStack(spacing: 0) {
                                        MemoryCheckboxItem(emoji: "🥦", title: "Vegan", isSelected: dietaryRestrictions.contains("Vegan")) {
                                            toggleSelection(&dietaryRestrictions, "Vegan")
                                        }
                                        MemoryCheckboxItem(emoji: "🥚", title: "Vegetarian", isSelected: dietaryRestrictions.contains("Vegetarian")) {
                                            toggleSelection(&dietaryRestrictions, "Vegetarian")
                                        }
                                        MemoryCheckboxItem(emoji: "🌾", title: "Gluten Free", isSelected: dietaryRestrictions.contains("Gluten Free")) {
                                            toggleSelection(&dietaryRestrictions, "Gluten Free")
                                        }
                                        MemoryCheckboxItem(emoji: "✨", title: "I Have No Dietary Restrictions", isSelected: dietaryRestrictions.contains("No Restrictions")) {
                                            toggleSelection(&dietaryRestrictions, "No Restrictions")
                                        }
                                    }
                                }

                                MemorySection(
                                    title: "Special Considerations",
                                    subtitle: "Any special considerations that would make your search experience much better?"
                                ) {
                                    VStack(spacing: 0) {
                                        MemoryCheckboxItem(emoji: "♿", title: "Wheelchair Accessible", isSelected: specialConsiderations.contains("Wheelchair Accessible")) {
                                            toggleSelection(&specialConsiderations, "Wheelchair Accessible")
                                        }
                                        MemoryCheckboxItem(emoji: "🎧", title: "Sensory Sensitivity", isSelected: specialConsiderations.contains("Sensory Sensitivity")) {
                                            toggleSelection(&specialConsiderations, "Sensory Sensitivity")
                                        }
                                    }
                                }

                                MemorySection(
                                    title: "Measurement Preferences",
                                    subtitle: "Do you have a preference for miles or kilometers?"
                                ) {
                                    VStack(spacing: 0) {
                                        MemoryCheckboxItem(emoji: "🇺🇸", title: "Miles", isSelected: measurementUnit == "Miles") {
                                            measurementUnit = "Miles"
                                        }
                                        MemoryCheckboxItem(emoji: "🌍", title: "Kilometers", isSelected: measurementUnit == "Kilometers") {
                                            measurementUnit = "Kilometers"
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 30)
                        }

                        VStack(spacing: 0) {
                            Divider()
                                .background(Color.white.opacity(0.1))

                            Button(action: {
                                print("💾 Guardando preferencias de Memory...")
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    isPresented = false
                                }
                            }) {
                                Text("Update Memory")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(Color(hex: "#C8FF00"))
                                    )
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                            .padding(.bottom, 34)
                        }
                        .background(Color.black)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: geometry.size.height - 50)
                    .background(Color.black)
                    .clipShape(
                        RoundedCorner(radius: 30, corners: [.topLeft, .topRight])
                    )
                }
            }
        }
        .overlay(
            Group {
                if showProfileView {
                    ProfileView(
                        isPresented: $showProfileView,
                        favoriteFoods: favoriteFoods,
                        coffeePreference: coffeePreference,
                        dietaryRestrictions: dietaryRestrictions,
                        specialConsiderations: specialConsiderations,
                        measurementUnit: measurementUnit
                    )
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                    .zIndex(1002)
                }
            }
        )
    }

    private func toggleSelection(_ set: inout Set<String>, _ item: String) {
        if set.contains(item) {
            set.remove(item)
        } else {
            set.insert(item)
        }
    }
}

// MARK: - Memory Section

struct MemorySection<Content: View>: View {
    let title: String
    let subtitle: String
    let content: Content

    init(title: String, subtitle: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)

            Text(subtitle)
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.5))
                .fixedSize(horizontal: false, vertical: true)

            content
        }
    }
}

// MARK: - Memory Checkbox Item

struct MemoryCheckboxItem: View {
    let emoji: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(emoji)
                    .font(.system(size: 24))

                Text(title)
                    .font(.system(size: 17))
                    .foregroundColor(.white)

                Spacer()

                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isSelected ? Color.blue : Color.white.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Profile View

struct ProfileView: View {
    @Binding var isPresented: Bool
    let favoriteFoods: Set<String>
    let coffeePreference: String?
    let dietaryRestrictions: Set<String>
    let specialConsiderations: Set<String>
    let measurementUnit: String
    @ObservedObject var userManager = UserManager.shared

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            isPresented = false
                        }
                    }

                VStack(spacing: 0) {
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(Color.black)
                            .frame(height: geometry.safeAreaInsets.top > 0 ? geometry.safeAreaInsets.top + 10 : 50)

                        HStack {
                            Button(action: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    isPresented = false
                                }
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding(12)
                                    .background(
                                        Circle()
                                            .fill(Color(white: 0.15))
                                    )
                            }

                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        .padding(.bottom, 8)

                        HStack(spacing: 16) {
                            // Foto de perfil
                            ZStack {
                                if let user = userManager.currentUser, let profileImage = user.profileImage {
                                    // Intentar cargar la imagen del usuario
                                    Image(profileImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 80, height: 80)
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .strokeBorder(
                                                    LinearGradient(
                                                        colors: [Color(hex: "#C8FF00"), Color(hex: "#00D084")],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    ),
                                                    lineWidth: 3
                                                )
                                        )
                                } else {
                                    // Gradiente de fondo si no hay imagen
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color(hex: "#C8FF00"), Color(hex: "#00D084")]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 80, height: 80)

                                    // Brillo superior
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.35),
                                                    Color.white.opacity(0.0)
                                                ],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .frame(width: 80, height: 80)

                                    // Icono de persona
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 40, weight: .semibold))
                                        .foregroundColor(.black.opacity(0.8))
                                }
                            }
                            .frame(width: 80, height: 80)
                            .shadow(color: Color(hex: "#00D084").opacity(0.5), radius: 16, x: 0, y: 8)

                            VStack(alignment: .leading, spacing: 6) {
                                Text(userManager.currentUser?.name ?? "Usuario")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)

                                if let user = userManager.currentUser, let country = user.country {
                                    HStack(spacing: 6) {
                                        Text(flagForCountry(country))
                                            .font(.system(size: 20))

                                        Text(country)
                                            .font(.system(size: 16))
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                }

                                // Badge de rol
                                if let user = userManager.currentUser {
                                    HStack(spacing: 6) {
                                        Image(systemName: user.isAdmin ? "star.fill" : "person.fill")
                                            .font(.system(size: 10, weight: .bold))
                                        Text(user.role.displayName)
                                            .font(.system(size: 13, weight: .semibold))
                                    }
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color(hex: "#C8FF00"), Color(hex: "#00D084")],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                    )
                                }
                            }

                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)

                        Divider()
                            .background(Color.white.opacity(0.1))
                            .padding(.horizontal, 20)
                            .padding(.bottom, 24)

                        ScrollView {
                            VStack(spacing: 32) {
                                // Información Personal
                                if let user = userManager.currentUser {
                                    ProfileInfoSection(title: "Personal Information", icon: "person.text.rectangle") {
                                        VStack(alignment: .leading, spacing: 12) {
                                            // Email
                                            ProfileInfoItem(text: user.email, emoji: "📧")

                                            // Teléfono
                                            if let phone = user.phoneNumber {
                                                ProfileInfoItem(text: phone, emoji: "📱")
                                            }

                                            // Edad
                                            if let age = user.age {
                                                ProfileInfoItem(text: "\(age) años", emoji: "🎂")
                                            }

                                            // Accesibilidad
                                            if user.needsAccessibilityFeatures {
                                                ProfileInfoItem(
                                                    text: accessibilityDescription(user.accessibilityOption),
                                                    emoji: "♿"
                                                )
                                            }

                                            // Fecha de creación
                                            ProfileInfoItem(
                                                text: "Miembro desde \(formatDate(user.createdAt))",
                                                emoji: "📅"
                                            )
                                        }
                                    }
                                }

                                if !favoriteFoods.isEmpty {
                                    ProfileInfoSection(title: "Favorite Foods", icon: "fork.knife") {
                                        VStack(alignment: .leading, spacing: 12) {
                                            ForEach(Array(favoriteFoods).sorted(), id: \.self) { food in
                                                ProfileInfoItem(text: food, emoji: emojiForFood(food))
                                            }
                                        }
                                    }
                                }

                                if let coffee = coffeePreference {
                                    ProfileInfoSection(title: "Coffee Shop Preference", icon: "cup.and.saucer.fill") {
                                        ProfileInfoItem(text: coffee, emoji: coffee == "Large Chains" ? "👨‍💼" : "😊")
                                    }
                                }

                                if !dietaryRestrictions.isEmpty {
                                    ProfileInfoSection(title: "Dietary Considerations", icon: "leaf.fill") {
                                        VStack(alignment: .leading, spacing: 12) {
                                            ForEach(Array(dietaryRestrictions).sorted(), id: \.self) { restriction in
                                                ProfileInfoItem(text: restriction, emoji: emojiForDietary(restriction))
                                            }
                                        }
                                    }
                                }

                                if !specialConsiderations.isEmpty {
                                    ProfileInfoSection(title: "Special Considerations", icon: "star.fill") {
                                        VStack(alignment: .leading, spacing: 12) {
                                            ForEach(Array(specialConsiderations).sorted(), id: \.self) { consideration in
                                                ProfileInfoItem(text: consideration, emoji: consideration == "Wheelchair Accessible" ? "♿" : "🎧")
                                            }
                                        }
                                    }
                                }

                                ProfileInfoSection(title: "Measurement Preference", icon: "ruler.fill") {
                                    ProfileInfoItem(text: measurementUnit, emoji: measurementUnit == "Miles" ? "🇺🇸" : "🌍")
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 40)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
                }
            }
        }
        .onAppear {
            print("🔍 ProfileView appeared - Current user: \(userManager.currentUser?.name ?? "nil")")
            print("🔍 User email: \(userManager.currentUser?.email ?? "nil")")
            print("🔍 User country: \(userManager.currentUser?.country ?? "nil")")
        }
    }

    private func emojiForFood(_ food: String) -> String {
        switch food {
        case "Italian": return "🍝"
        case "Mexican": return "🌮"
        case "Japanese": return "🍱"
        case "Chinese": return "🇨🇳"
        case "Mediterranean": return "🫒"
        case "Thai": return "🇹🇭"
        case "French": return "🐌"
        case "American": return "🍔"
        case "Middle Eastern": return "🥙"
        case "Vietnamese": return "🍜"
        case "Korean": return "🇰🇷"
        default: return "🍽️"
        }
    }

    private func emojiForDietary(_ restriction: String) -> String {
        switch restriction {
        case "Vegan": return "🥦"
        case "Vegetarian": return "🥚"
        case "Gluten Free": return "🌾"
        case "No Restrictions": return "✨"
        default: return "🍽️"
        }
    }

    private func flagForCountry(_ country: String) -> String {
        switch country.lowercased() {
        case "mexico", "méxico": return "🇲🇽"
        case "usa", "united states", "estados unidos": return "🇺🇸"
        case "canada", "canadá": return "🇨🇦"
        case "spain", "españa": return "🇪🇸"
        case "france", "francia": return "🇫🇷"
        case "germany", "alemania": return "🇩🇪"
        case "italy", "italia": return "🇮🇹"
        case "uk", "united kingdom", "reino unido": return "🇬🇧"
        case "brazil", "brasil": return "🇧🇷"
        case "argentina": return "🇦🇷"
        case "colombia": return "🇨🇴"
        case "japan", "japón": return "🇯🇵"
        case "china": return "🇨🇳"
        case "south korea", "corea del sur": return "🇰🇷"
        default: return "🌍"
        }
    }

    private func accessibilityDescription(_ option: AccessibilityOption) -> String {
        switch option {
        case .visual: return "Discapacidad Visual"
        case .hearing: return "Discapacidad Auditiva"
        case .motor: return "Discapacidad Motriz"
        case .cognitive: return "Discapacidad Cognitiva"
        case .speech: return "Discapacidad del Habla"
        case .neurological: return "Discapacidad Neurológica"
        case .multiple: return "Múltiples Discapacidades"
        default: return ""
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale.current
        return formatter.string(from: date)
    }
}

// MARK: - Profile Info Section

struct ProfileInfoSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content

    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                // Icono con fondo circular
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#C8FF00"), Color(hex: "#00D084")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 38, height: 38)

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 38, height: 38)

                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)
                }
                .shadow(color: Color(hex: "#00D084").opacity(0.5), radius: 12, x: 0, y: 6)

                Text(title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, Color.white.opacity(0.85)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Scale Button Style Simple

struct ScaleButtonStyleSimple: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? CGFloat(0.92) : CGFloat(1.0))
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Profile Info Item

struct ProfileInfoItem: View {
    let text: String
    let emoji: String

    var body: some View {
        HStack(spacing: 14) {
            // Emoji con fondo circular
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.15),
                                Color.white.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)

                Circle()
                    .strokeBorder(
                        Color.white.opacity(0.2),
                        lineWidth: 0.5
                    )
                    .frame(width: 44, height: 44)

                Text(emoji)
                    .font(.system(size: 22))
            }

            Text(text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.95))

            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            ZStack {
                // Base glassmorphism
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.ultraThinMaterial)

                // Gradiente sutil
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.1),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Border
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        Color.white.opacity(0.2),
                        lineWidth: 0.5
                    )
            }
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - API Key Settings View

struct APIKeySettingsView: View {
    @Binding var isPresented: Bool
    @State private var apiKeyText: String = APIConfiguration.shared.claudeAPIKey
    @State private var showSuccessMessage: Bool = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            isPresented = false
                        }
                    }

                VStack(spacing: 0) {
                    Spacer().frame(height: 50)

                    ScrollView {
                        VStack(spacing: 24) {
                            // Header
                            HStack {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("API Configuration")
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundColor(.white)

                                    HStack(spacing: 8) {
                                        Circle()
                                            .fill(APIConfiguration.shared.hasClaudeAPIKey ? Color.green : Color.orange)
                                            .frame(width: 8, height: 8)

                                        Text(APIConfiguration.shared.hasClaudeAPIKey ? "Configurado" : "No configurado")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                }

                                Spacer()

                                Button(action: {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                        isPresented = false
                                    }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(.white.opacity(0.3))
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 20)

                            // Información
                            VStack(alignment: .leading, spacing: 16) {
                                HStack(spacing: 12) {
                                    Image(systemName: "info.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(Color(hex: "#C8FF00"))

                                    Text("Necesitas una API key de Claude para usar el chat de IA")
                                        .font(.system(size: 15))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(hex: "#C8FF00").opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color(hex: "#C8FF00").opacity(0.3), lineWidth: 1)
                                        )
                                )
                            }
                            .padding(.horizontal, 24)

                            // Pasos para obtener API Key
                            VStack(alignment: .leading, spacing: 20) {
                                Text("Cómo obtener tu API Key:")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)

                                VStack(alignment: .leading, spacing: 16) {
                                    StepView(number: 1, text: "Visita la Consola de Anthropic")
                                    StepView(number: 2, text: "Inicia sesión o crea una cuenta")
                                    StepView(number: 3, text: "Ve a 'API Keys' y genera una nueva key")
                                    StepView(number: 4, text: "Copia la key y pégala abajo")
                                }

                                // Botón para abrir el link
                                Button(action: {
                                    if let url = URL(string: "https://console.anthropic.com/settings/keys") {
                                        UIApplication.shared.open(url)
                                    }
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "key.fill")
                                            .font(.system(size: 16))

                                        Text("Obtener API Key")
                                            .font(.system(size: 16, weight: .semibold))

                                        Image(systemName: "arrow.up.right")
                                            .font(.system(size: 14))
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(
                                        LinearGradient(
                                            colors: [Color.purple, Color.blue],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(12)
                                }
                            }
                            .padding(.horizontal, 24)

                            // Campo de texto para API Key
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Tu API Key")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)

                                TextField("sk-ant-api...", text: $apiKeyText)
                                    .font(.system(size: 15, design: .monospaced))
                                    .foregroundColor(.white)
                                    .padding(16)
                                    .background(Color(white: 0.12))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                            }
                            .padding(.horizontal, 24)

                            // Mensaje de éxito
                            if showSuccessMessage {
                                HStack(spacing: 12) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.green)

                                    Text("API Key guardada exitosamente")
                                        .font(.system(size: 15))
                                        .foregroundColor(.white)
                                }
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.green.opacity(0.2))
                                )
                                .padding(.horizontal, 24)
                                .transition(.opacity.combined(with: .scale))
                            }

                            // Botón Guardar
                            Button(action: {
                                APIConfiguration.shared.claudeAPIKey = apiKeyText
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    showSuccessMessage = true
                                }

                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                        isPresented = false
                                    }
                                }
                            }) {
                                Text("Guardar API Key")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color(hex: "#C8FF00"))
                                    .cornerRadius(14)
                            }
                            .padding(.horizontal, 24)
                            .disabled(apiKeyText.isEmpty)
                            .opacity(apiKeyText.isEmpty ? 0.5 : 1.0)

                            // Nota de seguridad
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 8) {
                                    Image(systemName: "lock.shield.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.5))

                                    Text("Tu API key se guarda de forma segura en tu dispositivo")
                                        .font(.system(size: 13))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 40)
                        }
                        .padding(.top, 10)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: geometry.size.height - 50)
                    .background(Color.black)
                    .clipShape(RoundedCorner(radius: 30, corners: [.topLeft, .topRight]))
                }
            }
        }
    }
}

// MARK: - Step View

struct StepView: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#00D084"))
                    .frame(width: 28, height: 28)

                Text("\(number)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.black)
            }

            Text(text)
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.9))

            Spacer()
        }
    }
}

// MARK: - Helpers
// RoundedCorner y Color extension ya están definidos en VenueBottomSheet.swift

#Preview {
    AISearchView(
        isPresented: .constant(true),
        selectedCategory: "coffee",
        onNavigateToLocation: { _, _, _ in },
        onShowDirections: { _, _ in },
        userLocation: CLLocationCoordinate2D(latitude: 19.4326, longitude: -99.1332)
    )
}
