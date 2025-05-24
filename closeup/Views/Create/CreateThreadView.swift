import SwiftUI
import PhotosUI
import UIKit

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
    @State private var selectedPhotos: [PhotosPickerItem] = []
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    private let threadService = ThreadService.shared
    
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
                    Button(action: {
                        selectedThread = thread
                    }) {
                        if selectedThread?.id == thread.id {
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
                    FormattedTextEditor(
                        attributedText: $attributedContent,
                        onImageInsertion: { image in
                            // Ensure we're on the main thread for UI updates
                            DispatchQueue.main.async {
                                self.insertImage(image)
                            }
                        },
                        onTextViewCreated: { textView in
                            DispatchQueue.main.async {
                                self.textView = textView
                            }
                        },
                        onTextChanged: { newText in
                            DispatchQueue.main.async {
                                self.attributedContent = newText
                            }
                        },
                        onSelectionChanged: { attributes in
                            DispatchQueue.main.async {
                                self.updateFormattingStates(from: attributes)
                            }
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
                    content: attributedContent.string,
                    audience: audience.rawValue,
                    media: [], // Images are now inline in the content
                    thread_id: selectedThread.id
                )
                
                if Task.isCancelled { return }
                
                await MainActor.run {
                    isSubmitting = false
                    dismiss()
                }
            } catch {
                if !Task.isCancelled {
                    await MainActor.run {
                        self.submitError = error.localizedDescription
                        self.isSubmitting = false
                    }
                }
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
}

#Preview {
    CreateThreadView(appUser: AppUser(uid: "123e4567-e89b-12d3-a456-426614174000", email: "preview@example.com"))
}
