//
//  CategoryFilterScrollView.swift
//  atenea
//
//  Filtro desplegable de categorías para el mapa (solo iconos)
//

import SwiftUI

struct CategoryFilterScrollView: View {
    @Binding var selectedCategory: MapCategory?
    @Binding var isExpanded: Bool
    let onCategorySelected: (MapCategory?) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Botón de toggle (chevron)
            Button(action: {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    isExpanded.toggle()
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }) {
                HStack {
                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.secondary.opacity(0.6))
                        .rotationEffect(.degrees(isExpanded ? 0 : 0))

                    Spacer()
                }
                .padding(.vertical, 8)
                .background(Color.clear)
            }
            .buttonStyle(.plain)

            // Grid de iconos (solo visible cuando está expandido)
            if isExpanded {
                HStack(spacing: 12) {
                    ForEach(MapCategory.allCategories) { category in
                        CategoryIconButton(
                            category: category,
                            isSelected: selectedCategory?.id == category.id,
                            action: {
                                handleCategoryTap(category)
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    private func handleCategoryTap(_ category: MapCategory) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if selectedCategory?.id == category.id {
                // Deseleccionar si ya está seleccionado
                selectedCategory = nil
                onCategorySelected(nil)
            } else {
                // Seleccionar nueva categoría
                selectedCategory = category
                onCategorySelected(category)
            }
        }
    }
}

// MARK: - Category Icon Button (Solo ícono circular)

struct CategoryIconButton: View {
    let category: MapCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                // Fondo del ícono
                Circle()
                    .fill(
                        isSelected
                            ? LinearGradient(
                                colors: [category.color, category.color.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [Color.white.opacity(0.9), Color.white.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                    )
                    .frame(width: 50, height: 50)

                // Borde sutil
                if !isSelected {
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.white.opacity(0.5), Color.gray.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                        .frame(width: 50, height: 50)
                }

                // Ícono
                Image(systemName: category.icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(isSelected ? .white : category.color)
            }
            .shadow(
                color: isSelected ? category.color.opacity(0.4) : Color.black.opacity(0.08),
                radius: isSelected ? 10 : 5,
                x: 0,
                y: isSelected ? 4 : 2
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Map Category Model

struct MapCategory: Identifiable, Equatable {
    let id: String
    let name: String
    let icon: String
    let color: Color
    let searchTerm: String  // Término para buscar en el mapa

    static func == (lhs: MapCategory, rhs: MapCategory) -> Bool {
        lhs.id == rhs.id
    }

    // Recomendaciones para el Mundial 2026
    static let allCategories: [MapCategory] = [
        MapCategory(
            id: "streetfood",
            name: LocalizedString("category.streetFood"),
            icon: "flame.fill",
            color: .orange,
            searchTerm: "Tacos"
        ),
        MapCategory(
            id: "stadiums",
            name: LocalizedString("category.stadiums"),
            icon: "trophy.fill",
            color: .green,
            searchTerm: "Estadio"
        ),
        MapCategory(
            id: "metro",
            name: LocalizedString("category.metro"),
            icon: "tram.fill",
            color: .blue,
            searchTerm: "Metro"
        ),
        MapCategory(
            id: "attractions",
            name: LocalizedString("category.attractions"),
            icon: "star.fill",
            color: .purple,
            searchTerm: "Monumento"
        ),
        MapCategory(
            id: "pharmacy",
            name: LocalizedString("category.pharmacy"),
            icon: "cross.fill",
            color: .red,
            searchTerm: "Farmacia"
        )
    ]
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.gray.opacity(0.3)
            .ignoresSafeArea()

        VStack {
            CategoryFilterScrollView(
                selectedCategory: .constant(nil),
                isExpanded: .constant(true),
                onCategorySelected: { category in
                    print("Categoría seleccionada: \(category?.name ?? "Ninguna")")
                }
            )
            .padding(.top, 120)

            Spacer()
        }
    }
}
