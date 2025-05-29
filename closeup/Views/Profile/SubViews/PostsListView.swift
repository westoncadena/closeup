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
    
    // Date Formatter
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }

    var body: some View {
        // Removed NavigationView as it's usually part of the parent view in a profile context
        List {
            // Section for the posts
            Section(header: Text("Posts").font(.title2).fontWeight(.bold)) {
                if isLoading {
                    ProgressView("Loading posts...")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else if let errorMessage = errorMessage {
                    VStack(alignment: .center) {
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
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                } else if posts.isEmpty {
                    Text("No posts yet. Share your thoughts!")
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    ForEach(posts) { post in // Changed mockUserPosts to posts
                        // Pass the specific user object to PostListItemView
                        PostListItemView(post: post, user: user, dateFormatter: dateFormatter)
                            .padding(.vertical, 8)
                    }
                }
            }
        }
        .listStyle(PlainListStyle())
        .onAppear {
            Task {
                await loadUserPosts()
            }
        }
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
            print("Successfully loaded \\(posts.count) posts for user: \\(user.username)")
        } catch {
            print("Error loading posts for user \\(user.username): \\(error)")
            self.errorMessage = error.localizedDescription
            self.posts = [] // Clear posts on error
        }
        isLoading = false
    }
}

// MARK: - Post List Item View (Helper)
// This view is inspired by elements from PostView but is more compact for a list.
private struct PostListItemView: View {
    let post: Post
    let user: UserProfile // Pass the user for context, though in this list it's always the mockUser
    let dateFormatter: DateFormatter

    // Mock interaction data for display purposes
    @State private var displayLikes: Int = Int.random(in: 0...200)
    @State private var displayCommentsCount: Int = Int.random(in: 0...50)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Post Content
            HTMLTextView(htmlContent: post.content)
                .font(.body)
                .lineLimit(5)

            // Media Preview (First image if available)
            if let mediaUrls = post.mediaUrls, !mediaUrls.isEmpty,
               let firstUrlString = mediaUrls.first, let url = URL(string: firstUrlString),
               let mediaTypes = post.mediaTypes, mediaTypes.count == mediaUrls.count,
               let firstType = mediaTypes.first, firstType.lowercased().hasPrefix("image") {
                
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView().frame(height: 150)
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                             .frame(maxHeight: 200) // Limit height for list view
                             .clipped().cornerRadius(8)
                    case .failure:
                        Image(systemName: "photo.fill")
                            .resizable().aspectRatio(contentMode: .fit)
                            .frame(height: 150).foregroundColor(.gray)
                    @unknown default:
                        EmptyView()
                    }
                }
            }

            // Date and Stats
            HStack {
                Text(dateFormatter.string(from: post.createdAt))
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "hand.thumbsup")
                    Text("\(displayLikes)")
                }
                .font(.caption)
                .foregroundColor(.gray)
                
                HStack(spacing: 4) {
                    Image(systemName: "message")
                    Text("\(displayCommentsCount)")
                }
                .font(.caption)
                .foregroundColor(.gray)
            }
            .padding(.top, 4)
        }
        // Consider adding a NavigationLink here if rows should be tappable to a full PostView
        // .background(NavigationLink("", destination: PostView(post: post)).opacity(0))
    }
}

#Preview {
    // Create a mock UserProfile for the preview
    let mockPreviewUser = UserProfile(
        id: UUID(),
        username: "preview_user",
        firstName: "Preview",
        lastName: "User",
        phoneNumber: nil,
        profilePicture: nil,
        lastLogin: Date(),
        joinedAt: Date()
    )
    PostsListView(user: mockPreviewUser)
} 
