import SwiftUI

// UserProfile is available from closeup/Models/UserProfile.swift
// Post model is available from closeup/Models/Post.swift

struct PostsBoardView: View {
    let userId: UUID // User ID to fetch posts for

    @StateObject private var postService = PostService()
    @State private var thoughtPosts: [Post] = []
    @State private var promptPosts: [Post] = []
    @State private var threadTopics: [Post] = []

    @State private var isLoading: Bool = true
    @State private var errorMessage: String? = nil

    init(userId: UUID) {
        self.userId = userId
        // Initializers for mock data are removed
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter
    }

    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView("Loading posts...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 50)
            } else if let errorMessage = errorMessage {
                VStack {
                    Text("Error: \(errorMessage)")
                        .foregroundColor(.red)
                    Button("Retry") {
                        Task {
                            await loadPostsData()
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                HStack(alignment: .top, spacing: 10) {
                    // Main content (Thoughts and Prompts)
                    VStack(alignment: .leading, spacing: 20) {
                        if !thoughtPosts.isEmpty {
                            thoughtsSection
                        }
                        if !promptPosts.isEmpty {
                            promptsSection
                        }
                        if thoughtPosts.isEmpty && promptPosts.isEmpty && threadTopics.isEmpty {
                            Text("No posts yet. Start sharing your thoughts!")
                                .foregroundColor(.gray)
                                .padding()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Side content (Threads)
                    if !threadTopics.isEmpty {
                        threadsSection
                            .frame(width: 120) // Fixed width for the side bar
                    }
                }
                .padding()
            }
        }
        .onAppear {
            Task {
                await loadPostsData()
            }
        }
    }

    private func loadPostsData() async {
        isLoading = true
        errorMessage = nil
        do {
            let allPosts = try await postService.fetchPosts(forUserId: userId)
            // Filter posts by type using string literals matching PostService.PostType raw values
            self.thoughtPosts = allPosts.filter { $0.type == "journal" } 
            self.promptPosts = allPosts.filter { $0.type == "prompt" }
            self.threadTopics = allPosts.filter { $0.type == "thread" }

        } catch {
            print("Error loading posts data in PostsBoardView: \(error)")
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private var thoughtsSection: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Thoughts")
                    .font(.title2)
                    .fontWeight(.bold)
                Image(systemName: "chevron.right")
                Spacer()
            }
            .padding(.bottom, 5)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                ForEach(thoughtPosts.prefix(4)) { post in
                    ThoughtItemView(post: post, dateFormatter: dateFormatter)
                }
            }
        }
    }

    private var promptsSection: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Prompts")
                    .font(.title2)
                    .fontWeight(.bold)
                Image(systemName: "chevron.right")
                Spacer()
            }
            .padding(.bottom, 5)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                ForEach(promptPosts.prefix(4)) { post in
                    PromptItemView(post: post, dateFormatter: dateFormatter)
                }
            }
        }
    }

    private var threadsSection: some View {
        VStack(alignment: .center, spacing: 15) {
            // The design shows "Standard" and a dropdown "Board"
            // This could be a placeholder for that section header later
            // For now, just the list of threads
            ForEach(threadTopics) { topicPost in
                ThreadItemView(post: topicPost)
            }
        }
        .padding(.top, 50) // Adjust to align with visual hierarchy if needed
    }
}

// MARK: - Helper Item Views

private struct ThoughtItemView: View {
    let post: Post
    let dateFormatter: DateFormatter

    var body: some View {
        VStack(alignment: .leading) {
            Text(post.title ?? "") // Using content as title. Provide default for nil.
                .font(.headline)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true) // Allow text to wrap
            
            Text(dateFormatter.string(from: post.createdAt))
                .font(.caption)
                .foregroundColor(.gray)
            
            // Image Placeholder
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .aspectRatio(1.0, contentMode: .fill) // Square aspect ratio
                .overlay(Image(systemName: "photo").foregroundColor(.white))
                .cornerRadius(8)
                .frame(minHeight: 80) // Ensure a minimum height
        }
        .padding(10)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .frame(maxWidth: .infinity) // Make items take available width in grid
    }
}

private struct PromptItemView: View {
    let post: Post
    let dateFormatter: DateFormatter

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(post.title ?? "") // Provide default for nil.
                .font(.subheadline)
                .lineLimit(3) // Allow more lines for prompt text
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer() // Pushes date to the bottom
            
            Text(dateFormatter.string(from: post.createdAt))
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(10)
        .frame(minHeight: 100, alignment: .topLeading) // Ensure a minimum height and align content
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .frame(maxWidth: .infinity)
    }
}

private struct ThreadItemView: View {
    let post: Post // Assuming content holds the thread name like "Reading"

    var body: some View {
        Text(post.content)
            .font(.subheadline)
            .fontWeight(.medium)
            .padding(15)
            .frame(width: 80, height: 80)
            .background(Color.blue.opacity(0.7))
            .foregroundColor(.white)
            .clipShape(Circle())
    }
}

#Preview {
    // PostsBoardView()
    // Preview will need a UUID. For simplicity, we can use a random one.
    // Or, ensure you have a mechanism to provide a specific one for testing if needed.
    PostsBoardView(userId: UUID())
} 