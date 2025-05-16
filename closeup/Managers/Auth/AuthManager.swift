//
//  AuthManager.swift
//  closeup
//
//  Created by Weston Cadena on 5/9/25.
//

import Foundation
import Supabase
import GoogleSignIn

struct AppUser {
    let uid: String
    let email: String?
}

class AuthManager {
    static let shared = AuthManager()
    
    private init() {}
    
    let client = SupabaseClient(
        supabaseURL: URL(string: "https://frjkiymssmpphkktvmsl.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZyamtpeW1zc21wcGhra3R2bXNsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDU5NDQyODAsImV4cCI6MjA2MTUyMDI4MH0.uu681e7ZdLMimZiae00-wcBL8wE04PqA8xoneXv3Pjc"
    )

    
    func getCurrentSession() async throws -> AppUser {
        let session = try await client.auth.session
        print(session)
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
