//
//  INTEGRATION_EXAMPLES.swift
//  Atenea
//
//  Ejemplos de cómo integrar Writing Tools en CommunityView y AISearchView
//  NOTA: Writing Tools funciona automáticamente, estos ejemplos solo agregan hints visuales
//

import SwiftUI

// MARK: - Ejemplo 1: CommunityView Básico (Sin Cambios Necesarios)

/*
 TU CÓDIGO ACTUAL YA FUNCIONA - Writing Tools está disponible automáticamente

 struct CommunityView: View {
     @State private var newPost = ""

     var body: some View {
         TextField("¿Qué está pasando?", text: $newPost)
             // ✅ Writing Tools disponible automáticamente en iOS 18+
     }
 }
*/

// MARK: - Ejemplo 2: CommunityView con Indicadores Visuales (Opcional)

@available(iOS 18.0, *)
struct EnhancedCommunityCreatePost: View {
    @State private var postText = ""
    @State private var showingWritingToolsHelp = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header con badge de Writing Tools
            HStack {
                Text("Crear Post")
                    .font(.headline)

                WritingToolsHelper.availabilityBadge()

                Spacer()

                // Botón de ayuda
                WritingToolsHelper.helpButton {
                    showingWritingToolsHelp = true
                }
            }

            // Campo de texto con Writing Tools automático
            EnhancedTextEditor(
                title: "Tu mensaje",
                text: $postText,
                minHeight: 120
            )

            // Botones de acción
            HStack {
                Button("Cancelar") {
                    postText = ""
                }
                .foregroundColor(.secondary)

                Spacer()

                Button("Publicar") {
                    publishPost(postText)
                }
                .buttonStyle(.borderedProminent)
                .disabled(postText.isEmpty)
            }
        }
        .padding()
        .alert(isPresented: $showingWritingToolsHelp) {
            WritingToolsExplainer.createAlert()
        }
    }

    private func publishPost(_ text: String) {
        // Tu lógica de publicación
        print("📝 Publicando post: \(text)")
    }
}

// MARK: - Ejemplo 3: Simple Integration en CommunityView Existente

struct CommunityViewSimpleEnhancement: View {
    @State private var postText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Tu TextField existente
            TextField("¿Qué está pasando?", text: $postText)
                .textFieldStyle(.roundedBorder)
                .writingToolsHint()  // ✅ Solo agregar este modificador
                // ⬆️ Agrega hint automáticamente en iOS 18+
        }
    }
}

// MARK: - Ejemplo 4: AISearchView Básico (Sin Cambios Necesarios)

/*
 TU CÓDIGO ACTUAL YA FUNCIONA

 struct AISearchView: View {
     @State private var question = ""

     var body: some View {
         TextField("Pregunta algo...", text: $question)
             // ✅ Writing Tools disponible automáticamente en iOS 18+
     }
 }
*/

// MARK: - Ejemplo 5: AISearchView con Indicadores (Opcional)

@available(iOS 18.0, *)
struct EnhancedAISearchView: View {
    @State private var question = ""
    @State private var isAsking = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Pregunta a Claude")
                    .font(.headline)

                WritingToolsHelper.availabilityBadge()

                Spacer()
            }

            // Campo de pregunta con Writing Tools
            EnhancedTextField(
                title: "Tu pregunta",
                text: $question,
                placeholder: "ej: ¿Dónde comer cerca del Azteca?",
                showBadge: false  // Ya mostramos badge arriba
            )

            // Sugerencias rápidas
            VStack(alignment: .leading, spacing: 8) {
                Text("💡 Tip: Mejora tu pregunta con Writing Tools antes de enviar")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                // Quick actions
                HStack {
                    quickActionButton("Hacer más claro", icon: "text.bubble") {
                        // Hint para seleccionar y usar "Rewrite"
                    }

                    quickActionButton("Traducir", icon: "globe") {
                        // Hint para usar "Translate"
                    }
                }
            }

            // Botón enviar
            Button(action: askClaude) {
                HStack {
                    if isAsking {
                        ProgressView()
                            .controlSize(.small)
                    }
                    Text("Preguntar")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(question.isEmpty || isAsking)
        }
        .padding()
    }

    private func quickActionButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.caption)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
    }

    private func askClaude() {
        isAsking = true
        // Tu lógica de Claude API
        print("🤖 Preguntando a Claude: \(question)")
    }
}

// MARK: - Ejemplo 6: Integración Mínima (Recomendado)

/*
 SI NO QUIERES AGREGAR INDICADORES VISUALES, NO HAGAS NADA.
 Writing Tools funciona automáticamente.

 Solo agrega esto si quieres dar hints a los usuarios:
*/

struct MinimalWritingToolsIntegration: View {
    @State private var text = ""

    var body: some View {
        VStack {
            // Opción 1: Agregar solo hint text
            TextField("Escribe aquí", text: $text)
                .writingToolsHint()

            // Opción 2: Agregar solo badge
            TextField("Escribe aquí", text: $text)
                .withWritingToolsBadge()

            // Opción 3: No agregar nada (Writing Tools funciona igual)
            TextField("Escribe aquí", text: $text)
        }
    }
}

// MARK: - Ejemplo 7: Post Editor con Preview

@available(iOS 18.0, *)
struct PostEditorWithPreview: View {
    @State private var postText = ""
    @State private var showPreview = false

    var body: some View {
        VStack(spacing: 16) {
            // Editor
            EnhancedTextEditor(
                title: "Editar Post",
                text: $postText,
                minHeight: 200
            )

            // Toggle preview
            Toggle("Vista previa", isOn: $showPreview)

            if showPreview && !postText.isEmpty {
                // Preview del post
                VStack(alignment: .leading, spacing: 8) {
                    Text("Vista Previa")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(postText)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }

            // Actions
            HStack {
                Button("Cancelar") {
                    postText = ""
                }

                Spacer()

                Button("Publicar") {
                    publishPost()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }

    private func publishPost() {
        print("📝 Publicando: \(postText)")
    }
}

// MARK: - Ejemplo 8: Multi-language Support

@available(iOS 18.0, *)
struct MultiLanguagePostEditor: View {
    @State private var postText = ""
    @State private var detectedLanguage = "es"  // Español por defecto

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header con detección de idioma
            HStack {
                Text("Crear Post")
                    .font(.headline)

                Spacer()

                // Badge de idioma detectado
                HStack(spacing: 4) {
                    Image(systemName: "globe")
                        .font(.caption)
                    Text(languageName(detectedLanguage))
                        .font(.caption)
                }
                .foregroundStyle(.blue)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule().fill(Color.blue.opacity(0.1))
                )
            }

            // Editor
            TextEditor(text: $postText)
                .frame(minHeight: 120)
                .onChange(of: postText) { _ in
                    detectLanguage()
                }

            // Hint con sugerencia de traducción
            if detectedLanguage != "es" {
                HStack(spacing: 4) {
                    Image(systemName: "info.circle")
                        .font(.caption2)
                    Text("Tip: Usa Writing Tools para traducir a español")
                        .font(.caption2)
                }
                .foregroundStyle(.blue)
            } else {
                WritingToolsHelper.hintText()
            }

            Button("Publicar") {
                publishPost()
            }
            .buttonStyle(.borderedProminent)
            .disabled(postText.isEmpty)
        }
        .padding()
    }

    private func detectLanguage() {
        // Lógica de detección de idioma (simplificada)
        // En producción, usar NLLanguageRecognizer
        if postText.contains("the") || postText.contains("is") {
            detectedLanguage = "en"
        } else {
            detectedLanguage = "es"
        }
    }

    private func languageName(_ code: String) -> String {
        switch code {
        case "es": return "Español"
        case "en": return "English"
        case "fr": return "Français"
        default: return code.uppercased()
        }
    }

    private func publishPost() {
        print("📝 Post en \(detectedLanguage): \(postText)")
    }
}

// MARK: - Dónde Integrar en Tu Código

/*
 UBICACIONES RECOMENDADAS:

 1. CommunityView.swift
    - Agregar WritingToolsHelper.hintText() debajo de TextField
    - Opcional: Agregar badge en header

 2. AISearchView.swift / UltraThinkRecommendationsView.swift
    - Agregar hint en el campo de pregunta
    - Mostrar tip sobre mejorar pregunta antes de enviar

 3. RegisterView.swift / LoginView.swift
    - No es necesario agregar nada
    - Writing Tools funcionará automáticamente

 4. CUALQUIER TextField o TextEditor
    - Writing Tools funciona automáticamente
    - Solo agrega hints si quieres educar al usuario

 RECUERDA:
 - Writing Tools es 100% automático en iOS 18+
 - Los hints son OPCIONALES
 - Los ejemplos aquí son para mejorar UX, no son requeridos
*/
