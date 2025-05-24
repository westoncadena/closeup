import SwiftUI

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
                    Text(post.createdAt, style: .date).font(.caption).foregroundColor(.gray) // Display creation date
                }
                Spacer()
                Text(post.type) // Display post type (e.g., "Thoughts", "Updates")
                    .font(.caption)
                    .padding(5)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(5)
            }

            Text(post.content).font(.body)

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
    }
}

// MARK: - Preview
#Preview {
    // Mock UserProfiles for the preview
    let eunsooProfile = UserProfile(id: UUID(), username: "eunsoo_y", firstName: "Eunsoo", lastName: "Yeo", phoneNumber: nil, profilePicture: nil, lastLogin: nil, joinedAt: Date())
    let westonProfile = UserProfile(id: UUID(), username: "weston_c", firstName: "Weston", lastName: "Cadena", phoneNumber: nil, profilePicture: nil, lastLogin: nil, joinedAt: Date())
    let mckenzieProfile = UserProfile(id: UUID(), username: "mckenzie_s", firstName: "Mckenzie", lastName: "Stanley", phoneNumber: nil, profilePicture: nil, lastLogin: nil, joinedAt: Date())

    // Mock Comments using UserProfile
    let comment1 = Comment(id: UUID(), user: westonProfile, text: "Cool stuff")
    let comment2 = Comment(id: UUID(), user: mckenzieProfile, text: "AMAZE!!!")
    let comment3 = Comment(id: UUID(), user: eunsooProfile, text: "Thanks for the feedback everyone! Really appreciate it.")

    let mockPost = Post(
        id: UUID(),
        userId: eunsooProfile.id, // Assigning a userId for the author for preview fetching logic
        content: "I am building this really cool app with Weston. I hope this becomes really helpful for people. The app will help people keep in touch more intentionally!",
        mediaUrls: ["./closeup/Resources/Media/DSC_8698.jpg"],
        mediaTypes: ["image/jpeg"],
        audience: "friends",
        type: "thoughts",
        promptId: nil,
        threadId: nil,
        createdAt: Date()
    )
    
    // PostView init now only takes post, initialMockLikes, initialMockComments
    PostCardView(post: mockPost)
}
