//
//  HomeView.swift
//  closeup
//
//  Created by Weston Cadena on 5/9/25.
//

import SwiftUI

struct HomeView: View {
    @Binding var appUser: AppUser?
    @State private var userPosts: [Post] = [] // To store fetched posts
    @State private var isLoadingPosts: Bool = false
    @State private var postFetchError: String? = nil

    private let postService = PostService() // Instance of your service
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) { // Added alignment and spacing
            if let user = appUser {
                Text("User ID: \(user.uid)")
                    .font(.caption)
                Text("Email: \(user.email ?? "No Email")")
                    .font(.caption)
                
                Divider()

                if isLoadingPosts {
                    ProgressView("Loading post...")
                } else if let error = postFetchError {
                    Text("Error fetching post: \(error)")
                        .foregroundColor(.red)
                } else if let firstPost = userPosts.first { // Display the first post
                    VStack(alignment: .leading) {
                        Text("Your Latest Post:")
                            .font(.headline)
                        Text(firstPost.content)
                            .padding(.vertical, 5)
                        if let mediaUrlString = firstPost.mediaUrl, let mediaUrl = URL(string: mediaUrlString) {
                            // AsyncImage is available in iOS 15+
                            // For older versions, you might need a custom solution or a library like Kingfisher
                            AsyncImage(url: mediaUrl) {
                                $0.resizable()
                                  .aspectRatio(contentMode: .fit)
                                  .frame(maxHeight: 200)
                                  .cornerRadius(8)
                            } placeholder: {
                                ProgressView()
                                    .frame(height: 200)
                            }
                        }
                        Text("Posted on: \(firstPost.createdAt, style: .date) at \(firstPost.createdAt, style: .time)")
                            .font(.footnote)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                } else {
                    Text("You haven't made any posts yet, or no posts found.")
                }
                
                Spacer() // Pushes sign out button to the bottom

                Button{
                    Task {
                        do {
                            try await AuthManager.shared.signOut()
                            appUser = nil
                            userPosts = [] // Clear posts on sign out
                            postFetchError = nil
                        }
                        catch {
                            print("Error signing out: \(error)")
                        }
                    }
                } label: {
                    Text("Sign Out")
                        .foregroundColor(.red)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray5))
                        .cornerRadius(10)
                }
            }
        }
        .padding() // Add padding to the main VStack
        .onAppear {
            if let userId = appUser?.uid {
                fetchUserPosts(userId: userId)
            }
        }
        // Optional: Re-fetch if the user changes (e.g., logs in again)
        .onChange(of: appUser) { newUser in
            if let userId = newUser?.uid {
                fetchUserPosts(userId: userId)
            } else {
                // User logged out, clear posts
                userPosts = []
                postFetchError = nil
            }
        }
    }

    private func fetchUserPosts(userId: String) {
        isLoadingPosts = true
        postFetchError = nil
        Task {
            do {
                let posts = try await postService.fetchPosts(forUserId: userId)
                // Update on the main thread
                await MainActor.run {
                    self.userPosts = posts
                    self.isLoadingPosts = false
                }
            } catch {
                // Update on the main thread
                await MainActor.run {
                    self.postFetchError = error.localizedDescription
                    self.isLoadingPosts = false
                }
            }
        }
    }
}

#Preview {
    // Create a mock AppUser
    let mockUser = AppUser(uid: "12345-67890-ABCDEF-GHIJKL", email: "test@test.com") // Using a more UUID-like string for clarity
    // Create a mock Post, ensuring all required fields are present and types are correct
    let mockPost = Post(
        id: UUID(), 
        userId: UUID(), // Or nil if appropriate for your preview case. Ensure it's a UUID.
        content: "This is a sample post content from the preview. It should be engaging and demonstrate the UI nicely.", 
        mediaUrl: "https://placekitten.com/g/300/200", // Using a placeholder image service
        mediaType: "image/jpeg", 
        audience: "friends", 
        type: "thoughts", 
        promptId: nil, // Or a UUID() if you want to preview a post linked to a prompt
        threadId: nil, // Or a UUID() if you want to preview a post linked to a thread
        createdAt: Date()
    )
    
    // Create a HomeView and manually set the user for preview
    let homeView = HomeView(appUser: .constant(mockUser))
    // To see the post UI in preview directly without relying on fetch, you would typically pass mock data in.
    // One way is to initialize @State userPosts directly within the HomeView for preview purposes, 
    // or use a PreviewProvider struct for more complex scenarios.
    // For now, the fetch logic will run. If you want to guarantee the post is shown, 
    // you could temporarily modify HomeView to accept an optional initial Post array for its state.

    homeView
}
