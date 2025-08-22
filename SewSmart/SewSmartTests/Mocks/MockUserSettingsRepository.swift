import Foundation
@testable import SewSmart

class MockUserSettingsRepository: UserSettingsRepositoryProtocol {
    private var userSettings = UserSettings()
    private var historyEntries: [UserHistory] = []
    
    var shouldThrowError = false
    var errorToThrow: Error = MockError.testError
    
    // Tracking calls for verification
    var fetchUserSettingsCalled = false
    var updateMeasurementUnitCalled = false
    var updateLengthUnitCalled = false
    var setDefaultMeasurementProfileCalled = false
    var addHistoryCalled = false
    var getRecentHistoryCalled = false
    var clearHistoryCalled = false
    
    var lastMeasurementUnit: MeasurementUnit?
    var lastLengthUnit: LengthUnit?
    var lastDefaultProfile: String?
    var lastHistoryEntry: (action: HistoryAction, details: String, context: HistoryContext)?
    
    func fetchUserSettings() async throws -> UserSettings {
        fetchUserSettingsCalled = true
        if shouldThrowError {
            throw errorToThrow
        }
        return userSettings
    }
    
    func updateMeasurementUnit(_ unit: MeasurementUnit) async throws {
        updateMeasurementUnitCalled = true
        lastMeasurementUnit = unit
        if shouldThrowError {
            throw errorToThrow
        }
        userSettings.preferredMeasurementUnit = unit
    }
    
    func updateLengthUnit(_ unit: LengthUnit) async throws {
        updateLengthUnitCalled = true
        lastLengthUnit = unit
        if shouldThrowError {
            throw errorToThrow
        }
        userSettings.preferredLengthUnit = unit
    }
    
    func setDefaultMeasurementProfile(_ profileName: String?) async throws {
        setDefaultMeasurementProfileCalled = true
        lastDefaultProfile = profileName
        if shouldThrowError {
            throw errorToThrow
        }
        userSettings.defaultMeasurementProfile = profileName
    }
    
    func addHistory(action: HistoryAction, details: String, context: HistoryContext) async throws {
        addHistoryCalled = true
        lastHistoryEntry = (action, details, context)
        if shouldThrowError {
            throw errorToThrow
        }
        
        let historyEntry = UserHistory(action: action, details: details, context: context)
        historyEntries.append(historyEntry)
        
        // Keep only last 100 entries
        if historyEntries.count > 100 {
            historyEntries = Array(historyEntries.suffix(100))
        }
    }
    
    func getRecentHistory(limit: Int = 20) async throws -> [UserHistory] {
        getRecentHistoryCalled = true
        if shouldThrowError {
            throw errorToThrow
        }
        return Array(historyEntries.suffix(limit))
    }
    
    func clearHistory() async throws {
        clearHistoryCalled = true
        if shouldThrowError {
            throw errorToThrow
        }
        historyEntries.removeAll()
    }
    
    // Test helpers
    func reset() {
        userSettings = UserSettings()
        historyEntries.removeAll()
        shouldThrowError = false
        
        fetchUserSettingsCalled = false
        updateMeasurementUnitCalled = false
        updateLengthUnitCalled = false
        setDefaultMeasurementProfileCalled = false
        addHistoryCalled = false
        getRecentHistoryCalled = false
        clearHistoryCalled = false
        
        lastMeasurementUnit = nil
        lastLengthUnit = nil
        lastDefaultProfile = nil
        lastHistoryEntry = nil
    }
    
    func setUserSettings(_ settings: UserSettings) {
        userSettings = settings
    }
    
    func addHistoryEntry(_ entry: UserHistory) {
        historyEntries.append(entry)
    }
}