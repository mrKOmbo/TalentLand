//
//  SidebarPushMenuContainer.swift
//  atenea
//
//  Menú lateral deslizante con Coppel Brand Toolkit 2024
//  Solo items implementados: Profile, Settings, Favorites, Help, Venues, Accessibility, Logout
//

import SwiftUI

struct SidebarPushMenuContainer<Content: View>: View {
    @ObservedObject var menuStateManager = MenuStateManager.shared
    @ObservedObject var languageManager: LanguageManager
    @ObservedObject var userManager = UserManager.shared

    let content: Content

    var onProfile: (() -> Void)?
    var onSettings: (() -> Void)?
    var onFavorites: (() -> Void)?
    var onHelp: (() -> Void)?
    var onShowVenues: (() -> Void)?
    var onShowARScanner: (() -> Void)?
    var onShowSchedule: (() -> Void)?
    var onAccessibility: (() -> Void)?
    var onLogout: (() -> Void)?

    init(
        languageManager: LanguageManager,
        @ViewBuilder content: () -> Content
    ) {
        self.languageManager = languageManager
        self.content = content()
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(red: 0.05, green: 0.09, blue: 0.33)
                    .ignoresSafeArea()

                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: menuStateManager.showMenu ? 24 : 0,
                            style: .continuous
                        )
                    )
                    .shadow(
                        color: Color.black.opacity(menuStateManager.showMenu ? 0.3 : 0),
                        radius: menuStateManager.showMenu ? 30 : 0,
                        x: -8,
                        y: 0
                    )
                    .offset(x: menuStateManager.showMenu ? geometry.size.width * 0.75 : 0)
                    .scaleEffect(CGSize(width: menuStateManager.showMenu ? 0.9 : 1.0, height: menuStateManager.showMenu ? 0.9 : 1.0))
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: menuStateManager.showMenu)
                    .onTapGesture {
                        if menuStateManager.showMenu {
                            closeMenu()
                        }
                    }
                    .gesture(
                        DragGesture()
                            .onEnded { value in
                                if menuStateManager.showMenu && value.translation.width < -50 {
                                    closeMenu()
                                }
                            }
                    )
            }
            .ignoresSafeArea()
        }
        .overlay(
            menuContent.opacity(menuStateManager.showMenu ? 1 : 0),
            alignment: .leading
        )
    }

    private var menuContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            menuHeader
                .padding(.top, 56)
                .padding(.horizontal, 20)
                .padding(.bottom, 32)

            // Items
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 2) {
                    menuSectionTitle("FIFA World Cup 2026™")

                    menuItem(icon: "location.fill", title: "Venues") {
                        onShowVenues?()
                        closeMenu()
                    }

                    Divider()
                        .padding(.vertical, 12)
                        .padding(.horizontal, 8)

                    menuItem(icon: "person.crop.circle.fill", title: "Profile") {
                        onProfile?()
                        closeMenu()
                    }

                    menuItem(icon: "star.fill", title: "Favorites") {
                        onFavorites?()
                        closeMenu()
                    }

                    menuItem(icon: "gearshape.fill", title: "Settings") {
                        onSettings?()
                        closeMenu()
                    }

                    menuItem(icon: "questionmark.circle.fill", title: "Help") {
                        onHelp?()
                        closeMenu()
                    }

                    if userManager.currentUser?.needsAccessibilityFeatures == true {
                        Divider()
                            .padding(.vertical, 12)
                            .padding(.horizontal, 8)

                        menuItem(icon: "accessibility.fill", title: "Accessibility") {
                            onAccessibility?()
                            closeMenu()
                        }
                    }
                }
                .padding(.horizontal, 12)
            }

            Spacer()

            // Logout
            Button(action: {
                onLogout?()
                closeMenu()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 24)

                    Text("Logout")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)

                    Spacer()
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(red: 0.11, green: 0.26, blue: 0.91))
                )
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.05, green: 0.09, blue: 0.33))
    }

    private var menuHeader: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(Color(red: 0.11, green: 0.26, blue: 0.91))
                    .frame(width: 48, height: 48)

                Image(systemName: "person.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
            }

            Spacer()

            Button(action: closeMenu) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(red: 0.94, green: 0.82, blue: 0.14))
                    .frame(width: 44, height: 44)
            }
        }
    }

    private func menuSectionTitle(_ title: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "soccerball.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(red: 0.94, green: 0.82, blue: 0.14))

            Text(title)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(Color(red: 0.94, green: 0.82, blue: 0.14))
                .tracking(0.5)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
    }

    private func menuItem(icon: String, title: String, action: (() -> Void)? = nil) -> some View {
        Button(action: {
            let feedback = UIImpactFeedbackGenerator(style: .light)
            feedback.impactOccurred()
            action?()
        }) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(red: 0.94, green: 0.82, blue: 0.14))
                    .frame(width: 24)

                Text(title)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(.white)

                Spacer()
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 8)
        }
    }

    private func closeMenu() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            menuStateManager.closeMenu()
        }
    }
}

// MARK: - Builder Extensions

extension SidebarPushMenuContainer {
    func onProfile(_ action: @escaping () -> Void) -> Self {
        var view = self
        view.onProfile = action
        return view
    }

    func onSettings(_ action: @escaping () -> Void) -> Self {
        var view = self
        view.onSettings = action
        return view
    }

    func onFavorites(_ action: @escaping () -> Void) -> Self {
        var view = self
        view.onFavorites = action
        return view
    }

    func onHelp(_ action: @escaping () -> Void) -> Self {
        var view = self
        view.onHelp = action
        return view
    }

    func onShowVenues(_ action: @escaping () -> Void) -> Self {
        var view = self
        view.onShowVenues = action
        return view
    }

    func onShowARScanner(_ action: @escaping () -> Void) -> Self {
        var view = self
        view.onShowARScanner = action
        return view
    }

    func onShowSchedule(_ action: @escaping () -> Void) -> Self {
        var view = self
        view.onShowSchedule = action
        return view
    }

    func onAccessibility(_ action: @escaping () -> Void) -> Self {
        var view = self
        view.onAccessibility = action
        return view
    }

    func onLogout(_ action: @escaping () -> Void) -> Self {
        var view = self
        view.onLogout = action
        return view
    }
}

#Preview {
    SidebarPushMenuContainer(languageManager: LanguageManager.shared) {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.4, green: 0.5, blue: 0.9),
                    Color(red: 0.5, green: 0.3, blue: 0.8)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack {
                HStack {
                    Button(action: {
                        MenuStateManager.shared.toggleMenu()
                    }) {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                    }
                    .padding(.leading, 20)

                    Spacer()
                }
                .padding(.top, 60)

                Spacer()

                Text("Main Map")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Spacer()
            }
        }
    }
}
