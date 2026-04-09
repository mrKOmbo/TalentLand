//
//  StickerAlbumView.swift
//  atenea
//
//  Vista del Álbum de Pegatinas tipo Panini
//

import SwiftUI
import AVFoundation

// Vista de Álbum de Pegatinas tipo Panini
struct StickerAlbumView: View {
    @Binding var selectedTab: Int
    @ObservedObject var collectionManager: StickerCollectionManager
    @Binding var lastCollectedVenue: WorldCupVenue?
    @Binding var showCollectionAnimation: Bool
    @State private var currentPageIndex: Int = 0
    @State private var showSections: Bool = false
    @State private var selectedSection: AlbumSection?
    @State private var showPaniniAlbum: Bool = false
    @State private var showARView: Bool = false
    @State private var showCameraPermissionAlert: Bool = false
    @StateObject private var cameraPermissionManager = CameraPermissionManager()

    let albumPages = AlbumDataGenerator.generateAlbum()

    var totalStickers: Int {
        albumPages.reduce(0) { $0 + $1.stickerSlots.count }
    }

    var progress: Double {
        Double(collectionManager.collectedStickers.count) / Double(totalStickers)
    }

    var body: some View {
        ZStack(alignment: .top) {
            // Fondo con textura tipo papel - Solo ignorar el top, respetar el bottom para el tab bar
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.95, green: 0.94, blue: 0.92),
                    Color(red: 0.92, green: 0.90, blue: 0.88)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.top)

            VStack(spacing: 0) {
                // Header con progreso
                albumHeader

                // Navegación de páginas
                if showSections {
                    sectionGridView
                } else {
                    albumPageView
                }
            }

            // Modal del Álbum Panini
            if showPaniniAlbum {
                PaniniAlbumView(isPresented: $showPaniniAlbum)
                    .zIndex(1000)
                    .transition(.opacity)
            }

            // Botón AR flotante (abajo derecha)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    arButton
                        .padding(.trailing, 20)
                        .padding(.bottom, 100)
                }
            }
        }
        .onChange(of: lastCollectedVenue) { oldValue, newValue in
            if let venue = newValue {
                navigateToVenuePage(venue)
            }
        }
        .fullScreenCover(isPresented: $showARView) {
            ARPosterView(
                collectionManager: collectionManager,
                onVenueDetected: { venue in
                    // Callback cuando se detecta una sede
                    print("Sede detectada desde AR: \(venue.name)")
                },
                onStickersCollected: { venue in
                    // Callback cuando se coleccionan stickers
                    lastCollectedVenue = venue
                    showCollectionAnimation = true
                }
            )
        }
        .alert(LocalizedString("album.cameraPermissionRequired"), isPresented: $showCameraPermissionAlert) {
            Button(LocalizedString("action.openSettings")) {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
            Button(LocalizedString("action.cancel"), role: .cancel) { }
        } message: {
            Text(LocalizedString("album.cameraPermissionMessage"))
        }
    }

    // MARK: - Navigate to Venue Page
    private func navigateToVenuePage(_ venue: WorldCupVenue) {
        // Encontrar el índice de la página de esta sede
        if let venueIndex = WorldCupVenue.allVenues.firstIndex(where: { $0.id == venue.id }) {
            // Las páginas de sedes empiezan en la página 4 (después de intro)
            let targetPageIndex = 4 + venueIndex

            // Cerrar vista de secciones si está abierta
            showSections = false

            // Navegar a la página con animación
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    currentPageIndex = targetPageIndex
                }

                // Resetear después de mostrar
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    lastCollectedVenue = nil
                    showCollectionAnimation = false
                }
            }
        }
    }

    // MARK: - AR Button
    private var arButton: some View {
        Button(action: {
            openARView()

            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
        }) {
            VStack(spacing: 8) {
                ZStack {
                    // Círculo de fondo con gradiente vibrante
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "#1C42E8"),
                                    Color(hex: "#1C42E8"),
                                    Color(hex: "#1C42E8")
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)

                    // Anillo pulsante exterior
                    Circle()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "#1C42E8"),
                                    Color(hex: "#1C42E8")
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 64, height: 64)
                        .scaleEffect(CGFloat(1.2))
                        .opacity(0.3)

                    // Brillo superior
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.5),
                                    Color.clear
                                ]),
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                        .frame(width: 64, height: 64)

                    // Ícono de cámara AR
                    Image(systemName: "camera.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                }
                .shadow(color: Color(hex: "#1C42E8").opacity(0.6), radius: 20, x: 0, y: 8)
                .overlay(
                    Circle()
                        .stroke(Color(white: 1.0, opacity: 0.3), lineWidth: 1.5)
                        .frame(width: CGFloat(64), height: CGFloat(64))
                )

                // Texto explicativo
                Text(LocalizedString("album.scan"))
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color(hex: "#1C42E8"))
                    )
                    .shadow(color: Color(hex: "#1C42E8").opacity(0.5), radius: 8, x: 0, y: 4)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func openARView() {
        let cameraStatus = cameraPermissionManager.checkPermission()

        switch cameraStatus {
        case .authorized:
            // Permiso concedido, abrir AR
            showARView = true

        case .notDetermined:
            // Solicitar permiso
            cameraPermissionManager.requestPermission()

            // Esperar un momento y verificar
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if cameraPermissionManager.permissionGranted {
                    showARView = true
                } else {
                    showCameraPermissionAlert = true
                }
            }

        case .denied, .restricted:
            // Permiso denegado, mostrar alerta
            showCameraPermissionAlert = true

        @unknown default:
            showCameraPermissionAlert = true
        }
    }

    // MARK: - Album Header
    private var albumHeader: some View {
        VStack(spacing: 0) {
            // Top section con título y botones - más compacto e intuitivo
            HStack(spacing: 12) {
                // Botón de vista de secciones - más claro
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        showSections.toggle()
                    }

                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                }) {
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(hex: "#1C42E8").opacity(0.15),
                                            Color(hex: "#F0D224").opacity(0.15)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 48, height: 48)
                                .overlay(
                                    Circle()
                                        .stroke(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color(hex: "#1C42E8"),
                                                    Color(hex: "#F0D224")
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 2
                                        )
                                )

                            Image(systemName: showSections ? "book.closed.fill" : "square.grid.2x2.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(hex: "#1C42E8"),
                                            Color(hex: "#1C42E8")
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }

                        Text(showSections ? LocalizedString("album.album") : LocalizedString("album.sections"))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(hex: "#1C42E8"))
                    }
                }
                .shadow(color: Color(hex: "#1C42E8").opacity(0.3), radius: 8, x: 0, y: 4)

                // Título y progreso - más claro
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(LocalizedString("album.myAlbum"))
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(hex: "#081754"),
                                        Color(hex: "#4A4A4A")
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )

                        // Badge de progreso circular
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.2), lineWidth: 3)
                                .frame(width: 32, height: 32)

                            Circle()
                                .trim(from: 0, to: progress)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color(hex: "#1C42E8"), Color(hex: "#F0D224")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                                )
                                .frame(width: 32, height: 32)
                                .rotationEffect(.degrees(-90))

                            Text("\(Int(progress * 100))%")
                                .font(.system(size: 8, weight: .black))
                                .foregroundColor(Color(hex: "#1C42E8"))
                        }
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color(hex: "#F0D224"))

                        Text("\(collectionManager.collectedStickers.count) \(LocalizedString("album.of")) \(totalStickers) \(LocalizedString("album.collected"))")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Botón Álbum 2014 mejorado
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        showPaniniAlbum = true
                    }
                }) {
                    ZStack {
                        // Fondo con gradiente animado
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(hex: "#1C42E8"),
                                        Color(hex: "#F0D224"),
                                        Color(hex: "#1C42E8")
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)

                        // Contenido
                        VStack(spacing: 3) {
                            Image(systemName: "book.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)

                            Text("2014")
                                .font(.system(size: 11, weight: .black))
                                .foregroundColor(.white)
                        }
                    }
                    .shadow(color: Color(hex: "#F0D224").opacity(0.5), radius: 12, x: 0, y: 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                    )
                }

                // Contador de páginas (si no está en vista de secciones)
                if !showSections {
                    VStack(spacing: 4) {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "#1C42E8"))

                        Text("\(currentPageIndex + 1)/\(albumPages.count)")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "#081754"))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: "#1C42E8").opacity(0.2), lineWidth: 1.5)
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 70)
            .padding(.bottom, 16)

            // Barra de progreso mejorada
            EnhancedProgressBar(progress: progress)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
        }
        .background(
            ZStack {
                // Fondo con gradiente sutil
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white,
                        Color(red: 0.98, green: 0.98, blue: 0.98)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Efecto de brillo superior
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.6),
                        Color.clear
                    ]),
                    startPoint: .top,
                    endPoint: .center
                )
            }
            .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 5)
        )
    }

    // MARK: - Album Page View
    private var albumPageView: some View {
        TabView(selection: $currentPageIndex) {
            ForEach(Array(albumPages.enumerated()), id: \.element.id) { index, page in
                AlbumPageDetailView(
                    page: page,
                    collectionManager: collectionManager,
                    highlightNewStickers: shouldHighlightPage(index)
                )
                .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .padding(.bottom, 100)
    }

    private func shouldHighlightPage(_ index: Int) -> Bool {
        guard showCollectionAnimation, let venue = lastCollectedVenue else {
            return false
        }

        if let venueIndex = WorldCupVenue.allVenues.firstIndex(where: { $0.id == venue.id }) {
            let targetPageIndex = 4 + venueIndex
            return index == targetPageIndex
        }

        return false
    }

    // MARK: - Section Grid View
    private var sectionGridView: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(AlbumSection.allCases) { section in
                    SectionCard(
                        section: section,
                        progress: sectionProgress(for: section)
                    ) {
                        // Navegar a la primera página de la sección
                        if let firstPageIndex = albumPages.firstIndex(where: { $0.section == section }) {
                            withAnimation {
                                currentPageIndex = firstPageIndex
                                showSections = false
                            }
                        }
                    }
                }
            }
            .padding(20)
            .padding(.bottom, 100)
        }
    }

    private func sectionProgress(for section: AlbumSection) -> Double {
        let sectionPages = albumPages.filter { $0.section == section }
        let totalStickersInSection = sectionPages.reduce(0) { $0 + $1.stickerSlots.count }
        let collectedInSection = sectionPages.reduce(0) { partialResult, page in
            partialResult + page.stickerSlots.filter { collectionManager.hasSticker($0.stickerId) }.count
        }
        return totalStickersInSection > 0 ? Double(collectedInSection) / Double(totalStickersInSection) : 0
    }
}

// MARK: - Album Page Detail View
struct AlbumPageDetailView: View {
    let page: AlbumPage
    @ObservedObject var collectionManager: StickerCollectionManager
    var highlightNewStickers: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header de la página
                VStack(spacing: 8) {
                    Text(page.title)
                        .font(SwiftUI.Font.system(size: 24, weight: .bold))
                        .foregroundColor(Color(hex: "#081754"))

                    if let subtitle = page.subtitle {
                        Text(subtitle)
                            .font(SwiftUI.Font.system(size: 16))
                            .foregroundColor(.gray)
                    }

                    // Badge de sección
                    HStack(spacing: 8) {
                        Image(systemName: page.section.icon)
                            .font(SwiftUI.Font.system(size: 12))
                        Text(page.section.rawValue)
                            .font(SwiftUI.Font.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(page.section.color)
                    )
                }
                .padding(.top, 20)

                // Grid de stickers según el layout
                stickerGrid
                    .padding(.horizontal, 20)
            }
            .padding(.bottom, 40)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private var stickerGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            ForEach(page.stickerSlots) { slot in
                StickerSlotView(
                    stickerId: slot.stickerId,
                    isSpecial: slot.isSpecialSlot,
                    isCollected: collectionManager.hasSticker(slot.stickerId),
                    shouldHighlight: highlightNewStickers && collectionManager.hasSticker(slot.stickerId),
                    label: slot.label
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        collectionManager.collectSticker(slot.stickerId)
                    }
                }
            }
        }
    }
}

// MARK: - Sticker Slot View
struct StickerSlotView: View {
    let stickerId: Int
    let isSpecial: Bool
    let isCollected: Bool
    var shouldHighlight: Bool = false
    var label: String? = nil
    let onTap: () -> Void

    @State private var showPeelEffect = false
    @State private var highlightPulse = false
    @State private var isPressed = false

    // Obtener el venue correspondiente si es un sticker de sede (14+)
    private var venue: WorldCupVenue? {
        guard stickerId >= 14 else { return nil }
        let venueIndex = stickerId - 14
        guard venueIndex < WorldCupVenue.allVenues.count else { return nil }
        return WorldCupVenue.allVenues[venueIndex]
    }

    var body: some View {
        VStack(spacing: 6) {
            Button(action: {
                if !isCollected {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()

                    showPeelEffect = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onTap()
                        showPeelEffect = false
                    }
                }
            }) {
                ZStack {
                // Anillo de resaltado pulsante para stickers recién agregados
                if shouldHighlight && isCollected {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "#1C42E8"),
                                    Color(hex: "#F0D224")
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 4
                        )
                        .scaleEffect(highlightPulse ? CGFloat(1.1) : CGFloat(1.0))
                        .opacity(highlightPulse ? 0.3 : 1.0)
                        .animation(
                            Animation.easeInOut(duration: 1.0)
                                .repeatForever(autoreverses: true),
                            value: highlightPulse
                        )
                        .onAppear {
                            highlightPulse = true
                        }

                    // Brillo exterior adicional
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "#1C42E8").opacity(0.2),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 1,
                                endRadius: 80
                            )
                        )
                        .scaleEffect(highlightPulse ? CGFloat(1.3) : CGFloat(1.0))
                        .opacity(highlightPulse ? 0.0 : 0.6)
                        .animation(
                            Animation.easeOut(duration: 1.5)
                                .repeatForever(autoreverses: false),
                            value: highlightPulse
                        )
                }

                // Fondo del slot - estilo HIG
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isCollected ? Color.white : Color(white: 0.97))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(
                                isCollected ?
                                    (shouldHighlight ?
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(hex: "#1C42E8"),
                                                Color(hex: "#F0D224")
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ) :
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.gray.opacity(0.2),
                                                Color.gray.opacity(0.2)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    ) :
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.gray.opacity(0.25),
                                            Color.gray.opacity(0.25)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                style: StrokeStyle(
                                    lineWidth: shouldHighlight && isCollected ? 3 : 1.5,
                                    dash: isCollected ? [] : [6, 3]
                                )
                            )
                    )
                    .shadow(
                        color: isCollected ? Color.black.opacity(0.08) : Color.clear,
                        radius: isCollected ? 8 : 0,
                        x: 0,
                        y: isCollected ? 4 : 0
                    )

                if isCollected {
                    // Sticker coleccionado - estilo HIG
                    VStack(spacing: 6) {
                        ZStack {
                            // Efecto de brillo para especiales
                            if isSpecial {
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            gradient: Gradient(colors: [
                                                Color(hex: "#F0D224").opacity(0.25),
                                                Color.clear
                                            ]),
                                            center: .center,
                                            startRadius: 10,
                                            endRadius: 40
                                        )
                                    )
                                    .frame(width: 80, height: 80)
                            }

                            // Mostrar imagen real del poster o ícono genérico
                            if let venue = venue {
                                Image(venue.imageName)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 85, height: 85)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            } else {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color(hex: "#1C42E8").opacity(0.15),
                                                    Color(hex: "#1C42E8").opacity(0.08)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 64, height: 64)

                                    Image(systemName: isSpecial ? "star.fill" : "soccerball")
                                        .font(SwiftUI.Font.system(size: 32, weight: .semibold))
                                        .foregroundStyle(
                                            isSpecial ?
                                                LinearGradient(
                                                    colors: [Color(hex: "#F0D224"), Color(hex: "#F0D224")],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ) :
                                                LinearGradient(
                                                    colors: [Color(hex: "#1C42E8"), Color(hex: "#1C42E8")],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                        )
                                        .symbolEffect(.bounce, value: showPeelEffect)
                                }
                            }
                        }

                        // Badge con número
                        Text("#\(stickerId)")
                            .font(SwiftUI.Font.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "#1C42E8"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(Color(hex: "#1C42E8").opacity(0.12))
                            )

                        // Badge "NUEVO" para stickers destacados
                        if shouldHighlight {
                            HStack(spacing: 3) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 8, weight: .bold))
                                Text(LocalizedString("album.new"))
                                    .font(.system(size: CGFloat(9), weight: .black))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: "#1C42E8"), Color(hex: "#1C42E8")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                            .shadow(color: Color(hex: "#1C42E8").opacity(0.5), radius: 6, x: 0, y: 3)
                            .scaleEffect(highlightPulse ? CGFloat(1.05) : CGFloat(0.95))
                            .animation(
                                Animation.easeInOut(duration: 0.6)
                                    .repeatForever(autoreverses: true),
                                value: highlightPulse
                            )
                        }
                    }
                    .padding(8)
                    .scaleEffect(showPeelEffect ? CGFloat(1.08) : (shouldHighlight ? CGFloat(1.02) : CGFloat(1.0)))
                    .rotation3DEffect(
                        .degrees(showPeelEffect ? 8 : 0),
                        axis: (x: 1, y: 1, z: 0)
                    )
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: showPeelEffect)
                } else {
                    // Slot vacío - estilo HIG
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.08))
                                .frame(width: 64, height: 64)

                            Image(systemName: "photo.badge.plus")
                                .font(SwiftUI.Font.system(size: 28, weight: .regular))
                                .foregroundColor(.gray.opacity(0.4))
                                .symbolEffect(.pulse, options: .repeating, value: isPressed)
                        }

                        Text("#\(stickerId)")
                            .font(SwiftUI.Font.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(.gray.opacity(0.5))
                    }
                    .padding(8)
                }
            }
            .frame(height: 140)
            .shadow(
                color: shouldHighlight && isCollected ? Color(hex: "#1C42E8").opacity(0.4) : Color.clear,
                radius: shouldHighlight && isCollected ? 10 : 0,
                x: 0,
                y: 0
            )
            }
            .buttonStyle(PlainButtonStyle())

            // Label del slot (nombre de la sede) - estilo HIG
            if let label = label {
                Text(label)
                    .font(SwiftUI.Font.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "#081754"))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 4)
            }
        }
    }
}

// MARK: - Section Card
struct SectionCard: View {
    let section: AlbumSection
    let progress: Double
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                // Fondo con gradiente
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white,
                                Color(red: 0.99, green: 0.99, blue: 0.99)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 16) {
                        // Ícono con efecto glassmorphism
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            section.color.opacity(0.2),
                                            section.color.opacity(0.1)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 68, height: 68)

                            Circle()
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            section.color.opacity(0.6),
                                            section.color.opacity(0.3)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                                .frame(width: 68, height: 68)

                            Image(systemName: section.icon)
                                .font(.system(size: 30, weight: .semibold))
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            section.color,
                                            section.color.opacity(0.7)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text(section.rawValue)
                                .font(.system(size: 22, weight: .heavy, design: .rounded))
                                .foregroundColor(Color(hex: "#081754"))

                            HStack(spacing: 8) {
                                Image(systemName: progress >= 1.0 ? "checkmark.circle.fill" : "clock.fill")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(progress >= 1.0 ? Color(hex: "#1C42E8") : section.color)

                                Text("\(Int(progress * 100))% \(LocalizedString("album.completed"))")
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundColor(.gray)
                            }
                        }

                        Spacer()

                        // Chevron con animación
                        ZStack {
                            Circle()
                                .fill(section.color.opacity(0.1))
                                .frame(width: 40, height: 40)

                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(section.color)
                        }
                    }

                    // Barra de progreso mejorada
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Fondo
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.gray.opacity(0.15),
                                            Color.gray.opacity(0.10)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(height: 12)

                            // Progreso
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                section.color,
                                                section.color.opacity(0.8)
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geometry.size.width * progress, height: 12)

                                // Brillo superior
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.white.opacity(0.4),
                                                Color.clear
                                            ]),
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(width: geometry.size.width * progress, height: 12)
                            }

                            // Badge de completado
                            if progress >= 1.0 {
                                HStack {
                                    Spacer()

                                    HStack(spacing: 4) {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 8, weight: .black))

                                        Text("100%")
                                            .font(.system(size: 10, weight: .black, design: .rounded))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(Color(hex: "#1C42E8"))
                                    )
                                }
                            }
                        }
                    }
                    .frame(height: 12)
                }
                .padding(24)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                section.color.opacity(0.3),
                                section.color.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: section.color.opacity(0.15), radius: 15, x: 0, y: 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Enhanced Progress Bar
struct EnhancedProgressBar: View {
    let progress: Double
    @State private var animatedProgress: Double = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Fondo con gradiente sutil
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.gray.opacity(0.12),
                                Color.gray.opacity(0.08)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 28)

                // Progreso con gradiente animado
                ZStack(alignment: .trailing) {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "#1C42E8"),
                                    Color(hex: "#1C42E8"),
                                    Color(hex: "#F0D224")
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * animatedProgress, height: 28)

                    // Brillo animado
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.4),
                                    Color.clear
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: geometry.size.width * animatedProgress, height: 28)
                }

                // Texto del porcentaje
                HStack {
                    Spacer()

                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)

                        Text("\(Int(animatedProgress * 100))%")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(.trailing, animatedProgress > 0.15 ? 12 : 0)
                    .opacity(animatedProgress > 0.08 ? 1.0 : 0.0)

                    if animatedProgress <= 0.15 {
                        Spacer()
                    }
                }
            }
        }
        .frame(height: 28)
        .shadow(color: Color(hex: "#1C42E8").opacity(0.25), radius: 8, x: 0, y: 4)
        .onAppear {
            withAnimation(.spring(response: 1.0, dampingFraction: 0.8)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { oldValue, newValue in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                animatedProgress = newValue
            }
        }
    }
}

// MARK: - Progress Bar (Legacy)
struct ProgressBar: View {
    let progress: Double

    var body: some View {
        EnhancedProgressBar(progress: progress)
    }
}

