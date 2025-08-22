import Testing
import Foundation
@testable import SewSmart

struct ComprehensiveFabricTests {
    
    @Test func testFabricInitialization() {
        let fabric = Fabric(name: "Test Fabric", type: .cotton, color: "Blue", yardage: 2.5)
        
        #expect(fabric.name == "Test Fabric")
        #expect(fabric.type == .cotton)
        #expect(fabric.color == "Blue")
        #expect(fabric.yardage == 2.5)
        #expect(fabric.content == "")
        #expect(fabric.brand == "")
        #expect(fabric.width == 45.0)
        #expect(fabric.cost == 0.0)
        #expect(fabric.store == "")
        #expect(fabric.careInstructions == "")
        #expect(fabric.notes == "")
        #expect(fabric.projects.isEmpty)
        #expect(fabric.photoData == nil)
        #expect(fabric.purchaseDate == nil)
    }
    
    @Test func testFabricInitializationWithMinimalParams() {
        let fabric = Fabric(name: "Simple Fabric")
        
        #expect(fabric.name == "Simple Fabric")
        #expect(fabric.type == .cotton) // default value
        #expect(fabric.color == "") // default value
        #expect(fabric.yardage == 0) // default value
    }
    
    @Test func testFabricInitializationWithPartialParams() {
        let fabric = Fabric(name: "Partial Fabric", type: .silk)
        
        #expect(fabric.name == "Partial Fabric")
        #expect(fabric.type == .silk)
        #expect(fabric.color == "") // default value
        #expect(fabric.yardage == 0) // default value
    }
    
    @Test func testFabricIdUniqueness() {
        let fabric1 = Fabric(name: "Fabric 1")
        let fabric2 = Fabric(name: "Fabric 2")
        
        #expect(fabric1.id != fabric2.id)
    }
    
    @Test func testFabricCreatedDateIsSetOnInitialization() {
        let beforeCreation = Date()
        let fabric = Fabric(name: "Test Fabric")
        let afterCreation = Date()
        
        #expect(fabric.createdDate >= beforeCreation)
        #expect(fabric.createdDate <= afterCreation)
    }
    
    @Test func testFabricPropertyModification() {
        let fabric = Fabric(name: "Original Name", type: .cotton, color: "Red", yardage: 1.0)
        
        // Modify properties
        fabric.name = "Updated Name"
        fabric.type = .silk
        fabric.color = "Blue"
        fabric.content = "100% Silk"
        fabric.brand = "Luxury Brand"
        fabric.width = 60.0
        fabric.yardage = 2.5
        fabric.cost = 25.99
        fabric.store = "Fabric Store"
        fabric.careInstructions = "Hand wash only"
        fabric.notes = "Beautiful fabric"
        fabric.purchaseDate = Date()
        
        #expect(fabric.name == "Updated Name")
        #expect(fabric.type == .silk)
        #expect(fabric.color == "Blue")
        #expect(fabric.content == "100% Silk")
        #expect(fabric.brand == "Luxury Brand")
        #expect(fabric.width == 60.0)
        #expect(fabric.yardage == 2.5)
        #expect(fabric.cost == 25.99)
        #expect(fabric.store == "Fabric Store")
        #expect(fabric.careInstructions == "Hand wash only")
        #expect(fabric.notes == "Beautiful fabric")
        #expect(fabric.purchaseDate != nil)
    }
    
    @Test func testFabricWithPhotoData() {
        let fabric = Fabric(name: "Photo Fabric")
        let testImageData = "test image data".data(using: .utf8)
        
        fabric.photoData = testImageData
        
        #expect(fabric.photoData == testImageData)
    }
    
    @Test func testFabricRelationshipWithProjects() {
        let fabric = Fabric(name: "Test Fabric")
        let project1 = Project(name: "Project 1", description: "Description 1", status: .planning)
        let project2 = Project(name: "Project 2", description: "Description 2", status: .inProgress)
        
        // Initially empty
        #expect(fabric.projects.isEmpty)
        
        // Add projects (Note: In real SwiftData usage, this would be managed by the context)
        fabric.projects.append(project1)
        fabric.projects.append(project2)
        
        #expect(fabric.projects.count == 2)
        #expect(fabric.projects.contains { $0.name == "Project 1" })
        #expect(fabric.projects.contains { $0.name == "Project 2" })
    }
}

struct ComprehensiveFabricTypeTests {
    
    @Test func testFabricTypeRawValues() {
        #expect(FabricType.cotton.rawValue == "Cotton")
        #expect(FabricType.linen.rawValue == "Linen")
        #expect(FabricType.silk.rawValue == "Silk")
        #expect(FabricType.wool.rawValue == "Wool")
        #expect(FabricType.polyester.rawValue == "Polyester")
        #expect(FabricType.rayon.rawValue == "Rayon")
        #expect(FabricType.denim.rawValue == "Denim")
        #expect(FabricType.jersey.rawValue == "Jersey")
        #expect(FabricType.fleece.rawValue == "Fleece")
        #expect(FabricType.other.rawValue == "Other")
    }
    
    @Test func testFabricTypeAllCases() {
        let allCases = FabricType.allCases
        
        #expect(allCases.count == 10)
        #expect(allCases.contains(.cotton))
        #expect(allCases.contains(.linen))
        #expect(allCases.contains(.silk))
        #expect(allCases.contains(.wool))
        #expect(allCases.contains(.polyester))
        #expect(allCases.contains(.rayon))
        #expect(allCases.contains(.denim))
        #expect(allCases.contains(.jersey))
        #expect(allCases.contains(.fleece))
        #expect(allCases.contains(.other))
    }
    
    @Test func testFabricTypeCodable() throws {
        let fabricType = FabricType.silk
        
        // Test encoding
        let encoder = JSONEncoder()
        let encodedData = try encoder.encode(fabricType)
        
        // Test decoding
        let decoder = JSONDecoder()
        let decodedFabricType = try decoder.decode(FabricType.self, from: encodedData)
        
        #expect(decodedFabricType == .silk)
    }
    
    @Test func testFabricTypeInitFromRawValue() {
        #expect(FabricType(rawValue: "Cotton") == .cotton)
        #expect(FabricType(rawValue: "Silk") == .silk)
        #expect(FabricType(rawValue: "Wool") == .wool)
        #expect(FabricType(rawValue: "InvalidType") == nil)
    }
    
    @Test func testFabricTypeEquality() {
        #expect(FabricType.cotton == FabricType.cotton)
        #expect(FabricType.silk != FabricType.cotton)
        
        let cottonType1 = FabricType.cotton
        let cottonType2 = FabricType.cotton
        #expect(cottonType1 == cottonType2)
    }
    
    @Test func testFabricTypeStringRepresentation() {
        #expect("\(FabricType.cotton)" == "cotton")
        #expect("\(FabricType.silk)" == "silk")
        #expect("\(FabricType.denim)" == "denim")
    }
}