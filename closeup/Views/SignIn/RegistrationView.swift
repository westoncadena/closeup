//
//  RegistrationView.swift
//  closeup
//
//  Created by Weston Cadena on 5/17/25.
//

import SwiftUI

struct RegistrationView: View {
    @EnvironmentObject var viewModel: SignInViewModel
    
    @State var email: String = ""
    @State var password: String = ""
    
    var body: some View {
        VStack {
            VStack(spacing:10){
                AppTextField(placeholder: "Email Address", text: $email)
                
                AppSecureField(placeholder: "Password", text: $password)
            }
            .padding(.horizontal, 24)
            
            Button {
                print("Registering...")
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
    RegistrationView()
        .environmentObject(SignInViewModel())
}
