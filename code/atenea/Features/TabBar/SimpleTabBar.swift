import SwiftUI

// MARK: - Main Tab Bar
struct SimpleTabBar: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var languageManager: LanguageManager
    
    // Estado para controlar la expansión de las etiquetas
    @State private var isExpanded: Bool = true
    @State private var collapseTask: Task<Void, Never>? = nil

    var body: some View {
        HStack {
            Spacer()

            HStack(spacing: 8) {
                // Tab 0: Home
                SimpleTabBarItem(
                    icon: "house.fill",
                    title: LocalizedString("tab.home"),
                    isSelected: selectedTab == 0,
                    isExpanded: isExpanded && selectedTab == 0
                ) {
                    handleTabTap(0)
                }

                // Tab 1: Mapa
                SimpleTabBarItem(
                    icon: "map.fill",
                    title: LocalizedString("tab.map"),
                    isSelected: selectedTab == 1,
                    isExpanded: isExpanded && selectedTab == 1
                ) {
                    handleTabTap(1)
                }

                // Tab 2: Comunidad
                SimpleTabBarItem(
                    icon: "person.3.fill",
                    title: LocalizedString("tab.community"),
                    isSelected: selectedTab == 2,
                    isExpanded: isExpanded && selectedTab == 2
                ) {
                    handleTabTap(2)
                }

                // Tab 3: Álbum
                SimpleTabBarItem(
                    icon: "square.grid.3x3.fill",
                    title: LocalizedString("tab.album"),
                    isSelected: selectedTab == 3,
                    isExpanded: isExpanded && selectedTab == 3
                ) {
                    handleTabTap(3)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(liquidGlassBackground)
            // Animación coordinada para toda la barra
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: isExpanded)
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: selectedTab)

            Spacer()
        }
        .padding(.bottom, 20)
        .onAppear {
            // Iniciamos el temporizador al cargar la vista
            startCollapseTimer()
        }
    }

    // MARK: - Logic
    
    private func handleTabTap(_ index: Int) {
        // Feedback háptico premium
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        selectedTab = index
        
        // Expandir inmediatamente al tocar
        withAnimation {
            isExpanded = true
        }
        
        // Reiniciar el temporizador de colapso
        startCollapseTimer()
    }
    
    private func startCollapseTimer() {
        collapseTask?.cancel() // Cancelar el timer previo
        
        collapseTask = Task {
            // Espera 3 segundos antes de colapsar
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            
            if !Task.isCancelled {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.9)) {
                    isExpanded = false
                }
            }
        }
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
    let title: String
    let isSelected: Bool
    let isExpanded: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(isSelected ? activeGradient : inactiveGradient)
                
                // El texto aparece solo si el item está seleccionado y la barra expandida
                if isExpanded {
                    Text(title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(activeGradient)
                        .fixedSize() // Clave para evitar saltos de línea en la animación
                        .transition(
                            .opacity
                            .combined(with: .move(edge: .leading))
                            .combined(with: .scale(scale: 0.9, anchor: .leading))
                        )
                }
            }
            .padding(.horizontal, isExpanded ? 16 : 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected && isExpanded ? Color.blue.opacity(0.1) : Color.clear)
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
