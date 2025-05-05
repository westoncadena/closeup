//
//  Comment.swift
//  closeup
//
//  Created by Weston Cadena on 5/4/25.
//

import Foundation

struct Comment: Identifiable {
    let id = UUID()
    var author: User
    var content: String
    var timestamp: Date
}
