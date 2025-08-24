import Foundation
import Network
import SwiftUI
import os.log

/// Manages offline functionality and network connectivity
@Observable
class OfflineManager {
    static let shared = OfflineManager()
    
    // MARK: - Properties
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    private let logger = Logger(subsystem: "com.sewsmart.offline", category: "OfflineManager")
    
    private(set) var isConnected = false
    private(set) var connectionType: NetworkConnectionType = .unknown
    private(set) var pendingOperations: [OfflineOperation] = []
    private(set) var cacheStatus: CacheStatus = .idle
    
    // MARK: - Cache Management
    
    private let cacheDirectory: URL
    private let userDefaults = UserDefaults.standard
    
    // MARK: - Initialization
    
    private init() {
        // Create cache directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        cacheDirectory = documentsPath.appendingPathComponent("OfflineCache")
        
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        setupNetworkMonitoring()
        loadPendingOperations()
        
        logger.info("OfflineManager initialized")
    }
    
    // MARK: - Network Monitoring
    
    private func setupNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.handleNetworkChange(path)
            }
        }
        monitor.start(queue: queue)
    }
    
    private func handleNetworkChange(_ path: NWPath) {
        let wasConnected = isConnected
        isConnected = path.status == .satisfied
        
        // Determine connection type
        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .ethernet
        } else {
            connectionType = isConnected ? .unknown : .none
        }
        
        logger.info("Network status changed: \(self.isConnected ? "Connected" : "Disconnected") via \(self.connectionType.description)")
        
        // Process pending operations when reconnected
        if !wasConnected && isConnected {
            logger.info("Network reconnected, processing \(self.pendingOperations.count) pending operations")
            Task {
                await processPendingOperations()
            }
        }
        
        // Post notification for UI updates
        NotificationCenter.default.post(name: .networkStatusChanged, object: nil)
    }
    
    // MARK: - Offline Operations
    
    func queueOperation(_ operation: OfflineOperation) {
        pendingOperations.append(operation)
        savePendingOperations()
        logger.info("Queued offline operation: \(operation.type.rawValue) for \(operation.entityType)")
        
        // Try to process immediately if connected
        if isConnected {
            Task {
                await processPendingOperations()
            }
        }
    }
    
    @MainActor
    private func processPendingOperations() async {
        guard isConnected && !pendingOperations.isEmpty else { return }
        
        logger.info("Processing \(self.pendingOperations.count) pending operations")
        
        var completedOperations: [OfflineOperation] = []
        
        for operation in pendingOperations {
            do {
                try await processOperation(operation)
                completedOperations.append(operation)
                logger.info("Completed offline operation: \(operation.type.rawValue) for \(operation.entityType)")
            } catch {
                logger.error("Failed to process offline operation: \(error.localizedDescription)")
                // Keep operation in queue for retry
            }
        }
        
        // Remove completed operations
        pendingOperations.removeAll { operation in
            completedOperations.contains { $0.id == operation.id }
        }
        
        savePendingOperations()
        
        if !completedOperations.isEmpty {
            NotificationCenter.default.post(name: .offlineOperationsProcessed, object: completedOperations.count)
        }
    }
    
    private func processOperation(_ operation: OfflineOperation) async throws {
        // In a real app, this would sync with a backend server
        // For now, we'll simulate the sync process
        
        switch operation.type {
        case .create:
            logger.info("Syncing created \(operation.entityType) with server")
        case .update:
            logger.info("Syncing updated \(operation.entityType) with server")
        case .delete:
            logger.info("Syncing deleted \(operation.entityType) with server")
        }
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
    }
    
    // MARK: - Cache Management
    
    func cacheData<T: Codable>(_ data: [T], for key: String) async {
        cacheStatus = .writing
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let encodedData = try encoder.encode(data)
            
            let cacheFile = cacheDirectory.appendingPathComponent("\(key).json")
            try encodedData.write(to: cacheFile)
            
            // Store metadata
            let metadata = CacheMetadata(
                key: key,
                itemCount: data.count,
                lastUpdated: Date(),
                dataSize: encodedData.count
            )
            setCacheMetadata(metadata, for: key)
            
            cacheStatus = .idle
            logger.info("Cached \(data.count) items for key: \(key)")
            
        } catch {
            cacheStatus = .error
            logger.error("Failed to cache data for key \(key): \(error.localizedDescription)")
        }
    }
    
    func loadCachedData<T: Codable>(for key: String, as type: T.Type) async -> [T]? {
        cacheStatus = .reading
        
        do {
            let cacheFile = cacheDirectory.appendingPathComponent("\(key).json")
            let data = try Data(contentsOf: cacheFile)
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let items = try decoder.decode([T].self, from: data)
            
            cacheStatus = .idle
            logger.info("Loaded \(items.count) cached items for key: \(key)")
            return items
            
        } catch {
            cacheStatus = .idle
            logger.info("No cached data found for key: \(key)")
            return nil
        }
    }
    
    func clearCache(for key: String? = nil) {
        if let key = key {
            // Clear specific cache
            let cacheFile = cacheDirectory.appendingPathComponent("\(key).json")
            try? FileManager.default.removeItem(at: cacheFile)
            removeCacheMetadata(for: key)
            logger.info("Cleared cache for key: \(key)")
        } else {
            // Clear all cache
            try? FileManager.default.removeItem(at: cacheDirectory)
            try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
            userDefaults.removeObject(forKey: "CacheMetadata")
            logger.info("Cleared all cache data")
        }
    }
    
    // MARK: - Cache Metadata
    
    private func setCacheMetadata(_ metadata: CacheMetadata, for key: String) {
        var allMetadata = getCacheMetadata()
        allMetadata[key] = metadata
        
        if let encoded = try? JSONEncoder().encode(allMetadata) {
            userDefaults.set(encoded, forKey: "CacheMetadata")
        }
    }
    
    private func removeCacheMetadata(for key: String) {
        var allMetadata = getCacheMetadata()
        allMetadata.removeValue(forKey: key)
        
        if let encoded = try? JSONEncoder().encode(allMetadata) {
            userDefaults.set(encoded, forKey: "CacheMetadata")
        }
    }
    
    func getCacheMetadata() -> [String: CacheMetadata] {
        guard let data = userDefaults.data(forKey: "CacheMetadata"),
              let metadata = try? JSONDecoder().decode([String: CacheMetadata].self, from: data) else {
            return [:]
        }
        return metadata
    }
    
    func getCacheInfo() -> CacheInfo {
        let metadata = getCacheMetadata()
        let totalItems = metadata.values.reduce(0) { $0 + $1.itemCount }
        let totalSize = metadata.values.reduce(0) { $0 + $1.dataSize }
        let oldestUpdate = metadata.values.map { $0.lastUpdated }.min()
        
        return CacheInfo(
            totalCachedItems: totalItems,
            totalCacheSize: totalSize,
            cacheKeys: Array(metadata.keys),
            oldestCacheDate: oldestUpdate
        )
    }
    
    // MARK: - Persistence
    
    private func savePendingOperations() {
        if let encoded = try? JSONEncoder().encode(pendingOperations) {
            userDefaults.set(encoded, forKey: "PendingOperations")
        }
    }
    
    private func loadPendingOperations() {
        guard let data = userDefaults.data(forKey: "PendingOperations"),
              let operations = try? JSONDecoder().decode([OfflineOperation].self, from: data) else {
            return
        }
        
        pendingOperations = operations
        logger.info("Loaded \(operations.count) pending operations")
    }
    
    // MARK: - Public Interface
    
    var isOfflineCapable: Bool {
        return !getCacheMetadata().isEmpty
    }
    
    var connectionStatusText: String {
        if isConnected {
            return "Online (\(connectionType.description))"
        } else {
            return isOfflineCapable ? "Offline (cached data available)" : "Offline (no cached data)"
        }
    }
    
    var hasPendingOperations: Bool {
        return !pendingOperations.isEmpty
    }
}

// MARK: - Supporting Types

struct OfflineOperation: Codable, Identifiable {
    var id = UUID()
    let type: OperationType
    let entityType: String
    let entityId: String?
    let data: Data?
    let timestamp: Date
    
    enum OperationType: String, Codable {
        case create, update, delete
    }
}

struct CacheMetadata: Codable {
    let key: String
    let itemCount: Int
    let lastUpdated: Date
    let dataSize: Int
}

struct CacheInfo {
    let totalCachedItems: Int
    let totalCacheSize: Int
    let cacheKeys: [String]
    let oldestCacheDate: Date?
    
    var formattedCacheSize: String {
        let formatter = ByteCountFormatter()
        return formatter.string(fromByteCount: Int64(totalCacheSize))
    }
}

enum NetworkConnectionType {
    case none, wifi, cellular, ethernet, unknown
    
    var description: String {
        switch self {
        case .none: return "No Connection"
        case .wifi: return "Wi-Fi"
        case .cellular: return "Cellular"
        case .ethernet: return "Ethernet"
        case .unknown: return "Unknown"
        }
    }
}

enum CacheStatus {
    case idle, reading, writing, error
}

// MARK: - Notifications

extension Notification.Name {
    static let networkStatusChanged = Notification.Name("networkStatusChanged")
    static let offlineOperationsProcessed = Notification.Name("offlineOperationsProcessed")
}

// MARK: - View Extensions

extension View {
    func offlineCapable<T: Codable>(
        data: [T],
        cacheKey: String,
        loadAction: @escaping () async -> Void
    ) -> some View {
        self.onAppear {
            if !OfflineManager.shared.isConnected {
                Task {
                    if let cachedData = await OfflineManager.shared.loadCachedData(for: cacheKey, as: T.self),
                       !cachedData.isEmpty {
                        // Use cached data (would need to update the parent view)
                    } else {
                        // No cached data available
                        await loadAction()
                    }
                }
            } else {
                Task {
                    await loadAction()
                    // Cache the loaded data
                    await OfflineManager.shared.cacheData(data, for: cacheKey)
                }
            }
        }
    }
    
    func networkStatusIndicator() -> some View {
        HStack {
            Circle()
                .fill(OfflineManager.shared.isConnected ? .green : .red)
                .frame(width: 8, height: 8)
            
            Text(OfflineManager.shared.connectionStatusText)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}