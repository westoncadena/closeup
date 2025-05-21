//
//  SignInViewModel.swift
//  closeup
//
//  Created by Weston Cadena on 5/9/25.
//

import Foundation

enum SignInError: Error {
    case invalidForm
    case invalidEmail
    case invalidPassword
    
    var message: String {
        switch self {
        case .invalidForm:
            return "Please check your email and password"
        case .invalidEmail:
            return "Please enter a valid email address"
        case .invalidPassword:
            return "Password must be at least 6 characters"
        }
    }
}

@MainActor
class SignInViewModel: ObservableObject {
    let signInGoogle = SignInGoogle()

    func isFormValid(email: String, password: String) throws {
        guard email.isValidEmail() else {
            throw SignInError.invalidEmail
        }
        guard password.count > 6 else {
            throw SignInError.invalidPassword
        }
    }

    func registerNewUserWithEmail(email: String, password: String) async throws -> AppUser {
        try isFormValid(email: email, password: password)
        return try await AuthManager.shared.registerNewUserWithEmail(email: email, password: password)
    }

    func signInWithEmail(email: String, password: String) async throws -> AppUser {
        try isFormValid(email: email, password: password)
        return try await AuthManager.shared.signInWithEmail(email: email, password: password)
    }
    
    func signInWithGoogle() async throws -> AppUser {
        let googleResult = try await signInGoogle.startSignInWithGoogleFlow()
        return try await AuthManager.shared.signInWithGoogle(idToken: googleResult.idToken, nonce: googleResult.nonce)
    }
}

extension String {
    func isValidEmail() -> Bool {

        let emailFormat = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailFormat)
        return emailPredicate.evaluate(with: self)

    }
}
