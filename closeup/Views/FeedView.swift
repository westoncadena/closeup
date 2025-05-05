import SwiftUI

struct FeedView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showingCreatePost = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    if appState.postService.isLoading {
                        ProgressView("Loading posts...")
                            .padding()
                    } else if appState.postService.feedPosts.isEmpty {
                        emptyFeedView
                    } else {
                        ForEach(appState.postService.feedPosts) { post in
                            PostCardView(post: post)
                                .padding(.horizontal)
                                .environmentObject(appState)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Your Feed")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingCreatePost = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .refreshable {
                appState.postService.fetchFeedPosts()
            }
            .onAppear {
                if appState.postService.feedPosts.isEmpty {
                    appState.postService.fetchFeedPosts()
                }
            }
            .sheet(isPresented: $showingCreatePost) {
                CreatePostView()
                    .environmentObject(appState)
            }
        }
    }
    
    private var emptyFeedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 70))
                .foregroundColor(.gray.opacity(0.7))
                .padding(.bottom, 10)
                .padding(.top, 50)
            
            Text("Your feed is empty")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Start by creating a post or answering a prompt")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                showingCreatePost = true
            }) {
                Text("Create First Post")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 10)
            
            Spacer()
        }
        .padding()
        .frame(minHeight: 400)
    }
}

struct FeedView_Previews: PreviewProvider {
    static var previews: some View {
        FeedView()
            .environmentObject({
                let state = AppState()
                state.postService.feedPosts = [
                    Post(
                        author: User(name: "Alex Johnson", profileImage: "user1"),
                        postType: .dailyPrompt,
                        content: "What am I excited about today? Starting my new project!",
                        timestamp: Date().addingTimeInterval(-3600),
                        images: ["project1", "project2"]
                    )
                ]
                return state
            }())
    }
}
