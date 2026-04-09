//
//  UserRegistrationInfo.swift
//  Atenea
//
//  Shared model for user registration data across auth flows
//

import Foundation

struct UserRegistrationInfo {
    let fullName: String
    let age: String
    let country: String
    let email: String
    let phoneNumber: String
    let accessibilityOption: AccessibilityOption
}
