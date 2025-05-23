import Foundation

struct UserProfile: Codable, Identifiable, Hashable {
    let id: UUID // Maps from user_id
    let username: String
    let firstName: String
    let lastName: String
    let phoneNumber: String?
    let profilePicture: String? // URL to the profile picture
    let lastLogin: Date?
    let joinedAt: Date?
    // createdAt is not included as it's often handled by DB and might not be needed on client

    enum CodingKeys: String, CodingKey {
        case id = "user_id"
        case username
        case firstName = "first_name"
        case lastName = "last_name"
        case phoneNumber = "phone_number"
        case profilePicture = "profile_picture"
        case lastLogin = "last_login"
        case joinedAt = "joined_at"
    }
    
    // Computed property for full name for convenience
    var fullName: String {
        "\(firstName) \(lastName)"
    }
} 