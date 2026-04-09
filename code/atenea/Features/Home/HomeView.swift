//
//  HomeView.swift
//  atenea
//
//  Vista de inicio adaptativa por rol (comerciante / cliente)
//

import SwiftUI
import CoreLocation
internal import Combine

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

// Mock location del usuario (Expo Santa Fe, CDMX) — se reemplazará con LocationManager real
let mockUserLatitude = 19.3580
let mockUserLongitude = -99.2620

// MARK: - HomeView Router

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
    @ObservedObject private var radarService = RadarService.shared
    @State private var profileViews = 87
    @State private var animateCards = false
    @State private var isReady = false
    @State private var showTimbreHistory = false
    @State private var shownTimbreId: UUID? = nil
    @State private var merchantChatTimbre: TimbreEvent? = nil
    @State private var showStreetCredDetail = false
    @State private var showBusinessQR = false
    @State private var streetCredScore: StreetCredScore?

    private var isBusinessActive: Bool {
        merchantManager.currentMerchantProfile?.isActive ?? false
    }

    private func toggleBusiness() {
        guard let id = merchantManager.currentMerchantProfile?.id else {
            print("🏪 [toggle] ERROR: no hay currentMerchantProfile")
            return
        }
        DispatchQueue.main.async {
            merchantManager.toggleActive(merchantId: id)
        }
    }

    var body: some View {
        ZStack {
            Color(hex: "#F5F3F0").ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        merchantHeroHeader
                        businessStatusCard
                        if let score = streetCredScore {
                            StreetCredCardView(score: score) {
                                showStreetCredDetail = true
                            }
                            .opacity(animateCards ? 1 : 0)
                            .offset(y: animateCards ? 0 : 20)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1), value: animateCards)
                        }
                        metricsGrid
                        quickActionsSection
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 0)
                    .padding(.bottom, 16)
                }
            }

            // Timbre overlay
            if let timbre = timbreManager.newTimbreReceived {
                VStack {
                    TimbreNotificationView(
                        timbre: timbre,
                        onRespond: { responseType in
                            timbreManager.respond(to: timbre.id, with: responseType)
                            timbreManager.newTimbreReceived = nil
                        },
                        onDismiss: { timbreManager.newTimbreReceived = nil },
                        onChat: {
                            merchantChatTimbre = timbre
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
        .onChange(of: timbreManager.newTimbreReceived?.id) { timbreId in
            guard let id = timbreId, id != shownTimbreId else { return }
            shownTimbreId = id
            if let timbre = timbreManager.newTimbreReceived {
                print("🔔 [MerchantHome] ⚡ TIMBRE: \(timbre.clientName) → \(timbre.type.displayName)")
            }
        }
        .onAppear {
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 200_000_000)
                if let merchant = merchantManager.currentMerchantProfile {
                    let scm = StreetCredManager.shared
                    if scm.activityLog.filter({ $0.merchantId == merchant.id }).isEmpty {
                        scm.generateMockData(for: merchant)
                    }
                    streetCredScore = scm.calculateScore(for: merchant)
                }
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    isReady = true
                    animateCards = true
                }
                try? await Task.sleep(nanoseconds: 500_000_000)
                if let merchant = merchantManager.currentMerchantProfile {
                    if merchant.isActive { PresenceManager.shared.startBroadcasting(merchant: merchant) }
                    RadarService.shared.startAdvertising(merchant: merchant)
                } else {
                    print("🏠 [MerchantHome] ⚠️ No hay currentMerchantProfile")
                }
                RadarService.shared.startScanning()
                print("🏠 [MerchantHome] ── READY ──")
            }
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
        .sheet(isPresented: $showTimbreHistory) { TimbreHistoryView() }
        .sheet(item: $merchantChatTimbre) { timbre in MerchantTimbreChatView(timbre: timbre) }
        .sheet(isPresented: $showStreetCredDetail) {
            if let score = streetCredScore { StreetCredDetailView(score: score) }
        }
    }

    // MARK: - Merchant Hero Header

    private var merchantHeroHeader: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [Color(hex: "#1C42E8"), Color(hex: "#081754")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Decorative orbs
            Circle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 200, height: 200)
                .offset(x: 160, y: -40)
            Circle()
                .fill(Color(hex: "#1C42E8").opacity(0.35))
                .frame(width: 100, height: 100)
                .offset(x: -60, y: 50)

            // Safe area top padding
            let topInset = (UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first?.windows.first?.safeAreaInsets.top ?? 54)

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(LocalizedString("home.yourBusinessToday"))
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.72))
                    Text(String(format: LocalizedString("home.hello"), user.name))
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    if let biz = merchantManager.currentMerchantProfile {
                        HStack(spacing: 6) {
                            Text(biz.emoji).font(.system(size: 14))
                            Text(biz.businessName)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.88))
                        }
                    }
                }
                Spacer()
                Button(action: {
                    MenuStateManager.shared.toggleMenu()
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "#F0D224"))
                            .frame(width: 50, height: 50)
                        Text(String(user.name.prefix(1)).uppercased())
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundColor(Color(hex: "#081754"))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, topInset + 12)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity)
        .cornerRadius(20)
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : -20)
        .animation(.spring(response: 0.65, dampingFraction: 0.85), value: animateCards)
    }

    // MARK: - Business Status

    private var businessStatusCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(isBusinessActive ? Color(hex: "#1C42E8").opacity(0.12) : Color.gray.opacity(0.1))
                    .frame(width: 50, height: 50)
                Image(systemName: isBusinessActive ? "antenna.radiowaves.left.and.right" : "moon.zzz.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(isBusinessActive ? Color(hex: "#1C42E8") : Color(hex: "#4A4A4A"))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(isBusinessActive ? LocalizedString("home.businessActive") : LocalizedString("home.businessPaused"))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "#081754"))
                Text(isBusinessActive ? LocalizedString("home.businessActiveDesc") : LocalizedString("home.businessPausedDesc"))
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(Color(hex: "#4A4A4A"))
            }

            Spacer()

            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                toggleBusiness()
            } label: {
                ZStack(alignment: isBusinessActive ? .trailing : .leading) {
                    Capsule()
                        .fill(isBusinessActive ? Color(hex: "#1C42E8") : Color.gray.opacity(0.28))
                        .frame(width: 54, height: 32)
                    Circle()
                        .fill(.white)
                        .frame(width: 28, height: 28)
                        .padding(2)
                        .shadow(color: .black.opacity(0.12), radius: 2, x: 0, y: 1)
                }
                .animation(.spring(response: 0.32, dampingFraction: 0.7), value: isBusinessActive)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(
            color: isBusinessActive ? Color(hex: "#1C42E8").opacity(0.12) : .black.opacity(0.04),
            radius: 12, x: 0, y: 4
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(
                    isBusinessActive ? Color(hex: "#1C42E8").opacity(0.22) : Color.clear,
                    lineWidth: 1.5
                )
        )
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 20)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.05), value: animateCards)
        .animation(.spring(response: 0.32, dampingFraction: 0.7), value: isBusinessActive)
    }

    // MARK: - Metrics Grid

    private var metricsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedString("home.today"))
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: "#1C42E8"))
                .kerning(1.0)
                .textCase(.uppercase)

            HStack(spacing: 10) {
                MetricCard(
                    icon: "person.2.fill",
                    value: "\(PresenceManager.shared.activeMerchantCount)",
                    label: LocalizedString("home.sellers"),
                    color: Color(hex: "#1C42E8")
                )
                MetricCard(
                    icon: "eye.fill",
                    value: "\(profileViews)",
                    label: LocalizedString("home.views"),
                    color: Color(hex: "#1C42E8")
                )
                Button(action: { showTimbreHistory = true }) {
                    MetricCard(
                        icon: "bell.fill",
                        value: "\(timbreManager.unreadCount)",
                        label: LocalizedString("home.timbres"),
                        color: timbreManager.unreadCount > 0 ? Color(hex: "#F0D224") : Color(hex: "#4A4A4A")
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 20)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.12), value: animateCards)
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedString("home.quickActions"))
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: "#1C42E8"))
                .kerning(1.0)
                .textCase(.uppercase)

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
                    icon: "qrcode",
                    title: LocalizedString("qr.viewMyQR"),
                    subtitle: LocalizedString("qr.showToCustomers"),
                    color: Color(hex: "#F0D224")
                ) {
                    showBusinessQR = true
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 20)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.18), value: animateCards)
        .sheet(isPresented: $showBusinessQR) {
            if let merchant = merchantManager.currentMerchantProfile {
                BusinessQRView(merchant: merchant)
            }
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
    @StateObject private var contextEngine = ContextEngine()
    @StateObject private var locationManager = LocationManager()
    @ObservedObject private var timbreManager = TimbreManager.shared
    @State private var animateCards = false
    @State private var heroAppeared = false
    @State private var selectedMerchantForTimbre: Merchant?
    @State private var selectedCategoryFilter: MerchantCategory? = nil
    @State private var showRadar = false
    @State private var showTapToPay = false
    @State private var showARStreetMenu = false
    @State private var showVoiceTranslator = false
    @State private var showAIChat = false
    @State private var aiChatPrefill: String = ""
    @State private var showTimbreChat = false
    @State private var chatMerchantName: String = ""
    @State private var chatMerchantEmoji: String = ""
    @State private var chatMerchant: Merchant?

    private var userCoordinate: CLLocationCoordinate2D {
        locationManager.currentLocation ?? CLLocationCoordinate2D(latitude: 19.3601, longitude: -99.2592)
    }

    private var filteredMerchants: [Merchant] {
        let active = merchantManager.merchants.filter { $0.isActive && $0.currentLocation != nil }
        let filtered = selectedCategoryFilter == nil ? active : active.filter { $0.category == selectedCategoryFilter }
        return filtered.sorted { a, b in
            let dA = MerchantManager.haversineDistance(
                lat1: userCoordinate.latitude, lon1: userCoordinate.longitude,
                lat2: a.currentLocation!.latitude, lon2: a.currentLocation!.longitude
            )
            let dB = MerchantManager.haversineDistance(
                lat1: userCoordinate.latitude, lon1: userCoordinate.longitude,
                lat2: b.currentLocation!.latitude, lon2: b.currentLocation!.longitude
            )
            return dA < dB
        }
    }

    private var activeCategories: [MerchantCategory] {
        let cats = Set(merchantManager.merchants.filter { $0.isActive }.map { $0.category })
        return MerchantCategory.allCases.filter { cats.contains($0) }
    }

    private var merchantsOnRoute: [Merchant] {
        merchantManager.merchants.filter { $0.isOnRoute && $0.currentLocation != nil }
    }

    private func distanceToMerchant(_ merchant: Merchant) -> Double {
        guard let loc = merchant.currentLocation else { return .infinity }
        return MerchantManager.haversineDistance(
            lat1: userCoordinate.latitude, lon1: userCoordinate.longitude,
            lat2: loc.latitude, lon2: loc.longitude
        )
    }

    private func formatDistance(_ meters: Double) -> String {
        meters < 1000 ? "\(Int(meters))m" : String(format: "%.1fkm", meters / 1000)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color(hex: "#F5F3F0").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // 1. HERO — full-width gradient
                    customerHeroSection

                    // 2. Content sections
                    VStack(spacing: 14) {
                        // Atenea insight (activado)
                        ateneaInsightSection

                        // Story bubbles de merchants
                        merchantStoriesSection

                        // Radar P2P compacto
                        radarCompactSection

                        // Grid 2×2 de acciones
                        customerActionsGrid

                        // Mundial
                        worldCupEventCard

                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 18)
                    .padding(.bottom, 16)
                }
            }
        }
        .onAppear {
            print("🏠 [CustomerHome] onAppear — user=\(user.name)")
            withAnimation(.spring(response: 0.7, dampingFraction: 0.85).delay(0.05)) {
                heroAppeared = true
                animateCards = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                RadarService.shared.startScanning()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                contextEngine.evaluate()
            }
        }
        .fullScreenCover(isPresented: $showRadar) { RadarView() }
        .fullScreenCover(isPresented: $showTapToPay) { TapToPayCustomerView() }
        .fullScreenCover(isPresented: $showARStreetMenu) {
            ARStreetMenuView().environmentObject(LanguageManager.shared)
        }
        .fullScreenCover(isPresented: $showAIChat) {
            AISearchView(
                isPresented: $showAIChat,
                onNavigateToLocation: { _, _, _ in showAIChat = false; selectedTab = 1 },
                onShowDirections: { _, _ in showAIChat = false; selectedTab = 1 }
            )
        }
        .sheet(isPresented: $showVoiceTranslator) { VoiceTranslatorView() }
        .sheet(item: $selectedMerchantForTimbre) { merchant in
            TimbreChatView(merchantName: merchant.businessName, merchantEmoji: merchant.emoji, merchant: merchant)
        }
        .sheet(isPresented: $showTimbreChat) {
            TimbreChatView(merchantName: chatMerchantName, merchantEmoji: chatMerchantEmoji, merchant: chatMerchant)
        }
        .onChange(of: timbreManager.lastResponse) { _, response in
            guard let response = response else { return }
            guard selectedMerchantForTimbre == nil && !showTimbreChat else {
                timbreManager.lastResponse = nil
                return
            }
            if let timbre = timbreManager.sentTimbres.first(where: { $0.id == response.timbreId }) {
                let merchant = merchantManager.merchants.first(where: { $0.id == response.merchantId })
                chatMerchantName = timbre.merchantName
                chatMerchantEmoji = merchant?.emoji ?? "🏪"
                chatMerchant = merchant
                showTimbreChat = true
            }
            timbreManager.lastResponse = nil
        }
    }

    // MARK: - Hero Section

    private var customerHeroSection: some View {
        ZStack(alignment: .bottom) {
            // Gradient hero — colores Atenea
            LinearGradient(
                colors: [Color(hex: "#F0D224"), Color(hex: "#1C42E8"), Color(hex: "#081754")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Decorative orbs
            Circle()
                .fill(Color.white.opacity(0.07))
                .frame(width: 240, height: 240)
                .offset(x: 120, y: -70)
            Circle()
                .fill(Color(hex: "#1C42E8").opacity(0.18))
                .frame(width: 130, height: 130)
                .offset(x: -130, y: 50)
            Circle()
                .fill(Color(hex: "#F0D224").opacity(0.18))
                .frame(width: 80, height: 80)
                .offset(x: 130, y: 70)

            // Content
            VStack(alignment: .leading, spacing: 0) {
                // Safe area
                Color.clear.frame(
                    height: (UIApplication.shared.connectedScenes
                        .compactMap { $0 as? UIWindowScene }
                        .first?.windows.first?.safeAreaInsets.top ?? 54) + 6
                )

                // Top row
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(timeGreeting)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.75))
                            .opacity(heroAppeared ? 1 : 0)
                            .animation(.easeOut(duration: 0.4).delay(0.08), value: heroAppeared)

                        Text(user.name)
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .opacity(heroAppeared ? 1 : 0)
                            .offset(y: heroAppeared ? 0 : 12)
                            .animation(.spring(response: 0.55, dampingFraction: 0.78).delay(0.1), value: heroAppeared)
                    }
                    Spacer()
                    Button(action: {
                        MenuStateManager.shared.toggleMenu()
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "#1C42E8"), Color(hex: "#081754")],
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 50, height: 50)
                                .overlay(Circle().strokeBorder(.white.opacity(0.3), lineWidth: 1.5))
                            Text(String(user.name.prefix(1)).uppercased())
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.horizontal, 20)

                Spacer().frame(height: 14)

                // Live merchant count
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(hex: "#1C42E8"))
                        .frame(width: 7, height: 7)
                    let activeCount = merchantManager.merchants.filter { $0.isActive }.count
                    Text("\(activeCount) vendedores activos cerca")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.horizontal, 20)
                .opacity(heroAppeared ? 1 : 0)
                .offset(x: heroAppeared ? 0 : -16)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.17), value: heroAppeared)

                Spacer().frame(height: 16)

                // AI Search bar
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    showAIChat = true
                }) {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "#1C42E8").opacity(0.12))
                                .frame(width: 34, height: 34)
                            Image(systemName: "sparkles")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color(hex: "#1C42E8"))
                        }
                        Text(LocalizedString("home.whatDoYouCrave"))
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(Color(hex: "#4A4A4A"))
                        Spacer()
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(Color(hex: "#1C42E8"))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 13)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.1), radius: 14, x: 0, y: 5)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .opacity(heroAppeared ? 1 : 0)
                .offset(y: heroAppeared ? 0 : 22)
                .animation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.22), value: heroAppeared)

                Spacer().frame(height: 30)
            }
        }
        .frame(maxWidth: .infinity)
        .clipped()
    }

    private var timeGreeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        if h < 12 { return "Buenos días" }
        if h < 19 { return "Buenas tardes" }
        return "Buenas noches"
    }

    // MARK: - Atenea Insight (activado)

    private var ateneaInsightSection: some View {
        VStack(spacing: 10) {
            if let insight = contextEngine.currentInsight {
                Button(action: { handleInsightAction(insight.action) }) {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: insight.accentColor), Color(hex: insight.accentColor).opacity(0.55)],
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 54, height: 54)
                            Image(systemName: insight.icon)
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 5) {
                                Text("Atenea")
                                    .font(.system(size: 10, weight: .black, design: .rounded))
                                    .foregroundColor(Color(hex: insight.accentColor))
                                    .kerning(1.5)
                                    .textCase(.uppercase)
                                Circle()
                                    .fill(Color(hex: "#1C42E8"))
                                    .frame(width: 5, height: 5)
                                Text(LocalizedString("home.atenea.live"))
                                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                                    .foregroundColor(Color(hex: "#1C42E8"))
                            }
                            Text(insight.title)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(Color(hex: "#081754"))
                                .lineLimit(1)
                            Text(insight.subtitle)
                                .font(.system(size: 13, design: .rounded))
                                .foregroundColor(Color(hex: "#4A4A4A"))
                                .lineLimit(2)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(hex: insight.accentColor).opacity(0.6))
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(color: Color(hex: insight.accentColor).opacity(0.14), radius: 14, x: 0, y: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(Color(hex: insight.accentColor).opacity(0.2), lineWidth: 1.5)
                    )
                }
                .buttonStyle(PressButtonStyle())
                .id(insight.title)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .offset(x: 24)),
                    removal: .opacity.combined(with: .offset(x: -24))
                ))
            }

            // Smart chips
            if !contextEngine.chips.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(contextEngine.chips.enumerated()), id: \.element.id) { idx, chip in
                            Button(action: {
                                aiChatPrefill = chip.query
                                showAIChat = true
                            }) {
                                HStack(spacing: 6) {
                                    Text(chip.emoji).font(.system(size: 14))
                                    Text(chip.label)
                                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                                        .foregroundColor(Color(hex: "#081754"))
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 9)
                                .background(Color.white)
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .strokeBorder(Color(hex: "#E0DCD7"), lineWidth: 1)
                                )
                                .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
                            }
                            .buttonStyle(.plain)
                            .opacity(animateCards ? 1 : 0)
                            .offset(y: animateCards ? 0 : 10)
                            .animation(.spring(response: 0.45, dampingFraction: 0.8).delay(Double(idx) * 0.04 + 0.08), value: animateCards)
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }
        }
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 14)
        .animation(.spring(response: 0.5, dampingFraction: 0.85).delay(0.06), value: animateCards)
        .onReceive(Timer.publish(every: 6, on: .main, in: .common).autoconnect()) { _ in
            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                contextEngine.nextInsight()
            }
        }
    }

    private func handleInsightAction(_ action: ContextAction) {
        switch action {
        case .openMap:
            withAnimation { selectedTab = 1 }
        case .openChat(let prefill):
            aiChatPrefill = prefill
            showAIChat = true
        case .openMerchant(let name):
            if let merchant = merchantManager.merchants.first(where: { $0.businessName == name }) {
                selectedMerchantForTimbre = merchant
            } else {
                selectedTab = 1
            }
        case .openPrediction:
            selectedTab = 1
        }
    }

    // MARK: - Merchant Stories

    private var merchantStoriesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(LocalizedString("home.merchantsNearby"))
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "#081754"))
                    let onRoute = merchantsOnRoute.count
                    if onRoute > 0 {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color(hex: "#1C42E8"))
                                .frame(width: 6, height: 6)
                            Text("\(onRoute) en ruta ahora")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(Color(hex: "#1C42E8"))
                        }
                    }
                }
                Spacer()
                Button(action: { withAnimation { selectedTab = 1 } }) {
                    HStack(spacing: 3) {
                        Text("Ver todo")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(Color(hex: "#1C42E8"))
                }
            }

            // Category filter chips
            if !activeCategories.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        categoryChip(nil, label: LocalizedString("home.filter.all"), icon: "square.grid.2x2.fill")
                        ForEach(activeCategories, id: \.self) { cat in
                            categoryChip(cat, label: cat.displayName, emoji: cat.emoji)
                        }
                    }
                }
            }

            // Story bubbles
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 18) {
                    ForEach(Array(filteredMerchants.enumerated()), id: \.element.id) { idx, merchant in
                        Button(action: {
                            guard let loc = merchant.currentLocation else { return }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            pendingMerchantPlace = SearchPlace(
                                name: merchant.businessName,
                                subtitle: "\(merchant.category.displayName) · \(formatDistance(distanceToMerchant(merchant)))",
                                category: merchant.category.displayName,
                                icon: "mappin.circle.fill",
                                coordinate: loc.coordinate
                            )
                            selectedTab = 1
                        }) {
                            MerchantStoryBubble(
                                merchant: merchant,
                                distance: distanceToMerchant(merchant),
                                onTimbre: { selectedMerchantForTimbre = merchant }
                            )
                        }
                        .buttonStyle(.plain)
                        .opacity(animateCards ? 1 : 0)
                        .offset(y: animateCards ? 0 : 18)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.82).delay(Double(idx) * 0.06 + 0.08),
                            value: animateCards
                        )
                    }

                    if filteredMerchants.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 28))
                                .foregroundColor(Color(hex: "#4A4A4A").opacity(0.28))
                            Text("Sin vendedores activos")
                                .font(.system(size: 13, design: .rounded))
                                .foregroundColor(Color(hex: "#4A4A4A").opacity(0.45))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 4)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 4)
    }

    @ViewBuilder
    private func categoryChip(_ category: MerchantCategory?, label: String, icon: String? = nil, emoji: String? = nil) -> some View {
        let selected = selectedCategoryFilter == category
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) {
                selectedCategoryFilter = category
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon).font(.system(size: 10, weight: .semibold))
                } else if let emoji = emoji {
                    Text(emoji).font(.system(size: 11))
                }
                Text(label)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(selected ? Color(hex: "#1C42E8") : Color(hex: "#F0EEF8")))
            .foregroundColor(selected ? .white : Color(hex: "#4A4A4A"))
        }
        .buttonStyle(.plain)
        .scaleEffect(selected ? CGFloat(1.04) : CGFloat(1.0), anchor: .center)
        .animation(.spring(response: 0.26, dampingFraction: 0.7), value: selected)
    }

    // MARK: - Radar Compact

    private var radarCompactSection: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            showRadar = true
        }) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(radarService.isScanning
                              ? Color(hex: "#1C42E8").opacity(0.12)
                              : Color(hex: "#4A4A4A").opacity(0.08))
                        .frame(width: 50, height: 50)
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(radarService.isScanning ? Color(hex: "#1C42E8") : Color(hex: "#4A4A4A"))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(LocalizedString("home.detectMerchants"))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "#081754"))
                    if radarService.activeMerchantCount > 0 {
                        Text(String(format: LocalizedString("home.nearby"), radarService.activeMerchantCount))
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(Color(hex: "#1C42E8"))
                    } else {
                        Text(LocalizedString("home.searchingMerchants"))
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(Color(hex: "#4A4A4A"))
                    }
                }

                Spacer()

                // Peer emoji stack
                let peers = radarService.discoveredMerchants.filter { !$0.isStale }.prefix(3)
                if !peers.isEmpty {
                    HStack(spacing: -10) {
                        ForEach(peers) { peer in
                            Text(peer.emoji)
                                .font(.system(size: 17))
                                .frame(width: 30, height: 30)
                                .background(Circle().fill(Color(hex: "#F5F3F0")))
                                .overlay(Circle().strokeBorder(.white, lineWidth: 1.5))
                        }
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(hex: "#1C42E8").opacity(0.7))
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
        }
        .buttonStyle(PressButtonStyle())
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 14)
        .animation(.spring(response: 0.5, dampingFraction: 0.85).delay(0.14), value: animateCards)
    }

    // MARK: - 2×2 Actions Grid

    private var customerActionsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedString("home.quickActions"))
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: "#1C42E8"))
                .kerning(1.0)
                .textCase(.uppercase)

            let cols = [GridItem(.flexible()), GridItem(.flexible())]
            LazyVGrid(columns: cols, spacing: 10) {
                ActionGridButton(
                    icon: "camera.viewfinder",
                    label: LocalizedString("home.menuAR"),
                    color: Color(hex: "#1C42E8"),
                    bgColor: Color(hex: "#1C42E8").opacity(0.1)
                ) { showARStreetMenu = true }

                ActionGridButton(
                    icon: "wave.3.right",
                    label: LocalizedString("home.pay"),
                    color: Color(hex: "#1C42E8"),
                    bgColor: Color(hex: "#1C42E8").opacity(0.1)
                ) { showTapToPay = true }

                ActionGridButton(
                    icon: "waveform.and.mic",
                    label: LocalizedString("home.voiceTranslator"),
                    color: Color(hex: "#1C42E8"),
                    bgColor: Color(hex: "#1C42E8").opacity(0.1)
                ) { showVoiceTranslator = true }

                ActionGridButton(
                    icon: "bell.fill",
                    label: LocalizedString("home.timbre"),
                    color: Color(hex: "#F0D224"),
                    bgColor: Color(hex: "#F0D224").opacity(0.18)
                ) {
                    if let first = merchantManager.activeMerchants().first {
                        selectedMerchantForTimbre = first
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 4)
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 14)
        .animation(.spring(response: 0.5, dampingFraction: 0.85).delay(0.2), value: animateCards)
    }

    // MARK: - World Cup Card

    private var worldCupEventCard: some View {
        Button(action: {}) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#F0D224").opacity(0.16), Color(hex: "#1C42E8").opacity(0.14)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    Image(systemName: "soccerball")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(Color(hex: "#1C42E8"))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(LocalizedString("home.matchToday"))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "#081754"))
                    Text(LocalizedString("home.matchTodayDesc"))
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(Color(hex: "#4A4A4A"))
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(hex: "#1C42E8").opacity(0.7))
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
        }
        .buttonStyle(PressButtonStyle())
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 14)
        .animation(.spring(response: 0.5, dampingFraction: 0.85).delay(0.25), value: animateCards)
    }
}

// MARK: - Merchant Story Bubble

struct MerchantStoryBubble: View {
    let merchant: Merchant
    let distance: Double
    let onTimbre: () -> Void

    @State private var ringPulse = false

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .bottomTrailing) {
                // Animated ring for on-route merchants
                Circle()
                    .strokeBorder(
                        merchant.isOnRoute
                        ? Color(hex: "#1C42E8")
                        : (merchant.isCurrentlyOpen
                           ? Color(hex: "#1C42E8").opacity(0.35)
                           : Color(hex: "#E8E4DF")),
                        lineWidth: merchant.isOnRoute ? 2.5 : 1.5
                    )
                    .frame(width: 76, height: 76)
                    .scaleEffect(merchant.isOnRoute && ringPulse ? CGFloat(1.07) : CGFloat(1.0), anchor: .center)
                    .animation(
                        merchant.isOnRoute
                        ? .easeInOut(duration: 1.3).repeatForever(autoreverses: true)
                        : .default,
                        value: ringPulse
                    )

                // Emoji
                Text(merchant.emoji)
                    .font(.system(size: 36))
                    .frame(width: 68, height: 68)
                    .background(Circle().fill(Color(hex: "#F5F3F0")))

                // Status dot
                Circle()
                    .fill(merchant.isCurrentlyOpen ? Color(hex: "#1C42E8") : Color(hex: "#F0D224"))
                    .frame(width: 14, height: 14)
                    .overlay(Circle().strokeBorder(.white, lineWidth: 2))
                    .offset(x: 2, y: 2)
            }
            .onAppear { ringPulse = true }

            // Name
            Text(merchant.businessName)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: "#081754"))
                .lineLimit(1)
                .frame(width: 84)

            // Distance
            if distance < .infinity {
                Text(distance < 1000 ? "\(Int(distance))m" : String(format: "%.1fkm", distance / 1000))
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(merchant.isOnRoute ? Color(hex: "#1C42E8") : Color(hex: "#1C42E8"))
            }

            // Timbre CTA
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onTimbre()
            }) {
                HStack(spacing: 3) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 9, weight: .bold))
                    Text(LocalizedString("home.timbre"))
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                }
                .foregroundColor(Color(hex: "#F0D224"))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color(hex: "#F0D224").opacity(0.14)))
            }
            .buttonStyle(.plain)
        }
        .frame(width: 90)
    }
}

// MARK: - Action Grid Button

struct ActionGridButton: View {
    let icon: String
    let label: String
    let color: Color
    let bgColor: Color
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) { isPressed = true }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { isPressed = false }
                action()
            }
        }) {
            VStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(bgColor)
                        .frame(width: 54, height: 54)
                    Image(systemName: icon)
                        .font(.system(size: 23, weight: .semibold))
                        .foregroundColor(color)
                        .scaleEffect(isPressed ? CGFloat(1.18) : 1.0, anchor: .center)
                        .animation(.spring(response: 0.2, dampingFraction: 0.5), value: isPressed)
                }
                Text(label)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: "#081754"))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(hex: "#FAFAF9"))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(color.opacity(isPressed ? 0.38 : 0.14), lineWidth: 1.5)
            )
            .scaleEffect(isPressed ? CGFloat(0.93) : 1.0, anchor: .center)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.26, dampingFraction: 0.7), value: isPressed)
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
            ZStack {
                Circle()
                    .fill(color.opacity(0.14))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(color)
            }
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: "#081754"))
            Text(label)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(Color(hex: "#4A4A4A"))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(color.opacity(0.07))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(color.opacity(0.35), lineWidth: 1.5)
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

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) { isPressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) { isPressed = false }
            }
            action()
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
                    .frame(width: 48, height: 48)
                    .background(color.opacity(0.14))
                    .cornerRadius(14)

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
                    .foregroundColor(color.opacity(0.7))
            }
            .padding(14)
            .background(Color.white)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(color.opacity(isPressed ? 0.5 : 0.3), lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .modifier(ScaleModifier(scale: isPressed ? 0.97 : 1.0))
        .modifier(OpacityModifier(opacity: isPressed ? 0.85 : 1.0))
    }
}

// MARK: - On Route Card (kept for compatibility)

struct OnRouteCard: View {
    let merchant: Merchant
    let distance: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(merchant.emoji).font(.system(size: 26))
                Spacer()
                Circle()
                    .fill(Color(hex: "#1C42E8"))
                    .frame(width: 8, height: 8)
            }

            Text(merchant.businessName)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(Color(hex: "#081754"))
                .lineLimit(1)

            HStack(spacing: 4) {
                Text(merchant.category.displayName)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundColor(Color(hex: "#4A4A4A"))
                if distance < .infinity {
                    Text("·").foregroundColor(Color(hex: "#4A4A4A"))
                    Text(formatDist(distance))
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(Color(hex: "#1C42E8"))
                }
            }

            if let stop = merchant.route?.sortedWaypoints.first?.name {
                HStack(spacing: 3) {
                    Image(systemName: "mappin.circle.fill").font(.system(size: 9))
                    Text(stop).font(.system(size: 10, design: .rounded)).lineLimit(1)
                }
                .foregroundColor(Color(hex: "#4A4A4A"))
            }

            let stops = merchant.route?.waypoints.count ?? 0
            HStack(spacing: 4) {
                Image(systemName: "figure.walk").font(.system(size: 10))
                Text(stops > 0 ? "En Ruta · \(stops) paradas" : "En Ruta")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
            }
            .foregroundColor(Color(hex: "#1C42E8"))
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(Capsule().fill(Color(hex: "#1C42E8").opacity(0.12)))
        }
        .padding(10)
        .frame(width: 155, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color(hex: "#1C42E8").opacity(0.35), lineWidth: 1.5)
                )
        )
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
    }

    private func formatDist(_ meters: Double) -> String {
        meters < 1000 ? "\(Int(meters))m" : String(format: "%.1fkm", meters / 1000)
    }
}

// MARK: - Home Merchant Card (kept for compatibility)

struct HomeMerchantCard: View {
    let merchant: Merchant
    let distance: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(merchant.emoji).font(.system(size: 26))
                Spacer()
                if merchant.trustLevel.isGreen {
                    Image(systemName: merchant.trustLevel.icon)
                        .font(.system(size: 14))
                        .foregroundColor(.green)
                }
                Circle()
                    .fill(merchant.isCurrentlyOpen ? Color(hex: "#1C42E8") : Color(hex: "#F0D224"))
                    .frame(width: 8, height: 8)
            }

            Text(merchant.businessName)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(Color(hex: "#081754"))
                .lineLimit(1)

            HStack(spacing: 4) {
                Text(merchant.category.displayName)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundColor(Color(hex: "#4A4A4A"))
                if distance < .infinity {
                    Text("·").foregroundColor(Color(hex: "#4A4A4A"))
                    Text(formatDist(distance))
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(Color(hex: "#1C42E8"))
                }
            }

            HStack(spacing: 4) {
                Image(systemName: merchant.isStatic ? "mappin.circle.fill" : "figure.walk")
                    .font(.system(size: 10))
                Text(merchant.isStatic ? LocalizedString("home.fixed") : LocalizedString("home.nomad"))
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
            }
            .foregroundColor(merchant.isStatic ? Color(hex: "#1C42E8") : Color(hex: "#F0D224"))
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(
                Capsule().fill(merchant.isStatic
                    ? Color(hex: "#1C42E8").opacity(0.12)
                    : Color(hex: "#F0D224").opacity(0.12))
            )
        }
        .padding(10)
        .frame(width: 140, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(
                            merchant.trustLevel.isGreen ? Color.green.opacity(0.4) : Color(hex: "#E8E4DF"),
                            lineWidth: merchant.trustLevel.isGreen ? 1.5 : 0.5
                        )
                )
        )
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
    }

    private func formatDist(_ meters: Double) -> String {
        meters < 1000 ? "\(Int(meters))m" : String(format: "%.1fkm", meters / 1000)
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
                    .fill(isActive ? Color(hex: "#1C42E8") : Color(hex: "#4A4A4A"))
                    .frame(width: 10, height: 10)
                    .overlay(Circle().strokeBorder(Color.white, lineWidth: 1.5))
            }
            Text(name)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(Color(hex: "#081754"))
            Text(distance)
                .font(.system(size: 11, weight: .regular, design: .rounded))
                .foregroundColor(Color(hex: "#4A4A4A"))
            Text(isStatic ? LocalizedString("home.fixed") : LocalizedString("home.nomad"))
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundColor(isStatic ? Color(hex: "#1C42E8") : Color(hex: "#F0D224"))
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(Capsule().fill(isStatic
                    ? Color(hex: "#1C42E8").opacity(0.12)
                    : Color(hex: "#F0D224").opacity(0.12)))
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
            withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) { isPressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) { isPressed = false }
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
                        .overlay(Circle().stroke(signalColor.opacity(isPressed ? 0.6 : 0.4), lineWidth: 1.5))
                    Circle()
                        .fill(signalColor)
                        .frame(width: 10, height: 10)
                        .overlay(Circle().strokeBorder(Color.white, lineWidth: 1.5))
                }
                Text(name)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: "#081754"))
                    .lineLimit(1)
                Text(LocalizedString("home.live"))
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: "#1C42E8"))
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Color(hex: "#1C42E8").opacity(0.12))
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

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) { isPressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) { isPressed = false }
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
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(isPressed ? 0.4 : 0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .modifier(ScaleModifier(scale: isPressed ? 0.96 : 1.0))
    }
}

// MARK: - Utility Styles & Modifiers

struct PressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? CGFloat(0.97) : CGFloat(1.0), anchor: .center)
            .opacity(configuration.isPressed ? 0.88 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct ScaleModifier: ViewModifier {
    let scale: CGFloat
    func body(content: Content) -> some View {
        content.scaleEffect(scale, anchor: .center)
    }
}

struct OpacityModifier: ViewModifier {
    let opacity: Double
    func body(content: Content) -> some View {
        content.opacity(opacity)
    }
}
