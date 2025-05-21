//
//  closeupApp.swift
//  closeup
//
//  Created by Weston Cadena on 5/9/25.
//

import SwiftUI
import GoogleSignIn

@main
struct closeupApp: App {
    @State private var appUser: AppUser?
    
    var body: some Scene {
        WindowGroup {
            ContentView(appUser: $appUser)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
