import Foundation
@testable import SewSmart

class MockPatternRepository: PatternRepositoryProtocol {
    private var patterns: [Pattern] = []
    var shouldThrowError = false
    var errorToThrow: Error = MockError.testError
    
    // Tracking calls for verification
    var fetchAllCalled = false
    var fetchByIdCalled = false
    var fetchByCategoryCalled = false
    var fetchByDifficultyCalled = false
    var saveCalled = false
    var deleteCalled = false
    var updateCalled = false
    
    var lastSavedPattern: Pattern?
    var lastDeletedPattern: Pattern?
    var lastUpdatedPattern: Pattern?
    var lastCategoryFilter: PatternCategory?
    var lastDifficultyFilter: PatternDifficulty?
    
    func fetchAll() async throws -> [Pattern] {
        fetchAllCalled = true
        if shouldThrowError {
            throw errorToThrow
        }
        return patterns.sorted { $0.createdDate > $1.createdDate }
    }
    
    func fetch(by id: UUID) async throws -> Pattern? {
        fetchByIdCalled = true
        if shouldThrowError {
            throw errorToThrow
        }
        return patterns.first { $0.id == id }
    }
    
    func fetch(by category: PatternCategory) async throws -> [Pattern] {
        fetchByCategoryCalled = true
        lastCategoryFilter = category
        if shouldThrowError {
            throw errorToThrow
        }
        return patterns.filter { $0.category == category }.sorted { $0.createdDate > $1.createdDate }
    }
    
    func fetch(by difficulty: PatternDifficulty) async throws -> [Pattern] {
        fetchByDifficultyCalled = true
        lastDifficultyFilter = difficulty
        if shouldThrowError {
            throw errorToThrow
        }
        return patterns.filter { $0.difficulty == difficulty }.sorted { $0.createdDate > $1.createdDate }
    }
    
    func save(_ pattern: Pattern) async throws {
        saveCalled = true
        lastSavedPattern = pattern
        if shouldThrowError {
            throw errorToThrow
        }
        patterns.append(pattern)
    }
    
    func delete(_ pattern: Pattern) async throws {
        deleteCalled = true
        lastDeletedPattern = pattern
        if shouldThrowError {
            throw errorToThrow
        }
        patterns.removeAll { $0.id == pattern.id }
    }
    
    func update(_ pattern: Pattern) async throws {
        updateCalled = true
        lastUpdatedPattern = pattern
        if shouldThrowError {
            throw errorToThrow
        }
    }
    
    // Test helpers
    func addPattern(_ pattern: Pattern) {
        patterns.append(pattern)
    }
    
    func removeAll() {
        patterns.removeAll()
    }
    
    func reset() {
        patterns.removeAll()
        shouldThrowError = false
        fetchAllCalled = false
        fetchByIdCalled = false
        fetchByCategoryCalled = false
        fetchByDifficultyCalled = false
        saveCalled = false
        deleteCalled = false
        updateCalled = false
        lastSavedPattern = nil
        lastDeletedPattern = nil
        lastUpdatedPattern = nil
        lastCategoryFilter = nil
        lastDifficultyFilter = nil
    }
}