import Foundation
import SwiftData

@Model
final class Fabric {
    var id: UUID
    var name: String
    var type: FabricType
    var color: String
    var content: String
    var brand: String
    var width: Double
    var yardage: Double
    var cost: Double
    var purchaseDate: Date?
    var store: String
    var careInstructions: String
    var notes: String
    var createdDate: Date
    var photoData: Data?
    
    @Relationship(deleteRule: .nullify)
    var projects: [Project] = []
    
    init(
        name: String,
        type: FabricType = .cotton,
        color: String = "",
        yardage: Double = 0
    ) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.color = color
        self.content = ""
        self.brand = ""
        self.width = 45.0
        self.yardage = yardage
        self.cost = 0.0
        self.store = ""
        self.careInstructions = ""
        self.notes = ""
        self.createdDate = Date()
    }
}

enum FabricType: String, CaseIterable, Codable {
    case cotton = "Cotton"
    case linen = "Linen"
    case silk = "Silk"
    case wool = "Wool"
    case polyester = "Polyester"
    case rayon = "Rayon"
    case denim = "Denim"
    case jersey = "Jersey"
    case fleece = "Fleece"
    case other = "Other"
}