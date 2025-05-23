import SwiftUI

// UserProfile is available from closeup/Models/UserProfile.swift
// Post model is available from closeup/Models/Post.swift

struct PostsBoardView: View {
    // Mock Data
    let mockUser = UserProfile(
        id: UUID(),
        username: "eunsoo_y",
        firstName: "Eunsoo",
        lastName: "Yeo",
        phoneNumber: nil,
        profilePicture: nil, // Add a URL string if you have one
        lastLogin: Date(),
        joinedAt: Date()
    )

    var mockThoughtPosts: [Post]
    var mockPromptPosts: [Post]
    var mockThreadTopics: [Post]

    init() {
        let calendar = Calendar.current
        let now = Date()
        
        // Initialize mockThoughtPosts
        mockThoughtPosts = [
            Post(id: UUID(), userId: mockUser.id, content: "New App Development", mediaUrls: ["placeholder"], mediaTypes: ["image"], audience: "friends", type: "thoughts", promptId: nil, threadId: nil, createdAt: calendar.date(byAdding: .day, value: -1, to: now)!),
            Post(id: UUID(), userId: mockUser.id, content: "Vacation Planning", mediaUrls: ["placeholder"], mediaTypes: ["image"], audience: "friends", type: "thoughts", promptId: nil, threadId: nil, createdAt: calendar.date(byAdding: .day, value: -2, to: now)!),
            Post(id: UUID(), userId: mockUser.id, content: "Book Club Insights", mediaUrls: ["placeholder"], mediaTypes: ["image"], audience: "friends", type: "thoughts", promptId: nil, threadId: nil, createdAt: calendar.date(byAdding: .day, value: -3, to: now)!),
            Post(id: UUID(), userId: mockUser.id, content: "Gardening Project", mediaUrls: ["placeholder"], mediaTypes: ["image"], audience: "friends", type: "thoughts", promptId: nil, threadId: nil, createdAt: calendar.date(byAdding: .day, value: -4, to: now)!),
            Post(id: UUID(), userId: mockUser.id, content: "Hidden Gem Cafe", mediaUrls: ["placeholder"], mediaTypes: ["image"], audience: "friends", type: "thoughts", promptId: nil, threadId: nil, createdAt: calendar.date(byAdding: .day, value: -5, to: now)!)
        ]

        // Initialize mockPromptPosts
        mockPromptPosts = [
            Post(id: UUID(), userId: mockUser.id, content: "What's something small you're looking forward to?", mediaUrls: nil, mediaTypes: nil, audience: "friends", type: "prompt", promptId: UUID(), threadId: nil, createdAt: calendar.date(byAdding: .month, value: -1, to: now)!),
            Post(id: UUID(), userId: mockUser.id, content: "What made you smile today?", mediaUrls: nil, mediaTypes: nil, audience: "friends", type: "prompt", promptId: UUID(), threadId: nil, createdAt: calendar.date(byAdding: DateComponents(month: -1, day: -1), to: now)!),
            Post(id: UUID(), userId: mockUser.id, content: "A skill I want to learn this year is...", mediaUrls: nil, mediaTypes: nil, audience: "friends", type: "prompt", promptId: UUID(), threadId: nil, createdAt: calendar.date(byAdding: DateComponents(month: -1, day: -2), to: now)!),
            Post(id: UUID(), userId: mockUser.id, content: "My favorite way to unwind is...", mediaUrls: nil, mediaTypes: nil, audience: "friends", type: "prompt", promptId: UUID(), threadId: nil, createdAt: calendar.date(byAdding: DateComponents(month: -1, day: -3), to: now)!),
            Post(id: UUID(), userId: mockUser.id, content: "One thing I'm grateful for today:", mediaUrls: nil, mediaTypes: nil, audience: "friends", type: "prompt", promptId: UUID(), threadId: nil, createdAt: calendar.date(byAdding: DateComponents(month: -1, day: -4), to: now)!)
        ]

        // Initialize mockThreadTopics
        mockThreadTopics = [
            Post(id: UUID(), userId: mockUser.id, content: "Reading", mediaUrls: nil, mediaTypes: nil, audience: "friends", type: "thread_topic", promptId: nil, threadId: UUID(), createdAt: now),
            Post(id: UUID(), userId: mockUser.id, content: "Running", mediaUrls: nil, mediaTypes: nil, audience: "friends", type: "thread_topic", promptId: nil, threadId: UUID(), createdAt: now),
            Post(id: UUID(), userId: mockUser.id, content: "Climbing", mediaUrls: nil, mediaTypes: nil, audience: "friends", type: "thread_topic", promptId: nil, threadId: UUID(), createdAt: now),
            Post(id: UUID(), userId: mockUser.id, content: "Traveling", mediaUrls: nil, mediaTypes: nil, audience: "friends", type: "thread_topic", promptId: nil, threadId: UUID(), createdAt: now),
            Post(id: UUID(), userId: mockUser.id, content: "Cooking", mediaUrls: nil, mediaTypes: nil, audience: "friends", type: "thread_topic", promptId: nil, threadId: UUID(), createdAt: now),
            Post(id: UUID(), userId: mockUser.id, content: "Coding", mediaUrls: nil, mediaTypes: nil, audience: "friends", type: "thread_topic", promptId: nil, threadId: UUID(), createdAt: now)
        ]
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter
    }

    var body: some View {
        ScrollView {
            HStack(alignment: .top, spacing: 10) {
                // Main content (Thoughts and Prompts)
                VStack(alignment: .leading, spacing: 20) {
                    thoughtsSection
                    promptsSection
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Side content (Threads)
                threadsSection
                    .frame(width: 120) // Fixed width for the side bar
            }
            .padding()
        }
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
                ForEach(mockThoughtPosts.prefix(4)) { post in
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
                ForEach(mockPromptPosts.prefix(4)) { post in
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
            ForEach(mockThreadTopics) { topicPost in
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
            Text(post.content) // Using content as title
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
            Text(post.content)
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
    PostsBoardView()
} 