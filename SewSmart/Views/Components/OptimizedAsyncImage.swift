import SwiftUI
import UIKit

/// High-performance AsyncImage replacement with caching and optimization
struct OptimizedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    let targetSize: CGSize?
    let content: (Image) -> Content
    let placeholder: () -> Placeholder
    
    @State private var loadedImage: UIImage?
    @State private var isLoading = false
    @State private var loadingError: Error?
    
    init(
        url: URL?,
        targetSize: CGSize? = nil,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.targetSize = targetSize
        self.content = content
        self.placeholder = placeholder
    }
    
    var body: some View {
        Group {
            if let loadedImage = loadedImage {
                content(Image(uiImage: loadedImage))
            } else if isLoading {
                placeholder()
                    .overlay(
                        ProgressView()
                            .scaleEffect(0.5)
                    )
            } else if loadingError != nil {
                placeholder()
                    .overlay(
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                    )
            } else {
                placeholder()
            }
        }
        .task {
            await loadImage()
        }
        .onChange(of: url) { oldValue, newValue in
            if oldValue != newValue {
                loadedImage = nil
                loadingError = nil
                Task {
                    await loadImage()
                }
            }
        }
    }
    
    private func loadImage() async {
        guard let url = url else { return }
        
        isLoading = true
        loadingError = nil
        
        do {
            // Generate cache key
            let cacheKey = url.absoluteString.replacingOccurrences(of: "/", with: "_")
            
            // Check cache first
            if let cachedImage = await ImageCache.shared.image(for: cacheKey) {
                await MainActor.run {
                    self.loadedImage = cachedImage
                    self.isLoading = false
                }
                return
            }
            
            // Download image
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let image = UIImage(data: data) else {
                throw ImageLoadingError.invalidImageData
            }
            
            // Process image if target size specified
            let processedImage: UIImage
            if let targetSize = targetSize {
                processedImage = await ImageProcessor.shared.resizeImage(image, to: targetSize) ?? image
            } else {
                processedImage = image
            }
            
            // Cache the processed image
            await ImageCache.shared.store(processedImage, for: cacheKey)
            
            await MainActor.run {
                self.loadedImage = processedImage
                self.isLoading = false
            }
            
        } catch {
            await MainActor.run {
                self.loadingError = error
                self.isLoading = false
            }
        }
    }
}

// MARK: - Convenience Initializers

extension OptimizedAsyncImage where Content == Image {
    init(url: URL?, targetSize: CGSize? = nil) where Placeholder == AnyView {
        self.init(
            url: url,
            targetSize: targetSize,
            content: { $0.resizable() },
            placeholder: { 
                AnyView(
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                )
            }
        )
    }
}

extension OptimizedAsyncImage {
    init(
        url: URL?,
        targetSize: CGSize? = nil,
        @ViewBuilder content: @escaping (Image) -> Content
    ) where Placeholder == AnyView {
        self.init(
            url: url,
            targetSize: targetSize,
            content: content,
            placeholder: { 
                AnyView(
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                )
            }
        )
    }
}

// MARK: - Error Types

enum ImageLoadingError: LocalizedError {
    case invalidImageData
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidImageData:
            return "Invalid image data"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        OptimizedAsyncImage(
            url: URL(string: "https://via.placeholder.com/300x200"),
            targetSize: CGSize(width: 300, height: 200)
        ) { image in
            image
                .aspectRatio(contentMode: .fill)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        } placeholder: {
            RoundedRectangle(cornerRadius: 12)
                .fill(DesignSystem.primaryPink.opacity(0.3))
        }
        .frame(width: 300, height: 200)
        
        OptimizedAsyncImage(
            url: URL(string: "https://via.placeholder.com/150x150"),
            targetSize: CGSize(width: 150, height: 150)
        )
        .frame(width: 150, height: 150)
        .clipShape(Circle())
    }
    .padding()
}