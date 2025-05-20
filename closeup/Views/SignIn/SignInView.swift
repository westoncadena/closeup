//
//  SignInView.swift
//  closeup
//
//  Created by Weston Cadena on 5/9/25.
//

import SwiftUI

struct SignInView: View {
    @StateObject var viewModel = SignInViewModel()
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isRegistrationPresented: Bool = false
    
    @Binding var appUser: AppUser?
    
    var body: some View {
        VStack(spacing:30){
            VStack(spacing:10){
                AppTextField(placeholder: "Email Address", text: $email)
                
                AppSecureField(placeholder: "Password", text: $password)
            }
            .padding(.horizontal, 24)
            
            Button("New User? Register Here") {
                isRegistrationPresented.toggle()
            }
            .sheet(isPresented: $isRegistrationPresented){
                RegistrationView()
            }
            
            Button {
                print("Sign In")
            } label: {
                Text("Sign In")
                    .padding()
                    .foregroundColor(Color(uiColor: .systemBackground))
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background{
                        RoundedRectangle(cornerRadius: 20, style: .continuous).foregroundColor(Color(uiColor: .label))
                    }
            }.padding(.horizontal, 24)
            
            VStack(spacing:10){
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
                        .frame(maxWidth: .infinity)
                        .foregroundColor(Color(uiColor:.label))
                        .padding()
                        .overlay{
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color(uiColor:.label), lineWidth: 1)
                        }
                }
            }
            .padding(.horizontal, 24)
        }
    }
}

#Preview {
    SignInView(appUser: .constant(AppUser(uid: "123", email: "test@test.com")))
}
