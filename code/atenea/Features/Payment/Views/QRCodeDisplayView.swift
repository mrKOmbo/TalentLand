import SwiftUI

struct QRCodeDisplayView: View {
    @ObservedObject var viewModel: SaleViewModel
    let onCancel: () -> Void

    @State private var pulseOpacity: Double = 0.6

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: onCancel) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text(LocalizedString("payment.cancel"))
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)

            Spacer()

            // Amount
            VStack(spacing: 4) {
                Text(LocalizedString("payment.chargeFor"))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                Text(viewModel.formattedAmount)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text(LocalizedString("payment.currency"))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
                if !viewModel.saleDescription.isEmpty {
                    Text(viewModel.saleDescription)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.4))
                        .padding(.top, 4)
                }
            }
            .padding(.bottom, 32)

            // QR Code
            if let url = viewModel.paymentLinkURL,
               let qrImage = QRGeneratorService.generateQRCode(from: url, size: CGSize(width: 280, height: 280)) {
                Image(uiImage: qrImage)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 260, height: 260)
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(.white)
                    )
                    .shadow(color: .white.opacity(0.1), radius: 20, x: 0, y: 0)
            } else {
                ProgressView()
                    .tint(.white)
                    .frame(width: 260, height: 260)
            }

            // Status indicator
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 8, height: 8)
                    .opacity(pulseOpacity)
                Text(LocalizedString("payment.waitingPayment"))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.top, 28)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    pulseOpacity = 1.0
                }
            }

            Text(LocalizedString("payment.customerScanQR"))
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.35))
                .multilineTextAlignment(.center)
                .padding(.top, 12)

            Spacer()
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
