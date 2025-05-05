//
//  PromptService.swift
//  closeup
//
//  Created by Weston Cadena on 5/4/25.
//


import Foundation
import Combine
import SwiftUI

// PromptService - Handles daily and weekly prompts
class PromptService: ObservableObject {
    @Published var dailyPrompt: String = ""
    @Published var weeklyPrompt: String = ""
    @Published var isLoading = false
    
    private let dailyPrompts = [
        "What are you excited about today?",
        "What's something you're grateful for right now?",
        "What's one small thing that made you smile today?",
        "What's a challenge you're facing today?",
        "What's something you're looking forward to this week?"
    ]
    
    private let weeklyPrompts = [
        "What was your high point this week?",
        "What's something new you learned this week?",
        "What's a challenge you overcame this week?",
        "How did you grow or change this week?",
        "What's something you're proud of from this week?"
    ]
    
    func fetchPrompts() {
        isLoading = true
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // In a real app, these would come from a server
            self.dailyPrompt = self.dailyPrompts.randomElement() ?? "What are you excited about today?"
            self.weeklyPrompt = self.weeklyPrompts.randomElement() ?? "What was your high point this week?"
            self.isLoading = false
        }
    }
    
    func submitPromptResponse(content: String, promptType: PostType, audience: PostAudience, images: [UIImage] = []) -> AnyPublisher<Post, Error> {
        // Reuse post creation logic
        return PostService().createPost(content: content, postType: promptType, audience: audience, images: images)
    }
}
