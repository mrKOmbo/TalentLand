//
//  PostModels.swift
//  Atenea
//
//  Created for Community Posts Integration
//

import Foundation

// MARK: - Post Response
struct PostsResponse: Codable {
    let posts: [CommunityPost]
}

// MARK: - Main User Response
struct MainUserResponse: Codable {
    let posts: [MainUserPost]
}

// MARK: - Main User Post (from /api/main_user)
struct MainUserPost: Codable {
    let mastodon_id: String?
    let author: String
    let image: String
    let date: String
    let id: Int
    let content: String
    let url: String
    let processed: Bool?

    // Convertir a CommunityPost para compatibilidad
    func toCommunityPost() -> CommunityPost {
        // Limpiar el contenido HTML
        let cleanedContent = content
            .replacingOccurrences(of: "<p>", with: "")
            .replacingOccurrences(of: "</p>", with: "")
            .replacingOccurrences(of: "<br>", with: "\n")
            .replacingOccurrences(of: "<br/>", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return CommunityPost(
            id: id,
            source: "Mastodon",
            url: url,
            author: author,
            image: image,
            likes: 0, // Main user posts no tienen likes inicialmente
            title: cleanedContent, // Usar el contenido como título
            content: cleanedContent,
            date: date,
            keywords: "mastodon, creator, mainuser"
        )
    }
}

// MARK: - Community Post
struct CommunityPost: Codable, Identifiable {
    let id: Int
    let source: String
    let url: String
    let author: String
    let image: String
    let likes: Int
    let title: String
    let content: String
    let date: String
    let keywords: String

    // Backwards compatibility
    var username: String { author }
    var caption: String { content }

    var keywordArray: [String] {
        keywords.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
    }

    var formattedDate: String {
        // Try different date formats
        let isoFormatter = ISO8601DateFormatter()
        var postDate: Date?

        // Try with Z suffix (standard ISO8601)
        postDate = isoFormatter.date(from: date)

        // If that fails, try without Z
        if postDate == nil {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            postDate = dateFormatter.date(from: date)
        }

        guard let postDate = postDate else {
            return "Hace tiempo"
        }

        let now = Date()
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: postDate, to: now)

        if let years = components.year, years > 0 {
            return "Hace \(years) año\(years == 1 ? "" : "s")"
        } else if let months = components.month, months > 0 {
            return "Hace \(months) mes\(months == 1 ? "" : "es")"
        } else if let days = components.day, days > 0 {
            return "Hace \(days) día\(days == 1 ? "" : "s")"
        } else if let hours = components.hour, hours > 0 {
            return "Hace \(hours) hora\(hours == 1 ? "" : "s")"
        } else if let minutes = components.minute, minutes > 0 {
            return "Hace \(minutes) minuto\(minutes == 1 ? "" : "s")"
        } else {
            return "Justo ahora"
        }
    }
}
