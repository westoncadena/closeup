import SwiftUI

// Dummy data model for a Post
// REMOVE THE EXISTING Post STRUCT DEFINITION HERE

// Sample posts - UPDATED to use your Post model
let samplePosts: [Post] = [
    Post(id: UUID(), userId: UUID(), content: "I am building this really cool app with Weston. I hope this becomes really helpful for people. The app will help people keep in touch more intentionally!", mediaUrl: nil, mediaType: nil, audience: "Friends", type: "Thoughts", promptId: nil, threadId: nil, createdAt: Date()),
    Post(id: UUID(), userId: UUID(), content: "Just got back from an amazing weekend trip to the mountains!", mediaUrl: "sample_mountain.jpg", mediaType: "image", audience: "Inner Circle", type: "Updates", promptId: nil, threadId: nil, createdAt: Date())
]

struct FeedView: View {
    @State private var selectedFeedType = 0
    let feedTypes = ["Friends", "Inner Circle"]

    // Sample data for posts - this would come from a ViewModel or service
    @State private var posts: [Post] = samplePosts

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
                }
            }
            .navigationTitle("closeup")
            .navigationBarTitleDisplayMode(.inline) // To keep title small like in the image
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Action for search
                        print("Search button tapped")
                    }) {
                        Image(systemName: "magnifyingglass")
                    }
                }
            }
        }
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
                    Text("User Name Placeholder").font(.headline)
                    Text(post.createdAt, style: .date).font(.caption).foregroundColor(.gray) // Display creation date
                }
                Spacer()
                Text(post.type) // Display post type (e.g., "Thoughts", "Updates")
                    .font(.caption)
                    .padding(5)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(5)
            }

            // Post Content
            // Text(post.title).font(.title3).bold() // Your model doesn't have a 'title'
            Text(post.content).font(.body)

            // Image Placeholders / Media Display
            if let mediaUrl = post.mediaUrl, let mediaType = post.mediaType, mediaType == "image" {
                // For now, just a placeholder if there's a mediaUrl
                // In a real app, you'd load the image from mediaUrl
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .aspectRatio(16/9, contentMode: .fit) // Common aspect ratio
                    .overlay(Image(systemName: "photo").foregroundColor(.white))
                    .frame(height: 200) // Example height
            }


            // Action Buttons (Like, Comment)
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
        .background(Color(UIColor.systemBackground)) // Adapts to light/dark mode
        .cornerRadius(10)
        .shadow(radius: 3)
    }
}

#Preview {
    FeedView()
} 