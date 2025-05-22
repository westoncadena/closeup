//
//  HomeView.swift
//  closeup
//
//  Created by Weston Cadena on 5/9/25.
//

import SwiftUI

struct HomeView: View {
    @Binding var appUser: AppUser?
    @State private var userPosts: [Post] = []
    @State private var isLoadingPosts: Bool = false
    @State private var postFetchError: String? = nil

    private let postService = PostService()
    
    // Mock data for PostView navigation
    private let defaultMockUser = User(id: UUID(), name: "Loading...", profileImageName: "person.fill")
    private let defaultMockComments: [Comment] = []

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
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
                    } else if let firstPost = userPosts.first {
                        NavigationLink(destination: PostView(post: firstPost, 
                                                          mockAuthor: defaultMockUser, 
                                                          mockLikes: 0,
                                                          mockComments: defaultMockComments)) {
                            VStack(alignment: .leading) {
                                Text("Your Latest Post:")
                                    .font(.headline)
                                Text(firstPost.content)
                                    .padding(.vertical, 5)
                                if let mediaUrlString = firstPost.media_url, let mediaUrl = URL(string: mediaUrlString) {
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
                                Text("Posted on: \(firstPost.created_at, style: .date) at \(firstPost.created_at, style: .time)")
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .foregroundColor(Color.primary)
                        }
                    } else {
                        Text("You haven't made any posts yet, or no posts found.")
                    }
                    
                    Spacer()

                    Button {
                        Task {
                            do {
                                try await AuthManager.shared.signOut()
                                appUser = nil
                                userPosts = []
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
            .padding()
            .navigationTitle("Home")
            .onAppear {
                if let userId = appUser?.uid {
                    fetchUserPosts(user_id: userId)
                }
            }
            .onChange(of: appUser) { newUser in
                if let userId = newUser?.uid {
                    fetchUserPosts(user_id: userId)
                } else {
                    userPosts = []
                    postFetchError = nil
                }
            }
        }
    }

    private func fetchUserPosts(user_id: String) {
        isLoadingPosts = true
        postFetchError = nil
        Task {
            do {
                let posts = try await postService.fetchPosts(forUserId: user_id)
                await MainActor.run {
                    self.userPosts = posts
                    self.isLoadingPosts = false
                }
            } catch {
                await MainActor.run {
                    self.postFetchError = error.localizedDescription
                    self.isLoadingPosts = false
                }
            }
        }
    }
}

#Preview {
    let mockUser = AppUser(uid: "12345-67890-ABCDEF-GHIJKL", email: "test@test.com")
    
    let mockPost = Post(
        id: UUID(),
        user_id: UUID(),
        content: "This is a sample post content from the preview. It should be engaging and demonstrate the UI nicely.",
        media_url: "https://placekitten.com/g/300/200",
        media_type: "image/jpeg",
        audience: "friends",
        post_type: "journal",
        prompt_id: nil,
        thread_id: nil,
        created_at: Date()
    )
    
    return HomeView(appUser: .constant(mockUser))
}
