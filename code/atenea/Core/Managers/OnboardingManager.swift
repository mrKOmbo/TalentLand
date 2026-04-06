//
//  OnboardingManager.swift
//  Atenea
//
//  Manager for in-app tutorial and onboarding
//

import Foundation
internal import Combine
import SwiftUI

class OnboardingManager: ObservableObject {
    static let shared = OnboardingManager()

    // Tutorial state
    @Published var currentHint: TutorialHint?
    @Published var currentStepIndex: Int = 0
    @Published var isShowingTutorial: Bool = false

    // Completion tracking
    @Published var hasCompletedInAppTutorial: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedInAppTutorial, forKey: Keys.hasCompletedInAppTutorial)
        }
    }

    @Published var completedSteps: Set<String> {
        didSet {
            if let data = try? JSONEncoder().encode(completedSteps) {
                UserDefaults.standard.set(data, forKey: Keys.completedSteps)
            }
        }
    }

    private struct Keys {
        static let hasCompletedInAppTutorial = "hasCompletedInAppTutorial"
        static let completedSteps = "completedTutorialSteps"
    }

    private init() {
        // Load saved values
        self.hasCompletedInAppTutorial = UserDefaults.standard.bool(forKey: Keys.hasCompletedInAppTutorial)

        // Load completed steps
        if let data = UserDefaults.standard.data(forKey: Keys.completedSteps),
           let steps = try? JSONDecoder().decode(Set<String>.self, from: data) {
            self.completedSteps = steps
        } else {
            self.completedSteps = []
        }
    }

    // MARK: - Public Methods

    /// Check if in-app tutorial should be shown
    func shouldShowInAppTutorial() -> Bool {
        return !hasCompletedInAppTutorial
    }

    /// Start the in-app tutorial
    func startTutorial() {
        guard !hasCompletedInAppTutorial else { return }
        currentStepIndex = 0
        isShowingTutorial = true
    }

    /// Show specific hint
    func showHint(_ hint: TutorialHint) {
        currentHint = hint
        isShowingTutorial = true
    }

    /// Advance to next tutorial step
    func nextStep() {
        // Mark current step as completed
        if let currentHint = currentHint {
            completedSteps.insert(currentHint.id)
        }

        // Clear current hint
        currentHint = nil

        // Advance index
        currentStepIndex += 1
    }

    /// Dismiss tutorial completely
    func dismissTutorial() {
        isShowingTutorial = false
        currentHint = nil
        hasCompletedInAppTutorial = true

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    /// Check if specific step is completed
    func isStepCompleted(_ stepId: String) -> Bool {
        return completedSteps.contains(stepId)
    }

    /// Reset tutorial (for testing/debugging)
    func resetTutorial() {
        hasCompletedInAppTutorial = false
        completedSteps.removeAll()
        currentStepIndex = 0
        currentHint = nil
        isShowingTutorial = false
    }
}

