import SwiftUI
import PhotosUI
import UIKit

struct ThreadTextEditor: UIViewRepresentable {
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
            onQuoteStateChanged: onQuoteStateChanged,
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
        private var isBulletedList = false
        private var bulletIndent: CGFloat = 20
        private var bulletHeadIndent: CGFloat = 35
        
        init(onTextChanged: ((NSAttributedString) -> Void)?,
             onSelectionChanged: (([NSAttributedString.Key: Any]) -> Void)?,
             onUpdateQuoteBorder: ((UITextView, Bool) -> Void)?,
             onItalicStateChanged: ((Bool) -> Void)?,
             onQuoteStateChanged: ((Bool) -> Void)?,
             handleQuoteFormatting: ((UITextView) -> Void)?) {
            self.onTextChanged = onTextChanged
            self.onSelectionChanged = onSelectionChanged
            self.onUpdateQuoteBorder = onUpdateQuoteBorder
            self.onItalicStateChanged = onItalicStateChanged
            self.onQuoteStateChanged = onQuoteStateChanged
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
        
        func textViewDidChange(_ textView: UITextView) {
            onTextChanged?(textView.attributedText)
            
            // Update bullet list formatting
            if isBulletedList {
                let attributes = textView.typingAttributes
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineSpacing = defaultLineSpacing
                paragraphStyle.paragraphSpacing = defaultLineSpacing * 2
                paragraphStyle.lineHeightMultiple = 1.2
                paragraphStyle.firstLineHeadIndent = bulletIndent
                paragraphStyle.headIndent = bulletHeadIndent
                
                var newAttributes = attributes
                newAttributes[.paragraphStyle] = paragraphStyle
                textView.typingAttributes = newAttributes
            }
            
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
            
            // Update quote borders if needed
            if isQuoteField {
                updateAllQuoteBorders(in: textView)
            }
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
            // Handle newline
            if text == "\n" {
                let currentAttributes = textView.typingAttributes
                
                // Check if we're in a bullet list
                if let paragraphStyle = currentAttributes[.paragraphStyle] as? NSParagraphStyle,
                   paragraphStyle.headIndent == bulletHeadIndent && paragraphStyle.firstLineHeadIndent == bulletIndent {
                    
                    // Get the current line's text
                    let nsText = textView.text as NSString
                    let currentLineRange = nsText.lineRange(for: NSRange(location: range.location, length: 0))
                    let currentLineText = nsText.substring(with: currentLineRange).trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    // If the current line is empty (just a bullet point), remove bullet formatting
                    if currentLineText.isEmpty || currentLineText == "•" || currentLineText == "• " {
                        // Remove bullet formatting
                        let normalStyle = NSMutableParagraphStyle()
                        normalStyle.lineSpacing = defaultLineSpacing
                        normalStyle.paragraphSpacing = defaultLineSpacing * 2
                        normalStyle.lineHeightMultiple = 1.2
                        normalStyle.firstLineHeadIndent = 0
                        normalStyle.headIndent = 0
                        
                        var newAttributes = currentAttributes
                        newAttributes[.paragraphStyle] = normalStyle
                        
                        // Remove the bullet point and any whitespace
                        let mutableText = NSMutableAttributedString(attributedString: textView.attributedText)
                        mutableText.replaceCharacters(in: currentLineRange, with: "")
                        textView.attributedText = mutableText
                        textView.typingAttributes = newAttributes
                        isBulletedList = false
                        return false
                    }
                    
                    // Insert newline and bullet point
                    textView.insertText("\n• ")
                    return false
                }
                
                // Check if we're in a quote
                if let paragraphStyle = currentAttributes[.paragraphStyle] as? NSParagraphStyle,
                   paragraphStyle.headIndent == 20 && paragraphStyle.firstLineHeadIndent == 20 {
                    
                    // Get the current line's text
                    let nsText = textView.text as NSString
                    let currentLineRange = nsText.lineRange(for: NSRange(location: range.location, length: 0))
                    let currentLineText = nsText.substring(with: currentLineRange).trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    // If the current line is empty, remove quote formatting
                    if currentLineText.isEmpty {
                        // Remove quote formatting
                        let normalStyle = NSMutableParagraphStyle()
                        normalStyle.lineSpacing = defaultLineSpacing
                        normalStyle.paragraphSpacing = defaultLineSpacing * 2
                        normalStyle.lineHeightMultiple = 1.2
                        normalStyle.firstLineHeadIndent = 0
                        normalStyle.headIndent = 0
                        
                        var newAttributes = currentAttributes
                        newAttributes[.paragraphStyle] = normalStyle
                        newAttributes[.foregroundColor] = UIColor.label
                        if let font = UIFont.systemFont(ofSize: defaultFontSize).fontDescriptor.withSymbolicTraits([]) {
                            newAttributes[.font] = UIFont(descriptor: font, size: defaultFontSize)
                        }
                        
                        // Apply normal formatting to the current line
                        textView.textStorage.addAttributes(newAttributes, range: currentLineRange)
                        textView.typingAttributes = newAttributes
                        
                        // Update quote state
                        isQuoteField = false
                        onQuoteStateChanged?(false)
                        onItalicStateChanged?(false)
                        
                        // Remove quote border
                        if let borderLayer = textView.layer.sublayers?.first(where: { $0.name == "quoteBorder" }) {
                            borderLayer.removeFromSuperlayer()
                        }
                        
                        // Remove the empty line
                        let mutableText = NSMutableAttributedString(attributedString: textView.attributedText)
                        mutableText.replaceCharacters(in: currentLineRange, with: "")
                        textView.attributedText = mutableText
                        return false
                    }
                    
                    // Continue quote formatting
                    textView.insertText("\n")
                    return false
                }
            }
            
            return true
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
        
        private func updateAllQuoteBorders(in textView: UITextView) {
            textView.layer.sublayers?.filter { $0.name == "quoteBorder" }.forEach { borderLayer in
                guard let quoteId = borderLayer.value(forKey: "quoteId") as? String,
                      let startPosition = textView.layer.value(forKey: "quoteStartPosition_\(quoteId)") as? UITextPosition else {
                    return
                }
                
                let startRect = textView.caretRect(for: startPosition)
                
                // Validate the rect values
                guard !startRect.isNull && !startRect.isInfinite && startRect.minY.isFinite else { return }
                
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
                            let newEndRect = textView.caretRect(for: endPosition)
                            // Validate the new end rect
                            if !newEndRect.isNull && !newEndRect.isInfinite && newEndRect.maxY.isFinite {
                                endRect = newEndRect
                            }
                        }
                        currentPosition = lineRange.location + lineRange.length
                    } else {
                        break
                    }
                }
                
                // Calculate and validate the height
                let height = endRect.maxY - startRect.minY
                guard height.isFinite && height >= 0 else { return }
                
                // Update the frame size
                var newFrame = borderLayer.frame
                newFrame.size.height = height
                borderLayer.frame = newFrame
            }
        }
    }
}

struct CreateThreadSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var threads: [Threads]
    let userId: String
    let threadService: ThreadService
    
    @State private var name: String = ""
    @State private var threadDescription: String = ""
    @State private var isCreating = false
    @State private var error: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Thread Name", text: $name)
                    TextField("Description", text: $threadDescription, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                if let error = error {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("New Thread")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Create") {
                    createThread()
                }
                .disabled(name.isEmpty || threadDescription.isEmpty || isCreating)
            )
        }
    }
    
    private func createThread() {
        isCreating = true
        error = nil
        
        Task {
            do {
                let newThread = try await threadService.createThread(
                    user_id: userId,
                    name: name,
                    description: threadDescription
                )
                await MainActor.run {
                    threads.append(newThread)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    self.isCreating = false
                }
            }
        }
    }
}

public struct CreateThreadView: View {
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
    @State private var threads: [Threads] = []
    @State private var selectedThread: Threads?
    @State private var showCreateThreadSheet = false
    @State private var isLoadingThreads = true
    @State private var threadsError: String?
    @State private var isSubmitting = false
    @State private var submitError: String?
    
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
    
    private let threadService = ThreadService.shared
    private let defaultFontSize: CGFloat = 18
    private let headingFontSize: CGFloat = 24
    private let defaultLineSpacing: CGFloat = 4
    
    private func insertImage(_ image: UIImage) {
        guard let textView = textView else { return }
        
        // Run UI updates on main thread
        DispatchQueue.main.async {
            // Create default attributes with proper spacing
            let attributes = self.createDefaultAttributes()
            
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
            self.attributedContent = textView.attributedText
        }
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
        let fontDescriptor = currentFont.fontDescriptor
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
            attributes[.font] = UIFont(descriptor: newFontDescriptor, size: isHeading ? headingFontSize : defaultFontSize)
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
            isHeading = font.pointSize >= headingFontSize
        } else {
            isBold = false
            isItalic = false
            isHeading = false
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
    
    private func selectThread(_ thread: Threads) {
        selectedThread = thread
    }
    
    @ViewBuilder
    private func buildThreadMenu() -> some View {
        Menu {
            if threads.isEmpty {
                Button(action: {
                    showCreateThreadSheet = true
                }) {
                    Label("Add Thread", systemImage: "plus")
                }
            } else {
                ForEach(threads) { thread in
                    let isSelected = selectedThread?.id == thread.id
                    Button(action: {
                        selectThread(thread)
                    }) {
                        if isSelected {
                            Label(thread.name, systemImage: "checkmark")
                        } else {
                            Text(thread.name)
                        }
                    }
                }
                
                Divider()
                
                Button(action: {
                    showCreateThreadSheet = true
                }) {
                    Label("Add Thread", systemImage: "plus")
                }
            }
        } label: {
            HStack {
                Text(selectedThread?.name ?? "Thread")
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
        // Check if both fields are empty
        if title.isEmpty && selectedThread == nil {
            alertMessage = "Please enter a title and select a thread for your post."
            showAlert = true
            return
        }
        
        // Check if only title is empty
        if title.isEmpty {
            alertMessage = "Please enter a title for your post."
            showAlert = true
            return
        }
        
        // Check if only thread is empty
        if selectedThread == nil {
            alertMessage = "Please select a thread for your post."
            showAlert = true
            return
        }
        
        submitPost()
    }
    
    public var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 16) {
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    Spacer()
                    Button("Save") {
                        validateAndSubmitPost()
                    }
                }
                .padding(.horizontal)
                
                TextField("Title", text: $title)
                    .font(.title)
                    .textFieldStyle(PlainTextFieldStyle())
                    .multilineTextAlignment(.center)
                    .textInputAutocapitalization(.words)
                    .padding(.horizontal)
                
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.gray.opacity(0.3))
                    .padding(.horizontal)
                
                HStack {
                    buildAudienceMenu()
                    
                    if isLoadingThreads {
                        ProgressView()
                            .padding(8)
                    } else {
                        buildThreadMenu()
                    }
                    
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
                
                if let error = threadsError {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }
                
                if let error = submitError {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }
                
                ScrollView {
                    ThreadTextEditor(
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
                        onQuoteStateChanged: { newState in
                            self.isQuoteField = newState
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
                            if let textView = textView {
                                handleBulletFormatting(textView)
                            }
                        }
                    ),
                    isQuoteField: Binding(
                        get: { isQuoteField },
                        set: { newValue in
                            isQuoteField = newValue
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
        .sheet(isPresented: $showCreateThreadSheet) {
            CreateThreadSheet(
                threads: $threads,
                userId: appUser.uid,
                threadService: threadService
            )
        }
        .task {
            await fetchUserThreads()
        }
        .overlay {
            if isSubmitting {
                ProgressView("Saving...")
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(8)
                    .shadow(radius: 4)
            }
        }
        .alert("Attention", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func handlePhotoSelection(_ items: [PhotosPickerItem]) {
        // Prevent multiple simultaneous photo processing
        guard !isSubmitting else { return }
        
        Task {
            for item in items {
                do {
                    guard let data = try await item.loadTransferable(type: Data.self) else { continue }
                    guard let image = UIImage(data: data) else { continue }
                    
                    // Process on main thread
                    await MainActor.run {
                        insertImage(image)
                    }
                } catch {
                    print("Error handling photo: \(error)")
                }
            }
        }
    }
    
    private func submitPost() {
        guard !isSubmitting else { return }
        guard let selectedThread = selectedThread else {
            submitError = "Please select a thread first"
            return
        }
        
        isSubmitting = true
        submitError = nil
        
        Task {
            do {
                let postService = PostService()
                try await postService.createPost(
                    user_id: appUser.uid,
                    post_type: .thread,
                    title: title,
                    content: attributedContent.string,
                    audience: audience.rawValue,
                    media_urls: [],
                    thread_id: selectedThread.id
                )
                dismiss()
            } catch {
                print("Error creating post: \(error)")
                isSubmitting = false
                submitError = error.localizedDescription
            }
        }
    }
    
    private func fetchUserThreads() {
        isLoadingThreads = true
        threadsError = nil
        
        Task {
            do {
                let userThreads = try await threadService.fetchThreads(forUserId: appUser.uid)
                if Task.isCancelled { return }
                
                await MainActor.run {
                    self.threads = userThreads
                    self.isLoadingThreads = false
                }
            } catch {
                if !Task.isCancelled {
                    await MainActor.run {
                        self.threadsError = error.localizedDescription
                        self.isLoadingThreads = false
                    }
                }
            }
        }
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
            guard let startPosition = textView.position(from: textView.beginningOfDocument, offset: lineRange.location) else { return }
            let startRect = textView.caretRect(for: startPosition)
            
            // Validate the rect values
            guard !startRect.isNull && !startRect.isInfinite && startRect.minY.isFinite else { return }
            
            // Store the start position and range for this quote section
            let quoteId = UUID().uuidString
            textView.layer.setValue(startPosition, forKey: "quoteStartPosition_\(quoteId)")
            textView.layer.setValue(lineRange, forKey: "quoteRange_\(quoteId)")
            borderLayer.setValue(quoteId, forKey: "quoteId")
            
            let x = textView.textContainerInset.left + 4
            let y = startRect.minY
            
            // Validate frame values before setting
            guard x.isFinite && y.isFinite else { return }
            
            borderLayer.frame = CGRect(
                x: x,
                y: y,
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
            
            // Validate the rect values
            guard !startRect.isNull && !startRect.isInfinite && startRect.minY.isFinite else { return }
            
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
                        let newEndRect = textView.caretRect(for: endPosition)
                        // Validate the new end rect
                        if !newEndRect.isNull && !newEndRect.isInfinite && newEndRect.maxY.isFinite {
                            endRect = newEndRect
                        }
                    }
                    currentPosition = lineRange.location + lineRange.length
                } else {
                    break
                }
            }
            
            // Calculate and validate the height
            let height = endRect.maxY - startRect.minY
            guard height.isFinite && height >= 0 else { return }
            
            // Update the frame size
            var newFrame = borderLayer.frame
            newFrame.size.height = height
            borderLayer.frame = newFrame
        }
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
            if let coordinator = textView.delegate as? ThreadTextEditor.Coordinator {
                coordinator.textViewDidChange(textView)
            }
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
        }
        
        // Update the binding
        attributedContent = textView.attributedText
    }
    
    private func handleBulletFormatting(_ textView: UITextView) {
        let selectedRange = textView.selectedRange
        let text = textView.text as NSString
        
        // Get the range of the current line
        let lineRange = text.lineRange(for: NSRange(location: selectedRange.location, length: 0))
        let currentLineText = text.substring(with: lineRange)
        
        if isBulletedList {
            // Create bullet attributes
            var attributes = createDefaultAttributes()
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = defaultLineSpacing
            paragraphStyle.paragraphSpacing = defaultLineSpacing * 2
            paragraphStyle.lineHeightMultiple = 1.2
            paragraphStyle.firstLineHeadIndent = 20
            paragraphStyle.headIndent = 35
            attributes[.paragraphStyle] = paragraphStyle
            
            // Apply bullet formatting to the current line
            textView.textStorage.addAttributes(attributes, range: lineRange)
            textView.typingAttributes = attributes
            
            // Add bullet point if line doesn't start with one
            if !currentLineText.hasPrefix("• ") {
                textView.insertText("• ")
            }
        } else {
            // Reset to default attributes
            var defaultAttributes = createDefaultAttributes()
            
            // Reset paragraph style
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = defaultLineSpacing
            paragraphStyle.paragraphSpacing = defaultLineSpacing * 2
            paragraphStyle.lineHeightMultiple = 1.2
            paragraphStyle.firstLineHeadIndent = 0
            paragraphStyle.headIndent = 0
            defaultAttributes[.paragraphStyle] = paragraphStyle
            
            // Apply normal formatting to the current line
            textView.textStorage.addAttributes(defaultAttributes, range: lineRange)
            textView.typingAttributes = defaultAttributes
            
            // Remove bullet point if present
            if currentLineText.hasPrefix("• ") {
                let bulletRange = NSRange(location: lineRange.location, length: 2)
                textView.textStorage.replaceCharacters(in: bulletRange, with: "")
            }
        }
        
        // Update the binding
        attributedContent = textView.attributedText
    }
}

#Preview {
    CreateThreadView(appUser: AppUser(uid: "123e4567-e89b-12d3-a456-426614174000", email: "preview@example.com"))
}
