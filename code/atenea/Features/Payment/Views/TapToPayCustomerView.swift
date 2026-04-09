import SwiftUI

struct TapToPayCustomerView: View {
    @StateObject private var peerService = TapToPayPeerService(role: .customer)
    @Environment(\.dismiss) private var dismiss

    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    peerService.stop()
                    dismiss()
                }) {
                    Text(LocalizedString("payment.cancel"))
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                Spacer()
                Image(systemName: "lock.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.green)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            Spacer()

            switch peerService.phase {
            case .preparing:
                searchingView
            case .waitingForCard:
                readyToPayView
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

            // Distancia
            if let distance = peerService.peerDistance {
                Text(String(format: "%.0f cm", distance * 100))
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.3))
                    .padding(.bottom, 8)
            }

            // Info del pago recibido del comerciante
            if let amount = peerService.receivedAmount {
                VStack(spacing: 4) {
                    Text(String(format: "$%.2f", Double(amount) / 100.0))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text(LocalizedString("payment.currency"))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.4))
                    if let merchant = peerService.receivedMerchantName {
                        Text(merchant)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.3))
                            .padding(.top, 2)
                    }
                }
                .padding(.bottom, 50)
            } else {
                Spacer().frame(height: 50)
            }
        }
        .background(
            ZStack {
                Color.black
                customerGradient
            }
            .ignoresSafeArea()
        )
        .onAppear {
            peerService.onPaymentTriggered = {
                peerService.phase = .approved

                let notification = UINotificationFeedbackGenerator()
                notification.notificationOccurred(.success)

                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    peerService.stop()
                    dismiss()
                }
            }
            peerService.start()
        }
        .onDisappear {
            peerService.stop()
        }
    }

    // MARK: - Fases

    private var searchingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(CGSize(width: 1.5, height: 1.5))
                .tint(.white)
            Text(LocalizedString("payment.searchingMerchant"))
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
            Text(LocalizedString("payment.ensureMerchantOpen"))
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.3))
                .multilineTextAlignment(.center)
        }
    }

    private var readyToPayView: some View {
        VStack(spacing: 24) {
            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(.cyan.opacity(0.1 - Double(i) * 0.03), lineWidth: 2)
                        .frame(width: 120 + CGFloat(i) * 40, height: 120 + CGFloat(i) * 40)
                        .scaleEffect(pulseScale)
                        .animation(
                            .easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.2),
                            value: pulseScale
                        )
                }

                Image(systemName: "iphone.gen3")
                    .font(.system(size: 56, weight: .light))
                    .foregroundColor(.cyan)
            }
            .onAppear {
                pulseScale = 1.15
            }

            VStack(spacing: 8) {
                Text(LocalizedString("payment.bringCloser"))
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)

                if let merchant = peerService.receivedMerchantName {
                    Text(String(format: LocalizedString("payment.payTo"), merchant))
                        .font(.system(size: 16))
                        .foregroundColor(.cyan)
                }
            }

            Text(LocalizedString("payment.keepDevicesClose"))
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.4))
        }
    }

    private var readingView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(.cyan.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "iphone.gen3")
                    .font(.system(size: 56, weight: .medium))
                    .foregroundColor(.cyan)
                    .symbolEffect(.pulse, options: .repeating)
            }

            Text(LocalizedString("payment.connecting"))
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
        }
    }

    private var processingView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(.cyan.opacity(0.1))
                    .frame(width: 120, height: 120)

                ProgressView()
                    .scaleEffect(CGSize(width: 2, height: 2))
                    .tint(.cyan)
            }

            Text(LocalizedString("payment.processing"))
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
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

            Text(LocalizedString("payment.paymentSent"))
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.green)

            if let amount = peerService.receivedAmount,
               let merchant = peerService.receivedMerchantName {
                Text(String(format: "$%.2f a %@", Double(amount) / 100.0, merchant))
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.5))
            }
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

            Text(LocalizedString("payment.error"))
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.red)

            Text(reason)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.5))
        }
    }

    // MARK: - Gradient

    private var customerGradient: some View {
        let phaseColor: Color = {
            switch peerService.phase {
            case .preparing, .waitingForCard: return .cyan
            case .reading, .processing: return .cyan
            case .approved: return .green
            case .declined: return .red
            }
        }()

        return RadialGradient(
            colors: [phaseColor.opacity(0.12), .clear],
            center: .center,
            startRadius: 10,
            endRadius: 300
        )
    }
}
