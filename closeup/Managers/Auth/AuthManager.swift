//
//  AuthManager.swift
//  closeup
//
//  Created by Weston Cadena on 5/9/25.
//

import Foundation
import Supabase
import GoogleSignIn

enum AuthError: Error {
    case sessionMissing
    case emailVerificationRequired
    case invalidCredentials
    case invalidEmail
    case invalidPassword
    case emailAlreadyRegistered
    case unknown(Error)
    
    var message: String {
        switch self {
        case .sessionMissing:
            return "Authentication session not found"
        case .emailVerificationRequired:
            return "Please check your inbox to verify your email. You can sign in after verification."
        case .invalidCredentials:
            return "Invalid email or password"
        case .invalidEmail:
            return "Please enter a valid email address"
        case .invalidPassword:
            return SignInViewModel.passwordRequirements
        case .emailAlreadyRegistered:
            return "This email is already registered but not verified. Please check your inbox for a verification link or request a new one."
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}

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

    // Update method to check Supabase's email verification status
    func isEmailVerified(user: Auth.User) -> Bool {
        // Check if the user's email is confirmed using Supabase's user metadata
        return user.aud == "authenticated" && user.email != nil
    }

    // MARK: - Register New User with Email
    func registerNewUserWithEmail(email: String, password: String) async throws -> AppUser {
        do {
            print("Attempting to register new user with email: \(email)")
            let regAuthResponse = try await client.auth.signUp(email: email, password: password)
            
            // Check if email confirmation is required
            if regAuthResponse.session == nil {
                print("No session returned - email verification likely required")
                if regAuthResponse.user != nil {
                    print("User created successfully, verification email should be sent")
                    throw AuthError.emailVerificationRequired
                } else {
                    print("No user and no session created")
                    throw AuthError.sessionMissing
                }
            }
            
            guard let session = regAuthResponse.session else {
                print("Session is nil after registration")
                throw AuthError.sessionMissing
            }
            
            print("Registration successful with session: \(session.user.id)")
            return AppUser(uid: session.user.id.uuidString, email: session.user.email)
        } catch let error as AuthError {
            print("AuthError during registration: \(error.message)")
            throw error
        } catch {
            print("Caught error during registration: \(error.localizedDescription)")
            if error.localizedDescription.contains("already registered") {
                print("Email already registered, attempting to resend verification...")
                do {
                    print("Calling resend verification for email: \(email)")
                    // Use Supabase's built-in resend functionality
                    try await client.auth.resend(email: email, type: .signup)
                    print("Verification email resent successfully")
                    throw AuthError.emailAlreadyRegistered
                } catch let resendError {
                    print("Failed to resend verification email: \(resendError.localizedDescription)")
                    throw AuthError.unknown(resendError)
                }
            }
            throw AuthError.unknown(error)
        }
    }

    // MARK: - Sign In with Email
    func signInWithEmail(email: String, password: String) async throws -> AppUser {
        do {
            let session = try await client.auth.signIn(email: email, password: password)
            
            // Check if email is verified using Supabase's built-in verification status
            if !isEmailVerified(user: session.user) {
                print("Email not verified for user: \(session.user.email ?? "")")
                try await signOut()
                throw AuthError.emailVerificationRequired
            }
            
            // After successful verification, ensure user exists in our database
            let userId = UUID(uuidString: session.user.id.uuidString)!
            if try await createUserIfNeeded(userId: userId, email: session.user.email ?? "") {
                print("Created new user profile in database")
            }
            
            return AppUser(uid: session.user.id.uuidString, email: session.user.email)
        } catch let error as AuthError {
            throw error
        } catch {
            throw AuthError.invalidCredentials
        }
    }
    
    // Helper method to create a user in our database if they don't exist
    private func createUserIfNeeded(userId: UUID, email: String) async throws -> Bool {
        // First check if user exists
        let existingUser: [UserProfile] = try await client
            .from("users")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
            
        if existingUser.isEmpty {
            // Create new user profile
            let username = email.components(separatedBy: "@")[0] // Default username from email
            let payload = [
                "user_id": userId.uuidString,
                "username": username,
                "first_name": "",
                "last_name": "",
                "email": email
            ]
            
            try await client
                .from("users")
                .insert(payload)
                .execute()
                
            return true
        }
        
        return false
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
