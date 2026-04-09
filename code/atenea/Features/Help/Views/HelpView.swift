//
//  HelpView.swift
//  atenea
//
//  Coppel Brand Toolkit 2024 — Help & support
//

import SwiftUI

struct HelpTopic: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
}

struct FAQItem: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
}

struct HelpView: View {
    @Environment(\.dismiss) var dismiss
    @State private var expandedFAQ: UUID?
    @State private var searchText = ""

    private let helpTopics = [
        HelpTopic(icon: "map.fill", title: LocalizedString("help.navigation"), description: LocalizedString("help.navigationDesc")),
        HelpTopic(icon: "soccerball.fill", title: LocalizedString("help.worldCup"), description: LocalizedString("help.worldCupDesc")),
        HelpTopic(icon: "star.fill", title: LocalizedString("help.favorites"), description: LocalizedString("help.favoritesDesc")),
        HelpTopic(icon: "gearshape.fill", title: LocalizedString("help.settings"), description: LocalizedString("help.settingsDesc")),
    ]

    private let faqs = [
        FAQItem(question: LocalizedString("help.faq1Q"), answer: LocalizedString("help.faq1A")),
        FAQItem(question: LocalizedString("help.faq2Q"), answer: LocalizedString("help.faq2A")),
        FAQItem(question: LocalizedString("help.faq3Q"), answer: LocalizedString("help.faq3A")),
        FAQItem(question: LocalizedString("help.faq4Q"), answer: LocalizedString("help.faq4A")),
    ]

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(LocalizedString("help.title"))
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(Color(red: 0.05, green: 0.09, blue: 0.33))

                            Text(LocalizedString("help.subtitle"))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.gray)
                        }

                        Spacer()

                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.gray.opacity(0.4))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    // Popular Topics
                    VStack(alignment: .leading, spacing: 12) {
                        Text(LocalizedString("help.popularTopics"))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 0.05, green: 0.09, blue: 0.33))
                            .padding(.horizontal, 20)

                        VStack(spacing: 10) {
                            ForEach(helpTopics) { topic in
                                topicCard(topic)
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    // FAQ Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text(LocalizedString("help.faq"))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 0.05, green: 0.09, blue: 0.33))
                            .padding(.horizontal, 20)

                        VStack(spacing: 8) {
                            ForEach(faqs) { faq in
                                faqCard(faq)
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    // Contact Support
                    VStack(spacing: 12) {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(Color(red: 0.11, green: 0.26, blue: 0.91).opacity(0.1))
                                    .frame(width: 48, height: 48)

                                Image(systemName: "message.circle.fill")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(Color(red: 0.11, green: 0.26, blue: 0.91))
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(LocalizedString("help.stillNeedHelp"))
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundColor(Color(red: 0.05, green: 0.09, blue: 0.33))

                                Text(LocalizedString("help.contactSupport"))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.gray)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.gray.opacity(0.4))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(.systemBackground))
                                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 20)

                    Spacer(minLength: 40)
                }
            }
        }
    }

    private func topicCard(_ topic: HelpTopic) -> some View {
        Button(action: {}) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.11, green: 0.26, blue: 0.91).opacity(0.1))
                        .frame(width: 44, height: 44)

                    Image(systemName: topic.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(red: 0.11, green: 0.26, blue: 0.91))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(topic.title)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(red: 0.05, green: 0.09, blue: 0.33))

                    Text(topic.description)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.gray.opacity(0.4))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.systemBackground))
                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
            )
        }
    }

    private func faqCard(_ faq: FAQItem) -> some View {
        VStack(spacing: 0) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    expandedFAQ = expandedFAQ == faq.id ? nil : faq.id
                }
            }) {
                HStack(spacing: 12) {
                    Text(faq.question)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(red: 0.05, green: 0.09, blue: 0.33))
                        .lineLimit(2)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.gray.opacity(0.6))
                        .rotationEffect(.degrees(expandedFAQ == faq.id ? 180 : 0))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }

            if expandedFAQ == faq.id {
                Divider()
                    .padding(.horizontal, 12)

                Text(faq.answer)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.gray)
                    .lineLimit(10)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.systemBackground))
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}

#Preview {
    HelpView()
}
