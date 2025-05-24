import Foundation

// Represents thread templates
public struct Threads: Identifiable, Decodable {
    public let id: UUID
    public let user_id: String
    public let name: String
    public let description: String
    public let created_at: Date
    
    public init(id: UUID, user_id: String, name: String, description: String, created_at: Date) {
        self.id = id
        self.user_id = user_id
        self.name = name
        self.description = description
        self.created_at = created_at
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "thread_id"
        case user_id
        case name
        case description
        case created_at
    }
} 