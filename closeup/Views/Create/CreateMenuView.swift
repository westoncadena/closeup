import SwiftUI

struct CreateMenuView: View {
    // Fake data for menu options
    struct MenuOption: Identifiable {
        let id = UUID()
        let title: String
        let description: String
        let iconName: String
    }
    
    let appUser: AppUser?
    @State private var showCreateJournalView = false
    
    private let menuOptions: [MenuOption] = [
        MenuOption(
            title: "Journal",
            description: "Just write whatever's on your mind — no structure, no pressure.",
            iconName: "book.closed"
        ),
        MenuOption(
            title: "Prompt",
            description: "A little question to get you started if you're not sure what to write.",
            iconName: "questionmark.circle"
        ),
        MenuOption(
            title: "Thread",
            description: "A spot to keep track of something specific — like a hobby, habit, or project.",
            iconName: "sparkles"
        )
    ]
    
    var body: some View {
        VStack(spacing: 50) {
            // Simulated status bar
            HStack {
                Text("09:52 AM")
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "wifi")
                    Image(systemName: "battery.100")
                }
                .foregroundColor(.gray)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            Spacer().frame(height: 8)
            
            // Menu options
            ForEach(menuOptions.indices, id: \.self) { idx in
                let option = menuOptions[idx]
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(option.title)
                            .font(.title3)
                            .fontWeight(.semibold)
                        Image(systemName: option.iconName)
                            .foregroundColor(.primary)
                    }
                    Text(option.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .contentShape(Rectangle())
                .onTapGesture {
                    if option.title == "Journal" {
                        showCreateJournalView = true
                    }
                    // Handle other options if necessary
                }
                
                if idx < menuOptions.count - 1 {
                    Divider()
                }
            }
            
            Spacer()
            
            // Bottom navigation bar
            HStack {
                Spacer()
                VStack {
                    Image(systemName: "person.2")
                    // Home
                }
                Spacer()
                VStack {
                    Image(systemName: "square.and.pencil")
                        .foregroundColor(.blue)
                    // Create (current)
                }
                Spacer()
                VStack {
                    Image(systemName: "person.crop.circle")
                    // Profile
                }
                Spacer()
            }
            .padding(.vertical, 10)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(radius: 2)
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .fullScreenCover(isPresented: $showCreateJournalView) {
            CreateJournalView(appUser: appUser)
        }
        .background(Color.white.ignoresSafeArea())
    }
}

struct CreateMenuView_Previews: PreviewProvider {
    static var previews: some View {
        CreateMenuView(appUser: AppUser(uid: "preview-uid", email: "preview@example.com"))
    }
}
