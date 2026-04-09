//
//  MerchantTimbreChatView.swift
//  atenea
//
//  Vista de chat del merchant al recibir un timbre.
//  Muestra el mensaje del cliente y permite responder con texto libre.
//

import SwiftUI

struct MerchantTimbreChatView: View {
    let timbre: TimbreEvent

    @ObservedObject private var timbreManager = TimbreManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var messageText = ""
    @FocusState private var isInputFocused: Bool

    /// Versión actualizada del timbre (con responses actualizadas)
    private var currentTimbre: TimbreEvent {
        timbreManager.pendingTimbres.first(where: { $0.id == timbre.id }) ?? timbre
    }

    var body: some View {
        VStack(spacing: 0) {
            chatHeader

            Divider().opacity(0.2)

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Burbuja del cliente (el timbre original)
                        clientBubble(currentTimbre)
                            .id("timbre")

                        // Respuestas del merchant
                        ForEach(currentTimbre.responses) { response in
                            merchantBubble(response)
                                .id(response.id)
                        }
                    }
                    .padding(16)
                }
                .onChange(of: currentTimbre.responses.count) { _, _ in
                    if let last = currentTimbre.responses.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
                .onAppear {
                    if let last = currentTimbre.responses.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }

            Divider().opacity(0.2)
            chatInputBar
        }
        .background(Color(hex: "#F5F3F0"))
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Header

    private var chatHeader: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#FFAE43").opacity(0.15))
                    .frame(width: 44, height: 44)
                Text("👤")
                    .font(.system(size: 22))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(timbre.clientName)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "#081754"))
                Text(timbre.type.displayName)
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

    // MARK: - Client Bubble

    private func clientBubble(_ t: TimbreEvent) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if t.type != .message {
                    HStack(spacing: 6) {
                        Text(t.type.emoji)
                            .font(.system(size: 16))
                        Text(t.type.displayName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: "#081754"))
                    }
                }

                if let msg = t.message, !msg.isEmpty {
                    Text(msg)
                        .font(.system(size: 15))
                        .foregroundColor(Color(hex: "#333333"))
                }

                Text(formatTime(t.timestamp))
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

    // MARK: - Merchant Bubble

    private func merchantBubble(_ response: TimbreResponse) -> some View {
        HStack {
            Spacer(minLength: 60)

            VStack(alignment: .trailing, spacing: 4) {
                if response.type != .message {
                    HStack(spacing: 6) {
                        Text(response.type.emoji)
                            .font(.system(size: 16))
                        Text(response.type.displayName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }

                if let msg = response.message, !msg.isEmpty {
                    Text(msg)
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.trailing)
                }

                if let minutes = response.estimatedMinutes {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                        Text("~\(minutes) min")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.white.opacity(0.8))
                }

                Text(formatTime(response.timestamp))
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

    // MARK: - Input

    private var chatInputBar: some View {
        VStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(TimbreResponseType.quickActions, id: \.self) { type in
                        Button {
                            sendQuickResponse(type: type)
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
                            .background(Capsule().fill(Color(hex: "#FFAE43").opacity(0.12)))
                            .overlay(Capsule().stroke(Color(hex: "#FFAE43").opacity(0.3), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }

            HStack(spacing: 10) {
                TextField("Escribe un mensaje...", text: $messageText)
                    .font(.system(size: 15))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color(hex: "#F5F3F0"))
                    )
                    .focused($isInputFocused)

                Button { sendMessage() } label: {
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

    private func sendQuickResponse(type: TimbreResponseType) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        timbreManager.respond(to: timbre.id, with: type)
    }

    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        timbreManager.respond(to: timbre.id, with: .message, message: text)
        messageText = ""
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
