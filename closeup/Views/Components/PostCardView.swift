//
//  PostCardView.swift
//  closeup
//
//  Created by Weston Cadena on 5/4/25.
//

import SwiftUI

struct PostCardView: View {
    let post: Post
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Author info
            HStack {
                Image(post.author.profileImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.author.name)
                        .font(.headline)
                    
                    HStack {
                        Text(postTypeLabel(post.postType))
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(postTypeColor(post.postType))
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                        
                        Text(timeAgoText(from: post.timestamp))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Menu {
                    Button(action: {}) {
                        Label("Save", systemImage: "bookmark")
                    }
                    Button(action: {}) {
                        Label("Hide", systemImage: "eye.slash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.gray)
                        .padding(8)
                }
            }
            
            // Post content
            Text(post.content)
                .font(.body)
                .padding(.vertical, 4)
            
            // Images if any
            if !post.images.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(post.images, id: \.self) { imageName in
                            Image(imageName)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 200)
                                .frame(minWidth: 200, maxWidth: post.images.count == 1 ? .infinity : 300)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
            }
            
            // Engagement buttons
            HStack(spacing: 20) {
                Button(action: {}) {
                    HStack {
                        Image(systemName: "heart")
                        Text("\(post.likes)")
                    }
                    .foregroundColor(.secondary)
                }
                
                Button(action: {}) {
                    HStack {
                        Image(systemName: "bubble.right")
                        Text("\(post.comments.count)")
                    }
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    func postTypeLabel(_ type: PostType) -> String {
        switch type {
        case .dailyPrompt:
            return "Daily Prompt"
        case .weeklyReflection:
            return "Weekly Reflection"
        case .thought:
            return "Thought"
        }
    }
    
    func postTypeColor(_ type: PostType) -> Color {
        switch type {
        case .dailyPrompt:
            return .blue
        case .weeklyReflection:
            return .purple
        case .thought:
            return .green
        }
    }
    
    func timeAgoText(from date: Date) -> String {
        // Simple implementation - you might want to use a more sophisticated date formatter
        let minutes = Int(-date.timeIntervalSinceNow / 60)
        if minutes < 60 {
            return "\(minutes)m ago"
        } else if minutes < 1440 { // less than a day
            return "\(minutes / 60)h ago"
        } else {
            return "\(minutes / 1440)d ago"
        }
    }
}
