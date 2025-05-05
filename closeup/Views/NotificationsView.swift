//
//  NotificationsView.swift
//  closeup
//
//  Created by Weston Cadena on 5/4/25.
//
import SwiftUI

struct NotificationsView: View {
    @State private var notifications: [AppNotification] = []
    
    var body: some View {
        NavigationView {
            List {
                if notifications.isEmpty {
                    Text("No notifications yet")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                        .listRowSeparator(.hidden)
                } else {
                    ForEach(notifications) { notification in
                        NotificationCell(notification: notification)
                    }
                }
            }
            .listStyle(PlainListStyle())
            .navigationTitle("Notifications")
            .onAppear {
                loadSampleNotifications()
            }
        }
    }
    
    func loadSampleNotifications() {
        let user1 = User(name: "Taylor Swift", profileImage: "user2")
        let user2 = User(name: "James Smith", profileImage: "user3")
        
        notifications = [
            AppNotification(type: .like, fromUser: user1, content: "liked your daily prompt response", timestamp: Date().addingTimeInterval(-3600)),
            AppNotification(type: .comment, fromUser: user2, content: "commented on your thought", timestamp: Date().addingTimeInterval(-7200)),
            AppNotification(type: .follow, fromUser: user1, content: "added you to their inner circle", timestamp: Date().addingTimeInterval(-86400))
        ]
    }
}


struct NotificationsView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationsView()
            .environmentObject(AppState())
    }
}
