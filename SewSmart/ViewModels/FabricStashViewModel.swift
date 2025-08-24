import SwiftUI
import SwiftData

@Observable
final class FabricStashViewModel {
    var showingAddFabric: Bool = false
    var selectedFabric: Fabric?
    var searchText: String = ""
    var selectedType: FabricType?
    
    private let modelContext: ModelContext
    private var settingsManager: UserSettingsManager?
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        setupSettingsManager()
    }
    
    private func setupSettingsManager() {
        settingsManager = UserSettingsManager(modelContext: modelContext)
    }
    
    func filteredFabrics(from fabrics: [Fabric]) -> [Fabric] {
        var filtered = fabrics
        
        if !searchText.isEmpty {
            filtered = filtered.filter { fabric in
                fabric.name.localizedCaseInsensitiveContains(searchText) ||
                fabric.color.localizedCaseInsensitiveContains(searchText) ||
                fabric.brand.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        if let type = selectedType {
            filtered = filtered.filter { $0.type == type }
        }
        
        return filtered
    }
    
    func showAddFabric() {
        showingAddFabric = true
    }
    
    func hideAddFabric() {
        showingAddFabric = false
    }
    
    func selectFabric(_ fabric: Fabric) {
        selectedFabric = fabric
    }
    
    func deselectFabric() {
        selectedFabric = nil
    }
    
    func selectType(_ type: FabricType?) {
        selectedType = selectedType == type ? nil : type
    }
    
    func clearFilters() {
        searchText = ""
        selectedType = nil
    }
    
    var hasActiveFilters: Bool {
        !searchText.isEmpty || selectedType != nil
    }
    
    func deleteFabric(_ fabric: Fabric) {
        modelContext.delete(fabric)
        
        do {
            try modelContext.save()
            settingsManager?.addHistory(
                action: .deletedFabric,
                details: fabric.name,
                context: .fabrics
            )
        } catch {
            // Handle error silently for now
        }
    }
    
    func deleteFabrics(at offsets: IndexSet, from fabrics: [Fabric]) {
        for index in offsets {
            deleteFabric(fabrics[index])
        }
    }
    
    func colorForType(_ type: FabricType) -> Color {
        switch type {
        case .cotton: return DesignSystem.primaryTeal
        case .silk: return DesignSystem.primaryPurple
        case .wool: return DesignSystem.primaryOrange
        case .linen: return DesignSystem.primaryYellow
        case .polyester: return DesignSystem.primaryPink
        case .rayon: return DesignSystem.primaryTeal
        case .denim: return .blue
        case .jersey: return DesignSystem.primaryPurple
        case .fleece: return DesignSystem.primaryOrange
        case .other: return .gray
        }
    }
    
    func getEmptyStateConfiguration() -> EmptyStateConfiguration {
        EmptyStateConfiguration(
            emoji: "🧵",
            title: "No Fabrics Yet",
            subtitle: "Build your fabric collection!",
            emojiSize: 64
        )
    }
    
    func getFilteredEmptyStateConfiguration() -> EmptyStateConfiguration {
        EmptyStateConfiguration(
            emoji: "🔍",
            title: "No Matching Fabrics",
            subtitle: "Try adjusting your search or filters",
            emojiSize: 64
        )
    }
}