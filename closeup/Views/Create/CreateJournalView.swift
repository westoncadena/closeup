import SwiftUI
import PhotosUI
import UIKit

// Move Audience enum outside and make it public
public enum Audience: String, CaseIterable {
    case personal = "Personal"
    case friends = "Friends"
    case innerCircle = "Inner Circle"
}

// Remove class requirement from protocol
protocol FormattedTextViewDelegate {
    func textDidChange(_ attributedText: NSAttributedString)
}

struct FormattedTextEditor: UIViewRepresentable {
    @Binding var attributedText: NSAttributedString
    var onImageInsertion: ((UIImage) -> Void)?
    var onTextViewCreated: ((UITextView) -> Void)?
    var onTextChanged: ((NSAttributedString) -> Void)?
    var onSelectionChanged: (([NSAttributedString.Key: Any]) -> Void)?
    
    private let defaultFontSize: CGFloat = 18
    private let defaultLineSpacing: CGFloat = 4
    private let horizontalMargin: CGFloat = 16
    
    private func createDefaultParagraphStyle() -> NSMutableParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = defaultLineSpacing
        style.paragraphSpacing = defaultLineSpacing * 2
        style.lineHeightMultiple = 1.2
        return style
    }
    
    private func createDefaultAttributes() -> [NSAttributedString.Key: Any] {
        let defaultFont = UIFont.systemFont(ofSize: defaultFontSize)
        return [
            .font: defaultFont,
            .paragraphStyle: createDefaultParagraphStyle()
        ]
    }
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        
        // Set default attributes
        let defaultAttributes = createDefaultAttributes()
        textView.typingAttributes = defaultAttributes
        
        textView.backgroundColor = .clear
        textView.isScrollEnabled = true
        textView.textContainerInset = UIEdgeInsets(top: 16, left: horizontalMargin, bottom: 16, right: horizontalMargin)
        textView.textContainer.lineFragmentPadding = 0
        
        // Set a fixed width for the text container
        textView.textContainer.size = CGSize(
            width: UIScreen.main.bounds.width - (horizontalMargin * 2),
            height: .greatestFiniteMagnitude
        )
        
        onTextViewCreated?(textView)
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.attributedText != attributedText {
            let selectedRange = uiView.selectedRange
            
            // Ensure consistent font size and paragraph style in attributed text
            let mutableAttr = NSMutableAttributedString(attributedString: attributedText)
            mutableAttr.enumerateAttributes(in: NSRange(location: 0, length: mutableAttr.length)) { (attributes, range, _) in
                var newAttributes = attributes
                
                // Preserve font size while keeping other font attributes
                if let font = attributes[.font] as? UIFont {
                    newAttributes[.font] = font.withSize(defaultFontSize)
                } else {
                    newAttributes[.font] = UIFont.systemFont(ofSize: defaultFontSize)
                }
                
                // Ensure paragraph style with proper spacing
                newAttributes[.paragraphStyle] = createDefaultParagraphStyle()
                
                mutableAttr.setAttributes(newAttributes, range: range)
            }
            
            uiView.attributedText = mutableAttr
            uiView.selectedRange = selectedRange
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onTextChanged: onTextChanged, onSelectionChanged: onSelectionChanged)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var currentTypingAttributes: [NSAttributedString.Key: Any]
        var onTextChanged: ((NSAttributedString) -> Void)?
        var onSelectionChanged: (([NSAttributedString.Key: Any]) -> Void)?
        private let defaultFontSize: CGFloat = 18
        private let defaultLineSpacing: CGFloat = 4
        
        init(onTextChanged: ((NSAttributedString) -> Void)?,
             onSelectionChanged: (([NSAttributedString.Key: Any]) -> Void)?) {
            self.onTextChanged = onTextChanged
            self.onSelectionChanged = onSelectionChanged
            
            // Initialize with default attributes including paragraph style
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = defaultLineSpacing
            paragraphStyle.paragraphSpacing = defaultLineSpacing * 2
            paragraphStyle.lineHeightMultiple = 1.2
            
            self.currentTypingAttributes = [
                .font: UIFont.systemFont(ofSize: defaultFontSize),
                .paragraphStyle: paragraphStyle
            ]
            
            super.init()
        }
        
        func textViewDidChangeSelection(_ textView: UITextView) {
            // Get attributes at cursor position or selection
            let attributes: [NSAttributedString.Key: Any]
            
            if textView.selectedRange.length > 0 {
                // For selection, use the attributes at the start of selection
                attributes = textView.attributedText.attributes(at: textView.selectedRange.location, 
                                                              effectiveRange: nil)
            } else if textView.selectedRange.location > 0 {
                // For cursor, use attributes of the character before cursor
                attributes = textView.attributedText.attributes(at: textView.selectedRange.location - 1, 
                                                              effectiveRange: nil)
            } else {
                // At the start of the text, use typing attributes
                attributes = textView.typingAttributes
            }
            
            onSelectionChanged?(attributes)
        }
        
        func textViewDidChange(_ textView: UITextView) {
            onTextChanged?(textView.attributedText)
        }
        
        func updateTypingAttributes(_ attributes: [NSAttributedString.Key: Any], for textView: UITextView) {
            currentTypingAttributes = attributes
            textView.typingAttributes = attributes
        }
    }
}

// Helper extension to get parent view controller
extension UIView {
    var parentViewController: UIViewController? {
        var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder?.next
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
        }
        return nil
    }
}

public struct CreateJournalView: View {
    let appUser: AppUser
    
    public init(appUser: AppUser) {
        self.appUser = appUser
    }
    
    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var attributedContent = NSAttributedString()
    @State private var selectedRange: NSRange?
    @State private var selectedDate: Date = Date()
    @State private var showDatePicker = false
    @State private var audience: Audience = .personal
    @State private var textView: UITextView?
    
    // Text formatting states
    @State private var isBold: Bool = false
    @State private var isItalic: Bool = false
    @State private var isUnderlined: Bool = false
    @State private var isBulletedList: Bool = false
    @State private var isQuoteField: Bool = false
    @State private var selectedPhotos: [PhotosPickerItem] = []
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    private let defaultFontSize: CGFloat = 18
    
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
    
    private func validateAndSubmitPost() {
        if title.isEmpty {
            alertMessage = "Please enter a title for your journal entry."
            showAlert = true
            return
        }
        
        submitPost()
    }
    
    public var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                VStack(spacing: 16) {
                    TextField("Title", text: $title)
                        .font(.title)
                        .multilineTextAlignment(.center)
                        .textInputAutocapitalization(.words)
                        .padding(.horizontal)
                    
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
                    validateAndSubmitPost()
                }
            )
            .alert("Attention", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
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
                    post_type: .journal,
                    content: attributedContent.string,
                    audience: audience.rawValue,
                    media: [] // Images are now inline in the content
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
    CreateJournalView(appUser: AppUser(uid: "preview-uid", email: "preview@example.com"))
}
