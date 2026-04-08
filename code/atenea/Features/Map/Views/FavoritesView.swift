//
//  FavoritesView.swift
//  atenea
//
//  Coppel Brand Toolkit 2024 — Favorites management
//

import SwiftUI

struct FavoriteVendor: Identifiable {
    let id = UUID()
    let name: String
    let category: String
    let distance: String
    let color: Color
}

struct FavoritesView: View {
    @Environment(\.dismiss) var dismiss
    @State private var favorites: [FavoriteVendor] = [
        FavoriteVendor(name: "Tacos El Rey", category: "Food", distance: "150m", color: Color(red: 1, green: 0.68, blue: 0.26)),
        FavoriteVendor(name: "Helados Don Taco", category: "Beverage", distance: "320m", color: Color(red: 0.05, green: 0.75, blue: 0.31)),
        FavoriteVendor(name: "Artesanías Maya", category: "Crafts", distance: "850m", color: Color(red: 0.49, green: 0.26, blue: 1)),
    ]

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Favorites")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(Color.coppelDarkBlue)

                            Text("\(favorites.count) saved vendors")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.gray)
                        }

                        Spacer()

                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.gray.opacity(0.4))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    if favorites.isEmpty {
                        emptyState
                    } else {
                        VStack(spacing: 10) {
                            ForEach(favorites) { vendor in
                                favoriteCard(vendor)
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    Spacer(minLength: 40)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color(red: 0.99, green: 0.73, blue: 0.18).opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "star.fill")
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundColor(Color(red: 0.99, green: 0.73, blue: 0.18))
            }

            VStack(spacing: 8) {
                Text("No favorites yet")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(Color.coppelDarkBlue)

                Text("Save vendors to find them faster")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }

            Button(action: { dismiss() }) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .semibold))

                    Text("Explore")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.coppelBlue)
                )
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 40)
    }

    private func favoriteCard(_ vendor: FavoriteVendor) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(vendor.color.opacity(0.1))
                    .frame(width: 50, height: 50)

                Image(systemName: "storefront.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(vendor.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(vendor.name)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.coppelDarkBlue)

                HStack(spacing: 6) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.gray.opacity(0.6))

                    Text("\(vendor.category) • \(vendor.distance)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    if let index = favorites.firstIndex(where: { $0.id == vendor.id }) {
                        favorites.remove(at: index)
                    }
                }
            }) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.coppelRed)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.systemBackground))
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}

#Preview {
    FavoritesView()
}
