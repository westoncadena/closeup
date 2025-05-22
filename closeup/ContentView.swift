import SwiftUI

struct ContentView: View {
    @Binding var appUser: AppUser?
    
    var body: some View {
        ZStack {
            if appUser != nil {
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
