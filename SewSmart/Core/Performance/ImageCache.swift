import Foundation
import UIKit
import os.log

/// High-performance image cache with memory management
actor ImageCache {
    static let shared = ImageCache()
    
    private let logger = Logger(subsystem: "com.sewsmart.performance", category: "ImageCache")
    private let memoryCache = NSCache<NSString, UIImage>()
    private let diskCache: DiskCache
    
    private init() {
        self.diskCache = DiskCache()
        // Defer isolated actor work to run on the actor executor
        Task { [weak self] in
            guard let self else { return }
            await self.configureMemoryCache()
            await self.observeMemoryWarnings()
        }
    }
    
    private func configureMemoryCache() {
        memoryCache.countLimit = 50 // Maximum 50 images in memory
        memoryCache.totalCostLimit = 50 * 1024 * 1024 // 50MB memory limit
    }
    
    private func observeMemoryWarnings() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                await self?.clearMemoryCache()
            }
        }
    }
    
    func image(for key: String) async -> UIImage? {
        // Check memory cache first
        if let cachedImage = memoryCache.object(forKey: key as NSString) {
            logger.debug("Memory cache hit for key: \(key)")
            return cachedImage
        }
        
        // Check disk cache
        if let diskImage = await diskCache.image(for: key) {
            logger.debug("Disk cache hit for key: \(key)")
            // Store in memory cache for faster future access
            let cost = Int(diskImage.size.width * diskImage.size.height * 4) // Rough bytes calculation
            memoryCache.setObject(diskImage, forKey: key as NSString, cost: cost)
            return diskImage
        }
        
        logger.debug("Cache miss for key: \(key)")
        return nil
    }
    
    func store(_ image: UIImage, for key: String) async {
        // Store in memory cache
        let cost = Int(image.size.width * image.size.height * 4)
        memoryCache.setObject(image, forKey: key as NSString, cost: cost)
        
        // Store in disk cache asynchronously
        await diskCache.store(image, for: key)
        
        let msg = "Stored image for key: \(key), size: \(image.size.debugDescription)"
        logger.debug("\(msg, privacy: .public)")
    }
    
    func removeImage(for key: String) async {
        memoryCache.removeObject(forKey: key as NSString)
        await diskCache.removeImage(for: key)
        logger.debug("Removed image for key: \(key)")
    }
    
    func clearMemoryCache() {
        memoryCache.removeAllObjects()
        logger.info("Cleared memory cache")
    }
    
    func clearAll() async {
        clearMemoryCache()
        await diskCache.clearAll()
        logger.info("Cleared all caches")
    }
}

/// Disk-based image cache for persistence
actor DiskCache {
    private let logger = Logger(subsystem: "com.sewsmart.performance", category: "DiskCache")
    private let cacheDirectory: URL
    
    init() {
        let documentsPath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        self.cacheDirectory = documentsPath.appendingPathComponent("SewSmartImageCache")
        
        // Create cache directory if needed
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    func image(for key: String) -> UIImage? {
        let fileURL = cacheDirectory.appendingPathComponent(key)
        
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            return nil
        }
        
        logger.debug("Loaded image from disk for key: \(key)")
        return image
    }
    
    func store(_ image: UIImage, for key: String) {
        let fileURL = cacheDirectory.appendingPathComponent(key)
        
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            logger.error("Failed to convert image to JPEG data for key: \(key)")
            return
        }
        
        do {
            try data.write(to: fileURL)
            logger.debug("Stored image to disk for key: \(key)")
        } catch {
            logger.error("Failed to write image to disk for key: \(key): \(error.localizedDescription)")
        }
    }
    
    func removeImage(for key: String) {
        let fileURL = cacheDirectory.appendingPathComponent(key)
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    func clearAll() {
        guard let contents = try? FileManager.default.contentsOfDirectory(at: cacheDirectory, 
                                                                          includingPropertiesForKeys: nil) else {
            return
        }
        
        for fileURL in contents {
            try? FileManager.default.removeItem(at: fileURL)
        }
        
        logger.info("Cleared disk cache")
    }
}