//
//  RegistrationView.swift
//  closeup
//
//  Created by Weston Cadena on 5/17/25.
//

import SwiftUI

struct RegistrationView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: SignInViewModel
    
    @State var email: String = ""
    @State var password: String = ""
    @State var errorMessage: String?
    @State var showError: Bool = false
    @State var showVerificationAlert: Bool = false

    @Binding var appUser: AppUser?
    
    var body: some View {
        VStack {
            VStack(spacing: 10) {
                AppTextField(placeholder: "Email Address", text: $email)
                
                AppSecureField(placeholder: "Password", text: $password)
                
                Text(SignInViewModel.passwordRequirements)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 24)
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.top, 4)
                    .padding(.horizontal, 24)
            }
            
            Button {
                Task{
                    do {
                        let appUser = try await viewModel.registerNewUserWithEmail(email: email, password: password)
                        self.appUser = appUser
                        dismiss.callAsFunction()
                    } catch AuthError.emailVerificationRequired {
                        showVerificationAlert = true
                    } catch let error as AuthError {
                        errorMessage = error.message
                    } catch {
                        errorMessage = "An unexpected error occurred. Please try again."
                    }
                }
            } label: {
                Text("Register")
                    .padding()
                    .foregroundColor(Color(uiColor: .systemBackground))
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background{
                        RoundedRectangle(cornerRadius: 20, style: .continuous).foregroundColor(Color(uiColor: .label))
                    }
            }
            .padding(.top, 12)
            .padding(.horizontal, 24)
        }
        .alert("Verify Your Email", isPresented: $showVerificationAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Please check your inbox to verify your email. You can sign in after verification.")
        }
    }
}

#Preview {
    RegistrationView(appUser: .constant(.init(uid: "123", email: "test@test.com")))
        .environmentObject(SignInViewModel())
}
