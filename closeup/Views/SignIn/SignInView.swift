//
//  SignInView.swift
//  closeup
//
//  Created by Weston Cadena on 5/9/25.
//

import SwiftUI

struct SignInView: View {
    @StateObject var viewModel = SignInViewModel()
    @Binding var appUser: AppUser?
    
    var body: some View {
        Button {
            Task {
                do {
                    let appUser = try await viewModel.signInWithGoogle()
                    self.appUser=appUser
                } catch {
                    // Handle error appropriately
                    print("Sign in failed: \(error)")
                }
            }
        } label: {
            Text("Sign in with Google")
                .foregroundColor(.black)
        }
    }
}

#Preview {
    SignInView(appUser: .constant(AppUser(uid: "123", email: "test@test.com")))
}
