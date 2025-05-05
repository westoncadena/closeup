//
//  ContentView.swift
//  closeup
//
//  Created by Weston Cadena on 5/2/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedTab = 0
    @State private var showingCreatePost = false
    @State private var promptForPost: String? = nil
    
    var body: some View {
        TabView(selection: $selectedTab) {
            FeedView()
                .environmentObject(appState)
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Feed")
                }
                .tag(0)
            
            PromptView(onAnswerPrompt: { promptText in
                promptForPost = promptText
                showingCreatePost = true
            })
                .environmentObject(appState)
                .tabItem {
                    Image(systemName: "questionmark.circle")
                    Text("Prompts")
                }
                .tag(1)
            
            // Create Post Button (center tab)
            Color.clear
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text("Post")
                }
                .tag(2)
            
            ProfileView()
                .environmentObject(appState)
                .tabItem {
                    Image(systemName: "person")
                    Text("Profile")
                }
                .tag(3)
            
            NotificationsView()
                .environmentObject(appState)
                .tabItem {
                    Image(systemName: "bell")
                    Text("Notifications")
                }
                .tag(4)
        }
        .onChange(of: selectedTab) { newValue in
            if newValue == 2 {
                // Reset to previous tab and show create post sheet
                DispatchQueue.main.async {
                    selectedTab = 0
                    showingCreatePost = true
                }
            }
        }
        .sheet(isPresented: $showingCreatePost) {
            CreatePostView(promptText: promptForPost)
                .environmentObject(appState)
        }
        .onAppear {
            // Load initial data when app launches
            appState.postService.fetchFeedPosts()
            appState.promptService.fetchPrompts()
        }
    }
}
