import Foundation
import SwiftData

@Model
final class Project {
    var id: UUID
    var name: String
    var projectDescription: String
    var status: ProjectStatus
    var progress: Double
    var createdDate: Date
    var updatedDate: Date
    var dueDate: Date?
    var notes: String
    var priority: Int
    
    @Relationship(deleteRule: .cascade, inverse: \ProjectPhoto.project)
    var photos: [ProjectPhoto] = []
    
    @Relationship(deleteRule: .nullify)
    var patterns: [Pattern] = []
    
    @Relationship(deleteRule: .nullify)
    var fabrics: [Fabric] = []
    
    init(
        name: String,
        description: String = "",
        status: ProjectStatus = .planning,
        priority: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.projectDescription = description
        self.status = status
        self.progress = 0.0
        self.createdDate = Date()
        self.updatedDate = Date()
        self.notes = ""
        self.priority = priority
    }
}

enum ProjectStatus: String, CaseIterable, Codable {
    case planning = "Planning"
    case inProgress = "In Progress"
    case onHold = "On Hold"
    case completed = "Completed"
    
    var color: String {
        switch self {
        case .planning: return "orange"
        case .inProgress: return "blue"
        case .onHold: return "red"
        case .completed: return "green"
        }
    }
}