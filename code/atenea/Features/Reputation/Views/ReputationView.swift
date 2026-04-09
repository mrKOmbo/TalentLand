//
//  ReputationView.swift
//  atenea
//
//  Sistema de reputación y reconocimientos para usuarios
//

import SwiftUI

// MARK: - Reputation Level

enum ReputationLevel: Int, CaseIterable {
    case novato = 1
    case explorador = 2
    case conocedor = 3
    case experto = 4
    case leyenda = 5

    var title: String {
        switch self {
        case .novato: return "Novato"
        case .explorador: return "Explorador"
        case .conocedor: return "Conocedor"
        case .experto: return "Experto"
        case .leyenda: return "Leyenda"
        }
    }

    var icon: String {
        switch self {
        case .novato: return "leaf.fill"
        case .explorador: return "binoculars.fill"
        case .conocedor: return "star.fill"
        case .experto: return "crown.fill"
        case .leyenda: return "trophy.fill"
        }
    }

    var color: Color {
        switch self {
        case .novato: return .gray
        case .explorador: return .green
        case .conocedor: return .coppelBlue
        case .experto: return .purple
        case .leyenda: return .coppelYellow
        }
    }

    var minPoints: Int {
        switch self {
        case .novato: return 0
        case .explorador: return 100
        case .conocedor: return 300
        case .experto: return 600
        case .leyenda: return 1000
        }
    }
}

// MARK: - Badge

struct ReputationBadge: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let icon: String
    let color: Color
    let earnedDate: Date?

    var isEarned: Bool { earnedDate != nil }
}

// MARK: - Activity

struct ReputationActivity: Identifiable {
    let id = UUID()
    let title: String
    let points: Int
    let icon: String
    let date: Date
}

// MARK: - ReputationView

struct ReputationView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var userManager = UserManager.shared

    // Datos simulados
    private let currentPoints = 345
    private let currentLevel = ReputationLevel.conocedor
    private let nextLevel = ReputationLevel.experto

    private let badges: [ReputationBadge] = [
        ReputationBadge(name: "Primera reseña", description: "Escribiste tu primera recomendación", icon: "pencil.circle.fill", color: .green, earnedDate: Calendar.current.date(byAdding: .day, value: -30, to: Date())),
        ReputationBadge(name: "Guía local", description: "5 recomendaciones útiles en tu zona", icon: "map.circle.fill", color: .coppelBlue, earnedDate: Calendar.current.date(byAdding: .day, value: -12, to: Date())),
        ReputationBadge(name: "Foodie", description: "10 reseñas de comida callejera", icon: "fork.knife.circle.fill", color: .orange, earnedDate: Calendar.current.date(byAdding: .day, value: -5, to: Date())),
        ReputationBadge(name: "Explorador FIFA", description: "Visitaste 5 sedes del Mundial", icon: "soccerball", color: .coppelYellow, earnedDate: Calendar.current.date(byAdding: .day, value: -2, to: Date())),
        ReputationBadge(name: "Influencer", description: "50 personas siguieron tu recomendación", icon: "person.3.fill", color: .purple, earnedDate: nil),
        ReputationBadge(name: "Leyenda urbana", description: "Alcanza el nivel Leyenda", icon: "trophy.fill", color: .coppelYellow, earnedDate: nil),
    ]

    private let recentActivity: [ReputationActivity] = [
        ReputationActivity(title: "Recomendación de tacos votada útil", points: 15, icon: "hand.thumbsup.fill", date: Calendar.current.date(byAdding: .hour, value: -3, to: Date())!),
        ReputationActivity(title: "Comentario en zona Estadio Azteca", points: 10, icon: "text.bubble.fill", date: Calendar.current.date(byAdding: .hour, value: -8, to: Date())!),
        ReputationActivity(title: "Reseña verificada por la comunidad", points: 25, icon: "checkmark.seal.fill", date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!),
        ReputationActivity(title: "Ayudaste a un turista con direcciones", points: 20, icon: "figure.walk", date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!),
        ReputationActivity(title: "Foto de puesto callejero compartida", points: 10, icon: "camera.fill", date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!),
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    levelCard
                    badgesSection
                    activitySection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .background(Color(hex: "#F5F3F0").ignoresSafeArea())
            .navigationTitle("Reconocimientos")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }

    // MARK: - Level Card

    private var levelCard: some View {
        VStack(spacing: 16) {
            // Icono y nivel
            ZStack {
                Circle()
                    .fill(currentLevel.color.opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: currentLevel.icon)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(currentLevel.color)
            }

            VStack(spacing: 4) {
                Text(userManager.currentUser?.name ?? "Usuario")
                    .font(.system(size: 20, weight: .bold, design: .rounded))

                Text("Nivel: \(currentLevel.title)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(currentLevel.color)
            }

            // Barra de progreso
            VStack(spacing: 8) {
                let progress = Double(currentPoints - currentLevel.minPoints) / Double(nextLevel.minPoints - currentLevel.minPoints)

                HStack {
                    Text("\(currentPoints) pts")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(nextLevel.minPoints) pts para \(nextLevel.title)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 10)

                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [currentLevel.color, nextLevel.color],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * progress, height: 10)
                    }
                }
                .frame(height: 10)
            }

            // Stats rápidos
            HStack(spacing: 0) {
                statItem(value: "12", label: "Reseñas")
                Divider().frame(height: 30)
                statItem(value: "87%", label: "Útiles")
                Divider().frame(height: 30)
                statItem(value: "4", label: "Insignias")
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.white)
                .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
        )
        .padding(.top, 8)
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Badges Section

    private var badgesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Insignias")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .padding(.leading, 4)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(badges) { badge in
                    badgeCard(badge)
                }
            }
        }
    }

    private func badgeCard(_ badge: ReputationBadge) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(badge.isEarned ? badge.color.opacity(0.15) : Color.gray.opacity(0.1))
                    .frame(width: 52, height: 52)

                Image(systemName: badge.icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(badge.isEarned ? badge.color : .gray.opacity(0.4))
            }

            Text(badge.name)
                .font(.system(size: 11, weight: .semibold))
                .multilineTextAlignment(.center)
                .foregroundColor(badge.isEarned ? .primary : .gray)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.white)
                .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
        )
        .opacity(badge.isEarned ? 1 : 0.6)
    }

    // MARK: - Activity Section

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Actividad reciente")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .padding(.leading, 4)

            VStack(spacing: 0) {
                ForEach(Array(recentActivity.enumerated()), id: \.element.id) { index, activity in
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.coppelBlue.opacity(0.12))
                                .frame(width: 40, height: 40)

                            Image(systemName: activity.icon)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.coppelBlue)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(activity.title)
                                .font(.system(size: 14, weight: .medium))
                                .lineLimit(1)

                            Text(activity.date, style: .relative)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Text("+\(activity.points)")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.green)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)

                    if index < recentActivity.count - 1 {
                        Divider().padding(.leading, 70)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
            )
        }
    }
}

#Preview {
    ReputationView()
}
