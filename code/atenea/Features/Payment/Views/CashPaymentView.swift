import SwiftUI

struct CashPaymentView: View {
    @ObservedObject var viewModel: SaleViewModel
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: onCancel) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("Atrás")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                }
                Spacer()
                Text("Cobro en efectivo")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                // Balance para centrar el título
                Color.clear.frame(width: 60, height: 1)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)

            Spacer()

            // Total a cobrar
            VStack(spacing: 4) {
                Text("Total a cobrar")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                Text(viewModel.formattedAmount)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("MXN")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(.bottom, 32)

            // Monto recibido
            VStack(spacing: 8) {
                Text("Efectivo recibido")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))

                TextField("0.00", text: $viewModel.cashReceivedString)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.green)
                    .multilineTextAlignment(.center)
                    .keyboardType(.decimalPad)
                    .padding(.horizontal, 40)
            }
            .padding(.bottom, 24)

            // Cambio
            VStack(spacing: 8) {
                Text("Cambio")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))

                Text(viewModel.formattedChange)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(viewModel.changeAmount > 0 ? .yellow : .white.opacity(0.3))
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3), value: viewModel.cashReceivedString)
            }
            .padding(.bottom, 16)

            // Billetes rápidos
            VStack(spacing: 8) {
                Text("Monto rápido")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))

                HStack(spacing: 10) {
                    ForEach([20, 50, 100, 200, 500], id: \.self) { amount in
                        Button {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            viewModel.cashReceivedString = "\(amount)"
                        } label: {
                            Text("$\(amount)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(.white.opacity(0.1))
                                )
                        }
                    }
                }
            }

            Spacer()

            // Confirmar
            Button {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                viewModel.confirmCashPayment()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "banknote.fill")
                        .font(.system(size: 20, weight: .semibold))
                    Text("Confirmar cobro")
                        .font(.system(size: 18, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            viewModel.cashReceivedValue >= viewModel.amountValue && viewModel.amountValue > 0
                                ? LinearGradient(colors: [.green, .mint], startPoint: .leading, endPoint: .trailing)
                                : LinearGradient(colors: [.gray.opacity(0.3), .gray.opacity(0.3)], startPoint: .leading, endPoint: .trailing)
                        )
                )
            }
            .disabled(viewModel.cashReceivedValue < viewModel.amountValue || viewModel.amountValue <= 0)
            .padding(.horizontal, 24)
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
}
