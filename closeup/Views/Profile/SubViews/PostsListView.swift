import SwiftUI

// Assuming Post and UserProfile models are defined elsewhere and accessible.
// UserProfile is available from closeup/Models/UserProfile.swift
// Post model is available from closeup/Models/Post.swift

struct PostsListView: View {
    // Mock Data
    let mockUser = UserProfile(
        id: UUID(),
        username: "eunsoo_y",
        firstName: "Eunsoo",
        lastName: "Yeo",
        phoneNumber: nil,
        profilePicture: "https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?ixlib=rb-1.2.1&auto=format&fit=crop&w=668&q=80", // Example profile pic
        lastLogin: Date(),
        joinedAt: Date()
    )

    var mockUserPosts: [Post]

    init() {
        let calendar = Calendar.current
        let now = Date()
        
        // Initialize mockUserPosts
        // These posts are by 'mockUser'
        mockUserPosts = [
            Post(id: UUID(), userId: mockUser.id, content: "Just enjoyed a wonderful hike in the mountains! The view was breathtaking. #nature #hiking", mediaUrls: ["https://images.unsplash.com/photo-1506744038136-46273834b3fb?ixlib=rb-1.2.1&auto=format&fit=crop&w=750&q=80"], mediaTypes: ["image"], audience: "friends", type: "thoughts", promptId: nil, threadId: nil, createdAt: calendar.date(byAdding: .day, value: -1, to: now)!),
            Post(id: UUID(), userId: mockUser.id, content: "What's a book that changed your perspective recently? Looking for recommendations!", mediaUrls: nil, mediaTypes: nil, audience: "public", type: "prompt", promptId: UUID(), threadId: nil, createdAt: calendar.date(byAdding: .day, value: -3, to: now)!),
            Post(id: UUID(), userId: mockUser.id, content: "Spent the afternoon coding and working on a new feature for my app. Making good progress!", mediaUrls: ["https://images.unsplash.com/photo-1517694712202-14dd9538aa97?ixlib=rb-1.2.1&auto=format&fit=crop&w=750&q=80"], mediaTypes: ["image"], audience: "friends", type: "thoughts", promptId: nil, threadId: nil, createdAt: calendar.date(byAdding: .day, value: -5, to: now)!),
            Post(id: UUID(), userId: mockUser.id, content: "Reflecting on the importance of small joys today. What's something simple that made you happy this week?", mediaUrls: nil, mediaTypes: nil, audience: "friends", type: "prompt", promptId: UUID(), threadId: nil, createdAt: calendar.date(byAdding: .weekOfYear, value: -1, to: now)!),
            Post(id: UUID(), userId: mockUser.id, content: "Experimenting with a new recipe tonight! Wish me luck. 🍝 #cooking #foodie", mediaUrls: [], mediaTypes: [], audience: "public", type: "thoughts", promptId: nil, threadId: nil, createdAt: calendar.date(byAdding: .day, value: -10, to: now)!)
        ]
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }

    var body: some View {
        NavigationView { // Added NavigationView for a title
            List {

                // Section for the posts
                Section(header: Text("Posts").font(.title2).fontWeight(.bold)) {
                    if mockUserPosts.isEmpty {
                        Text("No posts yet. Share your thoughts!")
                            .foregroundColor(.gray)
                            .padding()
                    } else {
                        ForEach(mockUserPosts) { post in
                            PostListItemView(post: post, user: mockUser, dateFormatter: dateFormatter)
                                .padding(.vertical, 8) // Add some padding between items
                        }
                    }
                }
            }
            .listStyle(PlainListStyle()) // Use PlainListStyle for a cleaner look
        }
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
            Text(post.content)
                .font(.body)
                .lineLimit(5) // Allow a few lines for content preview

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
    PostsListView()
} 
