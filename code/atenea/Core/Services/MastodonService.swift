//
//  MastodonService.swift
//  atenea
//
//  Fetches posts from Mastodon public API for the community feed.
//

import Foundation
internal import Combine

class MastodonService: ObservableObject {
    static let shared = MastodonService()

    @Published var posts: [CommunityPost] = []
    @Published var isLoading = false

    private let accountId = "115404144567445060"
    private let baseURL = "https://mastodon.social/api/v1"

    private init() {}

    /// Preloads posts at app launch
    func preload() {
        Task {
            await refresh()
        }
    }

    /// Refreshes posts from Mastodon (call from pull-to-refresh or manual reload)
    @MainActor
    func refresh() async {
        isLoading = true
        do {
            posts = try await fetchPosts()
        } catch {
            print("Error loading Mastodon posts: \(error)")
        }
        isLoading = false
    }

    /// Fetches the latest posts from @m_de_milo@mastodon.social
    func fetchPosts(limit: Int = 20) async throws -> [CommunityPost] {
        let urlString = "\(baseURL)/accounts/\(accountId)/statuses?limit=\(limit)&exclude_replies=true&exclude_reblogs=true"
        guard let url = URL(string: urlString) else { return [] }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            return []
        }

        let statuses = try JSONDecoder().decode([MastodonStatus].self, from: data)

        return statuses.enumerated().compactMap { index, status in
            let cleanContent = status.cleanedContent
            guard !cleanContent.isEmpty else { return nil }

            let imageURL = status.media_attachments.first(where: { $0.type == "image" })?.url
                ?? status.media_attachments.first(where: { $0.type == "image" })?.preview_url
                ?? ""

            return CommunityPost(
                id: 900_000 + index,
                source: "Mastodon",
                url: status.url ?? "",
                author: status.account.display_name.isEmpty ? status.account.username : status.account.display_name,
                image: imageURL,
                likes: status.favourites_count,
                title: String(cleanContent.prefix(100)),
                content: cleanContent,
                date: status.created_at,
                keywords: "mastodon, creator, mainuser"
            )
        }
    }
}

// MARK: - Mastodon API Models

struct MastodonStatus: Codable {
    let id: String
    let created_at: String
    let content: String
    let url: String?
    let favourites_count: Int
    let reblogs_count: Int
    let account: MastodonAccount
    let media_attachments: [MastodonMediaAttachment]

    var cleanedContent: String {
        content
            .replacingOccurrences(of: "<p>", with: "")
            .replacingOccurrences(of: "</p>", with: "\n")
            .replacingOccurrences(of: "<br>", with: "\n")
            .replacingOccurrences(of: "<br/>", with: "\n")
            .replacingOccurrences(of: "<br />", with: "\n")
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct MastodonAccount: Codable {
    let id: String
    let username: String
    let display_name: String
    let avatar: String
}

struct MastodonMediaAttachment: Codable {
    let id: String
    let type: String
    let url: String?
    let preview_url: String?
}
