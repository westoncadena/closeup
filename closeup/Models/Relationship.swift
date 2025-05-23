import Foundation

struct Relationship: Codable, Identifiable, Hashable {
    let id: UUID
    var requesterId: UUID
    var addresseeId: UUID
    var relationshipType: RelationshipType?
    var status: RelationshipStatus?
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case requesterId = "requester_id"
        case addresseeId = "addressee_id"
        case relationshipType = "relationship_type"
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    enum RelationshipType: String, Codable, CaseIterable, Hashable {
        case friend
        case innerCircle = "inner_circle"
    }

    enum RelationshipStatus: String, Codable, CaseIterable, Hashable {
        case pending
        case accepted
        case declined
        case blocked
    }
}

// Extension for sample data or helper methods if needed in the future
extension Relationship {
    static func == (lhs: Relationship, rhs: Relationship) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
