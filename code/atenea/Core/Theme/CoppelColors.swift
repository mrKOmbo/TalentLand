//
//  CoppelColors.swift
//  atenea
//
//  Coppel Brand Colors - Brand Toolkit 2024
//

import SwiftUI

extension Color {
    // MARK: - Primary Palette

    /// Coppel Blue - Primary brand color
    /// RGB: 28, 66, 232 | HEX: #1C42E8 | PANTONE: 2387 C
    static let coppelBlue = Color(hex: "1C42E8")

    /// Coppel Yellow - Primary brand color
    /// RGB: 240, 210, 36 | HEX: #F0D224 | PANTONE: 7405 C
    static let coppelYellow = Color(hex: "F0D224")

    /// Dark Blue - Primary palette
    /// RGB: 8, 23, 84 | HEX: #081754 | PANTONE: 2768 C
    static let coppelDarkBlue = Color(hex: "081754")

    /// Medium Blue (BanCoppel)
    /// RGB: 5, 41, 122 | HEX: #05297A | PANTONE: 661 C
    static let coppelMediumBlue = Color(hex: "05297A")

    /// Light Blue
    /// RGB: 37, 172, 245 | HEX: #1CA8F7 | PANTONE: 2925 C
    static let coppelLightBlue = Color(hex: "1CA8F7")

    // MARK: - Secondary Palette - Greens

    /// Lime
    /// RGB: 136, 255, 77 | HEX: #F8DE14 | PANTONE: 902 C
    static let coppelLime = Color(hex: "88FF4D")

    /// Green
    /// RGB: 10, 191, 79 | HEX: #0ABF4F | PANTONE: 7481 C
    static let coppelGreen = Color(hex: "0ABF4F")

    /// Dark Green
    /// RGB: 0, 94, 62 | HEX: #005E3E | PANTONE: 7728 C
    static let coppelDarkGreen = Color(hex: "005E3E")

    // MARK: - Secondary Palette - Purples

    /// Pink
    /// RGB: 253, 161, 251 | HEX: #FDA1FB | PANTONE: 244 C
    static let coppelPink = Color(hex: "FDA1FB")

    /// Purple
    /// RGB: 125, 66, 255 | HEX: #7D42FF | PANTONE: 2089 C
    static let coppelPurple = Color(hex: "7D42FF")

    /// Dark Purple
    /// RGB: 76, 4, 178 | HEX: #4C04B2 | PANTONE: 2091 C
    static let coppelDarkPurple = Color(hex: "4C04B2")

    // MARK: - Secondary Palette - Reds

    /// Red
    /// RGB: 255, 89, 77 | HEX: #FF594D | PANTONE: 1787 C
    static let coppelRed = Color(hex: "FF594D")

    /// Crimson
    /// RGB: 122, 38, 39 | HEX: #7A2627 | PANTONE: 1815 C
    static let coppelCrimson = Color(hex: "7A2627")

    /// Orange
    /// RGB: 255, 174, 67 | HEX: #FFAE43 | PANTONE: 136 C
    static let coppelOrange = Color(hex: "FFAE43")

    // MARK: - Secondary Palette - Neutrals

    /// Brown
    /// RGB: 102, 69, 29 | HEX: #66451D | PANTONE: 1405 C
    static let coppelBrown = Color(hex: "66451D")

    /// Tan
    /// RGB: 185, 155, 123 | HEX: #B99B7B | PANTONE: 2316 C
    static let coppelTan = Color(hex: "B99B7B")

    /// Beige
    /// RGB: 238, 232, 227 | HEX: #EEE8E3 | PANTONE: Warm Gray 1 C
    static let coppelBeige = Color(hex: "EEE8E3")

    /// Light Grey
    /// RGB: 201, 201, 201 | HEX: #C9C9C9 | PANTONE: Cool Gray 4 C
    static let coppelLightGrey = Color(hex: "C9C9C9")

    /// Grey
    /// RGB: 140, 140, 140 | HEX: #8C8C8C | PANTONE: Cool Gray 8 C
    static let coppelGrey = Color(hex: "8C8C8C")

    /// Dark Grey
    /// RGB: 73, 73, 73 | HEX: #4A4A4A | PANTONE: Cool Gray 11 C
    static let coppelDarkGrey = Color(hex: "4A4A4A")

    // MARK: - Semantic Colors

    /// Primary background color
    static let primaryBackground = coppelBlue

    /// Secondary background color
    static let secondaryBackground = Color.white

    /// Primary text color on light backgrounds
    static let primaryText = coppelDarkBlue

    /// Primary text color on dark backgrounds
    static let primaryTextInverted = Color.white

    /// Accent color for CTAs and highlights
    static let accent = coppelYellow

    /// Success state color
    static let success = coppelGreen

    /// Warning state color
    static let warning = coppelOrange

    /// Error state color
    static let error = coppelRed

    /// Info state color
    static let info = coppelLightBlue
}

// MARK: - Category Colors

extension Color {
    /// Category color assignments per Coppel Brand Guidelines
    enum CoppelCategory {
        static let muebles = Color.coppelBrown
        static let zapateria = Color.coppelTan
        static let deportes = Color.coppelDarkGreen
        static let celulares = Color.coppelGreen
        static let juguetes = Color.coppelOrange
        static let mascotas = Color.coppelCrimson
        static let ropa = Color.coppelDarkPurple
        static let motos = Color.coppelGrey
        static let banCoppel = Color.coppelMediumBlue
        static let cajas = Color.coppelYellow
        static let libros = Color.coppelBeige
        static let lineaBlanca = Color.coppelLightGrey
        static let cocina = Color.coppelDarkGrey
        static let electronica = Color.coppelLime
        static let bebesNinos = Color.coppelPink
        static let accesorios = Color.coppelRed
        static let belleza = Color.coppelPurple
        static let ferreteria = Color.coppelGrey
        static let servicios = Color.coppelLightBlue
        static let servicioCliente = Color.coppelYellow
    }
}

// MARK: - Gradients

extension LinearGradient {
    /// Dark Blue to Light Blue gradient
    static let coppelBlueGradient = LinearGradient(
        colors: [Color.coppelDarkBlue, Color.coppelMediumBlue, Color.coppelBlue, Color.coppelLightBlue],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Full spectrum gradient (Blue to Yellow)
    static let coppelFullSpectrum = LinearGradient(
        colors: [
            Color.coppelBlue,
            Color.coppelLightBlue,
            Color.coppelGreen,
            Color.coppelLime,
            Color.coppelYellow
        ],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Warm gradient (Lime to Red)
    static let coppelWarmGradient = LinearGradient(
        colors: [
            Color.coppelLime,
            Color.coppelYellow,
            Color.coppelOrange,
            Color.coppelRed
        ],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Vibrant gradient (Orange to Purple)
    static let coppelVibrantGradient = LinearGradient(
        colors: [
            Color.coppelOrange,
            Color.coppelRed,
            Color.coppelPink,
            Color.coppelPurple,
            Color.coppelDarkPurple
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
}
