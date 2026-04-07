//
//  HomeView.swift
//  atenea
//
//  Vista de inicio adaptativa por rol (comerciante / cliente)
//

import SwiftUI

struct HomeView: View {
    @Binding var selectedTab: Int
    @ObservedObject private var userManager = UserManager.shared
    @EnvironmentObject var languageManager: LanguageManager

    var body: some View {
        Group {
            if let user = userManager.currentUser {
                if user.isMerchant {
                    MerchantHomeView(selectedTab: $selectedTab, user: user)
                        .environmentObject(languageManager)
                } else {
                    CustomerHomeView(selectedTab: $selectedTab, user: user)
                        .environmentObject(languageManager)
                }
            } else {
                CustomerHomeView(selectedTab: $selectedTab, user: User(email: "", name: "Visitante", role: .user))
                    .environmentObject(languageManager)
            }
        }
    }
}

// MARK: - Merchant Home

struct MerchantHomeView: View {
    @Binding var selectedTab: Int
    let user: User

    @State private var isBusinessActive = true
    @State private var nearbyClients = 14
    @State private var profileViews = 87
    @State private var messagesReceived = 3
    @State private var animateCards = false

    var body: some View {
        ZStack {
            // Fondo
            LinearGradient(
                colors: [Color(hex: "#0A0A1A"), Color(hex: "#0D1B2A")],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header
                    merchantHeader

                    // Status toggle
                    businessStatusCard

                    // Métricas del día
                    metricsGrid

                    // Acciones rápidas
                    quickActionsSection

                    // Tip del día
                    demandTipCard

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 16)
                .padding(.top, 60)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                animateCards = true
            }
        }
    }

    // MARK: - Header

    private var merchantHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Hola, \(user.name) 👋")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                Text("Tu negocio hoy")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.6))
            }
            Spacer()
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: [.orange, .yellow],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 48, height: 48)
                Text(String(user.name.prefix(1)))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : -10)
    }

    // MARK: - Business Status

    private var businessStatusCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(isBusinessActive ? "Negocio activo" : "Negocio pausado")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                Text(isBusinessActive ? "Los clientes pueden encontrarte" : "No apareces en el mapa")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.6))
            }
            Spacer()
            Toggle("", isOn: $isBusinessActive)
                .labelsHidden()
                .tint(.green)
        }
        .padding(16)
        .background(glassCard(color: isBusinessActive ? .green.opacity(0.15) : .red.opacity(0.1)))
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 20)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isBusinessActive)
    }

    // MARK: - Metrics Grid

    private var metricsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("HOY")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
                .kerning(1.5)

            HStack(spacing: 12) {
                MetricCard(
                    icon: "person.fill",
                    value: "\(nearbyClients)",
                    label: "Clientes cercanos",
                    color: .blue
                )
                MetricCard(
                    icon: "eye.fill",
                    value: "\(profileViews)",
                    label: "Vistas de perfil",
                    color: .purple
                )
                MetricCard(
                    icon: "message.fill",
                    value: "\(messagesReceived)",
                    label: "Mensajes",
                    color: messagesReceived > 0 ? .orange : .gray
                )
            }
        }
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 20)
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ACCIONES RÁPIDAS")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
                .kerning(1.5)

            VStack(spacing: 10) {
                MerchantActionRow(
                    icon: "mappin.and.ellipse",
                    title: "Actualizar mi ubicación",
                    subtitle: "Deja que los clientes te encuentren",
                    color: .blue
                ) {
                    selectedTab = 1
                }

                MerchantActionRow(
                    icon: "megaphone.fill",
                    title: "Lanzar promoción",
                    subtitle: "Atrae clientes con una oferta",
                    color: .orange
                ) { }

                MerchantActionRow(
                    icon: "map.fill",
                    title: "Ver zonas de demanda",
                    subtitle: "Dónde hay más clientes ahora",
                    color: .green
                ) {
                    selectedTab = 1
                }
            }
        }
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 20)
    }

    // MARK: - Demand Tip

    private var demandTipCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 22))
                .foregroundStyle(LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom))
                .frame(width: 44, height: 44)
                .background(Color.yellow.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 3) {
                Text("Pico de demanda en 2h")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Text("El estadio Azteca termina partido a las 6pm. Posiciónate cerca.")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(2)
            }
        }
        .padding(14)
        .background(glassCard(color: .yellow.opacity(0.08)))
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 20)
    }
}

// MARK: - Customer Home

struct CustomerHomeView: View {
    @Binding var selectedTab: Int
    let user: User

    @State private var animateCards = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#0A0A1A"), Color(hex: "#0D1B2A")],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header
                    customerHeader

                    // Comerciantes activos cerca
                    nearbyMerchantsSection

                    // Recomendación IA
                    aiRecommendationCard

                    // Acciones rápidas
                    customerQuickActions

                    // Evento Mundial
                    worldCupEventCard

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 16)
                .padding(.top, 60)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                animateCards = true
            }
        }
    }

    // MARK: - Header

    private var customerHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Hola, \(user.name) 👋")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                Text("¿Qué se te antoja hoy?")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.6))
            }
            Spacer()
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: [.blue, .cyan],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 48, height: 48)
                Text(String(user.name.prefix(1)))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : -10)
    }

    // MARK: - Nearby Merchants

    private var nearbyMerchantsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("CERCA DE TI")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
                    .kerning(1.5)
                Spacer()
                Button("Ver mapa") {
                    selectedTab = 0
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    NearbyMerchantChip(emoji: "🌮", name: "Don Taco", distance: "120m", isActive: true)
                    NearbyMerchantChip(emoji: "🍦", name: "Paletas", distance: "340m", isActive: true)
                    NearbyMerchantChip(emoji: "🥤", name: "Jugos Mary", distance: "500m", isActive: false)
                    NearbyMerchantChip(emoji: "🫔", name: "Tamales", distance: "210m", isActive: true)
                }
            }
        }
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 20)
    }

    // MARK: - AI Recommendation

    private var aiRecommendationCard: some View {
        Button {
            selectedTab = 1 // Abre el mapa donde está el chat IA
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "sparkles")
                    .font(.system(size: 22))
                    .foregroundStyle(LinearGradient(colors: [.blue, .cyan], startPoint: .top, endPoint: .bottom))
                    .frame(width: 44, height: 44)
                    .background(Color.blue.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 3) {
                    Text("Pregúntale a Atenea IA")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    Text("¿Dónde están los mejores tacos cerca del Azteca?")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(2)
                }

                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(14)
            .background(glassCard(color: .blue.opacity(0.1)))
        }
        .buttonStyle(.plain)
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 20)
    }

    // MARK: - Quick Actions

    private var customerQuickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ACCESOS RÁPIDOS")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
                .kerning(1.5)

            HStack(spacing: 12) {
                CustomerActionButton(icon: "mappin.and.ellipse", label: "Buscar\ncomercio", color: .blue) {
                    selectedTab = 1
                }
                CustomerActionButton(icon: "camera.viewfinder", label: "Escáner\nAR", color: .purple) {
                    selectedTab = 1
                }
                CustomerActionButton(icon: "square.grid.3x3.fill", label: "Mi\nálbum", color: .orange) {
                    selectedTab = 3
                }
            }
        }
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 20)
    }

    // MARK: - World Cup Card

    private var worldCupEventCard: some View {
        HStack(spacing: 14) {
            Text("⚽")
                .font(.system(size: 28))
                .frame(width: 44, height: 44)
                .background(Color.green.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 3) {
                Text("Hoy hay partido")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Text("México vs Brasil · Estadio Azteca · 6:00 PM")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(14)
        .background(glassCard(color: .green.opacity(0.08)))
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 20)
    }
}

// MARK: - Shared Components

private func glassCard(color: Color) -> some View {
    ZStack {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(.ultraThinMaterial)
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(color)
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)
    }
}

struct MetricCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(glassCard(color: color.opacity(0.1)))
    }
}

struct MerchantActionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
                    .frame(width: 40, height: 40)
                    .background(color.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.5))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(12)
            .background(glassCard(color: .white.opacity(0.03)))
        }
        .buttonStyle(.plain)
    }
}

struct NearbyMerchantChip: View {
    let emoji: String
    let name: String
    let distance: String
    let isActive: Bool

    var body: some View {
        VStack(spacing: 6) {
            ZStack(alignment: .bottomTrailing) {
                Text(emoji)
                    .font(.system(size: 28))
                    .frame(width: 52, height: 52)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())

                Circle()
                    .fill(isActive ? Color.green : Color.gray)
                    .frame(width: 10, height: 10)
                    .overlay(Circle().strokeBorder(Color(hex: "#0A0A1A"), lineWidth: 1.5))
            }

            Text(name)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
            Text(distance)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(width: 72)
    }
}

struct CustomerActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(colors: [color, color.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                    )
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(glassCard(color: color.opacity(0.1)))
        }
        .buttonStyle(.plain)
    }
}
