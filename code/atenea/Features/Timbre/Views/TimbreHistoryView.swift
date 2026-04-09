//
//  TimbreHistoryView.swift
//  atenea
//
//  Lista de timbres recientes para el merchant
//

import SwiftUI

struct TimbreHistoryView: View {
    @ObservedObject private var timbreManager = TimbreManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#0A0A1A"), Color(hex: "#0D1B2A")],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(LocalizedString("timbre.history.title"))
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                        Text(String(format: LocalizedString("timbre.history.unread"), timbreManager.unreadCount))
                            .font(.system(size: 13))
                            .foregroundColor(.orange)
                    }

                    Spacer()

                    if timbreManager.unreadCount > 0 {
                        Button(LocalizedString("timbre.history.markAll")) {
                            timbreManager.markAllAsRead()
                        }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.blue)
                    }

                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .padding()

                if timbreManager.pendingTimbres.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.3))
                        Text(LocalizedString("timbre.history.noTimbres"))
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(timbreManager.pendingTimbres) { timbre in
                                TimbreHistoryRow(timbre: timbre) { responseType in
                                    timbreManager.respond(to: timbre.id, with: responseType)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
    }
}

// MARK: - History Row

struct TimbreHistoryRow: View {
    let timbre: TimbreEvent
    let onRespond: (TimbreResponseType) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                // Status dot
                if !timbre.isRead {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 8, height: 8)
                } else if timbre.isResponded {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.green)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 8, height: 8)
                }

                // Tipo emoji
                Text(timbre.type.emoji)
                    .font(.system(size: 20))

                // Info
                VStack(alignment: .leading, spacing: 1) {
                    Text(timbre.clientName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    Text(timbre.type.displayName)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                Text(timbre.timeAgo)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
            }

            // Mensaje si hay
            if let msg = timbre.message {
                Text("\"\(msg)\"")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
                    .italic()
                    .padding(.leading, 18)
            }

            // Respuesta o botones
            if let response = timbre.response {
                HStack(spacing: 4) {
                    Text(response.type.emoji)
                    Text(String(format: LocalizedString("timbre.history.respondedWith"), response.type.displayName))
                        .font(.system(size: 12))
                        .foregroundColor(.green.opacity(0.8))
                }
                .padding(.leading, 18)
            } else if !timbre.isResponded {
                HStack(spacing: 6) {
                    ForEach([TimbreResponseType.onMyWay, .waitHere, .busy], id: \.self) { type in
                        Button {
                            onRespond(type)
                        } label: {
                            Text("\(type.emoji) \(type.displayName)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(Capsule().fill(Color.white.opacity(0.1)))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.leading, 18)
            }
        }
        .padding(12)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(timbre.isRead ? Color.white.opacity(0.02) : Color.orange.opacity(0.05))
            }
        )
        .onAppear {
            if !timbre.isRead {
                TimbreManager.shared.markAsRead(timbre.id)
            }
        }
    }
}
