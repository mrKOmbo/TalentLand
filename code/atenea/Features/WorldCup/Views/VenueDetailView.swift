//
//  VenueDetailView.swift
//  Atenea
//
//  Created by Claude on 10/29/25.
//

import SwiftUI
import MapKit

struct VenueDetailView: View {
    let venue: WorldCupVenue
    @Binding var isPresented: Bool
    @State private var funFactsExpanded = false
    @State private var matchesExpanded = true // Partidos expandidos por defecto
    @State private var dragOffset: CGFloat = 0
    var onDismiss: (() -> Void)?
    var onGetDirections: (() -> Void)? // Callback para abrir direcciones

    // Función para abrir en Apple Maps (fallback)
    private func openInMaps() {
        let coordinate = venue.coordinate
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = venue.name

        // Abrir con direcciones en modo conducción
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .center) {
                // Fondo semi-transparente con blur para cerrar al tocar fuera
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isPresented = false
                            onDismiss?()
                        }
                    }
                    .zIndex(0) // Fondo en el nivel más bajo

                // Panel centrado y más grande
                VStack(spacing: 0) {
                    // Marcador de sede más grande y atractivo
                    VStack(spacing: 0) {
                        // Pin/Marcador visual mejorado
                        ZStack {
                            // Círculo exterior con sombra
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [venue.primaryColor, venue.secondaryColor]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 48, height: 48)
                                .shadow(color: venue.primaryColor.opacity(0.8), radius: 12, x: 0, y: 4)
                                .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 2)

                            Circle()
                                .stroke(Color.white, lineWidth: 3)
                                .frame(width: 48, height: 48)

                            Image(systemName: "soccerball.circle.fill")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.4), radius: 3)
                        }
                        .offset(y: 12)

                        // Línea conectora más elegante
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        venue.primaryColor.opacity(0.8),
                                        venue.primaryColor.opacity(0.4)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 3, height: 12)
                    }
                    .zIndex(10)

                    // Contenido del panel
                    VStack(spacing: 0) {
                        // Header más atractivo con background completo
                        ZStack {
                            // Background con gradiente mejorado
                            venue.gradient
                                .overlay(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.black.opacity(0.3),
                                            Color.clear,
                                            Color.black.opacity(0.1)
                                        ]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )

                            // Contenido del header
                            VStack(spacing: 8) {
                                // Barra de arrastre con gesture mejorada
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white.opacity(0.5))
                                    .frame(width: 50, height: 5)
                                    .padding(.top, 10)
                                    .padding(.bottom, 10)
                                    .gesture(
                                        DragGesture()
                                            .onChanged { value in
                                                // Solo permitir arrastre hacia abajo
                                                if value.translation.height > 0 {
                                                    dragOffset = value.translation.height
                                                }
                                            }
                                            .onEnded { value in
                                                // Si se arrastró más de 100 puntos, cerrar el modal
                                                if value.translation.height > 100 {
                                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                                        isPresented = false
                                                        onDismiss?()
                                                    }
                                                    dragOffset = 0
                                                } else {
                                                    // Si no, regresar a la posición original
                                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                                        dragOffset = 0
                                                    }
                                                }
                                            }
                                    )

                                // Nombre y ubicación mejorados
                                VStack(spacing: 6) {
                                    Text(venue.name)
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(2)
                                        .minimumScaleFactor(0.8)
                                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)

                                    HStack(spacing: 6) {
                                        Image(systemName: "mappin.circle.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white.opacity(0.9))
                                        Text("\(venue.city), \(venue.country)")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.white.opacity(0.95))
                                    }
                                    .shadow(color: .black.opacity(0.2), radius: 1)

                                    // Capacidad e Inauguración con mejor diseño
                                    HStack(spacing: 16) {
                                        HStack(spacing: 5) {
                                            Image(systemName: "person.3.fill")
                                                .font(.system(size: 11))
                                            Text(venue.capacity)
                                                .font(.system(size: 12, weight: .semibold))
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(
                                            Capsule()
                                                .fill(Color.white.opacity(0.2))
                                        )

                                        HStack(spacing: 5) {
                                            Image(systemName: "calendar")
                                                .font(.system(size: 11))
                                            Text(venue.inauguration)
                                                .font(.system(size: 12, weight: .semibold))
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(
                                            Capsule()
                                                .fill(Color.white.opacity(0.2))
                                        )
                                    }
                                    .foregroundColor(.white.opacity(0.9))

                                    // Botón para obtener direcciones mejorado
                                    Button(action: {
                                        // Primero cerrar el modal de detalle
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            isPresented = false
                                        }
                                        // Luego abrir direcciones
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            onGetDirections?()
                                        }
                                    }) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "location.fill")
                                                .font(.system(size: 14, weight: .semibold))
                                            Text("Cómo llegar")
                                                .font(.system(size: 15, weight: .bold))
                                        }
                                        .foregroundColor(.white)
                                        .frame(maxWidth: 200)
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 12)
                                        .background(
                                            LinearGradient(
                                                colors: [venue.primaryColor, venue.secondaryColor],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .cornerRadius(16)
                                        .shadow(color: venue.primaryColor.opacity(0.5), radius: 8, x: 0, y: 4)
                                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                                    }
                                    .padding(.top, 10)
                                }
                                .padding(.horizontal, 14)
                                .padding(.bottom, 8)
                            }
                        }

                        // Contenido scrolleable con mejor espaciado
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 16) {
                                // Sección de Partidos (expandible mejorada)
                                VStack(spacing: 0) {
                                    Button(action: {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                            matchesExpanded.toggle()
                                        }
                                    }) {
                                        HStack(spacing: 10) {
                                            Image(systemName: "soccerball.circle.fill")
                                                .font(.system(size: 18))
                                                .foregroundColor(venue.primaryColor)

                                            Text("PARTIDOS")
                                                .font(.system(size: 13, weight: .bold))
                                                .foregroundColor(.white)

                                            Text("\(venue.matches.count)")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 4)
                                                .background(
                                                    Capsule()
                                                        .fill(
                                                            LinearGradient(
                                                                colors: [venue.primaryColor, venue.primaryColor.opacity(0.8)],
                                                                startPoint: .leading,
                                                                endPoint: .trailing
                                                            )
                                                        )
                                                )

                                            Spacer()

                                            Image(systemName: matchesExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                                                .font(.system(size: 18))
                                                .foregroundColor(venue.primaryColor)
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 14)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.white.opacity(0.08))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(
                                                            LinearGradient(
                                                                colors: [venue.primaryColor.opacity(0.4), venue.primaryColor.opacity(0.2)],
                                                                startPoint: .leading,
                                                                endPoint: .trailing
                                                            ),
                                                            lineWidth: 1.5
                                                        )
                                                )
                                        )
                                        .padding(.horizontal, 12)
                                        .shadow(color: venue.primaryColor.opacity(0.2), radius: 4, x: 0, y: 2)
                                    }
                                    .buttonStyle(PlainButtonStyle())

                                    if matchesExpanded {
                                        VStack(spacing: 10) {
                                            ForEach(Array(venue.matches.prefix(3).enumerated()), id: \.element.id) { index, match in
                                                CompactMatchCard(match: match, color: venue.primaryColor, index: index + 1)
                                            }
                                            if venue.matches.count > 3 {
                                                Text("+\(venue.matches.count - 3) partidos más")
                                                    .font(.system(size: 12, weight: .semibold))
                                                    .foregroundColor(.white.opacity(0.6))
                                                    .padding(.vertical, 6)
                                                    .padding(.horizontal, 16)
                                                    .background(
                                                        Capsule()
                                                            .fill(Color.white.opacity(0.08))
                                                    )
                                            }
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.top, 10)
                                        .transition(.opacity.combined(with: .move(edge: .top)))
                                    }
                                }

                                // Sección de Datos Curiosos (expandible mejorada)
                                VStack(spacing: 0) {
                                    Button(action: {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                            funFactsExpanded.toggle()
                                        }
                                    }) {
                                        HStack(spacing: 10) {
                                            Image(systemName: "lightbulb.fill")
                                                .font(.system(size: 18))
                                                .foregroundColor(.yellow)

                                            Text("DATOS CURIOSOS")
                                                .font(.system(size: 13, weight: .bold))
                                                .foregroundColor(.white)

                                            Text("\(venue.funFacts.count)")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 4)
                                                .background(
                                                    Capsule()
                                                        .fill(
                                                            LinearGradient(
                                                                colors: [venue.primaryColor, venue.primaryColor.opacity(0.8)],
                                                                startPoint: .leading,
                                                                endPoint: .trailing
                                                            )
                                                        )
                                                )

                                            Spacer()

                                            Image(systemName: funFactsExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                                                .font(.system(size: 18))
                                                .foregroundColor(venue.primaryColor)
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 14)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.white.opacity(0.08))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(
                                                            LinearGradient(
                                                                colors: [venue.primaryColor.opacity(0.4), venue.primaryColor.opacity(0.2)],
                                                                startPoint: .leading,
                                                                endPoint: .trailing
                                                            ),
                                                            lineWidth: 1.5
                                                        )
                                                )
                                        )
                                        .padding(.horizontal, 12)
                                        .shadow(color: venue.primaryColor.opacity(0.2), radius: 4, x: 0, y: 2)
                                    }
                                    .buttonStyle(PlainButtonStyle())

                                    if funFactsExpanded {
                                        VStack(spacing: 10) {
                                            ForEach(Array(venue.funFacts.prefix(2).enumerated()), id: \.offset) { index, fact in
                                                CompactFunFactCard(fact: fact, index: index + 1, color: venue.primaryColor)
                                            }
                                            if venue.funFacts.count > 2 {
                                                Text("+\(venue.funFacts.count - 2) datos más")
                                                    .font(.system(size: 12, weight: .semibold))
                                                    .foregroundColor(.white.opacity(0.6))
                                                    .padding(.vertical, 6)
                                                    .padding(.horizontal, 16)
                                                    .background(
                                                        Capsule()
                                                            .fill(Color.white.opacity(0.08))
                                                    )
                                            }
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.top, 10)
                                        .transition(.opacity.combined(with: .move(edge: .top)))
                                    }
                                }

                                Color.clear.frame(height: 4)
                            }
                            .padding(.top, 12)
                        }
                        .frame(maxHeight: 280)

                        // Botón de cerrar mejorado
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                isPresented = false
                                onDismiss?()
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16))
                                Text("Cerrar")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.15),
                                        Color.white.opacity(0.08)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.03))
                    }
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial)

                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white.opacity(0.15),
                                            Color.white.opacity(0.08)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: venue.primaryColor.opacity(0.4), radius: 25, x: 0, y: -10)
                    .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: -8)
                }
                .frame(maxWidth: 380, maxHeight: 620)
                .padding(.horizontal, 20)
                .padding(.bottom, 100) // Mayor padding para no pegar al tab bar
                .offset(y: dragOffset)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(1) // Panel por encima del fondo para capturar gestos
            }
        }
    }
}

// Tarjeta de partido mejorada
struct CompactMatchCard: View {
    let match: WorldCupMatch
    let color: Color
    let index: Int

    var body: some View {
        HStack(spacing: 10) {
            // Número de partido mejorado
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [color, color.opacity(0.7)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 38, height: 38)
                    .shadow(color: color.opacity(0.6), radius: 5, x: 0, y: 3)

                Text("\(index)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(match.stage)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(color.opacity(0.25))
                    )

                Text(match.date)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)

                if match.time != "Por definir" {
                    Text(match.time)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }

                if match.teams != "Por definir" {
                    Text(match.teams)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(1)
                }
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            LinearGradient(
                                colors: [color.opacity(0.4), color.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
        )
        .shadow(color: color.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}

// Tarjeta de dato curioso mejorada
struct CompactFunFactCard: View {
    let fact: String
    let index: Int
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.3), color.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)

                Text("\(index)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(color)
            }
            .padding(.top, 2)

            Text(fact)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.95))
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(3)

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            LinearGradient(
                                colors: [color.opacity(0.3), color.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
        )
        .shadow(color: color.opacity(0.15), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    ZStack {
        // Fondo de mapa simulado
        LinearGradient(
            gradient: Gradient(colors: [
                Color.blue.opacity(0.4),
                Color.green.opacity(0.3)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        VenueDetailView(
            venue: WorldCupVenue.allVenues[1], // Estadio Azteca
            isPresented: .constant(true)
        )
    }
}
