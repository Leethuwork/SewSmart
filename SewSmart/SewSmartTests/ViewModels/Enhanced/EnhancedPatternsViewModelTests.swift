import XCTest
import SwiftData
@testable import SewSmart

@MainActor
final class EnhancedPatternsViewModelTests: XCTestCase {
    var viewModel: PatternsViewModel!
    var mockRepository: MockPatternRepository!
    var modelContext: ModelContext!
    var container: ModelContainer!
    
    @MainActor
    override func setUp() {
        super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try! ModelContainer(for: Pattern.self, configurations: config)
        modelContext = container.mainContext
        
        mockRepository = MockPatternRepository()
        viewModel = PatternsViewModel(repository: mockRepository)
    }
    
    override func tearDown() {
        viewModel = nil
        mockRepository = nil
        modelContext = nil
        container = nil
        super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func testInitialState() {
        XCTAssertEqual(viewModel.patternsState, .idle)
        XCTAssertEqual(viewModel.createPatternState, .idle)
        XCTAssertEqual(viewModel.updatePatternState, .idle)
        XCTAssertEqual(viewModel.deletePatternState, .idle)
        XCTAssertFalse(viewModel.showingAddPattern)
        XCTAssertNil(viewModel.selectedPattern)
        XCTAssertEqual(viewModel.searchText, "")
        XCTAssertNil(viewModel.selectedCategory)
        XCTAssertNil(viewModel.selectedDifficulty)
    }
    
    func testComputedProperties() {
        // Test empty state
        XCTAssertTrue(viewModel.patterns.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        
        // Test with loaded data
        let testPatterns = [
            Pattern(name: "Dress Pattern", type: .dress, difficulty: .intermediate, size: "M"),
            Pattern(name: "Shirt Pattern", type: .shirt, difficulty: .beginner, size: "L")
        ]
        viewModel.patternsState = .loaded(testPatterns)
        
        XCTAssertEqual(viewModel.patterns.count, 2)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    // MARK: - Load Patterns Tests
    
    func testLoadPatternsSuccess() async {
        let testPatterns = [
            Pattern(name: "Test Pattern", type: .dress, difficulty: .beginner, size: "S")
        ]
        mockRepository.mockPatterns = testPatterns
        
        await viewModel.loadPatterns()
        
        XCTAssertTrue(mockRepository.fetchAllCalled)
        XCTAssertEqual(viewModel.patternsState.data?.count, 1)
        XCTAssertEqual(viewModel.patterns.first?.name, "Test Pattern")
    }
    
    func testLoadPatternsWithType() async {
        let testPatterns = [
            Pattern(name: "Dress Pattern", type: .dress, difficulty: .intermediate, size: "M")
        ]
        mockRepository.mockPatternsByCategory = testPatterns
        viewModel.selectedCategory = .dress
        
        await viewModel.loadPatterns()
        
        XCTAssertTrue(mockRepository.fetchByCategoryCalled)
        XCTAssertEqual(viewModel.patterns.count, 1)
    }
    
    func testLoadPatternsWithSearch() async {
        let testPatterns = [
            Pattern(name: "Searched Pattern", type: .dress, difficulty: .beginner, size: "M")
        ]
        mockRepository.mockSearchResults = testPatterns
        viewModel.searchText = "Searched"
        
        await viewModel.loadPatterns()
        
        XCTAssertTrue(mockRepository.searchCalled)
        XCTAssertEqual(viewModel.patterns.count, 1)
    }
    
    func testLoadPatternsFailure() async {
        mockRepository.shouldFail = true
        
        await viewModel.loadPatterns()
        
        XCTAssertTrue(viewModel.patternsState.isFailed)
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    // MARK: - Create Pattern Tests
    
    func testCreatePatternSuccess() async {
        await viewModel.createPattern(
            name: "New Pattern",
            type: .dress,
            difficulty: .intermediate,
            size: "M",
            notes: "Test notes"
        )
        
        XCTAssertTrue(mockRepository.saveCalled)
        XCTAssertTrue(viewModel.createPatternState.isSuccess)
    }
    
    func testCreatePatternWithEmptyName() async {
        await viewModel.createPattern(
            name: "",
            type: .dress,
            difficulty: .beginner,
            size: "M",
            notes: ""
        )
        
        XCTAssertFalse(mockRepository.saveCalled)
        XCTAssertTrue(viewModel.createPatternState.isFailed)
    }
    
    func testCreatePatternWithWhitespaceOnlyName() async {
        await viewModel.createPattern(
            name: "   ",
            type: .dress,
            difficulty: .beginner,
            size: "M",
            notes: ""
        )
        
        XCTAssertFalse(mockRepository.saveCalled)
        XCTAssertTrue(viewModel.createPatternState.isFailed)
    }
    
    func testCreatePatternFailure() async {
        mockRepository.shouldFail = true
        
        await viewModel.createPattern(
            name: "Test Pattern",
            type: .dress,
            difficulty: .beginner,
            size: "M",
            notes: ""
        )
        
        XCTAssertTrue(viewModel.createPatternState.isFailed)
    }
    
    // MARK: - Update Pattern Tests
    
    func testUpdatePatternSuccess() async {
        let pattern = Pattern(name: "Test Pattern", type: .dress, difficulty: .beginner, size: "M")
        
        await viewModel.updatePattern(pattern)
        
        XCTAssertTrue(mockRepository.updateCalled)
        XCTAssertTrue(viewModel.updatePatternState.isSuccess)
    }
    
    func testUpdatePatternFailure() async {
        mockRepository.shouldFail = true
        let pattern = Pattern(name: "Test Pattern", type: .dress, difficulty: .beginner, size: "M")
        
        await viewModel.updatePattern(pattern)
        
        XCTAssertTrue(viewModel.updatePatternState.isFailed)
    }
    
    // MARK: - Delete Pattern Tests
    
    func testDeletePatternSuccess() async {
        let pattern = Pattern(name: "Test Pattern", type: .dress, difficulty: .beginner, size: "M")
        
        await viewModel.deletePattern(pattern)
        
        XCTAssertTrue(mockRepository.deleteCalled)
        XCTAssertTrue(viewModel.deletePatternState.isSuccess)
    }
    
    func testDeletePatternsAtOffsets() async {
        let patterns = [
            Pattern(name: "Pattern 1", type: .dress, difficulty: .beginner, size: "S"),
            Pattern(name: "Pattern 2", type: .shirt, difficulty: .intermediate, size: "M")
        ]
        viewModel.patternsState = .loaded(patterns)
        
        await viewModel.deletePatterns(at: IndexSet([0]))
        
        XCTAssertTrue(mockRepository.batchDeleteCalled)
        XCTAssertTrue(viewModel.deletePatternState.isSuccess)
    }
    
    // MARK: - State Management Tests
    
    func testClearStates() {
        viewModel.createPatternState = .failed(.dataCorruption)
        viewModel.updatePatternState = .failed(.dataCorruption)
        viewModel.deletePatternState = .failed(.dataCorruption)
        viewModel.patternsState = .failed(.dataCorruption)
        
        viewModel.clearCreatePatternState()
        viewModel.clearUpdatePatternState()
        viewModel.clearDeletePatternState()
        viewModel.clearError()
        
        XCTAssertEqual(viewModel.createPatternState, .idle)
        XCTAssertEqual(viewModel.updatePatternState, .idle)
        XCTAssertEqual(viewModel.deletePatternState, .idle)
        XCTAssertEqual(viewModel.patternsState, .idle)
    }
    
    func testSetSelectedType() {
        XCTAssertNil(viewModel.selectedCategory)
        XCTAssertNil(viewModel.selectedDifficulty)
        
        viewModel.setSelectedCategory(.dress)
        
        XCTAssertEqual(viewModel.selectedCategory, .dress)
    }
    
    func testUpdateSearchText() {
        XCTAssertEqual(viewModel.searchText, "")
        
        viewModel.updateSearchText("test search")
        
        XCTAssertEqual(viewModel.searchText, "test search")
    }
    
    func testClearFilters() {
        viewModel.selectedCategory = .dress
        viewModel.searchText = "test"
        
        viewModel.clearFilters()
        
        XCTAssertNil(viewModel.selectedCategory)
        XCTAssertNil(viewModel.selectedDifficulty)
        XCTAssertEqual(viewModel.searchText, "")
    }
    
    // MARK: - Business Logic Tests
    
    func testGetPatternsByType() {
        let patterns = [
            Pattern(name: "Dress Pattern", type: .dress, difficulty: .beginner, size: "S"),
            Pattern(name: "Shirt Pattern", type: .shirt, difficulty: .intermediate, size: "M"),
            Pattern(name: "Another Dress", type: .dress, difficulty: .advanced, size: "L")
        ]
        viewModel.patternsState = .loaded(patterns)
        
        let dressPatterns = viewModel.getPatternsByType(.dress)
        let shirtPatterns = viewModel.getPatternsByType(.shirt)
        
        XCTAssertEqual(dressPatterns.count, 2)
        XCTAssertEqual(shirtPatterns.count, 1)
        XCTAssertEqual(dressPatterns.first?.name, "Dress Pattern")
    }
    
    func testGetPatternsByDifficulty() {
        let patterns = [
            Pattern(name: "Easy Pattern", type: .dress, difficulty: .beginner, size: "S"),
            Pattern(name: "Medium Pattern", type: .shirt, difficulty: .intermediate, size: "M"),
            Pattern(name: "Hard Pattern", type: .pants, difficulty: .advanced, size: "L")
        ]
        viewModel.patternsState = .loaded(patterns)
        
        let beginnerPatterns = viewModel.getPatternsByDifficulty(.beginner)
        let intermediatePatterns = viewModel.getPatternsByDifficulty(.intermediate)
        let advancedPatterns = viewModel.getPatternsByDifficulty(.advanced)
        
        XCTAssertEqual(beginnerPatterns.count, 1)
        XCTAssertEqual(intermediatePatterns.count, 1)
        XCTAssertEqual(advancedPatterns.count, 1)
        XCTAssertEqual(beginnerPatterns.first?.name, "Easy Pattern")
    }
    
    func testGetPatternsGroupedByDifficulty() {
        let patterns = [
            Pattern(name: "Easy Pattern 1", type: .dress, difficulty: .beginner, size: "S"),
            Pattern(name: "Easy Pattern 2", type: .shirt, difficulty: .beginner, size: "M"),
            Pattern(name: "Medium Pattern", type: .pants, difficulty: .intermediate, size: "L")
        ]
        viewModel.patternsState = .loaded(patterns)
        
        let grouped = viewModel.getPatternsGroupedByDifficulty()
        
        XCTAssertEqual(grouped[.beginner]?.count, 2)
        XCTAssertEqual(grouped[.intermediate]?.count, 1)
        XCTAssertNil(grouped[.advanced])
    }
    
    func testGetCompletedPatternsCount() {
        let patterns = [
            Pattern(name: "Completed Pattern 1", type: .dress, difficulty: .beginner, size: "S"),
            Pattern(name: "Completed Pattern 2", type: .shirt, difficulty: .intermediate, size: "M"),
            Pattern(name: "Incomplete Pattern", type: .pants, difficulty: .advanced, size: "L")
        ]
        patterns[0].isCompleted = true
        patterns[1].isCompleted = true
        patterns[2].isCompleted = false
        viewModel.patternsState = .loaded(patterns)
        
        XCTAssertEqual(viewModel.getCompletedPatternsCount(), 2)
    }
    
    func testGetFavoritePatternsCount() {
        let patterns = [
            Pattern(name: "Favorite Pattern 1", type: .dress, difficulty: .beginner, size: "S"),
            Pattern(name: "Favorite Pattern 2", type: .shirt, difficulty: .intermediate, size: "M"),
            Pattern(name: "Regular Pattern", type: .pants, difficulty: .advanced, size: "L")
        ]
        patterns[0].isFavorite = true
        patterns[1].isFavorite = true
        patterns[2].isFavorite = false
        viewModel.patternsState = .loaded(patterns)
        
        XCTAssertEqual(viewModel.getFavoritePatternsCount(), 2)
    }
}