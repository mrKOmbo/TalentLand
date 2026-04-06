//
//  MenuStateManager.swift
//  atenea
//
//  Manages the global state of the sidebar menu across the app
//

import Foundation
internal import Combine

class MenuStateManager: ObservableObject {
    static let shared = MenuStateManager()

    @Published var showMenu: Bool = false

    private init() {}

    func toggleMenu() {
        showMenu.toggle()
    }

    func openMenu() {
        showMenu = true
    }

    func closeMenu() {
        showMenu = false
    }
}
