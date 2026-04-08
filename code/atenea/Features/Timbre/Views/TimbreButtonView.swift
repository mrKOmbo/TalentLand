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
            // Botón principal
            Button {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                showOptions = true
            } label: {
                ZStack {
                    // Pulse ring
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

            Text("Timbrar")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.orange)
        }
        .sheet(isPresented: $showOptions) {
            timbreOptionsSheet
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .overlay {
            if showSentConfirmation {
                sentConfirmationOverlay
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }

    // MARK: - Options Sheet

    private var timbreOptionsSheet: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 4) {
                Text(merchant.emoji)
                    .font(.system(size: 40))
                Text("Timbrar a \(merchant.businessName)")
                    .font(.system(size: 18, weight: .bold))
                Text("Elige qué quieres comunicar")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 20)

            // Opciones
            VStack(spacing: 10) {
                ForEach(TimbreType.allCases, id: \.self) { type in
                    Button {
                        selectedType = type
                    } label: {
                        HStack(spacing: 12) {
                            Text(type.emoji)
                                .font(.system(size: 24))
                                .frame(width: 44, height: 44)
                                .background(selectedType == type ? Color.orange.opacity(0.2) : Color.gray.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 10))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(type.displayName)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.primary)
                                Text(type.subtitle)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if selectedType == type {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.orange)
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedType == type ? Color.orange : Color.gray.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)

            // Mensaje opcional
            TextField("Mensaje opcional...", text: $customMessage)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

            // Enviar
            Button {
                sendTimbre()
            } label: {
                HStack {
                    Image(systemName: "bell.fill")
                    Text("Enviar timbre")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(colors: [.orange, .yellow.opacity(0.8)],
                                   startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Sent Confirmation

    private var sentConfirmationOverlay: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 36))
                .foregroundColor(.green)
            Text("Timbre enviado")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }

    // MARK: - Actions

    private func sendTimbre() {
        guard let client = userManager.currentUser else { return }

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        timbreManager.sendTimbre(
            from: client,
            to: merchant,
            type: selectedType,
            message: customMessage.isEmpty ? nil : customMessage,
            clientLatitude: mockUserLatitude,
            clientLongitude: mockUserLongitude
        )

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
