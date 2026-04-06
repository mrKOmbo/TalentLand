//
//  PostService.swift
//  Atenea
//
//  Service for fetching community posts from API
//

import Foundation
internal import Combine

@MainActor
class PostService: ObservableObject {
    @Published var posts: [CommunityPost] = []
    @Published var mainUserPosts: [CommunityPost] = []
    @Published var isLoading = false
    @Published var isSyncing = false
    @Published var errorMessage: String?
    @Published var lastSyncDate: Date?

    private let baseURL = "https://api.ks32.dev"

    // Singleton para uso compartido
    static let shared = PostService()

    private init() {}

    // MARK: - Fetch Posts
    func fetchPosts() async {
        isLoading = true
        errorMessage = nil

        // Limpiar posts anteriores para forzar recarga
        self.posts = []

        // Cargar posts normales y posts de main_user en paralelo
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.fetchAllPosts()
            }
            group.addTask {
                await self.fetchMainUserPosts()
            }
        }

        isLoading = false
    }

    // MARK: - Fetch All Posts
    private func fetchAllPosts() async {
        // Usar el endpoint /api/posts directamente
        let urlString = "\(baseURL)/api/posts"

        guard let url = URL(string: urlString) else {
            errorMessage = "URL inválida"
            print("❌ URL inválida: \(urlString)")
            return
        }

        print("🌐 Fetching posts from: \(url.absoluteString)")

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse else {
                errorMessage = "Respuesta del servidor inválida"
                print("❌ Respuesta inválida del servidor")
                return
            }

            print("📡 Status Code: \(httpResponse.statusCode)")
            print("📋 Headers: \(httpResponse.allHeaderFields)")

            if httpResponse.statusCode == 200 {
                // Log del JSON raw recibido (primeros 500 caracteres)
                if let jsonString = String(data: data, encoding: .utf8) {
                    let preview = String(jsonString.prefix(500))
                    print("📦 JSON received from API (preview):")
                    print(preview)
                    print("📦 Total JSON size: \(jsonString.count) characters")
                }

                let decoder = JSONDecoder()
                let postsResponse = try decoder.decode(PostsResponse.self, from: data)

                print("✅ Successfully loaded \(postsResponse.posts.count) posts from API")

                // Log first post details
                if let firstPost = postsResponse.posts.first {
                    print("📄 First post sample:")
                    print("  - ID: \(firstPost.id)")
                    print("  - Source: \(firstPost.source)")
                    print("  - Author: \(firstPost.author)")
                    print("  - Title: \(firstPost.title.prefix(60))...")
                    print("  - Likes: \(firstPost.likes)")
                    print("  - Date: \(firstPost.date)")
                }

                // Ordenar posts por fecha (más recientes primero)
                let sortedPosts = postsResponse.posts.sorted { post1, post2 in
                    let formatter = ISO8601DateFormatter()
                    let date1 = formatter.date(from: post1.date) ?? Date.distantPast
                    let date2 = formatter.date(from: post2.date) ?? Date.distantPast
                    return date1 > date2
                }

                // Actualizar la lista completa de posts
                self.posts = sortedPosts

                print("🎉 LOAD COMPLETE: Total of \(sortedPosts.count) posts loaded and sorted")
                print("📝 Posts summary:")
                for (index, post) in sortedPosts.prefix(3).enumerated() {
                    print("  Post #\(index + 1):")
                    print("    - ID: \(post.id)")
                    print("    - Source: \(post.source)")
                    print("    - Author: \(post.author)")
                    print("    - Title: \(post.title.prefix(50))...")
                    print("    - Likes: \(post.likes)")
                    print("    - Keywords: \(post.keywords.prefix(80))...")
                    print("    - Date: \(post.date)")
                    print("    - Image: \(post.image.prefix(60))...")
                }
                if sortedPosts.count > 3 {
                    print("  ... and \(sortedPosts.count - 3) more posts")
                }
            } else {
                errorMessage = "Error del servidor: \(httpResponse.statusCode)"
                print("⚠️ Server error: \(httpResponse.statusCode)")

                // Log de la respuesta de error
                if let errorString = String(data: data, encoding: .utf8) {
                    print("⚠️ Server response: \(errorString)")
                    errorMessage = errorString
                }
            }
        } catch let decodingError as DecodingError {
            print("❌ Error decoding JSON: \(decodingError)")

            switch decodingError {
            case .keyNotFound(let key, let context):
                errorMessage = "Missing key '\(key.stringValue)' in JSON"
                print("❌ Missing key: \(key) - \(context.debugDescription)")
            case .typeMismatch(let type, let context):
                errorMessage = "Type mismatch for '\(type)'"
                print("❌ Type mismatch: \(type) - \(context.debugDescription)")
            case .valueNotFound(let type, let context):
                errorMessage = "Value not found for '\(type)'"
                print("❌ Value not found: \(type) - \(context.debugDescription)")
            case .dataCorrupted(let context):
                errorMessage = "Data corrupted"
                print("❌ Data corrupted: \(context.debugDescription)")
            @unknown default:
                errorMessage = "Unknown decoding error"
            }
        } catch {
            errorMessage = "Error al cargar posts: \(error.localizedDescription)"
            print("❌ Error loading posts: \(error)")
            print("❌ Error details: \(error)")
        }
    }

    // MARK: - Refresh Posts
    func refreshPosts() async {
        await fetchPosts()
    }

    // MARK: - Force Sync
    func forceSync() async -> Bool {
        isSyncing = true
        errorMessage = nil

        let urlString = "\(baseURL)/sync/all"

        guard let url = URL(string: urlString) else {
            errorMessage = "URL de sync inválida"
            print("❌ URL de sync inválida: \(urlString)")
            isSyncing = false
            return false
        }

        print("🔄 Forcing sync from: \(url.absoluteString)")

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse else {
                errorMessage = "Respuesta del servidor de sync inválida"
                print("❌ Respuesta inválida del servidor de sync")
                isSyncing = false
                return false
            }

            print("📡 Sync Status Code: \(httpResponse.statusCode)")

            if httpResponse.statusCode == 200 {
                if let responseString = String(data: data, encoding: .utf8) {
                    print("✅ Sync response: \(responseString)")
                }

                // Actualizar fecha del último sync
                lastSyncDate = Date()

                // Esperar un momento para que el servidor procese
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 segundo

                // Recargar posts después del sync
                await fetchPosts()

                print("🎉 Sync completed successfully")
                isSyncing = false
                return true
            } else {
                errorMessage = "Error en sync: \(httpResponse.statusCode)"
                print("⚠️ Sync error: \(httpResponse.statusCode)")

                if let errorString = String(data: data, encoding: .utf8) {
                    print("⚠️ Sync error response: \(errorString)")
                }
                isSyncing = false
                return false
            }
        } catch {
            errorMessage = "Error al forzar sync: \(error.localizedDescription)"
            print("❌ Error forcing sync: \(error)")
            isSyncing = false
            return false
        }
    }

    // MARK: - Fetch Main User Posts
    func fetchMainUserPosts() async {
        let urlString = "\(baseURL)/api/main_user"

        guard let url = URL(string: urlString) else {
            print("❌ URL inválida para main_user: \(urlString)")
            return
        }

        print("🌐 Fetching main user posts from: \(url.absoluteString)")

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Respuesta inválida del servidor main_user")
                return
            }

            print("📡 Main User Status Code: \(httpResponse.statusCode)")

            if httpResponse.statusCode == 200 {
                // Log del JSON raw recibido
                if let jsonString = String(data: data, encoding: .utf8) {
                    let preview = String(jsonString.prefix(300))
                    print("📦 Main User JSON received (preview):")
                    print(preview)
                }

                let decoder = JSONDecoder()
                let mainUserResponse = try decoder.decode(MainUserResponse.self, from: data)

                print("✅ Successfully loaded \(mainUserResponse.posts.count) main user posts")

                // Convertir MainUserPost a CommunityPost
                let communityPosts = mainUserResponse.posts.map { $0.toCommunityPost() }

                // Actualizar la lista de posts de main_user
                self.mainUserPosts = communityPosts

                print("🎉 Main User Posts loaded: \(communityPosts.count) posts")
                if let firstPost = communityPosts.first {
                    print("📄 First main user post:")
                    print("  - Author: \(firstPost.author)")
                    print("  - Content: \(firstPost.content.prefix(60))...")
                    print("  - Date: \(firstPost.date)")
                }
            } else {
                print("⚠️ Main User server error: \(httpResponse.statusCode)")

                if let errorString = String(data: data, encoding: .utf8) {
                    print("⚠️ Main User response: \(errorString)")
                }
            }
        } catch let decodingError as DecodingError {
            print("❌ Error decoding Main User JSON: \(decodingError)")

            switch decodingError {
            case .keyNotFound(let key, let context):
                print("❌ Missing key in main_user: \(key) - \(context.debugDescription)")
            case .typeMismatch(let type, let context):
                print("❌ Type mismatch in main_user: \(type) - \(context.debugDescription)")
            case .valueNotFound(let type, let context):
                print("❌ Value not found in main_user: \(type) - \(context.debugDescription)")
            case .dataCorrupted(let context):
                print("❌ Data corrupted in main_user: \(context.debugDescription)")
            @unknown default:
                print("❌ Unknown decoding error in main_user")
            }
        } catch {
            print("❌ Error loading main user posts: \(error)")
        }
    }
}
