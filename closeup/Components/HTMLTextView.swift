import SwiftUI
import UIKit

struct HTMLTextView: UIViewRepresentable {
    let htmlContent: String
    let textAlignment: NSTextAlignment
    
    init(htmlContent: String, textAlignment: NSTextAlignment = .left) {
        self.htmlContent = htmlContent
        self.textAlignment = textAlignment
    }
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.backgroundColor = .clear
        textView.isEditable = false
        textView.isScrollEnabled = true
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        textView.textContainer.lineFragmentPadding = 0
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
            
            // Create paragraph style for alignment
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = textAlignment
            
            // Apply paragraph style to the entire text
            let range = NSRange(location: 0, length: mutableAttrString.length)
            mutableAttrString.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
            
            // Set the attributed text
            uiView.attributedText = mutableAttrString
        }
    }
}

#Preview {
    HTMLTextView(
        htmlContent: """
        <h3>Evening Reflections</h3>
        <p>I felt <strong>calm</strong> and <em>grateful</em> tonight.</p>
        <p><img src="https://example.com/image.jpg" alt="sunset" /></p>
        """
    )
} 