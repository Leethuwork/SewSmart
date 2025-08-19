import Foundation
import SwiftData

@Model
final class MeasurementProfile {
    var id: UUID
    var name: String
    var notes: String
    var createdDate: Date
    var isDefault: Bool
    
    @Relationship(deleteRule: .cascade, inverse: \Measurement.profile)
    var measurements: [Measurement] = []
    
    init(name: String, isDefault: Bool = false) {
        self.id = UUID()
        self.name = name
        self.notes = ""
        self.createdDate = Date()
        self.isDefault = isDefault
    }
}

@Model
final class Measurement {
    var id: UUID
    var name: String
    var value: Double
    var unit: MeasurementUnit
    var createdDate: Date
    var category: MeasurementCategory
    
    @Relationship(deleteRule: .nullify)
    var profile: MeasurementProfile?
    
    init(
        name: String,
        value: Double = 0,
        unit: MeasurementUnit = .inches,
        category: MeasurementCategory = .body
    ) {
        self.id = UUID()
        self.name = name
        self.value = value
        self.unit = unit
        self.category = category
        self.createdDate = Date()
    }
}

enum MeasurementUnit: String, CaseIterable, Codable {
    case inches = "inches"
    case centimeters = "cm"
    
    var abbreviation: String {
        switch self {
        case .inches: return "in"
        case .centimeters: return "cm"
        }
    }
}

enum MeasurementCategory: String, CaseIterable, Codable {
    case body = "Body"
    case garment = "Garment"
    case fit = "Fit Preferences"
}