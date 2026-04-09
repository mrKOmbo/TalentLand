//
//  LoginView.swift
//  Atenea
//
//  Login screen with email/phone and social auth options
//

import SwiftUI
import AuthenticationServices

// MARK: - Confetti Model (reutilizado del Onboarding)
struct ConfettiPiece2: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var rotation: Double
    var color: Color
    var scale: CGFloat
}

struct LoginView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @Binding var isLoggedIn: Bool
    @State private var emailOrPhone: String = ""
    @State private var agreedToTerms: Bool = false
    @State private var showingHelp: Bool = false
    @ObservedObject var userManager = UserManager.shared
    @State private var selectedUser: User?
    @State private var isWorldCupToday: Bool = false
    @State private var searchEmail: String = ""
    @State private var selectedTab: Int = 1 // 0 = Buscador, 1 = Usuarios

    // Confetti state
    @State private var confetti: [ConfettiPiece2] = []
    @State private var showConfetti = false

    // Check if continue button should be enabled
    private var canContinue: Bool {
        if selectedTab == 0 {
            // Buscador mode: need email and terms
            return !searchEmail.isEmpty && agreedToTerms
        } else {
            // Usuarios mode: need selected user and terms
            return selectedUser != nil && agreedToTerms
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                mainContent

                // Confetti overlay
                if showConfetti {
                    ForEach(confetti) { piece in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(piece.color)
                            .frame(width: 8, height: 12)
                            .scaleEffect(piece.scale)
                            .rotationEffect(.degrees(piece.rotation))
                            .position(x: piece.x, y: piece.y)
                    }
                    .allowsHitTesting(false)
                }
            }
            .alert(LocalizedString("login.helpTitle"), isPresented: $showingHelp) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(LocalizedString("login.helpMessage"))
            }
            .onAppear {
                // Always start unchecked by default
                isWorldCupToday = false
            }
            .id(languageManager.currentLanguage)
        }
    }

    private var backgroundGradient: some View {
        Color.white
            .ignoresSafeArea()
    }

    private var mainContent: some View {
        VStack(spacing: 0) {
            headerView
            scrollableContent
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            sponsorLogosSection
                .frame(height: 55)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
        }
    }

    private var sponsorLogosSection: some View {
        HStack(spacing: 0) {
            Image("Fundacion-Coppel-Logo")
                .resizable()
                .scaledToFit()
                .frame(height: 32)

            Spacer()

            Rectangle()
                .fill(Color.coppelDarkBlue.opacity(0.15))
                .frame(width: 1, height: 32)

            Spacer()

            Image("Coppel-Emprende-Logo")
                .resizable()
                .scaledToFit()
                .frame(height: 32)
        }
        .frame(maxWidth: .infinity)
    }

    private var headerView: some View {
        HStack(alignment: .center, spacing: 16) {
            worldCupToggle
            Spacer()
            utilityButtons
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private var worldCupToggle: some View {
        Button(action: {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                isWorldCupToday.toggle()
            }

            if isWorldCupToday {
                showConfetti = true
                initializeConfetti()
                startConfettiAnimation()

                let impact = UINotificationFeedbackGenerator()
                impact.notificationOccurred(.success)

                DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                    showConfetti = false
                }
            }
        }) {
            HStack(spacing: 6) {
                worldCupCheckmarkIcon
                
                Text(LocalizedString("login.worldCupToday"))
                    .font(.system(size: 13, weight: isWorldCupToday ? .semibold : .medium))
                    .foregroundColor(isWorldCupToday ? Color.coppelBlue : Color.coppelDarkBlue)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.coppelBlue.opacity(0.08))
            .clipShape(Capsule())
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(LocalizedString("login.worldCupToday"))
        .accessibilityValue(isWorldCupToday ? LocalizedString("login.worldCupChecked") : LocalizedString("login.worldCupUnchecked"))
    }

    private var worldCupCheckmarkIcon: some View {
        Image(systemName: isWorldCupToday ? "checkmark.circle.fill" : "circle")
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(isWorldCupToday ? Color.coppelBlue : Color.coppelDarkBlue)
            .rotationEffect(.degrees(isWorldCupToday ? 360 : 0))
            .animation(.spring(response: 0.6, dampingFraction: 0.5), value: isWorldCupToday)
    }

    private var utilityButtons: some View {
        Button(action: { showingHelp = true }) {
            Image(systemName: "questionmark.circle.fill")
                .font(.system(size: 22))
                .foregroundStyle(.secondary)
                .symbolRenderingMode(.hierarchical)
        }
        .accessibilityLabel(LocalizedString("login.help"))
        .accessibilityHint(LocalizedString("login.helpAccessibilityHint"))
        .accessibilityAddTraits(.isButton)
    }

    private var scrollableContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                titleSection
                userSelectionSection
                termsCheckbox
                continueButton
                divider
                appleSignInButton
                signUpLink
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 40)
        }
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizedString("login.welcome"))
                .font(.coppelBody)
                .foregroundStyle(.secondary)

            Text(LocalizedString("login.appName"))
                .font(.coppelHeadline)
                .foregroundStyle(Color.coppelDarkBlue)
        }
        .padding(.top, 20)
    }

    private var userSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Segmented control style tabs
            HStack(spacing: 0) {
                // Buscador tab
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = 0
                        selectedUser = nil
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 14, weight: .medium))
                        Text(LocalizedString("login.tabSearch"))
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundStyle(selectedTab == 0 ? .primary : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(selectedTab == 0 ? Color.white : Color.clear)
                            .shadow(color: selectedTab == 0 ? Color.coppelDarkBlue.opacity(0.1) : Color.clear, radius: 4, x: 0, y: 2)
                    )
                }

                // Usuarios tab
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = 1
                        searchEmail = ""
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 14, weight: .medium))
                        Text(LocalizedString("login.tabUsers"))
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundStyle(selectedTab == 1 ? .primary : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(selectedTab == 1 ? Color.white : Color.clear)
                            .shadow(color: selectedTab == 1 ? Color.coppelDarkBlue.opacity(0.1) : Color.clear, radius: 4, x: 0, y: 2)
                    )
                }
            }
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.gray.opacity(0.12))
            )

            // Content based on selected tab with animated height
            Group {
                if selectedTab == 0 {
                    searchSection
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                } else {
                    usersListSection
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedTab)
            .gesture(
                DragGesture(minimumDistance: 30)
                    .onEnded { value in
                        let horizontalDistance = value.translation.width

                        if horizontalDistance > 50 {
                            // Swipe right -> go to previous tab (Buscador)
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                selectedTab = 0
                                selectedUser = nil
                            }
                        } else if horizontalDistance < -50 {
                            // Swipe left -> go to next tab (Usuarios)
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                selectedTab = 1
                                searchEmail = ""
                            }
                        }
                    }
            )
        }
    }

    private var searchSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizedString("login.searchUser"))
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .kerning(0.5)

            // Email TextField
            HStack(spacing: 12) {
                Image(systemName: "envelope.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.coppelBlue.opacity(0.7))

                ZStack(alignment: .leading) {
                    if searchEmail.isEmpty {
                        Text("email@atenea.com")
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary.opacity(0.4))
                    }

                    TextField("", text: $searchEmail)
                        .font(.system(size: 16))
                        .foregroundStyle(.primary.opacity(0.7))
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: Color.coppelDarkBlue.opacity(0.05), radius: 8, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(searchEmail.isEmpty ? Color.clear : Color.coppelBlue.opacity(0.3), lineWidth: 1.5)
            )
        }
        .padding(.top, 8)
    }

    private var usersListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizedString("login.selectUser"))
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .kerning(0.5)

            VStack(spacing: 10) {
                ForEach(userManager.getAllUsers()) { user in
                    UserSelectionCard(
                        user: user,
                        isSelected: selectedUser?.id == user.id,
                        action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedUser = user
                            }
                        }
                    )
                }
            }
        }
        .padding(.top, 8)
    }

    private var termsCheckbox: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                agreedToTerms.toggle()
            }
        }) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: agreedToTerms ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(agreedToTerms ? Color.coppelBlue : .secondary)
                    .symbolRenderingMode(.hierarchical)

                termsText
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(LocalizedString("login.termsAccessibility"))
        .accessibilityValue(agreedToTerms ? LocalizedString("login.termsAccepted") : LocalizedString("login.termsNotAccepted"))
        .accessibilityHint(LocalizedString("login.termsHint"))
        .accessibilityAddTraits(.isButton)
    }

    private var termsText: some View {
        VStack(alignment: .leading, spacing: 2) {
            (Text(LocalizedString("login.terms")) +
             Text(" ") +
             Text(LocalizedString("login.termsLink")).bold() +
             Text(" ") +
             Text(LocalizedString("login.and")) +
             Text(" ") +
             Text(LocalizedString("login.privacyLink")).bold())
                .font(.coppelCaption)
                .foregroundStyle(.secondary)
                .tint(.coppelBlue)
        }
    }

    private var continueButton: some View {
        Button(action: { handleEmailLogin() }) {
            Text(LocalizedString("login.continue"))
                .font(.coppelCTA)
                .foregroundStyle(Color.primaryTextInverted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(continueButtonBackground)
                .shadow(color: canContinue ? Color.coppelBlue.opacity(0.3) : Color.clear, radius: 10, x: 0, y: 5)
        }
        .disabled(!canContinue)
        .scaleEffect(CGFloat(canContinue ? 1.0 : 0.98))
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: canContinue)
        .accessibilityLabel(LocalizedString("login.continue"))
        .accessibilityHint(canContinue ? LocalizedString("login.continueHint") : LocalizedString("login.continueDisabledHint"))
        .accessibilityAddTraits(.isButton)
    }

    private var continueButtonBackground: some View {
        RoundedRectangle(cornerRadius: CoppelTheme.CornerRadius.lg, style: .continuous)
            .fill(canContinue ? Color.coppelBlue : Color.coppelGrey.opacity(0.3))
    }

    private var divider: some View {
        HStack(spacing: 16) {
            Rectangle()
                .fill(.secondary.opacity(0.3))
                .frame(height: 0.5)

            Text(LocalizedString("login.or"))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)

            Rectangle()
                .fill(.secondary.opacity(0.3))
                .frame(height: 0.5)
        }
        .padding(.vertical, 4)
    }

    private var appleSignInButton: some View {
        SignInWithAppleButton(
            onRequest: { request in
                request.requestedScopes = [.fullName, .email]
            },
            onCompletion: { result in
                handleAppleLogin(result: result)
            }
        )
        .signInWithAppleButtonStyle(.white)
        .frame(height: 54)
        .cornerRadius(14)
        .shadow(color: .coppelDarkBlue.opacity(0.1), radius: 8, x: 0, y: 4)
        .accessibilityLabel(LocalizedString("login.appleSignIn"))
        .accessibilityHint(LocalizedString("login.appleSignInHint"))
    }

    private var signUpLink: some View {
        HStack(spacing: 4) {
            Text(LocalizedString("login.noAccount"))
                .font(.system(size: 15))
                .foregroundStyle(.secondary)

            NavigationLink(destination: RegisterView(isLoggedIn: $isLoggedIn)
                .environmentObject(languageManager)
                .navigationBarBackButtonHidden(false)
            ) {
                Text(LocalizedString("login.signUp"))
                    .font(.coppelCTA)
                    .foregroundStyle(Color.coppelBlue)
            }
            .accessibilityLabel(LocalizedString("login.signUp"))
            .accessibilityHint(LocalizedString("login.signUpHint"))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    // MARK: - Login Handlers

    private func handleEmailLogin() {
        let emailToLogin: String

        if selectedTab == 0 {
            // Buscador mode: use search email
            emailToLogin = searchEmail.trimmingCharacters(in: .whitespaces)
        } else {
            // Usuarios mode: use selected user email
            guard let user = selectedUser else { return }
            emailToLogin = user.email
        }

        // Loguear el usuario en el UserManager
        if userManager.loginUser(withEmail: emailToLogin) {
            if let loggedUser = userManager.currentUser {
                print("✅ Usuario logueado: \(loggedUser.name) (\(loggedUser.role.displayName))")

                // Guardar nombre del usuario para OnboardingWelcomeView
                UserDefaults.standard.set(loggedUser.name, forKey: "currentUserName")
            }

            // Guardar estado del Mundial
            UserDefaults.standard.set(isWorldCupToday, forKey: "isWorldCupToday")
            print("⚽ Hoy es el Mundial: \(isWorldCupToday ? "SÍ" : "NO")")

            // Marcar como logueado
            withAnimation {
                isLoggedIn = true
            }
        } else {
            // Show error - user not found
            print("❌ Usuario no encontrado con email: \(emailToLogin)")
        }
    }

    private func handleAppleLogin(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                let userIdentifier = appleIDCredential.user
                let fullName = appleIDCredential.fullName
                let email = appleIDCredential.email

                print("🍎 Login with Apple successful")
                print("   User ID: \(userIdentifier)")
                if let email = email {
                    print("   Email: \(email)")
                }

                // Guardar nombre del usuario para OnboardingWelcomeView
                var userName = LocalizedString("login.defaultUser")
                if let fullName = fullName {
                    let firstName = fullName.givenName ?? ""
                    let lastName = fullName.familyName ?? ""
                    userName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
                    if userName.isEmpty {
                        userName = LocalizedString("login.defaultUser")
                    }
                    print("   Name: \(userName)")
                }
                UserDefaults.standard.set(userName, forKey: "currentUserName")

                // Save user info and log in
                withAnimation {
                    isLoggedIn = true
                }
            }

        case .failure(let error):
            print("❌ Apple Sign In failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Confetti Functions

    private func initializeConfetti() {
        let screenWidth = UIScreen.main.bounds.width
        confetti = (0..<50).map { _ in
            ConfettiPiece2(
                x: CGFloat.random(in: 0...screenWidth),
                y: -50,
                rotation: Double.random(in: 0...360),
                color: [
                    Color.red, Color.orange, Color.yellow,
                    Color.green, Color.blue, Color.purple,
                    Color.pink, Color.cyan
                ].randomElement() ?? .blue,
                scale: CGFloat.random(in: 0.5...1.0)
            )
        }
    }

    private func startConfettiAnimation() {
        for index in confetti.indices {
            let delay = Double(index) * 0.02
            let duration = Double.random(in: 2...4)

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeIn(duration: duration)) {
                    confetti[index].y = UIScreen.main.bounds.height + 100
                    confetti[index].rotation += 720
                }
            }
        }
    }
}

// MARK: - User Selection Card Component
struct UserSelectionCard: View {
    let user: User
    let isSelected: Bool
    let action: () -> Void

    private var avatarGradient: LinearGradient {
        switch user.role {
        case .admin:
            return LinearGradient(
                colors: [Color.coppelOrange.opacity(0.8), Color.coppelRed.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .merchant:
            return LinearGradient(
                colors: [Color.coppelPurple.opacity(0.8), Color.coppelPink.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .user:
            return LinearGradient(
                colors: [Color.coppelBlue.opacity(0.8), Color.coppelLightBlue.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var avatarColor: Color {
        switch user.role {
        case .admin: return .coppelOrange
        case .merchant: return .coppelPurple
        case .user: return .coppelBlue
        }
    }

    private var roleIcon: String {
        switch user.role {
        case .admin: return "crown.fill"
        case .merchant: return "bag.fill"
        case .user: return "person.fill"
        }
    }

    private var shadowColor: Color {
        isSelected ? Color.coppelBlue.opacity(0.2) : Color.coppelDarkBlue.opacity(0.05)
    }

    private var shadowRadius: CGFloat {
        isSelected ? 12 : 6
    }

    private var shadowY: CGFloat {
        isSelected ? 6 : 3
    }

    var body: some View {
        Button(action: action) {
            cardContent
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(user.name), \(user.email), \(user.role.displayName)")
        .accessibilityValue(isSelected ? LocalizedString("login.selected") : LocalizedString("login.notSelected"))
        .accessibilityHint(LocalizedString("login.selectUserHint"))
        .accessibilityAddTraits(.isButton)
    }

    private var cardContent: some View {
        HStack(spacing: 14) {
            avatarView
            userInfoView
            Spacer()

            if isSelected {
                checkmarkView
            }
        }
        .padding(18)
        .background(cardBackground)
        .overlay(cardBorder)
        .scaleEffect(CGFloat(isSelected ? 1.0 : 0.98))
    }

    private var avatarView: some View {
        Group {
            if let imageName = user.profileImage {
                // User has a custom profile image
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(avatarGradient, lineWidth: 3)
                    )
                    .shadow(
                        color: avatarColor.opacity(0.3),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            } else {
                // Default gradient avatar
                ZStack {
                    Circle()
                        .fill(avatarGradient)
                        .frame(width: 56, height: 56)
                        .shadow(
                            color: avatarColor.opacity(0.3),
                            radius: 8,
                            x: 0,
                            y: 4
                        )

                    Image(systemName: roleIcon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
        }
    }

    private var userInfoView: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(user.name)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.primary)

            Text(user.email)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)

            roleBadge
        }
    }

    private var roleBadge: some View {
        Text(user.role.displayName)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(avatarColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(avatarColor.opacity(0.15))
            )
    }

    private var checkmarkView: some View {
        Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 26))
            .foregroundStyle(Color.coppelBlue)
            .transition(.scale.combined(with: .opacity))
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(.white)
            .shadow(
                color: shadowColor,
                radius: shadowRadius,
                x: 0,
                y: shadowY
            )
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: CoppelTheme.CornerRadius.lg, style: .continuous)
            .strokeBorder(isSelected ? Color.coppelBlue : Color.clear, lineWidth: 2)
    }
    private var sponsorLogosSection: some View {
        HStack(spacing: 0) {
            // Fundación Coppel (izquierda)
            // [Asset: FundacionCoppelLogoWhite]
            Image("Fundacion-Coppel-Logo")
                .resizable()
                .scaledToFit()
                .frame(height: 32)

            Spacer()

            // Divisor vertical fino en white
            Rectangle()
                .fill(Color.white.opacity(0.4))
                .frame(width: 1, height: 32)

            Spacer()

            // Coppel Emprende (derecha)
            // [Asset: CoppelEmprendeLogoWhite]
            Image("Coppel-Emprende-Logo")
                .resizable()
                .scaledToFit()
                .frame(height: 48)
        }
        .frame(maxWidth: .infinity)
    }

}

// MARK: - Rainbow Border Component
struct RainbowBorderView: View {
    @State private var rotation: Double = 0

    private let rainbowColors: [Color] = [
        .red,
        .orange,
        .yellow,
        .green,
        .blue,
        .purple,
        .pink,
        .red
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Main rotating rainbow gradient border
                Capsule()
                    .stroke(
                        AngularGradient(
                            colors: rainbowColors,
                            center: .center,
                            startAngle: .degrees(rotation),
                            endAngle: .degrees(rotation + 360)
                        ),
                        lineWidth: 2.5
                    )

                // Outer glow effect
                Capsule()
                    .stroke(
                        AngularGradient(
                            colors: rainbowColors.map { $0.opacity(0.5) },
                            center: .center,
                            startAngle: .degrees(rotation + 30),
                            endAngle: .degrees(rotation + 390)
                        ),
                        lineWidth: 3
                    )
                    .blur(radius: 3)
                    .scaleEffect(CGFloat(1.02))
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

// MARK: - Preview
#Preview {
    LoginView(isLoggedIn: .constant(false))
        .environmentObject(LanguageManager.shared)
}
