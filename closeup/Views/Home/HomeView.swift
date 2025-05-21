//
//  HomeView.swift
//  closeup
//
//  Created by Weston Cadena on 5/9/25.
//

import SwiftUI

struct HomeView: View {
    @Binding var appUser: AppUser?
    
    var body: some View {
        VStack{
            if let user = appUser {
                Text(user.uid)
                Text(user.email ?? "No Email")
                
                Button{
                    Task {
                        do {
                            try await AuthManager.shared.signOut()
                            appUser = nil
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
}

#Preview {
    HomeView(appUser: .constant(.init(uid: "123", email: "test@test.com")))
}
