import SwiftUI
import CoreLocation

struct MerchantLocationEditView: View {
    @Binding var isPresented: Bool
    var currentLocation: CLLocationCoordinate2D?

    @State private var pinOffset: CGSize = .zero
    @State private var isDragging = false
    @State private var confirmed = false
    @State private var simulatedAddress = "Obteniendo dirección..."

    var body: some View {
        VStack(spacing: 0) {
            // Handle
            Capsule()
                .fill(Color.white.opacity(0.2))
                .frame(width: 36, height: 4)
                .padding(.top, 12)

            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Editar mi ubicación")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    Text("Arrastra el pin para ajustar")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.5))
                }
                Spacer()
                Button { isPresented = false } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            // Mapa simulado
            ZStack {
                // Fondo tipo mapa oscuro
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 0.12, green: 0.16, blue: 0.22))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
                    )

                // Grid simulada de calles
                Canvas { context, size in
                    let streetColor = Color.white.opacity(0.07)
                    // Calles horizontales
                    for i in stride(from: 0, through: Int(size.height), by: 40) {
                        var path = Path()
                        path.move(to: CGPoint(x: 0, y: CGFloat(i)))
                        path.addLine(to: CGPoint(x: size.width, y: CGFloat(i)))
                        context.stroke(path, with: .color(streetColor), lineWidth: 1)
                    }
                    // Calles verticales
                    for i in stride(from: 0, through: Int(size.width), by: 40) {
                        var path = Path()
                        path.move(to: CGPoint(x: CGFloat(i), y: 0))
                        path.addLine(to: CGPoint(x: CGFloat(i), y: size.height))
                        context.stroke(path, with: .color(streetColor), lineWidth: 1)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // Radio de cobertura
                Circle()
                    .fill(Color.orange.opacity(0.12))
                    .frame(width: 120, height: 120)
                    .offset(pinOffset)

                Circle()
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1.5)
                    .frame(width: 120, height: 120)
                    .offset(pinOffset)

                // Pin arrastrable
                VStack(spacing: 0) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(colors: [.orange, .yellow],
                                               startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .frame(width: isDragging ? 52 : 44, height: isDragging ? 52 : 44)
                            .shadow(color: .orange.opacity(0.6), radius: isDragging ? 16 : 8)

                        Image(systemName: "storefront.fill")
                            .font(.system(size: isDragging ? 22 : 18))
                            .foregroundColor(.white)
                    }
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDragging)

                    // Punta del pin
                    Triangle()
                        .fill(Color.orange)
                        .frame(width: 12, height: 8)
                        .offset(y: -1)
                }
                .offset(pinOffset)
                .gesture(
                    DragGesture()
                        .onChanged { val in
                            isDragging = true
                            pinOffset = val.translation
                        }
                        .onEnded { _ in
                            isDragging = false
                            updateSimulatedAddress()
                        }
                )

                // Badge "MODO EDICIÓN"
                VStack {
                    HStack {
                        Spacer()
                        Label("MODO EDICIÓN", systemImage: "pencil")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.orange)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule().fill(Color.orange.opacity(0.15))
                                    .overlay(Capsule().strokeBorder(Color.orange.opacity(0.4), lineWidth: 0.5))
                            )
                            .padding(12)
                    }
                    Spacer()
                }
            }
            .frame(height: 240)
            .padding(.horizontal, 20)
            .padding(.top, 16)

            // Dirección detectada
            HStack(spacing: 10) {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 18))
                Text(simulatedAddress)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)

            // Botón confirmar
            Button {
                confirmed = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    isPresented = false
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: confirmed ? "checkmark.circle.fill" : "mappin.and.ellipse")
                    Text(confirmed ? "Ubicación guardada" : "Confirmar ubicación")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(confirmed
                              ? LinearGradient(colors: [.green, .mint], startPoint: .leading, endPoint: .trailing)
                              : LinearGradient(colors: [.orange, .yellow.opacity(0.8)], startPoint: .leading, endPoint: .trailing))
                )
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: confirmed)
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThickMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color(red: 0.06, green: 0.07, blue: 0.12).opacity(0.85))
                )
        )
        .onAppear { geocodeCurrentLocation() }
    }

    private func geocodeCurrentLocation() {
        let coord = currentLocation ?? CLLocationCoordinate2D(latitude: 19.4326, longitude: -99.1332)
        let location = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, _ in
            if let place = placemarks?.first {
                let name   = place.name ?? ""
                let street = place.thoroughfare ?? ""
                let col    = place.subLocality ?? place.locality ?? ""
                simulatedAddress = [name.isEmpty ? street : name, col]
                    .filter { !$0.isEmpty }
                    .joined(separator: ", ")
            } else {
                simulatedAddress = "Ubicación actual"
            }
        }
    }

    private func updateSimulatedAddress() {
        geocodeCurrentLocation()
    }
}

// MARK: - Triangle shape para la punta del pin

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}
