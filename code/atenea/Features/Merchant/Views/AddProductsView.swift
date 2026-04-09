//
//  AddProductsView.swift
//  atenea
//
//  Vista para agregar productos con foto durante el registro del comerciante
//  Coppel Brand Toolkit 2024
//

import SwiftUI
import PhotosUI

struct ProductDraft: Identifiable {
    let id = UUID()
    var name: String = ""
    var price: String = ""
    var emoji: String = "🍽"
    var selectedPhoto: PhotosPickerItem?
    var photoData: Data?
    var photoImage: UIImage?
}

struct AddProductsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var products: [ProductDraft] = [ProductDraft()]
    @State private var isUploading = false
    let onSave: ([Product]) -> Void
    let merchantId: String

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#EEE8E3").opacity(0.3)
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text(LocalizedString("products.addTitle"))
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(Color(hex: "#081754"))

                            Text(LocalizedString("products.addSubtitle"))
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(Color(hex: "#4A4A4A"))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                        // Product cards
                        ForEach($products) { $product in
                            ProductCardEditor(product: $product, onDelete: {
                                if products.count > 1 {
                                    products.removeAll { $0.id == product.id }
                                }
                            })
                        }
                        .padding(.horizontal, 20)

                        // Add product button
                        if products.count < 8 {
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    products.append(ProductDraft())
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 18))
                                    Text(LocalizedString("products.addAnother"))
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                }
                                .foregroundColor(Color(hex: "#1C42E8"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(Color(hex: "#1C42E8").opacity(0.2), lineWidth: 1.5)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .fill(Color.white)
                                        )
                                )
                            }
                            .padding(.horizontal, 20)
                        }

                        // Counter
                        Text(String(format: LocalizedString("products.count"), products.count))
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(Color(hex: "#4A4A4A").opacity(0.5))

                        Spacer(minLength: 100)
                    }
                }

                // Save button
                VStack {
                    Spacer()

                    Button {
                        saveProducts()
                    } label: {
                        HStack(spacing: 8) {
                            if isUploading {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(CGFloat(0.9))
                            }
                            Text(isUploading ? LocalizedString("products.uploading") : LocalizedString("products.save"))
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(Color(hex: "#1C42E8"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(hex: "#F0D224"))
                                .shadow(color: Color(hex: "#F0D224").opacity(0.3), radius: 12, x: 0, y: 6)
                        )
                    }
                    .disabled(isUploading || !hasValidProducts)
                    .opacity(hasValidProducts ? 1 : 0.5)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                            Text(LocalizedString("products.skip"))
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(Color(hex: "#1C42E8"))
                    }
                }
            }
        }
    }

    private var hasValidProducts: Bool {
        products.contains { !$0.name.isEmpty && !$0.price.isEmpty }
    }

    private func saveProducts() {
        isUploading = true

        Task {
            var savedProducts: [Product] = []

            for draft in products where !draft.name.isEmpty && !draft.price.isEmpty {
                var imageURL: String?

                // Upload photo if exists
                if let photoData = draft.photoData {
                    // Compress to JPEG
                    if let uiImage = UIImage(data: photoData),
                       let jpegData = uiImage.jpegData(compressionQuality: 0.7) {
                        do {
                            imageURL = try await SupabaseService.shared.uploadProductImage(
                                jpegData,
                                merchantId: merchantId,
                                productId: draft.id.uuidString
                            )
                        } catch {
                            print("⚠️ Failed to upload photo for \(draft.name): \(error)")
                        }
                    }
                }

                let product = Product(
                    name: draft.name,
                    price: Double(draft.price) ?? 0,
                    emoji: draft.emoji,
                    imageURL: imageURL
                )
                savedProducts.append(product)
            }

            await MainActor.run {
                isUploading = false
                onSave(savedProducts)
                dismiss()
            }
        }
    }
}

// MARK: - Product Card Editor

struct ProductCardEditor: View {
    @Binding var product: ProductDraft
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Photo section
            photoSection

            // Name
            HStack(spacing: 12) {
                Text(product.emoji)
                    .font(.system(size: 28))

                TextField(LocalizedString("products.namePlaceholder"), text: $product.name)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(Color(hex: "#081754"))
            }

            // Price
            HStack(spacing: 8) {
                Text("$")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "#1C42E8"))

                TextField("0", text: $product.price)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "#1C42E8"))
                    .keyboardType(.decimalPad)

                Text("MXN")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(Color(hex: "#4A4A4A").opacity(0.5))

                Spacer()

                // Delete button
                Button(action: onDelete) {
                    Image(systemName: "trash.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Color(hex: "#FF594D").opacity(0.6))
                }
            }

            // Emoji picker (simple)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(["🌮", "🫔", "🍦", "🥤", "🌽", "🍉", "🧀", "☕", "🍮", "🥩", "🫓", "🍋", "🥐", "🔥", "📦", "🍽"], id: \.self) { emoji in
                        Button {
                            product.emoji = emoji
                        } label: {
                            Text(emoji)
                                .font(.system(size: 22))
                                .padding(6)
                                .background(
                                    Circle()
                                        .fill(product.emoji == emoji ? Color(hex: "#F0D224").opacity(0.3) : Color.clear)
                                )
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color(hex: "#081754").opacity(0.06), radius: 12, x: 0, y: 4)
        )
    }

    // MARK: - Photo Section

    @ViewBuilder
    private var photoSection: some View {
        if let image = product.photoImage {
            // Show captured photo
            ZStack(alignment: .topTrailing) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                // Remove photo button
                Button {
                    product.photoImage = nil
                    product.photoData = nil
                    product.selectedPhoto = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .shadow(radius: 4)
                }
                .padding(8)
            }
        } else {
            // Photo picker
            PhotosPicker(selection: $product.selectedPhoto, matching: .images) {
                VStack(spacing: 10) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color(hex: "#1C42E8").opacity(0.4))

                    Text(LocalizedString("products.addPhoto"))
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: "#1C42E8").opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 120)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(hex: "#1C42E8").opacity(0.04))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(Color(hex: "#1C42E8").opacity(0.1), style: StrokeStyle(lineWidth: 1.5, dash: [8, 6]))
                        )
                )
            }
            .onChange(of: product.selectedPhoto) { _, newItem in
                guard let item = newItem else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        await MainActor.run {
                            product.photoData = data
                            product.photoImage = UIImage(data: data)
                        }
                    }
                }
            }
        }
    }
}
