import SwiftUI

struct SaleFlowView: View {
    @StateObject private var viewModel = SaleViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            switch viewModel.currentStep {
            case .enterAmount:
                AmountEntryView(viewModel: viewModel) {
                    dismiss()
                }
            case .showQR:
                QRCodeDisplayView(viewModel: viewModel) {
                    viewModel.reset()
                }
            case .cashPayment:
                CashPaymentView(viewModel: viewModel) {
                    viewModel.reset()
                }
            case .confirmed:
                PaymentConfirmedView(viewModel: viewModel) {
                    // Nuevo cobro
                    viewModel.reset()
                } onClose: {
                    dismiss()
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep.rawValue)
    }
}
