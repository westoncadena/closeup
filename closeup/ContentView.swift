//
//  ContentView.swift
//  closeup
//
//  Created by Weston Cadena on 5/9/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        SignInView(appUser: .constant(AppUser(uid: "123", email: "test@test.com")))
    }
}

#Preview {
    ContentView()
}
