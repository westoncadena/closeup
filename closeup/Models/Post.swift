//
//  Post.swift
//  closeup
//
//  Created by Weston Cadena on 5/4/25.
//

import Foundation

struct Post: Identifiable {
    let id = UUID()
    var author: User
    var postType: PostType
    var content: String
    var timestamp: Date
    var images: [String] = [] // URLs or asset names
    var likes: Int = 0
    var comments: [Comment] = []
    var audience: PostAudience = .innerCircle
}
