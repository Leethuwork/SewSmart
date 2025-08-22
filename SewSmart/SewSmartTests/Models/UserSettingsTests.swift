import Testing
import Foundation
@testable import SewSmart

struct UserSettingsModelTests {
    
    @Test func testUserSettingsInitialization() {
        let settings = UserSettings()
        
        #expect(settings.preferredMeasurementUnit == .inches)
        #expect(settings.preferredLengthUnit == .yards)
        #expect(settings.defaultMeasurementProfile == nil)
        #expect(settings.history.isEmpty)
    }
    
    @Test func testUserSettingsIdUniqueness() {
        let settings1 = UserSettings()
        let settings2 = UserSettings()
        
        #expect(settings1.id != settings2.id)
    }
    
    @Test func testUserSettingsCreatedDateIsSet() {
        let beforeCreation = Date()
        let settings = UserSettings()
        let afterCreation = Date()
        
        #expect(settings.createdDate >= beforeCreation)
        #expect(settings.createdDate <= afterCreation)
        #expect(settings.lastModified >= beforeCreation)
        #expect(settings.lastModified <= afterCreation)
    }
    
    @Test func testUserSettingsPropertyModification() {
        let settings = UserSettings()
        
        settings.preferredMeasurementUnit = .centimeters
        settings.preferredLengthUnit = .meters
        settings.defaultMeasurementProfile = "My Profile"
        
        #expect(settings.preferredMeasurementUnit == .centimeters)
        #expect(settings.preferredLengthUnit == .meters)
        #expect(settings.defaultMeasurementProfile == "My Profile")
    }
    
    @Test func testUserSettingsUpdateLastModified() {
        let settings = UserSettings()
        let originalLastModified = settings.lastModified
        
        // Wait a brief moment to ensure timestamp changes
        Thread.sleep(forTimeInterval: 0.01)
        
        settings.updateLastModified()
        
        #expect(settings.lastModified > originalLastModified)
    }
    
    @Test func testUserSettingsWithHistory() {
        let settings = UserSettings()
        let history1 = UserHistory(action: .createdProject, details: "Test Project", context: .projects)
        let history2 = UserHistory(action: .addedFabric, details: "Cotton Fabric", context: .fabric)
        
        #expect(settings.history.isEmpty)
        
        // Add history items (Note: In real SwiftData usage, this would be managed by the context)
        settings.history.append(history1)
        settings.history.append(history2)
        history1.settings = settings
        history2.settings = settings
        
        #expect(settings.history.count == 2)
        #expect(settings.history.contains { $0.action == .createdProject })
        #expect(settings.history.contains { $0.action == .addedFabric })
    }
}

struct UserHistoryTests {
    
    @Test func testUserHistoryInitialization() {
        let history = UserHistory(
            action: .createdProject,
            details: "New Project Created",
            context: .projects
        )
        
        #expect(history.action == .createdProject)
        #expect(history.details == "New Project Created")
        #expect(history.context == .projects)
        #expect(history.settings == nil)
    }
    
    @Test func testUserHistoryIdUniqueness() {
        let history1 = UserHistory(action: .addedFabric, details: "Fabric 1", context: .fabric)
        let history2 = UserHistory(action: .addedFabric, details: "Fabric 2", context: .fabric)
        
        #expect(history1.id != history2.id)
    }
    
    @Test func testUserHistoryTimestampIsSet() {
        let beforeCreation = Date()
        let history = UserHistory(action: .addedPattern, details: "Test Pattern", context: .patterns)
        let afterCreation = Date()
        
        #expect(history.timestamp >= beforeCreation)
        #expect(history.timestamp <= afterCreation)
    }
    
    @Test func testUserHistoryWithSettings() {
        let settings = UserSettings()
        let history = UserHistory(action: .changedMeasurementUnit, details: "Changed to centimeters", context: .settings)
        
        #expect(history.settings == nil)
        
        history.settings = settings
        
        #expect(history.settings?.preferredMeasurementUnit == .inches) // Default value
    }
    
    @Test func testUserHistoryWithDifferentActions() {
        let projectHistory = UserHistory(action: .createdProject, details: "Project 1", context: .projects)
        let fabricHistory = UserHistory(action: .addedFabric, details: "Silk Fabric", context: .fabric)
        let patternHistory = UserHistory(action: .deletedPattern, details: "Old Pattern", context: .patterns)
        let settingsHistory = UserHistory(action: .setDefaultProfile, details: "Profile 1", context: .settings)
        
        #expect(projectHistory.action == .createdProject)
        #expect(fabricHistory.action == .addedFabric)
        #expect(patternHistory.action == .deletedPattern)
        #expect(settingsHistory.action == .setDefaultProfile)
    }
    
    @Test func testUserHistoryWithDifferentContexts() {
        let projectContext = UserHistory(action: .createdProject, details: "Project", context: .projects)
        let fabricContext = UserHistory(action: .addedFabric, details: "Fabric", context: .fabric)
        let patternsContext = UserHistory(action: .addedPattern, details: "Pattern", context: .patterns)
        let settingsContext = UserHistory(action: .changedMeasurementUnit, details: "Unit", context: .settings)
        let measurementsContext = UserHistory(action: .addedMeasurement, details: "Measurement", context: .measurements)
        
        #expect(projectContext.context == .projects)
        #expect(fabricContext.context == .fabric)
        #expect(patternsContext.context == .patterns)
        #expect(settingsContext.context == .settings)
        #expect(measurementsContext.context == .measurements)
    }
}

struct LengthUnitTests {
    
    @Test func testLengthUnitRawValues() {
        #expect(LengthUnit.yards.rawValue == "yards")
        #expect(LengthUnit.meters.rawValue == "meters")
        #expect(LengthUnit.inches.rawValue == "inches")
        #expect(LengthUnit.centimeters.rawValue == "centimeters")
    }
    
    @Test func testLengthUnitAbbreviations() {
        #expect(LengthUnit.yards.abbreviation == "yd")
        #expect(LengthUnit.meters.abbreviation == "m")
        #expect(LengthUnit.inches.abbreviation == "in")
        #expect(LengthUnit.centimeters.abbreviation == "cm")
    }
    
    @Test func testLengthUnitDisplayNames() {
        #expect(LengthUnit.yards.displayName == "Yards")
        #expect(LengthUnit.meters.displayName == "Meters")
        #expect(LengthUnit.inches.displayName == "Inches")
        #expect(LengthUnit.centimeters.displayName == "Centimeters")
    }
    
    @Test func testLengthUnitAllCases() {
        let allCases = LengthUnit.allCases
        
        #expect(allCases.count == 4)
        #expect(allCases.contains(.yards))
        #expect(allCases.contains(.meters))
        #expect(allCases.contains(.inches))
        #expect(allCases.contains(.centimeters))
    }
    
    @Test func testLengthUnitCodable() throws {
        let unit = LengthUnit.meters
        
        // Test encoding
        let encoder = JSONEncoder()
        let encodedData = try encoder.encode(unit)
        
        // Test decoding
        let decoder = JSONDecoder()
        let decodedUnit = try decoder.decode(LengthUnit.self, from: encodedData)
        
        #expect(decodedUnit == .meters)
    }
    
    @Test func testLengthUnitInitFromRawValue() {
        #expect(LengthUnit(rawValue: "yards") == .yards)
        #expect(LengthUnit(rawValue: "meters") == .meters)
        #expect(LengthUnit(rawValue: "inches") == .inches)
        #expect(LengthUnit(rawValue: "centimeters") == .centimeters)
        #expect(LengthUnit(rawValue: "invalid") == nil)
    }
    
    @Test func testLengthUnitEquality() {
        #expect(LengthUnit.yards == LengthUnit.yards)
        #expect(LengthUnit.yards != LengthUnit.meters)
    }
}

struct HistoryActionTests {
    
    @Test func testHistoryActionRawValues() {
        #expect(HistoryAction.changedMeasurementUnit.rawValue == "Changed Measurement Unit")
        #expect(HistoryAction.changedLengthUnit.rawValue == "Changed Length Unit")
        #expect(HistoryAction.setDefaultProfile.rawValue == "Set Default Profile")
        #expect(HistoryAction.createdProject.rawValue == "Created Project")
        #expect(HistoryAction.deletedProject.rawValue == "Deleted Project")
        #expect(HistoryAction.addedFabric.rawValue == "Added Fabric")
        #expect(HistoryAction.deletedFabric.rawValue == "Deleted Fabric")
        #expect(HistoryAction.addedPattern.rawValue == "Added Pattern")
        #expect(HistoryAction.deletedPattern.rawValue == "Deleted Pattern")
        #expect(HistoryAction.addedMeasurement.rawValue == "Added Measurement")
        #expect(HistoryAction.updatedMeasurement.rawValue == "Updated Measurement")
    }
    
    @Test func testHistoryActionAllCases() {
        let allCases = HistoryAction.allCases
        
        #expect(allCases.count == 11)
        #expect(allCases.contains(.changedMeasurementUnit))
        #expect(allCases.contains(.changedLengthUnit))
        #expect(allCases.contains(.setDefaultProfile))
        #expect(allCases.contains(.createdProject))
        #expect(allCases.contains(.deletedProject))
        #expect(allCases.contains(.addedFabric))
        #expect(allCases.contains(.deletedFabric))
        #expect(allCases.contains(.addedPattern))
        #expect(allCases.contains(.deletedPattern))
        #expect(allCases.contains(.addedMeasurement))
        #expect(allCases.contains(.updatedMeasurement))
    }
    
    @Test func testHistoryActionCodable() throws {
        let action = HistoryAction.createdProject
        
        // Test encoding
        let encoder = JSONEncoder()
        let encodedData = try encoder.encode(action)
        
        // Test decoding
        let decoder = JSONDecoder()
        let decodedAction = try decoder.decode(HistoryAction.self, from: encodedData)
        
        #expect(decodedAction == .createdProject)
    }
    
    @Test func testHistoryActionInitFromRawValue() {
        #expect(HistoryAction(rawValue: "Created Project") == .createdProject)
        #expect(HistoryAction(rawValue: "Added Fabric") == .addedFabric)
        #expect(HistoryAction(rawValue: "Invalid Action") == nil)
    }
    
    @Test func testHistoryActionEquality() {
        #expect(HistoryAction.createdProject == HistoryAction.createdProject)
        #expect(HistoryAction.createdProject != HistoryAction.addedFabric)
    }
}

struct HistoryContextTests {
    
    @Test func testHistoryContextRawValues() {
        #expect(HistoryContext.settings.rawValue == "Settings")
        #expect(HistoryContext.projects.rawValue == "Projects")
        #expect(HistoryContext.fabric.rawValue == "Fabric")
        #expect(HistoryContext.fabrics.rawValue == "Fabrics")
        #expect(HistoryContext.patterns.rawValue == "Patterns")
        #expect(HistoryContext.measurements.rawValue == "Measurements")
    }
    
    @Test func testHistoryContextAllCases() {
        let allCases = HistoryContext.allCases
        
        #expect(allCases.count == 6)
        #expect(allCases.contains(.settings))
        #expect(allCases.contains(.projects))
        #expect(allCases.contains(.fabric))
        #expect(allCases.contains(.fabrics))
        #expect(allCases.contains(.patterns))
        #expect(allCases.contains(.measurements))
    }
    
    @Test func testHistoryContextCodable() throws {
        let context = HistoryContext.projects
        
        // Test encoding
        let encoder = JSONEncoder()
        let encodedData = try encoder.encode(context)
        
        // Test decoding
        let decoder = JSONDecoder()
        let decodedContext = try decoder.decode(HistoryContext.self, from: encodedData)
        
        #expect(decodedContext == .projects)
    }
    
    @Test func testHistoryContextInitFromRawValue() {
        #expect(HistoryContext(rawValue: "Projects") == .projects)
        #expect(HistoryContext(rawValue: "Fabric") == .fabric)
        #expect(HistoryContext(rawValue: "Patterns") == .patterns)
        #expect(HistoryContext(rawValue: "Invalid Context") == nil)
    }
    
    @Test func testHistoryContextEquality() {
        #expect(HistoryContext.projects == HistoryContext.projects)
        #expect(HistoryContext.projects != HistoryContext.fabric)
    }
    
    @Test func testHistoryContextStringRepresentation() {
        #expect("\(HistoryContext.settings)" == "settings")
        #expect("\(HistoryContext.projects)" == "projects")
        #expect("\(HistoryContext.fabric)" == "fabric")
    }
}