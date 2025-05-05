//
//  closeupApp.swift
//  closeup
//
//  Created by Weston Cadena on 5/2/25.
//

import SwiftUI

@main
struct CloseUpApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .preferredColorScheme(.light) // or .dark if you prefer
        }
    }
}
