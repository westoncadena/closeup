import SwiftUI

struct CreateJournalView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var postService = PostService()
    @State private var journalContent: String = ""
    @State private var selectedAudience: Audience = .friends
    @State private var selectedTag: String = "Personal" // Placeholder
    @State private var selectedDate: Date = Date()

    let appUser: AppUser? // Added to accept AppUser

    // Placeholder tags - you can replace these with actual data
    let tags = ["Personal", "Work", "Travel", "Ideas", "Gratitude"]

    enum Audience: String, CaseIterable, Identifiable {
        case everyone = "Everyone"
        case friends = "Friends"
        case innerCircle = "Inner circle" // Matches image, maps to "circle" in DB

        var id: String { self.rawValue }
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextEditor(text: $journalContent)
                        .frame(height: 200) // Adjust height as needed
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                } header: {
                    Text("What's on your mind?")
                }

                Section {
                    Picker("Audience", selection: $selectedAudience) {
                        ForEach(Audience.allCases) { audience in
                            Text(audience.rawValue).tag(audience)
                        }
                    }

                    Picker("Tag", selection: $selectedTag) {
                        ForEach(tags, id: \.self) { tag in
                            Text(tag).tag(tag)
                        }
                    }

                    DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                }
            }
            .navigationTitle("New Journal Entry")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Image(systemName: "chevron.backward")
                            .foregroundColor(.primary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Post") {
                        guard let currentUserId = appUser?.uid else { // Use appUser.uid
                            print("Error: User ID not found. Cannot post journal entry. Make sure AppUser is passed correctly.")
                            // Optionally, show an alert to the user
                            return
                        }

                        // Map Audience enum to database string value
                        let audienceValue: String
                        switch selectedAudience {
                        case .everyone:
                            audienceValue = "everyone"
                        case .friends:
                            audienceValue = "friends"
                        case .innerCircle:
                            audienceValue = "circle" // As per your DB constraint
                        }

                        Task {
                            do {
                                try await postService.createPost(
                                    userId: currentUserId,
                                    postType: .journal, // Explicitly using .journal
                                    content: journalContent,
                                    audience: audienceValue,
                                    media: nil // Passing nil for media as it's not in the UI yet
                                )
                                print("Journal entry posted successfully!")
                                presentationMode.wrappedValue.dismiss() // Dismiss on success
                            } catch {
                                print("Failed to post journal entry: \(error)")
                                // You might want to show an alert to the user here
                            }
                        }
                    }
                }
            }
        }
    }
}

struct CreateJournalView_Previews: PreviewProvider {
    static var previews: some View {
        // Pass a mock AppUser for the preview
        CreateJournalView(appUser: AppUser(uid: "preview-uid", email: "preview@example.com"))
    }
}
