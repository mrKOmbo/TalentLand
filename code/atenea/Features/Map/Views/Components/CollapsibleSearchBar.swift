import SwiftUI

struct CollapsibleSearchBar: View {
    @ObservedObject var searchViewModel: SearchViewModel
    @Binding var isExpanded: Bool
    @FocusState.Binding var isSearchFocused: Bool
    @Binding var isWorldCupToday: Bool

    var body: some View {
        HStack(spacing: 0) {
            // --- CONTENEDOR PRINCIPAL DE BÚSQUEDA ---
            ZStack(alignment: .trailing) {
                // Fondo que se expande: Al cambiar el frame, SwiftUI lo anima suavemente
                liquidGlassBackground
                    .frame(width: isExpanded ? nil : 50, height: 50)

                HStack(spacing: 0) {
                    // Ícono de Lupa / Trofeo (siempre a la izquierda)
                    ZStack {
                        Image(systemName: isExpanded && isWorldCupToday ? "trophy.fill" : "magnifyingglass")
                            .font(.system(size: isExpanded ? 18 : 20, weight: .medium))
                            .foregroundStyle(iconGradient)
                            .symbolEffect(.pulse, options: .repeat(2), value: isSearchFocused)
                    }
                    .frame(width: 50, height: 50)
                    .onTapGesture {
                        if !isExpanded {
                            toggleExpansion(true)
                        }
                    }

                    // Elementos que aparecen solo al expandir
                    if isExpanded {
                        TextField(LocalizedString("search.placeholder"), text: $searchViewModel.searchText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 16))
                            .focused($isSearchFocused)
                            .autocorrectionDisabled()
                            .transition(.opacity.combined(with: .move(edge: .trailing)))
                            .onTapGesture {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                            .padding(.leading, 8)

                        Spacer()

                        searchActionButtons
                            .transition(.scale.combined(with: .opacity))
                            .padding(.trailing, 12)
                    }
                }
            }
        }
        .padding(.horizontal, isExpanded ? 0 : 16)
        .padding(.leading, isExpanded ? 16 : 0)
        .padding(.top, 56)
        // La clave de la fluidez: Una respuesta rápida (0.35) y sin rebote excesivo (0.85)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: isExpanded)
        .overlay {
            if isWorldCupToday && isExpanded {
                celebrationStarsOverlay
                    .allowsHitTesting(false)
            }
        }
    }

    // MARK: - Lógica de Animación
    
    private func toggleExpansion(_ expand: Bool) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        withAnimation {
            isExpanded = expand
        }
        
        if expand {
            // Delay pequeño para que el teclado salga cuando la barra ya casi terminó de abrirse
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                isSearchFocused = true
            }
        } else {
            isSearchFocused = false
            searchViewModel.clearSearch()
        }
    }

    // MARK: - Componentes de la Interfaz

    private var iconGradient: LinearGradient {
        if isExpanded && isSearchFocused && isWorldCupToday {
            return LinearGradient(colors: [.orange, .yellow, .green], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        return LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var searchActionButtons: some View {
        HStack(spacing: 8) {
            if searchViewModel.isSearching {
                ProgressView()
                    .scaleEffect(x: 0.8, y: 0.8, anchor: .center)
                    .tint(.blue)
            } else {
                Button(action: {
                    if searchViewModel.searchText.isEmpty {
                        toggleExpansion(false)
                    } else {
                        searchViewModel.clearSearch()
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var liquidGlassBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .fill(.ultraThickMaterial)
            
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.25), Color.white.opacity(0.05)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
            
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(0.4), Color.white.opacity(0.1)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
            
            if isSearchFocused {
                RoundedRectangle(cornerRadius: 25, style: .continuous)
                    .stroke(LinearGradient(colors: [.blue.opacity(0.4), .cyan.opacity(0.2)], startPoint: .leading, endPoint: .trailing), lineWidth: 1)
                    .blur(radius: 2)
            }
        }
        .shadow(color: Color.black.opacity(0.12), radius: 16, x: 0, y: 8)
    }

    private var celebrationStarsOverlay: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<5, id: \.self) { index in
                    Image(systemName: "star.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(Color.yellow)
                        .position(
                            x: CGFloat.random(in: 50...(geometry.size.width - 50)),
                            y: CGFloat.random(in: 10...(geometry.size.height - 10))
                        )
                        .opacity(isExpanded ? 0.7 : 0)
                        .animation(Animation.easeInOut(duration: 1).repeatForever().delay(Double(index) * 0.2), value: isExpanded)
                }
            }
        }
    }
}

