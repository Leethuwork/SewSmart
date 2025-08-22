import SwiftUI
import SwiftData

@Observable
final class MeasurementsViewModel {
    var showingAddProfile: Bool = false
    var selectedProfile: MeasurementProfile?
    var searchText: String = ""
    
    private let modelContext: ModelContext
    private var settingsManager: UserSettingsManager?
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        setupSettingsManager()
    }
    
    private func setupSettingsManager() {
        settingsManager = UserSettingsManager(modelContext: modelContext)
    }
    
    func filteredProfiles(from profiles: [MeasurementProfile]) -> [MeasurementProfile] {
        guard !searchText.isEmpty else { return profiles }
        
        return profiles.filter { profile in
            profile.name.localizedCaseInsensitiveContains(searchText) ||
            profile.notes.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    func showAddProfile() {
        showingAddProfile = true
    }
    
    func hideAddProfile() {
        showingAddProfile = false
    }
    
    func selectProfile(_ profile: MeasurementProfile) {
        selectedProfile = profile
    }
    
    func deselectProfile() {
        selectedProfile = nil
    }
    
    func clearSearch() {
        searchText = ""
    }
    
    var hasActiveSearch: Bool {
        !searchText.isEmpty
    }
    
    func deleteProfile(_ profile: MeasurementProfile) {
        modelContext.delete(profile)
        
        do {
            try modelContext.save()
            settingsManager?.addHistory(
                action: .updatedMeasurement,
                details: "Deleted profile: \(profile.name)",
                context: .measurements
            )
        } catch {
            // Handle error silently for now
        }
    }
    
    func deleteProfiles(at offsets: IndexSet, from profiles: [MeasurementProfile]) {
        for index in offsets {
            deleteProfile(profiles[index])
        }
    }
    
    func getEmptyStateConfiguration() -> EmptyStateConfiguration {
        EmptyStateConfiguration(
            emoji: "📏",
            title: "No Profiles Yet",
            subtitle: "Create your first measurement profile!",
            emojiSize: 64
        )
    }
    
    func getFilteredEmptyStateConfiguration() -> EmptyStateConfiguration {
        EmptyStateConfiguration(
            emoji: "🔍",
            title: "No Matching Profiles",
            subtitle: "Try adjusting your search",
            emojiSize: 64
        )
    }
}