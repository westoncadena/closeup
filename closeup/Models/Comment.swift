import Foundation

// Represents a comment on a post
struct Comment: Identifiable {
    let id: UUID
    let user: User // The author of the comment
    let text: String
    // You might expand this with createdAt: Date, likes: Int, etc.
} 