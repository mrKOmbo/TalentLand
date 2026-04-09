import SwiftUI

// MARK: - Liquid Glass Bubble Tab Bar with Collapse Animation
struct SimpleTabBar: View {
    @Binding var selectedTab: Int
    @Binding var showSaleSheet: Bool
    @EnvironmentObject var languageManager: LanguageManager
    @ObservedObject private var userManager = UserManager.shared

    private var isMerchant: Bool { userManager.currentUser?.isMerchant == true || userManager.currentUser?.isAdmin == true }
    
    @State private var showLabel: Bool = false
    @State private var selectedTabForLabel: Int = -1

    var body: some View {
        ZStack(alignment: .top) {
            // Floating action button (merchant/admin only)
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

            // Compact bubble tab bar
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    TabBarItemCollapsible(
                        icon: "house.fill",
                        label: LocalizedString("tab.home"),
                        isSelected: selectedTab == 0,
                        showLabel: showLabel && selectedTabForLabel == 0,
                        action: { handleTabTap(0) }
                    )

                    TabBarItemCollapsible(
                        icon: "map.fill",
                        label: LocalizedString("tab.map"),
                        isSelected: selectedTab == 1,
                        showLabel: showLabel && selectedTabForLabel == 1,
                        action: { handleTabTap(1) }
                    )

                    // Espacio central para el botón flotante
                    if isMerchant {
                        Color.clear.frame(width: 56, height: 1)
                    }

                    TabBarItemCollapsible(
                        icon: "person.3.fill",
                        label: LocalizedString("tab.community"),
                        isSelected: selectedTab == 2,
                        showLabel: showLabel && selectedTabForLabel == 2,
                        action: { handleTabTap(2) }
                    )

                    TabBarItemCollapsible(
                        icon: "square.grid.3x3.fill",
                        label: LocalizedString("tab.more"),
                        isSelected: selectedTab == 3,
                        showLabel: showLabel && selectedTabForLabel == 3,
                        action: { handleTabTap(3) }
                    )
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(liquidGlassBackground)
                .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: selectedTab)
            .animation(.easeInOut(duration: 0.3), value: showLabel)
        }
    }

    // MARK: - Logic

    private func handleTabTap(_ index: Int) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        selectedTab = index
        selectedTabForLabel = index
        
        // Show label and collapse after delay
        showLabel = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation {
                showLabel = false
            }
        }
    }

    // MARK: - Liquid Glass Background

    private var liquidGlassBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(.ultraThinMaterial)
            
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
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Collapsible Tab Item
struct TabBarItemCollapsible: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let showLabel: Bool
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            ZStack {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(isSelected ? activeGradient : inactiveGradient)
                    .opacity(showLabel ? 0 : 1)

                // Label (appears on tap)
                if showLabel {
                    Text(label)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color(red: 0.051, green: 0.094, blue: 0.329))
                        .lineLimit(1)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(height: 40)
            .frame(maxWidth: showLabel ? 80 : 40)
            .background(
                Capsule()
                    .fill(isSelected ? Color.blue.opacity(0.12) : Color.clear)
            )
            .scaleEffect(CGSize(width: isPressed ? 0.9 : 1.0, height: isPressed ? 0.9 : 1.0))
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0.05, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }

    private var activeGradient: LinearGradient {
        LinearGradient(colors: [.coppelBlue, .coppelLightBlue], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var inactiveGradient: LinearGradient {
        LinearGradient(colors: [.secondary, .secondary], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}
