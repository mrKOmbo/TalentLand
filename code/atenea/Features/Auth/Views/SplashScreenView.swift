import SwiftUI

struct NumberLayer: Identifiable {
    let id = UUID()
    var scale: CGFloat
    var color: Color
}

struct SplashScreenView: View {
    @Binding var showSplash: Bool

    @State private var layers: [NumberLayer] = [NumberLayer(scale: 1, color: .white)]
    @State private var currentColorIndex = 0
    @State private var cupScale: CGFloat = 0.7
    @State private var fifaScale: CGFloat = 0.7
    @State private var fifaOffset: CGFloat = -75
    @State private var isContracting = false
    @State private var circleScale: CGFloat = 0

    let colors: [Color] = [
        .white,
        // ... (Tu array de colores)
        Color(hex: "#00A651"),
        Color(hex: "#34A853"),
        Color(hex: "#8BC53F"),
        Color(hex: "#00573D"),
        Color(hex: "#0072CE"),
        Color(hex: "#00A9E0"),
        Color(hex: "#0A2D6C"),
        Color(hex: "#0D47A1"),
        Color(hex: "#EF4135"),
        Color(hex: "#E41E26"),
        Color(hex: "#F58220"),
        Color(hex: "#FF5A00"),
        Color(hex: "#FFC72C"),
        Color(hex: "#FDB913"),
        Color(hex: "#FFEB3B"),
        Color(hex: "#EAAA00"),
        Color(hex: "#A14593"),
        Color(hex: "#662D8C"),
        Color(hex: "#EC008C"),
        Color(hex: "#FF007F")
    ]

    var body: some View {
        // No necesitamos GeometryReader para centrar, ZStack lo hace por defecto.
        ZStack {
            // Fondo negro
            Color.black
                .ignoresSafeArea()

            // Todas las capas de números expandiéndose/contrayéndose
            ForEach(layers) { layer in
                VStack(spacing: -75) {
                    Text("2")
                    Text("6")
                }
                .font(.custom("FIFA 26", size: 120))
                .foregroundStyle(layer.color)
                .scaleEffect(isContracting ? 0 : layer.scale)
                .opacity(isContracting ? 0 : 1)
                .offset(x: 7, y: -40)
            }

            // Contenedor con la copa y texto FIFA siempre al frente - centrado
            // Se mantiene el VStack principal para que los Spacer() centren el contenido de la copa/FIFA
            VStack(spacing: -7) {
                Spacer()

                // Imagen de la copa
                Image("Copa")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 350)
                    .scaleEffect(isContracting ? 0 : cupScale)
                    .opacity(isContracting ? 0 : 1)

                // Texto "FIFA" debajo de la copa
                Text("FIFA")
                    .font(.custom("FIFA Welcome", size: 60))
                    .fontWeight(.black)
                    .foregroundStyle(.black)
                    .kerning(8)
                    .bold()
                    .scaleEffect(isContracting ? 0 : fifaScale)
                    .offset(x:9, y: fifaOffset + 5)
                    .opacity(isContracting ? 0 : 1)

                Spacer()
            }
            .ignoresSafeArea() // El VStack debe ocupar todo el espacio para centrar su contenido
            
            // Círculo oscuro que se expande (encima del splash)
            Circle()
                .fill(Color(hex: "#1a1a2e"))
                .scaleEffect(circleScale)
                .ignoresSafeArea()
        }
        .ignoresSafeArea()
        .onAppear {
            // Esperar 1.5 segundos antes de iniciar la animación
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                startAnimation()
                // Animar copa y texto FIFA para que crezcan y el texto se baje
                withAnimation(.easeOut(duration: 0.8)) {
                    cupScale = 1.0
                    fifaScale = 1.0
                    fifaOffset = 0
                }
            }
        }
    }

    func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.18, repeats: true) { timer in
            currentColorIndex += 1

            if currentColorIndex < colors.count {
                // Crear nueva capa
                let newLayer = NumberLayer(scale: 1, color: colors[currentColorIndex])
                layers.append(newLayer)

                // Animar todas las capas existentes con animación continua y fluida
                withAnimation(.linear(duration: 0.18)) {
                    for index in layers.indices {
                        layers[index].scale += 0.35
                    }
                }
            } else {
                // Cuando termina la expansión, iniciar la contracción
                timer.invalidate()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    contractAndTransition()
                }
            }
        }
    }

    func contractAndTransition() {
        // Contraer todo hacia el centro
        withAnimation(.easeInOut(duration: 1.2)) {
            isContracting = true
        }

        // Después de la contracción, expandir el círculo blanco
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeOut(duration: 1.5)) {
                circleScale = 20
            }

            // Ocultar el splash screen
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                showSplash = false
            }
        }
    }
}
