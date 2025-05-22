import SwiftUI

// Mock data structures have been moved to the Models folder.

// Assuming a Post struct/class exists.
// Make sure this matches the Post struct you're using in HomeView or your PostService
// For now, adding mediaUrls as an array of strings for multiple images/videos.
/* REMOVING THIS DUPLICATE Post DEFINITION
struct Post: Identifiable {
    let id: UUID
    let author: User // Changed from userId to a User object for easier display
    let content: String
    let mediaUrls: [String]? // For carousel
    let mediaType: String? // e.g., "image/jpeg", "video/mp4"
    let likes: Int
    let comments: [Comment] // Embedding comments directly for this view for now
    let createdAt: Date
}
*/

struct PostView: View {
    // Environment variable to dismiss the view (for the back button)
    @Environment(\.dismiss) var dismiss
    
    let post: Post // This will now refer to the Post struct from PostService.swift
    @State private var showCommentsSheet: Bool = false
    
    // Mock data for UI elements not directly in PostService.Post for now
    @State private var displayAuthor: User // For preview and until User fetching is implemented
    @State private var displayLikes: Int = 0
    @State private var displayComments: [Comment] = []

    // Initializer to help with preview and bridge the gap
    init(post: Post, mockAuthor: User? = nil, mockLikes: Int = 0, mockComments: [Comment] = []) {
        self.post = post
        // For live data, you'd fetch User details based on post.userId
        // For preview, we pass it in.
        self._displayAuthor = State(initialValue: mockAuthor ?? User(id: UUID(), name: "Unknown User", profileImageName: "person.fill"))
        self._displayLikes = State(initialValue: mockLikes)
        self._displayComments = State(initialValue: mockComments)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // MARK: - Author Information
                HStack {
                    Image(systemName: displayAuthor.profileImageName) // Using displayAuthor
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        .padding(.trailing, 8)
                    Text(displayAuthor.name) // Using displayAuthor
                        .font(.headline)
                    Spacer()
                    Text(post.type.capitalized) // Using post.type from PostService.Post (e.g. "thoughts" -> "Thoughts")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)

                // MARK: - Post Content
                Text(post.content)
                    .font(.body)
                    .padding(.horizontal)

                // MARK: - Media Carousel (Adapted for single mediaUrl)
                if let mediaUrlString = post.mediaUrl, let url = URL(string: mediaUrlString) {
                    // For now, just showing the single image if available
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(height: 250)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: .infinity)
                                .frame(height: 250) // Adjust height as needed
                                .clipped()
                                .cornerRadius(8)
                        case .failure:
                            Image(systemName: "photo") // Placeholder for failed load
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 250)
                                .foregroundColor(.gray)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .padding(.horizontal)
                } else if post.mediaUrl != nil {
                    // Case where mediaUrl string is invalid but not nil
                    Image(systemName: "photo.on.rectangle.angled")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 250)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                        .overlay(Text("Invalid Media URL").foregroundColor(.red))
                }


                // MARK: - Likes and Comments Bar
                HStack(spacing: 20) {
                    Button(action: {
                        // TODO: Implement like action
                        print("Like button tapped")
                        // self.displayLikes += 1 // Example interaction
                    }) {
                        HStack {
                            Image(systemName: "hand.thumbsup")
                            Text("\(displayLikes)") // Using displayLikes
                        }
                    }
                    
                    Button(action: {
                        showCommentsSheet = true
                        print("Comment button tapped")
                    }) {
                        HStack {
                            Image(systemName: "message")
                            Text("\(displayComments.count)") // Using displayComments
                        }
                    }
                    Spacer() // Pushes like/comment to the left
                }
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.horizontal)
                .padding(.vertical, 8)

                Divider().padding(.horizontal)

                // MARK: - Comments Preview (as in the design)
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(displayComments.prefix(2)) { comment in // Show first 2 displayComments
                        CommentRow(comment: comment)
                    }
                }
                .padding(.horizontal)
                
                Spacer() // Pushes content to the top
            }
            // The sheet for showing all comments
            .sheet(isPresented: $showCommentsSheet) {
                // Ensure CommentsListView can handle the Comment struct defined in this file
                CommentsListView(comments: displayComments) // Using displayComments
            }
            .onAppear {
                // Here you would typically fetch the author details, likes, and comments
                // For example:
                // fetchUserDetails(userId: post.userId)
                // fetchLikesCount(postId: post.id)
                // fetchComments(postId: post.id)
                // For now, they are set via initializer or use default mock values.
            }
        }
    }
}

// MARK: - Comment Row View (Helper)
struct CommentRow: View {
    let comment: Comment

    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: comment.user.profileImageName) // Placeholder
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
                .clipShape(Circle())
            
            VStack(alignment: .leading) {
                Text(comment.user.name)
                    .font(.caption.bold())
                Text(comment.text)
                    .font(.caption)
            }
            Spacer()
            HStack(spacing: 15) {
                Button { /* Like comment action */ } label: { Image(systemName: "heart") }
                Button { /* Reply to comment action */ } label: { Image(systemName: "arrowshape.turn.up.left") }
            }
            .foregroundColor(.gray)
        }
    }
}

// MARK: - Comments List View (for the sheet)
struct CommentsListView: View {
    let comments: [Comment]
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView { // To have a title and dismiss button for the sheet
            List {
                ForEach(comments) { comment in
                    CommentRow(comment: comment) // Reusing the CommentRow
                }
            }
            .navigationTitle("Comments")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}


// MARK: - Preview
#Preview {
    // Mock Users
    let eunsoo = User(id: UUID(), name: "Eunsoo Yeo", profileImageName: "person.fill")
    let weston = User(id: UUID(), name: "Weston Cadena", profileImageName: "person.crop.circle.fill")
    let mckenzie = User(id: UUID(), name: "Mckenzie Stanley", profileImageName: "person.crop.square.fill")

    // Mock Comments
    let comment1 = Comment(id: UUID(), user: weston, text: "Cool stuff")
    let comment2 = Comment(id: UUID(), user: mckenzie, text: "AMAZE!!!")
    let comment3 = Comment(id: UUID(), user: eunsoo, text: "Thanks for the feedback everyone! Really appreciate it.")


    // Mock Post
    let mockPost = Post(
        id: UUID(),
        userId: UUID(), // This is from PostService.Post now
        content: "I am building this really cool app with Weston. I hope this becomes really helpful for people. The app will help people keep in touch more intentionally!",
        mediaUrl: "https://images.unsplash.com/photo-1506744038136-46273834b3fb?ixlib=rb-1.2.1&auto=format&fit=crop&w=750&q=80", // Single URL
        mediaType: "image/jpeg",
        audience: "friends", // Field from PostService.Post
        type: "thoughts",    // Field from PostService.Post
        promptId: nil,
        threadId: nil,
        createdAt: Date()
    )
    
    PostView(post: mockPost, mockAuthor: eunsoo, mockLikes: 10, mockComments: [comment1, comment2, comment3])
}


