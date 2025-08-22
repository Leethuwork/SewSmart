import Testing
import Foundation
@testable import SewSmart

struct ShoppingListTests {
    
    @Test func testShoppingListInitialization() {
        let shoppingList = ShoppingList(name: "Fabric Shopping List")
        
        #expect(shoppingList.name == "Fabric Shopping List")
        #expect(shoppingList.notes == "")
        #expect(shoppingList.isArchived == false)
        #expect(shoppingList.items.isEmpty)
    }
    
    @Test func testShoppingListIdUniqueness() {
        let list1 = ShoppingList(name: "List 1")
        let list2 = ShoppingList(name: "List 2")
        
        #expect(list1.id != list2.id)
    }
    
    @Test func testShoppingListCreatedDateIsSet() {
        let beforeCreation = Date()
        let shoppingList = ShoppingList(name: "Test List")
        let afterCreation = Date()
        
        #expect(shoppingList.createdDate >= beforeCreation)
        #expect(shoppingList.createdDate <= afterCreation)
    }
    
    @Test func testShoppingListPropertyModification() {
        let shoppingList = ShoppingList(name: "Original List")
        
        shoppingList.name = "Updated List"
        shoppingList.notes = "Updated notes"
        shoppingList.isArchived = true
        
        #expect(shoppingList.name == "Updated List")
        #expect(shoppingList.notes == "Updated notes")
        #expect(shoppingList.isArchived == true)
    }
    
    @Test func testShoppingListWithItems() {
        let shoppingList = ShoppingList(name: "Shopping List with Items")
        let item1 = ShoppingItem(name: "Cotton Fabric", category: .fabric)
        let item2 = ShoppingItem(name: "Thread", category: .thread)
        
        #expect(shoppingList.items.isEmpty)
        
        // Add items (Note: In real SwiftData usage, this would be managed by the context)
        shoppingList.items.append(item1)
        shoppingList.items.append(item2)
        item1.shoppingList = shoppingList
        item2.shoppingList = shoppingList
        
        #expect(shoppingList.items.count == 2)
        #expect(shoppingList.items.contains { $0.name == "Cotton Fabric" })
        #expect(shoppingList.items.contains { $0.name == "Thread" })
    }
    
    @Test func testShoppingListArchiving() {
        let shoppingList = ShoppingList(name: "Archivable List")
        
        #expect(shoppingList.isArchived == false)
        
        shoppingList.isArchived = true
        #expect(shoppingList.isArchived == true)
        
        shoppingList.isArchived = false
        #expect(shoppingList.isArchived == false)
    }
    
    @Test func testShoppingListEmptyNotes() {
        let shoppingList = ShoppingList(name: "Empty Notes List")
        
        #expect(shoppingList.notes == "")
        
        shoppingList.notes = "Some notes"
        #expect(shoppingList.notes == "Some notes")
    }
}

struct ShoppingItemTests {
    
    @Test func testShoppingItemInitialization() {
        let item = ShoppingItem(
            name: "Premium Silk",
            category: .fabric,
            quantity: 3,
            priority: .high
        )
        
        #expect(item.name == "Premium Silk")
        #expect(item.category == .fabric)
        #expect(item.quantity == 3)
        #expect(item.priority == .high)
        #expect(item.estimatedCost == 0.0)
        #expect(item.actualCost == 0.0)
        #expect(item.isPurchased == false)
        #expect(item.store == "")
        #expect(item.notes == "")
        #expect(item.shoppingList == nil)
    }
    
    @Test func testShoppingItemInitializationWithDefaults() {
        let item = ShoppingItem(name: "Basic Item")
        
        #expect(item.name == "Basic Item")
        #expect(item.category == .fabric)
        #expect(item.quantity == 1)
        #expect(item.priority == .medium)
        #expect(item.estimatedCost == 0.0)
        #expect(item.actualCost == 0.0)
        #expect(item.isPurchased == false)
        #expect(item.store == "")
        #expect(item.notes == "")
        #expect(item.shoppingList == nil)
    }
    
    @Test func testShoppingItemIdUniqueness() {
        let item1 = ShoppingItem(name: "Item 1")
        let item2 = ShoppingItem(name: "Item 2")
        
        #expect(item1.id != item2.id)
    }
    
    @Test func testShoppingItemCreatedDateIsSet() {
        let beforeCreation = Date()
        let item = ShoppingItem(name: "Test Item")
        let afterCreation = Date()
        
        #expect(item.createdDate >= beforeCreation)
        #expect(item.createdDate <= afterCreation)
    }
    
    @Test func testShoppingItemPropertyModification() {
        let item = ShoppingItem(name: "Original Item")
        
        item.name = "Updated Item"
        item.category = .notions
        item.quantity = 5
        item.estimatedCost = 15.99
        item.actualCost = 12.99
        item.isPurchased = true
        item.store = "Fabric Store"
        item.notes = "Great quality"
        item.priority = .urgent
        
        #expect(item.name == "Updated Item")
        #expect(item.category == .notions)
        #expect(item.quantity == 5)
        #expect(item.estimatedCost == 15.99)
        #expect(item.actualCost == 12.99)
        #expect(item.isPurchased == true)
        #expect(item.store == "Fabric Store")
        #expect(item.notes == "Great quality")
        #expect(item.priority == .urgent)
    }
    
    @Test func testShoppingItemWithShoppingList() {
        let shoppingList = ShoppingList(name: "Test Shopping List")
        let item = ShoppingItem(name: "Test Item", category: .fabric)
        
        #expect(item.shoppingList == nil)
        
        item.shoppingList = shoppingList
        
        #expect(item.shoppingList?.name == "Test Shopping List")
    }
    
    @Test func testShoppingItemPurchaseState() {
        let item = ShoppingItem(name: "Purchase Test Item")
        
        #expect(item.isPurchased == false)
        #expect(item.actualCost == 0.0)
        
        // Simulate purchase
        item.isPurchased = true
        item.actualCost = 25.99
        
        #expect(item.isPurchased == true)
        #expect(item.actualCost == 25.99)
    }
    
    @Test func testShoppingItemCostComparison() {
        let item = ShoppingItem(name: "Cost Test Item")
        
        item.estimatedCost = 20.0
        item.actualCost = 18.50
        
        #expect(item.estimatedCost == 20.0)
        #expect(item.actualCost == 18.50)
        #expect(item.actualCost < item.estimatedCost)
    }
    
    @Test func testShoppingItemQuantityHandling() {
        let item = ShoppingItem(name: "Quantity Test Item")
        
        // Test different quantity values
        item.quantity = 0
        #expect(item.quantity == 0)
        
        item.quantity = 1
        #expect(item.quantity == 1)
        
        item.quantity = 10
        #expect(item.quantity == 10)
        
        item.quantity = -1
        #expect(item.quantity == -1) // Model doesn't enforce positive values
    }
}

struct ShoppingCategoryTests {
    
    @Test func testShoppingCategoryRawValues() {
        #expect(ShoppingCategory.fabric.rawValue == "Fabric")
        #expect(ShoppingCategory.notions.rawValue == "Notions")
        #expect(ShoppingCategory.thread.rawValue == "Thread")
        #expect(ShoppingCategory.pattern.rawValue == "Pattern")
        #expect(ShoppingCategory.tool.rawValue == "Tool")
        #expect(ShoppingCategory.other.rawValue == "Other")
    }
    
    @Test func testShoppingCategoryAllCases() {
        let allCases = ShoppingCategory.allCases
        
        #expect(allCases.count == 6)
        #expect(allCases.contains(.fabric))
        #expect(allCases.contains(.notions))
        #expect(allCases.contains(.thread))
        #expect(allCases.contains(.pattern))
        #expect(allCases.contains(.tool))
        #expect(allCases.contains(.other))
    }
    
    @Test func testShoppingCategoryCodable() throws {
        let category = ShoppingCategory.fabric
        
        // Test encoding
        let encoder = JSONEncoder()
        let encodedData = try encoder.encode(category)
        
        // Test decoding
        let decoder = JSONDecoder()
        let decodedCategory = try decoder.decode(ShoppingCategory.self, from: encodedData)
        
        #expect(decodedCategory == .fabric)
    }
    
    @Test func testShoppingCategoryInitFromRawValue() {
        #expect(ShoppingCategory(rawValue: "Fabric") == .fabric)
        #expect(ShoppingCategory(rawValue: "Notions") == .notions)
        #expect(ShoppingCategory(rawValue: "Thread") == .thread)
        #expect(ShoppingCategory(rawValue: "Pattern") == .pattern)
        #expect(ShoppingCategory(rawValue: "Tool") == .tool)
        #expect(ShoppingCategory(rawValue: "Other") == .other)
        #expect(ShoppingCategory(rawValue: "Invalid") == nil)
    }
    
    @Test func testShoppingCategoryEquality() {
        #expect(ShoppingCategory.fabric == ShoppingCategory.fabric)
        #expect(ShoppingCategory.fabric != ShoppingCategory.thread)
    }
}

struct ItemPriorityTests {
    
    @Test func testItemPriorityRawValues() {
        #expect(ItemPriority.low.rawValue == "Low")
        #expect(ItemPriority.medium.rawValue == "Medium")
        #expect(ItemPriority.high.rawValue == "High")
        #expect(ItemPriority.urgent.rawValue == "Urgent")
    }
    
    @Test func testItemPriorityColors() {
        #expect(ItemPriority.low.color == "gray")
        #expect(ItemPriority.medium.color == "blue")
        #expect(ItemPriority.high.color == "orange")
        #expect(ItemPriority.urgent.color == "red")
    }
    
    @Test func testItemPriorityAllCases() {
        let allCases = ItemPriority.allCases
        
        #expect(allCases.count == 4)
        #expect(allCases.contains(.low))
        #expect(allCases.contains(.medium))
        #expect(allCases.contains(.high))
        #expect(allCases.contains(.urgent))
    }
    
    @Test func testItemPriorityCodable() throws {
        let priority = ItemPriority.high
        
        // Test encoding
        let encoder = JSONEncoder()
        let encodedData = try encoder.encode(priority)
        
        // Test decoding
        let decoder = JSONDecoder()
        let decodedPriority = try decoder.decode(ItemPriority.self, from: encodedData)
        
        #expect(decodedPriority == .high)
    }
    
    @Test func testItemPriorityInitFromRawValue() {
        #expect(ItemPriority(rawValue: "Low") == .low)
        #expect(ItemPriority(rawValue: "Medium") == .medium)
        #expect(ItemPriority(rawValue: "High") == .high)
        #expect(ItemPriority(rawValue: "Urgent") == .urgent)
        #expect(ItemPriority(rawValue: "Invalid") == nil)
    }
    
    @Test func testItemPriorityEquality() {
        #expect(ItemPriority.low == ItemPriority.low)
        #expect(ItemPriority.low != ItemPriority.urgent)
    }
    
    @Test func testItemPriorityColorConsistency() {
        // Verify color mappings are consistent
        let priorityColorMap = [
            ItemPriority.low: "gray",
            ItemPriority.medium: "blue",
            ItemPriority.high: "orange",
            ItemPriority.urgent: "red"
        ]
        
        for (priority, expectedColor) in priorityColorMap {
            #expect(priority.color == expectedColor)
        }
    }
    
    @Test func testItemPriorityStringRepresentation() {
        #expect("\(ItemPriority.low)" == "low")
        #expect("\(ItemPriority.medium)" == "medium")
        #expect("\(ItemPriority.high)" == "high")
        #expect("\(ItemPriority.urgent)" == "urgent")
    }
}