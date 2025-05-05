//
//  ViewExtensions.swift
//  closeup
//
//  Created by Weston Cadena on 5/4/25.
//

import SwiftUI

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

extension View {
    func createPostSheet(isPresented: Binding<Bool>, promptText: String? = nil) -> some View {
        self.sheet(isPresented: isPresented) {
            CreatePostView(promptText: promptText)
        }
    }
}
