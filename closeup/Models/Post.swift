import Foundation

// Define the structure for a Post when fetching from Supabase
struct Post: Decodable, Identifiable {
    let id: UUID
    let user_id: UUID?
    let content: String
    let media_url: String?
    let media_type: String?
    let audience: String
    let post_type: String
    let prompt_id: UUID?
    let thread_id: UUID?
    let created_at: Date

    enum CodingKeys: String, CodingKey {
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
