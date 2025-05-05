//
//  ImageLoader.swift
//  closeup
//
//  Created by Weston Cadena on 5/4/25.
//


import Foundation
import Combine
import SwiftUI

// ImageLoader - Simple image caching
class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    private var cancellable: AnyCancellable?
    private var cache = NSCache<NSString, UIImage>()
    
    func loadImage(from urlString: String) {
        let cacheKey = NSString(string: urlString)
        
        // Check cache first
        if let cachedImage = cache.object(forKey: cacheKey) {
            self.image = cachedImage
            return
        }
        
        // If URL is actually a local asset name
        if let image = UIImage(named: urlString) {
            self.image = image
            cache.setObject(image, forKey: cacheKey)
            return
        }
        
        // Otherwise load from network
        guard let url = URL(string: urlString) else { return }
        
        cancellable = URLSession.shared.dataTaskPublisher(for: url)
            .map { UIImage(data: $0.data) }
            .replaceError(with: nil)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] image in
                guard let self = self, let image = image else { return }
                self.image = image
                self.cache.setObject(image, forKey: cacheKey)
            }
    }
    
    func cancel() {
        cancellable?.cancel()
    }
}

// AsyncImage replacement for loading images with caching
struct CachedAsyncImage<Content: View>: View {
    @StateObject private var loader = ImageLoader()
    private let urlString: String
    private let content: (Image?) -> Content
    
    init(urlString: String, @ViewBuilder content: @escaping (Image?) -> Content) {
        self.urlString = urlString
        self.content = content
    }
    
    var body: some View {
        content(loader.image.map(Image.init(uiImage:)))
            .onAppear {
                loader.loadImage(from: urlString)
            }
            .onDisappear {
                loader.cancel()
            }
    }
}
