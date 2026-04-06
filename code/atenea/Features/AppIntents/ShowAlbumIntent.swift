//
//  ShowAlbumIntent.swift
//  Atenea
//
//  Intent to show the sticker album and collection progress
//  Usage: "Hey Siri, show my album in Atenea"
//         "Hey Siri, how many stickers do I have in Atenea?"
//

import Foundation
import AppIntents
import SwiftUI

/// Intent to open the sticker album
struct ShowAlbumIntent: AppIntent {
    static var title: LocalizedStringResource = "View My Album"
    static var description = IntentDescription("Show your 2026 World Cup sticker album")

    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Mark that we want to open the album directly
        UserDefaults.standard.set(true, forKey: "shouldOpenAlbum")

        print("📖 [APP INTENT] Album opening requested")

        return .result(
            dialog: IntentDialog(stringLiteral: "Opening your sticker album. Let's see your collection!")
        )
    }
}

/// Intent to get collection progress
struct GetCollectionProgressIntent: AppIntent {
    static var title: LocalizedStringResource = "Collection Progress"
    static var description = IntentDescription("Show how many stickers you have collected")

    static var openAppWhenRun: Bool = false // Does not need to open the app

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        // Get progress from UserDefaults or manager
        let collectedCount = UserDefaults.standard.integer(forKey: "totalCollectedStickers")
        let totalStickers = 672 // Total stickers in the album (calculated from AlbumDataGenerator)

        let percentage = totalStickers > 0 ? (Double(collectedCount) / Double(totalStickers)) * 100 : 0

        let message: String
        if collectedCount == 0 {
            message = "You haven't collected any stickers yet. Visit a stadium to get started!"
        } else if percentage >= 100 {
            message = "Congratulations! You've completed your album with \(totalStickers) stickers. Amazing!"
        } else {
            message = "You have collected \(collectedCount) of \(totalStickers) stickers. You're \(Int(percentage))% complete."
        }

        print("📊 [APP INTENT] Progress checked: \(collectedCount)/\(totalStickers)")

        return .result(
            dialog: IntentDialog(stringLiteral: message),
            view: CollectionProgressView(
                collected: collectedCount,
                total: totalStickers,
                percentage: percentage
            )
        )
    }
}

/// Intent to know how many stickers are missing
struct MissingStickersIntent: AppIntent {
    static var title: LocalizedStringResource = "Missing Stickers"
    static var description = IntentDescription("Show how many stickers you're missing")

    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let collectedCount = UserDefaults.standard.integer(forKey: "totalCollectedStickers")
        let totalStickers = 672
        let missing = max(0, totalStickers - collectedCount)

        let message: String
        if missing == 0 {
            message = "Perfect! You're not missing any stickers. You've completed your 2026 World Cup album."
        } else if missing == totalStickers {
            message = "You're missing all \(totalStickers) stickers. Start your collection by visiting stadiums!"
        } else {
            message = "You're missing \(missing) stickers to complete your 2026 World Cup album."
        }

        print("📊 [APP INTENT] Missing stickers: \(missing)")

        return .result(dialog: IntentDialog(stringLiteral: message))
    }
}

// MARK: - Snippet View para mostrar progreso

struct CollectionProgressView: View {
    let collected: Int
    let total: Int
    let percentage: Double

    var body: some View {
        VStack(spacing: 12) {
            // Barra de progreso
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 20)

                    // Progreso
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * (percentage / 100), height: 20)
                }
            }
            .frame(height: 20)

            // Texto del progreso
            HStack {
                Text("\(collected)/\(total)")
                    .font(.headline)
                Spacer()
                Text("\(Int(percentage))%")
                    .font(.headline)
                    .foregroundColor(.blue)
            }
        }
        .padding()
    }
}
