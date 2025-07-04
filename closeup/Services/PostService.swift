import Supabase
import Foundation
import UIKit // For UIImage
import Combine // Import Combine for ObservableObject

// Define the type of post
public enum PostType: String, Encodable {
    case journal = "journal"
    case prompt = "prompt"
    case thread = "thread"
}

// Define valid database audience values
private enum DatabaseAudience {
    static func convert(_ displayAudience: String) -> String {
        // Convert display-friendly audience values to database-accepted values
        switch displayAudience.lowercased() {
        case "personal": return "private"
        case "friends": return "friends"
        case "inner circle": return "circle"
        default: return "private" // Default to private for safety
        }
    }
}

// Define the structure for the post data to be sent to Supabase
private struct PostPayload: Encodable {
    let user_id: String
    let post_type: String
    let title: String
    let content: String
    let audience: String
    let media_urls: [String]?
    let media_types: [String]?
    let prompt_id: UUID?
    let thread_id: UUID?
    
    init(user_id: String, post_type: String, title: String, content: String, audience: String, media_urls: [String]?, media_types: [String]?, prompt_id: UUID?, thread_id: UUID?) {
        self.user_id = user_id
        self.post_type = post_type
        self.title = title
        self.content = content
        self.audience = DatabaseAudience.convert(audience)
        self.media_urls = media_urls
        self.media_types = media_types
        self.prompt_id = prompt_id
        self.thread_id = thread_id
    }
}

// Post struct has been moved to Models/Post.swift

public class PostService: ObservableObject {
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

    /// Creates a post, optionally uploading media first.
    /// - Parameters:
    ///   - userId: The ID of the user creating the post.
    ///   - postType: The type of the post (e.g., thoughts, prompt).
    ///   - title: The title of the post.
    ///   - content: The textual content of the post.
    ///   - audience: The audience for the post.
    ///   - media: An array of UIImages to be uploaded as media for the post.
    ///   - media_urls: An array of URLs to existing media for the post.
    ///   - prompt_id: The ID of the prompt associated with the post.
    /// - Throws: An error if the post creation or media upload fails.
    public func createPost(
        user_id: String,
        post_type: PostType,
        title: String,
        content: String,
        audience: String,
        media: [UIImage] = [],
        media_urls: [String]? = nil,
        prompt_id: UUID? = nil,
        thread_id: UUID? = nil
    ) async throws {
        var finalMediaUrls = media_urls ?? []
        var media_types: [String] = []

        // 1. If media exists, try to upload each image to Supabase Storage
        for imageToUpload in media {
            if let imageData = imageToUpload.jpegData(compressionQuality: 0.8) {
                let fileName = "\(UUID().uuidString).jpg"
                let storagePath = "posts_media/\(user_id)/\(fileName)"

                do {
                    print("Attempting to upload media to path: \(storagePath)")
                    // Upload the file
                    _ = try await client.storage
                        .from("media")
                        .upload(storagePath, data: imageData, options: FileOptions(contentType: "image/jpeg"))
                    
                    print("Media uploaded successfully.")

                    // Get the public URL for the uploaded file
                    let response = try client.storage
                        .from("media")
                        .getPublicURL(path: storagePath)
                    
                    finalMediaUrls.append(response.absoluteString)
                    media_types.append("image/jpeg")
                    print("Public media URL: \(response.absoluteString)")

                } catch {
                    print("Media upload failed: \(error)")
                    // Continue with next image
                    print("Continuing with next image")
                }
            }
        }

        // 2. Prepare the post payload
        let postPayload = PostPayload(
            user_id: user_id,
            post_type: post_type.rawValue,
            title: title,
            content: content,
            audience: DatabaseAudience.convert(audience),
            media_urls: finalMediaUrls.isEmpty ? nil : finalMediaUrls,
            media_types: media_types.isEmpty ? nil : media_types,
            prompt_id: prompt_id,
            thread_id: thread_id
        )

        // 3. Insert the post into the "posts" table
        do {
            print("Attempting to insert post: \(postPayload)")
            try await client
                .from("posts")
                .insert(postPayload)
                .execute()
            print("Post inserted successfully.")
        } catch {
            print("Database insert failed: \(error)")
            throw error
        }
    }

    /// Fetches posts from the Supabase database.
    /// - Returns: An array of `Post` objects.
    /// - Throws: An error if fetching or decoding fails.
    public func fetchPosts() async throws -> [Post] {
        do {
            print("Attempting to fetch posts...")
            let response: [Post] = try await client
                .from("posts")
                .select() // Selects all columns by default. Specify columns if needed: .select("id, content, user_id")
                // You can add ordering, e.g., .order("created_at", ascending: false)
                // You can add filtering, e.g., .eq("user_id", value: someUserId)
                // You can add pagination, e.g., .range(from: 0, to: 19) // fetches first 20 posts
                .execute()
                .value // Decodes the response into the specified type ([Post])
            
            print("Successfully fetched \(response.count) posts.")
            return response
        } catch {
            print("Failed to fetch posts: \(error)")
            throw error
        }
    }

    /// Fetches posts from the Supabase database for a specific user.
    /// - Parameter userId: The ID of the user whose posts are to be fetched.
    /// - Returns: An array of `Post` objects belonging to the user.
    /// - Throws: An error if fetching or decoding fails.
    func fetchPosts(forUserId userId: String) async throws -> [Post] {
        try await fetchPosts(forUserId: UUID(uuidString: userId) ?? UUID())
    }

    func fetchPosts(forUserId userId: UUID) async throws -> [Post] {
        do {
            print("Attempting to fetch posts for user ID: \(userId.uuidString)...")
            let response: [Post] = try await client
                .from("posts")
                .select() // Selects all columns
                .eq("user_id", value: userId.uuidString) // Filter by user_id
                .order("created_at", ascending: false) // Optional: order by creation date, newest first
                .execute()
                .value
            
            print("Successfully fetched \(response.count) posts for user ID: \(userId.uuidString).")
            return response
        } catch {
            print("Failed to fetch posts for user ID \(userId.uuidString): \(error)")
            throw error
        }
    }

    /// Fetches posts from the Supabase database for a list of specific user IDs.
    /// - Parameter userIds: An array of UUIDs of the users whose posts are to be fetched.
    /// - Returns: An array of `Post` objects belonging to the users.
    /// - Throws: An error if fetching or decoding fails.
    func fetchPosts(forUserIds userIds: [UUID]) async throws -> [Post] {
        guard !userIds.isEmpty else {
            print("No user IDs provided, returning empty posts array.")
            return []
        }

        do {
            let userIdStrings = userIds.map { $0.uuidString }
            print("Attempting to fetch posts for user IDs: \(userIdStrings.joined(separator: ", "))...")
            let response: [Post] = try await client
                .from("posts")
                .select() // Selects all columns
                .in("user_id", values: userIdStrings) // Filter by user_id in the list
                .order("created_at", ascending: false) // Order by creation date, newest first
                .execute()
                .value
            
            print("Successfully fetched \(response.count) posts for the provided user IDs.")
            return response
        } catch {
            print("Failed to fetch posts for user IDs: \(error)")
            throw error
        }
    }
}

// Example Usage (you would call this from your UI or another part of your app):
/*
func S_AMPLE_create_new_post() {
    let postService = PostService()
    let currentUserId = "user_example_123" // Replace with actual logged-in user ID

    // Example 1: Post with text only
    Task {
        do {
            try await postService.createPost(
                userId: currentUserId,
                type: .thoughts,
                content: "This is a new thought without media."
            )
            print("Successfully created text-only post!")
        } catch {
            print("Error creating text-only post: \(error)")
        }
    }

    // Example 2: Post with text and media
    // Assuming you have a UIImage instance, e.g., from an image picker
    // let sampleImage = UIImage(named: "yourSampleImage") // Replace with an actual image
    // if let image = sampleImage {
    //     Task {
    //         do {
    //             try await postService.createPost(
    //                 userId: currentUserId,
    //                 type: .prompt,
    //                 content: "Check out this cool image!",
    //                 media: image
    //             )
    //             print("Successfully created post with media!")
    //         } catch {
    //             print("Error creating post with media: \(error)")
    //         }
    //     }
    // } else {
    //     print("Sample image not found, skipping media post example.")
    // }
}

func S_AMPLE_fetch_all_posts() {
    let postService = PostService()
    Task {
        do {
            let posts = try await postService.fetchPosts()
            print("Fetched \(posts.count) posts:")
            for post in posts {
                print("- Post ID: \(post.id), Content: \(post.content), Created At: \(post.createdAt)")
            }
        } catch {
            print("Error fetching posts: \(error)")
        }
    }
}

func S_AMPLE_fetch_user_posts(userId: String) {
    let postService = PostService()
    Task {
        do {
            let posts = try await postService.fetchPosts(forUserId: userId)
            print("Fetched \(posts.count) posts for user \(userId):")
            for post in posts {
                print("- Post ID: \(post.id), Content: \(post.content)")
            }
        } catch {
            print("Error fetching user posts: \(error)")
        }
    }
}
*/
