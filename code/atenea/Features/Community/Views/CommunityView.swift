//
//  CommunityView.swift
//  atenea
//
//  Vista de Comunidad
//

import SwiftUI

// Vista de Comunidad
struct CommunityView: View {
    @State private var selectedFilter = LocalizedString("community.filter.all")
    @Binding var selectedTab: Int

    var filters: [String] {
        [
            LocalizedString("community.filter.all"),
            LocalizedString("community.filter.worldCup"),
            LocalizedString("community.filter.trending"),
            LocalizedString("community.filter.creator")
        ]
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Modern light gradient background
                LinearGradient(
                    colors: [
                        Color(red: 0.97, green: 0.98, blue: 1.0),
                        Color.white,
                        Color(red: 0.98, green: 0.97, blue: 1.0)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea(edges: .top)

                VStack(spacing: 0) {
                    // Modern premium header
                    premiumHeader

                    // Filter chips row
                    filterChipsRow

                    // Feed de la comunidad
                    communityFeed
                }
            }
            .navigationBarHidden(true)
        }
    }

    // MARK: - Premium Header
    private var premiumHeader: some View {
        VStack(spacing: 0) {
            // Top bar with title and actions
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizedString("tab.community"))
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(.primary)

                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.secondary)
                            .frame(width: 8, height: 8)
                        Text(LocalizedString("status.noPostsAvailable"))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Action buttons
                HStack(spacing: 12) {
                    Button(action: {}) {
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.12))
                                .frame(width: 40, height: 40)
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(.blue)
                                .symbolRenderingMode(.hierarchical)
                        }
                    }
                    .disabled(true)

                    Button(action: {}) {
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.12))
                                .frame(width: 40, height: 40)

                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(.primary)
                        }
                    }

                    Button(action: {}) {
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.12))
                                .frame(width: 40, height: 40)

                            Image(systemName: "bell.fill")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(.primary)
                                .symbolRenderingMode(.hierarchical)
                        }
                        .overlay(
                            Circle()
                                .fill(.red)
                                .frame(width: 12, height: 12)
                                .offset(x: 12, y: -12),
                            alignment: .topTrailing
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 16)

            // Stats bar
            HStack(spacing: 0) {
                CommunityStatCard(
                    icon: "flame.fill",
                    title: LocalizedString("community.filter.trending"),
                    value: "0",
                    color: .orange
                )

                Divider()
                    .frame(height: 40)

                CommunityStatCard(
                    icon: "soccerball",
                    title: LocalizedString("community.filter.worldCup"),
                    value: "0",
                    color: .green
                )

                Divider()
                    .frame(height: 40)

                CommunityStatCard(
                    icon: "newspaper.fill",
                    title: LocalizedString("community.filter.creator"),
                    value: "0",
                    color: .blue
                )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .background(.ultraThinMaterial)
    }

    // MARK: - Filter Chips Row
    private var filterChipsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(filters, id: \.self) { filter in
                    FilterChip(
                        title: filter,
                        isSelected: selectedFilter == filter,
                        icon: filterIcon(for: filter)
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedFilter = filter
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(.white.opacity(0.7))
    }

    // MARK: - Community Feed
    private var communityFeed: some View {
        Group {
            emptyState
        }
    }

    private var loadingState: some View {
        VStack(spacing: 20) {
            Spacer()
            ProgressView()
                .scaleEffect(CGFloat(1.3))
                .tint(.blue)
            Text(LocalizedString("status.loadingPosts"))
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    private func errorState(error: String) -> some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.red)
                    .symbolRenderingMode(.hierarchical)
            }

            VStack(spacing: 8) {
                Text(LocalizedString("status.errorLoadingPosts"))
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.primary)

                Text(error)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Button {
            } label: {
                Text(LocalizedString("action.retry"))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(.blue)
                    )
            }

            Spacer()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: "newspaper.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.blue)
                    .symbolRenderingMode(.hierarchical)
            }

            Text(LocalizedString("status.noPostsAvailable"))
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.primary)

            Spacer()
        }
    }

    private var postsScrollView: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(filteredPosts) { post in
                    CommunityPostCard(post: post)
                }
            }
            .padding(.vertical, 20)
            .padding(.bottom, 100)
        }
        .refreshable {}
    }

    // MARK: - Helper Functions
    private func filterIcon(for filter: String) -> String? {
        if filter == LocalizedString("community.filter.creator") {
            return "star.fill"
        } else if filter == LocalizedString("community.filter.worldCup") {
            return "soccerball"
        } else if filter == LocalizedString("community.filter.trending") {
            return "chart.line.uptrend.xyaxis"
        }
        return nil
    }

    // MARK: - Filtered Posts
    private var filteredPosts: [CommunityPost] { [] }
}

// MARK: - Filter Chip Component
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    var icon: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .medium))
                        .symbolRenderingMode(.hierarchical)
                }
                Text(title)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
            }
            .foregroundStyle(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ?
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [Color.gray.opacity(0.12), Color.gray.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(
                        color: isSelected ? Color.blue.opacity(0.3) : Color.clear,
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Community Post Card Component
struct CommunityPostCard: View {
    let post: CommunityPost
    @State private var isLiked = false
    @State private var imageData: Data?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header del post
            postHeader

            // Imagen del post
            postImage

            // Acciones rápidas
            actionButtons

            // Caption y detalles
            postDetails

            // Keywords/Tags
            if !post.keywordArray.isEmpty {
                tagsSection
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.white)
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
        )
        .padding(.horizontal, 16)
    }

    // MARK: - Post Header
    private var postHeader: some View {
        HStack(spacing: 12) {
            // Source icon based on source type
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.blue.opacity(0.2),
                                Color.blue.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)

                Image(systemName: sourceIcon)
                    .foregroundStyle(.blue)
                    .font(.system(size: 20, weight: .semibold))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(cleanAuthorName(post.author))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(post.source.uppercased())
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.blue)

                    Text("•")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 11))

                    Text(post.formattedDate)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Link to original post
            Link(destination: URL(string: post.url) ?? URL(string: "https://news.com")!) {
                Image(systemName: "arrow.up.right.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.blue)
                    .symbolRenderingMode(.hierarchical)
            }
        }
        .frame(height: 76)
        .padding(16)
    }

    private var sourceIcon: String {
        switch post.source.lowercased() {
        case "news":
            return "newspaper.fill"
        case "instagram":
            return "camera.fill"
        case "twitter", "x":
            return "message.fill"
        default:
            return "globe"
        }
    }

    private func cleanAuthorName(_ author: String) -> String {
        // Remove www. and .com/.co.uk etc from domain names
        var cleaned = author.replacingOccurrences(of: "www.", with: "")
        if let dotIndex = cleaned.lastIndex(of: ".") {
            let possibleExtension = String(cleaned[dotIndex...])
            if possibleExtension.count <= 4 { // .com, .net, .org
                cleaned = String(cleaned[..<dotIndex])
            }
        }
        return cleaned.capitalized
    }

    // MARK: - Post Image
    private var postImage: some View {
        ZStack {
            Rectangle()
                .fill(Color.gray.opacity(0.1))
                .frame(height: 240)

            if let imageData = imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: UIScreen.main.bounds.width - 32, height: 240)
                    .clipped()
            } else {
                VStack(spacing: 12) {
                    ProgressView()
                        .tint(.blue)
                    Text(LocalizedString("status.loading"))
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(height: 240)
        .clipped()
        .task {
            await loadImage()
        }
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        HStack(spacing: 16) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isLiked.toggle()
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .font(.system(size: 22))
                        .foregroundStyle(isLiked ? .red : .primary)
                        .symbolRenderingMode(.hierarchical)
                        .scaleEffect(CGFloat(isLiked ? 1.1 : 1.0))

                    if post.likes > 0 {
                        Text("\(post.likes)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.primary)
                    }
                }
            }

            Button(action: {}) {
                Image(systemName: "bubble.right")
                    .font(.system(size: 22))
                    .foregroundStyle(.primary)
            }

            Button(action: {}) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 22))
                    .foregroundStyle(.primary)
            }

            Spacer()
        }
        .frame(height: 46)
        .padding(.horizontal, 16)
    }

    // MARK: - Post Details
    private var postDetails: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title
            Text(post.title)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .truncationMode(.tail)
                .frame(maxHeight: 44, alignment: .topLeading)

            // Content preview
            Text(truncatedContent)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .lineLimit(3)
                .truncationMode(.tail)
                .frame(maxHeight: 60, alignment: .topLeading)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .frame(height: 128)
    }

    private var truncatedContent: String {
        // Remove extra whitespace and get first 200 characters
        let cleaned = post.content
            .replacingOccurrences(of: "\n\n", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if cleaned.count > 200 {
            let index = cleaned.index(cleaned.startIndex, offsetBy: 200)
            return String(cleaned[..<index]) + "..."
        }
        return cleaned
    }

    // MARK: - Tags Section
    private var tagsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(post.keywordArray.prefix(5), id: \.self) { keyword in
                    Text("#\(keyword)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.blue)
                        .lineLimit(1)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(Color.blue.opacity(0.1))
                        )
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 38)
        .padding(.bottom, 12)
    }

    // MARK: - Load Image
    private func loadImage() async {
        guard let url = URL(string: post.image) else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            await MainActor.run {
                self.imageData = data
            }
        } catch {
            print("❌ Error al cargar imagen: \(error)")
        }
    }
}

// MARK: - Stat Card Component
private struct CommunityStatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(color)
                    .symbolRenderingMode(.hierarchical)
            }

            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.primary)

            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
    }
}
