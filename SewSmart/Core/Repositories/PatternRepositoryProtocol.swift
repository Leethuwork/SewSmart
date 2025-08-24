import Foundation
import SwiftData
import os.log

protocol PatternRepositoryProtocol: Sendable {
    func fetchAll() async throws -> [Pattern]
    func fetch(by id: UUID) async throws -> Pattern?
    func fetch(by category: PatternCategory) async throws -> [Pattern]
    func fetch(by difficulty: PatternDifficulty) async throws -> [Pattern]
    func search(query: String) async throws -> [Pattern]
    func save(_ pattern: Pattern) async throws
    func delete(_ pattern: Pattern) async throws
    func update(_ pattern: Pattern) async throws
    func batchDelete(_ patterns: [Pattern]) async throws
}

actor PatternRepository: PatternRepositoryProtocol {
    private let modelContext: ModelContext
    private let logger = Logger(subsystem: "com.sewsmart.repository", category: "PatternRepository")
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Fetch
    func fetchAll() async throws -> [Pattern] {
        do {
            let fetched = try modelContext.fetch(FetchDescriptor<Pattern>())
            logger.info("Fetched all patterns: \(fetched.count)")
            return fetched
        } catch {
            logger.error("fetchAll failed: \(error.localizedDescription)")
            throw SewSmartError.dataCorruption
        }
    }
    
    func fetch(by id: UUID) async throws -> Pattern? {
        do {
            let all = try modelContext.fetch(FetchDescriptor<Pattern>())
            return all.first { $0.id == id }
        } catch {
            logger.error("fetch(by:) failed: \(error.localizedDescription)")
            throw SewSmartError.dataCorruption
        }
    }
    
    func fetch(by category: PatternCategory) async throws -> [Pattern] {
        do {
            let all = try modelContext.fetch(FetchDescriptor<Pattern>())
            var results: [Pattern] = []
            results.reserveCapacity(all.count)
            for p in all where p.category == category {
                results.append(p)
            }
            return results
        } catch {
            logger.error("fetch(by category:) failed: \(error.localizedDescription)")
            throw SewSmartError.dataCorruption
        }
    }
    
    func fetch(by difficulty: PatternDifficulty) async throws -> [Pattern] {
        do {
            let all = try modelContext.fetch(FetchDescriptor<Pattern>())
            var results: [Pattern] = []
            results.reserveCapacity(all.count)
            for p in all where p.difficulty == difficulty {
                results.append(p)
            }
            return results
        } catch {
            logger.error("fetch(by difficulty:) failed: \(error.localizedDescription)")
            throw SewSmartError.dataCorruption
        }
    }
    
    // MARK: - Search
    func search(query: String) async throws -> [Pattern] {
        do {
            let term = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard !term.isEmpty else { return [] }
            let all = try modelContext.fetch(FetchDescriptor<Pattern>())
            var results: [Pattern] = []
            results.reserveCapacity(all.count)
            for p in all {
                if p.name.lowercased().localizedStandardContains(term) ||
                   p.notes.lowercased().localizedStandardContains(term) {
                    results.append(p)
                }
            }
            return results
        } catch {
            logger.error("search(query:) failed: \(error.localizedDescription)")
            throw SewSmartError.dataCorruption
        }
    }
    
    // MARK: - Mutations
    func save(_ pattern: Pattern) async throws {
        do {
            modelContext.insert(pattern)
            try modelContext.save()
            logger.info("Saved pattern: \(pattern.name)")
        } catch {
            logger.error("save failed: \(error.localizedDescription)")
            throw SewSmartError.dataStorageUnavailable
        }
    }
    
    func delete(_ pattern: Pattern) async throws {
        do {
            modelContext.delete(pattern)
            try modelContext.save()
            logger.info("Deleted pattern: \(pattern.name)")
        } catch {
            logger.error("delete failed: \(error.localizedDescription)")
            throw SewSmartError.dataStorageUnavailable
        }
    }
    
    func update(_ pattern: Pattern) async throws {
        do {
            try modelContext.save()
            logger.info("Updated pattern: \(pattern.name)")
        } catch {
            logger.error("update failed: \(error.localizedDescription)")
            throw SewSmartError.dataStorageUnavailable
        }
    }
    
    func batchDelete(_ patterns: [Pattern]) async throws {
        do {
            for p in patterns {
                modelContext.delete(p)
            }
            try modelContext.save()
            logger.info("Batch deleted \(patterns.count) patterns")
        } catch {
            logger.error("batchDelete failed: \(error.localizedDescription)")
            throw SewSmartError.dataStorageUnavailable
        }
    }
}