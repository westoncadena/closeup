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
    
    func signInWithGoogle() async throws -> AppUser {
        let googleResult = try await signInGoogle.startSignInWithGoogleFlow()
        return try await AuthManager.shared.signInWithGoogle(idToken: googleResult.idToken, nonce: googleResult.nonce)
    }
}

