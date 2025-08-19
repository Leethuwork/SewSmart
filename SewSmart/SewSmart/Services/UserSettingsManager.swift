import Foundation
import SwiftData

@Observable
class UserSettingsManager {
    private var modelContext: ModelContext
    private var _userSettings: UserSettings?
    
    var userSettings: UserSettings {
        if let _userSettings = _userSettings {
            return _userSettings
        }
        
        // Try to fetch existing settings
        let descriptor = FetchDescriptor<UserSettings>()
        do {
            let settings = try modelContext.fetch(descriptor)
            if let existingSettings = settings.first {
                _userSettings = existingSettings
                return existingSettings
            }
        } catch {
            print("Error fetching user settings: \(error)")
        }
        
        // Create new settings if none exist
        let newSettings = UserSettings()
        modelContext.insert(newSettings)
        _userSettings = newSettings
        return newSettings
    }
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func updatePreferredMeasurementUnit(_ unit: MeasurementUnit) {
        let oldUnit = userSettings.preferredMeasurementUnit
        userSettings.preferredMeasurementUnit = unit
        userSettings.updateLastModified()
        
        addHistory(
            action: .changedMeasurementUnit,
            details: "From \(oldUnit.rawValue) to \(unit.rawValue)",
            context: .settings
        )
        
        try? modelContext.save()
    }
    
    func updatePreferredLengthUnit(_ unit: LengthUnit) {
        let oldUnit = userSettings.preferredLengthUnit
        userSettings.preferredLengthUnit = unit
        userSettings.updateLastModified()
        
        addHistory(
            action: .changedLengthUnit,
            details: "From \(oldUnit.rawValue) to \(unit.rawValue)",
            context: .settings
        )
        
        try? modelContext.save()
    }
    
    func setDefaultMeasurementProfile(_ profileName: String?) {
        let oldProfile = userSettings.defaultMeasurementProfile ?? "None"
        userSettings.defaultMeasurementProfile = profileName
        userSettings.updateLastModified()
        
        addHistory(
            action: .setDefaultProfile,
            details: "From \(oldProfile) to \(profileName ?? "None")",
            context: .settings
        )
        
        try? modelContext.save()
    }
    
    func addHistory(action: HistoryAction, details: String, context: HistoryContext) {
        let historyEntry = UserHistory(action: action, details: details, context: context)
        historyEntry.settings = userSettings
        userSettings.history.append(historyEntry)
        
        // Keep only last 100 history entries
        if userSettings.history.count > 100 {
            let sortedHistory = userSettings.history.sorted { $0.timestamp < $1.timestamp }
            let toRemove = sortedHistory.prefix(userSettings.history.count - 100)
            for entry in toRemove {
                modelContext.delete(entry)
            }
        }
    }
    
    func getRecentHistory(limit: Int = 20) -> [UserHistory] {
        return userSettings.history
            .sorted { $0.timestamp > $1.timestamp }
            .prefix(limit)
            .map { $0 }
    }
    
    func clearHistory() {
        for entry in userSettings.history {
            modelContext.delete(entry)
        }
        userSettings.history.removeAll()
        try? modelContext.save()
    }
}