import SwiftUI

struct CreateJournalView: View {
    let appUser: AppUser
    
    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var selectedDate: Date = Date()
    @State private var showDatePicker = false
    @State private var audience: Audience = .everyone
    
    enum Audience: String, CaseIterable {
        case everyone = "Private"
        case friends = "Friends"
        case innerCircle = "Inner Circle"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Title field
                TextField("Title", text: $title)
                    .font(.title)
                    .multilineTextAlignment(.center)
                    .textInputAutocapitalization(.words)
                    .padding(.horizontal)
                
                // Horizontal line
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.gray.opacity(0.3))
                    .padding(.horizontal)
                
                // Audience and Date Row
                HStack {
                    // Audience Picker
                    Menu {
                        ForEach(Audience.allCases, id: \.self) { option in
                            Button(action: {
                                audience = option
                            }) {
                                if audience == option {
                                    Label(option.rawValue, systemImage: "checkmark")
                                } else {
                                    Text(option.rawValue)
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(audience.rawValue)
                            Image(systemName: "chevron.down")
                        }
                        .padding(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    }
                    
                    Spacer()
                    
                    // Date and Calendar
                    HStack(spacing: 4) {
                        Text(selectedDate.formatted(date: .numeric, time: .omitted))
                            .foregroundColor(.gray)
                        Button(action: {
                            showDatePicker.toggle()
                        }) {
                            Image(systemName: "calendar")
                        }
                        .popover(isPresented: $showDatePicker, arrowEdge: .top) {
                            VStack {
                                DatePicker(
                                    "Select Date",
                                    selection: $selectedDate,
                                    displayedComponents: [.date]
                                )
                                .datePickerStyle(.graphical)
                                .padding()
                                .labelsHidden()
                            }
                            .frame(minWidth: 300, minHeight: 350)
                            .presentationCompactAdaptation(.popover)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Content editor
                TextEditor(text: $content)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .placeholder(when: content.isEmpty) {
                        Text("Write about anything")
                            .foregroundColor(.gray.opacity(0.8))
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            .padding(.top, 8)
                    }
                    .padding(.horizontal)
                
                /* Commented out toolbar as requested
                // Formatting toolbar
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        // ... toolbar content ...
                    }
                    .padding()
                }
                .background(Color(.systemGray6))
                */
            }
            .padding(.top)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Post") {
                    submitPost()
                }
                .disabled(title.isEmpty)
            )
        }
    }
    
    private func submitPost() {
        Task {
            do {
                let postService = PostService()
                try await postService.createPost(
                    user_id: appUser.uid,
                    post_type: .journal,
                    content: content,
                    audience: audience.rawValue,
                    media: nil
                )
                dismiss()
            } catch {
                print("Error creating post: \(error)")
                // TODO: Show error alert
            }
        }
    }
}

// Helper extension for placeholder text in TextEditor
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

#Preview {
    CreateJournalView(appUser: AppUser(uid: "preview-uid", email: "preview@example.com"))
}
