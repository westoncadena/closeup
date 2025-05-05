//
//  ProfileView.swift
//  closeup
//
//  Created by Weston Cadena on 5/4/25.
//

import SwiftUI

struct ProfileView: View {
    @State private var user = User(name: "Alex Johnson", profileImage: "user1")
    @State private var userPosts: [Post] = []
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    // Profile Header
                    VStack(spacing: 16) {
                        Image(user.profileImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .shadow(radius: 3)
                        
                        Text(user.name)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Your personal storyboard: thoughts, memories, growth")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        HStack(spacing: 30) {
                            VStack {
                                Text("42")
                                    .font(.headline)
                                Text("Posts")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack {
                                Text("184")
                                    .font(.headline)
                                Text("Friends")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack {
                                Text("16")
                                    .font(.headline)
                                Text("Inner Circle")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        
                        Button(action: {
                            // Edit Profile
                        }) {
                            Text("Edit Profile")
                                .fontWeight(.medium)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(Color(.systemGray5))
                                .foregroundColor(.primary)
                                .cornerRadius(20)
                        }
                    }
                    .padding()
                    
                    // Post Filter Options
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            FilterButton(title: "All Posts", isActive: true)
                            FilterButton(title: "Thoughts", isActive: false)
                            FilterButton(title: "Daily Prompts", isActive: false)
                            FilterButton(title: "Weekly Reflections", isActive: false)
                        }
                        .padding(.horizontal)
                    }
                    
                    // User Posts
                    if userPosts.isEmpty {
                        VStack(spacing: 20) {
                            Spacer()
                            Image(systemName: "text.bubble")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            
                            Text("No posts yet")
                                .font(.title3)
                                .foregroundColor(.gray)
                            
                            Button(action: {
                                // Create first post
                            }) {
                                Text("Share Your First Thought")
                                    .fontWeight(.semibold)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            Spacer()
                        }
                        .frame(height: 300)
                    } else {
                        ForEach(userPosts) { post in
                            PostCardView(post: post)
                                .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Show settings
                    }) {
                        Image(systemName: "gear")
                    }
                }
            }
            .onAppear {
                // Load user posts
            }
        }
    }
}

struct FilterButton: View {
    let title: String
    let isActive: Bool
    
    var body: some View {
        Text(title)
            .fontWeight(isActive ? .semibold : .regular)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isActive ? Color.blue.opacity(0.1) : Color.clear)
            .foregroundColor(isActive ? .blue : .primary)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isActive ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
            )
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
