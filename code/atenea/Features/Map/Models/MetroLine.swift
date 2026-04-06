//
//  MetroLine.swift
//  atenea
//
//  Modelo de datos para las líneas del Metro CDMX
//

import Foundation
import CoreLocation
import UIKit

struct MetroLine {
    let id: String
    let name: String
    let number: Int
    let color: UIColor
    let coordinates: [CLLocationCoordinate2D]
    let stationNames: [String]
    let startStation: String
    let endStation: String
}

// Datos de las líneas del Metro CDMX
// Fuente: Sistema de Transporte Colectivo Metro - CDMX
let metroLinesCDMX: [MetroLine] = [
    // LÍNEA 1 (Rosa) - Observatorio a Pantitlán
    MetroLine(
        id: "linea-1",
        name: "Línea 1",
        number: 1,
        color: UIColor(red: 0.95, green: 0.40, blue: 0.65, alpha: 1.0), // Rosa
        coordinates: [
            CLLocationCoordinate2D(latitude: 19.39881, longitude: -99.20067), // Observatorio
            CLLocationCoordinate2D(latitude: 19.40196, longitude: -99.19509), // Tacubaya
            CLLocationCoordinate2D(latitude: 19.40653, longitude: -99.18655), // Juanacatlán
            CLLocationCoordinate2D(latitude: 19.41088, longitude: -99.18162), // Chapultepec
            CLLocationCoordinate2D(latitude: 19.41555, longitude: -99.17743), // Sevilla
            CLLocationCoordinate2D(latitude: 19.42073, longitude: -99.17181), // Insurgentes
            CLLocationCoordinate2D(latitude: 19.42425, longitude: -99.16252), // Cuauhtémoc
            CLLocationCoordinate2D(latitude: 19.42654, longitude: -99.15489), // Balderas
            CLLocationCoordinate2D(latitude: 19.42693, longitude: -99.14769), // Salto del Agua
            CLLocationCoordinate2D(latitude: 19.42631, longitude: -99.13766), // Isabel la Católica
            CLLocationCoordinate2D(latitude: 19.42654, longitude: -99.13128), // Pino Suárez
            CLLocationCoordinate2D(latitude: 19.42543, longitude: -99.12335), // Merced
            CLLocationCoordinate2D(latitude: 19.42397, longitude: -99.11329), // Candelaria
            CLLocationCoordinate2D(latitude: 19.42257, longitude: -99.10598), // San Lázaro
            CLLocationCoordinate2D(latitude: 19.42171, longitude: -99.09629), // Moctezuma
            CLLocationCoordinate2D(latitude: 19.41984, longitude: -99.08714), // Balbuena
            CLLocationCoordinate2D(latitude: 19.41740, longitude: -99.07876), // Boulevard Puerto Aéreo
            CLLocationCoordinate2D(latitude: 19.41501, longitude: -99.07291), // Gómez Farías
            CLLocationCoordinate2D(latitude: 19.41521, longitude: -99.07242), // Pantitlán
        ],
        stationNames: [
            "Observatorio", "Tacubaya", "Juanacatlán", "Chapultepec", "Sevilla",
            "Insurgentes", "Cuauhtémoc", "Balderas", "Salto del Agua", "Isabel la Católica",
            "Pino Suárez", "Merced", "Candelaria", "San Lázaro", "Moctezuma",
            "Balbuena", "Boulevard Puerto Aéreo", "Gómez Farías", "Pantitlán"
        ],
        startStation: "Observatorio",
        endStation: "Pantitlán"
    ),

    // LÍNEA 2 (Azul) - Cuatro Caminos a Tasqueña
    MetroLine(
        id: "linea-2",
        name: "Línea 2",
        number: 2,
        color: UIColor(red: 0.0, green: 0.35, blue: 0.87, alpha: 1.0), // Azul
        coordinates: [
            CLLocationCoordinate2D(latitude: 19.45972, longitude: -99.21598), // Cuatro Caminos
            CLLocationCoordinate2D(latitude: 19.45825, longitude: -99.20329), // Panteones
            CLLocationCoordinate2D(latitude: 19.45677, longitude: -99.19528), // Tacuba
            CLLocationCoordinate2D(latitude: 19.45184, longitude: -99.18631), // Cuitláhuac
            CLLocationCoordinate2D(latitude: 19.44881, longitude: -99.17898), // Popotla
            CLLocationCoordinate2D(latitude: 19.44495, longitude: -99.17115), // Normal
            CLLocationCoordinate2D(latitude: 19.44120, longitude: -99.16335), // San Cosme
            CLLocationCoordinate2D(latitude: 19.43726, longitude: -99.15463), // Revolución
            CLLocationCoordinate2D(latitude: 19.43542, longitude: -99.14750), // Hidalgo
            CLLocationCoordinate2D(latitude: 19.43527, longitude: -99.14101), // Bellas Artes
            CLLocationCoordinate2D(latitude: 19.43489, longitude: -99.13734), // Allende
            CLLocationCoordinate2D(latitude: 19.43305, longitude: -99.13269), // Zócalo
            CLLocationCoordinate2D(latitude: 19.42625, longitude: -99.13198), // Pino Suárez
            CLLocationCoordinate2D(latitude: 19.41261, longitude: -99.13376), // San Antonio Abad
            CLLocationCoordinate2D(latitude: 19.37883, longitude: -99.13562), // Chabacano
            CLLocationCoordinate2D(latitude: 19.36231, longitude: -99.13690), // Viaducto
            CLLocationCoordinate2D(latitude: 19.35655, longitude: -99.13735), // Xola
            CLLocationCoordinate2D(latitude: 19.34625, longitude: -99.13798), // Villa de Cortés
            CLLocationCoordinate2D(latitude: 19.33743, longitude: -99.13841), // Nativitas
            CLLocationCoordinate2D(latitude: 19.32464, longitude: -99.13931), // Portales
            CLLocationCoordinate2D(latitude: 19.31371, longitude: -99.14011), // Ermita
            CLLocationCoordinate2D(latitude: 19.29999, longitude: -99.14134), // General Anaya
            CLLocationCoordinate2D(latitude: 19.28982, longitude: -99.14257), // Tasqueña
        ],
        stationNames: [
            "Cuatro Caminos", "Panteones", "Tacuba", "Cuitláhuac", "Popotla",
            "Normal", "San Cosme", "Revolución", "Hidalgo", "Bellas Artes",
            "Allende", "Zócalo", "Pino Suárez", "San Antonio Abad", "Chabacano",
            "Viaducto", "Xola", "Villa de Cortés", "Nativitas", "Portales",
            "Ermita", "General Anaya", "Tasqueña"
        ],
        startStation: "Cuatro Caminos",
        endStation: "Tasqueña"
    ),

    // LÍNEA 3 (Verde Olivo) - Indios Verdes a Universidad
    MetroLine(
        id: "linea-3",
        name: "Línea 3",
        number: 3,
        color: UIColor(red: 0.67, green: 0.71, blue: 0.18, alpha: 1.0), // Verde Olivo
        coordinates: [
            CLLocationCoordinate2D(latitude: 19.50469, longitude: -99.11940), // Indios Verdes
            CLLocationCoordinate2D(latitude: 19.49151, longitude: -99.11968), // Deportivo 18 de Marzo
            CLLocationCoordinate2D(latitude: 19.48512, longitude: -99.11982), // Potrero
            CLLocationCoordinate2D(latitude: 19.47868, longitude: -99.11997), // La Raza
            CLLocationCoordinate2D(latitude: 19.47023, longitude: -99.12046), // Tlatelolco
            CLLocationCoordinate2D(latitude: 19.46233, longitude: -99.12100), // Guerrero
            CLLocationCoordinate2D(latitude: 19.45421, longitude: -99.12154), // Hidalgo
            CLLocationCoordinate2D(latitude: 19.44361, longitude: -99.12228), // Juárez
            CLLocationCoordinate2D(latitude: 19.42690, longitude: -99.15489), // Balderas
            CLLocationCoordinate2D(latitude: 19.41868, longitude: -99.15568), // Niños Héroes
            CLLocationCoordinate2D(latitude: 19.40639, longitude: -99.15675), // Hospital General
            CLLocationCoordinate2D(latitude: 19.39820, longitude: -99.15723), // Centro Médico
            CLLocationCoordinate2D(latitude: 19.38175, longitude: -99.15850), // Etiopía
            CLLocationCoordinate2D(latitude: 19.37079, longitude: -99.15925), // Eugenia
            CLLocationCoordinate2D(latitude: 19.35881, longitude: -99.16000), // División del Norte
            CLLocationCoordinate2D(latitude: 19.34699, longitude: -99.16074), // Zapata
            CLLocationCoordinate2D(latitude: 19.33724, longitude: -99.16128), // Coyoacán
            CLLocationCoordinate2D(latitude: 19.32514, longitude: -99.16188), // Viveros
            CLLocationCoordinate2D(latitude: 19.31427, longitude: -99.16234), // Miguel Ángel de Quevedo
            CLLocationCoordinate2D(latitude: 19.30222, longitude: -99.16294), // Copilco
            CLLocationCoordinate2D(latitude: 19.28917, longitude: -99.16363), // Universidad
        ],
        stationNames: [
            "Indios Verdes", "Deportivo 18 de Marzo", "Potrero", "La Raza",
            "Tlatelolco", "Guerrero", "Hidalgo", "Juárez", "Balderas",
            "Niños Héroes", "Hospital General", "Centro Médico", "Etiopía",
            "Eugenia", "División del Norte", "Zapata", "Coyoacán", "Viveros",
            "Miguel Ángel de Quevedo", "Copilco", "Universidad"
        ],
        startStation: "Indios Verdes",
        endStation: "Universidad"
    ),

    // LÍNEA 9 (Café) - Tacubaya a Pantitlán
    MetroLine(
        id: "linea-9",
        name: "Línea 9",
        number: 9,
        color: UIColor(red: 0.43, green: 0.27, blue: 0.08, alpha: 1.0), // Café
        coordinates: [
            CLLocationCoordinate2D(latitude: 19.40196, longitude: -99.19509), // Tacubaya
            CLLocationCoordinate2D(latitude: 19.39828, longitude: -99.18613), // Patriotismo
            CLLocationCoordinate2D(latitude: 19.39480, longitude: -99.17850), // Chilpancingo
            CLLocationCoordinate2D(latitude: 19.39194, longitude: -99.17153), // Centro Médico
            CLLocationCoordinate2D(latitude: 19.39071, longitude: -99.16288), // Lázaro Cárdenas
            CLLocationCoordinate2D(latitude: 19.37883, longitude: -99.13562), // Chabacano
            CLLocationCoordinate2D(latitude: 19.38473, longitude: -99.10873), // Jamaica
            CLLocationCoordinate2D(latitude: 19.38906, longitude: -99.09646), // Mixiuhca
            CLLocationCoordinate2D(latitude: 19.39341, longitude: -99.08694), // Velódromo
            CLLocationCoordinate2D(latitude: 19.39841, longitude: -99.07915), // Ciudad Deportiva
            CLLocationCoordinate2D(latitude: 19.40755, longitude: -99.07291), // Puebla
            CLLocationCoordinate2D(latitude: 19.41521, longitude: -99.07242), // Pantitlán
        ],
        stationNames: [
            "Tacubaya", "Patriotismo", "Chilpancingo", "Centro Médico", "Lázaro Cárdenas",
            "Chabacano", "Jamaica", "Mixiuhca", "Velódromo", "Ciudad Deportiva",
            "Puebla", "Pantitlán"
        ],
        startStation: "Tacubaya",
        endStation: "Pantitlán"
    ),
]
