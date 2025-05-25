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
    var onUpdateQuoteBorder: ((UITextView, Bool) -> Void)?
    var onItalicStateChanged: ((Bool) -> Void)?
    var onQuoteStateChanged: ((Bool) -> Void)?
    var handleQuoteFormatting: ((UITextView) -> Void)?
    
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
        Coordinator(
            onTextChanged: onTextChanged,
            onSelectionChanged: onSelectionChanged,
            onUpdateQuoteBorder: onUpdateQuoteBorder,
            onItalicStateChanged: onItalicStateChanged,
            handleQuoteFormatting: handleQuoteFormatting
        )
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var currentTypingAttributes: [NSAttributedString.Key: Any]
        var onTextChanged: ((NSAttributedString) -> Void)?
        var onSelectionChanged: (([NSAttributedString.Key: Any]) -> Void)?
        var onUpdateQuoteBorder: ((UITextView, Bool) -> Void)?
        var onItalicStateChanged: ((Bool) -> Void)?
        var onQuoteStateChanged: ((Bool) -> Void)?
        var handleQuoteFormatting: ((UITextView) -> Void)?
        private let defaultFontSize: CGFloat = 18
        private let headingFontSize: CGFloat = 24
        private let defaultLineSpacing: CGFloat = 4
        private var lastWasNewline = false
        private var isHeading = false
        private var isQuoteField = false
        
        init(onTextChanged: ((NSAttributedString) -> Void)?,
             onSelectionChanged: (([NSAttributedString.Key: Any]) -> Void)?,
             onUpdateQuoteBorder: ((UITextView, Bool) -> Void)?,
             onItalicStateChanged: ((Bool) -> Void)?,
             handleQuoteFormatting: ((UITextView) -> Void)?) {
            self.onTextChanged = onTextChanged
            self.onSelectionChanged = onSelectionChanged
            self.onUpdateQuoteBorder = onUpdateQuoteBorder
            self.onItalicStateChanged = onItalicStateChanged
            self.handleQuoteFormatting = handleQuoteFormatting
            
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
        
        private func createDefaultParagraphStyle() -> NSMutableParagraphStyle {
            let style = NSMutableParagraphStyle()
            style.lineSpacing = defaultLineSpacing
            style.paragraphSpacing = defaultLineSpacing * 2
            style.lineHeightMultiple = 1.2
            return style
        }
        
        private func createDefaultAttributes() -> [NSAttributedString.Key: Any] {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = defaultLineSpacing
            paragraphStyle.paragraphSpacing = defaultLineSpacing * 2
            paragraphStyle.lineHeightMultiple = 1.2
            
            return [
                .font: UIFont.systemFont(ofSize: isHeading ? headingFontSize : defaultFontSize),
                .paragraphStyle: paragraphStyle,
                .foregroundColor: UIColor.label
            ]
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
        
        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            print("DEBUG - Function called with text:", text)
            print("DEBUG - Current range:", range)
            
            // Handle newline
            if text == "\n" {
                let currentAttributes = textView.typingAttributes
                
                // Check if we're in a quote
                if let paragraphStyle = currentAttributes[.paragraphStyle] as? NSParagraphStyle,
                   paragraphStyle.headIndent == 20 && paragraphStyle.firstLineHeadIndent == 20 {
                    print("DEBUG - In quote, handling newline")
                    
                    // 1. First, let the newline be inserted normally to maintain cursor position
                    textView.insertText("\n")
                    
                    // 2. Get the range of the line before the cursor
                    let text = textView.text as NSString
                    let cursorPosition = textView.selectedRange.location
                    let previousLineRange = text.lineRange(for: NSRange(location: max(0, cursorPosition - 2), length: 0))
                    
                    // 3. Ensure the previous line maintains quote formatting
                    let quoteStyle = NSMutableParagraphStyle()
                    quoteStyle.lineSpacing = defaultLineSpacing
                    quoteStyle.paragraphSpacing = defaultLineSpacing * 2
                    quoteStyle.lineHeightMultiple = 1.2
                    quoteStyle.firstLineHeadIndent = 20
                    quoteStyle.headIndent = 20
                    
                    var quoteAttributes = currentAttributes
                    quoteAttributes[.paragraphStyle] = quoteStyle
                    quoteAttributes[.foregroundColor] = UIColor.systemGray
                    if let font = UIFont.systemFont(ofSize: defaultFontSize).fontDescriptor.withSymbolicTraits(.traitItalic) {
                        quoteAttributes[.font] = UIFont(descriptor: font, size: defaultFontSize)
                    }
                    
                    textView.textStorage.addAttributes(quoteAttributes, range: previousLineRange)
                    
                    // 4. Set up normal formatting for new line
                    var newAttributes = createDefaultAttributes()
                    let normalParagraphStyle = NSMutableParagraphStyle()
                    normalParagraphStyle.lineSpacing = defaultLineSpacing
                    normalParagraphStyle.paragraphSpacing = defaultLineSpacing * 2
                    normalParagraphStyle.lineHeightMultiple = 1.2
                    normalParagraphStyle.firstLineHeadIndent = 0
                    normalParagraphStyle.headIndent = 0
                    newAttributes[.paragraphStyle] = normalParagraphStyle
                    newAttributes[.foregroundColor] = UIColor.label
                    newAttributes[.font] = UIFont.systemFont(ofSize: defaultFontSize)
                    
                    // 5. Apply normal formatting to the new line
                    let currentLineRange = text.lineRange(for: NSRange(location: cursorPosition, length: 0))
                    textView.textStorage.addAttributes(newAttributes, range: currentLineRange)
                    textView.typingAttributes = newAttributes
                    
                    // 6. Update states
                    isQuoteField = false
                    onItalicStateChanged?(false)
                    
                    // 7. Update the quote border height - only cover the quoted text
                    if let borderLayer = textView.layer.sublayers?.first(where: { $0.name == "quoteBorder" }),
                       let startPosition = textView.layer.value(forKey: "quoteStartPosition") as? UITextPosition {
                        let startRect = textView.caretRect(for: startPosition)
                        
                        // Get the position right before the newline in the previous line
                        if let endPosition = textView.position(from: textView.beginningOfDocument, offset: previousLineRange.location + previousLineRange.length - 1) {
                            let endRect = textView.caretRect(for: endPosition)
                            borderLayer.frame.size.height = endRect.maxY - startRect.minY
                        }
                    }
                    
                    print("DEBUG - Quote handling complete")
                    return false
                }
            }
            
            return true
        }
        
        func textViewDidChange(_ textView: UITextView) {
            onTextChanged?(textView.attributedText)
            
            // Scroll to make cursor visible with padding
            if let selectedRange = textView.selectedTextRange {
                let cursorRect = textView.caretRect(for: selectedRange.start)
                let visibleRect = textView.bounds.inset(by: textView.contentInset)
                
                // Add some padding above and below cursor for better visibility
                let paddedCursorRect = cursorRect.insetBy(dx: 0, dy: -50)
                
                if !visibleRect.contains(paddedCursorRect) {
                    textView.scrollRectToVisible(paddedCursorRect, animated: false)
                }
            }
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
    @State private var isHeading: Bool = false
    @State private var selectedPhotos: [PhotosPickerItem] = []
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var mediaUrls: [String] = []
    
    private let defaultFontSize: CGFloat = 18
    private let headingFontSize: CGFloat = 24
    private let defaultLineSpacing: CGFloat = 4
    
    private func createDefaultParagraphStyle() -> NSMutableParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = defaultLineSpacing
        style.paragraphSpacing = defaultLineSpacing * 2
        style.lineHeightMultiple = 1.2
        return style
    }
    
    private func convertToHTML() -> String {
        var html = "<div>"
        
        // Process the attributed string
        let fullRange = NSRange(location: 0, length: attributedContent.length)
        var currentParagraph = ""
        var isInBulletedList = false
        var isInQuote = false
        
        attributedContent.enumerateAttributes(in: fullRange, options: []) { attributes, range, _ in
            let substring = (attributedContent.string as NSString).substring(with: range)
            
            // Check for image attachment
            if let attachment = attributes[.attachment] as? NSTextAttachment,
               let image = attachment.image,
               let imageUrl = saveImageAndGetUrl(image) {
                // If there's pending paragraph text, add it first
                if !currentParagraph.isEmpty {
                    if isInQuote {
                        html += "<blockquote><em>\(currentParagraph.trimmingCharacters(in: .newlines))</em></blockquote>"
                    } else if isInBulletedList {
                        html += "<ul><li>\(currentParagraph.trimmingCharacters(in: .newlines))</li></ul>"
                    } else {
                        html += "<p>\(currentParagraph.trimmingCharacters(in: .newlines))</p>"
                    }
                    currentParagraph = ""
                }
                html += "<p><img src=\"\(imageUrl)\" alt=\"Journal image\" /></p>"
                if !mediaUrls.contains(imageUrl) {
                    mediaUrls.append(imageUrl)
                }
            } else {
                // Handle text formatting
                var text = substring
                
                // Escape HTML special characters
                text = text.replacingOccurrences(of: "&", with: "&amp;")
                text = text.replacingOccurrences(of: "<", with: "&lt;")
                text = text.replacingOccurrences(of: ">", with: "&gt;")
                
                // Check for quote and bullet formatting
                if let paragraphStyle = attributes[.paragraphStyle] as? NSParagraphStyle {
                    let isBullet = paragraphStyle.headIndent == 35 && paragraphStyle.firstLineHeadIndent == 20
                    let isQuoteFormatted = paragraphStyle.headIndent == 20 && paragraphStyle.firstLineHeadIndent == 20
                    
                    // If formatting changes, output current paragraph
                    if isBullet != isInBulletedList || isQuoteFormatted != isInQuote {
                        if !currentParagraph.isEmpty {
                            if isInQuote {
                                html += "<blockquote><em>\(currentParagraph.trimmingCharacters(in: .newlines))</em></blockquote>"
                            } else if isInBulletedList {
                                html += "<ul><li>\(currentParagraph.trimmingCharacters(in: .newlines))</li></ul>"
                            } else {
                                html += "<p>\(currentParagraph.trimmingCharacters(in: .newlines))</p>"
                            }
                            currentParagraph = ""
                        }
                        isInBulletedList = isBullet
                        isInQuote = isQuoteFormatted
                    }
                }
                
                // Apply text formatting only if not in quote
                if !isInQuote {
                    if let font = attributes[.font] as? UIFont {
                        let traits = font.fontDescriptor.symbolicTraits
                        
                        if font.pointSize >= headingFontSize {
                            text = "<h3>\(text)</h3>"
                        }
                        if traits.contains(.traitBold) {
                            text = "<strong>\(text)</strong>"
                        }
                        if traits.contains(.traitItalic) {
                            text = "<em>\(text)</em>"
                        }
                    }
                    
                    if attributes[.underlineStyle] != nil {
                        text = "<u>\(text)</u>"
                    }
                }
                
                currentParagraph += text
            }
        }
        
        // Add any remaining paragraph text
        if !currentParagraph.isEmpty {
            if isInQuote {
                html += "<blockquote><em>\(currentParagraph.trimmingCharacters(in: .newlines))</em></blockquote>"
            } else if isInBulletedList {
                html += "<ul><li>\(currentParagraph.trimmingCharacters(in: .newlines))</li></ul>"
            } else {
                html += "<p>\(currentParagraph.trimmingCharacters(in: .newlines))</p>"
            }
        }
        
        html += "</div>"
        return html
    }
    
    private func saveImageAndGetUrl(_ image: UIImage) -> String? {
        // This is a placeholder - in a real app, you would:
        // 1. Upload the image to your server/storage
        // 2. Get back the URL
        // 3. Return the URL
        // For now, we'll return a dummy URL
        return "https://cdn.yoursite.com/\(UUID().uuidString).jpg"
    }
    
    private func insertImage(_ image: UIImage) {
        guard let textView = textView else { return }
        
        // Save the entire attributed string and its attributes before insertion
        let originalText = textView.attributedText.mutableCopy() as! NSMutableAttributedString
        
        // Get the default paragraph style to ensure consistent spacing
        let paragraphStyle = createDefaultParagraphStyle()
        
        // Create attachment for the image
        let attachment = NSTextAttachment()
        attachment.image = image
        
        // Scale image to fit width while maintaining aspect ratio
        let maxWidth = textView.textContainer.size.width
        let aspectRatio = image.size.width / image.size.height
        let scaledHeight = maxWidth / aspectRatio
        attachment.bounds = CGRect(x: 0, y: 0, width: maxWidth, height: min(scaledHeight, 200))
        
        // Create attributed string with the image and consistent paragraph style
        let imageAttributes: [NSAttributedString.Key: Any] = [
            .paragraphStyle: paragraphStyle
        ]
        let imageString = NSAttributedString(attachment: attachment, attributes: imageAttributes)
        
        // Create a new mutable attributed string for the final content
        let newContent = NSMutableAttributedString()
        
        // Insert content before the cursor with original attributes
        if textView.selectedRange.location > 0 {
            let beforeCursor = originalText.attributedSubstring(
                from: NSRange(location: 0, length: textView.selectedRange.location)
            )
            newContent.append(beforeCursor)
            
            // Add newline before image if we're not already at the start of a line
            let currentLine = (textView.text as NSString).substring(to: textView.selectedRange.location)
            if !currentLine.hasSuffix("\n") {
                // Get attributes from the last character before cursor
                var newlineAttributes = originalText.attributes(
                    at: max(0, textView.selectedRange.location - 1),
                    effectiveRange: nil
                )
                // Ensure consistent paragraph style
                newlineAttributes[.paragraphStyle] = paragraphStyle
                newContent.append(NSAttributedString(string: "\n", attributes: newlineAttributes))
            }
        }
        
        // Insert the image
        newContent.append(imageString)
        
        // Add newline after image with consistent formatting
        if textView.selectedRange.location > 0 {
            // Get attributes from the text before cursor
            var newlineAttributes = originalText.attributes(
                at: max(0, textView.selectedRange.location - 1),
                effectiveRange: nil
            )
            // Ensure consistent paragraph style
            newlineAttributes[.paragraphStyle] = paragraphStyle
            newContent.append(NSAttributedString(string: "\n", attributes: newlineAttributes))
        } else {
            // If at start of document, use default attributes with paragraph style
            let defaultAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: defaultFontSize),
                .paragraphStyle: paragraphStyle
            ]
            newContent.append(NSAttributedString(string: "\n", attributes: defaultAttributes))
        }
        
        // Insert remaining content after the cursor with original attributes
        if textView.selectedRange.location < originalText.length {
            let afterCursor = originalText.attributedSubstring(
                from: NSRange(
                    location: textView.selectedRange.location,
                    length: originalText.length - textView.selectedRange.location
                )
            )
            
            // Create mutable copy to modify paragraph style
            let afterCursorMutable = NSMutableAttributedString(attributedString: afterCursor)
            afterCursorMutable.enumerateAttribute(.paragraphStyle, in: NSRange(location: 0, length: afterCursorMutable.length)) { _, range, _ in
                afterCursorMutable.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
            }
            
            newContent.append(afterCursorMutable)
        }
        
        // Update the text view with the new content
        textView.attributedText = newContent
        
        // Update cursor position to after the image and newline
        let newCursorPosition = textView.selectedRange.location + 2 // image + newline
        textView.selectedRange = NSRange(location: newCursorPosition, length: 0)
        
        // Update the binding
        attributedContent = textView.attributedText
        
        // Ensure formatting states are updated
        if let attributes = textView.typingAttributes as? [NSAttributedString.Key: Any] {
            updateFormattingStates(from: attributes)
        }
        
        // Update typing attributes to maintain consistent formatting
        textView.typingAttributes[.paragraphStyle] = paragraphStyle
    }
    
    private func createDefaultAttributes() -> [NSAttributedString.Key: Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = defaultLineSpacing
        paragraphStyle.paragraphSpacing = defaultLineSpacing * 2
        paragraphStyle.lineHeightMultiple = 1.2
        
        return [
            .font: UIFont.systemFont(ofSize: isHeading ? headingFontSize : defaultFontSize),
            .paragraphStyle: paragraphStyle,
            .foregroundColor: UIColor.label
        ]
    }
    
    private func updateTypingAttributes() {
        guard let textView = textView else { return }
        
        // Start with default attributes
        var attributes = createDefaultAttributes()
        
        // Get current font or use default system font
        let currentFont = textView.typingAttributes[.font] as? UIFont ?? UIFont.systemFont(ofSize: isHeading ? headingFontSize : defaultFontSize)
        
        // Create font descriptor with current traits
        var fontDescriptor = currentFont.fontDescriptor
        var traits = fontDescriptor.symbolicTraits
        
        // Clear existing bold and italic traits first
        traits.remove([.traitBold, .traitItalic])
        
        // Update traits based on state
        if isBold {
            traits.insert(.traitBold)
        }
        if isItalic || isQuoteField { // Add italic for quotes
            traits.insert(.traitItalic)
        }
        
        // Create new font with updated traits and proper size
        if let newFontDescriptor = fontDescriptor.withSymbolicTraits(traits) {
            let fontSize = isHeading ? headingFontSize : defaultFontSize
            attributes[.font] = UIFont(descriptor: newFontDescriptor, size: fontSize)
        }
        
        // Handle underline
        if isUnderlined {
            attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
        } else {
            attributes[.underlineStyle] = nil
        }
        
        // Create paragraph style with current formatting
        let paragraphStyle = createDefaultParagraphStyle()
        
        // Handle bulleted list
        if isBulletedList {
            paragraphStyle.firstLineHeadIndent = 20 // Space for bullet
            paragraphStyle.headIndent = 35 // Text indentation
        }
        
        // Handle quote formatting
        if isQuoteField {
            paragraphStyle.firstLineHeadIndent = 20
            paragraphStyle.headIndent = 20
        }
        
        attributes[.paragraphStyle] = paragraphStyle
        
        // Apply attributes to typing attributes
        textView.typingAttributes = attributes
        
        // Apply to selected text if there is a selection
        let selectedRange = textView.selectedRange
        if selectedRange.length > 0 {
            textView.textStorage.addAttributes(attributes, range: selectedRange)
            attributedContent = textView.attributedText
        }
        
        // Update the binding
        attributedContent = textView.attributedText
    }
    
    private func updateFormattingStates(from attributes: [NSAttributedString.Key: Any]) {
        if let font = attributes[.font] as? UIFont {
            let traits = font.fontDescriptor.symbolicTraits
            isBold = traits.contains(.traitBold)
            isItalic = traits.contains(.traitItalic)
            isHeading = (font.pointSize >= headingFontSize)
        } else {
            isBold = false
            isItalic = false
            isHeading = false
        }
        
        isUnderlined = attributes[.underlineStyle] != nil
        
        // Update bulleted list and quote states based on paragraph style
        if let paragraphStyle = attributes[.paragraphStyle] as? NSParagraphStyle {
            isBulletedList = paragraphStyle.headIndent == 35 && paragraphStyle.firstLineHeadIndent == 20
            isQuoteField = paragraphStyle.headIndent == 20 && paragraphStyle.firstLineHeadIndent == 20
        } else {
            isBulletedList = false
            isQuoteField = false
        }
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
                            },
                            onUpdateQuoteBorder: { textView, isEnabled in
                                updateQuoteBorder(for: textView, isEnabled: isEnabled)
                            },
                            onItalicStateChanged: { newState in
                                self.isItalic = newState
                            },
                            handleQuoteFormatting: { textView in
                                self.handleQuoteFormatting(textView)
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
                        isBulletedList: Binding(
                            get: { isBulletedList },
                            set: { newValue in
                                isBulletedList = newValue
                                // If enabling bullets, disable quotes
                                if newValue {
                                    isQuoteField = false
                                }
                                if let textView = textView {
                                    handleBulletedList(textView)
                                }
                            }
                        ),
                        isQuoteField: Binding(
                            get: { isQuoteField },
                            set: { newValue in
                                isQuoteField = newValue
                                // If enabling quotes, disable bullets
                                if newValue {
                                    isBulletedList = false
                                }
                                if let textView = textView {
                                    handleQuoteFormatting(textView)
                                }
                            }
                        ),
                        isHeading: Binding(
                            get: { isHeading },
                            set: { newValue in
                                isHeading = newValue
                                updateTypingAttributes()
                            }
                        ),
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
            .onAppear {
                // Setup notification observer for quote field state
                NotificationCenter.default.addObserver(
                    forName: NSNotification.Name("DisableQuoteField"),
                    object: nil,
                    queue: .main
                ) { _ in
                    isQuoteField = false
                }
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
                let htmlContent = convertToHTML()
                print("DEBUG - Raw HTML Content:")
                print("----------------------------------------")
                print(htmlContent)
                print("----------------------------------------")
                try await postService.createPost(
                    user_id: appUser.uid,
                    post_type: .journal,
                    title: title,
                    content: htmlContent,
                    audience: audience.rawValue,
                    media_urls: mediaUrls  // URLs of images embedded in the HTML content
                )
                dismiss()
            } catch {
                print("Error creating post: \(error)")
                // TODO: Show error alert
            }
        }
    }
    
    private func handleBulletedList(_ textView: UITextView) {
        let selectedRange = textView.selectedRange
        let text = textView.text as NSString
        
        // Get the range of the current line
        let lineRange = text.lineRange(for: NSRange(location: selectedRange.location, length: 0))
        let lineText = text.substring(with: lineRange)
        
        if isBulletedList {
            // If line doesn't start with bullet, add one
            if !lineText.hasPrefix("• ") {
                // Create attributes for the bullet point
                var attributes = textView.typingAttributes
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineSpacing = 4
                paragraphStyle.paragraphSpacing = 8
                paragraphStyle.lineHeightMultiple = 1.2
                paragraphStyle.firstLineHeadIndent = 20
                paragraphStyle.headIndent = 35
                attributes[.paragraphStyle] = paragraphStyle
                
                // Insert bullet point at the start of the line
                let bullet = NSAttributedString(string: "• ", attributes: attributes)
                textView.textStorage.insert(bullet, at: lineRange.location)
                
                // Apply formatting to the rest of the line
                let remainingRange = NSRange(location: lineRange.location + 2, length: lineText.count)
                textView.textStorage.addAttributes(attributes, range: remainingRange)
                
                // Move cursor after the bullet
                textView.selectedRange = NSRange(location: lineRange.location + 2, length: 0)
                
                // Update typing attributes for next input
                textView.typingAttributes = attributes
            }
        } else {
            // Only update typing attributes for future text
            var attributes = textView.typingAttributes
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 4
            paragraphStyle.paragraphSpacing = 8
            paragraphStyle.lineHeightMultiple = 1.2
            attributes[.paragraphStyle] = paragraphStyle
            textView.typingAttributes = attributes
            
            // If we're on a bullet line and it's empty, remove the bullet
            if lineText.trimmingCharacters(in: .whitespaces) == "•" || lineText == "• " {
                textView.textStorage.deleteCharacters(in: NSRange(location: lineRange.location, length: 2))
                
                // Adjust cursor position if needed
                if selectedRange.location >= lineRange.location + 2 {
                    textView.selectedRange = NSRange(location: selectedRange.location - 2, length: selectedRange.length)
                }
            }
        }
        
        // Update the binding
        attributedContent = textView.attributedText
    }
    
    private func handleQuoteFormatting(_ textView: UITextView) {
        let selectedRange = textView.selectedRange
        let text = textView.text as NSString
        
        // Get the range of the current line
        let lineRange = text.lineRange(for: NSRange(location: selectedRange.location, length: 0))
        
        if isQuoteField {
            // Create quote attributes
            var attributes = createDefaultAttributes()
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = defaultLineSpacing
            paragraphStyle.paragraphSpacing = defaultLineSpacing * 2
            paragraphStyle.lineHeightMultiple = 1.2
            paragraphStyle.firstLineHeadIndent = 20
            paragraphStyle.headIndent = 20
            attributes[.paragraphStyle] = paragraphStyle
            attributes[.foregroundColor] = UIColor.systemGray
            
            // Force italic when quotes are enabled
            if let font = UIFont.systemFont(ofSize: defaultFontSize).fontDescriptor.withSymbolicTraits(.traitItalic) {
                attributes[.font] = UIFont(descriptor: font, size: defaultFontSize)
            }
            
            // Apply quote formatting to the current line
            textView.textStorage.addAttributes(attributes, range: lineRange)
            textView.typingAttributes = attributes
            
            // Add left border for this quote section
            updateQuoteBorder(for: textView, isEnabled: true)
            
            // Update all quote borders
            updateAllQuoteBorders(in: textView)
        } else {
            // Reset to default attributes and disable italic
            isItalic = false
            
            // Create default attributes without italic
            var defaultAttributes = createDefaultAttributes()
            if let font = defaultAttributes[.font] as? UIFont,
               let normalDescriptor = font.fontDescriptor.withSymbolicTraits([]) {
                defaultAttributes[.font] = UIFont(descriptor: normalDescriptor, size: defaultFontSize)
            }
            
            // Reset paragraph style
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = defaultLineSpacing
            paragraphStyle.paragraphSpacing = defaultLineSpacing * 2
            paragraphStyle.lineHeightMultiple = 1.2
            paragraphStyle.firstLineHeadIndent = 0
            paragraphStyle.headIndent = 0
            defaultAttributes[.paragraphStyle] = paragraphStyle
            defaultAttributes[.foregroundColor] = UIColor.label
            
            // Apply normal formatting to the current line
            textView.textStorage.addAttributes(defaultAttributes, range: lineRange)
            textView.typingAttributes = defaultAttributes
            
            // Update all quote borders
            updateAllQuoteBorders(in: textView)
        }
        
        // Update the binding
        attributedContent = textView.attributedText
    }
    
    private func updateQuoteBorder(for textView: UITextView, isEnabled: Bool = true) {
        // Don't remove existing borders - each quote section should keep its border
        if isEnabled {
            let borderWidth: CGFloat = 3
            let borderLayer = CALayer()
            borderLayer.name = "quoteBorder"
            
            // Get the current line's rect
            let selectedRange = textView.selectedRange
            let text = textView.text as NSString
            let lineRange = text.lineRange(for: NSRange(location: selectedRange.location, length: 0))
            let startPosition = textView.position(from: textView.beginningOfDocument, offset: lineRange.location)!
            let startRect = textView.caretRect(for: startPosition)
            
            // Store the start position and range for this quote section
            let quoteId = UUID().uuidString
            textView.layer.setValue(startPosition, forKey: "quoteStartPosition_\(quoteId)")
            textView.layer.setValue(lineRange, forKey: "quoteRange_\(quoteId)")
            borderLayer.setValue(quoteId, forKey: "quoteId")
            
            borderLayer.frame = CGRect(
                x: textView.textContainerInset.left + 4,
                y: startRect.minY,
                width: borderWidth,
                height: 0 // Will be updated as text is added
            )
            borderLayer.backgroundColor = UIColor.systemGray2.cgColor
            textView.layer.addSublayer(borderLayer)
        }
    }
    
    private func updateAllQuoteBorders(in textView: UITextView) {
        // Update heights of all quote borders
        textView.layer.sublayers?.filter { $0.name == "quoteBorder" }.forEach { borderLayer in
            guard let quoteId = borderLayer.value(forKey: "quoteId") as? String,
                  let startPosition = textView.layer.value(forKey: "quoteStartPosition_\(quoteId)") as? UITextPosition else {
                return
            }
            
            let startRect = textView.caretRect(for: startPosition)
            
            // Find the end of this quote section by looking for the next non-quoted line
            let text = textView.text as NSString
            var currentPosition = textView.offset(from: textView.beginningOfDocument, to: startPosition)
            var endRect = startRect
            
            while currentPosition < text.length {
                let lineRange = text.lineRange(for: NSRange(location: currentPosition, length: 0))
                let attributes = textView.attributedText.attributes(at: currentPosition, effectiveRange: nil)
                
                if let paragraphStyle = attributes[.paragraphStyle] as? NSParagraphStyle,
                   paragraphStyle.headIndent == 20 && paragraphStyle.firstLineHeadIndent == 20 {
                    // This line is quoted, update end rect
                    if let endPosition = textView.position(from: textView.beginningOfDocument, offset: lineRange.location + lineRange.length - 1) {
                        endRect = textView.caretRect(for: endPosition)
                    }
                    currentPosition = lineRange.location + lineRange.length
                } else {
                    break
                }
            }
            
            borderLayer.frame.size.height = endRect.maxY - startRect.minY
        }
    }
}

#Preview {
    CreateJournalView(appUser: AppUser(uid: "preview-uid", email: "preview@example.com"))
}
