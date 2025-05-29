import SwiftUI
import Combine // For Timer used in debouncing, though Task.sleep is also an option

// SearchUser struct and allUsers array are removed as we will use UserProfile and UserService

struct SearchView: View {
    @State private var searchText = ""
    @State private var searchResults: [UserProfile] = []
    @State private var isLoading: Bool = false
    @State private var searchError: String? = nil
    
    // Timer for debouncing
    @State private var debounceTimer: Timer? = nil
    private let debounceInterval: TimeInterval = 0.5 // 0.5 seconds

    private let userService = UserService()

    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Searching...")
                        .padding()
                    Spacer()
                } else if let error = searchError {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                        .padding()
                    Button("Retry") {
                        // Clear error and retry search with current text
                        searchError = nil
                        performSearch(query: searchText)
                    }
                    Spacer()
                } else if searchText.isEmpty && searchResults.isEmpty {
                    Text("Search for users by username or full name.")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .padding()
                        Spacer()
                } else if !searchText.isEmpty && searchResults.isEmpty {
                     Text("No users found for \"\(searchText)\".")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .padding()
                        Spacer()
                } else {
                    List(searchResults) { user in
                        UserRow(user: user)
                    }
                }
            }
            .navigationTitle("Search Users")
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search by username or name")
            .onChange(of: searchText) { _, newValue in
                // Invalidate existing timer
                debounceTimer?.invalidate()
                // Start a new timer
                debounceTimer = Timer.scheduledTimer(withTimeInterval: debounceInterval, repeats: false) { _ in
                    performSearch(query: newValue)
                }
            }
            .onDisappear {
                // Invalidate timer when view disappears to prevent potential issues
                debounceTimer?.invalidate()
            }
        }
    }

    func performSearch(query: String) {
        // Ensure previous error is cleared before new search
        searchError = nil 

        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = []
            isLoading = false // Ensure loading is stopped if query is cleared
            return
        }

        isLoading = true
        
        Task {
            do {
                let users = try await userService.searchUsers(query: query)
                searchResults = users
                if users.isEmpty && !query.isEmpty {
                    // This state is handled by the View logic above
                }
            } catch {
                print("Search failed with error: \(error.localizedDescription)")
                searchError = error.localizedDescription
                searchResults = [] // Clear results on error
            }
            isLoading = false
        }
    }
}

struct UserRow: View {
    let user: UserProfile // Changed to UserProfile

    var body: some View {
        HStack(spacing: 12) {
            if let profilePicUrlString = user.profilePicture, let url = URL(string: profilePicUrlString) {
                AsyncImage(url: url) {
                    $0.resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 45, height: 45)
                        .clipShape(Circle())
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 45, height: 45)
                        .foregroundColor(.gray)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(Circle())
                }
            } else {
                Image(systemName: "person.circle.fill") // Default SF Symbol
                    .resizable()
                    .scaledToFit()
                    .frame(width: 45, height: 45)
                    .foregroundColor(.gray)
                    .padding(5)
                    .background(Color.gray.opacity(0.2))
                    .clipShape(Circle())
            }

            VStack(alignment: .leading) {
                Text(user.fullName) // Using fullName computed property from UserProfile
                    .font(.headline)
                Text("@\(user.username)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SearchView()
}
