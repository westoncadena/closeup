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
                // Handle both Google Sign In and Supabase email verification URLs
                if url.scheme?.contains("com.googleusercontent.apps") ?? false {
                    GIDSignIn.sharedInstance.handle(url)
                } else if url.scheme == "closeup" {
                    // Handle Supabase email verification
                    Task {
                        do {
                            let sessionUser = try await AuthManager.shared.getCurrentSession()
                            await MainActor.run {
                                self.appUser = sessionUser
                            }
                        } catch {
                            print("Error handling verification URL: \(error)")
                        }
                    }
                }
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
