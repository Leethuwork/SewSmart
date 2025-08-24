import Foundation
import SwiftData

@Model
final class ShoppingList {
    var id: UUID
    var name: String
    var notes: String
    var createdDate: Date
    var isArchived: Bool
    
    @Relationship(deleteRule: .cascade, inverse: \ShoppingItem.shoppingList)
    var items: [ShoppingItem] = []
    
    init(name: String) {
        self.id = UUID()
        self.name = name
        self.notes = ""
        self.createdDate = Date()
        self.isArchived = false
    }
}

@Model
final class ShoppingItem {
    var id: UUID
    var name: String
    var category: ShoppingCategory
    var quantity: Int
    var estimatedCost: Double
    var actualCost: Double
    var isPurchased: Bool
    var store: String
    var notes: String
    var priority: ItemPriority
    var createdDate: Date
    
    @Relationship(deleteRule: .nullify)
    var shoppingList: ShoppingList?
    
    init(
        name: String,
        category: ShoppingCategory = .fabric,
        quantity: Int = 1,
        priority: ItemPriority = .medium
    ) {
        self.id = UUID()
        self.name = name
        self.category = category
        self.quantity = quantity
        self.estimatedCost = 0.0
        self.actualCost = 0.0
        self.isPurchased = false
        self.store = ""
        self.notes = ""
        self.priority = priority
        self.createdDate = Date()
    }
}

enum ShoppingCategory: String, CaseIterable, Codable {
    case fabric = "Fabric"
    case notions = "Notions"
    case thread = "Thread"
    case pattern = "Pattern"
    case tool = "Tool"
    case other = "Other"
}

enum ItemPriority: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case urgent = "Urgent"
    
    var color: String {
        switch self {
        case .low: return "gray"
        case .medium: return "blue"
        case .high: return "orange"
        case .urgent: return "red"
        }
    }
}