//
//  MerchantRegistrationView.swift
//  Atenea
//
//  Merchant business registration form
//

import SwiftUI

struct MerchantRegistrationView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var languageManager: LanguageManager
    @ObservedObject var userManager = UserManager.shared
    @Binding var isLoggedIn: Bool
    let userInfo: UserRegistrationInfo

    // Form state
    @State private var hasCoppelAccount = false
    @State private var businessName = ""
    @State private var businessLocation: BusinessLocation?
    @State private var routeWaypoints: [RouteWaypoint]?
    @State private var selectedBusinessType: BusinessType = .food
    @State private var selectedBusinessSize: BusinessSize = .individual
    @State private var selectedMobility: BusinessMobility = .mobile

    // UI state
    @State private var showBusinessTypePicker = false
    @State private var showBusinessSizePicker = false
    @State private var showLocationMap = false
    @State private var isCalculatingRoute = false
    @State private var showCoppelModal = false
    @State private var coppelEmail = ""
    @State private var coppelName = ""

    private var canContinue: Bool {
        let hasName = !businessName.isEmpty
        let hasLocation: Bool

        if selectedMobility == .mobile {
            // Mobile business needs route waypoints
            hasLocation = routeWaypoints != nil && routeWaypoints!.count >= 2
        } else {
            // Fixed business needs single location
            hasLocation = businessLocation != nil
        }

        return hasName && hasLocation
    }

    var body: some View {
        ZStack {
            backgroundGradient

            VStack(spacing: 0) {
                progressBar
                    .padding(.top, 8)
                scrollableContent
            }
            .safeAreaInset(edge: .top) {
                Color.clear.frame(height: 0)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Atrás")
                            .font(.system(size: 17, weight: .regular))
                    }
                    .foregroundStyle(Color.white)
                }
            }
        }
        .sheet(isPresented: $showCoppelModal) {
            coppelModal
        }
        .sheet(isPresented: $showLocationMap) {
            NavigationStack {
                BusinessLocationMapView(
                    selectedLocation: $businessLocation,
                    isMobileBusinesse: selectedMobility == .mobile,
                    routeWaypoints: $routeWaypoints
                )
            }
        }
        .overlay {
            if isCalculatingRoute {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()

                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(CGFloat(1.5))
                            .tint(.white)

                        Text("Calculando ruta...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white)
                    }
                    .padding(32)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(.ultraThinMaterial)
                    )
                }
            }
        }
    }

    // MARK: - View Components

    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.112, green: 0.259, blue: 0.906),
                Color(red: 0.112, green: 0.259, blue: 0.906).opacity(0.85)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var progressBar: some View {
        VStack(alignment: .center, spacing: 12) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color.white.opacity(0.25))

                    // Progress fill (100% for step 2 of 2)
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 1.0, green: 0.824, blue: 0.141),
                                    Color(red: 1.0, green: 0.549, blue: 0.306)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width)
                }
                .frame(height: 6)
            }
            .frame(height: 6)

            Text("Paso 2 de 2")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.85))
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 24)
    }

    private var scrollableContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                headerSection
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 28)

                VStack(alignment: .leading, spacing: 28) {
                    coppelAccountSection
                    businessFormSection
                    mobilitySection
                    continueButton
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
                .background(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Color.white)
                )
            }
            .padding(.bottom, 40)
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Configura tu negocio")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white)
                .fixedSize(horizontal: false, vertical: true)

            Text("Completa la información de tu emprendimiento para que los clientes puedan encontrarte fácilmente")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(4)
        }
    }

    private var coppelAccountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Integración opcional")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(red: 0.051, green: 0.094, blue: 0.329).opacity(0.6))
                .textCase(.uppercase)
                .kerning(0.5)

            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    if !hasCoppelAccount {
                        showCoppelModal = true
                    } else {
                        hasCoppelAccount = false
                        businessName = ""
                        coppelEmail = ""
                        coppelName = ""
                    }
                }
            }) {
                HStack(spacing: 16) {
                    Image(systemName: hasCoppelAccount ? "checkmark.square.fill" : "square")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(hasCoppelAccount ? Color(red: 1.0, green: 0.824, blue: 0.141) : Color(red: 0.051, green: 0.094, blue: 0.329).opacity(0.3))

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Ya tengo cuenta Coppel Emprende")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color(red: 0.051, green: 0.094, blue: 0.329))
                            .fixedSize(horizontal: false, vertical: true)

                        Text("Vincula tu cuenta para importar tu catálogo de productos")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(Color(red: 0.051, green: 0.094, blue: 0.329).opacity(0.65))
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(2)
                    }

                    Spacer()
                }
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(hasCoppelAccount ? Color(red: 1.0, green: 0.824, blue: 0.141).opacity(0.1) : Color(red: 0.95, green: 0.97, blue: 1.0))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(hasCoppelAccount ? Color(red: 1.0, green: 0.824, blue: 0.141).opacity(0.4) : Color(red: 0.051, green: 0.094, blue: 0.329).opacity(0.1), lineWidth: 1.5)
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var businessFormSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Business Name
            formField(
                label: "Nombre del negocio",
                placeholder: "Ej: Tacos Don José",
                text: $businessName,
                icon: "bag.fill"
            )

            // Business Location Button
            businessLocationButton

            // Business Type Picker
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Text("Giro del negocio")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)

                    Image(systemName: "info.circle")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary.opacity(0.6))
                }

                Text("¿Qué vendes o qué servicio ofreces?")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary.opacity(0.8))
                    .padding(.bottom, 4)

                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showBusinessTypePicker.toggle()
                        showBusinessSizePicker = false
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: selectedBusinessType.icon)
                            .font(.system(size: 18))
                            .foregroundStyle(.purple)

                        Text(selectedBusinessType.displayName)
                            .font(.system(size: 16))
                            .foregroundStyle(.primary)

                        Spacer()

                        Image(systemName: showBusinessTypePicker ? "chevron.up" : "chevron.down")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                    )
                }

                if showBusinessTypePicker {
                    Picker("", selection: $selectedBusinessType) {
                        ForEach(BusinessType.allCases) { type in
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.displayName)
                            }
                            .tag(type)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 150)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(.ultraThinMaterial)
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
                }
            }

            // Business Size Picker
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Text("Tamaño del negocio")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)

                    Image(systemName: "info.circle")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary.opacity(0.6))
                }

                Text("¿Cuántas personas trabajan en tu negocio?")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary.opacity(0.8))
                    .padding(.bottom, 4)

                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showBusinessSizePicker.toggle()
                        showBusinessTypePicker = false
                    }
                }) {
                    HStack {
                        Text(selectedBusinessSize.displayName)
                            .font(.system(size: 16))
                            .foregroundStyle(.primary)

                        Spacer()

                        Image(systemName: showBusinessSizePicker ? "chevron.up" : "chevron.down")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                    )
                }

                if showBusinessSizePicker {
                    Picker("", selection: $selectedBusinessSize) {
                        ForEach(BusinessSize.allCases) { size in
                            Text(size.displayName).tag(size)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 150)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(.ultraThinMaterial)
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
                }
            }

            // Contact info display (pre-filled from step 1)
            VStack(alignment: .leading, spacing: 12) {
                Text("Información de contacto")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .kerning(0.5)

                VStack(spacing: 8) {
                    contactInfoRow(icon: "envelope.fill", text: userInfo.email)
                    contactInfoRow(icon: "phone.fill", text: userInfo.phoneNumber)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.purple.opacity(0.05))
                )
            }
        }
    }

    private var mobilitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Tipo de negocio")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .kerning(0.5)

                Text("Los negocios ambulantes podrán actualizar su ubicación en tiempo real")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 12) {
                // Fixed Button
                MobilityButton(
                    title: "Estático",
                    icon: "building.2.fill",
                    isSelected: selectedMobility == .fixed,
                    action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedMobility = .fixed
                        }
                    }
                )

                // Mobile Button
                MobilityButton(
                    title: "Ambulante",
                    icon: "figure.walk",
                    isSelected: selectedMobility == .mobile,
                    action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedMobility = .mobile
                        }
                    }
                )
            }
        }
    }

    private var continueButton: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            handleMerchantRegistration()
        }) {
            HStack(spacing: 8) {
                Text("Completar registro")
                    .font(.system(size: 17, weight: .semibold))

                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Group {
                    if canContinue {
                        LinearGradient(
                            gradient: Gradient(colors: [.purple, .pink]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    } else {
                        LinearGradient(
                            gradient: Gradient(colors: [.gray, .gray]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .opacity(0.5)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(
                color: canContinue ? Color.purple.opacity(0.4) : Color.clear,
                radius: 12,
                x: 0,
                y: 6
            )
        }
        .disabled(!canContinue)
        .buttonStyle(ScaleButtonStyle())
        .padding(.top, 8)
    }

    // MARK: - Helper Views

    private var businessLocationButton: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(selectedMobility == .mobile ? "Ruta del recorrido" : "Ubicación del negocio")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)

            Button(action: {
                showLocationMap = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: hasLocationOrRoute ? "mappin.circle.fill" : "mappin.circle")
                        .font(.system(size: 20))
                        .foregroundStyle(hasLocationOrRoute ? .purple : .secondary)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(locationButtonTitle)
                            .font(.system(size: 16, weight: hasLocationOrRoute ? .semibold : .regular))
                            .foregroundStyle(hasLocationOrRoute ? .primary : .secondary)

                        Text(locationButtonSubtitle)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(hasLocationOrRoute ? Color.purple.opacity(0.05) : Color.white)
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(hasLocationOrRoute ? Color.purple.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: 1.5)
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var hasLocationOrRoute: Bool {
        if selectedMobility == .mobile {
            return routeWaypoints != nil && routeWaypoints!.count >= 2
        } else {
            return businessLocation != nil
        }
    }

    private var locationButtonTitle: String {
        if selectedMobility == .mobile {
            return routeWaypoints != nil ? "Ruta configurada" : "Configurar ruta"
        } else {
            return businessLocation != nil ? "Ubicación configurada" : "Configurar en mapa"
        }
    }

    private var locationButtonSubtitle: String {
        if selectedMobility == .mobile {
            if let waypoints = routeWaypoints {
                return "\(waypoints.count) puntos marcados"
            } else {
                return "Marca los puntos de tu recorrido"
            }
        } else {
            if let location = businessLocation {
                return location.address
            } else {
                return "Toca para abrir el mapa"
            }
        }
    }

    private func formField(
        label: String,
        placeholder: String,
        text: Binding<String>,
        icon: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(.purple.opacity(0.7))

                TextField(placeholder, text: text)
                    .font(.system(size: 16))
                    .foregroundStyle(.primary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(text.wrappedValue.isEmpty ? Color.clear : Color.purple.opacity(0.3), lineWidth: 1.5)
            )
            .onTapGesture {
                closeAllPickers()
            }
        }
    }

    private func contactInfoRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(.purple.opacity(0.7))
                .frame(width: 24)

            Text(text)
                .font(.system(size: 15))
                .foregroundStyle(.secondary)

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(.green)
        }
    }

    // MARK: - Helper Functions

    private func closeAllPickers() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showBusinessTypePicker = false
            showBusinessSizePicker = false
        }
    }

    private func handleCoppelLinking() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if !coppelEmail.isEmpty && !coppelName.isEmpty {
                hasCoppelAccount = true
                businessName = "Tienda " + coppelName
                showCoppelModal = false
            }
        }
    }

    private func closeCoppelModal() {
        showCoppelModal = false
        coppelEmail = ""
        coppelName = ""
    }

    private func handleMerchantRegistration() {
        // Create merchant user
        let newUser = User(
            email: userInfo.email,
            name: userInfo.fullName,
            role: .merchant,
            accessibilityOption: userInfo.accessibilityOption,
            age: userInfo.age,
            country: userInfo.country,
            phoneNumber: userInfo.phoneNumber
        )

        // Calculate and save route if mobile business
        if selectedMobility == .mobile, let waypoints = routeWaypoints {
            isCalculatingRoute = true

            MapboxRoutingService.shared.calculateRoute(waypoints: waypoints, profile: .walking) { result in
                DispatchQueue.main.async {
                    isCalculatingRoute = false

                    switch result {
                    case .success(let response):
                        guard let route = response.routes.first else { return }

                        // Create merchant route with calculated data
                        let merchantRoute = MerchantRoute(
                            merchantId: newUser.id,
                            waypoints: waypoints,
                            routeGeometry: nil, // Store if needed
                            estimatedDuration: route.duration,
                            estimatedDistance: route.distance,
                            isActive: true
                        )

                        // Create business with route
                        let business = BusinessModel(
                            ownerId: newUser.id,
                            name: businessName,
                            address: "Negocio ambulante",
                            businessType: selectedBusinessType,
                            businessSize: selectedBusinessSize,
                            mobility: selectedMobility,
                            hasCoppelAccount: false,
                            route: merchantRoute
                        )

                        completeMerchantRegistration(user: newUser, business: business)

                    case .failure(let error):
                        print("❌ Error calculando ruta: \(error.localizedDescription)")

                        // Save anyway without route optimization
                        let merchantRoute = MerchantRoute(
                            merchantId: newUser.id,
                            waypoints: waypoints,
                            isActive: true
                        )

                        let business = BusinessModel(
                            ownerId: newUser.id,
                            name: businessName,
                            address: "Negocio ambulante",
                            businessType: selectedBusinessType,
                            businessSize: selectedBusinessSize,
                            mobility: selectedMobility,
                            hasCoppelAccount: false,
                            route: merchantRoute
                        )

                        completeMerchantRegistration(user: newUser, business: business)
                    }
                }
            }
        } else {
            // Fixed business or Coppel account
            let business = hasCoppelAccount
                ? BusinessModel.coppelEmprendeDefault(ownerId: newUser.id)
                : BusinessModel(
                    ownerId: newUser.id,
                    name: businessName,
                    address: businessLocation?.address ?? "Sin dirección",
                    businessType: selectedBusinessType,
                    businessSize: selectedBusinessSize,
                    mobility: selectedMobility,
                    hasCoppelAccount: false
                )

            completeMerchantRegistration(user: newUser, business: business)
        }
    }

    private func completeMerchantRegistration(user: User, business: BusinessModel) {
        // Save user
        userManager.currentUser = user

        // Save business (you would typically save this to a BusinessManager)
        print("📦 Negocio registrado: \(business.name)")
        print("   Tipo: \(business.businessType.displayName)")
        print("   Tamaño: \(business.businessSize.displayName)")
        print("   Movilidad: \(business.mobility.displayName)")
        print("   Coppel: \(business.hasCoppelAccount ? "Sí" : "No")")

        if let route = business.route {
            print("   📍 Ruta: \(route.waypoints.count) puntos")
            if let duration = route.estimatedDuration {
                print("   ⏱️ Duración estimada: \(Int(duration / 60)) minutos")
            }
            if let distance = route.estimatedDistance {
                print("   📏 Distancia estimada: \(Int(distance)) metros")
            }
        }

        // Announce if needed
        if user.hasVisualDisability {
            let accessibilityManager = AccessibilitySettingsManager.shared
            accessibilityManager.announce("Bienvenido a Atenea, \(user.name). Tu negocio ha sido registrado exitosamente.")
            accessibilityManager.provideHapticFeedback(.success)
        }

        // Log in
        withAnimation {
            isLoggedIn = true
        }
    }

    // MARK: - Coppel Modal

    private var coppelModal: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.95, green: 0.97, blue: 1.0)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Vincula Coppel Emprende")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(red: 0.051, green: 0.094, blue: 0.329))

                        Text("Ingresa los datos de tu cuenta para importar tu catálogo")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(Color(red: 0.051, green: 0.094, blue: 0.329).opacity(0.65))
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(3)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(24)

                    ScrollView {
                        VStack(spacing: 20) {
                            // Email field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Correo Coppel Emprende")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Color(red: 0.051, green: 0.094, blue: 0.329))

                                HStack(spacing: 12) {
                                    Image(systemName: "envelope.fill")
                                        .font(.system(size: 18))
                                        .foregroundStyle(Color(red: 0.112, green: 0.259, blue: 0.906))

                                    TextField("juan@coppelemp.com", text: $coppelEmail)
                                        .font(.system(size: 16, design: .rounded))
                                        .keyboardType(.emailAddress)
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(Color.white)
                                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                                )
                            }

                            // Name field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Nombre del propietario")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Color(red: 0.051, green: 0.094, blue: 0.329))

                                HStack(spacing: 12) {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 18))
                                        .foregroundStyle(Color(red: 0.112, green: 0.259, blue: 0.906))

                                    TextField("Juan Pérez García", text: $coppelName)
                                        .font(.system(size: 16, design: .rounded))
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(Color.white)
                                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                                )
                            }

                            // Info box
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 12) {
                                    Image(systemName: "info.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundStyle(Color(red: 0.112, green: 0.659, blue: 0.957))

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Tu catálogo será importado automáticamente")
                                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                                            .foregroundStyle(Color(red: 0.051, green: 0.094, blue: 0.329))

                                        Text("Podrás modificar tu información en cualquier momento")
                                            .font(.system(size: 13, weight: .medium, design: .rounded))
                                            .foregroundStyle(Color(red: 0.051, green: 0.094, blue: 0.329).opacity(0.7))
                                    }
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(Color(red: 0.112, green: 0.659, blue: 0.957).opacity(0.1))
                                )
                            }

                            Spacer()
                        }
                        .padding(24)
                    }

                    // Action buttons
                    VStack(spacing: 12) {
                        Button(action: { handleCoppelLinking() }) {
                            HStack(spacing: 8) {
                                Text("Vincular cuenta")
                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(
                                        coppelEmail.isEmpty || coppelName.isEmpty
                                            ? AnyShapeStyle(Color.gray.opacity(0.4))
                                            : AnyShapeStyle(LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color(red: 1.0, green: 0.824, blue: 0.141),
                                                    Color(red: 1.0, green: 0.549, blue: 0.306)
                                                ]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            ))
                                    )
                            )
                        }
                        .disabled(coppelEmail.isEmpty || coppelName.isEmpty)

                        Button(action: { closeCoppelModal() }) {
                            Text("Cancelar")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color(red: 0.051, green: 0.094, blue: 0.329))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(Color.white)
                                        .stroke(Color(red: 0.051, green: 0.094, blue: 0.329).opacity(0.2), lineWidth: 1.5)
                                )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 24)
                    .safeAreaInset(edge: .bottom) {
                        Color.clear.frame(height: 0)
                    }
                }
                .ignoresSafeArea(.container, edges: .bottom)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { closeCoppelModal() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color(red: 0.051, green: 0.094, blue: 0.329))
                    }
                }
            }
        }
    }
}

// MARK: - Mobility Button Component

struct MobilityButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(isSelected ? .white : .purple)

                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        isSelected
                            ? LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [.white, .white],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                    .shadow(
                        color: isSelected ? Color.purple.opacity(0.3) : Color.black.opacity(0.05),
                        radius: isSelected ? 12 : 6,
                        x: 0,
                        y: isSelected ? 6 : 2
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? Color.clear : Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MerchantRegistrationView(
            isLoggedIn: .constant(false),
            userInfo: UserRegistrationInfo(
                fullName: "Juan Pérez",
                age: "25",
                country: "Mexico",
                email: "juan@example.com",
                phoneNumber: "+52 55 1234 5678",
                accessibilityOption: .none
            )
        )
        .environmentObject(LanguageManager.shared)
    }
}
