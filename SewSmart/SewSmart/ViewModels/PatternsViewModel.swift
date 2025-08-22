import Foundation
import SwiftUI

@MainActor
@Observable
class PatternsViewModel {
    private let patternRepository: PatternRepositoryProtocol
    private let userSettingsRepository: UserSettingsRepositoryProtocol
    
    var patterns: [Pattern] = []
    var isLoading = false
    var errorMessage: String?
    var showingAddPattern = false
    var selectedPattern: Pattern?
    var selectedCategory: PatternCategory? = nil
    var selectedDifficulty: PatternDifficulty? = nil
    
    init(
        patternRepository: PatternRepositoryProtocol,
        userSettingsRepository: UserSettingsRepositoryProtocol
    ) {
        self.patternRepository = patternRepository
        self.userSettingsRepository = userSettingsRepository
    }
    
    func loadPatterns() async {
        isLoading = true
        errorMessage = nil
        
        do {
            if let category = selectedCategory {
                patterns = try await patternRepository.fetch(by: category)
            } else if let difficulty = selectedDifficulty {
                patterns = try await patternRepository.fetch(by: difficulty)
            } else {
                patterns = try await patternRepository.fetchAll()
            }
        } catch {
            errorMessage = "Failed to load patterns: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func createPattern(
        name: String,
        brand: String = "",
        category: PatternCategory,
        difficulty: PatternDifficulty
    ) async {
        guard !name.isEmpty else { return }
        
        let pattern = Pattern(
            name: name,
            brand: brand,
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
            await loadPatterns()
        } catch {
            errorMessage = "Failed to create pattern: \(error.localizedDescription)"
        }
    }
    
    func updatePattern(_ pattern: Pattern) async {
        do {
            try await patternRepository.update(pattern)
            await loadPatterns()
        } catch {
            errorMessage = "Failed to update pattern: \(error.localizedDescription)"
        }
    }
    
    func deletePattern(_ pattern: Pattern) async {
        do {
            try await patternRepository.delete(pattern)
            try await userSettingsRepository.addHistory(
                action: .deletedPattern,
                details: pattern.name,
                context: .patterns
            )
            await loadPatterns()
        } catch {
            errorMessage = "Failed to delete pattern: \(error.localizedDescription)"
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
    
    func clearError() {
        errorMessage = nil
    }
}