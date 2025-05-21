//
//  ProfileView.swift
//  closeup
//
//  Created by Weston Cadena on 5/21/25.
//

import SwiftUI

struct ProfileView: View {
    // Fake user data for now
    @State private var username: String = "westoncadena"
    @State private var bio: String = "iOS Developer. Traveler. Coffee Enthusiast."
    @State private var profileImage: Image = Image(systemName: "person.crop.circle.fill")
    @State private var posts: Int = 42
    @State private var followers: Int = 1280
    @State private var following: Int = 300

    var body: some View {
        VStack(spacing: 20) {
            profileImage
                .resizable()
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .padding(.top, 40)

            Text(username)
                .font(.title)
                .fontWeight(.bold)

            Text(bio)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            HStack(spacing: 40) {
                VStack {
                    Text("\(posts)")
                        .font(.headline)
                    Text("Posts")
                        .font(.caption)
                }
                VStack {
                    Text("\(followers)")
                        .font(.headline)
                    Text("Followers")
                        .font(.caption)
                }
                VStack {
                    Text("\(following)")
                        .font(.headline)
                    Text("Following")
                        .font(.caption)
                }
            }
            .padding(.top, 10)

            Spacer()
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ProfileView()
}
