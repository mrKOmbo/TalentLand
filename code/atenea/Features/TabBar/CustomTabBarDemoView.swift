import SwiftUI

/// Vista de demostración que muestra cómo el Custom Tab Bar se oculta dinámicamente
/// basado en el estado `showDirections` del NavigationStateManager
struct CustomTabBarDemoView: View {
    @ObservedObject private var navigationStateManager = NavigationStateManager.shared
    @State private var selectedTab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            // Contenido principal (simula el mapa)
            MapContentPlaceholder()
                .edgesIgnoringSafeArea(.all)

            // Botón de prueba para toggle direcciones
            VStack {
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        navigationStateManager.showDirections.toggle()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: navigationStateManager.showDirections ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                            .font(.system(size: 20))
                        Text(navigationStateManager.showDirections ? "Mostrar Tab Bar" : "Ocultar Tab Bar")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    )
                    .foregroundColor(.primary)
                }
                .padding(.top, 60)

                Spacer()
            }

            // Custom Tab Bar
            CustomTabBar(selectedTab: $selectedTab)
                .offset(y: navigationStateManager.showDirections ? 120 : 0)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: navigationStateManager.showDirections)
        }
    }
}

// MARK: - Map Placeholder

struct MapContentPlaceholder: View {
    var body: some View {
        ZStack {
            // Fondo con gradiente
            LinearGradient(
                colors: [
                    Color(hex: "#667eea"),
                    Color(hex: "#764ba2")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 12) {
                Image(systemName: "map.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white.opacity(0.8))

                Text("Vista de Mapa")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("Toca el botón para ocultar/mostrar el Tab Bar")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
    }
}

// MARK: - Custom Tab Bar

struct CustomTabBar: View {
    @Binding var selectedTab: Int

    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.white.opacity(0.2))

            HStack(spacing: 0) {
                TabBarButton(
                    icon: "map.fill",
                    title: "Explorar",
                    isSelected: selectedTab == 0
                ) {
                    selectedTab = 0
                }

                TabBarButton(
                    icon: "magnifyingglass",
                    title: "Buscar",
                    isSelected: selectedTab == 1
                ) {
                    selectedTab = 1
                }

                TabBarButton(
                    icon: "star.fill",
                    title: "Favoritos",
                    isSelected: selectedTab == 2
                ) {
                    selectedTab = 2
                }

                TabBarButton(
                    icon: "person.fill",
                    title: "Perfil",
                    isSelected: selectedTab == 3
                ) {
                    selectedTab = 3
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
            .padding(.bottom, 4)
            .background(
                ZStack {
                    // Fondo de vidrio esmerilado
                    Color(.systemBackground)
                        .opacity(0.9)

                    // Efecto de blur
                    Rectangle()
                        .fill(.ultraThinMaterial)
                }
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: -2)
            )
        }
    }
}

struct TabBarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            action()
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))

                Text(title)
                    .font(.system(size: 10, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .foregroundColor(isSelected ? .blue : .gray)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Preview

#Preview {
    CustomTabBarDemoView()
}
