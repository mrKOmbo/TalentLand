//
//  BusinessQRView.swift
//  atenea
//
//  Vista del QR del negocio — Coppel Brand Toolkit 2024
//  El comerciante muestra este QR para que clientes vean su info
//

import SwiftUI

struct BusinessQRView: View {
    let merchant: Merchant
    @Environment(\.dismiss) private var dismiss
    @State private var qrImage: UIImage?
    @State private var showShareSheet = false
    @State private var showCopiedToast = false
    @State private var isSyncing = true

    private var businessURL: String {
        let url = BusinessQRService.businessURL(for: merchant)
        print("📱 [BusinessQRView] businessURL: \(url)")
        return url
    }

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    header

                    // QR Card
                    qrCard

                    // Info preview
                    infoPreview

                    // Actions
                    actions

                    // Footer
                    footer
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 48)
            }

            // Copied toast
            if showCopiedToast {
                VStack {
                    Spacer()
                    copiedToast
                        .padding(.bottom, 32)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear {
            print("📱 [BusinessQRView] onAppear — merchant: \(merchant.businessName), id=\(merchant.id.uuidString)")
            print("📱 [BusinessQRView] merchant.currentLocation: \(merchant.currentLocation != nil ? "lat=\(merchant.currentLocation!.latitude), lng=\(merchant.currentLocation!.longitude)" : "nil")")
            print("📱 [BusinessQRView] merchant.isActive: \(merchant.isActive), isOpen: \(merchant.isCurrentlyOpen)")
            // Sync merchant a Supabase antes de generar QR (upsert)
            Task {
                print("📱 [BusinessQRView] syncing merchant to Supabase...")
                do {
                    let supabaseId = try await SupabaseService.shared.saveMerchant(merchant)
                    print("📱 [BusinessQRView] ✅ merchant synced to Supabase: \(supabaseId)")
                } catch {
                    print("📱 [BusinessQRView] ⚠️ sync failed: \(error.localizedDescription)")
                }
                isSyncing = false
                qrImage = BusinessQRService.generateQR(for: merchant)
                print("📱 [BusinessQRView] qrImage generado: \(qrImage != nil ? "✅" : "❌")")
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedString("qr.myBusinessQR"))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "#081754"))

                Text(LocalizedString("qr.showToCustomers"))
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(Color(hex: "#4A4A4A"))
            }

            Spacer()

            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color(hex: "#4A4A4A").opacity(0.4))
            }
        }
    }

    // MARK: - QR Card

    private var qrCard: some View {
        VStack(spacing: 20) {
            // Business identity
            HStack(spacing: 12) {
                Text(merchant.emoji)
                    .font(.system(size: 36))

                VStack(alignment: .leading, spacing: 2) {
                    Text(merchant.businessName)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "#081754"))

                    Text(merchant.category.displayName)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(Color(hex: "#4A4A4A"))
                }

                Spacer()
            }

            // QR code
            if let qrImage = qrImage {
                ZStack {
                    // White background for QR
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white)
                        .frame(width: 260, height: 260)

                    Image(uiImage: qrImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 240, height: 240)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(.vertical, 8)
            } else {
                // Loading state
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(hex: "#EEE8E3"))
                    .frame(width: 260, height: 260)
                    .overlay(
                        ProgressView()
                            .tint(Color(hex: "#1C42E8"))
                    )
            }

            // Scan instruction
            HStack(spacing: 8) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "#1C42E8"))

                Text(LocalizedString("qr.scanToSeeInfo"))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(Color(hex: "#4A4A4A"))
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color(hex: "#081754").opacity(0.08), radius: 16, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color(hex: "#1C42E8").opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - Info Preview

    private var infoPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedString("qr.whatCustomersSee"))
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(Color(hex: "#4A4A4A"))
                .textCase(.uppercase)
                .kerning(0.5)

            VStack(spacing: 8) {
                previewRow(icon: "bag.fill", text: merchant.businessName)

                if !merchant.products.isEmpty {
                    let count = merchant.products.filter { $0.isAvailable }.count
                    previewRow(icon: "list.bullet", text: String(format: LocalizedString("qr.productsWithPrices"), count))
                }

                if merchant.currentLocation != nil {
                    previewRow(icon: "map.fill", text: LocalizedString("qr.locationOnMap"))
                }

                if merchant.schedule != nil {
                    previewRow(icon: "clock.fill", text: LocalizedString("qr.schedule"))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(hex: "#EEE8E3").opacity(0.5))
            )
        }
    }

    private func previewRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(hex: "#1C42E8"))
                .frame(width: 24)

            Text(text)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(Color(hex: "#081754"))

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "#0ABF4F"))
        }
    }

    // MARK: - Actions

    private var actions: some View {
        VStack(spacing: 12) {
            // Share
            Button {
                shareQR()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                    Text(LocalizedString("qr.shareQR"))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(hex: "#1C42E8"))
                )
                .shadow(color: Color(hex: "#1C42E8").opacity(0.3), radius: 12, x: 0, y: 6)
            }

            // Copy link
            Button {
                UIPasteboard.general.string = businessURL
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showCopiedToast = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation { showCopiedToast = false }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "link")
                        .font(.system(size: 16, weight: .semibold))
                    Text(LocalizedString("qr.copyLink"))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                }
                .foregroundColor(Color(hex: "#1C42E8"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(Color(hex: "#1C42E8").opacity(0.2), lineWidth: 1.5)
                        )
                )
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 4) {
            Text(LocalizedString("qr.poweredByAtenea"))
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(Color(hex: "#4A4A4A").opacity(0.4))

            Text("komiia.com")
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(Color(hex: "#1C42E8").opacity(0.5))
        }
    }

    // MARK: - Toast

    private var copiedToast: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)

            Text(LocalizedString("qr.linkCopied"))
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            Capsule()
                .fill(Color(hex: "#0ABF4F"))
                .shadow(color: Color(hex: "#0ABF4F").opacity(0.3), radius: 12, x: 0, y: 4)
        )
    }

    // MARK: - Share

    private func shareQR() {
        print("📱 [BusinessQRView] shareQR tapped")
        var items: [Any] = []

        if let qr = qrImage {
            items.append(qr)
            print("📱 [BusinessQRView] share: QR image añadida")
        } else {
            print("📱 [BusinessQRView] share: ⚠️ sin QR image")
        }

        let url = businessURL
        items.append(url)
        print("📱 [BusinessQRView] share: URL añadida — \(url)")

        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}
