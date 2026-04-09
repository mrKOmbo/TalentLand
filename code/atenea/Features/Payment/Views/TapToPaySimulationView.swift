import SwiftUI

struct TapToPaySimulationView: View {
    @ObservedObject var viewModel: SaleViewModel
    let onCancel: () -> Void

    @StateObject private var peerService: TapToPayPeerService
    @State private var pulseScale: CGFloat = 1.0
    @State private var autoTriggerTask: Task<Void, Never>?

    init(viewModel: SaleViewModel, onCancel: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onCancel = onCancel

        let merchantName: String
        if let user = UserManager.shared.currentUser {
            merchantName = user.name
        } else {
            merchantName = LocalizedString("payment.merchant")
        }

        _peerService = StateObject(wrappedValue: TapToPayPeerService(
            role: .merchant,
            amount: viewModel.amountInCents,
            merchantName: merchantName,
            description: viewModel.saleDescription.isEmpty ? LocalizedString("payment.saleAtenea") : viewModel.saleDescription
        ))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    peerService.stop()
                    viewModel.reset()
                    onCancel()
                }) {
                    Text(LocalizedString("payment.cancel"))
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                Spacer()

                // Indicador de conexión
                HStack(spacing: 6) {
                    Circle()
                        .fill(peerService.isConnected ? .green : .orange)
                        .frame(width: 8, height: 8)
                    Text(peerService.isConnected ? LocalizedString("payment.connected") : LocalizedString("payment.searching"))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }

                Spacer()

                Image(systemName: "lock.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.green)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            Spacer()

            // Contenido central según fase
            switch peerService.phase {
            case .preparing:
                preparingView
            case .waitingForCard:
                waitingForCardView
            case .reading:
                readingView
            case .processing:
                processingView
            case .approved:
                approvedView
            case .declined(let reason):
                declinedView(reason: reason)
            }

            Spacer()

            // Distancia en tiempo real (si hay NI activo)
            if let distance = peerService.peerDistance {
                Text(String(format: "%.0f cm", distance * 100))
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.3))
                    .padding(.bottom, 8)
            }

            // Monto
            VStack(spacing: 4) {
                Text(viewModel.formattedAmount)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text(LocalizedString("payment.currency"))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.4))
                if !viewModel.saleDescription.isEmpty {
                    Text(viewModel.saleDescription)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.3))
                        .padding(.top, 2)
                }
            }
            .padding(.bottom, 50)
        }
        .background(
            ZStack {
                Color.black
                radialGradientForPhase
            }
            .ignoresSafeArea()
        )
        .onAppear {
            peerService.onPaymentTriggered = {
                // Cuando los iPhones se acercan lo suficiente → aprobar
                let result = viewModel.simulateTapToPayResult()
                viewModel.tapToPayResult = result
                peerService.phase = .approved
                peerService.sendConfirmation(approved: true)

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    viewModel.paymentStatus = .completed
                    viewModel.currentStep = .confirmed
                }
            }
            peerService.start()
        }
        .onDisappear {
            autoTriggerTask?.cancel()
            autoTriggerTask = nil
            peerService.stop()
        }
        .onChange(of: peerService.isConnected) { connected in
            if connected && peerService.phase == .waitingForCard {
                // Auto-trigger: 1 segundo después de detectar el otro iPhone
                autoTriggerTask = Task {
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    guard !Task.isCancelled else { return }
                    await MainActor.run {
                        guard peerService.phase == .waitingForCard else { return }
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                        viewModel.simulateTapCard()
                        peerService.phase = .reading
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            peerService.phase = .processing
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                peerService.onPaymentTriggered?()
                            }
                        }
                    }
                }
            } else if !connected {
                autoTriggerTask?.cancel()
                autoTriggerTask = nil
            }
        }
    }

    // MARK: - Fases

    private var preparingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(CGSize(width: 1.5, height: 1.5))
                .tint(.white)
            Text(LocalizedString("payment.searchingNearbyDevice"))
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
        }
    }

    private var waitingForCardView: some View {
        VStack(spacing: 24) {
            // Icono contactless con pulso
            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(.white.opacity(0.1 - Double(i) * 0.03), lineWidth: 2)
                        .frame(width: 120 + CGFloat(i) * 40, height: 120 + CGFloat(i) * 40)
                        .scaleEffect(pulseScale)
                        .animation(
                            .easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.2),
                            value: pulseScale
                        )
                }

                Image(systemName: "wave.3.right")
                    .font(.system(size: 64, weight: .light))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(-90))
            }
            .onAppear {
                pulseScale = 1.15
            }

            Text(LocalizedString("payment.bringOtherIphone"))
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            Text(peerService.isConnected
                 ? LocalizedString("payment.deviceDetected")
                 : LocalizedString("payment.waitingNearbyDevice"))
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)

            // Fallback: botón manual solo visible si NO hay conexión BLE (simulador)
            if !peerService.isConnected {
                Button {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    viewModel.simulateTapCard()
                    peerService.phase = .reading
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        peerService.phase = .processing
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            peerService.onPaymentTriggered?()
                        }
                    }
                } label: {
                    Text(LocalizedString("payment.simulateContact"))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.3))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Capsule().stroke(.white.opacity(0.15)))
                }
                .padding(.top, 16)
            }
        }
    }

    private var readingView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "wave.3.right")
                    .font(.system(size: 56, weight: .medium))
                    .foregroundColor(.orange)
                    .rotationEffect(.degrees(-90))
                    .symbolEffect(.pulse, options: .repeating)
            }

            Text(LocalizedString("payment.readingDevice"))
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
        }
        .onAppear {
            let impact = UIImpactFeedbackGenerator(style: .heavy)
            impact.impactOccurred()
        }
    }

    private var processingView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.1))
                    .frame(width: 120, height: 120)

                ProgressView()
                    .scaleEffect(CGSize(width: 2, height: 2))
                    .tint(.orange)
            }

            Text(LocalizedString("payment.processingPayment"))
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)

            if let result = viewModel.tapToPayResult {
                cardInfoBadge(brand: result.cardBrand, last4: result.lastFour)
                    .transition(.opacity.combined(with: .scale))
            }
        }
    }

    private var approvedView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: [.green, .mint],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 120, height: 120)
                    .shadow(color: .green.opacity(0.5), radius: 30, x: 0, y: 10)

                Image(systemName: "checkmark")
                    .font(.system(size: 56, weight: .bold))
                    .foregroundColor(.white)
            }
            .transition(.scale.combined(with: .opacity))

            Text(LocalizedString("payment.approved"))
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.green)

            if let result = viewModel.tapToPayResult {
                cardInfoBadge(brand: result.cardBrand, last4: result.lastFour)
            }
        }
        .onAppear {
            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.success)
        }
    }

    private func declinedView(reason: String) -> some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.2))
                    .frame(width: 120, height: 120)

                Image(systemName: "xmark")
                    .font(.system(size: 56, weight: .bold))
                    .foregroundColor(.red)
            }

            Text(LocalizedString("payment.declined"))
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.red)

            Text(reason)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.5))

            Button {
                peerService.stop()
                peerService.start()
            } label: {
                Text(LocalizedString("payment.tryAgain"))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(.white))
            }
            .padding(.top, 8)
        }
        .onAppear {
            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.error)
        }
    }

    // MARK: - Helpers

    private func cardInfoBadge(brand: String, last4: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "creditcard.fill")
                .font(.system(size: 16))
            Text("\(brand) •••• \(last4)")
                .font(.system(size: 15, weight: .medium, design: .monospaced))
        }
        .foregroundColor(.white.opacity(0.6))
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(.white.opacity(0.08))
        )
    }

    private var radialGradientForPhase: some View {
        let phaseColor: Color = {
            switch peerService.phase {
            case .preparing, .waitingForCard: return .blue
            case .reading, .processing: return .orange
            case .approved: return .green
            case .declined: return .red
            }
        }()

        return RadialGradient(
            colors: [phaseColor.opacity(0.15), .clear],
            center: .center,
            startRadius: 10,
            endRadius: 300
        )
        .animation(.easeInOut(duration: 0.8), value: peerService.phase)
    }
}
