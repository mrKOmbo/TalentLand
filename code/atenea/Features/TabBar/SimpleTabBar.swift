//
//  SimpleTabBar.swift
//  atenea
//
//  Tab Bar ultraThinMaterial con 3 tabs: Mapa, Comunidad, Álbum
//

import SwiftUI

// Tab Bar simple para otras vistas
struct SimpleTabBar: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var languageManager: LanguageManager

    var body: some View {
        HStack(spacing: 0) {
            // Tab 1: Mapa
            SimpleTabBarItem(
                icon: "map.fill",
                title: LocalizedString("tab.map"),
                isSelected: selectedTab == 0
            ) {
                selectedTab = 0
            }

            // Tab 2: Comunidad
            SimpleTabBarItem(
                icon: "person.3.fill",
                title: LocalizedString("tab.community"),
                isSelected: selectedTab == 1
            ) {
                selectedTab = 1
            }

            // Tab 3: Álbum
            SimpleTabBarItem(
                icon: "square.grid.3x3.fill",
                title: LocalizedString("tab.album"),
                isSelected: selectedTab == 2
            ) {
                selectedTab = 2
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 17)
        .padding(.bottom, 17)
        .background(
            // Fondo negro sólido para que sea visible sobre cualquier contenido
            Rectangle()
                .fill(Color.black)
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: -5)
        )
        .id(languageManager.currentLanguage) // Force re-render when language changes
    }
}

// Item individual del Tab Bar simple
struct SimpleTabBarItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .blue : .gray)

                Text(title)
                    .font(.system(size: 11))
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
