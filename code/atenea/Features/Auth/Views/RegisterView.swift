//
//  RegisterView.swift
//  Atenea
//
//  Registration screen with user information form
//

import SwiftUI

struct RegisterView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var languageManager: LanguageManager
    @ObservedObject var userManager = UserManager.shared
    @Binding var isLoggedIn: Bool

    @State private var fullName: String = ""
    @State private var age: String = ""
    @State private var selectedCountry: String = "Mexico"
    @State private var email: String = ""
    @State private var phoneNumber: String = ""
    @State private var selectedAccessibility: AccessibilityOption = .none
    @State private var showingCountryPicker: Bool = false
    @State private var showingAgePicker: Bool = false
    @State private var showingAccessibilityPicker: Bool = false
    @State private var navigateToRoleSelection = false

    // List of World Cup 2026 host countries and other popular countries
    let countries = [
        "Mexico",
        "United States",
        "Canada",
        "Argentina",
        "Brazil",
        "Spain",
        "Germany",
        "France",
        "Italy",
        "England",
        "Portugal",
        "Netherlands",
        "Belgium",
        "Uruguay",
        "Colombia",
        "Chile",
        "Peru",
        "Ecuador",
        "Japan",
        "South Korea",
        "Australia",
        "Morocco",
        "Nigeria",
        "Ghana",
        "Senegal"
    ].sorted()

    // Check if all required fields are filled
    private var canCreateAccount: Bool {
        !fullName.isEmpty &&
        !age.isEmpty &&
        !email.isEmpty &&
        !phoneNumber.isEmpty
    }

    var body: some View {
        ZStack {
            // Background gradient (same as login)
            backgroundGradient

            ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Title with animation
                        titleSection
                            .padding(.top, 20)

                        // Full Name Field
                        formField(
                            label: LocalizedString("register.name"),
                            placeholder: LocalizedString("register.namePlaceholder"),
                            text: $fullName,
                            keyboardType: .default,
                            autocapitalization: .words
                        )

                        // Age Field
                        agePickerField

                        // Place of Origin Picker
                        countryPickerField

                        // Email Field
                        formField(
                            label: LocalizedString("register.email"),
                            placeholder: LocalizedString("register.emailPlaceholder"),
                            text: $email,
                            keyboardType: .emailAddress,
                            autocapitalization: .never
                        )

                        // Phone Number Field
                        formField(
                            label: LocalizedString("register.phone"),
                            placeholder: LocalizedString("register.phonePlaceholder"),
                            text: $phoneNumber,
                            keyboardType: .phonePad,
                            autocapitalization: .never
                        )

                        // Accessibility Field
                        accessibilityPickerField

                        // Create Account Button
                        createAccountButton

                        // Sign In Link
                        signInLink
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $navigateToRoleSelection) {
                RoleSelectionView(
                    isLoggedIn: $isLoggedIn,
                    userInfo: UserRegistrationInfo(
                        fullName: fullName,
                        age: age,
                        country: selectedCountry,
                        email: email,
                        phoneNumber: phoneNumber,
                        accessibilityOption: selectedAccessibility
                    )
                )
                .environmentObject(languageManager)
            }
            .id(languageManager.currentLanguage) // Force re-render when language changes
        }

    // MARK: - View Components

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color.coppelBlue.opacity(0.05),
                Color.white,
                Color.coppelYellow.opacity(0.03)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedString("register.subtitle"))
                .font(.coppelBody)
                .foregroundStyle(.secondary)

            Text(LocalizedString("register.title"))
                .font(.coppelHeadline)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.coppelBlue, .coppelLightBlue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        }
    }

    private func formField(
        label: String,
        placeholder: String,
        text: Binding<String>,
        keyboardType: UIKeyboardType = .default,
        autocapitalization: TextInputAutocapitalization = .sentences
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.coppelCaption)
                .foregroundStyle(.secondary)

            TextField(placeholder, text: text)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.coppelBody)
                .foregroundStyle(Color.primaryText)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: CoppelTheme.CornerRadius.lg, style: .continuous)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: CoppelTheme.CornerRadius.lg, style: .continuous)
                        .stroke(Color.coppelGrey.opacity(0.1), lineWidth: 1)
                )
                .textInputAutocapitalization(autocapitalization)
                .keyboardType(keyboardType)
                .onTapGesture {
                    closeAllPickers()
                }
        }
    }

    private var agePickerField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizedString("register.age"))
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)

            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showingAgePicker.toggle()
                    if showingAgePicker {
                        showingCountryPicker = false
                        showingAccessibilityPicker = false
                    }
                }
            }) {
                HStack {
                    Text(age.isEmpty ? LocalizedString("register.agePlaceholder") : age)
                        .font(.system(size: 16))
                        .foregroundStyle(age.isEmpty ? .secondary : .primary)

                    Spacer()

                    Image(systemName: showingAgePicker ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                )
            }

            if showingAgePicker {
                Picker("", selection: Binding(
                    get: { age.isEmpty ? "18" : age },
                    set: { age = $0 }
                )) {
                    ForEach(Array(13...99).map { "\($0)" }, id: \.self) { ageOption in
                        Text(ageOption).tag(ageOption)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 150)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .clipped()
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
        }
    }

    private var countryPickerField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizedString("register.origin"))
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)

            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showingCountryPicker.toggle()
                    if showingCountryPicker {
                        showingAgePicker = false
                        showingAccessibilityPicker = false
                    }
                }
            }) {
                HStack {
                    Text(selectedCountry)
                        .font(.system(size: 16))
                        .foregroundStyle(.primary)

                    Spacer()

                    Image(systemName: showingCountryPicker ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                )
            }

            if showingCountryPicker {
                Picker("", selection: $selectedCountry) {
                    ForEach(countries, id: \.self) { country in
                        Text(country).tag(country)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 150)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .clipped()
                .onChange(of: selectedCountry) { oldValue, newValue in
                    let languageCode = LanguageManager.languageForCountry(newValue)
                    languageManager.setLanguage(languageCode)
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
        }
    }

    private var accessibilityPickerField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizedString("register.accessibility"))
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)

            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showingAccessibilityPicker.toggle()
                    if showingAccessibilityPicker {
                        showingAgePicker = false
                        showingCountryPicker = false
                    }
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: selectedAccessibility.icon)
                        .font(.system(size: 18))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.coppelBlue, .coppelLightBlue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text(selectedAccessibility.displayName)
                        .font(.system(size: 16))
                        .foregroundStyle(.primary)

                    Spacer()

                    Image(systemName: showingAccessibilityPicker ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                )
            }

            if showingAccessibilityPicker {
                Picker("", selection: $selectedAccessibility) {
                    ForEach(AccessibilityOption.allCases) { option in
                        HStack {
                            Image(systemName: option.icon)
                            Text(option.displayName)
                        }
                        .tag(option)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 150)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .clipped()
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
        }
    }

    private var createAccountButton: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            handleRegistration()
        }) {
            HStack(spacing: 8) {
                Text(LocalizedString("register.createAccount"))
                    .font(.coppelCTA)

                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(Color.primaryTextInverted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Group {
                    if canCreateAccount {
                        LinearGradient(
                            gradient: Gradient(colors: [.coppelBlue, .coppelLightBlue]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    } else {
                        LinearGradient(
                            gradient: Gradient(colors: [.coppelGrey, .coppelGrey]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .opacity(0.5)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: CoppelTheme.CornerRadius.lg, style: .continuous))
            .shadow(
                color: canCreateAccount ? Color.coppelBlue.opacity(0.4) : Color.clear,
                radius: 12,
                x: 0,
                y: 6
            )
        }
        .disabled(!canCreateAccount)
        .buttonStyle(ScaleButtonStyle())
        .padding(.top, 8)
    }

    private var signInLink: some View {
        HStack(spacing: 4) {
            Text(LocalizedString("register.alreadyHaveAccount"))
                .font(.system(size: 15))
                .foregroundStyle(.secondary)

            Button(action: {
                dismiss()
            }) {
                Text(LocalizedString("register.signIn"))
                    .font(.coppelCTA)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.coppelBlue, .coppelLightBlue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    // MARK: - Helper Functions

    private func closeAllPickers() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showingAgePicker = false
            showingCountryPicker = false
            showingAccessibilityPicker = false
        }
    }

    // MARK: - Registration Handler

    private func handleRegistration() {
        print("📝 Creating account:")
        print("   Name: \(fullName)")
        print("   Age: \(age)")
        print("   Country: \(selectedCountry)")
        print("   Email: \(email)")
        print("   Phone: \(phoneNumber)")
        print("   Accessibility: \(selectedAccessibility.displayName)")

        // Navigate to role selection instead of logging in directly
        navigateToRoleSelection = true
    }
}

// MARK: - Preview

#Preview {
    RegisterView(isLoggedIn: .constant(false))
        .environmentObject(LanguageManager.shared)
}
