//
//  SignInViewModel.swift
//  closeup
//
//  Created by Weston Cadena on 5/9/25.
//

import Foundation

@MainActor
class SignInViewModel: ObservableObject {
    let signInGoogle = SignInGoogle()
    
    static let passwordRequirements = "Password must be at least 6 characters"

    func isFormValid(email: String, password: String) throws {
        guard email.isValidEmail() else {
            throw AuthError.invalidEmail
        }
        guard password.count >= 6 else {
            throw AuthError.invalidPassword
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
