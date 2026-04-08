//  WelcomeView.swift
//  atenea
//
//  Vista de bienvenida optimizada con Apple HIG

import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @Binding var isLoggedIn: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                // 1. Fondo con Gradiente y Elementos Decorativos
                backgroundView

                // 2. Contenido Principal
                VStack(spacing: 0) {
                    Spacer()

                    // Logo y Títulos
                    VStack(spacing: 28) {
                        brandIcon

                        VStack(spacing: 12) {
                            Text("Bienvenido a Atenea")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)

                            Text("Descubre negocios locales o impulsa tu emprendimiento en la red más grande de la Copa del Mundo.")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.white.opacity(0.85))
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                                .padding(.horizontal, 20)
                        }
                    }

                    Spacer()

                    // Botones de Acción
                    actionSection
                        .padding(.bottom, 50)
                }
                .padding(.horizontal, 30)
            }
            .ignoresSafeArea()
        }
    }

    // MARK: - Componentes de UI

    private var backgroundView: some View {
        ZStack {
            Color.coppelDarkBlue // Color base

            LinearGradient(
                colors: [Color.coppelBlue.opacity(0.6), Color.coppelDarkBlue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Círculos decorativos más sutiles para no ensuciar el texto
            Circle()
                .fill(Color.coppelYellow.opacity(0.12))
                .frame(width: 300)
                .blur(radius: 70)
                .offset(x: 150, y: -250)

            Circle()
                .fill(Color.white.opacity(0.05))
                .frame(width: 400)
                .blur(radius: 90)
                .offset(x: -150, y: 300)
        }
    }

    private var brandIcon: some View {
        Text("ATR")
            .font(.system(size: 22, weight: .black, design: .rounded))
            .foregroundColor(.coppelBlue)
            .frame(width: 80, height: 80)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.coppelYellow)
                    .shadow(color: Color.coppelYellow.opacity(0.3), radius: 20, x: 0, y: 10)
            )
    }

    private var actionSection: some View {
        VStack(spacing: 16) {
            // Botón Principal - Iniciar Sesión
            NavigationLink(destination: LoginView(isLoggedIn: $isLoggedIn)
                .environmentObject(languageManager)
            ) {
                HStack {
                    Text("Iniciar sesión")
                    Image(systemName: "arrow.right")
                }
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.black) // Texto oscuro para máximo contraste
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.coppelYellow)
                )
            }
            .buttonStyle(PlainButtonStyle())

            // Botón Secundario - Registrarse
            NavigationLink(destination: RegisterView(isLoggedIn: $isLoggedIn)
                .environmentObject(languageManager)
            ) {
                Text("Registrarse")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.6), lineWidth: 2)
                            .background(Color.white.opacity(0.1))
                    )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

// MARK: - Preview

#Preview {
    WelcomeView(isLoggedIn: .constant(false))
        .environmentObject(LanguageManager.shared)
}
