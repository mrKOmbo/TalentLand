//
//  HelpView.swift
//  atenea
//
//  Ultra-modern help view with glassmorphism design
//

import SwiftUI

struct HelpTopic: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let gradient: [Color]
}

struct FAQItem: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
}

struct HelpView: View {
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    @State private var selectedFAQ: FAQItem?
    @State private var showContactSheet = false

    private let helpTopics = [
        HelpTopic(
            icon: "map.fill",
            title: "Navegación",
            description: "Cómo usar el mapa y encontrar rutas",
            gradient: [Color.blue, Color.cyan]
        ),
        HelpTopic(
            icon: "ticket.fill",
            title: "Reservaciones",
            description: "Cómo reservar simulaciones",
            gradient: [Color.green, Color.mint]
        ),
        HelpTopic(
            icon: "star.fill",
            title: "Favoritos",
            description: "Guarda tus lugares preferidos",
            gradient: [Color.orange, Color.yellow]
        ),
        HelpTopic(
            icon: "gearshape.fill",
            title: "Configuración",
            description: "Personaliza la aplicación",
            gradient: [Color.purple, Color.pink]
        )
    ]

    private let faqs = [
        FAQItem(
            question: "¿Cómo busco una estación?",
            answer: "Puedes buscar estaciones usando la barra de búsqueda en el mapa principal, o explorando las líneas del metro desde el menú lateral."
        ),
        FAQItem(
            question: "¿Cómo reservo una simulación?",
            answer: "Ve a la sección FIFA 2026 en el menú, selecciona 'Reservar' y elige la sede y horario que prefieras."
        ),
        FAQItem(
            question: "¿Puedo usar la app sin internet?",
            answer: "Algunas funciones básicas están disponibles sin conexión, pero necesitarás internet para navegar y hacer reservaciones."
        ),
        FAQItem(
            question: "¿Cómo cambio el idioma?",
            answer: "Ve a Configuración y selecciona tu idioma preferido de las opciones disponibles."
        )
    ]

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.95, green: 0.97, blue: 1.0),
                    Color(red: 0.98, green: 0.95, blue: 1.0)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Ayuda")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.indigo, Color.blue]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )

                            Text("¿En qué podemos ayudarte?")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.gray)
                        }

                        Spacer()

                        Button(action: {
                            dismiss()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 40, height: 40)
                                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)

                                Image(systemName: "xmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    // Search Bar
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.blue, Color.cyan]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        TextField("Buscar ayuda...", text: $searchText)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
                    )
                    .padding(.horizontal, 20)

                    // Quick Actions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Temas Populares")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 20)

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(helpTopics) { topic in
                                helpTopicCard(topic: topic)
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    // FAQ Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.purple.opacity(0.15), Color.pink.opacity(0.1)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 36, height: 36)

                                Image(systemName: "questionmark.circle.fill")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.purple, Color.pink]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }

                            Text("Preguntas Frecuentes")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal, 20)

                        VStack(spacing: 12) {
                            ForEach(faqs) { faq in
                                faqCard(faq: faq)
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    // Contact Support
                    VStack(spacing: 16) {
                        Button(action: {
                            showContactSheet = true
                        }) {
                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.green.opacity(0.15), Color.mint.opacity(0.1)]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 56, height: 56)

                                    Image(systemName: "message.fill")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundStyle(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.green, Color.mint]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Contactar Soporte")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.primary)

                                    Text("Estamos aquí para ayudarte 24/7")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.gray)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.gray.opacity(0.5))
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white)
                                    .shadow(color: Color.green.opacity(0.15), radius: 12, x: 0, y: 6)
                            )
                        }
                    }
                    .padding(.horizontal, 20)

                    // Social Links
                    VStack(spacing: 12) {
                        Text("Síguenos")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.gray)

                        HStack(spacing: 16) {
                            socialButton(icon: "globe", color: Color.blue)
                            socialButton(icon: "envelope.fill", color: Color.red)
                            socialButton(icon: "phone.fill", color: Color.green)
                        }
                    }
                    .padding(.vertical, 20)

                    Spacer(minLength: 40)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showContactSheet) {
            contactSupportSheet
        }
    }

    // MARK: - Components

    private func helpTopicCard(topic: HelpTopic) -> some View {
        Button(action: {
            // Action
        }) {
            VStack(alignment: .leading, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: topic.gradient.map { $0.opacity(0.15) }),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)

                    Image(systemName: topic.icon)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: topic.gradient),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(topic.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)

                    Text(topic.description)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .frame(height: 160)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
            )
        }
        .buttonStyle(ModernButtonStyle())
    }

    private func faqCard(faq: FAQItem) -> some View {
        DisclosureGroup {
            Text(faq.answer)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.gray)
                .padding(.top, 8)
        } label: {
            HStack {
                Text(faq.question)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)

                Spacer()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
        .tint(Color.purple)
    }

    private func socialButton(icon: String, color: Color) -> some View {
        Button(action: {
            // Social action
        }) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [color.opacity(0.15), color.opacity(0.1)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(color)
            }
        }
        .buttonStyle(ModernButtonStyle())
    }

    private var contactSupportSheet: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.95, green: 0.97, blue: 1.0),
                        Color(red: 0.98, green: 0.95, blue: 1.0)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 24) {
                    // Header Icon
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        Color.green.opacity(0.3),
                                        Color.mint.opacity(0.15),
                                        Color.clear
                                    ]),
                                    center: .center,
                                    startRadius: 30,
                                    endRadius: 60
                                )
                            )
                            .frame(width: 100, height: 100)
                            .blur(radius: 15)

                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.green, Color.mint]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                            .shadow(color: Color.green.opacity(0.4), radius: 12, x: 0, y: 6)

                        Image(systemName: "message.fill")
                            .font(.system(size: 35, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 40)

                    VStack(spacing: 12) {
                        Text("¿Necesitas Ayuda?")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)

                        Text("Nuestro equipo está listo para asistirte")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }

                    VStack(spacing: 16) {
                        contactOptionButton(
                            icon: "envelope.fill",
                            title: "Email",
                            subtitle: "soporte@atenea.com",
                            gradient: [Color.blue, Color.cyan]
                        )

                        contactOptionButton(
                            icon: "phone.fill",
                            title: "Teléfono",
                            subtitle: "+52 55 1234 5678",
                            gradient: [Color.green, Color.mint]
                        )

                        contactOptionButton(
                            icon: "message.fill",
                            title: "Chat en vivo",
                            subtitle: "Respuesta inmediata",
                            gradient: [Color.purple, Color.pink]
                        )
                    }
                    .padding(.horizontal, 20)

                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showContactSheet = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.gray.opacity(0.5))
                    }
                }
            }
        }
    }

    private func contactOptionButton(icon: String, title: String, subtitle: String, gradient: [Color]) -> some View {
        Button(action: {
            // Contact action
        }) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: gradient.map { $0.opacity(0.15) }),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)

                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: gradient),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.gray.opacity(0.5))
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
            )
        }
        .buttonStyle(ModernButtonStyle())
    }
}

#Preview {
    HelpView()
}
