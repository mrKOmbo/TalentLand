//
//  TimbreButtonView.swift
//  atenea
//
//  Botón de timbre virtual para el cliente
//

import SwiftUI

struct TimbreButtonView: View {
    let merchant: Merchant
    @ObservedObject private var timbreManager = TimbreManager.shared
    @ObservedObject private var userManager = UserManager.shared

    @State private var showOptions = false
    @State private var selectedType: TimbreType = .ring
    @State private var customMessage = ""
    @State private var showSentConfirmation = false
    @State private var pulseAnimation = false

    var body: some View {
        VStack(spacing: 16) {
            if showSentConfirmation {
                // Confirmación de envío
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.green)
                    Text(LocalizedString("timbre.sent"))
                        .font(.system(size: 14, weight: .semibold))
                }
                .transition(.scale.combined(with: .opacity))
            } else if showOptions {
                // Opciones inline (sin sheet anidado)
                timbreOptionsContent
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                // Botón principal
                Button {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showOptions = true
                    }
                } label: {
                    ZStack {
                        let pulseColor: Color = .orange.opacity(0.3)
                        Circle()
                            .stroke(pulseColor, lineWidth: 2)
                            .frame(width: 72, height: 72)
                            .scaleEffect(pulseAnimation ? CGFloat(1.4) : CGFloat(1.0))
                            .opacity(pulseAnimation ? 0.0 : 0.6)

                        Circle()
                            .fill(
                                LinearGradient(colors: [.orange, .yellow],
                                               startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .frame(width: 56, height: 56)
                            .shadow(color: .orange.opacity(0.4), radius: 12)

                        Image(systemName: "bell.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(.plain)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        pulseAnimation = true
                    }
                }

                Text(LocalizedString("timbre.ring"))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.orange)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showOptions)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showSentConfirmation)
    }

    // MARK: - Options Content (inline, no nested sheet)

    private var timbreOptionsContent: some View {
        VStack(spacing: 16) {
            // Header
            VStack(spacing: 4) {
                Text(LocalizedString("timbre.whatToCommunicate"))
                    .font(.system(size: 16, weight: .bold))
            }

            // Opciones
            VStack(spacing: 8) {
                ForEach(TimbreType.allCases, id: \.self) { type in
                    Button {
                        selectedType = type
                    } label: {
                        HStack(spacing: 12) {
                            Text(type.emoji)
                                .font(.system(size: 24))
                                .frame(width: 40, height: 40)
                                .background(selectedType == type ? Color.orange.opacity(0.2) : Color.gray.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 10))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(type.displayName)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.primary)
                                Text(type.subtitle)
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if selectedType == type {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.orange)
                            }
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedType == type ? Color.orange : Color.gray.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            // Mensaje opcional
            TextField(LocalizedString("timbre.optionalMessage"), text: $customMessage)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 14))

            // Botones
            HStack(spacing: 12) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showOptions = false
                    }
                } label: {
                    Text(LocalizedString("timbre.cancel"))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    sendTimbre()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 14))
                        Text(LocalizedString("timbre.send"))
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(colors: [.orange, .yellow.opacity(0.8)],
                                       startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Actions

    private func sendTimbre() {
        guard let client = userManager.currentUser else {
            print("⚠️ [Timbre] No hay usuario logueado — no se puede enviar")
            return
        }

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        let timbre = timbreManager.sendTimbre(
            from: client,
            to: merchant,
            type: selectedType,
            message: customMessage.isEmpty ? nil : customMessage,
            clientLatitude: mockUserLatitude,
            clientLongitude: mockUserLongitude
        )

        // Enviar por P2P si el merchant fue descubierto por MPC
        if let peer = RadarService.shared.discoveredMerchants.first(where: { $0.businessName == merchant.businessName }) {
            RadarService.shared.sendTimbreP2P(timbre, to: peer)
            print("✅ [Timbre] Enviado P2P de \(client.name) a \(merchant.businessName)")
        } else {
            print("✅ [Timbre] Enviado LOCAL de \(client.name) a \(merchant.businessName) (merchant no descubierto por MPC)")
        }

        showOptions = false
        customMessage = ""

        withAnimation(.spring()) {
            showSentConfirmation = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showSentConfirmation = false }
        }
    }
}
