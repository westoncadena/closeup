import SwiftUI
import UIKit

struct HTMLTextView: UIViewRepresentable {
    let htmlContent: String
    let textAlignment: NSTextAlignment
    let baseFontSize: CGFloat
    
    init(htmlContent: String, textAlignment: NSTextAlignment = .left, baseFontSize: CGFloat = 18) {
        self.htmlContent = htmlContent
        self.textAlignment = textAlignment
        self.baseFontSize = baseFontSize
    }
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.backgroundColor = .clear
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 0, bottom: 16, right: 0)
        textView.textContainer.lineFragmentPadding = 0
        
        textView.setContentCompressionResistancePriority(.required, for: .vertical)
        textView.setContentHuggingPriority(.defaultLow, for: .vertical)
        
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        // Create attributed string from HTML
        if let data = htmlContent.data(using: .utf8),
           let attributedString = try? NSAttributedString(
            data: data,
            options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ],
            documentAttributes: nil
           ) {
            
            // Create mutable copy to modify attributes
            let mutableAttrString = NSMutableAttributedString(attributedString: attributedString)
            
            // Enumerate attributes and adjust font size
            mutableAttrString.enumerateAttributes(in: NSRange(location: 0, length: mutableAttrString.length), options: []) { (attributes, range, _) in
                var newAttributes = attributes
                if let existingFont = attributes[.font] as? UIFont {
                    // Increase size of existing font
                    newAttributes[.font] = existingFont.withSize(baseFontSize + (existingFont.pointSize - UIFont.systemFontSize)) // Maintain relative size differences
                } else {
                    // Apply default base font size
                    newAttributes[.font] = UIFont.systemFont(ofSize: baseFontSize)
                }
                mutableAttrString.setAttributes(newAttributes, range: range)
            }
            
            // Create paragraph style for alignment
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = textAlignment
            
            // Apply paragraph style to the entire text
            let range = NSRange(location: 0, length: mutableAttrString.length)
            mutableAttrString.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
            
            // Set the attributed text
            uiView.attributedText = mutableAttrString
            
            // Removed explicit layout calls: uiView.setNeedsLayout() and uiView.layoutIfNeeded()
            // SwiftUI will manage layout updates when htmlContent changes and attributedText is set.
        }
    }
}

#Preview {
    HTMLTextView(
        htmlContent: """
        <h3>Evening Reflections</h3>
        <p>I felt <strong>calm</strong> and <em>grateful</em> tonight.</p>
        <p><img src="https://example.com/image.jpg" alt="sunset" /></p>
        """,
        baseFontSize: 20
    )
} 