//
//  CoppelEmprenderVerificationView.swift
//  Atenea
//
//  Verification flow for Coppel Emprende accounts
//

import SwiftUI

struct CoppelEmprenderVerificationView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var isLoggedIn: Bool
    let userInfo: UserRegistrationInfo

    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var isVerifying = false
    @State private var selectedMobility: String = "mobile"
    @State private var navigateToMerchantRegistration = false

    private var canVerify: Bool {
        !fullName.isEmpty && !email.isEmpty
    }

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            VStack(spacing: 0) {
                progressBar
                scrollableContent
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Atrás")
                            .font(.system(size: 17, weight: .regular))
                    }
                    .foregroundStyle(.blue)
                }
            }
        }
        .navigationDestination(isPresented: $navigateToMerchantRegistration) {
            MerchantRegistrationViewPrefilledWrapper(
                isLoggedIn: $isLoggedIn,
                userInfo: userInfo,
                prefilledBusinessName: fullName,
                selectedMobility: selectedMobility
            )
        }
    }

    // MARK: - View Components

    private var progressBar: some View {
        VStack(spacing: 12) {
            HStack(spacing: 4) {
                Text("Paso 1 de 2")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color.gray.opacity(0.2))

                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color.yellow)
                        .frame(width: geometry.size.width * 0.5)
                }
            }
            .frame(height: 6)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    private var scrollableContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                titleSection
                formFields
                mobilitySelection
                verifyButton
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
        }
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Verificar cuenta Coppel Emprende")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.black)

            Text("Ingresa tu nombre y correo para verificar tu cuenta")
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(.gray)
                .lineSpacing(4)
        }
    }

    private var formFields: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Full Name
            VStack(alignment: .leading, spacing: 8) {
                Text("Nombre completo")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.black)

                TextField("Tu nombre registrado", text: $fullName)
                    .font(.system(size: 16, weight: .regular))
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.white)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            }

            // Email
            VStack(alignment: .leading, spacing: 8) {
                Text("Correo electrónico")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.black)

                TextField("Tu correo registrado", text: $email)
                    .font(.system(size: 16, weight: .regular))
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.white)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            }
        }
    }

    private var mobilitySelection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("¿Dónde operas?")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.black)

            VStack(spacing: 12) {
                // Mobile option
                Button(action: { selectedMobility = "mobile" }) {
                    HStack(spacing: 12) {
                        Image(systemName: selectedMobility == "mobile" ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 20))
                            .foregroundStyle(selectedMobility == "mobile" ? .orange : .gray)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Ambulante (ruta)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.black)

                            Text("Múltiples puntos en el mapa")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundStyle(.gray)
                        }

                        Spacer()
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(selectedMobility == "mobile" ? Color.orange.opacity(0.1) : Color.gray.opacity(0.05))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(
                                selectedMobility == "mobile" ? Color.orange.opacity(0.3) : Color.gray.opacity(0.1),
                                lineWidth: 1
                            )
                    )
                }
                .buttonStyle(.plain)

                // Static option
                Button(action: { selectedMobility = "static" }) {
                    HStack(spacing: 12) {
                        Image(systemName: selectedMobility == "static" ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 20))
                            .foregroundStyle(selectedMobility == "static" ? .orange : .gray)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Punto fijo (local)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.black)

                            Text("Un solo lugar")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundStyle(.gray)
                        }

                        Spacer()
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(selectedMobility == "static" ? Color.orange.opacity(0.1) : Color.gray.opacity(0.05))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(
                                selectedMobility == "static" ? Color.orange.opacity(0.3) : Color.gray.opacity(0.1),
                                lineWidth: 1
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var verifyButton: some View {
        Button(action: { verifyAndContinue() }) {
            HStack(spacing: 8) {
                if isVerifying {
                    ProgressView()
                } else {
                    Text("Verificar cuenta")
                }
            }
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(canVerify && !isVerifying ? Color.yellow : Color.gray.opacity(0.2))
            )
        }
        .disabled(!canVerify || isVerifying)
    }

    // MARK: - Actions

    private func verifyAndContinue() {
        isVerifying = true

        // Simulate verification
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isVerifying = false
            navigateToMerchantRegistration = true
        }
    }
}

// MARK: - Wrapper para pasar datos a MerchantRegistrationView

struct MerchantRegistrationViewPrefilledWrapper: View {
    @Binding var isLoggedIn: Bool
    let userInfo: UserRegistrationInfo
    let prefilledBusinessName: String
    let selectedMobility: String

    var body: some View {
        MerchantRegistrationView(
            isLoggedIn: $isLoggedIn,
            userInfo: userInfo
        )
    }
}
