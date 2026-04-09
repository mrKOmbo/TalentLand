//
//  PostModels.swift
//  Atenea
//
//  Created for Community Posts Integration
//

import Foundation

// MARK: - Post Response
struct PostsResponse: Codable {
    let posts: [CommunityPost]
}

// MARK: - Main User Response
struct MainUserResponse: Codable {
    let posts: [MainUserPost]
}

// MARK: - Main User Post (from /api/main_user)
struct MainUserPost: Codable {
    let mastodon_id: String?
    let author: String
    let image: String
    let date: String
    let id: Int
    let content: String
    let url: String
    let processed: Bool?

    // Convertir a CommunityPost para compatibilidad
    func toCommunityPost() -> CommunityPost {
        // Limpiar el contenido HTML
        let cleanedContent = content
            .replacingOccurrences(of: "<p>", with: "")
            .replacingOccurrences(of: "</p>", with: "")
            .replacingOccurrences(of: "<br>", with: "\n")
            .replacingOccurrences(of: "<br/>", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return CommunityPost(
            id: id,
            source: "Mastodon",
            url: url,
            author: author,
            image: image,
            likes: 0, // Main user posts no tienen likes inicialmente
            title: cleanedContent, // Usar el contenido como título
            content: cleanedContent,
            date: date,
            keywords: "mastodon, creator, mainuser"
        )
    }
}

// MARK: - Sample Data
extension CommunityPost {
    static let samplePosts: [CommunityPost] = [
        // MARK: - World Cup / FIFA
        CommunityPost(
            id: 1,
            source: "News",
            url: "https://fifa.com/worldcup",
            author: "FIFA World Cup",
            image: "https://images.unsplash.com/photo-1486286701208-1d58e9338013?w=800",
            likes: 342,
            title: "CDMX se prepara para recibir al mundo: rutas, sedes y más",
            content: "La Ciudad de México se alista para ser una de las sedes más vibrantes del Mundial 2026. Con el Estadio Azteca como epicentro, las autoridades han anunciado mejoras en transporte público, señalización multilingüe y zonas de fan fest en Reforma y Chapultepec.",
            date: "2026-04-07T10:30:00Z",
            keywords: "mundial, cdmx, estadio azteca, fifa, 2026"
        ),
        CommunityPost(
            id: 2,
            source: "News",
            url: "https://marca.com",
            author: "Marca",
            image: "https://images.unsplash.com/photo-1431324155629-1a6deb1dec8d?w=800",
            likes: 489,
            title: "El Azteca será la primera sede en abrir el Mundial 2026",
            content: "La FIFA confirmó que el partido inaugural del Mundial 2026 se jugará en el icónico Estadio Azteca. Será la tercera vez que México alberga un juego inaugural mundialista, un récord histórico que pone a CDMX en el centro del mundo futbolístico.",
            date: "2026-04-07T08:00:00Z",
            keywords: "mundial, fifa, estadio azteca, inauguración, 2026"
        ),
        CommunityPost(
            id: 3,
            source: "X",
            url: "https://x.com/fifaworldcup",
            author: "FIFA World Cup",
            image: "https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=800",
            likes: 1204,
            title: "Fan Fest CDMX: el calendario oficial de actividades en Reforma",
            content: "El Fan Fest oficial de la FIFA en Paseo de la Reforma tendrá pantallas gigantes, zonas gastronómicas con comida de los 48 países participantes, música en vivo y actividades para toda la familia. Entrada gratuita todos los días de partido.",
            date: "2026-04-06T20:00:00Z",
            keywords: "mundial, fifa, fan fest, reforma, cdmx, 2026"
        ),
        CommunityPost(
            id: 4,
            source: "News",
            url: "https://espn.com.mx",
            author: "ESPN México",
            image: "https://images.unsplash.com/photo-1508098682722-e99c43a406b2?w=800",
            likes: 312,
            title: "Selecciones confirmadas para la fase de grupos en CDMX",
            content: "Ya se conocen los equipos que jugarán la fase de grupos en el Estadio Azteca. México, Brasil, Alemania y Japón son algunas de las selecciones que pisarán el césped del coloso de Santa Úrsula. Se esperan más de 200,000 turistas solo en la primera semana.",
            date: "2026-04-05T15:30:00Z",
            keywords: "mundial, fifa, selecciones, fase de grupos, azteca, 2026"
        ),
        CommunityPost(
            id: 5,
            source: "News",
            url: "https://eluniversal.com.mx",
            author: "El Universal",
            image: "https://images.unsplash.com/photo-1522778119026-d647f0596c20?w=800",
            likes: 278,
            title: "Metro y Metrobús amplían horarios para el Mundial 2026",
            content: "El sistema de transporte público de CDMX extenderá sus horarios de operación durante los días de partido. La Línea 9 del Metro, que conecta directamente con el Estadio Azteca, operará hasta las 2 AM. Metrobús habilitará rutas express.",
            date: "2026-04-04T09:15:00Z",
            keywords: "mundial, transporte, metro, metrobús, cdmx, 2026"
        ),
        CommunityPost(
            id: 6,
            source: "X",
            url: "https://x.com/miseleccionmx",
            author: "Selección Nacional",
            image: "https://images.unsplash.com/photo-1560272564-c83b66b1ad12?w=800",
            likes: 2340,
            title: "¡México en casa! La selección ya entrena en el CAR rumbo al Mundial",
            content: "La Selección Mexicana inició su preparación en el Centro de Alto Rendimiento. El cuerpo técnico confirmó la lista preliminar de 35 jugadores. Los entrenamientos serán a puerta cerrada pero habrá un día de puertas abiertas para aficionados el 15 de abril.",
            date: "2026-04-03T12:00:00Z",
            keywords: "mundial, selección, méxico, fifa, entrenamiento, 2026"
        ),

        // MARK: - Gastronomía / Street Food
        CommunityPost(
            id: 7,
            source: "News",
            url: "https://eluniversal.com.mx",
            author: "El Universal",
            image: "https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800",
            likes: 189,
            title: "Tacos, tamales y tlayudas: la guía definitiva de street food para el Mundial",
            content: "Expertos gastronómicos han creado una ruta de comida callejera imperdible para los visitantes del Mundial. Desde los tacos al pastor de la Álvaro Obregón hasta los esquites de Coyoacán, esta guía cubre los mejores puestos ambulantes de CDMX.",
            date: "2026-04-06T14:15:00Z",
            keywords: "gastronomía, street food, tacos, mundial, comercio ambulante"
        ),
        CommunityPost(
            id: 8,
            source: "Instagram",
            url: "https://instagram.com/foodie_cdmx",
            author: "foodie_cdmx",
            image: "https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=800",
            likes: 578,
            title: "Top 10 puestos ambulantes que DEBES visitar antes del Mundial",
            content: "Hicimos un recorrido por los mejores puestos ambulantes de CDMX usando Atenea como guía. Desde los elotes de Doña Mary en Chapultepec hasta los churros de Don Pepe en el Centro Histórico. ¡Aquí nuestro ranking!",
            date: "2026-03-30T17:45:00Z",
            keywords: "foodie, top 10, comida callejera, recomendaciones"
        ),
        CommunityPost(
            id: 9,
            source: "Instagram",
            url: "https://instagram.com/maboroshtacos",
            author: "maborosh_tacos",
            image: "https://images.unsplash.com/photo-1551504734-5ee1c4a1479b?w=800",
            likes: 723,
            title: "Los tacos al pastor que están rompiendo el internet",
            content: "Este puesto en la colonia Condesa lleva 3 generaciones perfeccionando el trompo. Su salsa de habanero con mango es legendaria. Ahora puedes rastrearlos en Atenea porque cambian de esquina cada semana. ¡No te los pierdas!",
            date: "2026-04-06T19:30:00Z",
            keywords: "tacos, pastor, condesa, gastronomía, viral"
        ),
        CommunityPost(
            id: 10,
            source: "News",
            url: "https://forbes.com.mx",
            author: "Forbes México",
            image: "https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=800",
            likes: 234,
            title: "Street food mexicano: un mercado de $85,000 MDP que el mundo quiere probar",
            content: "El mercado de comida callejera en México vale más de 85 mil millones de pesos anuales. Con el Mundial, Forbes analiza cómo la tecnología está transformando este sector: apps de rastreo, pagos digitales y menús multilingües son la nueva realidad.",
            date: "2026-04-02T10:00:00Z",
            keywords: "gastronomía, economía, street food, forbes, mercado"
        ),
        CommunityPost(
            id: 11,
            source: "X",
            url: "https://x.com/chaborrosfood",
            author: "Chaborros Food Truck",
            image: "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=800",
            likes: 167,
            title: "Menú especial mundialista: hamburguesas inspiradas en cada selección",
            content: "Para celebrar el Mundial lanzamos 8 hamburguesas temáticas: La Brasileña con piña asada, La Alemana con chucrut, La Japonesa con teriyaki y más. Encuéntranos en Atenea, estaremos cerca del Azteca los días de partido. 🍔⚽",
            date: "2026-04-05T11:00:00Z",
            keywords: "gastronomía, hamburguesas, mundial, food truck, comerciante"
        ),
        CommunityPost(
            id: 12,
            source: "Instagram",
            url: "https://instagram.com/mezcaleros_cdmx",
            author: "mezcaleros_cdmx",
            image: "https://images.unsplash.com/photo-1516684669134-de6f7c473a2a?w=800",
            likes: 445,
            title: "Ruta del mezcal ambulante: 5 puestos que debes conocer",
            content: "El mezcal artesanal también se vende en las calles de CDMX. Estos 5 puestos ofrecen degustaciones de mezcales de Oaxaca, Guerrero y Puebla a precios accesibles. Todos están verificados en Atenea con calificaciones de 4.8+ estrellas.",
            date: "2026-03-28T16:00:00Z",
            keywords: "mezcal, bebidas, artesanal, oaxaca, ruta"
        ),

        // MARK: - Atenea / Tecnología
        CommunityPost(
            id: 13,
            source: "X",
            url: "https://x.com/atenea_app",
            author: "Atenea App",
            image: "https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=800",
            likes: 95,
            title: "¡Más de 500 comerciantes ya usan Atenea en CDMX!",
            content: "Estamos emocionados de anunciar que más de 500 comerciantes ambulantes se han registrado en Atenea. Desde vendedores de jugos hasta artesanos, nuestra comunidad crece cada día. ¡Únete y digitaliza tu negocio!",
            date: "2026-04-05T09:00:00Z",
            keywords: "atenea, comerciantes, comunidad, registro"
        ),
        CommunityPost(
            id: 14,
            source: "News",
            url: "https://expansion.mx",
            author: "Expansión",
            image: "https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?w=800",
            likes: 203,
            title: "Pagos digitales revolucionan el comercio callejero mexicano",
            content: "Cada vez más vendedores ambulantes aceptan pagos con QR y tarjeta. Plataformas como Atenea integran Tap to Pay y códigos QR, eliminando la barrera del efectivo y abriendo las puertas a turistas que no cargan pesos.",
            date: "2026-04-01T13:00:00Z",
            keywords: "fintech, pagos digitales, tap to pay, QR, tecnología"
        ),
        CommunityPost(
            id: 15,
            source: "X",
            url: "https://x.com/atenea_app",
            author: "Atenea App",
            image: "https://images.unsplash.com/photo-1526628953301-3e589a6a8b74?w=800",
            likes: 134,
            title: "Nueva función: radar de comerciantes en tiempo real",
            content: "Acabamos de lanzar el radar de comerciantes. Abre Atenea y ve en tiempo real qué vendedores están cerca de ti, qué ofrecen y cuánto tardan en llegar. Ideal para los días de partido cuando hay miles de personas buscando comida.",
            date: "2026-04-04T14:00:00Z",
            keywords: "atenea, radar, tecnología, tiempo real, función nueva"
        ),
        CommunityPost(
            id: 16,
            source: "News",
            url: "https://wired.com",
            author: "WIRED en Español",
            image: "https://images.unsplash.com/photo-1535303311164-664fc9ec6532?w=800",
            likes: 356,
            title: "Atenea: la app mexicana que usa IA para conectar vendedores ambulantes con turistas",
            content: "WIRED analiza cómo Atenea utiliza inteligencia artificial Claude para dar recomendaciones personalizadas, traducir en tiempo real entre 25 idiomas y predecir zonas de alta demanda durante eventos masivos como el Mundial 2026.",
            date: "2026-03-29T08:00:00Z",
            keywords: "atenea, IA, inteligencia artificial, wired, tecnología, innovación"
        ),
        CommunityPost(
            id: 17,
            source: "Instagram",
            url: "https://instagram.com/atenea_app",
            author: "atenea_app",
            image: "https://images.unsplash.com/photo-1512941937669-90a1b58e7e9c?w=800",
            likes: 289,
            title: "Tutorial: cómo registrar tu negocio en Atenea en 3 minutos",
            content: "¿Eres comerciante ambulante y quieres aparecer en el mapa? Solo necesitas: 1) Descargar Atenea, 2) Registrarte con tu nombre y tipo de negocio, 3) Activar tu ubicación. ¡Listo! Tus clientes te encontrarán al instante.",
            date: "2026-04-03T10:30:00Z",
            keywords: "atenea, tutorial, registro, comerciante, onboarding"
        ),
        CommunityPost(
            id: 18,
            source: "X",
            url: "https://x.com/atenea_app",
            author: "Atenea App",
            image: "https://images.unsplash.com/photo-1557804506-669a67965ba0?w=800",
            likes: 87,
            title: "Red SOS de emergencia: tecnología mesh sin internet para el Mundial",
            content: "Atenea incluye una red de emergencia que funciona SIN internet usando Bluetooth y NearbyInteraction de Apple. Si estás en un evento masivo y hay una emergencia, puedes alertar a personas cercanas aunque no haya señal celular.",
            date: "2026-04-01T16:45:00Z",
            keywords: "atenea, emergencia, SOS, mesh, seguridad, tecnología"
        ),

        // MARK: - Comerciantes / Historias
        CommunityPost(
            id: 19,
            source: "Instagram",
            url: "https://instagram.com/atenea_mx",
            author: "atenea_mx",
            image: "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800",
            likes: 421,
            title: "Don Ramón y sus tacos de canasta conquistan Reforma",
            content: "Don Ramón lleva 20 años vendiendo tacos de canasta en la zona de Reforma. Gracias a Atenea, ahora sus clientes pueden encontrarlo en tiempo real. \"Antes me buscaban por teléfono, ahora me rastrean como Uber\" dice entre risas.",
            date: "2026-04-03T16:20:00Z",
            keywords: "historia, comerciante, tacos, reforma, éxito"
        ),
        CommunityPost(
            id: 20,
            source: "Instagram",
            url: "https://instagram.com/donamary_elotes",
            author: "dona_mary_elotes",
            image: "https://images.unsplash.com/photo-1470337458703-46ad1756a187?w=800",
            likes: 634,
            title: "Doña Mary: de un carrito de elotes a 3 puntos de venta con Atenea",
            content: "Doña Mary empezó con un solo carrito de elotes en Chapultepec. Hoy tiene 3 puntos de venta y usa Atenea para coordinar a sus empleados y rastrear la demanda. \"La tecnología me cambió el negocio\", dice orgullosa. Su esquite con chile de árbol es legendario.",
            date: "2026-03-31T14:00:00Z",
            keywords: "historia, comerciante, elotes, éxito, emprendimiento"
        ),
        CommunityPost(
            id: 21,
            source: "News",
            url: "https://jornada.com.mx",
            author: "La Jornada",
            image: "https://images.unsplash.com/photo-1590479773265-7464e5d48118?w=800",
            likes: 198,
            title: "Jóvenes emprendedores reinventan el comercio ambulante con tecnología",
            content: "Una nueva generación de vendedores ambulantes usa smartphones, redes sociales y apps como Atenea para llegar a más clientes. Carlos, de 24 años, vende café de especialidad en bicicleta y ya tiene 200 seguidores en la plataforma.",
            date: "2026-03-27T11:30:00Z",
            keywords: "emprendimiento, jóvenes, tecnología, comerciante, innovación"
        ),
        CommunityPost(
            id: 22,
            source: "X",
            url: "https://x.com/luistamalero",
            author: "Luis El Tamalero",
            image: "https://images.unsplash.com/photo-1534483509719-8bd347ae5a1d?w=800",
            likes: 312,
            title: "Mi ruta de tamales para los días de partido: ¡Síganme en Atenea!",
            content: "Amigos, los días de partido estaré desde las 5 AM en las cercanías del Azteca con tamales oaxaqueños, verdes, rojos y de dulce. Atole de guayaba incluido. Búsquenme como 'Luis El Tamalero' en Atenea para ver mi ubicación exacta.",
            date: "2026-04-06T05:30:00Z",
            keywords: "comerciante, tamales, azteca, mundial, ruta"
        ),
        CommunityPost(
            id: 23,
            source: "Instagram",
            url: "https://instagram.com/artesanias_oax",
            author: "artesanias_oaxaca",
            image: "https://images.unsplash.com/photo-1513519245088-0e12902e35ca?w=800",
            likes: 356,
            title: "Artesanías oaxaqueñas llegan al Fan Fest: alebrijes mundialistas",
            content: "La familia López trae desde Oaxaca una colección especial de alebrijes pintados con los colores de las selecciones del Mundial. Cada pieza es única y hecha a mano. Encuéntralos en Atenea cerca del Fan Fest de Reforma.",
            date: "2026-04-02T13:15:00Z",
            keywords: "artesanías, oaxaca, alebrijes, mundial, comerciante"
        ),
        CommunityPost(
            id: 24,
            source: "Instagram",
            url: "https://instagram.com/jugos_donjose",
            author: "jugos_donjose",
            image: "https://images.unsplash.com/photo-1622597467836-f3285f2131b8?w=800",
            likes: 198,
            title: "Jugos naturales a $25: la opción saludable cerca del Azteca",
            content: "Don José lleva su carrito de jugos naturales todos los días al camellón de Tlalpan. Naranja, zanahoria, betabel, verde... todo recién exprimido. Con el calor del verano y el Mundial, ya prepara producción doble. Rastrealo en Atenea.",
            date: "2026-04-01T08:00:00Z",
            keywords: "comerciante, jugos, saludable, azteca, bebidas"
        ),

        // MARK: - Gobierno / Regulación / Ciudad
        CommunityPost(
            id: 25,
            source: "X",
            url: "https://x.com/cdmx_oficial",
            author: "Gobierno CDMX",
            image: "https://images.unsplash.com/photo-1449824913935-59a10b8d2000?w=800",
            likes: 156,
            title: "Nuevas zonas designadas para comercio ambulante cerca de sedes mundialistas",
            content: "El gobierno de CDMX ha designado 15 nuevas zonas de comercio ambulante regulado cerca de las sedes del Mundial. Los comerciantes registrados en plataformas digitales tendrán prioridad de ubicación.",
            date: "2026-04-02T08:30:00Z",
            keywords: "gobierno, regulación, zonas comerciales, mundial"
        ),
        CommunityPost(
            id: 26,
            source: "News",
            url: "https://reforma.com",
            author: "Reforma",
            image: "https://images.unsplash.com/photo-1477959858617-67f85cf4f1df?w=800",
            likes: 245,
            title: "CDMX invertirá $2,000 MDP en infraestructura para el Mundial",
            content: "La jefa de gobierno anunció inversiones en mejora de banquetas, iluminación LED, señalización multilingüe y WiFi público en las zonas cercanas al Estadio Azteca y las principales avenidas turísticas. Las obras concluirán en mayo.",
            date: "2026-03-25T09:00:00Z",
            keywords: "gobierno, infraestructura, inversión, mundial, cdmx"
        ),
        CommunityPost(
            id: 27,
            source: "News",
            url: "https://excelsior.com.mx",
            author: "Excélsior",
            image: "https://images.unsplash.com/photo-1582213782179-e0d53f98f2ca?w=800",
            likes: 134,
            title: "Programa de capacitación para comerciantes ambulantes antes del Mundial",
            content: "El gobierno de CDMX y la UNAM lanzan un programa gratuito de capacitación para vendedores ambulantes: higiene alimentaria, inglés básico, uso de apps de pago y primeros auxilios. Ya se inscribieron más de 3,000 comerciantes.",
            date: "2026-03-20T10:00:00Z",
            keywords: "gobierno, capacitación, comerciantes, UNAM, programa"
        ),
        CommunityPost(
            id: 28,
            source: "X",
            url: "https://x.com/proteccion_civil",
            author: "Protección Civil CDMX",
            image: "https://images.unsplash.com/photo-1504384308090-c894fdcc538d?w=800",
            likes: 89,
            title: "Plan de seguridad para eventos masivos: lo que debes saber",
            content: "Protección Civil presenta el plan de seguridad para el Mundial: puntos de encuentro, rutas de evacuación, brigadas médicas cada 200 metros y la app Atenea como canal oficial de alertas SOS mediante su red mesh de emergencia.",
            date: "2026-04-05T07:00:00Z",
            keywords: "seguridad, protección civil, emergencia, mundial, plan"
        ),

        // MARK: - Economía / Negocios
        CommunityPost(
            id: 29,
            source: "News",
            url: "https://milenio.com",
            author: "Milenio",
            image: "https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=800",
            likes: 267,
            title: "Comercio informal genera $12,000 MDP durante eventos masivos en CDMX",
            content: "Un estudio reciente revela que el comercio ambulante genera más de 12 mil millones de pesos durante eventos masivos en la capital. Con el Mundial 2026, se espera que esta cifra se duplique gracias a la afluencia de turistas internacionales.",
            date: "2026-04-04T11:45:00Z",
            keywords: "economía, comercio informal, mundial, impacto económico"
        ),
        CommunityPost(
            id: 30,
            source: "News",
            url: "https://elfinanciero.com.mx",
            author: "El Financiero",
            image: "https://images.unsplash.com/photo-1526304640581-d334cdbbf45e?w=800",
            likes: 178,
            title: "Turismo mundialista dejará derrama de $45,000 MDP en CDMX",
            content: "Analistas estiman que el turismo del Mundial 2026 generará una derrama económica de 45 mil millones de pesos solo en la Ciudad de México. Hoteles, restaurantes y comercio ambulante serán los principales beneficiarios.",
            date: "2026-03-26T12:30:00Z",
            keywords: "economía, turismo, derrama, mundial, inversión"
        ),
        CommunityPost(
            id: 31,
            source: "News",
            url: "https://bloomberg.com.mx",
            author: "Bloomberg Línea",
            image: "https://images.unsplash.com/photo-1460925895917-afdab827c52f?w=800",
            likes: 301,
            title: "Fintech para el comercio informal: la oportunidad de $100 MUSD que nadie veía",
            content: "Bloomberg analiza cómo las startups fintech están descubriendo un mercado masivo en la digitalización del comercio ambulante latinoamericano. Atenea, con su enfoque en el Mundial, lidera esta nueva ola de inclusión financiera digital.",
            date: "2026-03-22T14:00:00Z",
            keywords: "fintech, economía, startups, inversión, tecnología, atenea"
        ),

        // MARK: - Cultura / Turismo
        CommunityPost(
            id: 32,
            source: "Instagram",
            url: "https://instagram.com/visit_cdmx",
            author: "visit_cdmx",
            image: "https://images.unsplash.com/photo-1518105779142-d975f22f1b0a?w=800",
            likes: 892,
            title: "CDMX en 48 horas: guía para turistas del Mundial",
            content: "Llegaste al Mundial y tienes 2 días libres entre partidos. Aquí la guía definitiva: Día 1 — Centro Histórico, Templo Mayor, tacos en el mercado de San Juan. Día 2 — Chapultepec, Museo de Antropología, mezcal en la Condesa. Usa Atenea para encontrar los mejores puestos.",
            date: "2026-04-07T06:00:00Z",
            keywords: "turismo, guía, cdmx, cultura, mundial"
        ),
        CommunityPost(
            id: 33,
            source: "X",
            url: "https://x.com/caborobot",
            author: "Travel Mexico",
            image: "https://images.unsplash.com/photo-1585464231875-d9ef1f5ad396?w=800",
            likes: 445,
            title: "5 mercados de CDMX que todo turista mundialista debe visitar",
            content: "La Merced, Jamaica, San Juan, Coyoacán y Sonora. Estos 5 mercados son la esencia gastronómica y cultural de la Ciudad de México. Cada uno tiene su personalidad y sus joyas escondidas. En Atenea puedes ver qué comerciantes están activos en cada zona.",
            date: "2026-04-01T11:00:00Z",
            keywords: "turismo, mercados, cultura, gastronomía, cdmx"
        ),
        CommunityPost(
            id: 34,
            source: "News",
            url: "https://lonelyplanet.com",
            author: "Lonely Planet",
            image: "https://images.unsplash.com/photo-1547995886-6dc09384c6e6?w=800",
            likes: 567,
            title: "Mexico City: Why the World Cup host is already the world's coolest city",
            content: "Lonely Planet dedica su portada a CDMX como la ciudad más vibrante del mundo en 2026. Destaca la escena gastronómica callejera, la arquitectura, los museos y la energía única que el Mundial potenciará. Recomienda apps locales como Atenea para vivir la experiencia auténtica.",
            date: "2026-03-18T15:00:00Z",
            keywords: "turismo, lonely planet, cdmx, cultura, mundial, internacional"
        ),
        CommunityPost(
            id: 35,
            source: "Instagram",
            url: "https://instagram.com/murales_cdmx",
            author: "murales_cdmx",
            image: "https://images.unsplash.com/photo-1561839561-b13bcfe0f6b5?w=800",
            likes: 723,
            title: "Nuevos murales mundialistas aparecen en colonias Roma y Condesa",
            content: "Artistas urbanos han pintado más de 20 murales temáticos del Mundial en las colonias Roma y Condesa. Desde retratos de leyendas del fútbol mexicano hasta piezas abstractas con los colores de las 48 selecciones. Ruta de murales disponible en Atenea.",
            date: "2026-04-04T18:00:00Z",
            keywords: "arte, murales, cultura, roma, condesa, mundial"
        ),

        // MARK: - Trending / Viral / Creators
        CommunityPost(
            id: 36,
            source: "X",
            url: "https://x.com/juanfutmx",
            author: "JuanFutMX",
            image: "https://images.unsplash.com/photo-1579952363873-27f3bade9f55?w=800",
            likes: 1567,
            title: "POV: llegas al Azteca y hay un señor vendiendo los mejores tacos del mundo",
            content: "El video ya tiene 2 millones de views. Un turista alemán prueba por primera vez tacos al pastor de un puesto ambulante fuera del Azteca y su reacción se vuelve viral. El vendedor, Don Memo, ya tiene 10,000 seguidores en Atenea.",
            date: "2026-04-07T22:00:00Z",
            keywords: "viral, trending, tacos, mundial, video"
        ),
        CommunityPost(
            id: 37,
            source: "Instagram",
            url: "https://instagram.com/alejandraeats",
            author: "alejandra.eats",
            image: "https://images.unsplash.com/photo-1529006557810-274b9b2fc783?w=800",
            likes: 1890,
            title: "Probé TODA la comida callejera de Coyoacán en UN DÍA",
            content: "Challenge aceptado: comí en 15 puestos ambulantes de Coyoacán en un solo día. Desde las quesadillas de huitlacoche hasta los helados de leche quemada. Todo rastreado con Atenea. El video completo ya está en mi canal. ¿Cuál es su favorito?",
            date: "2026-04-06T12:00:00Z",
            keywords: "creator, foodie, coyoacán, challenge, viral, gastronomía"
        ),
        CommunityPost(
            id: 38,
            source: "X",
            url: "https://x.com/dlopezblog",
            author: "Diego López Blog",
            image: "https://images.unsplash.com/photo-1504384764586-bb4cdc1707b0?w=800",
            likes: 234,
            title: "Thread: 🧵 Cómo la tecnología está salvando al comercio ambulante en México",
            content: "Hilo largo sobre cómo apps como Atenea están cambiando la vida de miles de vendedores ambulantes en CDMX. Desde pagos digitales hasta zonas de demanda con IA, el comercio informal se está modernizando sin perder su esencia. 1/25",
            date: "2026-04-03T20:00:00Z",
            keywords: "creator, thread, tecnología, comercio ambulante, opinión"
        ),
        CommunityPost(
            id: 39,
            source: "Instagram",
            url: "https://instagram.com/travel_matt",
            author: "travel_matt",
            image: "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800",
            likes: 1234,
            title: "I found the BEST street food in Mexico City using this app",
            content: "As a tourist from the US, I was worried about finding good food outside the tourist traps. Then I downloaded Atenea and it literally shows you where the local vendors are in real time. Game changer. The AI even translated the menus for me!",
            date: "2026-04-05T19:00:00Z",
            keywords: "creator, turismo, review, atenea, internacional, trending"
        ),
        CommunityPost(
            id: 40,
            source: "X",
            url: "https://x.com/karlafootball",
            author: "Karla Fútbol",
            image: "https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?w=800",
            likes: 678,
            title: "Las mejores botanas para ver el partido en casa, compradas en la calle",
            content: "No todos tenemos boleto para el Azteca pero sí podemos comer como reyes. Aquí mi lista de botanas callejeras para el watch party: chicharrones preparados, tostilocos, mangonadas y micheladas. Todo conseguido con Atenea en menos de 30 min.",
            date: "2026-04-07T15:00:00Z",
            keywords: "creator, botanas, mundial, fútbol, trending"
        ),
        CommunityPost(
            id: 41,
            source: "Instagram",
            url: "https://instagram.com/nomada_digital",
            author: "nomada_digital_mx",
            image: "https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=800",
            likes: 345,
            title: "Trabajar remoto desde los puestos de café ambulante de CDMX",
            content: "Descubrí que varios puestos ambulantes de café ya ofrecen WiFi portátil para sus clientes. Me senté en una banca de Reforma con mi laptop, un café de olla artesanal y trabajé toda la mañana. El futuro del coworking es ambulante.",
            date: "2026-03-29T09:30:00Z",
            keywords: "creator, nómada digital, café, coworking, tendencia"
        ),
        CommunityPost(
            id: 42,
            source: "X",
            url: "https://x.com/datamx",
            author: "Data México",
            image: "https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=800",
            likes: 456,
            title: "Mapa de calor: dónde se concentran más vendedores ambulantes en CDMX",
            content: "Usando datos abiertos y la API de Atenea, creamos un mapa de calor que muestra la densidad de comerciantes ambulantes por colonia. Centro Histórico, Coyoacán y las cercanías del Azteca lideran. Los datos completos están en nuestro GitHub.",
            date: "2026-04-02T16:00:00Z",
            keywords: "datos, mapa, tecnología, trending, análisis"
        ),

        // MARK: - Seguridad / Emergencia
        CommunityPost(
            id: 43,
            source: "News",
            url: "https://proceso.com.mx",
            author: "Proceso",
            image: "https://images.unsplash.com/photo-1582139329536-e7284fece509?w=800",
            likes: 210,
            title: "Red mesh de emergencia: cómo funciona la tecnología SOS sin internet",
            content: "La tecnología de red mesh que usa Atenea permite enviar alertas de emergencia entre dispositivos cercanos usando Bluetooth, sin necesidad de WiFi o datos celulares. En pruebas, logró cubrir un radio de 500 metros con solo 20 dispositivos conectados.",
            date: "2026-03-24T10:00:00Z",
            keywords: "seguridad, emergencia, mesh, tecnología, SOS"
        ),
        CommunityPost(
            id: 44,
            source: "X",
            url: "https://x.com/cruzroja_mx",
            author: "Cruz Roja México",
            image: "https://images.unsplash.com/photo-1516574187841-cb9cc2ca948b?w=800",
            likes: 178,
            title: "Brigadas de primeros auxilios en todas las zonas de venta ambulante del Mundial",
            content: "Cruz Roja Mexicana desplegará brigadas de primeros auxilios en las zonas de alta concentración de comercio ambulante durante el Mundial. Coordinamos con apps como Atenea para geolocalizar incidentes en tiempo real.",
            date: "2026-04-06T07:00:00Z",
            keywords: "seguridad, cruz roja, primeros auxilios, mundial, emergencia"
        ),

        // MARK: - Sustentabilidad
        CommunityPost(
            id: 45,
            source: "News",
            url: "https://greenpeace.org.mx",
            author: "Greenpeace México",
            image: "https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?w=800",
            likes: 289,
            title: "Comercio ambulante sustentable: vendedores adoptan envases biodegradables",
            content: "Más de 200 comerciantes ambulantes en CDMX han cambiado a envases biodegradables de maíz para el Mundial. La iniciativa, apoyada por Greenpeace y el gobierno local, busca reducir la huella de plástico del evento más grande del año.",
            date: "2026-03-21T11:00:00Z",
            keywords: "sustentabilidad, medio ambiente, biodegradable, comerciantes"
        ),
        CommunityPost(
            id: 46,
            source: "Instagram",
            url: "https://instagram.com/eco_street_food",
            author: "eco_street_food",
            image: "https://images.unsplash.com/photo-1542601906990-b4d3fb778b09?w=800",
            likes: 412,
            title: "Zero waste en la calle: conoce a los vendedores que no generan basura",
            content: "Estos 5 vendedores ambulantes trabajan con filosofía zero waste: hojas de maíz como plato, popotes de carrizo, bolsas de tela reutilizables y composta de sus propios residuos orgánicos. La sustentabilidad también es ambulante.",
            date: "2026-03-28T13:30:00Z",
            keywords: "sustentabilidad, zero waste, eco, comerciante, innovación"
        ),

        // MARK: - Accesibilidad / Inclusión
        CommunityPost(
            id: 47,
            source: "News",
            url: "https://publimetro.com.mx",
            author: "Publimetro",
            image: "https://images.unsplash.com/photo-1573497620053-ea5300f94f21?w=800",
            likes: 156,
            title: "Atenea lanza modo accesible: comercio ambulante para todos",
            content: "La app Atenea ahora incluye modo de alto contraste, soporte para lectores de pantalla, navegación por voz y modo para daltonismo. \"Queremos que todos puedan encontrar un taco, sin importar sus capacidades\", dice el equipo de desarrollo.",
            date: "2026-03-19T08:00:00Z",
            keywords: "accesibilidad, inclusión, tecnología, atenea, discapacidad"
        ),
        CommunityPost(
            id: 48,
            source: "X",
            url: "https://x.com/incluyemx",
            author: "Incluye México",
            image: "https://images.unsplash.com/photo-1559027615-cd4628902d4a?w=800",
            likes: 234,
            title: "Vendedores con discapacidad visual encuentran clientes gracias a la tecnología",
            content: "Roberto, vendedor de dulces con discapacidad visual, usa la función de voz de Atenea para recibir notificaciones de clientes cercanos. \"Antes dependía de que la gente me encontrara, ahora ellos vienen a mí\". Su historia inspira a la comunidad.",
            date: "2026-04-01T09:00:00Z",
            keywords: "accesibilidad, inclusión, discapacidad, historia, comerciante"
        ),

        // MARK: - Internacional / Turistas
        CommunityPost(
            id: 49,
            source: "News",
            url: "https://nytimes.com",
            author: "The New York Times",
            image: "https://images.unsplash.com/photo-1558618666-fcd25c85f82e?w=800",
            likes: 890,
            title: "Street Food in Mexico City: A World Cup Guide for First-Timers",
            content: "The NYT travel section dedicates a full spread to CDMX street food ahead of the World Cup. From al pastor tacos to blue corn quesadillas, the guide recommends using local apps like Atenea to find authentic vendors instead of tourist-oriented restaurants.",
            date: "2026-04-07T04:00:00Z",
            keywords: "internacional, NYT, turismo, street food, mundial, guía"
        ),
        CommunityPost(
            id: 50,
            source: "X",
            url: "https://x.com/bbcmundo",
            author: "BBC Mundo",
            image: "https://images.unsplash.com/photo-1489749798305-4fea3ae63d43?w=800",
            likes: 567,
            title: "Cómo CDMX convirtió su comercio callejero en su mayor atractivo turístico",
            content: "La BBC analiza el fenómeno del comercio ambulante en CDMX como atractivo turístico único. A diferencia de otras ciudades que criminalizan a los vendedores, México los integra al ecosistema urbano con tecnología y regulación inteligente.",
            date: "2026-03-15T16:00:00Z",
            keywords: "internacional, BBC, turismo, comercio ambulante, mundial, análisis"
        ),
    ]
}

// MARK: - Community Post
struct CommunityPost: Codable, Identifiable {
    let id: Int
    let source: String
    let url: String
    let author: String
    let image: String
    let likes: Int
    let title: String
    let content: String
    let date: String
    let keywords: String

    // Backwards compatibility
    var username: String { author }
    var caption: String { content }

    var keywordArray: [String] {
        keywords.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
    }

    var formattedDate: String {
        // Try different date formats
        let isoFormatter = ISO8601DateFormatter()
        var postDate: Date?

        // Try with Z suffix (standard ISO8601)
        postDate = isoFormatter.date(from: date)

        // If that fails, try without Z
        if postDate == nil {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            postDate = dateFormatter.date(from: date)
        }

        guard let postDate = postDate else {
            return "Hace tiempo"
        }

        let now = Date()
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: postDate, to: now)

        if let years = components.year, years > 0 {
            return "Hace \(years) año\(years == 1 ? "" : "s")"
        } else if let months = components.month, months > 0 {
            return "Hace \(months) mes\(months == 1 ? "" : "es")"
        } else if let days = components.day, days > 0 {
            return "Hace \(days) día\(days == 1 ? "" : "s")"
        } else if let hours = components.hour, hours > 0 {
            return "Hace \(hours) hora\(hours == 1 ? "" : "s")"
        } else if let minutes = components.minute, minutes > 0 {
            return "Hace \(minutes) minuto\(minutes == 1 ? "" : "s")"
        } else {
            return "Justo ahora"
        }
    }
}
