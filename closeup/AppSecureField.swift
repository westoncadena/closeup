//
//  AppSecureField.swift
//  closeup
//
//  Created by Weston Cadena on 5/17/25.
//

import SwiftUI

struct AppSecureField: View {
    var placeholder: String
    @Binding var text: String
    
    var body: some View {
        SecureField(placeholder, text: $text)
            .padding()
            .overlay{
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color(uiColor: .secondaryLabel), lineWidth: 1)
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .padding(.horizontal, 24)
    }
}

#Preview {
    AppSecureField(placeholder: "Password", text: .constant(""))
}
