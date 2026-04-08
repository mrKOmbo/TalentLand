//
//  ProfileView.swift
//  atenea
//
//  Coppel Brand Toolkit 2024 — Ultra-clean profile view
//

import SwiftUI

struct UserProfileView: View {
    @ObservedObject var userManager = UserManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var isEditMode = false
    @State private var editedName = ""
    @State private var editedEmail = ""
    @State private var showSuccess = false

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Profile")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(Color.coppelDarkBlue)

                            Text("Manage your account")
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

                    // Avatar
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.coppelBlue)
                                .frame(width: 100, height: 100)

                            Image(systemName: "person.fill")
                                .font(.system(size: 48, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .overlay(
                            Circle()
                                .stroke(Color(red: 0.11, green: 0.26, blue: 0.91).opacity(0.2), lineWidth: 3)
                        )

                        if !isEditMode {
                            VStack(spacing: 4) {
                                Text(userManager.currentUser?.name ?? "User")
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .foregroundColor(Color.coppelDarkBlue)

                                Text(userManager.currentUser?.email ?? "user@atenea.com")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                        }
                    }

                    // Stats Grid
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            statItem(icon: "location.fill", label: "Routes", value: "24", color: Color(red: 0.11, green: 0.26, blue: 0.91))
                            statItem(icon: "star.fill", label: "Points", value: "1.2K", color: Color(red: 0.99, green: 0.73, blue: 0.18))
                            statItem(icon: "badge.fill", label: "Badges", value: "8", color: Color(red: 0.05, green: 0.75, blue: 0.31))
                        }
                    }
                    .padding(.horizontal, 20)

                    // Content Section
                    VStack(spacing: 16) {
                        if isEditMode {
                            editModeContent
                        } else {
                            viewModeContent
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer(minLength: 40)
                }
            }

            // Success Toast
            if showSuccess {
                VStack {
                    Spacer()

                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)

                        Text("Changes saved")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.coppelGreen)
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private var viewModeContent: some View {
        VStack(spacing: 12) {
            infoRow(icon: "person.fill", label: "Name", value: userManager.currentUser?.name ?? "User")
            infoRow(icon: "envelope.fill", label: "Email", value: userManager.currentUser?.email ?? "user@atenea.com")
            infoRow(icon: "calendar.circle.fill", label: "Member since", value: "January 2024")

            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    editedName = userManager.currentUser?.name ?? ""
                    editedEmail = userManager.currentUser?.email ?? ""
                    isEditMode = true
                }
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 18, weight: .semibold))

                    Text("Edit profile")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))

                    Spacer()
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.coppelBlue)
                )
            }
            .padding(.top, 8)
        }
    }

    private var editModeContent: some View {
        VStack(spacing: 12) {
            inputField(icon: "person.fill", placeholder: "Name", text: $editedName)
            inputField(icon: "envelope.fill", placeholder: "Email", text: $editedEmail)

            HStack(spacing: 12) {
                Button(action: saveChanges) {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18, weight: .semibold))

                        Text("Save")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))

                        Spacer()
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.coppelGreen)
                    )
                }

                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isEditMode = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.gray.opacity(0.5))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
            }
        }
    }

    private func statItem(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
            }

            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(Color(red: 0.05, green: 0.09, blue: 0.33))

            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.systemBackground))
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(red: 0.11, green: 0.26, blue: 0.91).opacity(0.1))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(red: 0.11, green: 0.26, blue: 0.91))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)

                Text(value)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(red: 0.05, green: 0.09, blue: 0.33))
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.systemBackground))
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }

    private func inputField(icon: String, placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(red: 0.11, green: 0.26, blue: 0.91))
                .frame(width: 24)

            TextField(placeholder, text: text)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(Color(red: 0.05, green: 0.09, blue: 0.33))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.systemBackground))
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }

    private func saveChanges() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isEditMode = false
            showSuccess = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showSuccess = false
            }
        }
    }
}

#Preview {
    UserProfileView()
}
