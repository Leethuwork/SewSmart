import Foundation
import SwiftData

@Model
final class UserSettings {
    var id: UUID
    var preferredMeasurementUnit: MeasurementUnit
    var preferredLengthUnit: LengthUnit
    var defaultMeasurementProfile: String? // Profile name
    var createdDate: Date
    var lastModified: Date
    
    @Relationship(deleteRule: .cascade, inverse: \UserHistory.settings)
    var history: [UserHistory] = []
    
    init() {
        self.id = UUID()
        self.preferredMeasurementUnit = .inches
        self.preferredLengthUnit = .yards
        self.defaultMeasurementProfile = nil
        self.createdDate = Date()
        self.lastModified = Date()
    }
    
    func updateLastModified() {
        self.lastModified = Date()
    }
}

@Model
final class UserHistory {
    var id: UUID
    var action: HistoryAction
    var details: String
    var timestamp: Date
    var context: HistoryContext
    
    @Relationship(deleteRule: .nullify)
    var settings: UserSettings?
    
    init(action: HistoryAction, details: String, context: HistoryContext) {
        self.id = UUID()
        self.action = action
        self.details = details
        self.context = context
        self.timestamp = Date()
    }
}

enum LengthUnit: String, CaseIterable, Codable {
    case yards = "yards"
    case meters = "meters"
    case inches = "inches"
    case centimeters = "centimeters"
    
    var abbreviation: String {
        switch self {
        case .yards: return "yd"
        case .meters: return "m"
        case .inches: return "in"
        case .centimeters: return "cm"
        }
    }
    
    var displayName: String {
        return self.rawValue.capitalized
    }
}

enum HistoryAction: String, CaseIterable, Codable {
    case changedMeasurementUnit = "Changed Measurement Unit"
    case changedLengthUnit = "Changed Length Unit"
    case setDefaultProfile = "Set Default Profile"
    case createdProject = "Created Project"
    case addedFabric = "Added Fabric"
    case addedPattern = "Added Pattern"
    case addedMeasurement = "Added Measurement"
    case updatedMeasurement = "Updated Measurement"
}

enum HistoryContext: String, CaseIterable, Codable {
    case settings = "Settings"
    case projects = "Projects"
    case fabrics = "Fabrics"
    case patterns = "Patterns"
    case measurements = "Measurements"
}