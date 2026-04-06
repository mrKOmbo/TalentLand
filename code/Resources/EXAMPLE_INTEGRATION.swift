//
//  EXAMPLE_INTEGRATION.swift
//  Atenea
//
//  Ejemplo de cómo integrar el tutorial in-app en MainMapView
//  NO COMPILAR ESTE ARCHIVO - Solo referencia
//

import SwiftUI

/*

 PASO 1: Agregar @StateObject para el tutorial manager

*/

struct MainMapView: View {
    @Binding var selectedTab: Int
    @Binding var isLoggedIn: Bool

    // ⭐ Agregar esto
    @StateObject private var tutorialManager = OnboardingManager.shared

    // ⭐ Estados para guardar posiciones de elementos
    @State private var menuButtonFrame: CGRect = .zero
    @State private var searchButtonFrame: CGRect = .zero
    @State private var emergencyButtonFrame: CGRect = .zero

    // ⭐ Array de pasos del tutorial
    @State private var tutorialSteps: [TutorialHint] = []

    var body: some View {
        ZStack {
            // Tu contenido normal aquí...

            /*

             PASO 2: Capturar posiciones de elementos importantes
             Ejemplo con el botón de menú:

            */

            VStack {
                HStack {
                    Button(action: openMenu) {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
                    }
                    // ⭐ Agregar esto para capturar posición
                    .background(
                        GeometryReader { geometry in
                            Color.clear.preference(
                                key: ViewFrameKey.self,
                                value: geometry.frame(in: .global)
                            )
                        }
                    )
                    .onPreferenceChange(ViewFrameKey.self) { frame in
                        menuButtonFrame = frame
                    }

                    Spacer()
                }
                Spacer()
            }
        }
        // ⭐ PASO 3: Agregar el modifier del tutorial
        .tutorialOverlay()

        // ⭐ PASO 4: Observar cambios en el índice del tutorial
        .onChange(of: tutorialManager.currentStepIndex) { newIndex in
            showNextHint(at: newIndex)
        }

        // ⭐ PASO 5: Iniciar tutorial al aparecer
        .onAppear {
            // Delay para asegurar que las posiciones estén listas
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if tutorialManager.shouldShowInAppTutorial() {
                    prepareTutorialSteps()
                    tutorialManager.startTutorial()
                }
            }
        }
    }

    /*

     PASO 6: Funciones auxiliares

    */

    private func prepareTutorialSteps() {
        tutorialSteps = [
            // Hint 1: Botón de menú
            TutorialHint(
                id: TutorialStep.menuButton.rawValue,
                title: TutorialStep.menuButton.localizedTitle,
                description: TutorialStep.menuButton.localizedDescription,
                position: menuButtonFrame,
                arrowDirection: .down,  // Flecha apuntando hacia abajo
                textPosition: .bottom   // Texto debajo del elemento
            ),

            // Hint 2: Botón de búsqueda
            TutorialHint(
                id: TutorialStep.searchButton.rawValue,
                title: TutorialStep.searchButton.localizedTitle,
                description: TutorialStep.searchButton.localizedDescription,
                position: searchButtonFrame,
                arrowDirection: .down,
                textPosition: .bottom
            ),

            // Hint 3: Botón de emergencia
            TutorialHint(
                id: TutorialStep.emergencyButton.rawValue,
                title: TutorialStep.emergencyButton.localizedTitle,
                description: TutorialStep.emergencyButton.localizedDescription,
                position: emergencyButtonFrame,
                arrowDirection: .down,
                textPosition: .bottom
            ),

            // Agregar más hints según necesites...
        ]
    }

    private func showNextHint(at index: Int) {
        guard index < tutorialSteps.count else {
            // Tutorial completado
            tutorialManager.dismissTutorial()
            return
        }

        // Mostrar siguiente hint
        tutorialManager.showHint(tutorialSteps[index])
    }

    private func openMenu() {
        // Tu código del menú
    }
}

/*

 PASO 7: ViewFrameKey helper (agregar a tu proyecto)

*/

struct ViewFrameKey: PreferenceKey {
    static var defaultValue: CGRect = .zero

    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

/*

 ALTERNATIVA MÁS SIMPLE (sin PreferenceKey):
 Usar GeometryReader con onAppear

*/

struct SimplerExample: View {
    @State private var buttonFrame: CGRect = .zero

    var body: some View {
        Button(action: {}) {
            Text("Click me")
        }
        .background(
            GeometryReader { geometry in
                Color.clear.onAppear {
                    // ⚠️ Importante: Usar DispatchQueue.main.async
                    DispatchQueue.main.async {
                        buttonFrame = geometry.frame(in: .global)
                    }
                }
            }
        )
    }
}

/*

 BOTÓN DE DEBUG (opcional):
 Agregar durante desarrollo para resetear el tutorial

*/

#if DEBUG
struct DebugTutorialButton: View {
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button("Reset Tutorial") {
                    OnboardingManager.shared.resetTutorial()
                    print("✅ Tutorial reset - Restart app to see it again")
                }
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(8)
                .padding()
            }
        }
    }
}
#endif

/*

 RESULTADO ESPERADO:

 1. Usuario abre la app por primera vez
 2. Aparece overlay oscuro
 3. Botón de menú resaltado con círculo brillante
 4. Tarjeta con texto explicativo abajo
 5. Usuario presiona "Next" → siguiente hint
 6. Repite hasta completar todos los hints
 7. Tutorial no se vuelve a mostrar

*/

/*

 TIPS:

 ✅ Usar delay de 0.5s en .onAppear para asegurar frames listos
 ✅ Verificar que frames no sean .zero antes de crear hints
 ✅ Máximo 5-7 hints para no abrumar al usuario
 ✅ Agregar botón de debug para testing
 ✅ Probar en diferentes tamaños de pantalla

 ❌ No capturar frames de elementos que no son visibles
 ❌ No crear hints antes de que la vista se renderice
 ❌ No olvidar agregar .tutorialOverlay()

*/
