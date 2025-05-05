//
//  PromptView.swift
//  closeup
//
//  Created by Weston Cadena on 5/4/25.
//

import SwiftUI

struct PromptView: View {
    @EnvironmentObject private var appState: AppState
    var onAnswerPrompt: ((String) -> Void)? = nil
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if appState.promptService.isLoading {
                        ProgressView("Loading prompts...")
                            .padding()
                    } else {
                        // Daily Prompt Card
                        PromptCard(
                            title: "Today's Question",
                            prompt: appState.promptService.dailyPrompt,
                            expiration: "Expires in 12 hours",
                            color: .blue,
                            buttonText: "Answer Now",
                            buttonAction: {
                                onAnswerPrompt?(appState.promptService.dailyPrompt)
                            }
                        )
                        
                        // Weekly Prompt Card
                        PromptCard(
                            title: "This Week's Reflection",
                            prompt: appState.promptService.weeklyPrompt,
                            expiration: "Expires in 3 days",
                            color: .purple,
                            buttonText: "Reflect Now",
                            buttonAction: {
                                onAnswerPrompt?(appState.promptService.weeklyPrompt)
                            }
                        )
                        
                        // Past Reflections
                        pastReflectionsSection
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Prompts")
            .onAppear {
                if appState.promptService.dailyPrompt.isEmpty {
                    appState.promptService.fetchPrompts()
                }
            }
            .refreshable {
                appState.promptService.fetchPrompts()
            }
        }
    }
    
    private var pastReflectionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Past Reflections")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(0..<5) { index in
                        PastPromptCard(
                            date: Date().addingTimeInterval(Double(-index) * 86400 * 7),
                            prompt: samplePastPrompts[index % samplePastPrompts.count],
                            didAnswer: index % 3 != 2
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.top, 20)
    }
    
    private let samplePastPrompts = [
        "What made you feel proud this week?",
        "What's a small win you had recently?",
        "What's something you learned this month?",
        "What are you grateful for today?",
        "What's something that challenged you recently?"
    ]
}


struct PromptView_Previews: PreviewProvider {
    static var previews: some View {
        PromptView()
            .environmentObject({
                let state = AppState()
                state.promptService.dailyPrompt = "What are you excited about today?"
                state.promptService.weeklyPrompt = "What was your high point this week?"
                return state
            }())
    }
}
