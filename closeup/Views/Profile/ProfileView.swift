import SwiftUI

struct ProfileView: View {
    // Assuming AppUser is passed, similar to FeedView. This identifies the *logged-in* user.
    // If this ProfileView can be for *any* user, you might pass a userId: UUID instead.
    let appUser: AppUser 
    @Environment(\.dismiss) private var dismiss
    @State private var userProfile: UserProfile? = nil
    @State private var userPosts: [Post] = []
    @State private var isLoading: Bool = true
    @State private var errorMessage: String? = nil
    @State private var showSignOutAlert = false
    @State private var showMenu = false

    @State private var selectedViewType: ProfileSubViewType = .grid

    private let userService = UserService()
    private let postService = PostService()

    enum ProfileSubViewType: String, CaseIterable, Identifiable {
        case grid = "Grid"
        case list = "List"
        case calendar = "Calendar"
        var id: String { self.rawValue }

        var iconName: String {
            switch self {
            case .grid: return "square.grid.2x2.fill" // Day One uses a book icon, using grid for now
            case .list: return "list.bullet"
            case .calendar: return "calendar"
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if isLoading {
                    ProgressView("Loading profile...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = errorMessage {
                    VStack {
                        Text("Error: \(errorMessage)")
                            .foregroundColor(.red)
                        Button("Retry") { Task { await loadProfileData() } }
                    }.frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let profile = userProfile {
                    // MARK: - Profile Header
                    VStack(spacing: 10) {
                        HStack(alignment: .center, spacing: 15) {
                            // Profile Picture
                            if let profilePicUrlString = profile.profilePicture, let url = URL(string: profilePicUrlString) {
                                AsyncImage(url: url) {
                                    $0.resizable().aspectRatio(contentMode: .fill).frame(width: 80, height: 80).clipShape(Circle())
                                } placeholder: {
                                    Image(systemName: "person.circle.fill").resizable().scaledToFit().frame(width: 80, height: 80).foregroundColor(.gray)
                                }
                            } else {
                                Image(systemName: "person.circle.fill").resizable().scaledToFit().frame(width: 80, height: 80).foregroundColor(.gray)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(profile.fullName).font(.title2).bold()
                                Text("@\(profile.username)").font(.subheadline).foregroundColor(.gray)
                                // You could add more info here like post count, friends count etc.
                                // Text("\(userPosts.count) Posts").font(.caption).foregroundColor(.gray)
                            }
                            Spacer() 
                        }
                        .padding(.horizontal)
                        .padding(.top)
                        
                        // Could add a bio here if your UserProfile model has one
                        // Text(profile.bio ?? "No bio yet.").font(.body).padding(.horizontal)

                        Divider().padding(.top, 5)
                    }
                    
                    // MARK: - View Type Picker
                    Picker("View Type", selection: $selectedViewType) {
                        ForEach(ProfileSubViewType.allCases) { viewType in
                            // Using icon only as per Day One style for this picker
                            Image(systemName: viewType.iconName).tag(viewType)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()

                    // MARK: - Content Area for Sub-Views
                    Group {
                        switch selectedViewType {
                        case .grid:
                            // profile.id is non-optional UUID, so no conditional binding needed.
                            PostsBoardView(userId: profile.id) 
                        case .list:
                            PostsListView(user: profile) // Pass userPosts when ready: PostsListView(posts: userPosts)
                        case .calendar:
                            PostsCalendarView(user: profile) // Pass userPosts when ready: PostsCalendarView(posts: userPosts)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                } else {
                    Text("Profile not found.")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            // Using the username in the nav title might be too long, "Journal" or "Profile" is more common
            .navigationTitle(userProfile?.username ?? "Profile")
            .navigationBarTitleDisplayMode(.inline) // As per Day One image (small title)
             // Hamburger menu if needed - usually part of a more complex navigation structure
            .toolbar {
                 ToolbarItem(placement: .navigationBarLeading) {
                     Menu {
                         Button(role: .destructive) {
                             showSignOutAlert = true
                         } label: {
                             Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                         }
                     } label: {
                         Image(systemName: "line.3.horizontal")
                     }
                 }
            }
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    Task {
                        do {
                            try await AuthManager.shared.signOut()
                            NotificationCenter.default.post(name: NSNotification.Name("UserDidSignOut"), object: nil)
                        } catch {
                            print("Error signing out: \(error)")
                        }
                    }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
        .onAppear {
            Task {
                await loadProfileData()
            }
        }
    }

    func loadProfileData() async {
        isLoading = true
        errorMessage = nil
        do {
            guard let userId = UUID(uuidString: appUser.uid) else {
                errorMessage = "Invalid User ID format in AppUser."
                isLoading = false
                return
            }
            
            async let fetchedProfile = userService.getUser(userId: userId)
            async let fetchedPosts = postService.fetchPosts(forUserId: userId)
            
            let (profileResult, postsResult) = await (try fetchedProfile, try fetchedPosts)
            
            self.userProfile = profileResult
            self.userPosts = postsResult
            
            if self.userProfile == nil {
                errorMessage = "Could not load user profile."
            }
            
        } catch {
            print("Error loading profile data: \(error)")
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

#Preview {
    // Ensure AppUser exists in your project for preview
    // You might need to define a mock AppUser if it's not globally available
    struct MockAppUserPreview: View {
        @State var mockAppUser: AppUser? = AppUser(uid: UUID().uuidString, email: "preview@example.com")
        var body: some View {
            if let user = mockAppUser {
                ProfileView(appUser: user)
            } else {
                Text("Mock AppUser not available for ProfileView preview")
            }
        }
    }
    return MockAppUserPreview()
}
