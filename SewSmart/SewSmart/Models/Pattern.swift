import Foundation
import SwiftData

@Model
final class Pattern {
    var id: UUID
    var name: String
    var brand: String
    var category: PatternCategory
    var difficulty: PatternDifficulty
    var rating: Int
    var notes: String
    var tags: String
    var createdDate: Date
    var pdfData: Data?
    var thumbnailData: Data?
    var fileName: String?
    var fileType: PatternFileType?
    
    @Relationship(deleteRule: .nullify)
    var projects: [Project] = []
    
    init(
        name: String,
        brand: String = "",
        category: PatternCategory = .dress,
        difficulty: PatternDifficulty = .beginner
    ) {
        self.id = UUID()
        self.name = name
        self.brand = brand
        self.category = category
        self.difficulty = difficulty
        self.rating = 0
        self.notes = ""
        self.tags = ""
        self.createdDate = Date()
    }
}

enum PatternCategory: String, CaseIterable, Codable {
    case dress = "Dress"
    case top = "Top"
    case pants = "Pants"
    case skirt = "Skirt"
    case jacket = "Jacket"
    case accessory = "Accessory"
    case other = "Other"
}

enum PatternDifficulty: String, CaseIterable, Codable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    case expert = "Expert"
    
    var color: String {
        switch self {
        case .beginner: return "green"
        case .intermediate: return "yellow"
        case .advanced: return "orange"
        case .expert: return "red"
        }
    }
}

enum PatternFileType: String, CaseIterable, Codable {
    case pdf = "PDF"
    case image = "Image"
    
    var icon: String {
        switch self {
        case .pdf: return "doc.fill"
        case .image: return "photo.fill"
        }
    }
    
    var allowedExtensions: [String] {
        switch self {
        case .pdf: return ["pdf"]
        case .image: return ["jpg", "jpeg", "png", "heic"]
        }
    }
}