import Foundation
import SwiftData
import os.log

protocol FabricRepositoryProtocol: Sendable {
    func fetchAll() async throws -> [Fabric]
    func fetch(by id: UUID) async throws -> Fabric?
    func fetch(by type: FabricType) async throws -> [Fabric]
    func search(query: String) async throws -> [Fabric]
    func save(_ fabric: Fabric) async throws
    func delete(_ fabric: Fabric) async throws
    func update(_ fabric: Fabric) async throws
    func batchDelete(_ fabrics: [Fabric]) async throws
    func getTotalValue() async throws -> Double
    func getTotalYardage() async throws -> Double
}

actor FabricRepository: FabricRepositoryProtocol {
    private let modelContext: ModelContext
    private let logger = Logger(subsystem: "com.sewsmart.repository", category: "FabricRepository")
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func fetchAll() async throws -> [Fabric] {
        do {
            let fabrics = try modelContext.fetch(FetchDescriptor<Fabric>())
            let sorted = fabrics.sorted { $0.createdDate > $1.createdDate }
            logger.info("Successfully fetched \(sorted.count) fabrics")
            return sorted
        } catch {
            logger.error("Failed to fetch all fabrics: \(error.localizedDescription)")
            throw SewSmartError.dataCorruption
        }
    }
    
    func fetch(by id: UUID) async throws -> Fabric? {
        do {
            let all = try modelContext.fetch(FetchDescriptor<Fabric>())
            let fabric = all.first { $0.id == id }
            logger.info("Fetched fabric with ID: \(id)")
            return fabric
        } catch {
            logger.error("Failed to fetch fabric by ID \(id): \(error.localizedDescription)")
            throw SewSmartError.dataCorruption
        }
    }
    
    func fetch(by type: FabricType) async throws -> [Fabric] {
        do {
            let all = try modelContext.fetch(FetchDescriptor<Fabric>())
            let fabrics = all
                .filter { $0.type == type }
                .sorted { $0.createdDate > $1.createdDate }
//            logger.info("Fetched \(fabrics.count) fabrics with type: \(type)")
            return fabrics
        } catch {
//            logger.error("Failed to fetch fabrics by type \(type): \(error.localizedDescription)")
            throw SewSmartError.dataCorruption
        }
    }
    
    func search(query: String) async throws -> [Fabric] {
        do {
            let searchTerm = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard !searchTerm.isEmpty else { return [] }
            
            let all = try modelContext.fetch(FetchDescriptor<Fabric>())
            let fabrics = all.filter { fabric in
                fabric.name.lowercased().localizedStandardContains(searchTerm) ||
                fabric.notes.lowercased().localizedStandardContains(searchTerm) ||
                fabric.brand.lowercased().localizedStandardContains(searchTerm) ||
                fabric.color.lowercased().localizedStandardContains(searchTerm)
            }
            .sorted { $0.createdDate > $1.createdDate }
            
            logger.info("Search for '\(query)' returned \(fabrics.count) fabrics")
            return fabrics
        } catch {
            logger.error("Failed to search fabrics with query '\(query)': \(error.localizedDescription)")
            throw SewSmartError.dataCorruption
        }
    }
    
    func save(_ fabric: Fabric) async throws {
        do {
            modelContext.insert(fabric)
            try modelContext.save()
            logger.info("Successfully saved fabric: \(fabric.name)")
        } catch {
            logger.error("Failed to save fabric \(fabric.name): \(error.localizedDescription)")
            throw SewSmartError.dataStorageUnavailable
        }
    }
    
    func delete(_ fabric: Fabric) async throws {
        do {
            modelContext.delete(fabric)
            try modelContext.save()
            logger.info("Successfully deleted fabric: \(fabric.name)")
        } catch {
            logger.error("Failed to delete fabric \(fabric.name): \(error.localizedDescription)")
            throw SewSmartError.dataStorageUnavailable
        }
    }
    
    func update(_ fabric: Fabric) async throws {
        do {
            try modelContext.save()
            logger.info("Successfully updated fabric: \(fabric.name)")
        } catch {
            logger.error("Failed to update fabric \(fabric.name): \(error.localizedDescription)")
            throw SewSmartError.dataStorageUnavailable
        }
    }
    
    func batchDelete(_ fabrics: [Fabric]) async throws {
        do {
            for fabric in fabrics {
                modelContext.delete(fabric)
            }
            try modelContext.save()
            logger.info("Successfully batch deleted \(fabrics.count) fabrics")
        } catch {
            logger.error("Failed to batch delete fabrics: \(error.localizedDescription)")
            throw SewSmartError.dataStorageUnavailable
        }
    }
    
    func getTotalValue() async throws -> Double {
        do {
            let fabrics = try await fetchAll()
            let totalValue = fabrics.reduce(0) { $0 + $1.cost }
            logger.info("Calculated total fabric value: $\(totalValue)")
            return totalValue
        } catch {
            logger.error("Failed to calculate total fabric value: \(error.localizedDescription)")
            throw error
        }
    }
    
    func getTotalYardage() async throws -> Double {
        do {
            let fabrics = try await fetchAll()
            let totalYardage = fabrics.reduce(0) { $0 + $1.yardage }
            logger.info("Calculated total fabric yardage: \(totalYardage) yards")
            return totalYardage
        } catch {
            logger.error("Failed to calculate total fabric yardage: \(error.localizedDescription)")
            throw error
        }
    }
}
