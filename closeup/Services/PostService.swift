//
//  PostService.swift
//  closeup
//
//  Created by Weston Cadena on 5/4/25.
//


import Foundation
import Combine
import SwiftUI

// PostService - Handles post creation, retrieval, and interaction
class PostService: ObservableObject {
    @Published var feedPosts: [Post] = []
    @Published var userPosts: [Post] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // In a real app, you would implement actual network requests
    func fetchFeedPosts() {
        isLoading = true
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Create sample posts
            let user1 = User(name: "Alex Johnson", profileImage: "user1")
            let user2 = User(name: "Taylor Swift", profileImage: "user2")
            let user3 = User(name: "James Smith", profileImage: "user3")
            
            self.feedPosts = [
                Post(author: user1,
                     postType: .dailyPrompt,
                     content: "What am I excited about today? Starting my new project that I've been planning for months. Finally taking the leap!",
                     timestamp: Date().addingTimeInterval(-3600),
                     images: ["project1", "project2"]),
                
                Post(author: user2,
                     postType: .weeklyReflection,
                     content: "This week's high: Finally finished that book I've been reading for months. The ending was absolutely worth it!",
                     timestamp: Date().addingTimeInterval(-86400),
                     images: ["book"]),
                
                Post(author: user3,
                     postType: .thought,
                     content: "Just had the most amazing conversation with a stranger on the train. It's these unexpected moments that remind me how connected we all are.",
                     timestamp: Date().addingTimeInterval(-172800)),
                
                Post(author: user1,
                     postType: .thought,
                     content: "Sometimes I wonder if the pressure to always seem productive is actually making us less productive. Taking breaks and reflecting has helped me so much lately.",
                     timestamp: Date().addingTimeInterval(-259200))
            ]
            
            self.isLoading = false
        }
    }
    
    func fetchUserPosts(for userId: UUID) {
        isLoading = true
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let user = User(name: "Alex Johnson", profileImage: "user1")
            
            self.userPosts = [
                Post(author: user,
                     postType: .dailyPrompt,
                     content: "What am I excited about today? Starting my new project that I've been planning for months. Finally taking the leap!",
                     timestamp: Date().addingTimeInterval(-3600),
                     images: ["project1", "project2"]),
                
                Post(author: user,
                     postType: .thought,
                     content: "Sometimes I wonder if the pressure to always seem productive is actually making us less productive. Taking breaks and reflecting has helped me so much lately.",
                     timestamp: Date().addingTimeInterval(-259200))
            ]
            
            self.isLoading = false
        }
    }
    
    func createPost(content: String, postType: PostType, audience: PostAudience, images: [UIImage] = []) -> AnyPublisher<Post, Error> {
        // In a real app, you would upload images to storage and create a post in the database
        return Future<Post, Error> { promise in
            if let currentUser = UserService().currentUser {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    let newPost = Post(
                        author: currentUser,
                        postType: postType,
                        content: content,
                        timestamp: Date(),
                        audience: audience
                    )
                    
                    // Add to local cache
                    self.feedPosts.insert(newPost, at: 0)
                    self.userPosts.insert(newPost, at: 0)
                    
                    promise(.success(newPost))
                }
            } else {
                promise(.failure(AuthError.notAuthenticated))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func likePost(_ post: Post) -> AnyPublisher<Post, Error> {
        return Future<Post, Error> { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                var updatedPost = post
                updatedPost.likes += 1
                
                // Update in local cache
                if let index = self.feedPosts.firstIndex(where: { $0.id == post.id }) {
                    self.feedPosts[index] = updatedPost
                }
                
                if let index = self.userPosts.firstIndex(where: { $0.id == post.id }) {
                    self.userPosts[index] = updatedPost
                }
                
                promise(.success(updatedPost))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func addComment(to post: Post, content: String) -> AnyPublisher<Post, Error> {
        return Future<Post, Error> { promise in
            if let currentUser = UserService().currentUser {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    let newComment = Comment(
                        author: currentUser,
                        content: content,
                        timestamp: Date()
                    )
                    
                    var updatedPost = post
                    updatedPost.comments.append(newComment)
                    
                    // Update in local cache
                    if let index = self.feedPosts.firstIndex(where: { $0.id == post.id }) {
                        self.feedPosts[index] = updatedPost
                    }
                    
                    if let index = self.userPosts.firstIndex(where: { $0.id == post.id }) {
                        self.userPosts[index] = updatedPost
                    }
                    
                    promise(.success(updatedPost))
                }
            } else {
                promise(.failure(AuthError.notAuthenticated))
            }
        }
        .eraseToAnyPublisher()
    }
}
