import SwiftUI

struct AmountEntryView: View {
    @ObservedObject var viewModel: SaleViewModel
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(LocalizedString("payment.charge"))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)

            Spacer()

            // Amount Display
            VStack(spacing: 8) {
                Text(viewModel.formattedAmount)
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3), value: viewModel.amountString)

                Text(LocalizedString("payment.currency"))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.bottom, 16)

            // Description Field
            TextField(LocalizedString("payment.conceptOptional"), text: $viewModel.saleDescription)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.white.opacity(0.08))
                )
                .padding(.horizontal, 40)
                .padding(.bottom, 24)

            // Error message
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.system(size: 14))
                    .foregroundColor(.red)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)
            }

            // Numeric Keypad
            numericKeypad
                .padding(.horizontal, 32)

            // Action Buttons
            VStack(spacing: 12) {
                // Cobrar con QR (Stripe)
                Button {
                    Task {
                        await viewModel.generatePaymentLink()
                    }
                } label: {
                    HStack(spacing: 10) {
                        if viewModel.isGenerating {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "qrcode")
                                .font(.system(size: 20, weight: .semibold))
                        }
                        Text(viewModel.isGenerating ? LocalizedString("payment.generating") : LocalizedString("payment.chargeWithCard"))
                            .font(.system(size: 18, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(
                                viewModel.canGenerate
                                    ? LinearGradient(colors: [.orange, .yellow], startPoint: .leading, endPoint: .trailing)
                                    : LinearGradient(colors: [.gray.opacity(0.3), .gray.opacity(0.3)], startPoint: .leading, endPoint: .trailing)
                            )
                    )
                }
                .disabled(!viewModel.canGenerate)

                // Tap to Pay (simulación)
                Button {
                    viewModel.startTapToPay()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "wave.3.right")
                            .font(.system(size: 20, weight: .semibold))
                        Text(LocalizedString("payment.tapToPay"))
                            .font(.system(size: 18, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(
                                viewModel.amountInCents > 0
                                    ? LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing)
                                    : LinearGradient(colors: [.gray.opacity(0.3), .gray.opacity(0.3)], startPoint: .leading, endPoint: .trailing)
                            )
                    )
                }
                .disabled(viewModel.amountInCents <= 0)

                // Cobrar en efectivo
                Button {
                    viewModel.startCashPayment()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "banknote.fill")
                            .font(.system(size: 20, weight: .semibold))
                        Text(LocalizedString("payment.chargeCash"))
                            .font(.system(size: 18, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(
                                viewModel.amountInCents > 0
                                    ? LinearGradient(colors: [.green, .mint], startPoint: .leading, endPoint: .trailing)
                                    : LinearGradient(colors: [.gray.opacity(0.3), .gray.opacity(0.3)], startPoint: .leading, endPoint: .trailing)
                            )
                    )
                }
                .disabled(viewModel.amountInCents <= 0)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 40)
        }
        .background(
            LinearGradient(
                colors: [Color(red: 0.04, green: 0.04, blue: 0.1), Color(red: 0.05, green: 0.1, blue: 0.16)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }

    // MARK: - Numeric Keypad

    private var numericKeypad: some View {
        let keys: [[String]] = [
            ["1", "2", "3"],
            ["4", "5", "6"],
            ["7", "8", "9"],
            [".", "0", "⌫"]
        ]

        return VStack(spacing: 12) {
            ForEach(keys, id: \.self) { row in
                HStack(spacing: 12) {
                    ForEach(row, id: \.self) { key in
                        Button {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            if key == "⌫" {
                                viewModel.deleteLastDigit()
                            } else {
                                viewModel.appendDigit(key)
                            }
                        } label: {
                            Text(key)
                                .font(.system(size: key == "⌫" ? 22 : 28, weight: .medium, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 60)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(.white.opacity(0.06))
                                )
                        }
                    }
                }
            }
        }
    }
}
