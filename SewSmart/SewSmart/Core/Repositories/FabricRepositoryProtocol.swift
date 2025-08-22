import Foundation
import SwiftData

protocol FabricRepositoryProtocol {
    func fetchAll() async throws -> [Fabric]
    func fetch(by id: UUID) async throws -> Fabric?
    func fetch(by type: FabricType) async throws -> [Fabric]
    func save(_ fabric: Fabric) async throws
    func delete(_ fabric: Fabric) async throws
    func update(_ fabric: Fabric) async throws
    func getTotalValue() async throws -> Double
    func getTotalYardage() async throws -> Double
}

class FabricRepository: FabricRepositoryProtocol {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func fetchAll() async throws -> [Fabric] {
        let descriptor = FetchDescriptor<Fabric>(
            sortBy: [SortDescriptor(\.createdDate, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    func fetch(by id: UUID) async throws -> Fabric? {
        let descriptor = FetchDescriptor<Fabric>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }
    
    func fetch(by type: FabricType) async throws -> [Fabric] {
        let allFabrics = try await fetchAll()
        return allFabrics.filter { $0.type == type }
    }
    
    func save(_ fabric: Fabric) async throws {
        modelContext.insert(fabric)
        try modelContext.save()
    }
    
    func delete(_ fabric: Fabric) async throws {
        modelContext.delete(fabric)
        try modelContext.save()
    }
    
    func update(_ fabric: Fabric) async throws {
        try modelContext.save()
    }
    
    func getTotalValue() async throws -> Double {
        let fabrics = try await fetchAll()
        return fabrics.reduce(0) { $0 + $1.cost }
    }
    
    func getTotalYardage() async throws -> Double {
        let fabrics = try await fetchAll()
        return fabrics.reduce(0) { $0 + $1.yardage }
    }
}