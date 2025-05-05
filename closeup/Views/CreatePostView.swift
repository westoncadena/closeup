import SwiftUI
import PhotosUI

struct CreatePostView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var postContent: String = ""
    @State private var selectedPostType: PostType = .thought
    @State private var selectedAudience: PostAudience = .innerCircle
    @State private var selectedPhotosItems: [PhotosPickerItem] = []
    @State private var selectedImagesData: [Data] = []
    @State private var isShowingImagePicker = false
    @State private var isPosting = false
    
    var promptText: String? = nil
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    if let prompt = promptText {
                        Text(prompt)
                            .font(.headline)
                            .padding(.vertical, 5)
                    }
                    
                    TextEditor(text: $postContent)
                        .frame(minHeight: 150)
                        .placeholder(when: postContent.isEmpty) {
                            Text("What's on your mind?")
                                .foregroundColor(.gray)
                                .padding(.top, 8)
                                .padding(.leading, 5)
                        }
                }
                
                // Selected images preview
                if !selectedImagesData.isEmpty {
                    Section {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(0..<selectedImagesData.count, id: \.self) { index in
                                    if let uiImage = UIImage(data: selectedImagesData[index]) {
                                        ZStack(alignment: .topTrailing) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 100, height: 100)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                            
                                            Button(action: {
                                                selectedImagesData.remove(at: index)
                                                selectedPhotosItems.remove(at: index)
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(.white)
                                                    .background(Color.black.opacity(0.7))
                                                    .clipShape(Circle())
                                            }
                                            .padding(5)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 5)
                        }
                    }
                }
                
                Section {
                    if promptText == nil {
                        Picker("Post Type", selection: $selectedPostType) {
                            Text("Thought").tag(PostType.thought)
                            Text("Daily Prompt").tag(PostType.dailyPrompt)
                            Text("Weekly Reflection").tag(PostType.weeklyReflection)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    Picker("Audience", selection: $selectedAudience) {
                        Text("Inner Circle").tag(PostAudience.innerCircle)
                        Text("Friends").tag(PostAudience.friends)
                        Text("Everyone").tag(PostAudience.everyone)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section {
                    Button(action: {
                        isShowingImagePicker = true
                    }) {
                        HStack {
                            Image(systemName: "photo.on.rectangle")
                            Text("Add Photos")
                        }
                    }
                }
            }
            .navigationTitle(promptText != nil ? "Respond to Prompt" : "New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Post") {
                        isPosting = true
                        // Process post creation
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            isPosting = false
                            dismiss()
                        }
                    }
                    .disabled(postContent.isEmpty || isPosting)
                    .opacity(postContent.isEmpty ? 0.6 : 1)
                }
            }
            .photosPicker(isPresented: $isShowingImagePicker, selection: $selectedPhotosItems, maxSelectionCount: 5, matching: .images)
            .onChange(of: selectedPhotosItems) { newItems in
                selectedImagesData = []
                
                for item in newItems {
                    Task {
                        if let data = try? await item.loadTransferable(type: Data.self) {
                            selectedImagesData.append(data)
                        }
                    }
                }
            }
            .overlay {
                if isPosting {
                    ProgressView("Posting...")
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 10)
                }
            }
        }
    }
}

struct CreatePostView_Previews: PreviewProvider {
    static var previews: some View {
        CreatePostView()
    }
}
