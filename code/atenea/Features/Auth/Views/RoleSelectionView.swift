//
//  RoleSelectionView.swift
//  Atenea
//
//  Role selection view after registration
//

import SwiftUI
import CoreLocation

struct RoleSelectionView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @ObservedObject var userManager = UserManager.shared
    @Binding var isLoggedIn: Bool
    let userInfo: UserRegistrationInfo

    @State private var showMerchantRegistration = false
    @State private var showIdentityVerificationDialog = false
    @StateObject private var locationManager = LocationManager()

    var body: some View {
        ZStack {
            backgroundGradient

            VStack(spacing: 0) {
                progressBar
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 24)

                headerSection
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)

                roleCardsSection
                    .padding(.horizontal, 24)

                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $showMerchantRegistration) {
            MerchantRegistrationView(
                isLoggedIn: $isLoggedIn,
                userInfo: userInfo
            )
            .environmentObject(languageManager)
        }
        .alert("Verificación de identidad", isPresented: $showIdentityVerificationDialog) {
            Button("Verificar ahora", role: .none) {
                // TODO: Implement identity verification flow
                completeUserRegistration()
            }
            Button("Más tarde", role: .cancel) {
                completeUserRegistration()
            }
        } message: {
            Text("Para acceder a todas las funciones de Atenea, te recomendamos verificar tu identidad. ¿Deseas hacerlo ahora?")
        }
    }

    // MARK: - View Components

    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.coppelBlue,
                Color.coppelBlue.opacity(0.85)
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

                    // Progress fill (50% for step 1 of 2)
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
                        .frame(width: geometry.size.width * 0.5)
                }
                .frame(height: 6)
            }
            .frame(height: 6)

            Text("Paso 1 de 2")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.85))
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("¿Cómo quieres usar Atenea?")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white)
                .fixedSize(horizontal: false, vertical: true)

            Text("Elige el perfil que mejor describa cómo planeas usar la aplicación. Podrás cambiar esto después en tu configuración.")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var roleCardsSection: some View {
        VStack(spacing: 20) {
            // User Role Card
            RoleCard(
                title: "Soy cliente",
                description: "Quiero descubrir y encontrar comerciantes cerca de mí durante el Mundial.",
                features: ["Navega con AR", "Recomendaciones IA", "Mensajes directos"],
                icon: "person.crop.circle.fill",
                accentColor: Color(red: 1.0, green: 0.824, blue: 0.141),
                action: { handleUserRoleSelection() }
            )

            // Merchant Role Card
            RoleCard(
                title: "Soy comerciante",
                description: "Quiero dar a conocer mi negocio y atraer más clientes.",
                features: ["Ubicación en tiempo real", "Gestión de productos", "Zona de demanda"],
                icon: "briefcase.fill",
                accentColor: Color(red: 0.112, green: 0.659, blue: 0.957),
                action: { handleMerchantRoleSelection() }
            )
        }
    }

    // MARK: - Actions

    private func handleUserRoleSelection() {
        // Show identity verification dialog
        showIdentityVerificationDialog = true
    }

    private func completeUserRegistration() {
        // Request location permission
        locationManager.requestLocationPermission()

        // Get current location
        let currentLocation: UserLocation?
        if let location = locationManager.currentLocation {
            currentLocation = UserLocation(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                timestamp: Date(),
                address: nil
            )
        } else {
            currentLocation = nil
        }

        // Create user with user role
        var newUser = User(
            email: userInfo.email,
            name: userInfo.fullName,
            role: .user,
            accessibilityOption: userInfo.accessibilityOption,
            age: userInfo.age,
            country: userInfo.country,
            phoneNumber: userInfo.phoneNumber,
            currentLocation: currentLocation,
            routeHistory: currentLocation != nil ? [currentLocation!] : []
        )

        // Save user
        userManager.currentUser = newUser

        // Announce if needed
        if newUser.hasVisualDisability {
            let accessibilityManager = AccessibilitySettingsManager.shared
            accessibilityManager.announce("Bienvenido a Atenea, \(newUser.name). Tu perfil de accesibilidad ha sido configurado.")
            accessibilityManager.provideHapticFeedback(.success)
        }

        // Log in
        withAnimation {
            isLoggedIn = true
        }
    }

    private func handleMerchantRoleSelection() {
        // Navigate to merchant registration
        showMerchantRegistration = true
    }
}

// MARK: - Role Card Component

struct RoleCard: View {
    let title: String
    let description: String
    let features: [String]
    let icon: String
    let accentColor: Color
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(role: .none, action: {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                action()
            }
        }) {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .top, spacing: 16) {
                    Image(systemName: icon)
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(accentColor)
                        .frame(width: 64, height: 64)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(accentColor.opacity(0.12))
                        )

                    VStack(alignment: .leading, spacing: 8) {
                        Text(title)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(red: 0.051, green: 0.094, blue: 0.329))
                            .fixedSize(horizontal: false, vertical: true)

                        Text(description)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(Color(red: 0.051, green: 0.094, blue: 0.329).opacity(0.65))
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Features list
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(features, id: \.self) { feature in
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(accentColor)

                            Text(feature)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(Color(red: 0.051, green: 0.094, blue: 0.329).opacity(0.75))
                        }
                    }
                }

                // Action indicator
                HStack {
                    Spacer()
                    HStack(spacing: 6) {
                        Text("Seleccionar")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(accentColor)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(accentColor)
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white)
            )
            .shadow(color: Color(red: 0.051, green: 0.094, blue: 0.329).opacity(0.12), radius: 12, x: 0, y: 6)
            .scaleEffect(CGSize(width: isPressed ? 0.97 : 1.0, height: isPressed ? 0.97 : 1.0))
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                        isPressed = false
                    }
                }
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        RoleSelectionView(
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

