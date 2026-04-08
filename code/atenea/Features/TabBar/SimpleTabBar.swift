import SwiftUI

// MARK: - Enhanced Tab Bar with Glassmorphism
struct SimpleTabBar: View {
    @Binding var selectedTab: Int
    @Binding var showSaleSheet: Bool
    @EnvironmentObject var languageManager: LanguageManager
    @ObservedObject private var userManager = UserManager.shared

    private var isMerchant: Bool { userManager.currentUser?.isMerchant == true || userManager.currentUser?.isAdmin == true }
    
    @State private var tabBarHeight: CGFloat = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            // Floating action button (merchant/admin only)
            if isMerchant {
                VStack {
                    Spacer()
                    floatingActionButton
                        .offset(y: -tabBarHeight / 2 + 8)
                }
                .ignoresSafeArea(edges: .bottom)
            }

            // Modern glassmorphic tab bar
            VStack(spacing: 0) {
                Spacer()
                
                HStack(spacing: 0) {
                    // Left tabs (Home, Map)
                    HStack(spacing: 4) {
                        TabBarItemModern(
                            icon: "house.fill",
                            label: LocalizedString("tab.home"),
                            isSelected: selectedTab == 0,
                            action: { handleTabTap(0) }
                        )
                        
                        TabBarItemModern(
                            icon: "map.fill",
                            label: LocalizedString("tab.map"),
                            isSelected: selectedTab == 1,
                            action: { handleTabTap(1) }
                        )
                    }
                    .frame(maxWidth: .infinity)

                    // Center spacer for floating action button
                    if isMerchant {
                        Spacer()
                            .frame(width: 56)
                    }

                    // Right tabs (Community, More)
                    HStack(spacing: 4) {
                        TabBarItemModern(
                            icon: "person.3.fill",
                            label: LocalizedString("tab.community"),
                            isSelected: selectedTab == 2,
                            action: { handleTabTap(2) }
                        )
                        
                        TabBarItemModern(
                            icon: "square.grid.3x3.fill",
                            label: LocalizedString("tab.more"),
                            isSelected: selectedTab == 3,
                            action: { handleTabTap(3) }
                        )
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(height: 72)
                .background(glassBackground)
                .cornerRadius(24, corners: [.topLeft, .topRight])
                .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: -8)
            }
            .frame(height: tabBarHeight)
            .onAppear { tabBarHeight = 72 }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: selectedTab)
    }

    // MARK: - Components

    private var floatingActionButton: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            showSaleSheet = true
        }) {
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 1.0, green: 0.6, blue: 0.2).opacity(0.3),
                                Color(red: 1.0, green: 0.4, blue: 0.0).opacity(0)
                            ]),
                            startPoint: .center,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                // Main circle
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 1.0, green: 0.65, blue: 0.2),
                                Color(red: 1.0, green: 0.5, blue: 0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                    .shadow(color: Color(red: 1.0, green: 0.5, blue: 0.1).opacity(0.5), radius: 16, x: 0, y: 8)

                // Icon
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var glassBackground: some View {
        ZStack {
            // Base glass layer
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
            
            // Gradient overlay
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.15),
                            Color.white.opacity(0.05)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Border
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.5),
                            Color.white.opacity(0.1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
    }

    // MARK: - Logic

    private func handleTabTap(_ index: Int) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        selectedTab = index
    }
}

// MARK: - Modern Tab Bar Item
struct TabBarItemModern: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .lineLimit(1)
            }
            .foregroundStyle(
                isSelected
                    ? LinearGradient(
                        gradient: Gradient(colors: [.coppelBlue, .coppelLightBlue]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    : LinearGradient(
                        gradient: Gradient(colors: [Color.gray, Color.gray.opacity(0.6)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.coppelBlue.opacity(0.1))
                    } else {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.clear)
                    }
                }
            )
    }
    .buttonStyle(.plain)
    }
}
