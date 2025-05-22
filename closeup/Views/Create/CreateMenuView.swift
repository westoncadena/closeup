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
            iconName: "book.pages"
        ),
        MenuOption(
            title: "Prompt",
            description: "A little question to get you started if you're not sure what to write.",
            iconName: "questionmark.bubble"
        ),
        MenuOption(
            title: "Thread",
            description: "A spot to keep track of something specific — like a hobby, habit, or project.",
            iconName: "target"
        )
    ]
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack {
                    Spacer()
                    
                    // Menu options
                    ForEach(menuOptions.indices, id: \.self) { idx in
                        let option = menuOptions[idx]
                        Group {
                            if option.title == "Journal" {
                                Button(action: {
                                    showCreateJournalView = true
                                }) {
                                    menuOptionView(for: option)
                                }
                            } else {
                                NavigationLink(destination: Text("Create \(option.title)")) {
                                    menuOptionView(for: option)
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        if idx < menuOptions.count - 1 {
                            Spacer()
                            Divider()
                                .padding(.horizontal, 24)
                            Spacer()
                        }
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(Color.white.ignoresSafeArea())
            .fullScreenCover(isPresented: $showCreateJournalView) {
                if let user = appUser {
                    CreateJournalView(appUser: user)
                }
            }
        }
    }
    
    private func menuOptionView(for option: MenuOption) -> some View {
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
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(nil)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }
}

struct CreateMenuView_Previews: PreviewProvider {
    static var previews: some View {
        CreateMenuView(appUser: AppUser(uid: "preview-uid", email: "preview@example.com"))
    }
}