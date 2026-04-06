//
//  StaffStatisticsView.swift
//  atenea
//
//  Vista de estadísticas para el staff
//

import SwiftUI

struct StaffStatisticsView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            // Fondo
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(red: 0.0, green: 0.15, blue: 0.1)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        isPresented = false
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Atrás")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.white.opacity(0.7))
                    }

                    Spacer()

                    Text("Estadísticas")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)

                    Spacer()

                    // Espaciador para centrar el título
                    Color.clear
                        .frame(width: 80, height: 28)
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 20)

                // Contenido
                ScrollView {
                    VStack(spacing: 20) {
                        // Icono principal
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.2))
                                .frame(width: 80, height: 80)

                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 40))
                                .foregroundColor(.green)
                        }
                        .padding(.top, 20)

                        // Grid de estadísticas
                        VStack(spacing: 16) {
                            HStack(spacing: 16) {
                                StatCard(
                                    title: "Usuarios Totales",
                                    value: "1,234",
                                    icon: "person.3.fill",
                                    color: .blue
                                )

                                StatCard(
                                    title: "Activos Hoy",
                                    value: "856",
                                    icon: "person.fill.checkmark",
                                    color: .green
                                )
                            }

                            HStack(spacing: 16) {
                                StatCard(
                                    title: "Reservaciones",
                                    value: "2,450",
                                    icon: "ticket.fill",
                                    color: .purple
                                )

                                StatCard(
                                    title: "Emergencias",
                                    value: "12",
                                    icon: "exclamationmark.triangle.fill",
                                    color: .red
                                )
                            }

                            HStack(spacing: 16) {
                                StatCard(
                                    title: "Lugares Visitados",
                                    value: "4,521",
                                    icon: "mappin.circle.fill",
                                    color: .orange
                                )

                                StatCard(
                                    title: "Búsquedas IA",
                                    value: "8,934",
                                    icon: "sparkles",
                                    color: .cyan
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                        // Sección de gráficos
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Actividad Semanal")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)

                            // Placeholder para gráfico
                            VStack(spacing: 12) {
                                HStack(alignment: .bottom, spacing: 12) {
                                    ForEach(0..<7) { index in
                                        VStack(spacing: 4) {
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(Color.green.opacity(0.8))
                                                .frame(width: 40, height: CGFloat.random(in: 60...160))

                                            Text(["L", "M", "M", "J", "V", "S", "D"][index])
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(.white.opacity(0.6))
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .padding(20)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(16)
                            .padding(.horizontal, 20)
                        }
                        .padding(.top, 20)

                        Spacer()
                            .frame(height: 40)
                    }
                }
            }
        }
    }
}

// MARK: - Stat Card Component
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(color)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)

                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(Color.white.opacity(0.1))
        .cornerRadius(16)
    }
}

#Preview {
    StaffStatisticsView(isPresented: .constant(true))
        .environmentObject(LanguageManager.shared)
}
