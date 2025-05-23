import Supabase
import Foundation
import Combine

// Payload for creating a new relationship.
// We use this to ensure correct snake_case naming for Supabase table columns
// and to explicitly set initial values.
private struct RelationshipInsertPayload: Encodable {
    let requester_id: UUID
    let addressee_id: UUID
    let relationship_type: String
    let status: String
    // created_at and updated_at are handled by database defaults/triggers
}

// Payload for updating specific fields of a relationship.
// Optional fields allow for partial updates.
private struct RelationshipUpdatePayload: Encodable {
    var status: String? = nil
    var relationship_type: String? = nil
    // updated_at is handled by a database trigger ('update_updated_at_column')
}

class RelationshipService: ObservableObject {
    private let client: SupabaseClient
    private let tableName = "relationships"

    init() {
        guard let infoPlistPath = Bundle.main.path(forResource: "Info", ofType: "plist"),
              let infoPlistDict = NSDictionary(contentsOfFile: infoPlistPath),
              let urlString = infoPlistDict["SupabaseUrl"] as? String,
              let anonKey = infoPlistDict["SupabaseAnonKey"] as? String,
              let supabaseURL = URL(string: urlString) else {
            fatalError("Supabase URL or Anon Key not found or invalid in Info.plist. Please check your configuration.")
        }
        self.client = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: anonKey)
    }

    // MARK: - Relationship Actions

    /// Sends a friend request from one user to another.
    func sendFriendRequest(from requesterId: UUID, to addresseeId: UUID) async throws {
        let payload = RelationshipInsertPayload(
            requester_id: requesterId,
            addressee_id: addresseeId,
            relationship_type: Relationship.RelationshipType.friend.rawValue,
            status: Relationship.RelationshipStatus.pending.rawValue
        )
        try await client.from(tableName).insert(payload).execute()
    }

    /// Accepts a friend request.
    func acceptFriendRequest(relationshipId: UUID) async throws {
        let payload = RelationshipUpdatePayload(status: Relationship.RelationshipStatus.accepted.rawValue)
        try await client.from(tableName)
            .update(payload)
            .eq("id", value: relationshipId)
            .eq("status", value: Relationship.RelationshipStatus.pending.rawValue) // Ensure it's a pending request
            .execute()
    }

    /// Declines a friend request.
    func declineFriendRequest(relationshipId: UUID) async throws {
        let payload = RelationshipUpdatePayload(status: Relationship.RelationshipStatus.declined.rawValue)
        try await client.from(tableName)
            .update(payload)
            .eq("id", value: relationshipId)
            .eq("status", value: Relationship.RelationshipStatus.pending.rawValue) // Ensure it's a pending request
            .execute()
    }
    
    /// Blocks a user. This action is initiated by `blockerId` towards `blockedId`.
    /// If a relationship exists (in either direction), its status is set to 'blocked'.
    /// If no relationship exists, a new one is created with `blockerId` as requester and status 'blocked'.
    func blockUser(blockerId: UUID, blockedId: UUID) async throws {
        // 1. Check for an existing relationship between the two users (direction-agnostic)
        let existingRelationship: Relationship? = try await client.from(tableName)
            .select()
            .or("and(requester_id.eq.\(blockerId.uuidString),addressee_id.eq.\(blockedId.uuidString)),and(requester_id.eq.\(blockedId.uuidString),addressee_id.eq.\(blockerId.uuidString))")
            .limit(1)
            .single()
            .execute()
            .value

        if let relationship = existingRelationship {
            // 2. If found, update its status to 'blocked'
            let updatePayload = RelationshipUpdatePayload(status: Relationship.RelationshipStatus.blocked.rawValue)
            try await client.from(tableName)
                .update(updatePayload)
                .eq("id", value: relationship.id)
                .execute()
        } else {
            // 3. If not found, insert a new 'blocked' relationship with blockerId as the requester
            let insertPayload = RelationshipInsertPayload(
                requester_id: blockerId,
                addressee_id: blockedId,
                relationship_type: Relationship.RelationshipType.friend.rawValue, // Or null, type is less relevant for blocks
                status: Relationship.RelationshipStatus.blocked.rawValue
            )
            try await client.from(tableName).insert(insertPayload).execute()
        }
    }

    /// Removes a friend or cancels a request by deleting the relationship.
    func removeFriend(relationshipId: UUID) async throws {
        try await client.from(tableName)
            .delete()
            .eq("id", value: relationshipId)
            .execute()
    }

    // MARK: - Status Changes

    /// Upgrades an existing friendship to 'inner_circle'.
    func upgradeToInnerCircle(relationshipId: UUID) async throws {
        let payload = RelationshipUpdatePayload(relationship_type: Relationship.RelationshipType.innerCircle.rawValue)
        try await client.from(tableName)
            .update(payload)
            .eq("id", value: relationshipId)
            .eq("status", value: Relationship.RelationshipStatus.accepted.rawValue) // Ensure they are already accepted
            .execute()
    }

    /// Downgrades an 'inner_circle' relationship back to 'friend'.
    func downgradeFromInnerCircle(relationshipId: UUID) async throws {
        let payload = RelationshipUpdatePayload(relationship_type: Relationship.RelationshipType.friend.rawValue)
        try await client.from(tableName)
            .update(payload)
            .eq("id", value: relationshipId)
            .eq("status", value: Relationship.RelationshipStatus.accepted.rawValue)
            .eq("relationship_type", value: Relationship.RelationshipType.innerCircle.rawValue)
            .execute()
    }

    // MARK: - Fetching Relationships

    /// Fetches pending friend requests for a given user (user is the addressee).
    func loadPendingRequests(forUserId userId: UUID) async throws -> [Relationship] {
        try await client.from(tableName)
            .select()
            .eq("addressee_id", value: userId)
            .eq("status", value: Relationship.RelationshipStatus.pending.rawValue)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    /// Fetches sent friend requests by a given user (user is the requester).
    func loadSentRequests(byUserId userId: UUID) async throws -> [Relationship] {
        try await client.from(tableName)
            .select()
            .eq("requester_id", value: userId)
            .eq("status", value: Relationship.RelationshipStatus.pending.rawValue)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    /// Fetches all active friends for a given user.
    func loadFriends(forUserId userId: UUID) async throws -> [Relationship] {
        try await client.from(tableName)
            .select()
            .or("requester_id.eq.\(userId.uuidString),addressee_id.eq.\(userId.uuidString)")
            .eq("status", value: Relationship.RelationshipStatus.accepted.rawValue)
            .eq("relationship_type", value: Relationship.RelationshipType.friend.rawValue)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    /// Fetches all active inner circle members for a given user.
    func loadInnerCircle(forUserId userId: UUID) async throws -> [Relationship] {
        try await client.from(tableName)
            .select()
            .or("requester_id.eq.\(userId.uuidString),addressee_id.eq.\(userId.uuidString)")
            .eq("status", value: Relationship.RelationshipStatus.accepted.rawValue)
            .eq("relationship_type", value: Relationship.RelationshipType.innerCircle.rawValue)
            .order("created_at", ascending: false)
            .execute()
            .value
    }
    
    /// Fetches the relationship status between two specific users.
    /// Returns the relationship object if one exists, otherwise nil.
    func getRelationshipStatus(betweenUser userId1: UUID, andUser userId2: UUID) async throws -> Relationship? {
        let response: [Relationship] = try await client.from(tableName)
            .select()
            .or("and(requester_id.eq.\(userId1.uuidString),addressee_id.eq.\(userId2.uuidString)),and(requester_id.eq.\(userId2.uuidString),addressee_id.eq.\(userId1.uuidString))")
            .limit(1) // Expecting at most one relationship
            .execute()
            .value
        return response.first
    }

    /// Fetches relationships between a given user and a list of other specified users.
    /// This is useful for checking friendship status with multiple users at once.
    /// Only returns 'accepted' relationships.
    func relationshipsWithUsers(userId: UUID, otherUserIds: [UUID]) async throws -> [Relationship] {
        guard !otherUserIds.isEmpty else { return [] }
        
        let otherUserIdsString = otherUserIds.map { $0.uuidString }.joined(separator: ",")

        // Build the OR condition string carefully
        // (requester_id = userId AND addressee_id IN (otherUserIds)) OR (addressee_id = userId AND requester_id IN (otherUserIds))
        let orFilter = "and(requester_id.eq.\(userId.uuidString),addressee_id.in.(\(otherUserIdsString))),and(addressee_id.eq.\(userId.uuidString),requester_id.in.(\(otherUserIdsString)))"
        
        return try await client.from(tableName)
            .select()
            .or(orFilter)
            .eq("status", value: Relationship.RelationshipStatus.accepted.rawValue) // Only accepted relationships
            .execute()
            .value
    }
}
