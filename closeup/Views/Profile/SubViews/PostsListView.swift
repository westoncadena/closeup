import SwiftUI

// Assuming Post and UserProfile models are defined elsewhere and accessible.
// UserProfile is available from closeup/Models/UserProfile.swift
// Post model is available from closeup/Models/Post.swift

struct PostsListView: View {
    // User for whom to display posts
    let user: UserProfile

    // Services
    private let postService = PostService()

    // State for posts, loading, and error handling
    @State private var posts: [Post] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        VStack(spacing: 0) { // Use VStack to structure content similar to FeedView
            if isLoading && posts.isEmpty { // Show loading only if posts are not yet loaded
                ProgressView("Loading posts...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = errorMessage {
                VStack {
                    Text("Error loading posts:")
                        .foregroundColor(.red)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                    Button("Retry") {
                        Task {
                            await loadUserPosts()
                        }
                    }
                    .padding(.top, 5)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if posts.isEmpty {
                Text("No posts yet. Share your thoughts!")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 15) {
                        ForEach(posts) { post in
                            NavigationLink(destination: PostView(post: post)) {
                                PostCardView(post: post)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top) // Add some top padding for the scroll content
                }
                .refreshable {
                    await loadUserPosts()
                }
            }
        }
        .onAppear {
            // Prevent multiple loads if already loading and posts are present (e.g., from refresh)
            if posts.isEmpty { // Only load if posts are initially empty
                Task {
                    await loadUserPosts()
                }
            }
        }
        // .navigationTitle remains handled by the parent view (e.g., ProfileView)
    }

    // Function to load posts for the current user
    func loadUserPosts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Fetch posts for the specific user's ID
            // Assuming user.id is the correct UUID to fetch posts for.
            // PostService().fetchPosts(forUserId: UUID) is assumed to exist
            // If PostService().fetchPosts expects an array of UUIDs, adjust accordingly.
            // For now, assuming a function like `fetchPosts(forUserId: UUID)` or similar is available
            // or that `fetchPosts(forUserIds: [UUID])` can be used with a single user ID.
            let userSpecificPosts = try await postService.fetchPosts(forUserIds: [user.id])
            self.posts = userSpecificPosts.sorted(by: { $0.createdAt > $1.createdAt }) // Sort by most recent
            print("Successfully loaded \(posts.count) posts for user: \(user.username)")
        } catch {
            print("Error loading posts for user \(user.username): \(error)")
            self.errorMessage = error.localizedDescription
            // self.posts = [] // Keep existing posts on error during refresh, or clear if desired
        }
        isLoading = false
    }
}

// PostListItemView has been removed as PostCardView is used directly.

#Preview {
    let mockPreviewUser = UserProfile(
        id: UUID(),
        username: "preview_user",
        firstName: "Preview",
        lastName: "User",
        phoneNumber: nil,
        profilePicture: "https://example.com/profile.jpg", // Added for PostCardView
        lastLogin: Date(),
        joinedAt: Date()
    )
    // Wrap in NavigationView for previewing navigation if PostListView might be used in such a context
    // or if PostCardView relies on it for some reason (though it shouldn't directly)
    NavigationView {
        PostsListView(user: mockPreviewUser)
            .navigationTitle(mockPreviewUser.username) // Example title for preview context
    }
} 
