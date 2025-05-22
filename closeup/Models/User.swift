import Foundation

// Represents general user data for display (e.g., author of a post/comment)
struct User: Identifiable {
    let id: UUID
    let name: String
    let profileImageName: String // Example: system name for SFSymbol or an asset name
    // You might expand this later with profileImageURL: URL?, bio: String?, etc.
} 