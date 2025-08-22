import Foundation
import SwiftData

protocol PatternRepositoryProtocol {
    func fetchAll() async throws -> [Pattern]
    func fetch(by id: UUID) async throws -> Pattern?
    func fetch(by category: PatternCategory) async throws -> [Pattern]
    func fetch(by difficulty: PatternDifficulty) async throws -> [Pattern]
    func save(_ pattern: Pattern) async throws
    func delete(_ pattern: Pattern) async throws
    func update(_ pattern: Pattern) async throws
}

class PatternRepository: PatternRepositoryProtocol {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func fetchAll() async throws -> [Pattern] {
        let descriptor = FetchDescriptor<Pattern>(
            sortBy: [SortDescriptor(\.createdDate, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    func fetch(by id: UUID) async throws -> Pattern? {
        let descriptor = FetchDescriptor<Pattern>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }
    
    func fetch(by category: PatternCategory) async throws -> [Pattern] {
        let allPatterns = try await fetchAll()
        return allPatterns.filter { $0.category == category }
    }
    
    func fetch(by difficulty: PatternDifficulty) async throws -> [Pattern] {
        let allPatterns = try await fetchAll()
        return allPatterns.filter { $0.difficulty == difficulty }
    }
    
    func save(_ pattern: Pattern) async throws {
        modelContext.insert(pattern)
        try modelContext.save()
    }
    
    func delete(_ pattern: Pattern) async throws {
        modelContext.delete(pattern)
        try modelContext.save()
    }
    
    func update(_ pattern: Pattern) async throws {
        try modelContext.save()
    }
}