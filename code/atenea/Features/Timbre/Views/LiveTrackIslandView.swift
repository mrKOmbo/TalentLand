//
//  LiveTrackIslandView.swift
//  atenea
//
//  Dynamic Island flotante que muestra el tracking del vendedor acercándose
//  "Uber al revés" — el vendedor camina hacia ti y tú lo ves llegar
//

import SwiftUI

// MARK: - Live Track Dynamic Island

struct LiveTrackIslandView: View {
    @ObservedObject var tracker = LiveTrackManager.shared
    @State private var isExpanded = false
    @State private var showContent = false
    @State private var pulseAnimation = false

    var body: some View {
        if tracker.isTracking {
            VStack {
                Spacer()

                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        isExpanded.toggle()
                    }
                } label: {
                    if isExpanded {
                        expandedView
                    } else {
                        compactView
                    }
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.bottom, 100)
            }
            .ignoresSafeArea()
            .transition(.move(edge: .top).combined(with: .opacity))
            .onAppear {
                withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                    showContent = true
                }
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    pulseAnimation = true
                }
            }
            .onDisappear {
                showContent = false
            }
        }
    }

    private var compactBorderColor: Color {
        tracker.hasArrived ? Color.green.opacity(0.4) : Color.cyan.opacity(0.2)
    }

    private var expandedBorderColor: Color {
        tracker.hasArrived ? Color.green.opacity(0.3) : Color.cyan.opacity(0.15)
    }

    // MARK: - Compact View

    private var compactView: some View {
        HStack(spacing: 8) {
            // Emoji del vendedor con pulso
            ZStack {
                if !tracker.hasArrived {
                    Circle()
                        .fill(Color.green.opacity(0.3))
                        .frame(width: 30, height: 30)
                        .scaleEffect(CGFloat(pulseAnimation ? 1.3 : 1.0))
                }
                Text(tracker.merchantEmoji)
                    .font(.system(size: 18))
            }
            .frame(width: 30, height: 30)

            if tracker.hasArrived {
                Text(LocalizedString("liveTrack.arrived"))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.green)
            } else {
                // Distancia
                Text(tracker.distanceText)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("·")
                    .foregroundColor(.white.opacity(0.3))

                // ETA
                Text(tracker.etaText)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.cyan)
            }

            // Mini progress
            if !tracker.hasArrived {
                ProgressRing(progress: tracker.progress, size: 18, lineWidth: 2.5)
            }

            Image(systemName: "chevron.down")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.white.opacity(0.4))
                .rotationEffect(.degrees(isExpanded ? 180 : 0))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .strokeBorder(compactBorderColor, lineWidth: 0.5)
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 4)
        .opacity(showContent ? 1 : 0)
        .scaleEffect(showContent ? 1 : 0.8)
    }

    // MARK: - Expanded View

    private var expandedView: some View {
        VStack(spacing: 14) {
            // Header
            HStack(spacing: 12) {
                Button {
                    withAnimation { tracker.stopTracking() }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.white.opacity(0.3))
                }

                Spacer()

                ZStack {
                    if !tracker.hasArrived {
                        Circle()
                            .fill(Color.green.opacity(0.2))
                            .frame(width: 48, height: 48)
                            .scaleEffect(CGFloat(pulseAnimation ? 1.2 : 1.0))
                    }
                    Text(tracker.merchantEmoji)
                        .font(.system(size: 28))
                }
                .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: 3) {
                    Text(tracker.merchantName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Text(tracker.merchantCategory)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }
            }

            if tracker.hasArrived {
                // Llegó
                arrivedSection
            } else {
                // Tracking activo
                activeTrackingSection
            }
        }
        .padding(16)
        .frame(maxWidth: 320)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(expandedBorderColor, lineWidth: 0.5)
                )
        )
        .shadow(color: .black.opacity(0.35), radius: 16, x: 0, y: 6)
    }

    // MARK: - Active Tracking Section

    private var activeTrackingSection: some View {
        VStack(spacing: 12) {
            // Barra de progreso
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 8)

                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.cyan, .green],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(geo.size.width * tracker.progress, 8), height: 8)

                    // Dot indicator
                    Circle()
                        .fill(.white)
                        .frame(width: 14, height: 14)
                        .shadow(color: .cyan.opacity(0.5), radius: 4)
                        .offset(x: min(geo.size.width * tracker.progress - 7, geo.size.width - 14))
                }
            }
            .frame(height: 14)

            // Stats
            HStack(spacing: 16) {
                VStack(spacing: 2) {
                    Text(tracker.distanceText)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .contentTransition(.numericText())
                    Text(LocalizedString("liveTrack.distance"))
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.4))
                }

                Divider()
                    .frame(height: 30)
                    .background(Color.white.opacity(0.1))

                VStack(spacing: 2) {
                    Text(tracker.etaText)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.cyan)
                        .contentTransition(.numericText())
                    Text(LocalizedString("liveTrack.arrival"))
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.4))
                }

                Divider()
                    .frame(height: 30)
                    .background(Color.white.opacity(0.1))

                VStack(spacing: 2) {
                    ProgressRing(progress: tracker.progress, size: 24, lineWidth: 3)
                    Text("\(Int(tracker.progress * 100))%")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
    }

    // MARK: - Arrived Section

    private var arrivedSection: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.green)

                Text(String(format: LocalizedString("liveTrack.merchantArrived"), tracker.merchantName))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.green)
            }

            Text(LocalizedString("liveTrack.lookNearby"))
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Progress Ring

struct ProgressRing: View {
    let progress: Double
    let size: CGFloat
    let lineWidth: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(colors: [.cyan, .green], startPoint: .topLeading, endPoint: .bottomTrailing),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
    }
}
