import SwiftUI

struct ContentView: View {
    @Binding var appUser: AppUser?
    
    var body: some View {
        ZStack {
            if let appUser = appUser {
                HomeView(appUser: $appUser)
            } else {
                SignInView(appUser: $appUser)
            }
        }
    }
}

#Preview {
    ContentView(appUser: .constant(nil))
}