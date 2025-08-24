import Foundation
import SwiftUI
import os.log

@MainActor
@Observable
class PatternsViewModel {
    private let patternRepository: PatternRepository
    private let userSettingsRepository: UserSettingsRepository
    private let logger = Logger(subsystem: "com.sewsmart.viewmodel", category: "PatternsViewModel")
    
    // State Management
    private(set) var patternsState: LoadingState<[Pattern]> = .idle
    private(set) var createPatternState: SimpleLoadingState = .idle
    private(set) var updatePatternState: SimpleLoadingState = .idle
    private(set) var deletePatternState: SimpleLoadingState = .idle
    
    // UI State
    var showingAddPattern = false
    var selectedPattern: Pattern?
    var selectedCategory: PatternCategory? = nil
    var selectedDifficulty: PatternDifficulty? = nil
    var searchText = ""
    
    // Computed properties for backward compatibility
    var patterns: [Pattern] {
        patternsState.data ?? []
    }
    
    var isLoading: Bool {
        patternsState.isLoading
    }
    
    var errorMessage: String? {
        patternsState.error?.localizedDescription
    }
    
    init(
        patternRepository: PatternRepository,
        userSettingsRepository: UserSettingsRepository
    ) {
        self.patternRepository = patternRepository
        self.userSettingsRepository = userSettingsRepository
        logger.info("Initialized PatternsViewModel with actor-based repositories")
    }
    
    func loadPatterns() async {
        patternsState.setLoading()
        
        do {
            let fetchedPatterns: [Pattern]
            
            if !searchText.isEmpty {
                fetchedPatterns = try await patternRepository.search(query: searchText)
            } else if let category = selectedCategory {
                fetchedPatterns = try await patternRepository.fetch(by: category)
            } else if let difficulty = selectedDifficulty {
                fetchedPatterns = try await patternRepository.fetch(by: difficulty)
            } else {
                fetchedPatterns = try await patternRepository.fetchAll()
            }
            
            patternsState.setLoaded(fetchedPatterns)
            logger.info("Loaded \(fetchedPatterns.count) patterns")
        } catch let error as SewSmartError {
            patternsState.setFailed(error)
            logger.error("Failed to load patterns: \(error.localizedDescription)")
        } catch {
            patternsState.setFailed(.dataCorruption)
            logger.error("Failed to load patterns: \(error.localizedDescription)")
        }
    }
    
    func createPattern(
        name: String,
        brand: String = "",
        category: PatternCategory,
        difficulty: PatternDifficulty
    ) async {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            createPatternState.setFailed(.invalidInput("Pattern name cannot be empty"))
            return
        }
        
        createPatternState.setLoading()
        
        let pattern = Pattern(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            brand: brand.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category,
            difficulty: difficulty
        )
        
        do {
            try await patternRepository.save(pattern)
            try await userSettingsRepository.addHistory(
                action: .addedPattern,
                details: "\(name) - \(category.rawValue)",
                context: .patterns
            )
            createPatternState.setSuccess()
            await loadPatterns()
            logger.info("Created pattern: \(name)")
        } catch let error as SewSmartError {
            createPatternState.setFailed(error)
            logger.error("Failed to create pattern: \(error.localizedDescription)")
        } catch {
            createPatternState.setFailed(.dataStorageUnavailable)
            logger.error("Failed to create pattern: \(error.localizedDescription)")
        }
    }
    
    func updatePattern(_ pattern: Pattern) async {
        updatePatternState.setLoading()
        
        do {
            try await patternRepository.update(pattern)
            updatePatternState.setSuccess()
            await loadPatterns()
            logger.info("Updated pattern: \(pattern.name)")
        } catch let error as SewSmartError {
            updatePatternState.setFailed(error)
            logger.error("Failed to update pattern: \(error.localizedDescription)")
        } catch {
            updatePatternState.setFailed(.dataStorageUnavailable)
            logger.error("Failed to update pattern: \(error.localizedDescription)")
        }
    }
    
    func deletePattern(_ pattern: Pattern) async {
        deletePatternState.setLoading()
        
        do {
            try await patternRepository.delete(pattern)
            try await userSettingsRepository.addHistory(
                action: .deletedPattern,
                details: pattern.name,
                context: .patterns
            )
            deletePatternState.setSuccess()
            await loadPatterns()
            logger.info("Deleted pattern: \(pattern.name)")
        } catch let error as SewSmartError {
            deletePatternState.setFailed(error)
            logger.error("Failed to delete pattern: \(error.localizedDescription)")
        } catch {
            deletePatternState.setFailed(.dataStorageUnavailable)
            logger.error("Failed to delete pattern: \(error.localizedDescription)")
        }
    }
    
    func filterPatterns(by category: PatternCategory?) async {
        selectedCategory = category
        selectedDifficulty = nil
        await loadPatterns()
    }
    
    func filterPatterns(by difficulty: PatternDifficulty?) async {
        selectedDifficulty = difficulty
        selectedCategory = nil
        await loadPatterns()
    }
    
    func clearFilters() async {
        selectedCategory = nil
        selectedDifficulty = nil
        await loadPatterns()
    }
    
    func getPatternsByCategory(_ category: PatternCategory) -> [Pattern] {
        return patterns.filter { $0.category == category }
    }
    
    func getPatternsByDifficulty(_ difficulty: PatternDifficulty) -> [Pattern] {
        return patterns.filter { $0.difficulty == difficulty }
    }
    
    func getCategoryDistribution() -> [PatternCategory: Int] {
        var distribution: [PatternCategory: Int] = [:]
        for category in PatternCategory.allCases {
            distribution[category] = patterns.filter { $0.category == category }.count
        }
        return distribution
    }
    
    func getDifficultyDistribution() -> [PatternDifficulty: Int] {
        var distribution: [PatternDifficulty: Int] = [:]
        for difficulty in PatternDifficulty.allCases {
            distribution[difficulty] = patterns.filter { $0.difficulty == difficulty }.count
        }
        return distribution
    }
    
    // State management methods
    func clearError() {
        if patternsState.isFailed {
            patternsState.setIdle()
        }
    }
    
    func clearCreatePatternState() {
        createPatternState.setIdle()
    }
    
    func clearUpdatePatternState() {
        updatePatternState.setIdle()
    }
    
    func clearDeletePatternState() {
        deletePatternState.setIdle()
    }
    
    func updateSearchText(_ text: String) {
        searchText = text
        Task {
            // Debounce search if needed
            try await Task.sleep(for: .milliseconds(300))
            if searchText == text { // Check if search text hasn't changed
                await loadPatterns()
            }
        }
    }
    
    // Memory cleanup
    deinit {
        logger.info("PatternsViewModel deinitialized")
    }
}