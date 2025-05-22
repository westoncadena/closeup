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
    @State private var isLoading: Bool = true

    var body: some Scene {
        WindowGroup {
            Group {
                if isLoading {
                    ProgressView()
                } else {
                    ContentView(appUser: $appUser)
                }
            }
            .onOpenURL { url in
                GIDSignIn.sharedInstance.handle(url)
            }
            .task {
                await checkSession()
            }
        }
    }

    private func checkSession() async {
        defer { isLoading = false }
        do {
            let sessionUser = try await AuthManager.shared.getCurrentSession()
            await MainActor.run {
                self.appUser = sessionUser
            }
        } catch {
            await MainActor.run {
                self.appUser = nil
            }
        }
    }
}
