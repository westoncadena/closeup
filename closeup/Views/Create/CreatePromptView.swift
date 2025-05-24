import SwiftUI
import PhotosUI
import UIKit

public struct CreatePromptView: View {
    let appUser: AppUser
    
    public init(appUser: AppUser) {
        self.appUser = appUser
    }
    
    @Environment(\.dismiss) private var dismiss
    @State private var attributedContent = NSAttributedString()
    @State private var selectedRange: NSRange?
    @State private var selectedDate: Date = Date()
    @State private var showDatePicker = false
    @State private var audience: Audience = .personal
    @State private var textView: UITextView?
    @State private var todaysPrompt: Prompt?
    @State private var isLoadingPrompt = true
    @State private var promptError: String?
    
    // Text formatting states
    @State private var isBold: Bool = false
    @State private var isItalic: Bool = false
    @State private var isUnderlined: Bool = false
    @State private var isBulletedList: Bool = false
    @State private var isQuoteField: Bool = false
    @State private var selectedPhotos: [PhotosPickerItem] = []
    
    private let defaultFontSize: CGFloat = 18
    private let promptService = PromptService()
    
    private func insertImage(_ image: UIImage) {
        guard let textView = textView else { return }
        
        // Create default attributes with proper spacing
        let attributes = createDefaultAttributes()
        
        // Create attachment for the image
        let attachment = NSTextAttachment()
        attachment.image = image
        
        // Scale image to fit width while maintaining aspect ratio
        let maxWidth = textView.textContainer.size.width
        let aspectRatio = image.size.width / image.size.height
        let scaledHeight = maxWidth / aspectRatio
        attachment.bounds = CGRect(x: 0, y: 0, width: maxWidth, height: min(scaledHeight, 200))
        
        // Create attributed string with the image
        let imageString = NSAttributedString(attachment: attachment)
        
        // Always insert a newline before the image if we're not at the start of the text
        let currentLocation = textView.selectedRange.location
        if currentLocation > 0 {
            // Check if we're already at the start of a line
            let currentLine = (textView.text as NSString).substring(to: currentLocation)
            let isAtLineStart = currentLine.hasSuffix("\n")
            
            if !isAtLineStart {
                // Insert newline with default attributes
                let newlineString = NSAttributedString(string: "\n", attributes: attributes)
                textView.textStorage.insert(newlineString, at: textView.selectedRange.location)
            }
        }
        
        // Insert the image
        textView.textStorage.insert(imageString, at: textView.selectedRange.location)
        
        // Insert a newline after the image with default attributes
        let newlineString = NSAttributedString(string: "\n", attributes: attributes)
        textView.textStorage.insert(newlineString, at: textView.selectedRange.location + 1)
        
        // Ensure consistent formatting after image insertion
        let fullRange = NSRange(location: 0, length: textView.textStorage.length)
        textView.textStorage.addAttributes(attributes, range: fullRange)
        
        // Update the binding
        attributedContent = textView.attributedText
    }
    
    private func createDefaultAttributes() -> [NSAttributedString.Key: Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        paragraphStyle.paragraphSpacing = 8
        paragraphStyle.lineHeightMultiple = 1.2
        
        return [
            .font: UIFont.systemFont(ofSize: 18),
            .paragraphStyle: paragraphStyle,
            .foregroundColor: UIColor.label
        ]
    }
    
    private func updateTypingAttributes() {
        guard let textView = textView else { return }
        
        // Start with default attributes
        var attributes = createDefaultAttributes()
        
        // Get current font or use default system font
        let currentFont = textView.typingAttributes[.font] as? UIFont ?? UIFont.systemFont(ofSize: 18)
        
        // Create font descriptor with current traits
        var fontDescriptor = currentFont.fontDescriptor
        var traits = fontDescriptor.symbolicTraits
        
        // Update traits based on state
        if isBold {
            traits.insert(.traitBold)
        }
        if isItalic {
            traits.insert(.traitItalic)
        }
        
        // Create new font with updated traits
        if let newFontDescriptor = fontDescriptor.withSymbolicTraits(traits) {
            attributes[.font] = UIFont(descriptor: newFontDescriptor, size: 18)
        }
        
        // Handle underline separately
        if isUnderlined {
            attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
        }
        
        // Apply attributes to typing attributes
        textView.typingAttributes = attributes
        
        // Apply to selected text if there is a selection
        let selectedRange = textView.selectedRange
        if selectedRange.length > 0 {
            textView.textStorage.addAttributes(attributes, range: selectedRange)
            attributedContent = textView.attributedText
        }
    }
    
    private func updateFormattingStates(from attributes: [NSAttributedString.Key: Any]) {
        if let font = attributes[.font] as? UIFont {
            let traits = font.fontDescriptor.symbolicTraits
            isBold = traits.contains(.traitBold)
            isItalic = traits.contains(.traitItalic)
        } else {
            isBold = false
            isItalic = false
        }
        
        isUnderlined = attributes[.underlineStyle] != nil
    }
    
    @ViewBuilder
    private func buildAudienceMenu() -> some View {
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
    }
    
    public var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                VStack(spacing: 16) {
                    if isLoadingPrompt {
                        ProgressView("Loading today's prompt...")
                            .padding()
                    } else if let error = promptError {
                        Text("Error: \(error)")
                            .foregroundColor(.red)
                            .padding()
                    } else if let prompt = todaysPrompt {
                        Text(prompt.text)
                            .font(.title)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(.gray.opacity(0.3))
                        .padding(.horizontal)
                    
                    HStack {
                        buildAudienceMenu()
                        
                        Spacer()
                        
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
                    
                    ScrollView {
                        FormattedTextEditor(
                            attributedText: $attributedContent,
                            onImageInsertion: { image in
                                insertImage(image)
                            },
                            onTextViewCreated: { textView in
                                self.textView = textView
                            },
                            onTextChanged: { newText in
                                self.attributedContent = newText
                            },
                            onSelectionChanged: { attributes in
                                updateFormattingStates(from: attributes)
                            }
                        )
                        .frame(maxWidth: .infinity, minHeight: UIScreen.main.bounds.height * 0.7)
                        
                        // Add padding at the bottom for toolbar
                        Color.clear
                            .frame(height: 60)
                    }
                }
                .padding(.top)
                
                VStack(spacing: 0) {
                    Divider()
                    
                    TextToolbar(
                        isBold: Binding(
                            get: { isBold },
                            set: { newValue in
                                isBold = newValue
                                updateTypingAttributes()
                            }
                        ),
                        isItalic: Binding(
                            get: { isItalic },
                            set: { newValue in
                                isItalic = newValue
                                updateTypingAttributes()
                            }
                        ),
                        isUnderlined: Binding(
                            get: { isUnderlined },
                            set: { newValue in
                                isUnderlined = newValue
                                updateTypingAttributes()
                            }
                        ),
                        isBulletedList: $isBulletedList,
                        isQuoteField: $isQuoteField,
                        onPhotoSelected: { items in
                            handlePhotoSelection(items)
                        }
                    )
                    .background(Color(UIColor.systemBackground))
                }
            }
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    submitPost()
                }
                .disabled(attributedContent.string.isEmpty)
            )
            .task {
                await fetchTodaysPrompt()
            }
        }
    }
    
    private func fetchTodaysPrompt() async {
        do {
            let prompt = try await promptService.fetchTodaysPrompt()
            await MainActor.run {
                self.todaysPrompt = prompt
                self.isLoadingPrompt = false
            }
        } catch {
            await MainActor.run {
                self.promptError = error.localizedDescription
                self.isLoadingPrompt = false
            }
        }
    }
    
    private func handlePhotoSelection(_ items: [PhotosPickerItem]) {
        Task {
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        insertImage(image)
                    }
                }
            }
        }
    }
    
    private func submitPost() {
        Task {
            do {
                let postService = PostService()
                try await postService.createPost(
                    user_id: appUser.uid,
                    post_type: .prompt,
                    content: attributedContent.string,
                    audience: audience.rawValue,
                    media: [], // Images are now inline in the content
                    prompt_id: todaysPrompt?.id
                )
                dismiss()
            } catch {
                print("Error creating post: \(error)")
                // TODO: Show error alert
            }
        }
    }
}

#Preview {
    CreatePromptView(appUser: AppUser(uid: "preview-uid", email: "preview@example.com"))
}
