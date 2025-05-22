import SwiftUI
import PhotosUI

struct CreateJournalView: View {
    let appUser: AppUser
    
    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var selectedDate: Date = Date()
    @State private var showDatePicker = false
    @State private var audience: Audience = .personal
    
    // Text formatting states
    @State private var isBold: Bool = false
    @State private var isItalic: Bool = false
    @State private var isUnderlined: Bool = false
    @State private var isBulletedList: Bool = false
    @State private var isQuoteField: Bool = false
    @State private var selectedMedia: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil
    
    enum Audience: String, CaseIterable {
        case personal = "Personal"
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
                
                // Selected Image Preview
                if let imageData = selectedImageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .padding(.horizontal)
                }
                
                // Text Toolbar
                TextToolbar(
                    isBold: $isBold,
                    isItalic: $isItalic,
                    isUnderlined: $isUnderlined,
                    isBulletedList: $isBulletedList,
                    isQuoteField: $isQuoteField,
                    onPhotoSelected: { item in
                        handlePhotoSelection(item)
                    }
                )
            }
            .padding(.top)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    submitPost()
                }
                .disabled(title.isEmpty)
            )
        }
    }
    
    private func handlePhotoSelection(_ item: PhotosPickerItem) {
        Task {
            if let data = try? await item.loadTransferable(type: Data.self) {
                await MainActor.run {
                    selectedImageData = data
                }
            }
        }
    }
    
    private func submitPost() {
        Task {
            do {
                let postService = PostService()
                let mediaImage: UIImage? = selectedImageData.flatMap { UIImage(data: $0) }
                try await postService.createPost(
                    user_id: appUser.uid,
                    post_type: .journal,
                    content: content,
                    audience: audience.rawValue,
                    media: mediaImage
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
