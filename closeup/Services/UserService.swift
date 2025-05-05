//
//  UserService.swift
//  closeup
//
//  Created by Weston Cadena on 5/4/25.
//


import Foundation
import Combine
import SwiftUI

// UserService - Handles user authentication and profile management
class UserService: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    
    // In a real app, you would implement actual authentication with Firebase/Auth0/etc.
    func login(email: String, password: String) -> AnyPublisher<User, Error> {
        // Simulate network delay
        return Future<User, Error> { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                // Simple validation
                if email.contains("@") && password.count >= 6 {
                    let user = User(name: "Alex Johnson", profileImage: "user1")
                    self.currentUser = user
                    self.isAuthenticated = true
                    promise(.success(user))
                } else {
                    promise(.failure(AuthError.invalidCredentials))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func logout() {
        currentUser = nil
        isAuthenticated = false
    }
    
    func createAccount(name: String, email: String, password: String) -> AnyPublisher<User, Error> {
        // Simulate network delay
        return Future<User, Error> { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                // Simple validation
                if name.count >= 2 && email.contains("@") && password.count >= 6 {
                    let user = User(name: name, profileImage: "default_avatar")
                    self.currentUser = user
                    self.isAuthenticated = true
                    promise(.success(user))
                } else {
                    promise(.failure(AuthError.invalidInput))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func updateProfile(name: String, bio: String, profileImage: UIImage?) -> AnyPublisher<User, Error> {
        // In a real app, you would upload the image to storage and update user profile
        return Future<User, Error> { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if var user = self.currentUser {
                    user.name = name
                    self.currentUser = user
                    promise(.success(user))
                } else {
                    promise(.failure(AuthError.notAuthenticated))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
