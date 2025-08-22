import Testing
import SwiftData
import Foundation
@testable import SewSmart

@MainActor
struct PatternRepositoryTests {
    
    private func createInMemoryModelContext() throws -> ModelContext {
        let schema = Schema([
            Project.self,
            Pattern.self,
            Fabric.self,
            MeasurementProfile.self,
            Measurement.self,
            ProjectPhoto.self,
            ShoppingList.self,
            ShoppingItem.self,
            UserSettings.self,
            UserHistory.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        return ModelContext(container)
    }
    
    @Test func testFetchAllPatternsEmpty() async throws {
        let modelContext = try createInMemoryModelContext()
        let repository = PatternRepository(modelContext: modelContext)
        
        let patterns = try await repository.fetchAll()
        
        #expect(patterns.isEmpty)
    }
    
    @Test func testSaveAndFetchPattern() async throws {
        let modelContext = try createInMemoryModelContext()
        let repository = PatternRepository(modelContext: modelContext)
        
        let pattern = Pattern(name: "Test Pattern", brand: "Test Brand", category: .dress, difficulty: .beginner)
        
        try await repository.save(pattern)
        let fetchedPatterns = try await repository.fetchAll()
        
        #expect(fetchedPatterns.count == 1)
        #expect(fetchedPatterns[0].name == "Test Pattern")
        #expect(fetchedPatterns[0].brand == "Test Brand")
        #expect(fetchedPatterns[0].category == .dress)
        #expect(fetchedPatterns[0].difficulty == .beginner)
    }
    
    @Test func testFetchPatternById() async throws {
        let modelContext = try createInMemoryModelContext()
        let repository = PatternRepository(modelContext: modelContext)
        
        let pattern = Pattern(name: "Test Pattern", brand: "Test Brand", category: .dress, difficulty: .beginner)
        let patternId = pattern.id
        
        try await repository.save(pattern)
        let fetchedPattern = try await repository.fetch(by: patternId)
        
        #expect(fetchedPattern != nil)
        #expect(fetchedPattern?.name == "Test Pattern")
        #expect(fetchedPattern?.id == patternId)
    }
    
    @Test func testFetchPatternByIdNotFound() async throws {
        let modelContext = try createInMemoryModelContext()
        let repository = PatternRepository(modelContext: modelContext)
        
        let nonExistentId = UUID()
        let fetchedPattern = try await repository.fetch(by: nonExistentId)
        
        #expect(fetchedPattern == nil)
    }
    
    @Test func testFetchPatternsByCategory() async throws {
        let modelContext = try createInMemoryModelContext()
        let repository = PatternRepository(modelContext: modelContext)
        
        let dressPattern1 = Pattern(name: "Dress 1", category: .dress, difficulty: .beginner)
        let topPattern = Pattern(name: "Top 1", category: .top, difficulty: .intermediate)
        let dressPattern2 = Pattern(name: "Dress 2", category: .dress, difficulty: .advanced)
        
        try await repository.save(dressPattern1)
        try await repository.save(topPattern)
        try await repository.save(dressPattern2)
        
        let dressPatterns = try await repository.fetch(by: .dress)
        let topPatterns = try await repository.fetch(by: .top)
        let skirtPatterns = try await repository.fetch(by: .skirt)
        
        #expect(dressPatterns.count == 2)
        #expect(topPatterns.count == 1)
        #expect(skirtPatterns.isEmpty)
        #expect(dressPatterns.contains { $0.name == "Dress 1" })
        #expect(dressPatterns.contains { $0.name == "Dress 2" })
        #expect(topPatterns.contains { $0.name == "Top 1" })
    }
    
    @Test func testFetchPatternsByDifficulty() async throws {
        let modelContext = try createInMemoryModelContext()
        let repository = PatternRepository(modelContext: modelContext)
        
        let beginnerPattern1 = Pattern(name: "Easy 1", category: .dress, difficulty: .beginner)
        let intermediatePattern = Pattern(name: "Medium 1", category: .top, difficulty: .intermediate)
        let beginnerPattern2 = Pattern(name: "Easy 2", category: .skirt, difficulty: .beginner)
        
        try await repository.save(beginnerPattern1)
        try await repository.save(intermediatePattern)
        try await repository.save(beginnerPattern2)
        
        let beginnerPatterns = try await repository.fetch(by: .beginner)
        let intermediatePatterns = try await repository.fetch(by: .intermediate)
        let expertPatterns = try await repository.fetch(by: .expert)
        
        #expect(beginnerPatterns.count == 2)
        #expect(intermediatePatterns.count == 1)
        #expect(expertPatterns.isEmpty)
        #expect(beginnerPatterns.contains { $0.name == "Easy 1" })
        #expect(beginnerPatterns.contains { $0.name == "Easy 2" })
        #expect(intermediatePatterns.contains { $0.name == "Medium 1" })
    }
    
    @Test func testUpdatePattern() async throws {
        let modelContext = try createInMemoryModelContext()
        let repository = PatternRepository(modelContext: modelContext)
        
        let pattern = Pattern(name: "Original Pattern", brand: "Original Brand", category: .dress, difficulty: .beginner)
        try await repository.save(pattern)
        
        // Update the pattern
        pattern.name = "Updated Pattern"
        pattern.brand = "Updated Brand"
        pattern.category = .top
        pattern.difficulty = .intermediate
        pattern.rating = 5
        pattern.notes = "Great pattern!"
        
        try await repository.update(pattern)
        
        // Fetch the updated pattern
        let fetchedPattern = try await repository.fetch(by: pattern.id)
        
        #expect(fetchedPattern?.name == "Updated Pattern")
        #expect(fetchedPattern?.brand == "Updated Brand")
        #expect(fetchedPattern?.category == .top)
        #expect(fetchedPattern?.difficulty == .intermediate)
        #expect(fetchedPattern?.rating == 5)
        #expect(fetchedPattern?.notes == "Great pattern!")
    }
    
    @Test func testDeletePattern() async throws {
        let modelContext = try createInMemoryModelContext()
        let repository = PatternRepository(modelContext: modelContext)
        
        let pattern1 = Pattern(name: "Pattern 1", category: .dress, difficulty: .beginner)
        let pattern2 = Pattern(name: "Pattern 2", category: .top, difficulty: .intermediate)
        
        try await repository.save(pattern1)
        try await repository.save(pattern2)
        
        // Verify both patterns exist
        let allPatterns = try await repository.fetchAll()
        #expect(allPatterns.count == 2)
        
        // Delete pattern1
        try await repository.delete(pattern1)
        
        // Verify only pattern2 remains
        let remainingPatterns = try await repository.fetchAll()
        #expect(remainingPatterns.count == 1)
        #expect(remainingPatterns[0].name == "Pattern 2")
    }
    
    @Test func testFetchAllPatternsSortedByCreatedDate() async throws {
        let modelContext = try createInMemoryModelContext()
        let repository = PatternRepository(modelContext: modelContext)
        
        let pattern1 = Pattern(name: "First Pattern", category: .dress, difficulty: .beginner)
        let pattern2 = Pattern(name: "Second Pattern", category: .top, difficulty: .intermediate)
        let pattern3 = Pattern(name: "Third Pattern", category: .skirt, difficulty: .advanced)
        
        // Save patterns with small delays to ensure different creation times
        try await repository.save(pattern1)
        try await Task.sleep(for: .milliseconds(10))
        
        try await repository.save(pattern2)
        try await Task.sleep(for: .milliseconds(10))
        
        try await repository.save(pattern3)
        
        let fetchedPatterns = try await repository.fetchAll()
        
        #expect(fetchedPatterns.count == 3)
        // Should be sorted by creation date in reverse order (newest first)
        #expect(fetchedPatterns[0].name == "Third Pattern")
        #expect(fetchedPatterns[1].name == "Second Pattern")
        #expect(fetchedPatterns[2].name == "First Pattern")
    }
    
    @Test func testPatternWithComplexData() async throws {
        let modelContext = try createInMemoryModelContext()
        let repository = PatternRepository(modelContext: modelContext)
        
        let pattern = Pattern(name: "Complex Pattern", brand: "Designer Brand", category: .jacket, difficulty: .expert)
        pattern.rating = 4
        pattern.notes = "This is a challenging but rewarding pattern"
        pattern.tags = "advanced,tailoring,structured"
        pattern.fileName = "pattern.pdf"
        pattern.fileType = .pdf
        
        try await repository.save(pattern)
        let fetchedPattern = try await repository.fetch(by: pattern.id)
        
        #expect(fetchedPattern?.name == "Complex Pattern")
        #expect(fetchedPattern?.brand == "Designer Brand")
        #expect(fetchedPattern?.category == .jacket)
        #expect(fetchedPattern?.difficulty == .expert)
        #expect(fetchedPattern?.rating == 4)
        #expect(fetchedPattern?.notes == "This is a challenging but rewarding pattern")
        #expect(fetchedPattern?.tags == "advanced,tailoring,structured")
        #expect(fetchedPattern?.fileName == "pattern.pdf")
        #expect(fetchedPattern?.fileType == .pdf)
    }
    
    @Test func testSaveMultiplePatterns() async throws {
        let modelContext = try createInMemoryModelContext()
        let repository = PatternRepository(modelContext: modelContext)
        
        let patterns = [
            Pattern(name: "Pattern A", category: .dress, difficulty: .beginner),
            Pattern(name: "Pattern B", category: .top, difficulty: .intermediate),
            Pattern(name: "Pattern C", category: .pants, difficulty: .advanced),
            Pattern(name: "Pattern D", category: .accessory, difficulty: .expert)
        ]
        
        for pattern in patterns {
            try await repository.save(pattern)
        }
        
        let fetchedPatterns = try await repository.fetchAll()
        #expect(fetchedPatterns.count == 4)
        
        let patternNames = Set(fetchedPatterns.map { $0.name })
        #expect(patternNames.contains("Pattern A"))
        #expect(patternNames.contains("Pattern B"))
        #expect(patternNames.contains("Pattern C"))
        #expect(patternNames.contains("Pattern D"))
    }
}