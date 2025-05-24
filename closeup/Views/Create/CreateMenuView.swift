import SwiftUI

struct CreateMenuView: View {
    // Menu option type
    struct MenuOption: Identifiable {
        let id = UUID()
        let title: String
        let description: String
        let iconName: String
    }
    
    @Binding var appUser: AppUser?
    
    // Separate state for each view type
    @State private var showJournalView = false
    @State private var showPromptView = false
    @State private var showThreadView = false
    
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
        GeometryReader { geometry in
            VStack {
                Spacer()
                
                // Menu options
                ForEach(menuOptions) { option in
                    Button(action: {
                        switch option.title {
                        case "Journal":
                            showJournalView = true
                        case "Prompt":
                            showPromptView = true
                        case "Thread":
                            showThreadView = true
                        default:
                            break
                        }
                    }) {
                        menuOptionView(for: option)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    if option.id != menuOptions.last?.id {
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
        .background(Color(UIColor.systemBackground).ignoresSafeArea())
        // Use separate fullScreenCover for each view type
        .fullScreenCover(isPresented: $showJournalView) {
            if let user = appUser {
                CreateJournalView(appUser: user)
            }
        }
        .fullScreenCover(isPresented: $showPromptView) {
            if let user = appUser {
                CreatePromptView(appUser: user)
            }
        }
        .fullScreenCover(isPresented: $showThreadView) {
            if let user = appUser {
                CreateThreadView(appUser: user)
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
    NavigationView {
        CreateMenuView(appUser: .constant(AppUser(uid: "123e4567-e89b-12d3-a456-426614174000", email: "preview@example.com")))
    }
}