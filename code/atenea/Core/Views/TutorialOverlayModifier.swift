//
//  TutorialOverlayModifier.swift
//  Atenea
//
//  ViewModifier to add tutorial overlay to any view
//

import SwiftUI

struct TutorialOverlayModifier: ViewModifier {
    @ObservedObject var tutorialManager = OnboardingManager.shared

    func body(content: Content) -> some View {
        ZStack {
            content

            // Tutorial overlay
            if tutorialManager.isShowingTutorial,
               let hint = tutorialManager.currentHint {
                TutorialSpotlightView(
                    hint: hint,
                    onNext: {
                        tutorialManager.nextStep()
                    },
                    onDismiss: {
                        tutorialManager.dismissTutorial()
                    }
                )
                .zIndex(9999)
                .transition(.opacity)
            }
        }
    }
}

extension View {
    /// Add tutorial overlay to this view
    func tutorialOverlay() -> some View {
        modifier(TutorialOverlayModifier())
    }
}
