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
                CustomerHomeView(selectedTab: $selectedTab, pendingMerchantPlace: $pendingMerchantPlace, user: User(email: "", name: LocalizedString("home.visitor"), role: .user))
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
            Color(hex: "#F5F3F0")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Spacer para safe area top (leído desde window)
                Color(hex: "#F5F3F0")
                    .frame(height: (UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first?.windows.first?.safeAreaInsets.top ?? 54) + 8)

                ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
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
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
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

        } // ZStack
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
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text(String(format: LocalizedString("home.hello"), user.name))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "#081754"))
                Text(LocalizedString("home.yourBusinessToday"))
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(Color(hex: "#4A4A4A"))
            }
            Spacer()
            Button(action: {
                MenuStateManager.shared.toggleMenu()
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            }) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "#FFAE43"))
                        .frame(width: 48, height: 48)
                    Text(String(user.name.prefix(1)).uppercased())
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(hex: "#FFFFFF"))
        .cornerRadius(12)
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : -10)
    }

    // MARK: - Business Status

    private var businessStatusCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(isBusinessActive ? LocalizedString("home.businessActive") : LocalizedString("home.businessPaused"))
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: "#081754"))
                Text(isBusinessActive ? LocalizedString("home.businessActiveDesc") : LocalizedString("home.businessPausedDesc"))
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(Color(hex: "#4A4A4A"))
            }
            Spacer()
            Button {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                toggleBusiness()
            } label: {
                RoundedRectangle(cornerRadius: 16)
                    .fill(isBusinessActive ? Color(hex: "#0ABF4F") : Color.gray.opacity(0.3))
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
        .background(Color(hex: "#FFFFFF"))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isBusinessActive ? Color(hex: "#0ABF4F").opacity(0.2) : Color(hex: "#FF594D").opacity(0.2),
                    lineWidth: 1
                )
        )
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 20)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isBusinessActive)
    }

    // MARK: - Metrics Grid

    private var metricsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedString("home.today"))
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(Color(hex: "#081754"))

            HStack(spacing: 12) {
                MetricCard(
                    icon: "person.fill",
                    value: "\(PresenceManager.shared.activeMerchantCount)",
                    label: LocalizedString("home.sellers"),
                    color: Color(hex: "#1C42E8")
                )
                MetricCard(
                    icon: "eye.fill",
                    value: "\(profileViews)",
                    label: LocalizedString("home.views"),
                    color: Color(hex: "#7D42FF")
                )
                Button(action: { showTimbreHistory = true }) {
                    MetricCard(
                        icon: "bell.fill",
                        value: "\(timbreManager.unreadCount)",
                        label: LocalizedString("home.timbres"),
                        color: timbreManager.unreadCount > 0 ? Color(hex: "#FFAE43") : Color(hex: "#4A4A4A")
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(Color(hex: "#FFFFFF"))
        .cornerRadius(12)
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 20)
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedString("home.quickActions"))
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(Color(hex: "#081754"))

            VStack(spacing: 10) {
                MerchantActionRow(
                    icon: "mappin.and.ellipse",
                    title: LocalizedString("home.updateLocation"),
                    subtitle: LocalizedString("home.updateLocationDesc"),
                    color: Color(hex: "#1C42E8")
                ) {
                    NavigationStateManager.shared.merchantLocationEditMode = true
                    selectedTab = 1
                }

                MerchantActionRow(
                    icon: "map.fill",
                    title: LocalizedString("home.viewDemandZones"),
                    subtitle: String(format: LocalizedString("home.searchesThisHour"), demandManager.totalDemandLastHour()),
                    color: Color(hex: "#0ABF4F")
                ) {
                    showDemandInsights = true
                }
            }
        }
        .padding(16)
        .background(Color(hex: "#FFFFFF"))
        .cornerRadius(12)
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 20)
    }

    // MARK: - Demand Tip

    private var demandTipCard: some View {
        let topZone = demandManager.topZones(limit: 1).first
        let tipTitle = topZone != nil
            ? "Demanda \(topZone!.intensity.displayName.lowercased()) de \(topZone!.topCategory?.displayName ?? "comida")"
            : LocalizedString("home.noDataYet")
        let tipSubtitle = topZone != nil
            ? "\(topZone!.demandScore) búsquedas en zona"
            : LocalizedString("home.dataWillAppear")

        return Button(action: { showDemandInsights = true }) {
            HStack(spacing: 12) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color(hex: "#FFAE43"))
                    .frame(width: 44, height: 44)
                    .background(Color(hex: "#FFAE43").opacity(0.12))
                    .cornerRadius(12)

                VStack(alignment: .leading, spacing: 3) {
                    Text(tipTitle)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: "#081754"))
                    Text(tipSubtitle)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundColor(Color(hex: "#4A4A4A"))
                        .lineLimit(2)
                }

                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "#FFAE43"))
            }
            .padding(14)
            .background(Color(hex: "#FFFFFF"))
            .cornerRadius(12)
        }
        .buttonStyle(PressButtonStyle())
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
            Color(hex: "#F5F3F0")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Color(hex: "#F5F3F0")
                    .frame(height: (UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first?.windows.first?.safeAreaInsets.top ?? 54) + 8)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
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
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 16)
            }
            } // VStack
        } // ZStack
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
                        Text(LocalizedString("home.products"))
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
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(radarService.isScanning ? Color(hex: "#0ABF4F") : Color(hex: "#4A4A4A"))
                    Text(LocalizedString("home.detectMerchants"))
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: "#081754"))
                }
                Spacer()
                if radarService.activeMerchantCount > 0 {
                    Text(String(format: LocalizedString("home.nearby"), radarService.activeMerchantCount))
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: "#0ABF4F"))
                }
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showRadar = true
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: "#1C42E8"))
                }
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
            }

            if radarService.discoveredMerchants.isEmpty {
                HStack(spacing: 10) {
                    ProgressView()
                        .tint(Color(hex: "#0ABF4F"))
                        .scaleEffect(CGFloat(0.8))
                    Text(LocalizedString("home.searchingMerchants"))
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundColor(Color(hex: "#4A4A4A"))
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(hex: "#EEE8E3"))
                .cornerRadius(12)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(radarService.discoveredMerchants.filter { !$0.isStale }) { peer in
                            InteractivePeerButton(
                                emoji: peer.emoji,
                                name: peer.businessName,
                                signalColor: peer.signalStrength.color,
                                action: {
                                    if let merchant = MerchantManager.shared.merchants.first(where: { $0.businessName == peer.businessName }) {
                                        selectedMerchantForTimbre = merchant
                                    }
                                }
                            )
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color(hex: "#FFFFFF"))
        .cornerRadius(12)
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 20)
    }

    private var customerHeader: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text(String(format: LocalizedString("home.hello"), user.name))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "#081754"))
                Text(LocalizedString("home.whatDoYouCrave"))
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(Color(hex: "#4A4A4A"))
            }
            Spacer()
            Button(action: {
                MenuStateManager.shared.toggleMenu()
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            }) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#1C42E8"), Color(hex: "#0ABF4F")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                    Text(String(user.name.prefix(1)).uppercased())
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(hex: "#FFFFFF"))
        .cornerRadius(12)
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : -10)
    }

    // MARK: - Nearby Merchants

    private var nearbyMerchantsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(LocalizedString("home.merchantsNearby"))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: "#081754"))
                Spacer()
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = 1
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: "#1C42E8"))
                }
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(nearbyMerchants) { merchant in
                        if merchant.isStatic {
                            Button(action: {
                                pendingMerchantPlace = SearchPlace(
                                    name: merchant.name,
                                    subtitle: "\(merchant.category) · \(merchant.distance)",
                                    category: merchant.category,
                                    icon: "mappin.circle.fill",
                                    coordinate: merchant.coordinate
                                )
                                selectedTab = 1
                            }) {
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
        .padding(16)
        .background(Color(hex: "#FFFFFF"))
        .cornerRadius(12)
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 20)
    }

    // MARK: - AI Recommendation

    private var aiRecommendationCard: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = 1
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color(hex: "#1C42E8"))
                    .frame(width: 44, height: 44)
                    .background(Color(hex: "#1C42E8").opacity(0.12))
                    .cornerRadius(12)

                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizedString("home.askAteneaAI"))
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: "#081754"))
                    Text(LocalizedString("home.askAteneaAIDesc"))
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundColor(Color(hex: "#4A4A4A"))
                        .lineLimit(2)
                }

                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "#1C42E8"))
            }
            .padding(14)
            .background(Color(hex: "#FFFFFF"))
            .cornerRadius(12)
        }
        .buttonStyle(PressButtonStyle())
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 20)
    }

    // MARK: - Voice Translator

    private var voiceTranslatorCard: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showVoiceTranslator = true
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: "waveform.and.mic")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color(hex: "#7D42FF"))
                    .frame(width: 44, height: 44)
                    .background(Color(hex: "#7D42FF").opacity(0.12))
                    .cornerRadius(12)

                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizedString("home.voiceTranslator"))
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: "#081754"))
                    Text(LocalizedString("home.voiceTranslatorDesc"))
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundColor(Color(hex: "#4A4A4A"))
                        .lineLimit(2)
                }

                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "#7D42FF"))
            }
            .padding(14)
            .background(Color(hex: "#FFFFFF"))
            .cornerRadius(12)
        }
        .buttonStyle(PressButtonStyle())
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 20)
    }

    // MARK: - Quick Actions

    private var customerQuickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedString("home.quickActions"))
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(Color(hex: "#081754"))

            HStack(spacing: 12) {
                CustomerActionButton(icon: "camera.viewfinder", label: LocalizedString("home.menuAR"), color: Color(hex: "#7D42FF")) {
                    showARStreetMenu = true
                }
                CustomerActionButton(icon: "wave.3.right", label: LocalizedString("home.pay"), color: Color(hex: "#1CA8F7")) {
                    showTapToPay = true
                }
                CustomerActionButton(icon: "bell.fill", label: LocalizedString("home.timbre"), color: Color(hex: "#FFAE43")) {
                    if let first = merchantManager.activeMerchants().first {
                        selectedMerchantForTimbre = first
                    }
                }
                CustomerActionButton(icon: "mappin.and.ellipse", label: LocalizedString("home.search"), color: Color(hex: "#1C42E8")) {
                    selectedTab = 1
                }
            }
        }
        .padding(16)
        .background(Color(hex: "#FFFFFF"))
        .cornerRadius(12)
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 20)
    }

    // MARK: - World Cup Card

    private var worldCupEventCard: some View {
        Button(action: {}) {
            HStack(spacing: 12) {
                Image(systemName: "soccerball")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color(hex: "#0ABF4F"))
                    .frame(width: 44, height: 44)
                    .background(Color(hex: "#0ABF4F").opacity(0.12))
                    .cornerRadius(12)

                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizedString("home.matchToday"))
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: "#081754"))
                    Text(LocalizedString("home.matchTodayDesc"))
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundColor(Color(hex: "#4A4A4A"))
                        .lineLimit(2)
                }

                Spacer()
            }
            .padding(14)
            .background(Color(hex: "#FFFFFF"))
            .cornerRadius(12)
        }
        .buttonStyle(PressButtonStyle())
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 20)
    }
}

// MARK: - Shared Components

struct MetricCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: "#081754"))
            Text(label)
                .font(.system(size: 11, weight: .regular, design: .rounded))
                .foregroundColor(Color(hex: "#4A4A4A"))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(hex: "#FFFFFF"))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.15), lineWidth: 1)
        )
    }
}

struct MerchantActionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void

    @State private var isPressed = false

    private var strokeColor: Color {
        color.opacity(isPressed ? 0.25 : 0.15)
    }

    private var contentScale: CGFloat {
        isPressed ? 0.97 : 1.0
    }

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                    isPressed = false
                }
            }
            action()
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
                    .frame(width: 44, height: 44)
                    .background(color.opacity(0.12))
                    .cornerRadius(10)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: "#081754"))
                    Text(subtitle)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundColor(Color(hex: "#4A4A4A"))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(color)
            }
            .padding(12)
            .background(Color(hex: "#FFFFFF"))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(strokeColor, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .modifier(ScaleModifier(scale: contentScale))
        .modifier(OpacityModifier(opacity: isPressed ? 0.85 : 1.0))
    }
}

struct NearbyMerchantChip: View {
    let emoji: String
    let name: String
    let distance: String
    let isActive: Bool
    var isStatic: Bool = true

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .bottomTrailing) {
                Text(emoji)
                    .font(.system(size: 28))
                    .frame(width: 56, height: 56)
                    .background(Color(hex: "#EEE8E3"))
                    .clipShape(Circle())

                Circle()
                    .fill(isActive ? Color(hex: "#0ABF4F") : Color(hex: "#4A4A4A"))
                    .frame(width: 10, height: 10)
                    .overlay(Circle().strokeBorder(Color(hex: "#FFFFFF"), lineWidth: 1.5))
            }

            Text(name)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(Color(hex: "#081754"))
            Text(distance)
                .font(.system(size: 11, weight: .regular, design: .rounded))
                .foregroundColor(Color(hex: "#4A4A4A"))

            Text(isStatic ? LocalizedString("home.fixed") : LocalizedString("home.nomad"))
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundColor(isStatic ? Color(hex: "#1C42E8") : Color(hex: "#FFAE43"))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(isStatic ? Color(hex: "#1C42E8").opacity(0.12) : Color(hex: "#FFAE43").opacity(0.12))
                )
        }
        .frame(width: 80)
    }
}

struct InteractivePeerButton: View {
    let emoji: String
    let name: String
    let signalColor: Color
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                    isPressed = false
                }
            }
            action()
        }) {
            VStack(spacing: 8) {
                ZStack(alignment: .bottomTrailing) {
                    Text(emoji)
                        .font(.system(size: 28))
                        .frame(width: 56, height: 56)
                        .background(Color(hex: "#EEE8E3"))
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(signalColor.opacity(isPressed ? 0.6 : 0.4), lineWidth: 1.5)
                        )

                    Circle()
                        .fill(signalColor)
                        .frame(width: 10, height: 10)
                        .overlay(Circle().strokeBorder(Color(hex: "#FFFFFF"), lineWidth: 1.5))
                }

                Text(name)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: "#081754"))
                    .lineLimit(1)

                Text(LocalizedString("home.live"))
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: "#0ABF4F"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(hex: "#0ABF4F").opacity(0.12))
                    .cornerRadius(4)
            }
            .frame(width: 80)
            .modifier(ScaleModifier(scale: isPressed ? 0.92 : 1.0))
            .modifier(OpacityModifier(opacity: isPressed ? 0.75 : 1.0))
        }
        .buttonStyle(.plain)
    }
}

struct CustomerActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    @State private var isPressed = false

    private var borderColor: Color {
        color.opacity(isPressed ? 0.4 : 0.2)
    }

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                    isPressed = false
                }
            }
            action()
        }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
                    .modifier(ScaleModifier(scale: isPressed ? 1.1 : 1.0))
                Text(label)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: "#081754"))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(hex: "#FFFFFF"))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 1)
            )
            .modifier(ScaleModifier(scale: isPressed ? 0.95 : 1.0))
            .modifier(OpacityModifier(opacity: isPressed ? 0.8 : 1.0))
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Press Button Style
struct PressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        let scale: CGFloat = configuration.isPressed ? 0.95 : 1.0
        return configuration.label
            .modifier(ScaleModifier(scale: scale))
            .modifier(OpacityModifier(opacity: configuration.isPressed ? 0.8 : 1.0))
    }
}

// MARK: - Opacity Modifier
struct OpacityModifier: ViewModifier {
    let opacity: Double

    func body(content: Content) -> some View {
        content.opacity(opacity)
    }
}

// MARK: - Scale Modifier
struct ScaleModifier: ViewModifier {
    let scale: CGFloat

    func body(content: Content) -> some View {
        content
            .transformEffect(CGAffineTransform(scaleX: scale, y: scale))
    }
}
