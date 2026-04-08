//
//  RoleSelectionView.swift
//  Atenea
//
//  Role selection view after registration
//

import SwiftUI

struct RoleSelectionView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @ObservedObject var userManager = UserManager.shared
    @Binding var isLoggedIn: Bool
    let userInfo: UserRegistrationInfo

    @State private var showMerchantRegistration = false
    @State private var showIdentityVerificationDialog = false

    var body: some View {
        ZStack {
            backgroundGradient

            VStack(spacing: 32) {
                headerSection
                roleCardsSection
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 40)
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
            colors: [
                Color.coppelBlue.opacity(0.05),
                Color.white,
                Color.coppelYellow.opacity(0.03)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("¿Cómo quieres usar Atenea?")
                .font(.coppelHeader)
                .foregroundStyle(Color.coppelDarkBlue)
                .fixedSize(horizontal: false, vertical: true)

            Text("Elige el perfil que mejor describa cómo planeas usar la aplicación. Podrás cambiar esto después en tu configuración.")
                .font(.coppelBody)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var roleCardsSection: some View {
        VStack(spacing: 20) {
            // User Role Card
            RoleCard(
                title: "Soy Cliente",
                description: "Quiero descubrir y encontrar comerciantes cerca de mí durante el Mundial",
                features: ["Navega con AR", "Recomendaciones IA", "Mensajes directos"],
                icon: "person.fill",
                gradient: LinearGradient(
                    colors: [Color.coppelBlue, Color.coppelLightBlue],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                action: { handleUserRoleSelection() }
            )

            // Merchant Role Card
            RoleCard(
                title: "Soy Comerciante",
                description: "Quiero dar a conocer mi negocio y atraer más clientes",
                features: ["Ubicación en tiempo real", "Gestión de productos", "Zona de demanda"],
                icon: "bag.fill",
                gradient: LinearGradient(
                    colors: [Color.coppelPurple, Color.coppelPink],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
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
        // Create user with user role
        let newUser = User(
            email: userInfo.email,
            name: userInfo.fullName,
            role: .user,
            accessibilityOption: userInfo.accessibilityOption,
            age: userInfo.age,
            country: userInfo.country,
            phoneNumber: userInfo.phoneNumber
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
    let gradient: LinearGradient
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            action()
        }) {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .top, spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(gradient)
                            .frame(width: 64, height: 64)
                            .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 4)

                        Image(systemName: icon)
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(title)
                            .font(.coppelSubheader)
                            .foregroundStyle(Color.coppelDarkBlue)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(description)
                            .font(.coppelBodySmall)
                            .foregroundStyle(.secondary)
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
                                .font(.system(size: 16))
                                .foregroundStyle(gradient)

                            Text(feature)
                                .font(.coppelBodySmall)
                                .foregroundStyle(Color.primaryText.opacity(0.8))
                        }
                    }
                }

                // Action indicator
                HStack {
                    Spacer()
                    HStack(spacing: 6) {
                        Text("Seleccionar")
                            .font(.coppelCTA)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(gradient)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: CoppelTheme.CornerRadius.xl, style: .continuous)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CoppelTheme.CornerRadius.xl, style: .continuous)
                    .strokeBorder(gradient.opacity(0.3), lineWidth: 2)
            )
            .scaleEffect(CGSize(width: isPressed ? 0.98 : 1.0, height: isPressed ? 0.98 : 1.0))
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

// MARK: - User Registration Info Model

struct UserRegistrationInfo {
    let fullName: String
    let age: String
    let country: String
    let email: String
    let phoneNumber: String
    let accessibilityOption: AccessibilityOption
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

// MARK: - Identity Verification Alert

extension RoleSelectionView {
    private func showIdentityVerificationAlert() {
        // Placeholder for future identity verification implementation
    }
}
