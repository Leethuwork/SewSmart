import Foundation
import SwiftData
import os.log

protocol UserSettingsRepositoryProtocol: Sendable {
    func fetchUserSettings() async throws -> UserSettings
    func updateMeasurementUnit(_ unit: MeasurementUnit) async throws
    func updateLengthUnit(_ unit: LengthUnit) async throws
    func setDefaultMeasurementProfile(_ profileName: String?) async throws
    func addHistory(action: HistoryAction, details: String, context: HistoryContext) async throws
    func getRecentHistory(limit: Int) async throws -> [UserHistory]
    func clearHistory() async throws
    func resetSettings() async throws
}

actor UserSettingsRepository: UserSettingsRepositoryProtocol {
    private let modelContext: ModelContext
    private let logger = Logger(subsystem: "com.sewsmart.repository", category: "UserSettingsRepository")
    private var cachedSettings: UserSettings?
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func fetchUserSettings() async throws -> UserSettings {
        do {
            if let cachedSettings = cachedSettings {
                logger.info("Using cached user settings")
                return cachedSettings
            }
            
            let descriptor = FetchDescriptor<UserSettings>()
            let settings = try modelContext.fetch(descriptor)
            
            if let existingSettings = settings.first {
                cachedSettings = existingSettings
                logger.info("Fetched existing user settings")
                return existingSettings
            }
            
            let newSettings = UserSettings()
            modelContext.insert(newSettings)
            try modelContext.save()
            cachedSettings = newSettings
            logger.info("Created new user settings")
            return newSettings
        } catch {
            logger.error("Failed to fetch user settings: \(error.localizedDescription)")
            throw SewSmartError.dataStorageUnavailable
        }
    }
    
    func updateMeasurementUnit(_ unit: MeasurementUnit) async throws {
        do {
            let settings = try await fetchUserSettings()
            settings.preferredMeasurementUnit = unit
            settings.updateLastModified()
            try modelContext.save()
            logger.info("Updated measurement unit to: \(unit.rawValue)")
        } catch {
            logger.error("Failed to update measurement unit: \(error.localizedDescription)")
            throw SewSmartError.dataStorageUnavailable
        }
    }
    
    func updateLengthUnit(_ unit: LengthUnit) async throws {
        do {
            let settings = try await fetchUserSettings()
            settings.preferredLengthUnit = unit
            settings.updateLastModified()
            try modelContext.save()
            logger.info("Updated length unit to: \(unit.rawValue)")
        } catch {
            logger.error("Failed to update length unit: \(error.localizedDescription)")
            throw SewSmartError.dataStorageUnavailable
        }
    }
    
    func setDefaultMeasurementProfile(_ profileName: String?) async throws {
        do {
            let settings = try await fetchUserSettings()
            settings.defaultMeasurementProfile = profileName
            settings.updateLastModified()
            try modelContext.save()
            logger.info("Set default measurement profile to: \(profileName ?? "None")")
        } catch {
            logger.error("Failed to set default measurement profile: \(error.localizedDescription)")
            throw SewSmartError.dataStorageUnavailable
        }
    }
    
    func addHistory(action: HistoryAction, details: String, context: HistoryContext) async throws {
        do {
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
            logger.info("Added history entry: \(action.rawValue) - \(details)")
        } catch {
            logger.error("Failed to add history entry: \(error.localizedDescription)")
            throw SewSmartError.dataStorageUnavailable
        }
    }
    
    func getRecentHistory(limit: Int = 20) async throws -> [UserHistory] {
        do {
            let settings = try await fetchUserSettings()
            let recentHistory = settings.history
                .sorted { $0.timestamp > $1.timestamp }
                .prefix(limit)
                .map { $0 }
            logger.info("Fetched \(recentHistory.count) recent history entries")
            return recentHistory
        } catch {
            logger.error("Failed to get recent history: \(error.localizedDescription)")
            throw error
        }
    }
    
    func clearHistory() async throws {
        do {
            let settings = try await fetchUserSettings()
            let historyCount = settings.history.count
            for entry in settings.history {
                modelContext.delete(entry)
            }
            settings.history.removeAll()
            try modelContext.save()
            logger.info("Cleared \(historyCount) history entries")
        } catch {
            logger.error("Failed to clear history: \(error.localizedDescription)")
            throw SewSmartError.dataStorageUnavailable
        }
    }
    
    func resetSettings() async throws {
        do {
            if let settings = cachedSettings {
                modelContext.delete(settings)
                cachedSettings = nil
            }
            
            let descriptor = FetchDescriptor<UserSettings>()
            let allSettings = try modelContext.fetch(descriptor)
            for setting in allSettings {
                modelContext.delete(setting)
            }
            
            try modelContext.save()
            logger.info("Reset all user settings")
        } catch {
            logger.error("Failed to reset settings: \(error.localizedDescription)")
            throw SewSmartError.dataStorageUnavailable
        }
    }
}