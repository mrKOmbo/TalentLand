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
    @State private var selectedBusinessType: BusinessType = .food
    @State private var selectedBusinessSize: BusinessSize = .individual
    @State private var selectedMobility: BusinessMobility = .mobile

    // UI state
    @State private var showBusinessTypePicker = false
    @State private var showBusinessSizePicker = false
    @State private var showLocationMap = false

    private var canContinue: Bool {
        if hasCoppelAccount {
            return true
        } else {
            return !businessName.isEmpty && businessLocation != nil
        }
    }

    var body: some View {
        ZStack {
            backgroundGradient

            VStack(spacing: 0) {
                progressBar
                scrollableContent
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
                    .foregroundStyle(.blue)
                }
            }
        }
        .sheet(isPresented: $showLocationMap) {
            NavigationStack {
                BusinessLocationMapView(selectedLocation: $businessLocation)
            }
        }
    }

    // MARK: - View Components

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.95, green: 0.97, blue: 1.0),
                Color.white
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var progressBar: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Text("Paso 2")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                Text("de")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.secondary.opacity(0.7))
                Text("2")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 6)

                    // Progress fill
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * 1.0, height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }

    private var scrollableContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                headerSection
                coppelAccountSection

                if !hasCoppelAccount {
                    businessFormSection
                }

                mobilitySection
                continueButton
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Configura tu negocio")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Text("Completa la información de tu emprendimiento para que los clientes puedan encontrarte fácilmente")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(4)
        }
    }

    private var coppelAccountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Integración opcional")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .kerning(0.5)

            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    hasCoppelAccount.toggle()

                    // Auto-fill if Coppel account
                    if hasCoppelAccount {
                        businessName = "Mi Negocio Coppel"
                    } else {
                        businessName = ""
                    }
                }
            }) {
                HStack(spacing: 16) {
                    Image(systemName: hasCoppelAccount ? "checkmark.square.fill" : "square")
                        .font(.system(size: 26))
                        .foregroundStyle(hasCoppelAccount ? .purple : .secondary)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Ya tengo cuenta Coppel Emprende")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("Vincula tu cuenta para importar tu catálogo de productos")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(2)
                    }

                    Spacer()
                }
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(hasCoppelAccount ? Color.purple.opacity(0.1) : Color.white)
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(hasCoppelAccount ? Color.purple.opacity(0.4) : Color.clear, lineWidth: 2)
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
            Text("Ubicación del negocio")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)

            Button(action: {
                showLocationMap = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: businessLocation != nil ? "mappin.circle.fill" : "mappin.circle")
                        .font(.system(size: 20))
                        .foregroundStyle(businessLocation != nil ? .purple : .secondary)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(businessLocation != nil ? "Ubicación configurada" : "Configurar en mapa")
                            .font(.system(size: 16, weight: businessLocation != nil ? .semibold : .regular))
                            .foregroundStyle(businessLocation != nil ? .primary : .secondary)

                        if let location = businessLocation {
                            Text(location.address)
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        } else {
                            Text("Toca para abrir el mapa")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(businessLocation != nil ? Color.purple.opacity(0.05) : Color.white)
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(businessLocation != nil ? Color.purple.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: 1.5)
                )
            }
            .buttonStyle(.plain)
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

        // Create business
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

        // Save user
        userManager.currentUser = newUser

        // Save business (you would typically save this to a BusinessManager)
        print("📦 Negocio registrado: \(business.name)")
        print("   Tipo: \(business.businessType.displayName)")
        print("   Tamaño: \(business.businessSize.displayName)")
        print("   Movilidad: \(business.mobility.displayName)")
        print("   Coppel: \(business.hasCoppelAccount ? "Sí" : "No")")

        // Announce if needed
        if newUser.hasVisualDisability {
            let accessibilityManager = AccessibilitySettingsManager.shared
            accessibilityManager.announce("Bienvenido a Atenea, \(newUser.name). Tu negocio ha sido registrado exitosamente.")
            accessibilityManager.provideHapticFeedback(.success)
        }

        // Log in
        withAnimation {
            isLoggedIn = true
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
