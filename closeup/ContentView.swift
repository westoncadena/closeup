import SwiftUI

struct ContentView: View {
    @Binding var appUser: AppUser?
    
    var body: some View {
        ZStack {
            if appUser != nil {
                MainTabView(appUser: $appUser)
            } else {
                SignInView(appUser: $appUser)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserDidSignOut"))) { _ in
            appUser = nil
        }
    }
}

#Preview {
    ContentView(appUser: .constant(nil))
}
