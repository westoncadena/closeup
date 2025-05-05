//
//  RootView.swift
//  closeup
//
//  Created by Weston Cadena on 5/4/25.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        Group {
            if appState.userService.isAuthenticated {
                ContentView()
            } else {
                LoginView()
            }
        }
    }
}
