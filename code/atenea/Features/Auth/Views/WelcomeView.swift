//  WelcomeView.swift
//  atenea
//
//  Vista de bienvenida nativa iOS — Coppel Brand Toolkit 2024
//  Cumplimiento estricto: gradiente lineal, logos sin barra opaca, búho limpio, contraste AAA

import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @Binding var isLoggedIn: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                // MARK: - Fondo: Gradiente Lineal Vertical (coppelBlue → darkBlue)
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color.coppelBlue, location: 0.0),
                        .init(color: Color.coppelDarkBlue, location: 1.0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // MARK: - Contenido Principal (VStack vertical)
                VStack(spacing: 0) {
                    // 1. Logos de Patrocinadores (Fundación Coppel + Divisor + Coppel Emprende)
                    // Posicionados directamente sobre el gradiente, sin barra opaca
                    sponsorLogosSection
                        .frame(height: 55)
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .padding(.bottom, 32)

                    Spacer()

                    // 2. Logo del Búho de Atenea (limpio, sin recuadro)
                    // [Asset: AteneaOwlIconCleanVector]
                    Image("Atenea-Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .shadow(color: Color.black.opacity(0.25), radius: 16, x: 0, y: 8)

                    // 3. Textos de Bienvenida (Jerarquía visual)
                    VStack(spacing: 16) {
                        // Headline: "Bienvenido a Atenea" en coppelYellow
                        Text("Bienvenido a Atenea")
                            .font(.system(size: 36, weight: .semibold, design: .default))
                            .foregroundColor(.coppelYellow)
                            .multilineTextAlignment(.center)

                        // Body: Descripción en white con 120% leading
                        Text("Descubre negocios locales o impulsa tu emprendimiento en la red más grande de la Copa del Mundo.")
                            .font(.system(size: 17, weight: .regular, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)
                            .padding(.horizontal, 24)
                    }
                    .padding(.top, 32)

                    Spacer()

                    // 4. Acciones (Botones con AAA contrast)
                    actionSection
                        .padding(.horizontal, 24)
                        .padding(.bottom, 60)
                }
            }
        }
    }

    // MARK: - Sponsor Logos Section
    private var sponsorLogosSection: some View {
        HStack(spacing: 0) {
            // Fundación Coppel (izquierda)
            // [Asset: FundaciónCoppelLogoWhite]
            Image("Fundacion-Coppel-Logo")
                .resizable()
                .scaledToFit()
                .frame(height: 32)

            Spacer()

            // Divisor vertical fino en white
            Rectangle()
                .fill(Color.white.opacity(0.4))
                .frame(width: 1, height: 32)

            Spacer()

            // Coppel Emprende (derecha)
            // [Asset: CoppelEmprendeLogoWhite]
            Image("Coppel-Emprende-Logo")
                .resizable()
                .scaledToFit()
                .frame(height: 32)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Action Section (Botones)
    private var actionSection: some View {
        VStack(spacing: 16) {
            // Botón Primario: "Iniciar sesión →" (coppelYellow fill, darkBlue text)
            NavigationLink(destination: LoginView(isLoggedIn: $isLoggedIn)
                .environmentObject(languageManager)
            ) {
                HStack(spacing: 8) {
                    Text("Iniciar sesión")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))

                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.coppelDarkBlue)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.coppelYellow)
                )
            }
            .buttonStyle(PlainButtonStyle())

            // Botón Secundario: "Registrarse" (white outline, white text)
            NavigationLink(destination: RegisterView(isLoggedIn: $isLoggedIn)
                .environmentObject(languageManager)
            ) {
                Text("Registrarse")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.7), lineWidth: 2)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.white.opacity(0.08))
                            )
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
