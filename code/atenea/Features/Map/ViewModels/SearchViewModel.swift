//
//  SearchViewModel.swift
//  atenea
//
//  ViewModel para manejar la búsqueda de lugares (versión sin MapboxSearch)
//

import Foundation
import CoreLocation
internal import Combine

/// ViewModel que maneja toda la lógica de búsqueda de lugares
@MainActor
class SearchViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var searchText: String = ""
    @Published var suggestions: [SearchPlace] = []
    @Published var isSearching: Bool = false
    @Published var errorMessage: String?
    @Published var selectedPlace: SearchPlace?

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()
    private var userLocation: CLLocationCoordinate2D?

    // Base de datos local de lugares populares de CDMX
    private var allPlaces: [SearchPlace] = []

    // MARK: - Initialization

    init(userLocation: CLLocationCoordinate2D? = nil) {
        self.userLocation = userLocation
        setupSearchDebouncing()
        loadPlacesDatabase()
    }

    // MARK: - Setup

    /// Configura debouncing para la búsqueda (evita buscar en cada tecla)
    private func setupSearchDebouncing() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] searchQuery in
                self?.performSearch(query: searchQuery)
            }
            .store(in: &cancellables)
    }

    /// Carga base de datos local de lugares populares
    private func loadPlacesDatabase() {
        allPlaces = [
            // Lugares icónicos de CDMX
            SearchPlace(
                id: "place-1",
                name: "Zócalo",
                subtitle: "Plaza de la Constitución, Centro Histórico",
                fullAddress: "Plaza de la Constitución S/N, Centro Histórico de la Cdad. de México",
                category: "Histórico",
                icon: "building.columns.fill",
                coordinate: CLLocationCoordinate2D(latitude: 19.4326, longitude: -99.1332),
                isRecommended: true
            ),
            SearchPlace(
                id: "place-2",
                name: "Ángel de la Independencia",
                subtitle: "Monumento en Paseo de la Reforma",
                fullAddress: "Paseo de la Reforma y Eje 2 Pte Río Tiber, Juárez, CDMX",
                category: "Monumento",
                icon: "figure.stand",
                coordinate: CLLocationCoordinate2D(latitude: 19.4270, longitude: -99.1676),
                isRecommended: true
            ),
            SearchPlace(
                id: "place-3",
                name: "Bosque de Chapultepec",
                subtitle: "Parque urbano más grande de la ciudad",
                fullAddress: "San Miguel Chapultepec I Secc, Miguel Hidalgo, CDMX",
                category: "Parque",
                icon: "leaf.fill",
                coordinate: CLLocationCoordinate2D(latitude: 19.4204, longitude: -99.1895),
                isRecommended: true
            ),
            SearchPlace(
                id: "place-4",
                name: "Museo Nacional de Antropología",
                subtitle: "Museo de arte y cultura precolombina",
                fullAddress: "Av. Paseo de la Reforma y Calzada Gandhi S/N, Polanco, CDMX",
                category: "Museo",
                icon: "building.columns",
                coordinate: CLLocationCoordinate2D(latitude: 19.4259, longitude: -99.1862),
                isRecommended: true
            ),
            SearchPlace(
                id: "place-5",
                name: "Palacio de Bellas Artes",
                subtitle: "Centro cultural y sala de conciertos",
                fullAddress: "Av. Juárez S/N, Centro Histórico de la Cdad. de México",
                category: "Cultural",
                icon: "theatermasks.fill",
                coordinate: CLLocationCoordinate2D(latitude: 19.4352, longitude: -99.1412),
                isRecommended: true
            ),
            SearchPlace(
                id: "place-6",
                name: "Basílica de Guadalupe",
                subtitle: "Santuario católico más visitado del mundo",
                fullAddress: "Plaza de las Américas 1, Villa de Guadalupe, Gustavo A. Madero, CDMX",
                category: "Religioso",
                icon: "building.fill",
                coordinate: CLLocationCoordinate2D(latitude: 19.4847, longitude: -99.1177),
                isRecommended: true
            ),
            SearchPlace(
                id: "place-7",
                name: "Xochimilco",
                subtitle: "Canales prehispánicos y trajineras",
                fullAddress: "Embarcadero Cuemanco, Xochimilco, CDMX",
                category: "Turismo",
                icon: "ferry.fill",
                coordinate: CLLocationCoordinate2D(latitude: 19.2577, longitude: -99.1036),
                isRecommended: true
            ),
            SearchPlace(
                id: "place-8",
                name: "Torre Latinoamericana",
                subtitle: "Rascacielos con mirador panorámico",
                fullAddress: "Eje Central Lázaro Cárdenas 2, Centro, Cuauhtémoc, CDMX",
                category: "Mirador",
                icon: "building.2.fill",
                coordinate: CLLocationCoordinate2D(latitude: 19.4337, longitude: -99.1407),
                isRecommended: true
            ),
            SearchPlace(
                id: "place-9",
                name: "Coyoacán",
                subtitle: "Barrio tradicional y cultural",
                fullAddress: "Centro de Coyoacán, Coyoacán, CDMX",
                category: "Barrio",
                icon: "house.fill",
                coordinate: CLLocationCoordinate2D(latitude: 19.3492, longitude: -99.1617),
                isRecommended: true
            ),
            SearchPlace(
                id: "place-10",
                name: "Estadio Azteca",
                subtitle: "Estadio de fútbol icónico",
                fullAddress: "Calz. de Tlalpan 3465, Santa Úrsula Coapa, Coyoacán, CDMX",
                category: "Deporte",
                icon: "sportscourt.fill",
                coordinate: CLLocationCoordinate2D(latitude: 19.3029, longitude: -99.1506),
                isRecommended: true
            ),
            // Lugares adicionales para búsqueda
            SearchPlace(
                id: "place-11",
                name: "Museo Frida Kahlo",
                subtitle: "Casa Azul, museo de la artista",
                fullAddress: "Londres 247, Del Carmen, Coyoacán, CDMX",
                category: "Museo",
                icon: "paintbrush.fill",
                coordinate: CLLocationCoordinate2D(latitude: 19.3551, longitude: -99.1624),
                isRecommended: false
            ),
            SearchPlace(
                id: "place-12",
                name: "Castillo de Chapultepec",
                subtitle: "Palacio histórico y museo",
                fullAddress: "Bosque de Chapultepec I Secc, Miguel Hidalgo, CDMX",
                category: "Histórico",
                icon: "building.columns.fill",
                coordinate: CLLocationCoordinate2D(latitude: 19.4203, longitude: -99.1817),
                isRecommended: false
            ),
            SearchPlace(
                id: "place-13",
                name: "Mercado de la Ciudadela",
                subtitle: "Mercado de artesanías mexicanas",
                fullAddress: "Balderas S/N, Centro, Cuauhtémoc, CDMX",
                category: "Mercado",
                icon: "bag.fill",
                coordinate: CLLocationCoordinate2D(latitude: 19.4259, longitude: -99.1504),
                isRecommended: false
            ),
            SearchPlace(
                id: "place-14",
                name: "Teotihuacán",
                subtitle: "Zona arqueológica de pirámides",
                fullAddress: "San Juan Teotihuacán, Estado de México",
                category: "Arqueológico",
                icon: "triangle.fill",
                coordinate: CLLocationCoordinate2D(latitude: 19.6925, longitude: -98.8438),
                isRecommended: false
            ),
            SearchPlace(
                id: "place-15",
                name: "Polanco",
                subtitle: "Zona residencial y comercial de lujo",
                fullAddress: "Polanco, Miguel Hidalgo, CDMX",
                category: "Zona",
                icon: "building.2.crop.circle.fill",
                coordinate: CLLocationCoordinate2D(latitude: 19.4338, longitude: -99.1955),
                isRecommended: false
            ),
            SearchPlace(
                id: "place-16",
                name: "Condesa",
                subtitle: "Barrio moderno con parques y cafés",
                fullAddress: "Hipódromo Condesa, Cuauhtémoc, CDMX",
                category: "Barrio",
                icon: "house.fill",
                coordinate: CLLocationCoordinate2D(latitude: 19.4111, longitude: -99.1722),
                isRecommended: false
            ),
            SearchPlace(
                id: "place-17",
                name: "Arena México",
                subtitle: "Templo de la lucha libre",
                fullAddress: "Dr. Lavista 189, Doctores, Cuauhtémoc, CDMX",
                category: "Deporte",
                icon: "figure.wrestling",
                coordinate: CLLocationCoordinate2D(latitude: 19.4204, longitude: -99.1544),
                isRecommended: false
            ),
            SearchPlace(
                id: "place-18",
                name: "Six Flags México",
                subtitle: "Parque de diversiones",
                fullAddress: "Carretera Picacho-Ajusco Km. 1.5, Héroes de Padierna, CDMX",
                category: "Entretenimiento",
                icon: "figure.play",
                coordinate: CLLocationCoordinate2D(latitude: 19.2963, longitude: -99.2132),
                isRecommended: false
            ),
            SearchPlace(
                id: "place-19",
                name: "Universidad Nacional Autónoma de México",
                subtitle: "Ciudad Universitaria, UNAM",
                fullAddress: "Av. Universidad 3000, Coyoacán, CDMX",
                category: "Educación",
                icon: "book.fill",
                coordinate: CLLocationCoordinate2D(latitude: 19.3237, longitude: -99.1819),
                isRecommended: false
            ),
            SearchPlace(
                id: "place-20",
                name: "Mercado de San Juan",
                subtitle: "Mercado gourmet y exótico",
                fullAddress: "Ernesto Pugibet 21, Centro, Cuauhtémoc, CDMX",
                category: "Mercado",
                icon: "fork.knife",
                coordinate: CLLocationCoordinate2D(latitude: 19.4317, longitude: -99.1437),
                isRecommended: false
            ),
            // Bares
            SearchPlace(
                id: "bar-1",
                name: "Licorería Limantour",
                subtitle: "Bar de coctelería",
                fullAddress: "Álvaro Obregón 106, Roma Norte, Cuauhtémoc, CDMX",
                category: "Bar",
                icon: "wineglass.fill",
                coordinate: CLLocationCoordinate2D(latitude: 19.4185, longitude: -99.1654),
                isRecommended: false
            ),
            SearchPlace(
                id: "bar-2",
                name: "Baltra Bar",
                subtitle: "Bar de coctelería tropical",
                fullAddress: "Orizaba 127, Roma Norte, Cuauhtémoc, CDMX",
                category: "Bar",
                icon: "wineglass.fill",
                coordinate: CLLocationCoordinate2D(latitude: 19.4173, longitude: -99.1639),
                isRecommended: false
            ),
            SearchPlace(
                id: "bar-3",
                name: "Xaman Bar",
                subtitle: "Bar mezcalería",
                fullAddress: "Colima 378, Roma Norte, Cuauhtémoc, CDMX",
                category: "Bar",
                icon: "wineglass.fill",
                coordinate: CLLocationCoordinate2D(latitude: 19.4145, longitude: -99.1675),
                isRecommended: false
            ),
            SearchPlace(
                id: "bar-4",
                name: "Fifty Mils",
                subtitle: "Bar del Four Seasons",
                fullAddress: "Paseo de la Reforma 500, Juárez, Cuauhtémoc, CDMX",
                category: "Bar",
                icon: "wineglass.fill",
                coordinate: CLLocationCoordinate2D(latitude: 19.4267, longitude: -99.1689),
                isRecommended: false
            ),
            SearchPlace(
                id: "bar-5",
                name: "Maison Artemisia",
                subtitle: "Bar de absenta y coctelería",
                fullAddress: "Tonalá 23, Roma Norte, Cuauhtémoc, CDMX",
                category: "Bar",
                icon: "wineglass.fill",
                coordinate: CLLocationCoordinate2D(latitude: 19.4156, longitude: -99.1645),
                isRecommended: false
            ),
            SearchPlace(
                id: "bar-6",
                name: "La Clandestina",
                subtitle: "Mezcalería en Condesa",
                fullAddress: "Álvaro Obregón 298, Hipódromo Condesa, CDMX",
                category: "Bar",
                icon: "wineglass.fill",
                coordinate: CLLocationCoordinate2D(latitude: 19.4095, longitude: -99.1712),
                isRecommended: false
            ),
            SearchPlace(
                id: "bar-7",
                name: "Pulquería Los Insurgentes",
                subtitle: "Pulquería tradicional",
                fullAddress: "Av. Insurgentes Sur 226, Roma Norte, CDMX",
                category: "Bar",
                icon: "wineglass.fill",
                coordinate: CLLocationCoordinate2D(latitude: 19.4198, longitude: -99.1621),
                isRecommended: false
            ),
            SearchPlace(
                id: "bar-8",
                name: "Zinco Jazz Club",
                subtitle: "Bar de jazz en el Centro",
                fullAddress: "Motolinia 20, Centro Histórico, CDMX",
                category: "Bar",
                icon: "wineglass.fill",
                coordinate: CLLocationCoordinate2D(latitude: 19.4352, longitude: -99.1398),
                isRecommended: false
            ),
            SearchPlace(
                id: "bar-9",
                name: "Bósforo",
                subtitle: "Bar cervecero artesanal",
                fullAddress: "Orizaba 42, Roma Norte, CDMX",
                category: "Bar",
                icon: "wineglass.fill",
                coordinate: CLLocationCoordinate2D(latitude: 19.4201, longitude: -99.1627),
                isRecommended: false
            ),
            SearchPlace(
                id: "bar-10",
                name: "La Bipo",
                subtitle: "Cantina tradicional",
                fullAddress: "República de Cuba 49, Centro Histórico, CDMX",
                category: "Bar",
                icon: "wineglass.fill",
                coordinate: CLLocationCoordinate2D(latitude: 19.4361, longitude: -99.1371),
                isRecommended: false
            ),
            SearchPlace(
                id: "bar-11",
                name: "Pata Negra",
                subtitle: "Tapas bar español",
                fullAddress: "Tamaulipas 30, Hipódromo Condesa, CDMX",
                category: "Bar",
                icon: "wineglass.fill",
                coordinate: CLLocationCoordinate2D(latitude: 19.4101, longitude: -99.1695),
                isRecommended: false
            ),
            SearchPlace(
                id: "bar-12",
                name: "Salón Ríos",
                subtitle: "Cantina clásica desde 1949",
                fullAddress: "Versalles 88, Juárez, Cuauhtémoc, CDMX",
                category: "Bar",
                icon: "wineglass.fill",
                coordinate: CLLocationCoordinate2D(latitude: 19.4278, longitude: -99.1602),
                isRecommended: false
            ),
            SearchPlace(
                id: "bar-13",
                name: "Xaman Craft Bar",
                subtitle: "Cerveza artesanal",
                fullAddress: "Insurgentes Sur 377, Hipódromo Condesa, CDMX",
                category: "Bar",
                icon: "wineglass.fill",
                coordinate: CLLocationCoordinate2D(latitude: 19.4089, longitude: -99.1689),
                isRecommended: false
            ),
            SearchPlace(
                id: "bar-14",
                name: "La Purísima",
                subtitle: "Cantina moderna",
                fullAddress: "Francisco Pimentel 10, San Rafael, CDMX",
                category: "Bar",
                icon: "wineglass.fill",
                coordinate: CLLocationCoordinate2D(latitude: 19.4412, longitude: -99.1589),
                isRecommended: false
            ),
            SearchPlace(
                id: "bar-15",
                name: "Departamento",
                subtitle: "Rooftop bar con DJ",
                fullAddress: "Av. Nuevo León 61, Hipódromo Condesa, CDMX",
                category: "Bar",
                icon: "wineglass.fill",
                coordinate: CLLocationCoordinate2D(latitude: 19.4093, longitude: -99.1721),
                isRecommended: false
            ),
            SearchPlace(
                id: "bar-16",
                name: "Jules Basement",
                subtitle: "Bar subterráneo de cocteles",
                fullAddress: "Julio Verne 93, Polanco, Miguel Hidalgo, CDMX",
                category: "Bar",
                icon: "wineglass.fill",
                coordinate: CLLocationCoordinate2D(latitude: 19.4329, longitude: -99.1889),
                isRecommended: false
            ),
            SearchPlace(
                id: "bar-17",
                name: "Traspatio",
                subtitle: "Bar con jardín en Coyoacán",
                fullAddress: "Jardín Centenario 14, Villa Coyoacán, CDMX",
                category: "Bar",
                icon: "wineglass.fill",
                coordinate: CLLocationCoordinate2D(latitude: 19.3502, longitude: -99.1613),
                isRecommended: false
            ),
            SearchPlace(
                id: "bar-18",
                name: "Candelaria",
                subtitle: "Taquería y bar de cocteles",
                fullAddress: "Versalles 45, Juárez, Cuauhtémoc, CDMX",
                category: "Bar",
                icon: "wineglass.fill",
                coordinate: CLLocationCoordinate2D(latitude: 19.4289, longitude: -99.1615),
                isRecommended: false
            ),
            SearchPlace(
                id: "bar-19",
                name: "Beer Factory",
                subtitle: "Cervecería artesanal",
                fullAddress: "Av. Insurgentes Sur 1388, Del Valle, CDMX",
                category: "Bar",
                icon: "wineglass.fill",
                coordinate: CLLocationCoordinate2D(latitude: 19.3751, longitude: -99.1703),
                isRecommended: false
            ),
            SearchPlace(
                id: "bar-20",
                name: "Covadonga",
                subtitle: "Bar español tradicional",
                fullAddress: "Puebla 121, Roma Norte, Cuauhtémoc, CDMX",
                category: "Bar",
                icon: "wineglass.fill",
                coordinate: CLLocationCoordinate2D(latitude: 19.4146, longitude: -99.1628),
                isRecommended: false
            ),
            // Bares cerca del Centro Banamex (Polanco, Anzures, Granada)
            SearchPlace(
                id: "bar-21",
                name: "Area Bar & Terrace",
                subtitle: "Bar con terraza en Polanco",
                fullAddress: "Emilio Castelar 163, Polanco, Miguel Hidalgo, CDMX",
                category: "Bar",
                icon: "wineglass.fill",
                coordinate: CLLocationCoordinate2D(latitude: 19.4334, longitude: -99.1889),
                isRecommended: false
            ),
            SearchPlace(
                id: "bar-22",
                name: "Handshake Speakeasy",
                subtitle: "Bar escondido de cocteles",
                fullAddress: "Anatole France 13, Polanco, Miguel Hidalgo, CDMX",
                category: "Bar",
                icon: "wineglass.fill",
                coordinate: CLLocationCoordinate2D(latitude: 19.4361, longitude: -99.1877),
                isRecommended: false
            ),
            SearchPlace(
                id: "bar-23",
                name: "La Única",
                subtitle: "Pulquería artesanal",
                fullAddress: "Emerson 82, Polanco, Miguel Hidalgo, CDMX",
                category: "Bar",
                icon: "wineglass.fill",
                coordinate: CLLocationCoordinate2D(latitude: 19.4392, longitude: -99.1912),
                isRecommended: false
            ),
            SearchPlace(
                id: "bar-24",
                name: "Cityzen Bar",
                subtitle: "Bar en azotea del Hotel Intercontinental",
                fullAddress: "Campos Elíseos 218, Polanco, Miguel Hidalgo, CDMX",
                category: "Bar",
                icon: "wineglass.fill",
                coordinate: CLLocationCoordinate2D(latitude: 19.4298, longitude: -99.2012),
                isRecommended: false
            ),
            SearchPlace(
                id: "bar-25",
                name: "Balmori Roofbar",
                subtitle: "Rooftop bar",
                fullAddress: "Av. Presidente Masaryk 393, Polanco, Miguel Hidalgo, CDMX",
                category: "Bar",
                icon: "wineglass.fill",
                coordinate: CLLocationCoordinate2D(latitude: 19.4281, longitude: -99.1989),
                isRecommended: false
            ),
            SearchPlace(
                id: "bar-26",
                name: "Gin Gin",
                subtitle: "Bar de ginebras",
                fullAddress: "Alejandro Dumas 24, Polanco, Miguel Hidalgo, CDMX",
                category: "Bar",
                icon: "wineglass.fill",
                coordinate: CLLocationCoordinate2D(latitude: 19.4357, longitude: -99.1893),
                isRecommended: false
            ),
            SearchPlace(
                id: "bar-27",
                name: "Patrick Miller",
                subtitle: "Bar disco retro",
                fullAddress: "Av. Presidente Masaryk 393, Polanco, Miguel Hidalgo, CDMX",
                category: "Bar",
                icon: "wineglass.fill",
                coordinate: CLLocationCoordinate2D(latitude: 19.4282, longitude: -99.1991),
                isRecommended: false
            ),
            SearchPlace(
                id: "bar-28",
                name: "Broka Bistro",
                subtitle: "Bistro bar francés",
                fullAddress: "Horacio 111, Polanco, Miguel Hidalgo, CDMX",
                category: "Bar",
                icon: "wineglass.fill",
                coordinate: CLLocationCoordinate2D(latitude: 19.4312, longitude: -99.1923),
                isRecommended: false
            ),
            SearchPlace(
                id: "bar-29",
                name: "Tlecan",
                subtitle: "Bar mexicano contemporáneo",
                fullAddress: "Goldsmith 38, Polanco, Miguel Hidalgo, CDMX",
                category: "Bar",
                icon: "wineglass.fill",
                coordinate: CLLocationCoordinate2D(latitude: 19.4378, longitude: -99.1934),
                isRecommended: false
            ),
            SearchPlace(
                id: "bar-30",
                name: "Bar Oriol",
                subtitle: "Coctelería de autor",
                fullAddress: "Newton 88, Polanco, Miguel Hidalgo, CDMX",
                category: "Bar",
                icon: "wineglass.fill",
                coordinate: CLLocationCoordinate2D(latitude: 19.4347, longitude: -99.1934),
                isRecommended: false
            ),
            SearchPlace(
                id: "bar-31",
                name: "Parker & Lenox",
                subtitle: "Bar de jazz y blues",
                fullAddress: "Milán 14, Juárez, Cuauhtémoc, CDMX",
                category: "Bar",
                icon: "wineglass.fill",
                coordinate: CLLocationCoordinate2D(latitude: 19.4245, longitude: -99.1678),
                isRecommended: false
            ),
            SearchPlace(
                id: "bar-32",
                name: "Caradura Bar",
                subtitle: "Bar de mezcal",
                fullAddress: "Lamartine 159, Polanco, Miguel Hidalgo, CDMX",
                category: "Bar",
                icon: "wineglass.fill",
                coordinate: CLLocationCoordinate2D(latitude: 19.4412, longitude: -99.1923),
                isRecommended: false
            ),
            SearchPlace(
                id: "bar-33",
                name: "El Deposito",
                subtitle: "Bar cervecero",
                fullAddress: "Edgar Allan Poe 8, Polanco, Miguel Hidalgo, CDMX",
                category: "Bar",
                icon: "wineglass.fill",
                coordinate: CLLocationCoordinate2D(latitude: 19.4423, longitude: -99.1889),
                isRecommended: false
            ),
            SearchPlace(
                id: "bar-34",
                name: "Blanco Colima",
                subtitle: "Bar de cocteles artesanales",
                fullAddress: "Av. Insurgentes Sur 179, Roma Norte, CDMX",
                category: "Bar",
                icon: "wineglass.fill",
                coordinate: CLLocationCoordinate2D(latitude: 19.4189, longitude: -99.1645),
                isRecommended: false
            ),
            SearchPlace(
                id: "bar-35",
                name: "La Nacional",
                subtitle: "Cantina histórica",
                fullAddress: "Leibnitz 163, Anzures, Miguel Hidalgo, CDMX",
                category: "Bar",
                icon: "wineglass.fill",
                coordinate: CLLocationCoordinate2D(latitude: 19.4267, longitude: -99.1823),
                isRecommended: false
            ),
            SearchPlace(
                id: "bar-36",
                name: "M.N. Roy",
                subtitle: "Bar de mezcal y tequila",
                fullAddress: "Merida 186, Roma Norte, CDMX",
                category: "Bar",
                icon: "wineglass.fill",
                coordinate: CLLocationCoordinate2D(latitude: 19.4134, longitude: -99.1689),
                isRecommended: false
            ),
            SearchPlace(
                id: "bar-37",
                name: "Felina",
                subtitle: "Coctelería moderna",
                fullAddress: "Oscar Wilde 16, Polanco, Miguel Hidalgo, CDMX",
                category: "Bar",
                icon: "wineglass.fill",
                coordinate: CLLocationCoordinate2D(latitude: 19.4398, longitude: -99.1901),
                isRecommended: false
            ),
            SearchPlace(
                id: "bar-38",
                name: "Ticuchi",
                subtitle: "Bar oaxaqueño",
                fullAddress: "Tonalá 133, Roma Norte, CDMX",
                category: "Bar",
                icon: "wineglass.fill",
                coordinate: CLLocationCoordinate2D(latitude: 19.4135, longitude: -99.1658),
                isRecommended: false
            ),
            SearchPlace(
                id: "bar-39",
                name: "La Roma Beer Co.",
                subtitle: "Cervecería artesanal",
                fullAddress: "Álvaro Obregón 49, Roma Norte, CDMX",
                category: "Bar",
                icon: "wineglass.fill",
                coordinate: CLLocationCoordinate2D(latitude: 19.4198, longitude: -99.1638),
                isRecommended: false
            ),
            SearchPlace(
                id: "bar-40",
                name: "Rokai",
                subtitle: "Bar asiático fusion",
                fullAddress: "Campos Elíseos 199, Polanco, Miguel Hidalgo, CDMX",
                category: "Bar",
                icon: "wineglass.fill",
                coordinate: CLLocationCoordinate2D(latitude: 19.4312, longitude: -99.2001),
                isRecommended: false
            ),
            // Restaurantes
            SearchPlace(
                id: "rest-1",
                name: "Quintonil",
                subtitle: "Alta cocina mexicana",
                fullAddress: "Newton 55, Polanco, Miguel Hidalgo, CDMX",
                category: "Restaurante",
                icon: "fork.knife",
                coordinate: CLLocationCoordinate2D(latitude: 19.4356, longitude: -99.1922),
                isRecommended: false
            ),
            SearchPlace(
                id: "rest-2",
                name: "Pujol",
                subtitle: "Restaurante de Enrique Olvera",
                fullAddress: "Tennyson 133, Polanco, Miguel Hidalgo, CDMX",
                category: "Restaurante",
                icon: "fork.knife",
                coordinate: CLLocationCoordinate2D(latitude: 19.4378, longitude: -99.1961),
                isRecommended: false
            ),
            SearchPlace(
                id: "rest-3",
                name: "Contramar",
                subtitle: "Mariscos frescos",
                fullAddress: "Durango 200, Roma Norte, Cuauhtémoc, CDMX",
                category: "Restaurante",
                icon: "fork.knife",
                coordinate: CLLocationCoordinate2D(latitude: 19.4152, longitude: -99.1697),
                isRecommended: false
            ),
            SearchPlace(
                id: "rest-4",
                name: "Rosetta",
                subtitle: "Cocina italiana en casona",
                fullAddress: "Colima 166, Roma Norte, Cuauhtémoc, CDMX",
                category: "Restaurante",
                icon: "fork.knife",
                coordinate: CLLocationCoordinate2D(latitude: 19.4167, longitude: -99.1684),
                isRecommended: false
            ),
            SearchPlace(
                id: "rest-5",
                name: "Máximo Bistrot",
                subtitle: "Bistró francés contemporáneo",
                fullAddress: "Tonalá 133, Roma Norte, Cuauhtémoc, CDMX",
                category: "Restaurante",
                icon: "fork.knife",
                coordinate: CLLocationCoordinate2D(latitude: 19.4134, longitude: -99.1658),
                isRecommended: false
            ),
            // Cafés
            SearchPlace(
                id: "cafe-1",
                name: "Café Nin",
                subtitle: "Café de especialidad",
                fullAddress: "Havre 73, Juárez, Cuauhtémoc, CDMX",
                category: "Café",
                icon: "cup.and.saucer.fill",
                coordinate: CLLocationCoordinate2D(latitude: 19.4291, longitude: -99.1639),
                isRecommended: false
            ),
            SearchPlace(
                id: "cafe-2",
                name: "Blend Station",
                subtitle: "Coffee shop moderno",
                fullAddress: "Álvaro Obregón 64, Roma Norte, Cuauhtémoc, CDMX",
                category: "Café",
                icon: "cup.and.saucer.fill",
                coordinate: CLLocationCoordinate2D(latitude: 19.4191, longitude: -99.1643),
                isRecommended: false
            ),
            SearchPlace(
                id: "cafe-3",
                name: "Chiquitito Café",
                subtitle: "Café acogedor",
                fullAddress: "Colima 124, Roma Norte, Cuauhtémoc, CDMX",
                category: "Café",
                icon: "cup.and.saucer.fill",
                coordinate: CLLocationCoordinate2D(latitude: 19.4178, longitude: -99.1671),
                isRecommended: false
            ),
            SearchPlace(
                id: "cafe-4",
                name: "Buna Café",
                subtitle: "Café de origen",
                fullAddress: "Orizaba 42, Roma Norte, Cuauhtémoc, CDMX",
                category: "Café",
                icon: "cup.and.saucer.fill",
                coordinate: CLLocationCoordinate2D(latitude: 19.4201, longitude: -99.1626),
                isRecommended: false
            ),
            SearchPlace(
                id: "cafe-5",
                name: "Quentin Café",
                subtitle: "Café librería",
                fullAddress: "Álvaro Obregón 64, Roma Norte, Cuauhtémoc, CDMX",
                category: "Café",
                icon: "cup.and.saucer.fill",
                coordinate: CLLocationCoordinate2D(latitude: 19.4192, longitude: -99.1644),
                isRecommended: false
            ),
            // Tiendas
            SearchPlace(
                id: "shop-1",
                name: "Palacio de Hierro Polanco",
                subtitle: "Tienda departamental",
                fullAddress: "Molière 222, Polanco, Miguel Hidalgo, CDMX",
                category: "Tienda",
                icon: "cart.fill",
                coordinate: CLLocationCoordinate2D(latitude: 19.4319, longitude: -99.1978),
                isRecommended: false
            ),
            SearchPlace(
                id: "shop-2",
                name: "Antara Polanco",
                subtitle: "Centro comercial",
                fullAddress: "Av. Ejército Nacional 843-B, Granada, Miguel Hidalgo, CDMX",
                category: "Tienda",
                icon: "cart.fill",
                coordinate: CLLocationCoordinate2D(latitude: 19.4419, longitude: -99.2001),
                isRecommended: false
            ),
            SearchPlace(
                id: "shop-3",
                name: "Liverpool Insurgentes",
                subtitle: "Tienda departamental",
                fullAddress: "Av. Insurgentes Sur 1310, Del Valle, Benito Juárez, CDMX",
                category: "Tienda",
                icon: "cart.fill",
                coordinate: CLLocationCoordinate2D(latitude: 19.3763, longitude: -99.1699),
                isRecommended: false
            ),
            SearchPlace(
                id: "shop-4",
                name: "Plaza Satélite",
                subtitle: "Centro comercial",
                fullAddress: "Circuito Centro Comercial 2251, Cd. Satélite, Naucalpan, Edo. Méx.",
                category: "Tienda",
                icon: "cart.fill",
                coordinate: CLLocationCoordinate2D(latitude: 19.5089, longitude: -99.2377),
                isRecommended: false
            ),
            // Gimnasios
            SearchPlace(
                id: "gym-1",
                name: "Sports World Polanco",
                subtitle: "Gimnasio premium",
                fullAddress: "Av. Ejército Nacional 505, Polanco, Miguel Hidalgo, CDMX",
                category: "Gimnasio",
                icon: "figure.run",
                coordinate: CLLocationCoordinate2D(latitude: 19.4354, longitude: -99.1932),
                isRecommended: false
            ),
            SearchPlace(
                id: "gym-2",
                name: "Sports World Santa Fe",
                subtitle: "Gimnasio premium",
                fullAddress: "Vasco de Quiroga 3800, Santa Fe, Cuajimalpa, CDMX",
                category: "Gimnasio",
                icon: "figure.run",
                coordinate: CLLocationCoordinate2D(latitude: 19.3596, longitude: -99.2667),
                isRecommended: false
            ),
            SearchPlace(
                id: "gym-3",
                name: "CrossFit Insurgentes",
                subtitle: "Box de CrossFit",
                fullAddress: "Av. Insurgentes Sur 519, Hipódromo, Cuauhtémoc, CDMX",
                category: "Gimnasio",
                icon: "figure.run",
                coordinate: CLLocationCoordinate2D(latitude: 19.4089, longitude: -99.1712),
                isRecommended: false
            ),
            SearchPlace(
                id: "gym-4",
                name: "Siclo Condesa",
                subtitle: "Estudio de ciclismo indoor",
                fullAddress: "Av. Nuevo León 107, Hipódromo Condesa, Cuauhtémoc, CDMX",
                category: "Gimnasio",
                icon: "figure.run",
                coordinate: CLLocationCoordinate2D(latitude: 19.4078, longitude: -99.1734),
                isRecommended: false
            )
        ]

        print("✅ \(allPlaces.count) lugares cargados en la base de datos local")
    }

    // MARK: - Search Methods

    /// Realiza búsqueda local en la base de datos de lugares
    func performSearch(query: String) {
        // Limpiar resultados si la búsqueda está vacía
        guard !query.isEmpty else {
            suggestions = []
            isSearching = false
            return
        }

        isSearching = true
        errorMessage = nil

        // Simular delay de red (opcional, puede removerse)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }

            let lowercasedQuery = query.lowercased()

            // Buscar en nombre, subtítulo, dirección y categoría
            let results = self.allPlaces.filter { place in
                place.name.lowercased().contains(lowercasedQuery) ||
                place.subtitle.lowercased().contains(lowercasedQuery) ||
                (place.fullAddress?.lowercased().contains(lowercasedQuery) ?? false) ||
                place.category.lowercased().contains(lowercasedQuery)
            }

            // Ordenar por relevancia (primero coincidencias exactas en el nombre)
            let sortedResults = results.sorted { place1, place2 in
                let name1StartsWithQuery = place1.name.lowercased().hasPrefix(lowercasedQuery)
                let name2StartsWithQuery = place2.name.lowercased().hasPrefix(lowercasedQuery)

                if name1StartsWithQuery && !name2StartsWithQuery {
                    return true
                } else if !name1StartsWithQuery && name2StartsWithQuery {
                    return false
                }

                // Si ambos tienen la misma relevancia, ordenar por distancia
                if let userLoc = self.userLocation,
                   let coord1 = place1.coordinate,
                   let coord2 = place2.coordinate {
                    let dist1 = self.calculateDistance(from: userLoc, to: coord1)
                    let dist2 = self.calculateDistance(from: userLoc, to: coord2)
                    return dist1 < dist2
                }

                return place1.name < place2.name
            }

            self.suggestions = Array(sortedResults.prefix(10)) // Limitar a 10 resultados
            self.isSearching = false

            print("✅ Búsqueda local exitosa: \(self.suggestions.count) resultados para '\(query)'")
        }
    }

    /// Selecciona un lugar
    func selectPlace(_ place: SearchPlace) {
        selectedPlace = place
        print("✅ Lugar seleccionado: \(place.name)")
    }

    /// Busca todos los lugares de una categoría específica
    func searchByCategory(_ category: String) {
        isSearching = true
        errorMessage = nil

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }

            let lowercasedCategory = category.lowercased()

            // Filtrar todos los lugares que coincidan con la categoría
            let results = self.allPlaces.filter { place in
                place.category.lowercased() == lowercasedCategory
            }

            // Ordenar por distancia si tenemos ubicación del usuario
            let sortedResults = results.sorted { place1, place2 in
                if let userLoc = self.userLocation,
                   let coord1 = place1.coordinate,
                   let coord2 = place2.coordinate {
                    let dist1 = self.calculateDistance(from: userLoc, to: coord1)
                    let dist2 = self.calculateDistance(from: userLoc, to: coord2)
                    return dist1 < dist2
                }
                return place1.name < place2.name
            }

            self.suggestions = sortedResults
            self.isSearching = false

            print("✅ Búsqueda por categoría '\(category)': \(self.suggestions.count) resultados")
        }
    }

    /// Obtiene lugares de una categoría sin actualizar suggestions (para chips)
    func getPlacesByCategory(_ category: String) -> [SearchPlace] {
        let lowercasedCategory = category.lowercased()

        // Filtrar todos los lugares que coincidan con la categoría
        let results = allPlaces.filter { place in
            place.category.lowercased() == lowercasedCategory
        }

        // Ordenar por distancia si tenemos ubicación del usuario
        let sortedResults = results.sorted { place1, place2 in
            if let userLoc = self.userLocation,
               let coord1 = place1.coordinate,
               let coord2 = place2.coordinate {
                let dist1 = self.calculateDistance(from: userLoc, to: coord1)
                let dist2 = self.calculateDistance(from: userLoc, to: coord2)
                return dist1 < dist2
            }
            return place1.name < place2.name
        }

        return sortedResults
    }

    // MARK: - Utility Methods

    /// Limpia la búsqueda actual
    func clearSearch() {
        searchText = ""
        suggestions = []
        errorMessage = nil
        isSearching = false
    }

    /// Calcula distancia desde la ubicación del usuario a un lugar
    func distanceToPlace(_ place: SearchPlace) -> String? {
        guard let userLocation = userLocation,
              let placeCoordinate = place.coordinate else {
            return nil
        }

        let distanceInMeters = calculateDistance(from: userLocation, to: placeCoordinate)

        if distanceInMeters < 1000 {
            return String(format: "%.0f m", distanceInMeters)
        } else {
            return String(format: "%.1f km", distanceInMeters / 1000)
        }
    }

    /// Calcula distancia entre dos coordenadas en metros
    private func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation)
    }

    /// Actualiza la ubicación del usuario para cálculos de distancia
    func updateUserLocation(_ location: CLLocationCoordinate2D?) {
        userLocation = location
    }
}

// MARK: - SearchPlace Model

/// Modelo unificado para lugares (búsqueda y recomendados)
struct SearchPlace: Identifiable, Equatable {
    let id: String
    let name: String
    let subtitle: String
    var fullAddress: String?
    let category: String
    let icon: String
    var coordinate: CLLocationCoordinate2D?
    let isRecommended: Bool

    init(id: String = UUID().uuidString,
         name: String,
         subtitle: String,
         fullAddress: String? = nil,
         category: String,
         icon: String,
         coordinate: CLLocationCoordinate2D? = nil,
         isRecommended: Bool = false) {
        self.id = id
        self.name = name
        self.subtitle = subtitle
        self.fullAddress = fullAddress
        self.category = category
        self.icon = icon
        self.coordinate = coordinate
        self.isRecommended = isRecommended
    }

    static func == (lhs: SearchPlace, rhs: SearchPlace) -> Bool {
        lhs.id == rhs.id
    }
}
