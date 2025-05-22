import SwiftUI

struct FeedView: View {
    var body: some View {
        // Each tab can have its own NavigationView if complex navigation is needed within the tab.
        // For a simple feed, a NavigationView might not be immediately necessary at this level
        // if PostView is presented modally. If PostView is pushed, then NavigationView is needed.
        NavigationView {
            Text("Feed View")
                .navigationTitle("Feed")
        }
    }
}

#Preview {
    FeedView()
} 