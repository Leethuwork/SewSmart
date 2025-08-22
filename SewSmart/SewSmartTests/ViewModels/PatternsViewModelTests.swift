import Testing
import Foundation
@testable import SewSmart

@MainActor
struct PatternsViewModelTests {
    
    private func createMockRepositories() -> (MockPatternRepository, MockUserSettingsRepository) {
        let patternRepo = MockPatternRepository()
        let settingsRepo = MockUserSettingsRepository()
        return (patternRepo, settingsRepo)
    }
    
    private func createViewModel(
        patternRepo: MockPatternRepository = MockPatternRepository(),
        settingsRepo: MockUserSettingsRepository = MockUserSettingsRepository()
    ) -> PatternsViewModel {
        return PatternsViewModel(
            patternRepository: patternRepo,
            userSettingsRepository: settingsRepo
        )
    }

    @Test func testInitialState() async throws {
        let viewModel = createViewModel()
        
        #expect(viewModel.patterns.isEmpty)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.showingAddPattern == false)
        #expect(viewModel.selectedPattern == nil)
        #expect(viewModel.selectedCategory == nil)
        #expect(viewModel.selectedDifficulty == nil)
    }
    
    @Test func testLoadPatternsSuccess() async throws {
        let (patternRepo, settingsRepo) = createMockRepositories()
        let viewModel = createViewModel(patternRepo: patternRepo, settingsRepo: settingsRepo)
        
        let pattern1 = Pattern(name: "Test Pattern 1", category: .dress, difficulty: .beginner)
        let pattern2 = Pattern(name: "Test Pattern 2", category: .top, difficulty: .intermediate)
        patternRepo.addPattern(pattern1)
        patternRepo.addPattern(pattern2)
        
        await viewModel.loadPatterns()
        
        #expect(patternRepo.fetchAllCalled == true)
        #expect(viewModel.patterns.count == 2)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.patterns.contains { $0.name == "Test Pattern 1" })
        #expect(viewModel.patterns.contains { $0.name == "Test Pattern 2" })
    }
    
    @Test func testLoadPatternsFailure() async throws {
        let (patternRepo, settingsRepo) = createMockRepositories()
        let viewModel = createViewModel(patternRepo: patternRepo, settingsRepo: settingsRepo)
        
        patternRepo.shouldThrowError = true
        patternRepo.errorToThrow = MockError.networkError
        
        await viewModel.loadPatterns()
        
        #expect(patternRepo.fetchAllCalled == true)
        #expect(viewModel.patterns.isEmpty)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage?.contains("Network error") == true)
    }
    
    @Test func testCreatePatternSuccess() async throws {
        let (patternRepo, settingsRepo) = createMockRepositories()
        let viewModel = createViewModel(patternRepo: patternRepo, settingsRepo: settingsRepo)
        
        await viewModel.createPattern(
            name: "New Pattern",
            brand: "Test Brand",
            category: .dress,
            difficulty: .beginner
        )
        
        #expect(patternRepo.saveCalled == true)
        #expect(settingsRepo.addHistoryCalled == true)
        #expect(patternRepo.fetchAllCalled == true)
        #expect(patternRepo.lastSavedPattern?.name == "New Pattern")
        #expect(patternRepo.lastSavedPattern?.brand == "Test Brand")
        #expect(patternRepo.lastSavedPattern?.category == .dress)
        #expect(patternRepo.lastSavedPattern?.difficulty == .beginner)
    }
    
    @Test func testCreatePatternWithEmptyNameShouldNotCreate() async throws {
        let (patternRepo, settingsRepo) = createMockRepositories()
        let viewModel = createViewModel(patternRepo: patternRepo, settingsRepo: settingsRepo)
        
        await viewModel.createPattern(
            name: "",
            category: .dress,
            difficulty: .beginner
        )
        
        #expect(patternRepo.saveCalled == false)
        #expect(settingsRepo.addHistoryCalled == false)
    }
    
    @Test func testUpdatePatternSuccess() async throws {
        let (patternRepo, settingsRepo) = createMockRepositories()
        let viewModel = createViewModel(patternRepo: patternRepo, settingsRepo: settingsRepo)
        
        let pattern = Pattern(name: "Test Pattern", category: .dress, difficulty: .beginner)
        pattern.rating = 5
        
        await viewModel.updatePattern(pattern)
        
        #expect(patternRepo.updateCalled == true)
        #expect(patternRepo.lastUpdatedPattern?.id == pattern.id)
        #expect(patternRepo.fetchAllCalled == true)
    }
    
    @Test func testDeletePatternSuccess() async throws {
        let (patternRepo, settingsRepo) = createMockRepositories()
        let viewModel = createViewModel(patternRepo: patternRepo, settingsRepo: settingsRepo)
        
        let pattern = Pattern(name: "Test Pattern", category: .dress, difficulty: .beginner)
        
        await viewModel.deletePattern(pattern)
        
        #expect(patternRepo.deleteCalled == true)
        #expect(settingsRepo.addHistoryCalled == true)
        #expect(patternRepo.lastDeletedPattern?.id == pattern.id)
        #expect(settingsRepo.lastHistoryEntry?.action == .deletedPattern)
        #expect(settingsRepo.lastHistoryEntry?.details == "Test Pattern")
    }
    
    @Test func testFilterPatternsByCategory() async throws {
        let (patternRepo, settingsRepo) = createMockRepositories()
        let viewModel = createViewModel(patternRepo: patternRepo, settingsRepo: settingsRepo)
        
        let pattern1 = Pattern(name: "Dress Pattern", category: .dress, difficulty: .beginner)
        let pattern2 = Pattern(name: "Top Pattern", category: .top, difficulty: .intermediate)
        patternRepo.addPattern(pattern1)
        patternRepo.addPattern(pattern2)
        
        await viewModel.filterPatterns(by: .dress)
        
        #expect(viewModel.selectedCategory == .dress)
        #expect(viewModel.selectedDifficulty == nil)
        #expect(patternRepo.fetchByCategoryCalled == true)
        #expect(patternRepo.lastCategoryFilter == .dress)
    }
    
    @Test func testFilterPatternsByDifficulty() async throws {
        let (patternRepo, settingsRepo) = createMockRepositories()
        let viewModel = createViewModel(patternRepo: patternRepo, settingsRepo: settingsRepo)
        
        await viewModel.filterPatterns(by: .intermediate)
        
        #expect(viewModel.selectedDifficulty == .intermediate)
        #expect(viewModel.selectedCategory == nil)
        #expect(patternRepo.fetchByDifficultyCalled == true)
        #expect(patternRepo.lastDifficultyFilter == .intermediate)
    }
    
    @Test func testClearFilters() async throws {
        let (patternRepo, settingsRepo) = createMockRepositories()
        let viewModel = createViewModel(patternRepo: patternRepo, settingsRepo: settingsRepo)
        
        // Set some filters first
        await viewModel.filterPatterns(by: .dress)
        patternRepo.reset()
        
        // Clear filters
        await viewModel.clearFilters()
        
        #expect(viewModel.selectedCategory == nil)
        #expect(viewModel.selectedDifficulty == nil)
        #expect(patternRepo.fetchAllCalled == true)
    }
    
    @Test func testGetPatternsByCategory() async throws {
        let (patternRepo, settingsRepo) = createMockRepositories()
        let viewModel = createViewModel(patternRepo: patternRepo, settingsRepo: settingsRepo)
        
        let pattern1 = Pattern(name: "Dress Pattern 1", category: .dress, difficulty: .beginner)
        let pattern2 = Pattern(name: "Top Pattern", category: .top, difficulty: .intermediate)
        let pattern3 = Pattern(name: "Dress Pattern 2", category: .dress, difficulty: .advanced)
        
        patternRepo.addPattern(pattern1)
        patternRepo.addPattern(pattern2)
        patternRepo.addPattern(pattern3)
        
        await viewModel.loadPatterns()
        
        let dressPatterns = viewModel.getPatternsByCategory(.dress)
        let topPatterns = viewModel.getPatternsByCategory(.top)
        
        #expect(dressPatterns.count == 2)
        #expect(topPatterns.count == 1)
        #expect(dressPatterns.contains { $0.name == "Dress Pattern 1" })
        #expect(dressPatterns.contains { $0.name == "Dress Pattern 2" })
        #expect(topPatterns.contains { $0.name == "Top Pattern" })
    }
    
    @Test func testGetPatternsByDifficulty() async throws {
        let (patternRepo, settingsRepo) = createMockRepositories()
        let viewModel = createViewModel(patternRepo: patternRepo, settingsRepo: settingsRepo)
        
        let pattern1 = Pattern(name: "Easy Pattern", category: .dress, difficulty: .beginner)
        let pattern2 = Pattern(name: "Medium Pattern", category: .top, difficulty: .intermediate)
        let pattern3 = Pattern(name: "Another Easy", category: .skirt, difficulty: .beginner)
        
        patternRepo.addPattern(pattern1)
        patternRepo.addPattern(pattern2)
        patternRepo.addPattern(pattern3)
        
        await viewModel.loadPatterns()
        
        let beginnerPatterns = viewModel.getPatternsByDifficulty(.beginner)
        let intermediatePatterns = viewModel.getPatternsByDifficulty(.intermediate)
        
        #expect(beginnerPatterns.count == 2)
        #expect(intermediatePatterns.count == 1)
        #expect(beginnerPatterns.contains { $0.name == "Easy Pattern" })
        #expect(beginnerPatterns.contains { $0.name == "Another Easy" })
        #expect(intermediatePatterns.contains { $0.name == "Medium Pattern" })
    }
    
    @Test func testGetCategoryDistribution() async throws {
        let (patternRepo, settingsRepo) = createMockRepositories()
        let viewModel = createViewModel(patternRepo: patternRepo, settingsRepo: settingsRepo)
        
        let pattern1 = Pattern(name: "Dress 1", category: .dress, difficulty: .beginner)
        let pattern2 = Pattern(name: "Top 1", category: .top, difficulty: .intermediate)
        let pattern3 = Pattern(name: "Dress 2", category: .dress, difficulty: .advanced)
        let pattern4 = Pattern(name: "Skirt 1", category: .skirt, difficulty: .beginner)
        
        patternRepo.addPattern(pattern1)
        patternRepo.addPattern(pattern2)
        patternRepo.addPattern(pattern3)
        patternRepo.addPattern(pattern4)
        
        await viewModel.loadPatterns()
        
        let distribution = viewModel.getCategoryDistribution()
        
        #expect(distribution[.dress] == 2)
        #expect(distribution[.top] == 1)
        #expect(distribution[.skirt] == 1)
        #expect(distribution[.pants] == 0)
    }
    
    @Test func testGetDifficultyDistribution() async throws {
        let (patternRepo, settingsRepo) = createMockRepositories()
        let viewModel = createViewModel(patternRepo: patternRepo, settingsRepo: settingsRepo)
        
        let pattern1 = Pattern(name: "Easy 1", category: .dress, difficulty: .beginner)
        let pattern2 = Pattern(name: "Medium 1", category: .top, difficulty: .intermediate)
        let pattern3 = Pattern(name: "Easy 2", category: .skirt, difficulty: .beginner)
        let pattern4 = Pattern(name: "Hard 1", category: .jacket, difficulty: .advanced)
        
        patternRepo.addPattern(pattern1)
        patternRepo.addPattern(pattern2)
        patternRepo.addPattern(pattern3)
        patternRepo.addPattern(pattern4)
        
        await viewModel.loadPatterns()
        
        let distribution = viewModel.getDifficultyDistribution()
        
        #expect(distribution[.beginner] == 2)
        #expect(distribution[.intermediate] == 1)
        #expect(distribution[.advanced] == 1)
        #expect(distribution[.expert] == 0)
    }
    
    @Test func testClearError() async throws {
        let (patternRepo, settingsRepo) = createMockRepositories()
        let viewModel = createViewModel(patternRepo: patternRepo, settingsRepo: settingsRepo)
        
        // Set an error
        patternRepo.shouldThrowError = true
        await viewModel.loadPatterns()
        #expect(viewModel.errorMessage != nil)
        
        // Clear the error
        viewModel.clearError()
        #expect(viewModel.errorMessage == nil)
    }
}