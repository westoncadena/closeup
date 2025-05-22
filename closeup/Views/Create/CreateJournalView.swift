import SwiftUI

struct CreateJournalView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var journalContent: String = ""
    @State private var selectedAudience: Audience = .friends
    @State private var selectedTag: String = "Personal" // Placeholder
    @State private var selectedDate: Date = Date()

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
                        // Add post action here
                        print("Post tapped")
                        // print("Content: \(journalContent)")
                        // print("Audience: \(selectedAudience.rawValue)")
                        // print("Tag: \(selectedTag)")
                        // print("Date: \(selectedDate)")
                        // Map to Supabase values:
                        // audience: selectedAudience.rawValue (map "Inner circle" to "circle" if needed for DB)
                        // post_type: "journal"
                        // content: journalContent
                        // created_at: selectedDate (ensure formatting is correct for Supabase)
                    }
                }
            }
        }
    }
}

struct CreateJournalView_Previews: PreviewProvider {
    static var previews: some View {
        CreateJournalView()
    }
}
