import SwiftUI
import ConfettiSwiftUI

struct PaymentConfirmedView: View {
    @ObservedObject var viewModel: SaleViewModel
    let onNewSale: () -> Void
    let onClose: () -> Void

    @State private var checkmarkScale: CGFloat = 0
    @State private var confettiCounter = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Checkmark animation
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: [.green, .mint],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: .green.opacity(0.4), radius: 20, x: 0, y: 8)

                Image(systemName: "checkmark")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)
            }
            .scaleEffect(checkmarkScale)
            .padding(.bottom, 32)

            Text("¡Pago recibido!")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)

            Text(viewModel.formattedAmount)
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.top, 8)

            Text("MXN")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))

            if !viewModel.saleDescription.isEmpty {
                Text(viewModel.saleDescription)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.4))
                    .padding(.top, 8)
            }

            Text(Date(), style: .time)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.3))
                .padding(.top, 12)

            Spacer()

            // Actions
            VStack(spacing: 12) {
                Button {
                    onNewSale()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                        Text("Nuevo cobro")
                    }
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(LinearGradient(colors: [.orange, .yellow],
                                                  startPoint: .leading, endPoint: .trailing))
                    )
                }

                Button {
                    onClose()
                } label: {
                    Text("Cerrar")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .confettiCannon(trigger: $confettiCounter, num: 60, colors: [.orange, .yellow, .green, .mint], confettiSize: 12, radius: 400)
        .background(
            LinearGradient(
                colors: [Color(red: 0.04, green: 0.04, blue: 0.1), Color(red: 0.05, green: 0.1, blue: 0.16)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .onAppear {
            // Haptic
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

            // Animate checkmark
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                checkmarkScale = 1.0
            }

            // Confetti
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                confettiCounter += 1
            }

            // Guardar venta en historial
            if let linkId = viewModel.paymentLinkId {
                let record = SaleRecord(
                    id: UUID(),
                    amount: viewModel.amountInCents,
                    currency: "mxn",
                    description: viewModel.saleDescription.isEmpty ? "Venta Atenea" : viewModel.saleDescription,
                    status: .completed,
                    createdAt: Date(),
                    paymentLinkId: linkId
                )
                SalesHistoryManager.shared.addSale(record)
            }
        }
    }
}
