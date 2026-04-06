//
//  ProfileView.swift
//  atenea
//
//  Ultra-modern profile view with glassmorphism design
//

import SwiftUI

struct UserProfileView: View {
    @ObservedObject var userManager = UserManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var isEditMode = false
    @State private var editedName = ""
    @State private var editedEmail = ""
    @State private var showSuccessMessage = false

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.95, green: 0.97, blue: 1.0),
                    Color(red: 0.98, green: 0.95, blue: 1.0)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Header con botón de cerrar
                    HStack {
                        Spacer()

                        Button(action: {
                            dismiss()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 36, height: 36)
                                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)

                                Image(systemName: "xmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    // Avatar Section
                    VStack(spacing: 16) {
                        ZStack {
                            // Glow effect
                            Circle()
                                .fill(
                                    RadialGradient(
                                        gradient: Gradient(colors: [
                                            Color.blue.opacity(0.4),
                                            Color.purple.opacity(0.2),
                                            Color.clear
                                        ]),
                                        center: .center,
                                        startRadius: 40,
                                        endRadius: 80
                                    )
                                )
                                .frame(width: 140, height: 140)
                                .blur(radius: 20)

                            // Avatar
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.blue,
                                            Color.purple.opacity(0.8),
                                            Color.pink.opacity(0.6)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 120, height: 120)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 4)
                                )
                                .shadow(color: Color.blue.opacity(0.3), radius: 20, x: 0, y: 10)

                            Image(systemName: "person.fill")
                                .font(.system(size: 50, weight: .medium))
                                .foregroundColor(.white)
                        }

                        if !isEditMode {
                            VStack(spacing: 8) {
                                Text(userManager.currentUser?.name ?? "Usuario")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundStyle(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.blue, Color.purple]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )

                                Text(userManager.currentUser?.email ?? "usuario@email.com")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                        }
                    }

                    // Stats Cards
                    HStack(spacing: 12) {
                        statCard(
                            icon: "map.fill",
                            title: "Viajes",
                            value: "24",
                            gradient: [Color.green, Color.mint]
                        )

                        statCard(
                            icon: "star.fill",
                            title: "Puntos",
                            value: "1.2K",
                            gradient: [Color.orange, Color.yellow]
                        )

                        statCard(
                            icon: "flag.fill",
                            title: "Logros",
                            value: "12",
                            gradient: [Color.purple, Color.pink]
                        )
                    }
                    .padding(.horizontal, 20)

                    // Info Section
                    VStack(spacing: 16) {
                        if isEditMode {
                            // Edit Mode
                            modernTextField(
                                icon: "person.fill",
                                placeholder: "Nombre",
                                text: $editedName,
                                gradient: [Color.blue, Color.cyan]
                            )

                            modernTextField(
                                icon: "envelope.fill",
                                placeholder: "Email",
                                text: $editedEmail,
                                gradient: [Color.purple, Color.pink]
                            )

                            // Save Button
                            Button(action: {
                                saveChanges()
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 20, weight: .bold))

                                    Text("Guardar Cambios")
                                        .font(.system(size: 17, weight: .bold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.blue, Color.purple]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                                .shadow(color: Color.blue.opacity(0.4), radius: 12, x: 0, y: 6)
                            }

                            // Cancel Button
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    isEditMode = false
                                }
                            }) {
                                Text("Cancelar")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                            }
                        } else {
                            // View Mode
                            infoCard(
                                icon: "person.fill",
                                title: "Nombre",
                                value: userManager.currentUser?.name ?? "Usuario",
                                gradient: [Color.blue, Color.cyan]
                            )

                            infoCard(
                                icon: "envelope.fill",
                                title: "Email",
                                value: userManager.currentUser?.email ?? "usuario@email.com",
                                gradient: [Color.purple, Color.pink]
                            )

                            infoCard(
                                icon: "calendar",
                                title: "Miembro desde",
                                value: "Enero 2024",
                                gradient: [Color.green, Color.mint]
                            )

                            // Edit Button
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    editedName = userManager.currentUser?.name ?? ""
                                    editedEmail = userManager.currentUser?.email ?? ""
                                    isEditMode = true
                                }
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "pencil.circle.fill")
                                        .font(.system(size: 20, weight: .bold))

                                    Text("Editar Perfil")
                                        .font(.system(size: 17, weight: .bold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.blue, Color.purple]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                                .shadow(color: Color.blue.opacity(0.4), radius: 12, x: 0, y: 6)
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer(minLength: 40)
                }
            }

            // Success Message
            if showSuccessMessage {
                VStack {
                    Spacer()

                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.green)

                        Text("Cambios guardados")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
                    )
                    .padding(.bottom, 40)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Components

    private func statCard(icon: String, title: String, value: String, gradient: [Color]) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: gradient.map { $0.opacity(0.15) }),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: gradient),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)

            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
        )
    }

    private func infoCard(icon: String, title: String, value: String, gradient: [Color]) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: gradient.map { $0.opacity(0.15) }),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: gradient),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.gray)

                Text(value)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
        )
    }

    private func modernTextField(icon: String, placeholder: String, text: Binding<String>, gradient: [Color]) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: gradient.map { $0.opacity(0.15) }),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: gradient),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            TextField(placeholder, text: text)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
        )
    }

    private func saveChanges() {
        // Simulate save
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isEditMode = false
            showSuccessMessage = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showSuccessMessage = false
            }
        }
    }
}

#Preview {
    UserProfileView()
}
