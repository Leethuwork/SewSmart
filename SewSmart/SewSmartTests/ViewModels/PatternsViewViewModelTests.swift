import XCTest
import SwiftData
@testable import SewSmart

@MainActor
final class PatternsViewViewModelTests: XCTestCase {
    var viewModel: PatternsViewViewModel!
    var modelContext: ModelContext!
    var container: ModelContainer!
    var samplePatterns: [Pattern]!
    
    @MainActor
    override func setUp() {
        super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try! ModelContainer(for: Pattern.self, UserSettings.self, configurations: config)
        modelContext = container.mainContext
        viewModel = PatternsViewViewModel(modelContext: modelContext)
        setupSamplePatterns()
    }
    
    override func tearDown() {
        viewModel = nil
        modelContext = nil
        container = nil
        samplePatterns = nil
        super.tearDown()
    }
    
    private func setupSamplePatterns() {
        samplePatterns = [
            Pattern(name: "Summer Dress", brand: "Simplicity", category: .dress, difficulty: .beginner),
            Pattern(name: "Cotton Blouse", brand: "McCall's", category: .top, difficulty: .intermediate),
            Pattern(name: "Denim Jacket", brand: "Vogue", category: .jacket, difficulty: .advanced),
            Pattern(name: "Casual Pants", brand: "Butterick", category: .pants, difficulty: .beginner),
            Pattern(name: "Party Skirt", brand: "Simplicity", category: .skirt, difficulty: .intermediate)
        ]
        
        // Add tags to all patterns
        samplePatterns[0].tags = "summer, casual, cotton"
        samplePatterns[1].tags = "work, formal, silk"
        samplePatterns[2].tags = "outerwear, denim, casual"
        samplePatterns[3].tags = "everyday, basic, comfortable"
        samplePatterns[4].tags = "party, elegant, formal"
    }
    
    // MARK: - Initialization Tests
    
    func testInitialState() {
        XCTAssertFalse(viewModel.showingAddPattern)
        XCTAssertNil(viewModel.selectedPattern)
        XCTAssertEqual(viewModel.searchText, "")
        XCTAssertNil(viewModel.selectedCategory)
        XCTAssertFalse(viewModel.hasActiveFilters)
    }
    
    // MARK: - Pattern Display Tests
    
    func testShowAddPattern() {
        XCTAssertFalse(viewModel.showingAddPattern)
        viewModel.showAddPattern()
        XCTAssertTrue(viewModel.showingAddPattern)
    }
    
    func testHideAddPattern() {
        viewModel.showAddPattern()
        XCTAssertTrue(viewModel.showingAddPattern)
        viewModel.hideAddPattern()
        XCTAssertFalse(viewModel.showingAddPattern)
    }
    
    func testSelectPattern() {
        let pattern = samplePatterns[0]
        XCTAssertNil(viewModel.selectedPattern)
        viewModel.selectPattern(pattern)
        XCTAssertEqual(viewModel.selectedPattern, pattern)
    }
    
    func testDeselectPattern() {
        let pattern = samplePatterns[0]
        viewModel.selectPattern(pattern)
        XCTAssertNotNil(viewModel.selectedPattern)
        viewModel.deselectPattern()
        XCTAssertNil(viewModel.selectedPattern)
    }
    
    // MARK: - Filtering Tests
    
    func testFilteredPatterns_NoFilters() {
        let filtered = viewModel.filteredPatterns(from: samplePatterns)
        XCTAssertEqual(filtered.count, samplePatterns.count)
        XCTAssertEqual(filtered, samplePatterns)
    }
    
    func testFilteredPatterns_SearchByName() {
        viewModel.searchText = "dress"
        let filtered = viewModel.filteredPatterns(from: samplePatterns)
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.name, "Summer Dress")
    }
    
    func testFilteredPatterns_SearchByBrand() {
        viewModel.searchText = "simplicity"
        let filtered = viewModel.filteredPatterns(from: samplePatterns)
        XCTAssertEqual(filtered.count, 2) // Summer Dress and Party Skirt
        XCTAssertTrue(filtered.contains { $0.name == "Summer Dress" })
        XCTAssertTrue(filtered.contains { $0.name == "Party Skirt" })
    }
    
    func testFilteredPatterns_SearchByTags() {
        viewModel.searchText = "casual"
        let filtered = viewModel.filteredPatterns(from: samplePatterns)
        // Test that tags filtering works (expecting Summer Dress and Denim Jacket)
        XCTAssertGreaterThan(filtered.count, 0) // At least some patterns should match
        XCTAssertTrue(filtered.contains { $0.name == "Summer Dress" })
        XCTAssertTrue(filtered.contains { $0.name == "Denim Jacket" })
    }
    
    func testFilteredPatterns_SearchCaseInsensitive() {
        viewModel.searchText = "SUMMER"
        let filtered = viewModel.filteredPatterns(from: samplePatterns)
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.name, "Summer Dress")
    }
    
    func testFilteredPatterns_SearchNoResults() {
        viewModel.searchText = "nonexistent"
        let filtered = viewModel.filteredPatterns(from: samplePatterns)
        XCTAssertTrue(filtered.isEmpty)
    }
    
    func testFilteredPatterns_ByCategory() {
        viewModel.selectCategory(.dress)
        let filtered = viewModel.filteredPatterns(from: samplePatterns)
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.category, .dress)
    }
    
    func testFilteredPatterns_SearchAndCategory() {
        viewModel.searchText = "simplicity"
        viewModel.selectCategory(.dress)
        let filtered = viewModel.filteredPatterns(from: samplePatterns)
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.name, "Summer Dress")
    }
    
    // MARK: - Category Selection Tests
    
    func testSelectCategory() {
        XCTAssertNil(viewModel.selectedCategory)
        viewModel.selectCategory(.dress)
        XCTAssertEqual(viewModel.selectedCategory, .dress)
    }
    
    func testSelectCategory_ToggleOff() {
        viewModel.selectCategory(.dress)
        XCTAssertEqual(viewModel.selectedCategory, .dress)
        viewModel.selectCategory(.dress) // Select same category again
        XCTAssertNil(viewModel.selectedCategory) // Should toggle off
    }
    
    func testSelectCategory_ChangesCategory() {
        viewModel.selectCategory(.dress)
        XCTAssertEqual(viewModel.selectedCategory, .dress)
        viewModel.selectCategory(.top)
        XCTAssertEqual(viewModel.selectedCategory, .top)
    }
    
    // MARK: - Filter Management Tests
    
    func testHasActiveFilters_NoFilters() {
        XCTAssertFalse(viewModel.hasActiveFilters)
    }
    
    func testHasActiveFilters_WithSearchText() {
        viewModel.searchText = "test"
        XCTAssertTrue(viewModel.hasActiveFilters)
    }
    
    func testHasActiveFilters_WithCategory() {
        viewModel.selectCategory(.dress)
        XCTAssertTrue(viewModel.hasActiveFilters)
    }
    
    func testHasActiveFilters_WithBothFilters() {
        viewModel.searchText = "test"
        viewModel.selectCategory(.dress)
        XCTAssertTrue(viewModel.hasActiveFilters)
    }
    
    func testClearFilters() {
        viewModel.searchText = "test"
        viewModel.selectCategory(.dress)
        XCTAssertTrue(viewModel.hasActiveFilters)
        
        viewModel.clearFilters()
        
        XCTAssertEqual(viewModel.searchText, "")
        XCTAssertNil(viewModel.selectedCategory)
        XCTAssertFalse(viewModel.hasActiveFilters)
    }
    
    // MARK: - Pattern Deletion Tests
    
    func testDeletePattern() {
        let pattern = Pattern(name: "Test Pattern", category: .dress, difficulty: .beginner)
        modelContext.insert(pattern)
        
        do {
            try modelContext.save()
        } catch {
            XCTFail("Failed to save pattern: \(error)")
        }
        
        // Verify pattern exists
        let descriptor = FetchDescriptor<Pattern>()
        let patterns = try! modelContext.fetch(descriptor)
        XCTAssertEqual(patterns.count, 1)
        
        // Delete pattern
        viewModel.deletePattern(pattern)
        
        // Verify pattern is deleted
        let remainingPatterns = try! modelContext.fetch(descriptor)
        XCTAssertEqual(remainingPatterns.count, 0)
    }
    
    func testDeletePatterns_AtOffsets() {
        // Add sample patterns to context
        for pattern in samplePatterns {
            modelContext.insert(pattern)
        }
        
        do {
            try modelContext.save()
        } catch {
            XCTFail("Failed to save patterns: \(error)")
        }
        
        // Delete patterns at specific offsets
        let offsetsToDelete = IndexSet([0, 2]) // Delete first and third patterns
        viewModel.deletePatterns(at: offsetsToDelete, from: samplePatterns)
        
        // Verify correct patterns were deleted
        let descriptor = FetchDescriptor<Pattern>()
        let remainingPatterns = try! modelContext.fetch(descriptor)
        XCTAssertEqual(remainingPatterns.count, 3) // Should have 3 patterns left
    }
    
    // MARK: - Category Color Tests
    
    func testCategoryColor() {
        XCTAssertEqual(viewModel.categoryColor(for: .dress), DesignSystem.primaryPink)
        XCTAssertEqual(viewModel.categoryColor(for: .top), DesignSystem.primaryOrange)
        XCTAssertEqual(viewModel.categoryColor(for: .pants), DesignSystem.primaryTeal)
        XCTAssertEqual(viewModel.categoryColor(for: .skirt), DesignSystem.primaryTeal)
        XCTAssertEqual(viewModel.categoryColor(for: .jacket), DesignSystem.primaryPurple)
        XCTAssertEqual(viewModel.categoryColor(for: .accessory), DesignSystem.primaryYellow)
        XCTAssertEqual(viewModel.categoryColor(for: .other), .gray)
    }
    
    // MARK: - Empty State Configuration Tests
    
    func testGetEmptyStateConfiguration() {
        let config = viewModel.getEmptyStateConfiguration()
        XCTAssertEqual(config.emoji, "📄")
        XCTAssertEqual(config.title, "No Patterns Yet")
        XCTAssertEqual(config.subtitle, "Add your first sewing pattern! ✨")
        XCTAssertEqual(config.emojiSize, 64)
    }
    
    func testGetFilteredEmptyStateConfiguration() {
        let config = viewModel.getFilteredEmptyStateConfiguration()
        XCTAssertEqual(config.emoji, "🔍")
        XCTAssertEqual(config.title, "No Matching Patterns")
        XCTAssertEqual(config.subtitle, "Try adjusting your search or filters")
        XCTAssertEqual(config.emojiSize, 64)
    }
    
    // MARK: - Performance Tests
    
    func testFilteringPerformance() {
        // Create a large number of patterns
        var largePatternSet: [Pattern] = []
        for i in 0..<1000 {
            let pattern = Pattern(
                name: "Pattern \(i)",
                brand: "Brand \(i % 10)",
                category: PatternCategory.allCases[i % PatternCategory.allCases.count],
                difficulty: PatternDifficulty.allCases[i % PatternDifficulty.allCases.count]
            )
            pattern.tags = "tag\(i % 5), common, test"
            largePatternSet.append(pattern)
        }
        
        viewModel.searchText = "Pattern 5"
        
        measure {
            _ = viewModel.filteredPatterns(from: largePatternSet)
        }
    }
    
    func testCategoryFilteringPerformance() {
        // Create a large number of patterns
        var largePatternSet: [Pattern] = []
        for i in 0..<1000 {
            let pattern = Pattern(
                name: "Pattern \(i)",
                category: PatternCategory.allCases[i % PatternCategory.allCases.count],
                difficulty: .beginner
            )
            largePatternSet.append(pattern)
        }
        
        viewModel.selectCategory(.dress)
        
        measure {
            _ = viewModel.filteredPatterns(from: largePatternSet)
        }
    }
}