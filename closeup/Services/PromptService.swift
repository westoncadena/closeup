import Supabase
import Foundation

public class PromptService {
    private var client: SupabaseClient
    
    public init() {
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
    
    /// Fetches today's prompt from the Supabase database.
    /// - Returns: A `Prompt` object for today's date.
    /// - Throws: An error if fetching or decoding fails.
    public func fetchTodaysPrompt() async throws -> Prompt {
        // Get today's date in MM-dd format
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd"
        let todayString = dateFormatter.string(from: Date())
        
        do {
            print("Attempting to fetch prompt for date: \(todayString)...")
            let response: [Prompt] = try await client
                .from("prompts")
                .select()
                .eq("month_day", value: todayString)
                .execute()
                .value
            
            guard let prompt = response.first else {
                throw NSError(domain: "PromptService", code: 404, userInfo: [
                    NSLocalizedDescriptionKey: "No prompt found for today's date"
                ])
            }
            
            print("Successfully fetched prompt for \(todayString)")
            return prompt
        } catch {
            print("Failed to fetch prompt: \(error)")
            throw error
        }
    }
    
    /// Fetches a prompt for a specific date from the Supabase database.
    /// - Parameter date: The date to fetch the prompt for.
    /// - Returns: A `Prompt` object for the specified date.
    /// - Throws: An error if fetching or decoding fails.
    public func fetchPrompt(forDate date: Date) async throws -> Prompt {
        // Get date in MM-dd format
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd"
        let dateString = dateFormatter.string(from: date)
        
        do {
            print("Attempting to fetch prompt for date: \(dateString)...")
            let response: [Prompt] = try await client
                .from("prompts")
                .select()
                .eq("month_day", value: dateString)
                .execute()
                .value
            
            guard let prompt = response.first else {
                throw NSError(domain: "PromptService", code: 404, userInfo: [
                    NSLocalizedDescriptionKey: "No prompt found for date \(dateString)"
                ])
            }
            
            print("Successfully fetched prompt for \(dateString)")
            return prompt
        } catch {
            print("Failed to fetch prompt: \(error)")
            throw error
        }
    }
} 