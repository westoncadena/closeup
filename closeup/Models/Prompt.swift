import Foundation

// Represents prompt templates
public struct Prompt: Identifiable, Decodable {
    public let id: UUID
    public let text: String // The prompt text
    public let month_day: String // Assigned month and day of the year
    
    public init(prompt_id: UUID, text: String, month_day: String) {
        self.id = prompt_id
        self.text = text
        self.month_day = month_day
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "prompt_id"
        case text
        case month_day
    }
} 