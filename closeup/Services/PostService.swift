import Supabase
import Foundation
import UIKit // For UIImage

// Define the type of post
enum PostType: String, Encodable {
    case thoughts = "Thoughts"
    case prompt = "Prompt"
    case thread = "Thread"
}

// Define the structure for the post data to be sent to Supabase
struct PostPayload: Encodable {
    let user_id: String
    let type: String
    let content: String
    let media_url: String?
    // Supabase typically handles created_at automatically if the column is configured with a default value like now()
    // let created_at: String // You might not need to send this explicitly
}

class PostService {
    // Removed hardcoded URL and Key string properties

    private var client: SupabaseClient

    init() {
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
    ///   - type: The type of the post (e.g., thoughts, prompt).
    ///   - content: The textual content of the post.
    ///   - media: An optional UIImage to be uploaded as media for the post.
    /// - Throws: An error if the post creation or media upload fails.
    func createPost(
        userId: String,
        type: PostType,
        content: String,
        media: UIImage? = nil
    ) async throws {
        var mediaURL: String? = nil

        // 1. If media exists, upload it to Supabase Storage first
        if let imageToUpload = media, let imageData = imageToUpload.jpegData(compressionQuality: 0.8) {
            let fileName = "\(UUID().uuidString).jpg"
            // Define a path like "posts_media/{userId}/{fileName}"
            // Using a "posts_media" top-level folder, then user-specific subfolders.
            let storagePath = "posts_media/\(userId)/\(fileName)"

            do {
                print("Attempting to upload media to path: \(storagePath)")
                // Upload the file
                _ = try await client.storage
                    .from("media") // Assuming your bucket is named "media"
                    .upload(storagePath, data: imageData, options: FileOptions(contentType: "image/jpeg"))
                
                print("Media uploaded successfully.")

                // Get the public URL for the uploaded file
                // Note: Ensure your bucket ("media") and the files within are configured for public access
                // or use signed URLs if you need more restricted access.
                let response = try client.storage
                    .from("media")
                    .getPublicURL(path: storagePath)
                
                mediaURL = response.absoluteString
                print("Public media URL: \(mediaURL ?? "Not available")")

            } catch {
                print("Media upload failed: \(error)")
                // You might want to decide if a failed media upload should prevent post creation
                // or if the post should be created without media.
                // For this example, we'll throw the error.
                throw error
            }
        }

        // 2. Prepare the post payload
        let postPayload = PostPayload(
            user_id: userId,
            type: type.rawValue,
            content: content,
            media_url: mediaURL
            // created_at is often handled by the database (e.g., default value now())
        )

        // 3. Insert the post into the "posts" table
        do {
            print("Attempting to insert post: \(postPayload)")
            try await client
                .from("posts") // Assuming your table is named "posts"
                .insert(postPayload)
                .execute() // Essential for triggering the insert operation
            print("Post inserted successfully.")
        } catch {
            print("Database insert failed: \(error)")
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
*/
