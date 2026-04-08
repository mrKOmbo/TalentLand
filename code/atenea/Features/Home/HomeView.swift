//
//  HomeView.swift
//  atenea
//
//  Vista de inicio adaptativa por rol (comerciante / cliente)
//

import SwiftUI
import CoreLocation

// MARK: - Nearby Merchant Model

struct NearbyMerchant: Identifiable {
    let id = UUID()
    let emoji: String
    let name: String
    let distance: String
    let isActive: Bool
    let isStatic: Bool
    let category: String
    let coordinate: CLLocationCoordinate2D
}

// Mock location del usuario (Centro de CDMX) — se reemplazará con LocationManager real
let mockUserLatitude = 19.4326
let mockUserLongitude = -99.1332

struct HomeView: View {
    @Binding var selectedTab: Int
    @Binding var pendingMerchantPlace: SearchPlace?
    @ObservedObject private var userManager = UserManager.shared
    @EnvironmentObject var languageManager: LanguageManager

    var body: some View {
        Group {
            if let user = userManager.currentUser {
                let _ = print("🏠 [HomeView] User: \(user.name) | role: \(user.role.rawValue) | isMerchant: \(user.isMerchant)")
                if user.isMerchant {
                    MerchantHomeView(selectedTab: $selectedTab, user: user)
                        .environmentObject(languageManager)
                } else {
                    CustomerHomeView(selectedTab: $selectedTab, pendingMerchantPlace: $pendingMerchantPlace, user: user)
                        .environmentObject(languageManager)
                }
            } else {
                let _ = print("🏠 [HomeView] No user → Visitante")
                CustomerHomeView(selectedTab: $selectedTab, pendingMerchantPlace: $pendingMerchantPlace, user: User(email: "", name: "Visitante", role: .user))
                    .environmentObject(languageManager)
            }
        }
    }
}

// MARK: - Merchant Home

struct MerchantHomeView: View {
    @Binding var selectedTab: Int
    let user: User

    @ObservedObject private var merchantManager = MerchantManager.shared
    @ObservedObject private var timbreManager = TimbreManager.shared
    @ObservedObject private var demandManager = DemandZoneManager.shared
    @ObservedObject private var radarService = RadarService.shared
    @State private var profileViews = 87
    @State private var animateCards = false
    @State private var isReady = false
    @State private var showTimbreHistory = false
    @State private var showDemandInsights = false
    @State private var showStreetCredDetail = false
    @State private var showPredictionDetail = false
    @State private var streetCredScore: StreetCredScore?
    @State private var matchPrediction: MatchPrediction?

    private var isBusinessActive: Bool {
        merchantManager.currentMerchantProfile?.isActive ?? false
    }

    private func toggleBusiness() {
        guard let id = merchantManager.currentMerchantProfile?.id else {
            print("🏪 [toggle] ERROR: no hay currentMerchantProfile")
            return
        }
        print("🏪 [toggle] Antes: isActive=\(merchantManager.currentMerchantProfile?.isActive ?? false)")
        DispatchQueue.main.async {
            merchantManager.toggleActive(merchantId: id)
            print("🏪 [toggle] Después: isActive=\(merchantManager.currentMerchantProfile?.isActive ?? false)")
        }
    }

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

                    // Street Cred Score
                    if let score = streetCredScore {
                        StreetCredCardView(score: score) {
                            showStreetCredDetail = true
                        }
                        .opacity(animateCards ? 1 : 0)
                        .offset(y: animateCards ? 0 : 20)
                    }

                    // Métricas del día
                    metricsGrid

                    // Acciones rápidas
                    quickActionsSection

                    // Tip del día
                    demandTipCard

                    // Predicción del próximo partido
                    if let prediction = matchPrediction {
                        PredictionCardView(
                            prediction: prediction,
                            merchantCategory: merchantManager.currentMerchantProfile?.category,
                            onTap: { showPredictionDetail = true }
                        )
                        .opacity(animateCards ? 1 : 0)
                        .offset(y: animateCards ? 0 : 20)
                    }

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
            }

            // Notificación de timbre
            if let timbre = timbreManager.newTimbreReceived {
                let _ = print("🔔 [MerchantHome] ⚡ TIMBRE DETECTADO: \(timbre.clientName) → \(timbre.type.displayName)")
                VStack {
                    TimbreNotificationView(
                        timbre: timbre,
                        onRespond: { responseType in
                            timbreManager.respond(to: timbre.id, with: responseType)
                            timbreManager.newTimbreReceived = nil
                        },
                        onDismiss: {
                            timbreManager.newTimbreReceived = nil
                        }
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                    Spacer()
                }
                .padding(.top, 50)
                .zIndex(100)
            }

        }
        .onAppear {
            Task { @MainActor in
                // Cargar datos ANTES de mostrar la UI
                try? await Task.sleep(nanoseconds: 200_000_000)

                demandManager.refreshMockData(around: (19.3585, -99.2740))

                if let merchant = merchantManager.currentMerchantProfile {
                    let scm = StreetCredManager.shared
                    if scm.activityLog.filter({ $0.merchantId == merchant.id }).isEmpty {
                        scm.generateMockData(for: merchant)
                    }
                    streetCredScore = scm.calculateScore(for: merchant)
                }
                matchPrediction = PredictionEngine.shared.predictNextMatch()

                // Mostrar UI
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    isReady = true
                    animateCards = true
                }

                // Radar después de que UI esté estable
                try? await Task.sleep(nanoseconds: 500_000_000)

                if let merchant = merchantManager.currentMerchantProfile, merchant.isActive {
                    PresenceManager.shared.startBroadcasting(merchant: merchant)
                    RadarService.shared.startAdvertising(merchant: merchant)
                }
                RadarService.shared.startScanning()
                print("🏠 [MerchantHome] ── READY ──")
            }
            print("🏠 [MerchantHome] ── ON APPEAR END ──")
        }
        .onChange(of: merchantManager.currentMerchantProfile?.isActive) { _, isActive in
            DispatchQueue.main.async {
                if let merchant = merchantManager.currentMerchantProfile, isActive == true {
                    PresenceManager.shared.startBroadcasting(merchant: merchant)
                    RadarService.shared.startAdvertising(merchant: merchant)
                } else {
                    PresenceManager.shared.stopBroadcasting()
                    RadarService.shared.stopAdvertising()
                }
            }
        }
        .sheet(isPresented: $showTimbreHistory) {
            TimbreHistoryView()
        }
        .sheet(isPresented: $showStreetCredDetail) {
            if let score = streetCredScore {
                StreetCredDetailView(score: score)
            }
        }
        .sheet(isPresented: $showPredictionDetail) {
            if let prediction = matchPrediction {
                PredictionDetailView(prediction: prediction, selectedTab: $selectedTab)
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
            Button {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                toggleBusiness()
            } label: {
                RoundedRectangle(cornerRadius: 16)
                    .fill(isBusinessActive ? Color.green : Color.gray.opacity(0.3))
                    .frame(width: 51, height: 31)
                    .overlay(alignment: isBusinessActive ? .trailing : .leading) {
                        Circle()
                            .fill(.white)
                            .frame(width: 27, height: 27)
                            .padding(2)
                    }
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isBusinessActive)
            }
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
                    value: "\(PresenceManager.shared.activeMerchantCount)",
                    label: "Vendedores zona",
                    color: .blue
                )
                MetricCard(
                    icon: "eye.fill",
                    value: "\(profileViews)",
                    label: "Vistas de perfil",
                    color: .purple
                )
                Button { showTimbreHistory = true } label: {
                    MetricCard(
                        icon: "bell.fill",
                        value: "\(timbreManager.unreadCount)",
                        label: "Timbres",
                        color: timbreManager.unreadCount > 0 ? .orange : .gray
                    )
                }
                .buttonStyle(.plain)
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
                    NavigationStateManager.shared.merchantLocationEditMode = true
                    selectedTab = 1
                }


                MerchantActionRow(
                    icon: "map.fill",
                    title: "Ver zonas de demanda",
                    subtitle: "\(demandManager.totalDemandLastHour()) búsquedas en la última hora",
                    color: .green
                ) {
                    showDemandInsights = true
                }
            }
        }
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 20)
    }

    // MARK: - Demand Tip

    private var demandTipCard: some View {
        let topZone = demandManager.topZones(limit: 1).first
        let tipTitle = topZone != nil
            ? "Demanda \(topZone!.intensity.displayName.lowercased()) de \(topZone!.topCategory?.displayName ?? "comida")"
            : "Sin datos de demanda aún"
        let tipSubtitle = topZone != nil
            ? "\(topZone!.demandScore) búsquedas en zona \(topZone!.geohash.prefix(5))… · Toca para ver más"
            : "Las búsquedas y timbres de clientes aparecerán aquí"

        return Button { showDemandInsights = true } label: {
            HStack(spacing: 14) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 22))
                    .foregroundStyle(LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom))
                    .frame(width: 44, height: 44)
                    .background(Color.yellow.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 3) {
                    Text(tipTitle)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    Text(tipSubtitle)
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
            .background(glassCard(color: topZone?.intensity.color.opacity(0.08) ?? .yellow.opacity(0.08)))
        }
        .buttonStyle(.plain)
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 20)
        .sheet(isPresented: $showDemandInsights) {
            DemandInsightsView(selectedTab: $selectedTab)
        }
    }
}

// MARK: - Customer Home

struct CustomerHomeView: View {
    @Binding var selectedTab: Int
    @Binding var pendingMerchantPlace: SearchPlace?
    let user: User

    @StateObject private var merchantManager = MerchantManager.shared
    @StateObject private var radarService = RadarService.shared
    @State private var animateCards = false
    @State private var selectedMerchantForTimbre: Merchant?
    @State private var showRadar = false
    @State private var showTapToPay = false
    @State private var showARStreetMenu = false
    @State private var showVoiceTranslator = false

    private var nearbyMerchants: [NearbyMerchant] {
        merchantManager.nearbyMerchantsList(fromLatitude: mockUserLatitude, longitude: mockUserLongitude)
    }

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

                    // Radar P2P — merchants detectados en vivo
                    radarSection

                    // Comerciantes activos cerca
                    nearbyMerchantsSection

                    // Recomendación IA
                    aiRecommendationCard

                    // Traductor de voz
                    voiceTranslatorCard

                    // Acciones rápidas
                    customerQuickActions

                    // Evento Mundial
                    worldCupEventCard

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                animateCards = true
            }
            // Iniciar radar automáticamente (diferido para evitar "Publishing changes from within view updates")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                RadarService.shared.startScanning()
            }
        }
        .fullScreenCover(isPresented: $showRadar) {
            RadarView()
        }
        .fullScreenCover(isPresented: $showTapToPay) {
            TapToPayCustomerView()
        }
        .fullScreenCover(isPresented: $showARStreetMenu) {
            ARStreetMenuView()
                .environmentObject(LanguageManager.shared)
        }
        .sheet(isPresented: $showVoiceTranslator) {
            VoiceTranslatorView()
        }
        .sheet(item: $selectedMerchantForTimbre) { merchant in
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text(merchant.emoji)
                        .font(.system(size: 48))
                    Text(merchant.businessName)
                        .font(.system(size: 20, weight: .bold))
                    Text(merchant.category.displayName)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    if !merchant.description.isEmpty {
                        Text(merchant.description)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                .padding(.top, 24)

                if !merchant.products.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("PRODUCTOS")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                            .kerning(1.2)
                        ForEach(merchant.products) { product in
                            HStack {
                                Text(product.emoji)
                                Text(product.name)
                                    .font(.system(size: 14))
                                Spacer()
                                Text(product.formattedPrice)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }

                Spacer()

                TimbreButtonView(merchant: merchant)
                    .padding(.bottom, 30)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Header

    // MARK: - Radar P2P Section

    private var radarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 12))
                        .foregroundColor(radarService.isScanning ? .green : .gray)
                    Text("RADAR P2P")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                        .kerning(1.5)
                }
                Spacer()
                if radarService.activeMerchantCount > 0 {
                    Text("\(radarService.activeMerchantCount) detectados")
                        .font(.system(size: 12))
                        .foregroundColor(.green)
                }
                Button("Ver radar") {
                    showRadar = true
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(LinearGradient(colors: [.green, .cyan], startPoint: .leading, endPoint: .trailing))
            }

            if radarService.discoveredMerchants.isEmpty {
                HStack(spacing: 10) {
                    ProgressView()
                        .tint(.green)
                        .scaleEffect(CGFloat(0.8))
                    Text("Buscando comerciantes por Bluetooth/WiFi...")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.ultraThinMaterial)
                        RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.green.opacity(0.03))
                    }
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(radarService.discoveredMerchants.filter { !$0.isStale }) { peer in
                            Button {
                                if let merchant = MerchantManager.shared.merchants.first(where: { $0.businessName == peer.businessName }) {
                                    selectedMerchantForTimbre = merchant
                                }
                            } label: {
                                VStack(spacing: 6) {
                                    ZStack(alignment: .bottomTrailing) {
                                        Text(peer.emoji)
                                            .font(.system(size: 28))
                                            .frame(width: 52, height: 52)
                                            .background(Color.white.opacity(0.08))
                                            .clipShape(Circle())
                                            .overlay(
                                                Circle()
                                                    .stroke(peer.signalStrength.color.opacity(0.4), lineWidth: 1.5)
                                            )

                                        Circle()
                                            .fill(peer.signalStrength.color)
                                            .frame(width: 10, height: 10)
                                            .overlay(Circle().strokeBorder(Color(hex: "#0A0A1A"), lineWidth: 1.5))
                                    }

                                    Text(peer.businessName)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.white)
                                        .lineLimit(1)

                                    Text("EN VIVO")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundColor(.green)
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 2)
                                        .background(Capsule().fill(Color.green.opacity(0.15)))
                                }
                                .frame(width: 72)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 20)
    }

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
                    selectedTab = 1
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(nearbyMerchants) { merchant in
                        if merchant.isStatic {
                            Button {
                                pendingMerchantPlace = SearchPlace(
                                    name: merchant.name,
                                    subtitle: "\(merchant.category) · \(merchant.distance)",
                                    category: merchant.category,
                                    icon: "mappin.circle.fill",
                                    coordinate: merchant.coordinate
                                )
                                selectedTab = 1
                            } label: {
                                NearbyMerchantChip(emoji: merchant.emoji, name: merchant.name, distance: merchant.distance, isActive: merchant.isActive, isStatic: true)
                            }
                            .buttonStyle(.plain)
                        } else {
                            NearbyMerchantChip(emoji: merchant.emoji, name: merchant.name, distance: merchant.distance, isActive: merchant.isActive, isStatic: false)
                        }
                    }
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

    // MARK: - Voice Translator

    private var voiceTranslatorCard: some View {
        Button { showVoiceTranslator = true } label: {
            HStack(spacing: 14) {
                Image(systemName: "waveform.and.mic")
                    .font(.system(size: 22))
                    .foregroundStyle(LinearGradient(colors: [.purple, .pink], startPoint: .top, endPoint: .bottom))
                    .frame(width: 44, height: 44)
                    .background(Color.purple.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 3) {
                    Text("Traductor de voz")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Habla y el vendedor te entiende al instante")
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
            .background(glassCard(color: .purple.opacity(0.1)))
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
                CustomerActionButton(icon: "camera.viewfinder", label: "AR\nMenú", color: .purple) {
                    showARStreetMenu = true
                }
                CustomerActionButton(icon: "wave.3.right", label: "Tap to\nPay", color: .cyan) {
                    showTapToPay = true
                }
                CustomerActionButton(icon: "bell.fill", label: "Timbrar\ncercano", color: .orange) {
                    if let first = merchantManager.activeMerchants().first {
                        selectedMerchantForTimbre = first
                    }
                }
                CustomerActionButton(icon: "mappin.and.ellipse", label: "Buscar\ncomercio", color: .blue) {
                    selectedTab = 1
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
    var isStatic: Bool = true

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

            Text(isStatic ? "Fijo" : "Nómada")
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(isStatic ? .blue : .orange)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(isStatic ? Color.blue.opacity(0.15) : Color.orange.opacity(0.15))
                )
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
