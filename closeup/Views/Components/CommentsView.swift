//
//  CommentsView.swift
//  closeup
//
//  Created by Weston Cadena on 5/4/25.
//

import SwiftUI

struct CommentsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @State private var commentText = ""
    @State private var isPostingComment = false
    let post: Post
    
    var body: some View {
        NavigationView {
            VStack {
                // Comments list
                if post.comments.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "bubble.right")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("No comments yet")
                            .font(.headline)
                        
                        Text("Be the first to comment")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(post.comments) { comment in
                            CommentCell(comment: comment)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
                
                // Comment input
                HStack {
                    TextField("Add a comment...", text: $commentText)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(20)
                    
                    Button(action: postComment) {
                        if isPostingComment {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    .disabled(commentText.isEmpty || isPostingComment)
                    .padding(.leading, 8)
                }
                .padding()
            }
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func postComment() {
        guard !commentText.isEmpty else { return }
        
        isPostingComment = true
        
        _ = appState.postService.addComment(to: post, content: commentText)
            .sink(
                receiveCompletion: { _ in
                    isPostingComment = false
                },
                receiveValue: { _ in
                    commentText = ""
                    isPostingComment = false
                }
            )
    }
}

struct CommentCell: View {
    let comment: Comment
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            CachedAsyncImage(urlString: comment.author.profileImage) { image in
                if let image = image {
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 36, height: 36)
                        .foregroundColor(.gray)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(comment.author.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text(timeAgoText(from: comment.timestamp))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(comment.content)
                    .font(.subheadline)
            }
        }
        .padding(.vertical, 6)
    }
    
    func timeAgoText(from date: Date) -> String {
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

