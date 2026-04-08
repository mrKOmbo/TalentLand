import SwiftUI

// MARK: - Main Tab Bar
struct SimpleTabBar: View {
    @Binding var selectedTab: Int
    @Binding var showSaleSheet: Bool
    @EnvironmentObject var languageManager: LanguageManager
    @ObservedObject private var userManager = UserManager.shared

    private var isMerchant: Bool { userManager.currentUser?.isMerchant == true || userManager.currentUser?.isAdmin == true }

    var body: some View {
        ZStack(alignment: .top) {
            // Botón flotante de cobro (merchant/admin only)
            if isMerchant {
                Button {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    showSaleSheet = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(colors: [.orange, .yellow],
                                               startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .frame(width: 56, height: 56)
                            .shadow(color: .orange.opacity(0.4), radius: 12, x: 0, y: 4)

                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .offset(y: -28)
                .zIndex(1)
            }

            // Tab bar — se extiende hasta el fondo del safe area
            VStack(spacing: 0) {
                HStack {
                    SimpleTabBarItem(icon: "house.fill", isSelected: selectedTab == 0) {
                        handleTabTap(0)
                    }
                    Spacer()
                    SimpleTabBarItem(icon: "map.fill", isSelected: selectedTab == 1) {
                        handleTabTap(1)
                    }
                    Spacer()

                    // Espacio central para el botón flotante
                    if isMerchant {
                        Color.clear.frame(width: 56, height: 1)
                        Spacer()
                    }

                    SimpleTabBarItem(icon: "person.3.fill", isSelected: selectedTab == 2) {
                        handleTabTap(2)
                    }
                    Spacer()
                    SimpleTabBarItem(icon: "square.grid.3x3.fill", isSelected: selectedTab == 3) {
                        handleTabTap(3)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 6)
                .padding(.bottom, 4)
            }
            .frame(maxWidth: .infinity)
            .background(
                liquidGlassBackground
                    .ignoresSafeArea(.container, edges: .bottom)
            )
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: selectedTab)
        }
    }

    // MARK: - Logic

    private func handleTabTap(_ index: Int) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        selectedTab = index
    }

    // MARK: - Liquid Glass Background

    private var liquidGlassBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(.ultraThickMaterial)
            
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.2), Color.white.opacity(0.05)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
            
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(0.4), Color.white.opacity(0.1)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        }
        .shadow(color: Color.black.opacity(0.12), radius: 16, x: 0, y: 8)
    }
}

// MARK: - Tab Item
struct SimpleTabBarItem: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(isSelected ? activeGradient : inactiveGradient)
                .padding(10)
                .background(
                    Circle()
                        .fill(isSelected ? Color.blue.opacity(0.12) : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }

    private var activeGradient: LinearGradient {
        LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var inactiveGradient: LinearGradient {
        LinearGradient(colors: [.secondary, .secondary], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}
