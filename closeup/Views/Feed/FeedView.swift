import SwiftUI

// Dummy data model for a Post
// REMOVE THE EXISTING Post STRUCT DEFINITION HERE

// Sample posts - UPDATED to use your Post model
// let samplePosts: [Post] = [] // We will load this dynamically

struct FeedView: View {
    @State private var selectedFeedType = 0 // 0 for Friends, 1 for Inner Circle
    let feedTypes = ["Friends", "Inner Circle"]
    let appUser: AppUser

    // Services - In a larger app, consider injecting these via environment or a ViewModel
    private let relationshipService = RelationshipService()
    private let postService = PostService()

    // State for posts and loading
    @State private var posts: [Post] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Picker("Feed Type", selection: $selectedFeedType) {
                    ForEach(0..<feedTypes.count, id: \.self) { index in
                        Text(self.feedTypes[index]).tag(index)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.bottom, 10)

                if isLoading {
                    ProgressView("Loading feed...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = errorMessage {
                    VStack {
                        Text("Error loading feed:")
                        Text(errorMessage).font(.caption).foregroundColor(.red)
                        Button("Retry") {
                            Task {
                                await loadFeedPosts()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if posts.isEmpty {
                    Text("No posts to show in this feed yet.")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 15) {
                            ForEach(posts) { post in
                                NavigationLink(destination: PostDetailView(post: post)) {
                                    PostCardView(post: post)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("closeup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        print("Search button tapped")
                    }) {
                        Image(systemName: "magnifyingglass")
                    }
                }
            }
            .onAppear {
                Task {
                    await loadFeedPosts()
                }
            }
            .onChange(of: selectedFeedType) { _ in
                Task {
                    await loadFeedPosts()
                }
            }
        }
    }

    func loadFeedPosts() async {
        isLoading = true
        errorMessage = nil
        var userIdsToFetch: [UUID] = []

        guard let currentUserIdFromString = UUID(uuidString: appUser.uid) else {
            self.errorMessage = "Invalid user ID format."
            self.isLoading = false
            self.posts = []
            return
        }

        do {
            if selectedFeedType == 0 { // Friends
                print("Loading Friends feed for user: \(currentUserIdFromString)")
                let friendRelationships = try await relationshipService.loadFriends(forUserId: currentUserIdFromString)
                userIdsToFetch = friendRelationships.map { relationship in
                    // Return the ID of the other user in the relationship
                    return relationship.requesterId == currentUserIdFromString ? relationship.addresseeId : relationship.requesterId
                }
                print("Friend IDs: \(userIdsToFetch.map { $0.uuidString }.joined(separator: ", "))")
            } else { // Inner Circle
                print("Loading Inner Circle feed for user: \(currentUserIdFromString)")
                let innerCircleRelationships = try await relationshipService.loadInnerCircle(forUserId: currentUserIdFromString)
                userIdsToFetch = innerCircleRelationships.map { relationship in
                    return relationship.requesterId == currentUserIdFromString ? relationship.addresseeId : relationship.requesterId
                }
                print("Inner Circle IDs: \(userIdsToFetch.map { $0.uuidString }.joined(separator: ", "))")
            }

            if userIdsToFetch.isEmpty {
                print("No users found for the selected feed type. Feed will be empty.")
                self.posts = []
            } else {
                // Also include the current user's own posts in their feed if desired
                // userIdsToFetch.append(currentUserId) 
                self.posts = try await postService.fetchPosts(forUserIds: Array(Set(userIdsToFetch))) // Use Set to remove duplicates if any
                print("Successfully loaded \(posts.count) posts for the feed.")
            }

        } catch {
            print("Error loading feed posts: \(error)")
            self.errorMessage = error.localizedDescription
            self.posts = [] // Clear posts on error
        }
        isLoading = false
    }
}

// Renamed from PostView to PostCardView
struct PostCardView: View {
    let post: Post

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // User Info Header - This will need adjustment based on how User info is fetched/linked
            HStack {
                Image(systemName: "person.circle.fill") // Placeholder avatar
                    .resizable()
                    .frame(width: 30, height: 30)
                    .clipShape(Circle())
                VStack(alignment: .leading) {
                    // We'll need to fetch/display actual user name based on post.userId
                    Text("User: \((post.userId?.uuidString ?? "Unknown").prefix(8))").font(.headline) // Safely unwrapped userId
                    Text(post.createdAt ?? Date(), style: .date).font(.caption).foregroundColor(.gray) // Display creation date
                }
                Spacer()
                Text(post.type ?? "Post") // Display post type (e.g., "Thoughts", "Updates")
                    .font(.caption)
                    .padding(5)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(5)
            }

            Text(post.content).font(.body)

            if let mediaUrlString = post.mediaUrl, let _ = URL(string: mediaUrlString), post.mediaType == "image" {
                // AsyncImage to load image from URL (iOS 15+)
                // Fallback for older versions would be needed
                if #available(iOS 15.0, *) {
                    AsyncImage(url: URL(string: mediaUrlString)) {
                        $0.resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 200)
                            .cornerRadius(8)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .aspectRatio(16/9, contentMode: .fit)
                            .overlay(Image(systemName: "photo").foregroundColor(.white))
                            .frame(height: 200)
                    }
                } else {
                     Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .aspectRatio(16/9, contentMode: .fit)
                        .overlay(Text("Image preview not available").foregroundColor(.white))
                        .frame(height: 200)
                }
            }

            HStack {
                Button(action: { /* Like action */ }) {
                    Image(systemName: "hand.thumbsup")
                    Text("Like")
                }
                Spacer()
                Button(action: { /* Comment action */ }) {
                    Image(systemName: "bubble.left")
                    Text("Comment")
                }
            }
            .padding(.top, 5)
            .foregroundColor(.gray)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 3)
    }
}

struct PostDetailView: View { // Renamed from PostView to PostDetailView
    let post: Post
    var body: some View {
        Text("Detail view for post: \(post.content.prefix(50))")
            .navigationTitle("Post Details")
    }
}

#Preview {
    FeedView(appUser: AppUser(uid: UUID().uuidString, email: "preview@example.com"))
} 