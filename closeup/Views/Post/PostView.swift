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

// The local User and Comment structs will be adjusted or replaced.
// For consistency, it's better to use UserProfile directly.

// REMOVED Comment struct definition from here - it now uses Models/Comment.swift

struct PostView: View {
    @Environment(\.dismiss) var dismiss
    
    let post: Post
    @State private var showCommentsSheet: Bool = false
    
    // State for fetched data
    @State private var authorProfile: UserProfile? = nil
    @State private var isLoadingAuthor: Bool = false
    
    // For now, likes and comments will still use mock data structure but with UserProfile
    @State private var displayLikes: Int = 0
    @State private var displayComments: [Comment] = [] // This will be array of new Comment struct

    // Services
    private let userService = UserService()
    // private let commentService = CommentService() // Future
    // private let likeService = LikeService()    // Future

    // Updated initializer
    init(post: Post, initialMockLikes: Int = 0, initialMockComments: [Comment] = []) {
        self.post = post
        self._displayLikes = State(initialValue: initialMockLikes)
        self._displayComments = State(initialValue: initialMockComments)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // MARK: - Author Information
                if isLoadingAuthor {
                    HStack {
                        ProgressView()
                        Text("Loading author...")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Spacer()
                    }.padding(.horizontal)
                } else if let author = authorProfile {
                HStack {
                        if let profilePicUrlString = author.profilePicture, let url = URL(string: profilePicUrlString) {
                            AsyncImage(url: url) {
                                $0.resizable().aspectRatio(contentMode: .fill).frame(width: 40, height: 40).clipShape(Circle())
                            } placeholder: {
                                Image(systemName: "person.circle.fill").resizable().scaledToFit().frame(width: 40, height: 40).clipShape(Circle()).foregroundColor(.gray)
                            }
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable().scaledToFit().frame(width: 40, height: 40).clipShape(Circle()).foregroundColor(.gray)
                        }
                        Text(author.fullName)
                        .font(.headline)
                    Spacer()
                        Text(post.type.capitalized)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)
                } else {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .resizable().scaledToFit().frame(width: 40, height: 40).clipShape(Circle()).foregroundColor(.gray)
                        Text("Author not available")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Spacer()
                    }.padding(.horizontal)
                }

                // MARK: - Post Content
                Text(post.content)
                    .font(.body)
                    .padding(.horizontal)

                // MARK: - Media Carousel (Adapted for array of mediaUrls)
                // This example displays the first image if available.
                if let mediaUrls = post.mediaUrls, !mediaUrls.isEmpty,
                   let mediaTypes = post.mediaTypes, mediaTypes.count == mediaUrls.count,
                   let firstUrlString = mediaUrls.first, let url = URL(string: firstUrlString),
                   let firstType = mediaTypes.first, firstType.lowercased() == "image" {
                    
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
                                .frame(height: 250)
                                .clipped()
                                .cornerRadius(8)
                        case .failure:
                            Image(systemName: "photo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 250)
                                .foregroundColor(.gray)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .padding(.horizontal)
                } else if let mediaUrls = post.mediaUrls, !mediaUrls.isEmpty {
                    // Case where mediaUrls exist but might not be an image or URL is invalid for the first item
                    Image(systemName: "photo.on.rectangle.angled")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 250)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                        .overlay(Text("Media preview not available").foregroundColor(.white))
                }

                // MARK: - Likes and Comments Bar
                HStack(spacing: 20) {
                    Button(action: {
                        // TODO: Implement like action
                        print("Like button tapped")
                    }) {
                        HStack {
                            Image(systemName: "hand.thumbsup")
                            Text("\(displayLikes)")
                        }
                    }
                    
                    Button(action: {
                        showCommentsSheet = true
                        print("Comment button tapped")
                    }) {
                        HStack {
                            Image(systemName: "message")
                            Text("\(displayComments.count)")
                        }
                    }
                    Spacer()
                }
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.horizontal)
                .padding(.vertical, 8)

                Divider().padding(.horizontal)

                // MARK: - Comments Preview
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(displayComments.prefix(2)) { comment in
                        CommentRow(comment: comment)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .sheet(isPresented: $showCommentsSheet) {
                CommentsListView(comments: displayComments)
            }
            .onAppear {
                fetchPostDetails()
            }
        }
    }

    func fetchPostDetails() {
        print("PostView appeared. Post ID: \(post.id)")
        print("Media URLs: \(post.mediaUrls ?? [])")
        print("Media Types: \(post.mediaTypes ?? [])")

        // Fetch Author
        if let authorId = post.userId {
            isLoadingAuthor = true
            Task {
                do {
                    authorProfile = try await userService.getUser(userId: authorId)
                } catch {
                    print("Error fetching author profile: \(error)")
                    // authorProfile remains nil, UI will show placeholder
                }
                isLoadingAuthor = false
            }
        } else {
            print("Post does not have a userId to fetch author.")
            // authorProfile remains nil
        }

        // TODO: Fetch Likes (e.g., from a LikeService)
        // self.displayLikes = await likeService.fetchLikesCount(forPostId: post.id)
        
        // TODO: Fetch Comments (e.g., from a CommentService)
        // self.displayComments = await commentService.fetchComments(forPostId: post.id)
    }
}

// MARK: - Comment Row View
struct CommentRow: View {
    let comment: Comment

    var body: some View {
        HStack(alignment: .top) {
            if let profilePicUrlString = comment.user.profilePicture, let url = URL(string: profilePicUrlString) {
                AsyncImage(url: url) {
                    $0.resizable().aspectRatio(contentMode: .fill).frame(width: 30, height: 30).clipShape(Circle())
                } placeholder: {
                    Image(systemName: "person.circle.fill").resizable().scaledToFit().frame(width: 30, height: 30).clipShape(Circle()).foregroundColor(.gray)
                }
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable().scaledToFit().frame(width: 30, height: 30).clipShape(Circle()).foregroundColor(.gray)
            }
            
            VStack(alignment: .leading) {
                Text(comment.user.fullName) // Uses UserProfile.fullName
                    .font(.caption.bold())
                Text(comment.text)
                    .font(.caption)
            }
            Spacer()
            HStack(spacing: 15) {
                Button { /* Like comment action */ } label: { Image(systemName: "heart") }
                Button { /* Reply to comment action */ } label: { Image(systemName: "arrowshape.turn.up.left") }
            }.foregroundColor(.gray)
        }
    }
}

// MARK: - Comments List View
struct CommentsListView: View {
    let comments: [Comment]
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List {
                ForEach(comments) { comment in
                    CommentRow(comment: comment)
                }
            }
            .navigationTitle("Comments")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}

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
        mediaUrls: ["https://images.unsplash.com/photo-1506744038136-46273834b3fb?ixlib=rb-1.2.1&auto=format&fit=crop&w=750&q=80"],
        mediaTypes: ["image/jpeg"],
        audience: "friends",
        type: "thoughts",
        promptId: nil,
        threadId: nil,
        createdAt: Date()
    )
    
    // PostView init now only takes post, initialMockLikes, initialMockComments
    PostView(post: mockPost, initialMockLikes: 10, initialMockComments: [comment1, comment2, comment3])
}


