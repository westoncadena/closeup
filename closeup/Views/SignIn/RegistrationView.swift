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

    @Binding var appUser: AppUser?
    
    var body: some View {
        VStack {
            VStack(spacing:10){
                AppTextField(placeholder: "Email Address", text: $email)
                
                AppSecureField(placeholder: "Password", text: $password)
            }
            .padding(.horizontal, 24)
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.top, 4)
            }
            
            Button {
                Task{
                    do {
                        let appUser = try await viewModel.registerNewUserWithEmail(email: email, password: password)
                        self.appUser = appUser
                        dismiss.callAsFunction()
                    } catch let error as SignInError {
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
    }
}

#Preview {
    RegistrationView(appUser: .constant(.init(uid: "123", email: "test@test.com")))
        .environmentObject(SignInViewModel())
}
