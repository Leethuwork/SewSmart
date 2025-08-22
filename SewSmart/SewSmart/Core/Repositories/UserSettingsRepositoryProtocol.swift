import Foundation
import SwiftData

protocol UserSettingsRepositoryProtocol {
    func fetchUserSettings() async throws -> UserSettings
    func updateMeasurementUnit(_ unit: MeasurementUnit) async throws
    func updateLengthUnit(_ unit: LengthUnit) async throws
    func setDefaultMeasurementProfile(_ profileName: String?) async throws
    func addHistory(action: HistoryAction, details: String, context: HistoryContext) async throws
    func getRecentHistory(limit: Int) async throws -> [UserHistory]
    func clearHistory() async throws
}

class UserSettingsRepository: UserSettingsRepositoryProtocol {
    private let modelContext: ModelContext
    private var cachedSettings: UserSettings?
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func fetchUserSettings() async throws -> UserSettings {
        if let cachedSettings = cachedSettings {
            return cachedSettings
        }
        
        let descriptor = FetchDescriptor<UserSettings>()
        let settings = try modelContext.fetch(descriptor)
        
        if let existingSettings = settings.first {
            cachedSettings = existingSettings
            return existingSettings
        }
        
        let newSettings = UserSettings()
        modelContext.insert(newSettings)
        try modelContext.save()
        cachedSettings = newSettings
        return newSettings
    }
    
    func updateMeasurementUnit(_ unit: MeasurementUnit) async throws {
        let settings = try await fetchUserSettings()
        settings.preferredMeasurementUnit = unit
        settings.updateLastModified()
        try modelContext.save()
    }
    
    func updateLengthUnit(_ unit: LengthUnit) async throws {
        let settings = try await fetchUserSettings()
        settings.preferredLengthUnit = unit
        settings.updateLastModified()
        try modelContext.save()
    }
    
    func setDefaultMeasurementProfile(_ profileName: String?) async throws {
        let settings = try await fetchUserSettings()
        settings.defaultMeasurementProfile = profileName
        settings.updateLastModified()
        try modelContext.save()
    }
    
    func addHistory(action: HistoryAction, details: String, context: HistoryContext) async throws {
        let settings = try await fetchUserSettings()
        let historyEntry = UserHistory(action: action, details: details, context: context)
        historyEntry.settings = settings
        settings.history.append(historyEntry)
        
        // Keep only last 100 history entries
        if settings.history.count > 100 {
            let sortedHistory = settings.history.sorted { $0.timestamp < $1.timestamp }
            let toRemove = sortedHistory.prefix(settings.history.count - 100)
            for entry in toRemove {
                modelContext.delete(entry)
            }
        }
        
        try modelContext.save()
    }
    
    func getRecentHistory(limit: Int = 20) async throws -> [UserHistory] {
        let settings = try await fetchUserSettings()
        return settings.history
            .sorted { $0.timestamp > $1.timestamp }
            .prefix(limit)
            .map { $0 }
    }
    
    func clearHistory() async throws {
        let settings = try await fetchUserSettings()
        for entry in settings.history {
            modelContext.delete(entry)
        }
        settings.history.removeAll()
        try modelContext.save()
    }
}