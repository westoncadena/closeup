import Foundation

// Define the structure for a Post when fetching from Supabase
struct Post: Decodable, Identifiable {
    let id: UUID // Maps from post_id
    let userId: UUID? // Maps from user_id, which is nullable UUID
    let content: String
    let mediaUrl: String?
    let mediaType: String?
    let audience: String
    let type: String // Maps from post_type
    let promptId: UUID?
    let threadId: UUID?
    let createdAt: Date // Maps from created_at

    enum CodingKeys: String, CodingKey {
        case id = "post_id"
        case userId = "user_id"
        case content
        case mediaUrl = "media_url"
        case mediaType = "media_type"
        case audience
        case type = "post_type"
        case promptId = "prompt_id"
        case threadId = "thread_id"
        case createdAt = "created_at"
    }
}
