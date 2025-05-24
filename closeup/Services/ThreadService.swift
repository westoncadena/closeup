import Supabase
import Foundation

public class ThreadService {
    private let client: SupabaseClient
    
    public static let shared = ThreadService()
    
    private init() {
        // Read Supabase credentials from Info.plist
        guard let infoPlistPath = Bundle.main.path(forResource: "Info", ofType: "plist"),
              let infoPlistDict = NSDictionary(contentsOfFile: infoPlistPath),
              let urlString = infoPlistDict["SupabaseUrl"] as? String,
              let anonKey = infoPlistDict["SupabaseAnonKey"] as? String,
              let supabaseURL = URL(string: urlString) else {
            fatalError("Supabase URL or Anon Key not found or invalid in Info.plist. Please check your configuration.")
        }
        
        // Initialize the Supabase client with values from Info.plist
        self.client = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: anonKey)
    }
    
    public init(client: SupabaseClient) {
        self.client = client
    }
    
    /// Creates a new thread
    /// - Parameters:
    ///   - user_id: The ID of the user creating the thread (string format from auth)
    ///   - name: The name of the thread
    ///   - description: A description of what the thread is about
    /// - Returns: The created Threads object
    /// - Throws: An error if the thread creation fails
    public func createThread(user_id: String, name: String, description: String) async throws -> Threads {
        let response: [Threads] = try await client
            .from("threads")
            .insert(["user_id": user_id, "name": name, "description": description])
            .select()
            .execute()
            .value
        
        guard let thread = response.first else {
            throw NSError(domain: "ThreadService", code: 500, userInfo: [
                NSLocalizedDescriptionKey: "Failed to create thread"
            ])
        }
        
        return thread
    }
    
    /// Fetches all threads for a user
    /// - Parameter user_id: The ID of the user whose threads to fetch
    /// - Returns: An array of Threads objects
    /// - Throws: An error if the fetch fails
    public func fetchThreads(forUserId user_id: String) async throws -> [Threads] {
        let response: [Threads] = try await client
            .from("threads")
            .select()
            .eq("user_id", value: user_id)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return response
    }
    
    /// Fetches a specific thread by ID
    /// - Parameter thread_id: The ID of the thread to fetch
    /// - Returns: The Threads object
    /// - Throws: An error if the thread is not found
    public func fetchThread(byId thread_id: UUID) async throws -> Threads {
        let response: [Threads] = try await client
            .from("threads")
            .select()
            .eq("thread_id", value: thread_id)
            .execute()
            .value
        
        guard let thread = response.first else {
            throw NSError(domain: "ThreadService", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "Thread not found"
            ])
        }
        
        return thread
    }
    
    /// Updates a thread's details
    /// - Parameters:
    ///   - thread_id: The ID of the thread to update
    ///   - name: The new name for the thread (optional)
    ///   - description: The new description for the thread (optional)
    /// - Returns: The updated Threads object
    /// - Throws: An error if the thread is not found or the update fails
    public func updateThread(thread_id: UUID, name: String? = nil, description: String? = nil) async throws -> Threads {
        let updates = ThreadUpdatePayload(
            name: name,
            description: description
        )
        
        let response: [Threads] = try await client
            .from("threads")
            .update(updates)
            .eq("thread_id", value: thread_id)
            .select()
            .execute()
            .value
        
        guard let thread = response.first else {
            throw NSError(domain: "ThreadService", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "Thread not found"
            ])
        }
        
        return thread
    }
    
    /// Deletes a thread
    /// - Parameter thread_id: The ID of the thread to delete
    /// - Throws: An error if the deletion fails
    public func deleteThread(thread_id: UUID) async throws {
        try await client
            .from("threads")
            .delete()
            .eq("thread_id", value: thread_id)
            .execute()
    }
    
    private struct ThreadPayload: Encodable {
        let user_id: UUID
        let name: String
        let description: String
    }
    
    private struct ThreadUpdatePayload: Encodable {
        let name: String?
        let description: String?
    }
} 