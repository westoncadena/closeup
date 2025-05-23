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
    @State private var showCreatePromptView = false
    
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
                            } else if option.title == "Prompt" {
                                Button(action: {
                                    showCreatePromptView = true
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
            .fullScreenCover(isPresented: $showCreatePromptView) {
                if let user = appUser {
                    CreatePromptView(appUser: user)
                }
            }
        }
    }
    
    @ViewBuilder
    private func menuOptionView(for option: MenuOption) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: option.iconName)
                    .font(.title2)
                Text(option.title)
                    .font(.title2)
                    .fontWeight(.medium)
            }
            Text(option.description)
                .font(.subheadline)
                .foregroundColor(.gray)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(UIColor.systemBackground))
    }
}

#Preview {
    CreateMenuView(appUser: AppUser(uid: "preview-uid", email: "preview@example.com"))
}