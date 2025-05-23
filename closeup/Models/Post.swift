import Foundation

// Define the structure for a Post when fetching from Supabase
public struct Post: Decodable, Identifiable {
    public let id: UUID
    public let user_id: UUID?
    public let content: String
    public let media_url: String?
    public let media_type: String?
    public let audience: String
    public let post_type: String
    public let prompt_id: UUID?
    public let thread_id: UUID?
    public let created_at: Date

    public enum CodingKeys: String, CodingKey {
        case id = "post_id"
        case user_id
        case content
        case media_url
        case media_type
        case audience
        case post_type
        case prompt_id
        case thread_id
        case created_at
    }
}
