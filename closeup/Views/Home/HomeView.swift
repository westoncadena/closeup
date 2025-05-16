//
//  HomeView.swift
//  closeup
//
//  Created by Weston Cadena on 5/9/25.
//

import SwiftUI

struct HomeView: View {
    @State var appUser: AppUser
    
    var body: some View {
        VStack{
            Text(appUser.uid)
            Text(appUser.email ?? "No Email")
            
            Button{
                Task {
                    do {
                        try await AuthManager.shared.signOut()
                    }
                    catch {
                        print("Error signing out: \(error)")
                    }
                }
            } label: {
                Text("Sign Out")
                    .foregroundColor(.red)
            }
        }
    }
}

#Preview {
    HomeView(appUser: .init(uid: "123", email: "test@test.com"))
}
