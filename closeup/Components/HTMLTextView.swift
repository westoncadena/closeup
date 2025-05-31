import SwiftUI
import UIKit

struct HTMLTextView: UIViewRepresentable {
    let htmlContent: String
    let textAlignment: NSTextAlignment
    let baseFontSize: CGFloat
    let maxWidth: CGFloat?

    init(htmlContent: String, textAlignment: NSTextAlignment = .left, baseFontSize: CGFloat = 18, maxWidth: CGFloat? = nil) {
        self.htmlContent = htmlContent
        self.textAlignment = textAlignment
        self.baseFontSize = baseFontSize
        self.maxWidth = maxWidth
    }

    // Helper to create the fully styled attributed string
    private func makeAttributedString() -> NSAttributedString? {
        guard !htmlContent.isEmpty, let data = htmlContent.data(using: .utf8) else {
            return NSAttributedString(string: "") // Return empty string if htmlContent is empty
        }
        
        guard let attributedString = try? NSAttributedString(
            data: data,
            options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ],
            documentAttributes: nil
        ) else {
            return NSAttributedString(string: htmlContent) // Fallback to plain text if HTML parsing fails
        }

        let mutableAttrString = NSMutableAttributedString(attributedString: attributedString)

        mutableAttrString.enumerateAttributes(in: NSRange(location: 0, length: mutableAttrString.length), options: []) { (attributes, range, _) in
            var newAttributes = attributes
            if let existingFont = attributes[.font] as? UIFont {
                newAttributes[.font] = existingFont.withSize(baseFontSize + (existingFont.pointSize - UIFont.systemFontSize)) // Maintain relative size differences
            } else {
                newAttributes[.font] = UIFont.systemFont(ofSize: baseFontSize)
            }
            mutableAttrString.setAttributes(newAttributes, range: range)
        }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = textAlignment
        paragraphStyle.lineBreakMode = .byWordWrapping // Essential for wrapping

        let fullRange = NSRange(location: 0, length: mutableAttrString.length)
        mutableAttrString.addAttribute(.paragraphStyle, value: paragraphStyle, range: fullRange)

        return mutableAttrString
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.backgroundColor = .clear
        textView.isEditable = false
        textView.isScrollEnabled = false // Crucial for intrinsic content sizing
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 0, bottom: 16, right: 0) // Keep your original insets
        textView.textContainer.lineFragmentPadding = 0
        
        textView.layoutManager.allowsNonContiguousLayout = false // Ensure synchronous layout

        // Priorities to allow the view to expand vertically based on content
        textView.setContentCompressionResistancePriority(.required, for: .vertical)
        textView.setContentHuggingPriority(.defaultLow, for: .vertical) // Hug low, so it can expand

        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.attributedText = makeAttributedString()
        // No need to set textContainer.size here if sizeThatFits is implemented correctly
        // SwiftUI will call sizeThatFits, which will use the proposal.
        // We may need to trigger a re-layout if content changes in a way that affects size.
        // uiView.invalidateIntrinsicContentSize() // Consider this if updates don't reflect immediately
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        // Ensure attributedText is current. updateUIView should have set it.
        // If makeAttributedString() is lightweight, can call it here too for safety,
        // but ideally updateUIView handles setting the most current text.
        // uiView.attributedText = makeAttributedString() // Uncomment if necessary

        guard let attributedText = uiView.attributedText, attributedText.length > 0 else {
            // If no content, return a size that accounts for vertical insets only, or .zero
            return CGSize(width: proposal.width ?? 10, height: uiView.textContainerInset.top + uiView.textContainerInset.bottom)
        }

        // Determine the width for measurement.
        // Use the proposal's width if provided and finite.
        // Otherwise, use self.maxWidth (screen width based fallback).
        let measurementWidth: CGFloat
        if let proposedWidth = proposal.width, proposedWidth.isFinite, proposedWidth > 0 {
            measurementWidth = proposedWidth
        } else if let selfMaxWidth = self.maxWidth, selfMaxWidth > 0 {
            measurementWidth = selfMaxWidth
        } else {
            // Fallback to a reasonable default if no width is provided or calculable
            // Subtract horizontal insets if they were non-zero
            measurementWidth = UIScreen.main.bounds.width - (uiView.textContainerInset.left + uiView.textContainerInset.right)
        }
        
        // Ensure measurement width is positive
        let positiveMeasurementWidth = max(1, measurementWidth)

        // Set the text container's width for accurate size calculation.
        // The height is irrelevant here as we want UITextView to calculate it.
        if uiView.textContainer.size.width != positiveMeasurementWidth {
            uiView.textContainer.size = CGSize(width: positiveMeasurementWidth, height: CGFloat.greatestFiniteMagnitude)
        }

        // Ask the UITextView to calculate its optimal size for the given width.
        var calculatedSize = uiView.sizeThatFits(CGSize(width: positiveMeasurementWidth, height: CGFloat.greatestFiniteMagnitude))

        // Ensure calculated width is not zero if there's content, use measurement width as a fallback.
        if calculatedSize.width == 0 && attributedText.length > 0 {
            calculatedSize.width = positiveMeasurementWidth
        }
        
        // The sizeThatFits on UITextView should already include textContainerInsets.
        // If it didn't, you would add them here:
        // calculatedSize.height += uiView.textContainerInset.top + uiView.textContainerInset.bottom
        // calculatedSize.width += uiView.textContainerInset.left + uiView.textContainerInset.right

        return calculatedSize
    }
}

#Preview {
    ScrollView { // Added ScrollView for better previewing of potentially long text
        VStack(alignment: .leading) {
            HTMLTextView(
                htmlContent: """
                <h3>Evening Reflections</h3>
                <p>This is a short line.</p>
                <p>This is a <strong>significantly longer line of text</strong> that absolutely <em>must wrap</em> to multiple lines to demonstrate the wrapping behavior we are trying to achieve with the UITextView inside our HTMLTextView component. If it doesn't wrap, then something is still amiss.</p>
                <p>Another paragraph here. Let's see how it handles multiple paragraphs and varying lengths. We are hoping that the <code>sizeThatFits</code> method, combined with the correct text container setup, will resolve all our wrapping woes and make this component behave as expected in a SwiftUI layout.</p>
                <p><img src="https://via.placeholder.com/150" alt="placeholder" /></p>
                """,
                baseFontSize: 18,
                maxWidth: 300 // Simulate a constrained width for preview
            )
            .border(Color.red) // Visual aid for debugging frame

            HTMLTextView(
                htmlContent: "<p>Just a little bit of text.</p>",
                baseFontSize: 16
            )
            .border(Color.blue)
            
            HTMLTextView(
                htmlContent: "", // Test empty string
                baseFontSize: 16
            )
            .frame(height: 50) // Give it a frame to see it
            .border(Color.green)
        }
        .padding()
    }
}
