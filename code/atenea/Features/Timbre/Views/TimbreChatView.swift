//
//  TimbreChatView.swift
//  atenea
//
//  Chat de conversación timbre entre cliente y comerciante.
//  Muestra los timbres enviados y las respuestas recibidas.
//

import SwiftUI

struct TimbreChatView: View {
    let merchantName: String
    let merchantEmoji: String
    let merchant: Merchant?

    @ObservedObject private var timbreManager = TimbreManager.shared
    @ObservedObject private var userManager = UserManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var messageText = ""
    @FocusState private var isInputFocused: Bool
    @State private var isAwaitingClaudeReply = false
    @StateObject private var claudeService = ClaudeAPIService(apiKey: APIConfiguration.shared.claudeAPIKey)

    /// Timbres enviados a este merchant, ordenados por timestamp
    private var conversation: [TimbreEvent] {
        timbreManager.sentTimbres
            .filter { $0.merchantName == merchantName }
            .sorted { $0.timestamp < $1.timestamp }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            chatHeader

            Divider().opacity(0.2)

            if conversation.isEmpty {
                emptyState
            } else {
                // Mensajes
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(conversation) { timbre in
                                VStack(spacing: 8) {
                                    // Burbuja del cliente (enviado)
                                    clientBubble(timbre)

                                    // Todas las respuestas del merchant
                                    if timbre.responses.isEmpty && !timbre.isResponded {
                                        waitingIndicator
                                    } else {
                                        ForEach(timbre.responses) { response in
                                            merchantBubble(response)
                                        }
                                    }
                                }
                                .id(timbre.id)
                            }
                        }
                        .padding(16)
                    }
                    .onChange(of: conversation.count) { _, _ in
                        if let last = conversation.last {
                            withAnimation {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                    .onAppear {
                        if let last = conversation.last {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            // Input de chat
            if merchant != nil {
                Divider().opacity(0.2)
                chatInputBar
            }
        }
        .background(Color(hex: "#F5F3F0"))
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Header

    private var chatHeader: some View {
        HStack(spacing: 12) {
            // Avatar merchant
            ZStack {
                Circle()
                    .fill(Color(hex: "#FFAE43").opacity(0.15))
                    .frame(width: 44, height: 44)
                Text(merchantEmoji)
                    .font(.system(size: 22))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(merchantName)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "#081754"))
                Text(String(format: LocalizedString("timbre.chat.messageCount"), conversation.count))
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#4A4A4A"))
            }

            Spacer()

            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(hex: "#4A4A4A"))
                    .frame(width: 32, height: 32)
                    .background(Color(hex: "#E8E2DC"))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white)
    }

    // MARK: - Client Bubble (enviado)

    private func clientBubble(_ timbre: TimbreEvent) -> some View {
        HStack {
            Spacer(minLength: 60)

            VStack(alignment: .trailing, spacing: 4) {
                // Timbres rápidos: mostrar tipo + emoji
                if timbre.type != .message {
                    HStack(spacing: 6) {
                        Text(timbre.type.emoji)
                            .font(.system(size: 16))
                        Text(timbre.type.displayName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }

                // Mensaje de texto (siempre si existe, o si es tipo .message)
                if let message = timbre.message, !message.isEmpty {
                    Text(message)
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.trailing)
                }

                Text(formatTime(timbre.timestamp))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#FFAE43"), Color(hex: "#FF8C00")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
        }
    }

    // MARK: - Merchant Bubble (respuesta)

    private func merchantBubble(_ response: TimbreResponse) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                // Respuestas rápidas: mostrar tipo + emoji
                if response.type != .message {
                    HStack(spacing: 6) {
                        Text(response.type.emoji)
                            .font(.system(size: 16))
                        Text(response.type.displayName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: "#081754"))
                    }
                }

                // Texto del mensaje
                if let message = response.message, !message.isEmpty {
                    Text(message)
                        .font(.system(size: 15))
                        .foregroundColor(Color(hex: "#333333"))
                }

                if let minutes = response.estimatedMinutes {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                        Text(String(format: LocalizedString("timbre.chat.estimatedMinutes"), minutes))
                            .font(.system(size: 12))
                    }
                    .foregroundColor(Color(hex: "#0ABF4F"))
                }

                Text(formatTime(response.timestamp))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(Color(hex: "#4A4A4A").opacity(0.5))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white)
            )
            .shadow(color: .black.opacity(0.04), radius: 4, y: 2)

            Spacer(minLength: 60)
        }
    }

    // MARK: - Waiting Indicator

    private var waitingIndicator: some View {
        HStack {
            HStack(spacing: 8) {
                ProgressView()
                    .scaleEffect(CGFloat(0.7))
                    .tint(Color(hex: "#4A4A4A"))
                Text(isAwaitingClaudeReply ? "🤖 Respondiendo..." : LocalizedString("timbre.chat.waiting"))
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#4A4A4A"))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.7))
            )

            Spacer(minLength: 60)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 40))
                .foregroundColor(Color(hex: "#4A4A4A").opacity(0.3))
            Text(LocalizedString("timbre.chat.empty"))
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "#4A4A4A"))
            Spacer()
        }
    }

    // MARK: - Chat Input Bar

    private var chatInputBar: some View {
        VStack(spacing: 8) {
            // Chips rápidos
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(TimbreType.quickActions, id: \.self) { type in
                        Button {
                            sendQuickTimbre(type: type)
                        } label: {
                            HStack(spacing: 4) {
                                Text(type.emoji)
                                    .font(.system(size: 13))
                                Text(type.displayName)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Color(hex: "#081754"))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(
                                Capsule().fill(Color(hex: "#FFAE43").opacity(0.12))
                            )
                            .overlay(
                                Capsule().stroke(Color(hex: "#FFAE43").opacity(0.3), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }

            // Campo de texto + botón enviar
            HStack(spacing: 10) {
                TextField(LocalizedString("timbre.chat.placeholder"), text: $messageText)
                    .font(.system(size: 15))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color(hex: "#F5F3F0"))
                    )
                    .focused($isInputFocused)

                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(
                            messageText.trimmingCharacters(in: .whitespaces).isEmpty
                                ? AnyShapeStyle(Color.gray.opacity(0.3))
                                : AnyShapeStyle(LinearGradient(
                                    colors: [Color(hex: "#FFAE43"), Color(hex: "#FF8C00")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                        )
                }
                .disabled(messageText.trimmingCharacters(in: .whitespaces).isEmpty)
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
        .padding(.top, 8)
        .background(Color.white)
    }

    // MARK: - Actions

    private func sendQuickTimbre(type: TimbreType) {
        guard let client = userManager.currentUser,
              let merchant = merchant else { return }

        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        let timbre = timbreManager.sendTimbre(
            from: client,
            to: merchant,
            type: type,
            message: nil,
            clientLatitude: mockUserLatitude,
            clientLongitude: mockUserLongitude
        )

        sendP2P(timbre: timbre, merchant: merchant)
    }

    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty,
              let client = userManager.currentUser,
              let merchant = merchant else { return }

        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        let timbre = timbreManager.sendTimbre(
            from: client,
            to: merchant,
            type: .message,
            message: text,
            clientLatitude: mockUserLatitude,
            clientLongitude: mockUserLongitude
        )

        sendP2P(timbre: timbre, merchant: merchant)
        messageText = ""
    }

    private func sendP2P(timbre: TimbreEvent, merchant: Merchant) {
        if let peer = RadarService.shared.discoveredMerchants.first(where: { $0.businessName == merchant.businessName }) {
            RadarService.shared.sendTimbreP2P(timbre, to: peer)
        } else {
            // Sin BLE peer — Claude simula la respuesta del merchant
            isAwaitingClaudeReply = true
            Task {
                await simulateWithClaude(timbre: timbre, merchant: merchant)
            }
        }
    }

    private func simulateWithClaude(timbre: TimbreEvent, merchant: Merchant) async {
        // Delay realista (1-2s) para simular que el merchant "lee" el timbre
        try? await Task.sleep(nanoseconds: UInt64.random(in: 1_200_000_000...2_500_000_000))

        do {
            let (type, message, minutes) = try await claudeService.generateMerchantReply(
                timbre: timbre,
                merchantEmoji: merchant.emoji,
                merchantCategory: merchant.category.displayName
            )
            await MainActor.run {
                timbreManager.applySimulatedResponse(
                    for: timbre.id,
                    type: type,
                    message: message,
                    estimatedMinutes: minutes,
                    merchantId: merchant.id
                )
                isAwaitingClaudeReply = false
            }
        } catch {
            await MainActor.run {
                timbreManager.applySimulatedResponse(
                    for: timbre.id,
                    type: .onMyWay,
                    message: "¡Ya voy para allá!",
                    estimatedMinutes: 5,
                    merchantId: merchant.id
                )
                isAwaitingClaudeReply = false
            }
        }
    }

    // MARK: - Helpers

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
