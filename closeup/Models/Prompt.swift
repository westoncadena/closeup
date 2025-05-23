import Foundation

// Represents prompt templates
struct Prompt: Identifiable {
    let prompt_id: UUID
    let text: String // The prompt text
    let month_day: String // Assigned month and day of the year
} 