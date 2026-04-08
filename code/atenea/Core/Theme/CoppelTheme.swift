//
//  CoppelTheme.swift
//  atenea
//
//  Coppel Brand Theme - Complete Design System
//  Based on Coppel Brand Toolkit 2024
//

import SwiftUI

/// Main theme configuration for the Atenea app with Coppel branding
struct CoppelTheme {

    // MARK: - Spacing

    struct Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
        static let xxxl: CGFloat = 64
    }

    // MARK: - Corner Radius

    struct CornerRadius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let full: CGFloat = 9999
    }

    // MARK: - Shadow

    // Note: SwiftUI shadows are applied via .shadow() modifier
    // These are helper values for consistent shadow styling
    struct ShadowStyle {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat

        static let sm = ShadowStyle(
            color: Color.black.opacity(0.08),
            radius: 4,
            x: 0,
            y: 2
        )

        static let md = ShadowStyle(
            color: Color.black.opacity(0.12),
            radius: 8,
            x: 0,
            y: 4
        )

        static let lg = ShadowStyle(
            color: Color.black.opacity(0.16),
            radius: 16,
            x: 0,
            y: 8
        )
    }

    // MARK: - Icon Sizes

    struct IconSize {
        static let xs: CGFloat = 16
        static let sm: CGFloat = 20
        static let md: CGFloat = 24
        static let lg: CGFloat = 32
        static let xl: CGFloat = 48
        static let xxl: CGFloat = 64
    }

    // MARK: - Logo Minimum Sizes (from Brand Guidelines)

    struct LogoSize {
        /// Primary horizontal logo minimum: 0.5 inch (80px screen)
        static let minPrimaryHorizontal: CGFloat = 80

        /// Secondary stacked logo minimum: 0.68 inch (80px screen)
        static let minSecondaryStacked: CGFloat = 80

        /// Symbol only minimum: 0.25 inch (20px screen)
        static let minSymbol: CGFloat = 20

        /// Favicon size: 16px
        static let favicon: CGFloat = 16

        /// Standard sizes
        static let small: CGFloat = 100
        static let medium: CGFloat = 150
        static let large: CGFloat = 200
    }
}

// MARK: - Button Styles

struct CoppelPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.coppelCTA)
            .foregroundColor(.primaryTextInverted)
            .padding(.horizontal, CoppelTheme.Spacing.lg)
            .padding(.vertical, CoppelTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CoppelTheme.CornerRadius.lg)
                    .fill(Color.coppelBlue)
            )
            .scaleEffect(CGFloat(configuration.isPressed ? 0.95 : 1.0))
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct CoppelSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.coppelCTA)
            .foregroundColor(.coppelBlue)
            .padding(.horizontal, CoppelTheme.Spacing.lg)
            .padding(.vertical, CoppelTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CoppelTheme.CornerRadius.lg)
                    .stroke(Color.coppelBlue, lineWidth: 2)
            )
            .scaleEffect(CGFloat(configuration.isPressed ? 0.95 : 1.0))
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct CoppelAccentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.coppelCTA)
            .foregroundColor(.coppelDarkBlue)
            .padding(.horizontal, CoppelTheme.Spacing.lg)
            .padding(.vertical, CoppelTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CoppelTheme.CornerRadius.lg)
                    .fill(Color.coppelYellow)
            )
            .scaleEffect(CGFloat(configuration.isPressed ? 0.95 : 1.0))
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Card Style

struct CoppelCardModifier: ViewModifier {
    var backgroundColor: Color = .white
    var hasShadow: Bool = true

    func body(content: Content) -> some View {
        content
            .background(backgroundColor)
            .cornerRadius(CoppelTheme.CornerRadius.lg)
            .shadow(
                color: hasShadow ? Color.black.opacity(0.08) : Color.clear,
                radius: hasShadow ? 8 : 0,
                x: 0,
                y: hasShadow ? 4 : 0
            )
    }
}

extension View {
    func coppelCard(
        backgroundColor: Color = .white,
        hasShadow: Bool = true
    ) -> some View {
        self.modifier(CoppelCardModifier(
            backgroundColor: backgroundColor,
            hasShadow: hasShadow
        ))
    }

    func coppelPrimaryButton() -> some View {
        self.buttonStyle(CoppelPrimaryButtonStyle())
    }

    func coppelSecondaryButton() -> some View {
        self.buttonStyle(CoppelSecondaryButtonStyle())
    }

    func coppelAccentButton() -> some View {
        self.buttonStyle(CoppelAccentButtonStyle())
    }
}

// MARK: - Category Badge

struct CoppelCategoryBadge: View {
    let category: String
    let color: Color

    var body: some View {
        Text(category)
            .font(.coppelCaption)
            .foregroundColor(.white)
            .padding(.horizontal, CoppelTheme.Spacing.sm)
            .padding(.vertical, CoppelTheme.Spacing.xs)
            .background(
                Capsule()
                    .fill(color)
            )
    }
}

// MARK: - Coppel Navigation Bar Style

struct CoppelNavigationBarModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.coppelBlue, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

extension View {
    func coppelNavigationBar() -> some View {
        self.modifier(CoppelNavigationBarModifier())
    }
}


// MARK: - User Role Badge Colors

extension Color {
    static func roleColor(for role: String) -> Color {
        switch role.lowercased() {
        case "comerciante", "merchant":
            return Color.coppelOrange
        case "cliente", "customer":
            return Color.coppelLightBlue
        case "administrador", "admin":
            return Color.coppelDarkBlue
        default:
            return Color.coppelGrey
        }
    }
}
