//
//  CoppelTypography.swift
//  atenea
//
//  Coppel Typography System - Brand Toolkit 2024
//  Primary: Reckless Neue (serif), Sharp Sans Display No. 2 (sans-serif), Monosten (monospace)
//  Fallbacks: SF Pro (system), Helvetica Neue
//

import SwiftUI

// MARK: - Font Family Names

extension Font {
    // MARK: - Coppel Primary Typefaces

    /// Reckless Neue - Serif typeface for headlines
    /// Provides robust yet elegant voice in highly legible, contemporary typeface
    static func recklessMedium(size: CGFloat) -> Font {
        return Font.custom("RecklessNeue-Medium", size: size)
    }

    static func recklessMediumItalic(size: CGFloat) -> Font {
        return Font.custom("RecklessNeue-MediumItalic", size: size)
    }

    static func recklessBold(size: CGFloat) -> Font {
        return Font.custom("RecklessNeue-Bold", size: size)
    }

    static func recklessBoldItalic(size: CGFloat) -> Font {
        return Font.custom("RecklessNeue-BoldItalic", size: size)
    }

    static func recklessBook(size: CGFloat) -> Font {
        return Font.custom("RecklessNeue-Book", size: size)
    }

    /// Sharp Sans Display No. 2 - Geometric sans-serif
    /// Friendly yet personable typeface based on circles
    static func sharpSansMedium(size: CGFloat) -> Font {
        return Font.custom("SharpSansDispNo2-Medium", size: size)
    }

    static func sharpSansBold(size: CGFloat) -> Font {
        return Font.custom("SharpSansDispNo2-Bold", size: size)
    }

    static func sharpSansMediumOblique(size: CGFloat) -> Font {
        return Font.custom("SharpSansDispNo2-MediumObl", size: size)
    }

    static func sharpSansBoldOblique(size: CGFloat) -> Font {
        return Font.custom("SharpSansDispNo2-BoldObl", size: size)
    }

    /// Monosten - Monospaced typeface with humanistic qualities
    static func monosten(size: CGFloat) -> Font {
        return Font.custom("MonostenPro-Regular", size: size)
    }

    // MARK: - Fallback Options (when brand fonts unavailable)

    /// System fallback - Playfair Display (Google Font equivalent to Reckless)
    static func playfairMedium(size: CGFloat) -> Font {
        return Font.custom("PlayfairDisplay-Medium", size: size)
    }

    /// System fallback - Poppins (Google Font equivalent to Sharp Sans)
    static func poppinsRegular(size: CGFloat) -> Font {
        return Font.custom("Poppins-Regular", size: size)
    }

    static func poppinsSemiBold(size: CGFloat) -> Font {
        return Font.custom("Poppins-SemiBold", size: size)
    }
}

// MARK: - Coppel Typography Scale

extension Font {
    /// Headline - Reckless Medium
    /// Leading: 100% of type size | Tracking: -15
    /// Color: Dark Blue
    static let coppelHeadline = Font.recklessMedium(size: 34)
        .weight(.medium)

    static let coppelHeadlineLarge = Font.recklessMedium(size: 48)
        .weight(.medium)

    static let coppelHeadlineSmall = Font.recklessMedium(size: 28)
        .weight(.medium)

    /// Header 2 - Sharp Sans Bold
    /// Leading: 120% of type size
    static let coppelHeader = Font.sharpSansBold(size: 24)

    /// Subheader - Sharp Sans Bold
    /// Leading: 120% of type size
    static let coppelSubheader = Font.sharpSansBold(size: 18)

    /// Body - Sharp Sans Medium
    /// Leading: 120-140% of type size
    /// Color: Dark Blue
    static let coppelBody = Font.sharpSansMedium(size: 16)

    static let coppelBodyLarge = Font.sharpSansMedium(size: 18)

    static let coppelBodySmall = Font.sharpSansMedium(size: 14)

    /// CTA (Call to Action) - Sharp Sans Bold
    /// Leading: 120% of type size
    static let coppelCTA = Font.sharpSansBold(size: 16)

    /// Eyebrow - Monosten
    /// Sentence case | Leading: 120% of type size
    static let coppelEyebrow = Font.monosten(size: 12)

    /// Metadata - Monosten
    /// Title case | Size: 9pt minimum | Leading: 120%
    /// Color: Dark Blue
    static let coppelMetadata = Font.monosten(size: 10)

    /// Callout - Sharp Sans Medium Oblique
    static let coppelCallout = Font.sharpSansMediumOblique(size: 16)

    /// Caption - Sharp Sans Medium
    static let coppelCaption = Font.sharpSansMedium(size: 12)
}

// MARK: - Fallback Typography (System Fonts)

extension Font {
    /// System fallback for headlines when brand fonts unavailable
    static let coppelHeadlineSystem = Font.system(size: 34, weight: .medium, design: .serif)

    /// System fallback for headers
    static let coppelHeaderSystem = Font.system(size: 24, weight: .bold, design: .default)

    /// System fallback for body
    static let coppelBodySystem = Font.system(size: 16, weight: .medium, design: .default)

    /// System fallback for CTA
    static let coppelCTASystem = Font.system(size: 16, weight: .bold, design: .default)

    /// System fallback for metadata
    static let coppelMetadataSystem = Font.system(size: 10, weight: .regular, design: .monospaced)
}

// MARK: - Text Styles with Tracking

struct CoppelTextStyle {
    let font: Font
    let tracking: CGFloat
    let lineSpacing: CGFloat

    static let headline = CoppelTextStyle(
        font: .coppelHeadline,
        tracking: -0.5,
        lineSpacing: 0
    )

    static let header = CoppelTextStyle(
        font: .coppelHeader,
        tracking: 0,
        lineSpacing: 4.8
    )

    static let subheader = CoppelTextStyle(
        font: .coppelSubheader,
        tracking: 0,
        lineSpacing: 3.6
    )

    static let body = CoppelTextStyle(
        font: .coppelBody,
        tracking: 0,
        lineSpacing: 3.2
    )

    static let cta = CoppelTextStyle(
        font: .coppelCTA,
        tracking: 0,
        lineSpacing: 3.2
    )

    static let eyebrow = CoppelTextStyle(
        font: .coppelEyebrow,
        tracking: 0,
        lineSpacing: 2.4
    )

    static let metadata = CoppelTextStyle(
        font: .coppelMetadata,
        tracking: 0,
        lineSpacing: 2.0
    )
}

// MARK: - View Modifier for Coppel Typography

struct CoppelTypographyModifier: ViewModifier {
    let style: CoppelTextStyle

    func body(content: Content) -> some View {
        content
            .font(style.font)
            .tracking(style.tracking)
            .lineSpacing(style.lineSpacing)
    }
}

extension View {
    func coppelTypography(_ style: CoppelTextStyle) -> some View {
        self.modifier(CoppelTypographyModifier(style: style))
    }

    func coppelHeadline() -> some View {
        self.modifier(CoppelTypographyModifier(style: .headline))
    }

    func coppelHeader() -> some View {
        self.modifier(CoppelTypographyModifier(style: .header))
    }

    func coppelBody() -> some View {
        self.modifier(CoppelTypographyModifier(style: .body))
    }

    func coppelCTA() -> some View {
        self.modifier(CoppelTypographyModifier(style: .cta))
    }
}
