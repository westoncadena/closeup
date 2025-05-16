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
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)

                }
        }
    }
}
