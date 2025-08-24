import Foundation
@testable import SewSmart

class MockPatternRepository: PatternRepositoryProtocol {
    private var patterns: [Pattern] = []
    var shouldThrowError = false
    var shouldFail = false
    var errorToThrow: Error = MockError.testError
    
    // Mock data for different scenarios
    var mockPatterns: [Pattern] = []
    var mockPatternsByCategory: [Pattern] = []
    var mockSearchResults: [Pattern] = []
    
    // Tracking calls for verification
    var fetchAllCalled = false
    var fetchByIdCalled = false
    var fetchByCategoryCalled = false
    var fetchByDifficultyCalled = false
    var searchCalled = false
    var saveCalled = false
    var deleteCalled = false
    var updateCalled = false
    var batchDeleteCalled = false
    
    var lastSavedPattern: Pattern?
    var lastDeletedPattern: Pattern?
    var lastUpdatedPattern: Pattern?
    var lastCategoryFilter: PatternCategory?
    var lastDifficultyFilter: PatternDifficulty?
    
    func fetchAll() async throws -> [Pattern] {
        fetchAllCalled = true
        if shouldThrowError || shouldFail {
            throw errorToThrow
        }
        return mockPatterns.isEmpty ? patterns.sorted { $0.createdDate > $1.createdDate } : mockPatterns
    }
    
    func fetch(by id: UUID) async throws -> Pattern? {
        fetchByIdCalled = true
        if shouldThrowError || shouldFail {
            throw errorToThrow
        }
        let allPatterns = mockPatterns.isEmpty ? patterns : mockPatterns
        return allPatterns.first { $0.id == id }
    }
    
    func fetch(by category: PatternCategory) async throws -> [Pattern] {
        fetchByCategoryCalled = true
        lastCategoryFilter = category
        if shouldThrowError || shouldFail {
            throw errorToThrow
        }
        return mockPatternsByCategory.isEmpty ? patterns.filter { $0.category == category }.sorted { $0.createdDate > $1.createdDate } : mockPatternsByCategory
    }
    
    func fetch(by difficulty: PatternDifficulty) async throws -> [Pattern] {
        fetchByDifficultyCalled = true
        lastDifficultyFilter = difficulty
        if shouldThrowError || shouldFail {
            throw errorToThrow
        }
        return patterns.filter { $0.difficulty == difficulty }.sorted { $0.createdDate > $1.createdDate }
    }
    
    func search(query: String) async throws -> [Pattern] {
        searchCalled = true
        if shouldThrowError || shouldFail {
            throw errorToThrow
        }
        if !mockSearchResults.isEmpty {
            return mockSearchResults
        }
        let searchTerm = query.lowercased()
        return patterns.filter { 
            $0.name.lowercased().contains(searchTerm) || 
            $0.patternDescription.lowercased().contains(searchTerm)
        }
    }
    
    func save(_ pattern: Pattern) async throws {
        saveCalled = true
        lastSavedPattern = pattern
        if shouldThrowError || shouldFail {
            throw errorToThrow
        }
        patterns.append(pattern)
    }
    
    func delete(_ pattern: Pattern) async throws {
        deleteCalled = true
        lastDeletedPattern = pattern
        if shouldThrowError || shouldFail {
            throw errorToThrow
        }
        patterns.removeAll { $0.id == pattern.id }
    }
    
    func update(_ pattern: Pattern) async throws {
        updateCalled = true
        lastUpdatedPattern = pattern
        if shouldThrowError || shouldFail {
            throw errorToThrow
        }
    }
    
    func batchDelete(_ patterns: [Pattern]) async throws {
        batchDeleteCalled = true
        if shouldThrowError || shouldFail {
            throw errorToThrow
        }
        for pattern in patterns {
            self.patterns.removeAll { $0.id == pattern.id }
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
        mockPatterns.removeAll()
        mockPatternsByCategory.removeAll()
        mockSearchResults.removeAll()
        shouldThrowError = false
        shouldFail = false
        fetchAllCalled = false
        fetchByIdCalled = false
        fetchByCategoryCalled = false
        fetchByDifficultyCalled = false
        searchCalled = false
        saveCalled = false
        deleteCalled = false
        updateCalled = false
        batchDeleteCalled = false
        lastSavedPattern = nil
        lastDeletedPattern = nil
        lastUpdatedPattern = nil
        lastCategoryFilter = nil
        lastDifficultyFilter = nil
    }
}