import Foundation

// Represents a comment on a post
struct Comment: Identifiable, Hashable {
    let id: UUID
    let user: UserProfile // Changed from User to UserProfile
    let text: String
    // You might expand this with createdAt: Date, likes: Int, etc.
    // To be decoded from a database, you'd add Codable and CodingKeys if names differ.
} 