import Testing
import SwiftData
import Foundation
@testable import SewSmart

@MainActor
struct FabricRepositoryTests {
    
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
    
    @Test func testFetchAllFabricsEmpty() async throws {
        let modelContext = try createInMemoryModelContext()
        let repository = FabricRepository(modelContext: modelContext)
        
        let fabrics = try await repository.fetchAll()
        
        #expect(fabrics.isEmpty)
    }
    
    @Test func testSaveAndFetchFabric() async throws {
        let modelContext = try createInMemoryModelContext()
        let repository = FabricRepository(modelContext: modelContext)
        
        let fabric = Fabric(name: "Test Fabric", type: .cotton, color: "Blue", yardage: 2.5)
        fabric.cost = 15.99
        fabric.content = "100% Cotton"
        fabric.brand = "Test Brand"
        
        try await repository.save(fabric)
        let fetchedFabrics = try await repository.fetchAll()
        
        #expect(fetchedFabrics.count == 1)
        #expect(fetchedFabrics[0].name == "Test Fabric")
        #expect(fetchedFabrics[0].type == .cotton)
        #expect(fetchedFabrics[0].color == "Blue")
        #expect(fetchedFabrics[0].yardage == 2.5)
        #expect(fetchedFabrics[0].cost == 15.99)
        #expect(fetchedFabrics[0].content == "100% Cotton")
        #expect(fetchedFabrics[0].brand == "Test Brand")
    }
    
    @Test func testFetchFabricById() async throws {
        let modelContext = try createInMemoryModelContext()
        let repository = FabricRepository(modelContext: modelContext)
        
        let fabric = Fabric(name: "Test Fabric", type: .silk, color: "Red", yardage: 1.0)
        let fabricId = fabric.id
        
        try await repository.save(fabric)
        let fetchedFabric = try await repository.fetch(by: fabricId)
        
        #expect(fetchedFabric != nil)
        #expect(fetchedFabric?.name == "Test Fabric")
        #expect(fetchedFabric?.id == fabricId)
        #expect(fetchedFabric?.type == .silk)
    }
    
    @Test func testFetchFabricByIdNotFound() async throws {
        let modelContext = try createInMemoryModelContext()
        let repository = FabricRepository(modelContext: modelContext)
        
        let nonExistentId = UUID()
        let fetchedFabric = try await repository.fetch(by: nonExistentId)
        
        #expect(fetchedFabric == nil)
    }
    
    @Test func testFetchFabricsByType() async throws {
        let modelContext = try createInMemoryModelContext()
        let repository = FabricRepository(modelContext: modelContext)
        
        let cottonFabric1 = Fabric(name: "Cotton 1", type: .cotton, color: "White", yardage: 1.5)
        let silkFabric = Fabric(name: "Silk 1", type: .silk, color: "Black", yardage: 0.75)
        let cottonFabric2 = Fabric(name: "Cotton 2", type: .cotton, color: "Gray", yardage: 2.0)
        
        try await repository.save(cottonFabric1)
        try await repository.save(silkFabric)
        try await repository.save(cottonFabric2)
        
        let cottonFabrics = try await repository.fetch(by: .cotton)
        let silkFabrics = try await repository.fetch(by: .silk)
        let linenFabrics = try await repository.fetch(by: .linen)
        
        #expect(cottonFabrics.count == 2)
        #expect(silkFabrics.count == 1)
        #expect(linenFabrics.isEmpty)
        #expect(cottonFabrics.contains { $0.name == "Cotton 1" })
        #expect(cottonFabrics.contains { $0.name == "Cotton 2" })
        #expect(silkFabrics.contains { $0.name == "Silk 1" })
    }
    
    @Test func testUpdateFabric() async throws {
        let modelContext = try createInMemoryModelContext()
        let repository = FabricRepository(modelContext: modelContext)
        
        let fabric = Fabric(name: "Original Fabric", type: .cotton, color: "Blue", yardage: 1.0)
        fabric.cost = 10.0
        try await repository.save(fabric)
        
        // Update the fabric
        fabric.name = "Updated Fabric"
        fabric.type = .silk
        fabric.color = "Red"
        fabric.yardage = 2.0
        fabric.cost = 25.0
        fabric.content = "100% Silk"
        fabric.brand = "Updated Brand"
        fabric.notes = "Premium quality"
        
        try await repository.update(fabric)
        
        // Fetch the updated fabric
        let fetchedFabric = try await repository.fetch(by: fabric.id)
        
        #expect(fetchedFabric?.name == "Updated Fabric")
        #expect(fetchedFabric?.type == .silk)
        #expect(fetchedFabric?.color == "Red")
        #expect(fetchedFabric?.yardage == 2.0)
        #expect(fetchedFabric?.cost == 25.0)
        #expect(fetchedFabric?.content == "100% Silk")
        #expect(fetchedFabric?.brand == "Updated Brand")
        #expect(fetchedFabric?.notes == "Premium quality")
    }
    
    @Test func testDeleteFabric() async throws {
        let modelContext = try createInMemoryModelContext()
        let repository = FabricRepository(modelContext: modelContext)
        
        let fabric1 = Fabric(name: "Fabric 1", type: .cotton, color: "Blue", yardage: 1.0)
        let fabric2 = Fabric(name: "Fabric 2", type: .silk, color: "Red", yardage: 0.5)
        
        try await repository.save(fabric1)
        try await repository.save(fabric2)
        
        // Verify both fabrics exist
        let allFabrics = try await repository.fetchAll()
        #expect(allFabrics.count == 2)
        
        // Delete fabric1
        try await repository.delete(fabric1)
        
        // Verify only fabric2 remains
        let remainingFabrics = try await repository.fetchAll()
        #expect(remainingFabrics.count == 1)
        #expect(remainingFabrics[0].name == "Fabric 2")
    }
    
    @Test func testGetTotalValue() async throws {
        let modelContext = try createInMemoryModelContext()
        let repository = FabricRepository(modelContext: modelContext)
        
        let fabric1 = Fabric(name: "Fabric 1", type: .cotton, color: "Blue", yardage: 1.0)
        fabric1.cost = 15.50
        let fabric2 = Fabric(name: "Fabric 2", type: .silk, color: "Red", yardage: 0.5)
        fabric2.cost = 24.99
        let fabric3 = Fabric(name: "Fabric 3", type: .linen, color: "White", yardage: 2.0)
        fabric3.cost = 12.75
        
        try await repository.save(fabric1)
        try await repository.save(fabric2)
        try await repository.save(fabric3)
        
        let totalValue = try await repository.getTotalValue()
        let expectedTotal = 15.50 + 24.99 + 12.75
        
        #expect(abs(totalValue - expectedTotal) < 0.001)
    }
    
    @Test func testGetTotalValueEmpty() async throws {
        let modelContext = try createInMemoryModelContext()
        let repository = FabricRepository(modelContext: modelContext)
        
        let totalValue = try await repository.getTotalValue()
        
        #expect(totalValue == 0.0)
    }
    
    @Test func testGetTotalYardage() async throws {
        let modelContext = try createInMemoryModelContext()
        let repository = FabricRepository(modelContext: modelContext)
        
        let fabric1 = Fabric(name: "Fabric 1", type: .cotton, color: "Blue", yardage: 2.5)
        let fabric2 = Fabric(name: "Fabric 2", type: .silk, color: "Red", yardage: 1.25)
        let fabric3 = Fabric(name: "Fabric 3", type: .linen, color: "White", yardage: 3.75)
        
        try await repository.save(fabric1)
        try await repository.save(fabric2)
        try await repository.save(fabric3)
        
        let totalYardage = try await repository.getTotalYardage()
        let expectedTotal = 2.5 + 1.25 + 3.75
        
        #expect(abs(totalYardage - expectedTotal) < 0.001)
    }
    
    @Test func testGetTotalYardageEmpty() async throws {
        let modelContext = try createInMemoryModelContext()
        let repository = FabricRepository(modelContext: modelContext)
        
        let totalYardage = try await repository.getTotalYardage()
        
        #expect(totalYardage == 0.0)
    }
    
    @Test func testFetchAllFabricsSortedByCreatedDate() async throws {
        let modelContext = try createInMemoryModelContext()
        let repository = FabricRepository(modelContext: modelContext)
        
        let fabric1 = Fabric(name: "First Fabric", type: .cotton, color: "Blue", yardage: 1.0)
        let fabric2 = Fabric(name: "Second Fabric", type: .silk, color: "Red", yardage: 0.5)
        let fabric3 = Fabric(name: "Third Fabric", type: .linen, color: "White", yardage: 2.0)
        
        // Save fabrics with small delays to ensure different creation times
        try await repository.save(fabric1)
        try await Task.sleep(for: .milliseconds(10))
        
        try await repository.save(fabric2)
        try await Task.sleep(for: .milliseconds(10))
        
        try await repository.save(fabric3)
        
        let fetchedFabrics = try await repository.fetchAll()
        
        #expect(fetchedFabrics.count == 3)
        // Should be sorted by creation date in reverse order (newest first)
        #expect(fetchedFabrics[0].name == "Third Fabric")
        #expect(fetchedFabrics[1].name == "Second Fabric")
        #expect(fetchedFabrics[2].name == "First Fabric")
    }
    
    @Test func testFabricWithComplexData() async throws {
        let modelContext = try createInMemoryModelContext()
        let repository = FabricRepository(modelContext: modelContext)
        
        let fabric = Fabric(name: "Premium Silk", type: .silk, color: "Deep Purple", yardage: 1.5)
        fabric.cost = 89.99
        fabric.content = "100% Mulberry Silk"
        fabric.brand = "Luxury Textiles Co."
        fabric.notes = "Perfect for evening wear, handle with care"
        fabric.store = "Storage Bin A3"
        
        try await repository.save(fabric)
        let fetchedFabric = try await repository.fetch(by: fabric.id)
        
        #expect(fetchedFabric?.name == "Premium Silk")
        #expect(fetchedFabric?.type == .silk)
        #expect(fetchedFabric?.color == "Deep Purple")
        #expect(fetchedFabric?.yardage == 1.5)
        #expect(fetchedFabric?.cost == 89.99)
        #expect(fetchedFabric?.content == "100% Mulberry Silk")
        #expect(fetchedFabric?.brand == "Luxury Textiles Co.")
        #expect(fetchedFabric?.notes == "Perfect for evening wear, handle with care")
        #expect(fetchedFabric?.store == "Storage Bin A3")
    }
    
    @Test func testSaveMultipleFabrics() async throws {
        let modelContext = try createInMemoryModelContext()
        let repository = FabricRepository(modelContext: modelContext)
        
        let fabrics = [
            Fabric(name: "Cotton A", type: .cotton, color: "White", yardage: 2.0),
            Fabric(name: "Silk B", type: .silk, color: "Black", yardage: 1.0),
            Fabric(name: "Linen C", type: .linen, color: "Natural", yardage: 3.0),
            Fabric(name: "Wool D", type: .wool, color: "Gray", yardage: 1.5)
        ]
        
        for fabric in fabrics {
            try await repository.save(fabric)
        }
        
        let fetchedFabrics = try await repository.fetchAll()
        #expect(fetchedFabrics.count == 4)
        
        let fabricNames = Set(fetchedFabrics.map { $0.name })
        #expect(fabricNames.contains("Cotton A"))
        #expect(fabricNames.contains("Silk B"))
        #expect(fabricNames.contains("Linen C"))
        #expect(fabricNames.contains("Wool D"))
    }
}