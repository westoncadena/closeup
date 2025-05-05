//
//  AppState.swift
//  closeup
//
//  Created by Weston Cadena on 5/4/25.
//

import SwiftUI

class AppState: ObservableObject {
    @Published var userService = UserService()
    @Published var postService = PostService()
    @Published var promptService = PromptService()
    
    init() {
        // Initialize app state
        setupDefaults()
    }
    
    private func setupDefaults() {
        // Load any stored preferences or settings
    }
}
