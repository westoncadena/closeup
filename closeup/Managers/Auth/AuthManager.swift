//
//  AuthManager.swift
//  closeup
//
//  Created by Weston Cadena on 5/9/25.
//

import Foundation
import Supabase
import GoogleSignIn

class AuthManager {
    static let shared = AuthManager()
    
    private init() {}
    
    let client = SupabaseClient(
        supabaseURL: URL(string: Config.supabaseUrl)!,
        supabaseKey: Config.supabaseAnonKey
    )

    
    func getCurrentSession() async throws -> AppUser {
        let session = try await client.auth.session
        print(session)
        return AppUser(uid: session.user.id.uuidString, email: session.user.email)
    }

    // MARK: - Register New User with Email
    func registerNewUserWithEmail(email: String, password: String) async throws -> AppUser {
        let regAuthResponse = try await client.auth.signUp(email: email, password: password)
        guard let session = regAuthResponse.session else {
            print("Error: No session found")
            throw AuthError.sessionMissing
        }
        return AppUser(uid: session.user.id.uuidString, email: session.user.email)
    }

    // MARK: - Sign In with Email
    func signInWithEmail(email: String, password: String) async throws -> AppUser {
        let session = try await client.auth.signIn(email: email, password: password)
        print(session)
        print(session.user)
        return AppUser(uid: session.user.id.uuidString, email: session.user.email)
    }
    
    func signInWithGoogle(idToken: String, nonce: String) async throws -> AppUser {
        let session = try await client.auth.signInWithIdToken(credentials: .init(provider: .google, idToken: idToken, nonce: nonce))
        print(session)
        print(session.user)
        return AppUser(uid: session.user.id.uuidString, email: session.user.email)
    }
    
    func signOut() async throws {
        try await client.auth.signOut()
    }
}
