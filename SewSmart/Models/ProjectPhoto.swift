import Foundation
import SwiftData

@Model
final class ProjectPhoto {
    var id: UUID
    var imageData: Data?
    var caption: String
    var stage: PhotoStage
    var createdDate: Date
    
    @Relationship(deleteRule: .nullify)
    var project: Project?
    
    init(
        imageData: Data? = nil,
        caption: String = "",
        stage: PhotoStage = .inProgress
    ) {
        self.id = UUID()
        self.imageData = imageData
        self.caption = caption
        self.stage = stage
        self.createdDate = Date()
    }
}

enum PhotoStage: String, CaseIterable, Codable {
    case planning = "Planning"
    case cutting = "Cutting"
    case inProgress = "In Progress"
    case fitting = "Fitting"
    case finished = "Finished"
    case detail = "Detail"
}