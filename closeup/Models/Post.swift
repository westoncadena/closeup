import Foundation

// Define the structure for a Post when fetching from Supabase
public struct Post: Decodable, Identifiable {
    public let id: UUID // Maps from post_id
    public let userId: UUID? // Maps from user_id, which is nullable UUID
    public let content: String
    public let mediaUrls: [String]? // Changed from mediaUrl: String?
    public let mediaTypes: [String]? // Changed from mediaType: String?
    public let audience: String
    public let type: String // Maps from post_type
    public let promptId: UUID?
    public let threadId: UUID?
    public let createdAt: Date // Maps from created_at
    public let title: String? // Maps from title, which is nullable text

    public enum CodingKeys: String, CodingKey {
        case id = "post_id"
        case userId = "user_id"
        case content
        case mediaUrls = "media_urls" // Changed from media_url
        case mediaTypes = "media_types" // Changed from media_type
        case audience
        case type = "post_type"
        case promptId = "prompt_id"
        case threadId = "thread_id"
        case createdAt = "created_at"
        case title
    }

    public init(id: UUID, userId: UUID?, content: String, mediaUrls: [String]?, mediaTypes: [String]?, audience: String, type: String, promptId: UUID?, threadId: UUID?, createdAt: Date, title: String? = nil) {
        self.id = id
        self.userId = userId
        self.content = content
        self.mediaUrls = mediaUrls
        self.mediaTypes = mediaTypes
        self.audience = audience
        self.type = type
        self.promptId = promptId
        self.threadId = threadId
        self.createdAt = createdAt
        self.title = title
    }
}