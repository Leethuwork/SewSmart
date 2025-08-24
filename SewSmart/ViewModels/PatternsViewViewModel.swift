import SwiftUI
import SwiftData

@Observable
final class PatternsViewViewModel {
    var showingAddPattern: Bool = false
    var selectedPattern: Pattern?
    var searchText: String = ""
    var selectedCategory: PatternCategory?
    
    private let modelContext: ModelContext
    private var settingsManager: UserSettingsManager?
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        setupSettingsManager()
    }
    
    private func setupSettingsManager() {
        settingsManager = UserSettingsManager(modelContext: modelContext)
    }
    
    func filteredPatterns(from patterns: [Pattern]) -> [Pattern] {
        var filtered = patterns
        
        if !searchText.isEmpty {
            filtered = filtered.filter { pattern in
                pattern.name.localizedCaseInsensitiveContains(searchText) ||
                pattern.brand.localizedCaseInsensitiveContains(searchText) ||
                pattern.tags.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        if let selectedCategory = selectedCategory {
            filtered = filtered.filter { $0.category == selectedCategory }
        }
        
        return filtered
    }
    
    func showAddPattern() {
        showingAddPattern = true
    }
    
    func hideAddPattern() {
        showingAddPattern = false
    }
    
    func selectPattern(_ pattern: Pattern) {
        selectedPattern = pattern
    }
    
    func deselectPattern() {
        selectedPattern = nil
    }
    
    func selectCategory(_ category: PatternCategory?) {
        selectedCategory = selectedCategory == category ? nil : category
    }
    
    func clearFilters() {
        searchText = ""
        selectedCategory = nil
    }
    
    var hasActiveFilters: Bool {
        !searchText.isEmpty || selectedCategory != nil
    }
    
    func deletePattern(_ pattern: Pattern) {
        modelContext.delete(pattern)
        
        do {
            try modelContext.save()
            settingsManager?.addHistory(
                action: .deletedPattern,
                details: pattern.name,
                context: .patterns
            )
        } catch {
            // Handle error silently for now
        }
    }
    
    func deletePatterns(at offsets: IndexSet, from patterns: [Pattern]) {
        for index in offsets {
            deletePattern(patterns[index])
        }
    }
    
    func categoryColor(for category: PatternCategory) -> Color {
        switch category {
        case .dress: return DesignSystem.primaryPink
        case .top: return DesignSystem.primaryOrange
        case .pants: return DesignSystem.primaryTeal
        case .skirt: return DesignSystem.primaryTeal
        case .jacket: return DesignSystem.primaryPurple
        case .accessory: return DesignSystem.primaryYellow
        case .other: return .gray
        }
    }
    
    func getEmptyStateConfiguration() -> EmptyStateConfiguration {
        EmptyStateConfiguration(
            emoji: "📄",
            title: "No Patterns Yet",
            subtitle: "Add your first sewing pattern! ✨",
            emojiSize: 64
        )
    }
    
    func getFilteredEmptyStateConfiguration() -> EmptyStateConfiguration {
        EmptyStateConfiguration(
            emoji: "🔍",
            title: "No Matching Patterns",
            subtitle: "Try adjusting your search or filters",
            emojiSize: 64
        )
    }
}

