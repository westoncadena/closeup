import Foundation
import Supabase
import Combine

class UserService: ObservableObject {
    private let client: SupabaseClient
    private let tableName = "users"

    init() {
        // Read Supabase credentials from Info.plist
        guard let infoPlistPath = Bundle.main.path(forResource: "Info", ofType: "plist"),
              let infoPlistDict = NSDictionary(contentsOfFile: infoPlistPath),
              let urlString = infoPlistDict["SupabaseUrl"] as? String,
              let anonKey = infoPlistDict["SupabaseAnonKey"] as? String,
              let supabaseURL = URL(string: urlString) else {
            fatalError("Supabase URL or Anon Key not found or invalid in Info.plist. Please check your configuration.")
        }
        
        self.client = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: anonKey)
    }

    /// Fetches a single user profile by their UUID.
    /// - Parameter userId: The UUID of the user to fetch.
    /// - Returns: A `UserProfile` object if found, otherwise nil.
    /// - Throws: An error if the fetch operation fails.
    func getUser(userId: UUID) async throws -> UserProfile? {
        do {
            let response: UserProfile = try await client
                .from(tableName)
                .select()
                .eq("user_id", value: userId.uuidString)
                .single() // Expects a single row, errors if not found or multiple
                .execute()
                .value
            return response
        } catch {
            // If the error is because no rows were found by single(), it might be a PostgrestError.
            // You can inspect the error type if you need to distinguish "not found" from other errors.
            print("Failed to fetch user \(userId.uuidString): \(error)")
            return nil // Return nil if user not found or other error
        }
    }

    /// Fetches all user profiles. 
    /// Warning: This can be inefficient for large user bases.
    /// Consider pagination or more specific search functions for production.
    /// - Returns: An array of `UserProfile` objects.
    /// - Throws: An error if the fetch operation fails.
    func getAllUsers() async throws -> [UserProfile] {
        do {
            let response: [UserProfile] = try await client
                .from(tableName)
                .select()
                .order("username") // Optional: order by username
                .execute()
                .value
            return response
        } catch {
            print("Failed to fetch all users: \(error)")
            throw error
        }
    }
    
    /// Searches for users based on a query string against username, first name, or last name.
    /// Uses case-insensitive partial matching (ilike).
    /// - Parameter query: The search string.
    /// - Returns: An array of matching `UserProfile` objects.
    /// - Throws: An error if the search operation fails.
    func searchUsers(query: String) async throws -> [UserProfile] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return [] // Return empty if query is empty or just whitespace
        }
        
        // The pattern for ilike should be e.g., "%searchText%"
        let searchPattern = "%\(query)%"
        
        do {
            let response: [UserProfile] = try await client
                .from(tableName)
                .select()
                .or("username.ilike.\(searchPattern),first_name.ilike.\(searchPattern),last_name.ilike.\(searchPattern)")
                .limit(20) // Good practice to limit search results
                .execute()
                .value
            return response
        } catch {
            print("Failed to search users with query \"\(query)\": \(error)")
            throw error
        }
    }
    
    // Potential future functions:
    // - func updateUserProfile(profile: UserProfile) async throws -> UserProfile
    // - func createUserProfile(userId: UUID, username: String, firstName: String, lastName: String) async throws -> UserProfile 
    //   (Note: User creation usually happens via Auth, then a trigger creates the public.users row)
}
