import SwiftUI
import PhotosUI

struct TextToolbar: View {
    @Binding var isBold: Bool
    @Binding var isItalic: Bool
    @Binding var isUnderlined: Bool
    @Binding var isBulletedList: Bool
    @Binding var isQuoteField: Bool
    @Binding var isHeading: Bool
    
    var onPhotoSelected: ([PhotosPickerItem]) -> Void
    
    @State private var selectedItems: [PhotosPickerItem] = []
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                // Heading
                Button(action: {
                    isHeading.toggle()
                }) {
                    Image(systemName: "textformat.size")
                        .foregroundColor(isHeading ? .blue : .primary)
                }
                
                // Bold
                Button(action: {
                    isBold.toggle()
                }) {
                    Image(systemName: "bold")
                        .foregroundColor(isBold ? .blue : .primary)
                }
                
                // Italic
                Button(action: {
                    isItalic.toggle()
                }) {
                    Image(systemName: "italic")
                        .foregroundColor(isItalic ? .blue : .primary)
                }
                
                // Underline
                Button(action: {
                    isUnderlined.toggle()
                }) {
                    Image(systemName: "underline")
                        .foregroundColor(isUnderlined ? .blue : .primary)
                }
                
                // Bulleted List
                Button(action: {
                    isBulletedList.toggle()
                }) {
                    Image(systemName: "list.bullet")
                        .foregroundColor(isBulletedList ? .blue : .primary)
                }
                
                // Quote
                Button(action: {
                    isQuoteField.toggle()
                }) {
                    Image(systemName: "text.quote")
                        .foregroundColor(isQuoteField ? .blue : .primary)
                }
                
                // Photo Picker
                PhotosPicker(
                    selection: $selectedItems,
                    maxSelectionCount: 10,
                    matching: .images
                ) {
                    Image(systemName: "photo.on.rectangle.angled")
                }
                .onChange(of: selectedItems) { _, newValue in
                    onPhotoSelected(newValue)
                    selectedItems = [] // Reset selection after handling
                }
            }
            .padding(.horizontal)
            .frame(height: 44)
        }
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.gray.opacity(0.3)),
            alignment: .top
        )
    }
}

#Preview {
    TextToolbar(
        isBold: .constant(false),
        isItalic: .constant(false),
        isUnderlined: .constant(false),
        isBulletedList: .constant(false),
        isQuoteField: .constant(false),
        isHeading: .constant(false),
        onPhotoSelected: { _ in }
    )
} 
