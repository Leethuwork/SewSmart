import Testing
import SwiftData
import Foundation
@testable import SewSmart

@MainActor
struct UserSettingsRepositoryTests {
    
    private func createInMemoryModelContext() throws -> ModelContext {
        let schema = Schema([
            Project.self,
            Pattern.self,
            Fabric.self,
            MeasurementProfile.self,
            Measurement.self,
            ProjectPhoto.self,
            ShoppingList.self,
            ShoppingItem.self,
            UserSettings.self,
            UserHistory.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        return ModelContext(container)
    }
    
    @Test func testFetchUserSettingsCreatesNewIfNoneExist() async throws {
        let modelContext = try createInMemoryModelContext()
        let repository = UserSettingsRepository(modelContext: modelContext)
        
        let settings = try await repository.fetchUserSettings()
        
        #expect(settings.preferredMeasurementUnit == .inches)
        #expect(settings.preferredLengthUnit == .yards)
        #expect(settings.defaultMeasurementProfile == nil)
        #expect(settings.history.isEmpty)
    }
    
    @Test func testFetchUserSettingsReturnsCachedSettings() async throws {
        let modelContext = try createInMemoryModelContext()
        let repository = UserSettingsRepository(modelContext: modelContext)
        
        let settings1 = try await repository.fetchUserSettings()
        let settings2 = try await repository.fetchUserSettings()
        
        #expect(settings1.id == settings2.id)
    }
    
    @Test func testUpdateMeasurementUnit() async throws {
        let modelContext = try createInMemoryModelContext()
        let repository = UserSettingsRepository(modelContext: modelContext)
        
        try await repository.updateMeasurementUnit(.centimeters)
        let settings = try await repository.fetchUserSettings()
        
        #expect(settings.preferredMeasurementUnit == .centimeters)
    }
    
    @Test func testUpdateLengthUnit() async throws {
        let modelContext = try createInMemoryModelContext()
        let repository = UserSettingsRepository(modelContext: modelContext)
        
        try await repository.updateLengthUnit(.meters)
        let settings = try await repository.fetchUserSettings()
        
        #expect(settings.preferredLengthUnit == .meters)
    }
    
    @Test func testSetDefaultMeasurementProfile() async throws {
        let modelContext = try createInMemoryModelContext()
        let repository = UserSettingsRepository(modelContext: modelContext)
        
        try await repository.setDefaultMeasurementProfile("Test Profile")
        let settings = try await repository.fetchUserSettings()
        
        #expect(settings.defaultMeasurementProfile == "Test Profile")
    }
    
    @Test func testAddHistory() async throws {
        let modelContext = try createInMemoryModelContext()
        let repository = UserSettingsRepository(modelContext: modelContext)
        
        try await repository.addHistory(
            action: .createdProject,
            details: "Test Project",
            context: .projects
        )
        
        let settings = try await repository.fetchUserSettings()
        
        #expect(settings.history.count == 1)
        #expect(settings.history.first?.action == .createdProject)
        #expect(settings.history.first?.details == "Test Project")
        #expect(settings.history.first?.context == .projects)
    }
    
    @Test func testAddHistoryKeepsOnlyLast100Entries() async throws {
        let modelContext = try createInMemoryModelContext()
        let repository = UserSettingsRepository(modelContext: modelContext)
        
        // Add 105 history entries
        for i in 1...105 {
            try await repository.addHistory(
                action: .createdProject,
                details: "Project \(i)",
                context: .projects
            )
        }
        
        let settings = try await repository.fetchUserSettings()
        
        #expect(settings.history.count == 100)
        
        // Should have the most recent 100 entries
        let recentHistory = try await repository.getRecentHistory(limit: 100)
        #expect(recentHistory.count == 100)
        #expect(recentHistory.first?.details == "Project 105")
    }
    
    @Test func testGetRecentHistory() async throws {
        let modelContext = try createInMemoryModelContext()
        let repository = UserSettingsRepository(modelContext: modelContext)
        
        // Add several history entries
        for i in 1...10 {
            try await repository.addHistory(
                action: .createdProject,
                details: "Project \(i)",
                context: .projects
            )
        }
        
        let recentHistory = try await repository.getRecentHistory(limit: 5)
        
        #expect(recentHistory.count == 5)
        #expect(recentHistory.first?.details == "Project 10") // Most recent first
    }
    
    @Test func testGetRecentHistoryDefaultLimit() async throws {
        let modelContext = try createInMemoryModelContext()
        let repository = UserSettingsRepository(modelContext: modelContext)
        
        // Add 25 history entries
        for i in 1...25 {
            try await repository.addHistory(
                action: .createdProject,
                details: "Project \(i)",
                context: .projects
            )
        }
        
        let recentHistory = try await repository.getRecentHistory() // Default limit 20
        
        #expect(recentHistory.count == 20)
        #expect(recentHistory.first?.details == "Project 25")
    }
    
    @Test func testClearHistory() async throws {
        let modelContext = try createInMemoryModelContext()
        let repository = UserSettingsRepository(modelContext: modelContext)
        
        // Add some history entries
        try await repository.addHistory(
            action: .createdProject,
            details: "Project 1",
            context: .projects
        )
        try await repository.addHistory(
            action: .addedFabric,
            details: "Fabric 1",
            context: .fabric
        )
        
        var settings = try await repository.fetchUserSettings()
        #expect(settings.history.count == 2)
        
        // Clear history
        try await repository.clearHistory()
        
        settings = try await repository.fetchUserSettings()
        #expect(settings.history.isEmpty)
    }
    
    @Test func testMultipleHistoryActions() async throws {
        let modelContext = try createInMemoryModelContext()
        let repository = UserSettingsRepository(modelContext: modelContext)
        
        try await repository.addHistory(
            action: .createdProject,
            details: "Test Project",
            context: .projects
        )
        
        try await repository.addHistory(
            action: .addedFabric,
            details: "Cotton Fabric",
            context: .fabric
        )
        
        try await repository.addHistory(
            action: .addedPattern,
            details: "Dress Pattern",
            context: .patterns
        )
        
        let recentHistory = try await repository.getRecentHistory()
        
        #expect(recentHistory.count == 3)
        #expect(recentHistory[0].action == .addedPattern)
        #expect(recentHistory[1].action == .addedFabric)
        #expect(recentHistory[2].action == .createdProject)
    }
    
    @Test func testUpdateLastModifiedOnSettingsChanges() async throws {
        let modelContext = try createInMemoryModelContext()
        let repository = UserSettingsRepository(modelContext: modelContext)
        
        let initialSettings = try await repository.fetchUserSettings()
        let initialModified = initialSettings.lastModified
        
        // Wait a moment to ensure timestamp changes
        try await Task.sleep(for: .milliseconds(10))
        
        try await repository.updateMeasurementUnit(.centimeters)
        let updatedSettings = try await repository.fetchUserSettings()
        
        #expect(updatedSettings.lastModified > initialModified)
    }
}