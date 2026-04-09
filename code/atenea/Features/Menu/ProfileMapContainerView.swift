//
//  ProfileMapContainerView.swift
//  atenea
//
//  Contenedor principal: menú + vistas funcionales
//

import SwiftUI

struct ProfileMapContainerView: View {
    @StateObject private var languageManager = LanguageManager.shared
    @StateObject private var userManager = UserManager.shared
    @ObservedObject private var menuStateManager = MenuStateManager.shared

    @State private var showProfileSheet = false
    @State private var showSettingsSheet = false
    @State private var showFavoritesSheet = false
    @State private var showHelpSheet = false
    @State private var showVenuesSheet = false
    @State private var showAccessibilitySheet = false
    @State private var isLoggedIn = true

    var body: some View {
        SidebarPushMenuContainer(languageManager: languageManager) {
            mapContentView
        }
        .onProfile {
            showProfileSheet = true
        }
        .onSettings {
            showSettingsSheet = true
        }
        .onFavorites {
            showFavoritesSheet = true
        }
        .onHelp {
            showHelpSheet = true
        }
        .onShowVenues {
            showVenuesSheet = true
        }
        .onAccessibility {
            showAccessibilitySheet = true
        }
        .onLogout {
            handleLogout()
        }
        .sheet(isPresented: $showProfileSheet) {
            UserProfileView()
        }
        .sheet(isPresented: $showSettingsSheet) {
            SettingsView(languageManager: languageManager)
        }
        .sheet(isPresented: $showFavoritesSheet) {
            FavoritesView()
        }
        .sheet(isPresented: $showHelpSheet) {
            HelpView()
        }
        .sheet(isPresented: $showVenuesSheet) {
            NavigationView {
                VenuesListView()
            }
        }
        .sheet(isPresented: $showAccessibilitySheet) {
            VisualAccessibilitySettingsView()
        }
    }

    private var mapContentView: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.16, blue: 0.42),
                    Color(red: 0.7, green: 0.12, blue: 0.12),
                    Color(red: 0.99, green: 0.73, blue: 0.18)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                headerView
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.4, green: 0.5, blue: 0.9),
                                Color(red: 0.5, green: 0.3, blue: 0.8)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(
                        .rect(
                            bottomLeadingRadius: 24,
                            bottomTrailingRadius: 24
                        )
                    )
                    .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 6)

                Spacer()

                bottomSheetView
            }
            .ignoresSafeArea(edges: .top)
        }
    }

    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        menuStateManager.toggleMenu()
                    }
                }) {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Color.white.opacity(0.2)))
                }
                .padding(.leading, 16)

                Spacer()

                Button(action: {}) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(width: 44, height: 44)
                }
                .padding(.trailing, 16)
            }
            .padding(.top, 56)

            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 76, height: 76)
                        .overlay(Circle().stroke(Color.white.opacity(0.5), lineWidth: 2))
                        .shadow(color: Color.black.opacity(0.2), radius: 12)

                    Image(systemName: "person.fill")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.9))
                }

                VStack(spacing: 4) {
                    Text(userManager.currentUser?.name ?? "User")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text(userManager.currentUser?.email ?? "user@atenea.com")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.85))
                }
            }
            .padding(.bottom, 16)
        }
    }

    private var bottomSheetView: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(spacing: 8) {
                quickActionItem(icon: "person.crop.circle.fill", title: "Profile", color: Color(red: 0.11, green: 0.26, blue: 0.91)) {
                    showProfileSheet = true
                }

                quickActionItem(icon: "star.fill", title: "Favorites", color: Color(red: 0.99, green: 0.73, blue: 0.18)) {
                    showFavoritesSheet = true
                }

                quickActionItem(icon: "gearshape.fill", title: "Settings", color: Color(red: 0.94, green: 0.36, blue: 0.3)) {
                    showSettingsSheet = true
                }

                quickActionItem(icon: "questionmark.circle.fill", title: "Help", color: Color(red: 0.49, green: 0.26, blue: 1)) {
                    showHelpSheet = true
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            Divider()
                .padding(.vertical, 12)
                .padding(.horizontal, 16)

            Button(action: { showVenuesSheet = true }) {
                HStack {
                    Image(systemName: "soccerball.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)

                    Text("FIFA World Cup 2026™")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(red: 0.05, green: 0.75, blue: 0.31))
                )
            }
            .padding(.horizontal, 16)

            Spacer()

            Text(LocalizedString("profileMap.atenea2026"))
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(.gray.opacity(0.5))
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 16, x: 0, y: -6)
        )
    }

    private func quickActionItem(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.12))
                        .frame(width: 42, height: 42)

                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(color)
                }

                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.gray.opacity(0.3))
            }
            .padding(.vertical, 8)
        }
    }

    private func handleLogout() {
        withAnimation {
            isLoggedIn = false
        }
        print("🔓 Logout")
    }
}

#Preview {
    ProfileMapContainerView()
}
