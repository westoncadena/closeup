import SwiftUI

struct MainTabView: View {
    @Binding var appUser: AppUser? // Passed from the view that manages auth state
    @State private var selectedTab: Tab = .feed

    // Enum to define the tabs for better type safety and readability
    enum Tab: Hashable {
        case feed
        case create
        case profile
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            FeedView()
                .tabItem {
                    Label("Feed", systemImage: "list.bullet.rectangle.portrait")
                }
                .tag(Tab.feed)

            CreateMenuView()
                .tabItem {
                    Label("Create", systemImage: "plus.circle.fill")
                }
                .tag(Tab.create)

            // Ensure ProfileView is set up to receive an AppUser binding or object
            // For now, assuming ProfileView might need the appUser binding.
            // If ProfileView fetches its own data based on a userID, adjust accordingly.
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle.fill")
                }
                .tag(Tab.profile)
        }
        .onAppear {
            // This is a good place to ensure appUser is not nil if this view appears.
            // If it is nil, it might indicate an issue in the auth flow, 
            // and you might want to trigger a re-authentication or logout.
            if appUser == nil {
                print("Warning: MainTabView appeared but AppUser is nil.")
                // Depending on your app's logic, you might:
                // 1. Force a logout (if this view should never appear without a user)
                // 2. Attempt to re-fetch the session
            }
        }
        // Example: Changing icon color for the selected tab
        // .accentColor(.blue) // Or your app's primary color
    }
}

#if DEBUG
struct MainTabView_Previews: PreviewProvider {
    // Mock AppUser for preview - Reflecting the CURRENT AppUser model from Models/AppUser.swift
    @State static var mockUser: AppUser? = AppUser(
        uid: UUID().uuidString, // Using UUID().uuidString to match String type for uid
        email: "preview@example.com"
    )
    
    // Wrapper to provide a binding to the mockUser for the preview
    struct PreviewWrapper: View {
        @State var user: AppUser? = MainTabView_Previews.mockUser
        var body: some View {
            MainTabView(appUser: $user)
        }
    }

    static var previews: some View {
        PreviewWrapper()
    }
}
#endif
