import SwiftUI

struct PromptCard: View {
    let title: String
    let prompt: String
    let expiration: String
    let color: Color
    let buttonText: String
    let buttonAction: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(color)
            
            Text(prompt)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(expiration)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button(action: buttonAction) {
                Text(buttonText)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(color)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
}

struct PastPromptCard: View {
    let date: Date
    let prompt: String
    let didAnswer: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Date
            Text(dateFormatter.string(from: date))
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Prompt
            Text(prompt)
                .font(.headline)
                .lineLimit(3)
            
            Spacer()
            
            // Status
            HStack {
                Circle()
                    .frame(width: 8, height: 8)
                    .foregroundColor(didAnswer ? .green : .red)
                
                Text(didAnswer ? "Answered" : "Missed")
                    .font(.caption)
                    .foregroundColor(didAnswer ? .green : .red)
            }
        }
        .padding()
        .frame(width: 200, height: 150)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
    }
}

struct NotificationCell: View {
    let notification: AppNotification
    
    var body: some View {
        HStack(spacing: 12) {
            Image(notification.fromUser.profileImage)
                .resizable()
                .scaledToFill()
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(notification.fromUser.name)
                        .fontWeight(.semibold)
                    
                    Text(notification.content)
                }
                
                Text(timeAgoText(from: notification.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            notificationIcon
        }
        .padding(.vertical, 8)
    }
    
    var notificationIcon: some View {
        switch notification.type {
        case .like:
            return Image(systemName: "heart.fill")
                .foregroundColor(.red)
                .frame(width: 30)
        case .comment:
            return Image(systemName: "bubble.right.fill")
                .foregroundColor(.blue)
                .frame(width: 30)
        case .follow:
            return Image(systemName: "person.fill.badge.plus")
                .foregroundColor(.green)
                .frame(width: 30)
        case .mention:
            return Image(systemName: "at")
                .foregroundColor(.orange)
                .frame(width: 30)
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
