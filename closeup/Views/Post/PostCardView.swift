import SwiftUI

struct PostCardView: View {
    let post: Post
    @State private var authorProfile: UserProfile? // Store the whole profile
    private let userService = UserService() // Instance of UserService

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // User Info Header
            HStack {
                if let profilePicUrlString = authorProfile?.profilePicture, let url = URL(string: profilePicUrlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 30, height: 30)
                                .clipShape(Circle())
                        case .failure(_):
                            Image(systemName: "person.circle.fill") // Fallback on failure
                                .resizable()
                                .frame(width: 30, height: 30)
                                .clipShape(Circle())
                        case .empty:
                            Image(systemName: "person.circle.fill") // Placeholder while loading
                                .resizable()
                                .frame(width: 30, height: 30)
                                .clipShape(Circle())
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Image(systemName: "person.circle.fill") // Default placeholder
                        .resizable()
                        .frame(width: 30, height: 30)
                        .clipShape(Circle())
                }
                VStack(alignment: .leading) {
                    Text(authorProfile?.username ?? "Loading...").font(.headline) // Display username from profile
                    Text(post.createdAt, style: .date).font(.caption).foregroundColor(.gray)
                }
                Spacer()
                Text(post.type) // Display post type (e.g., "Thoughts", "Updates")
                    .font(.caption)
                    .padding(5)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(5)
            }

            // Display Title if available and not 'Untitled'
            if let title = post.title, title.lowercased() != "untitled" {
                Text(title)
                    .font(.title2) // Slightly larger font for title
                    .fontWeight(.semibold)
                    .lineLimit(2) // Limit title to 2 lines with truncation
            }

            HTMLTextView(htmlContent: post.content, baseFontSize: 18)
                .lineLimit(3) // Limit content to 3 lines with truncation

            // Updated to handle mediaUrls and mediaTypes arrays
            // This example displays the first image if available.
            if let mediaUrls = post.mediaUrls, !mediaUrls.isEmpty,
               let mediaTypes = post.mediaTypes, mediaTypes.count == mediaUrls.count,
               let firstUrlString = mediaUrls.first, let _ = URL(string: firstUrlString),
               let firstType = mediaTypes.first, firstType == "image" {

                if #available(iOS 15.0, *) {
                    AsyncImage(url: URL(string: firstUrlString)) {
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
        .onAppear {
            Task { // Explicitly create Task at the call site
                await fetchAuthorProfile()
            }
        }
    }

    // Modify fetchAuthorProfile to be an async function
    private func fetchAuthorProfile() async {
        guard let userId = post.userId else {
            // Potentially set a default state for authorProfile if needed
            // For now, it will remain nil and UI will show "Loading..." or default
            return
        }

        // No need for an inner Task { } block as the function is now async
        do {
            let fetchedProfile = try await userService.getUser(userId: userId)
            // Ensure state update is on the main actor
            await MainActor.run {
                self.authorProfile = fetchedProfile // Store the fetched profile
            }
        } catch {
            print("Error fetching user profile for post \(post.id): \(error)")
            // authorProfile remains nil, UI handles it
        }
    }
}

// MARK: - Preview
#Preview {
    // Mock UserProfiles for the preview
    let eunsooProfile = UserProfile(id: UUID(), username: "eunsoo_y", firstName: "Eunsoo", lastName: "Yeo", phoneNumber: nil, profilePicture: "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?ixlib=rb-1.2.1&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80", lastLogin: nil, joinedAt: Date()) // Added a sample profile picture URL

    let mockPost = Post(
        id: UUID(),
        userId: eunsooProfile.id, // Assigning a userId for the author for preview fetching logic
        content: "I am building this really cool app with Weston. I hope this becomes really helpful for people. The app will help people keep in touch more intentionally! This is a longer line of text to test truncation and see how it behaves when the content exceeds the available space.",
        mediaUrls: ["./closeup/Resources/Media/DSC_8698.jpg"],
        mediaTypes: ["image/jpeg"],
        audience: "friends",
        type: "thoughts",
        promptId: nil,
        threadId: nil,
        createdAt: Date(),
        title: "My Awesome Post Title That Might Be a Bit Long"
    )
    
    // PostView init now only takes post, initialMockLikes, initialMockComments
    PostCardView(post: mockPost)
}
