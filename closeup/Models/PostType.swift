//
//  PostType.swift
//  closeup
//
//  Created by Weston Cadena on 5/4/25.
//

import Foundation

enum PostType {
    case dailyPrompt
    case weeklyReflection
    case thought
}

enum PostAudience {
    case innerCircle
    case friends
    case everyone
}

enum AuthError: Error {
    case invalidCredentials
    case invalidInput
    case notAuthenticated
    case networkError
    case unknown
}
