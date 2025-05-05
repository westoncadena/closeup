//
//  AppNotification.swift
//  closeup
//
//  Created by Weston Cadena on 5/4/25.
//

import Foundation

struct AppNotification: Identifiable {
    let id = UUID()
    var type: NotificationType
    var fromUser: User
    var content: String
    var timestamp: Date
    var isRead: Bool = false
}

enum NotificationType {
    case like, comment, follow, mention
}


