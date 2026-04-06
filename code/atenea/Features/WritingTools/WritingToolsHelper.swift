//
//  WritingToolsHelper.swift
//  Atenea
//
//  Helper opcional para agregar indicadores visuales de Writing Tools
//  NOTA: Writing Tools funciona automáticamente sin este helper
//

import SwiftUI

/// Helper para agregar indicadores visuales de Writing Tools
struct WritingToolsHelper {

    /// Verifica si Writing Tools está disponible en el dispositivo
    static var isAvailable: Bool {
        if #available(iOS 18.0, *) {
            return true
        }
        return false
    }

    /// Badge visual indicando que Writing Tools está disponible
    @available(iOS 18.0, *)
    static func availabilityBadge() -> some View {
        Label("AI Writing", systemImage: "wand.and.stars")
            .font(.caption)
            .foregroundStyle(.blue)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color.blue.opacity(0.1))
            )
    }

    /// Hint text para informar al usuario
    @available(iOS 18.0, *)
    static func hintText(_ message: String = "Selecciona texto para usar Writing Tools") -> some View {
        HStack(spacing: 4) {
            Image(systemName: "sparkles")
                .font(.caption2)
            Text(message)
                .font(.caption2)
        }
        .foregroundStyle(.secondary)
    }

    /// Botón de ayuda que explica Writing Tools
    @available(iOS 18.0, *)
    static func helpButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: "questionmark.circle")
                .foregroundStyle(.blue)
        }
    }
}

// MARK: - View Extension para fácil integración

extension View {
    /// Agrega un hint de Writing Tools debajo del campo de texto
    @ViewBuilder
    func writingToolsHint(_ message: String = "Selecciona texto para mejorar con AI") -> some View {
        if #available(iOS 18.0, *) {
            VStack(alignment: .leading, spacing: 4) {
                self
                WritingToolsHelper.hintText(message)
            }
        } else {
            self
        }
    }

    /// Agrega un badge de Writing Tools al lado del campo
    @ViewBuilder
    func withWritingToolsBadge() -> some View {
        if #available(iOS 18.0, *) {
            HStack {
                self
                WritingToolsHelper.availabilityBadge()
            }
        } else {
            self
        }
    }
}

// MARK: - Custom TextField con indicadores de Writing Tools

/// TextField mejorado con indicadores visuales de Writing Tools
@available(iOS 18.0, *)
struct EnhancedTextField: View {
    let title: String
    @Binding var text: String
    var placeholder: String = ""
    var showBadge: Bool = true
    var showHint: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header con título y badge
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if showBadge {
                    WritingToolsHelper.availabilityBadge()
                }

                Spacer()
            }

            // TextField
            TextField(placeholder.isEmpty ? title : placeholder, text: $text)
                .textFieldStyle(.roundedBorder)

            // Hint
            if showHint && text.isEmpty {
                WritingToolsHelper.hintText()
            }
        }
    }
}

/// TextEditor mejorado con indicadores visuales de Writing Tools
@available(iOS 18.0, *)
struct EnhancedTextEditor: View {
    let title: String
    @Binding var text: String
    var minHeight: CGFloat = 120
    var showBadge: Bool = true
    var showHint: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if showBadge {
                    WritingToolsHelper.availabilityBadge()
                }

                Spacer()

                // Character count
                if !text.isEmpty {
                    Text("\(text.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // TextEditor
            TextEditor(text: $text)
                .frame(minHeight: minHeight)
                .scrollContentBackground(.hidden)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )

            // Hint
            if showHint {
                WritingToolsHelper.hintText("Selecciona texto para reescribir, corregir o traducir")
            }
        }
    }
}

// MARK: - Alert Helper para explicar Writing Tools

@available(iOS 18.0, *)
struct WritingToolsExplainer {
    static func createAlert() -> Alert {
        Alert(
            title: Text("✨ Writing Tools"),
            message: Text("""
            Selecciona cualquier texto y usa las herramientas de IA para:

            • Reescribir con diferentes tonos
            • Corregir ortografía y gramática
            • Resumir texto largo
            • Traducir a otros idiomas

            Busca el botón ✨ en tu teclado.
            """),
            dismissButton: .default(Text("Entendido"))
        )
    }
}
