import Testing
import Foundation
@testable import SewSmart

struct ProjectTests {
    
    @Test func testProjectInitialization() throws {
        let project = Project(
            name: "Test Project",
            description: "Test Description",
            status: .inProgress,
            priority: 2
        )
        
        #expect(project.name == "Test Project")
        #expect(project.projectDescription == "Test Description")
        #expect(project.status == .inProgress)
        #expect(project.priority == 2)
        #expect(project.progress == 0.0)
        #expect(project.notes == "")
        #expect(project.photos.isEmpty)
        #expect(project.patterns.isEmpty)
        #expect(project.fabrics.isEmpty)
        #expect(project.dueDate == nil)
        
        // Test that dates are set
        #expect(project.createdDate <= Date())
        #expect(project.updatedDate <= Date())
        #expect(project.id != UUID())
    }
    
    @Test func testProjectInitializationWithDefaults() throws {
        let project = Project(name: "Simple Project")
        
        #expect(project.name == "Simple Project")
        #expect(project.projectDescription == "")
        #expect(project.status == .planning)
        #expect(project.priority == 0)
    }
    
    @Test func testProjectStatusColors() throws {
        #expect(ProjectStatus.planning.color == "orange")
        #expect(ProjectStatus.inProgress.color == "blue")
        #expect(ProjectStatus.onHold.color == "red")
        #expect(ProjectStatus.completed.color == "green")
    }
    
    @Test func testProjectStatusCases() throws {
        let allCases = ProjectStatus.allCases
        #expect(allCases.count == 4)
        #expect(allCases.contains(.planning))
        #expect(allCases.contains(.inProgress))
        #expect(allCases.contains(.onHold))
        #expect(allCases.contains(.completed))
    }
    
    @Test func testProjectStatusRawValues() throws {
        #expect(ProjectStatus.planning.rawValue == "Planning")
        #expect(ProjectStatus.inProgress.rawValue == "In Progress")
        #expect(ProjectStatus.onHold.rawValue == "On Hold")
        #expect(ProjectStatus.completed.rawValue == "Completed")
    }
    
    @Test func testProjectStatusCodable() throws {
        let status = ProjectStatus.inProgress
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let encoded = try encoder.encode(status)
        let decoded = try decoder.decode(ProjectStatus.self, from: encoded)
        
        #expect(decoded == status)
    }
    
    @Test func testProjectUniqueIds() throws {
        let project1 = Project(name: "Project 1")
        let project2 = Project(name: "Project 2")
        
        #expect(project1.id != project2.id)
    }
    
    @Test func testProjectWithCustomValues() throws {
        let project = Project(
            name: "Custom Project",
            description: "Custom Description",
            status: .completed,
            priority: 3
        )
        
        project.progress = 1.0
        project.notes = "Custom notes"
        project.dueDate = Date()
        
        #expect(project.progress == 1.0)
        #expect(project.notes == "Custom notes")
        #expect(project.dueDate != nil)
    }
    
    @Test func testProjectWithPhotos() throws {
        let project = Project(name: "Photo Project")
        let photo1 = ProjectPhoto(caption: "Progress photo 1", stage: .inProgress)
        let photo2 = ProjectPhoto(caption: "Progress photo 2", stage: .fitting)
        
        #expect(project.photos.isEmpty)
        
        // Add photos (Note: In real SwiftData usage, this would be managed by the context)
        project.photos.append(photo1)
        project.photos.append(photo2)
        photo1.project = project
        photo2.project = project
        
        #expect(project.photos.count == 2)
        #expect(project.photos.contains { $0.caption == "Progress photo 1" })
        #expect(project.photos.contains { $0.caption == "Progress photo 2" })
    }
    
    @Test func testProjectWithPatterns() throws {
        let project = Project(name: "Pattern Project")
        let pattern1 = Pattern(name: "Dress Pattern", category: .dress)
        let pattern2 = Pattern(name: "Top Pattern", category: .top)
        
        #expect(project.patterns.isEmpty)
        
        // Add patterns (Note: In real SwiftData usage, this would be managed by the context)
        project.patterns.append(pattern1)
        project.patterns.append(pattern2)
        pattern1.projects.append(project)
        pattern2.projects.append(project)
        
        #expect(project.patterns.count == 2)
        #expect(project.patterns.contains { $0.name == "Dress Pattern" })
        #expect(project.patterns.contains { $0.name == "Top Pattern" })
    }
    
    @Test func testProjectWithFabrics() throws {
        let project = Project(name: "Fabric Project")
        let fabric1 = Fabric(name: "Cotton Fabric", type: .cotton, color: "Blue")
        let fabric2 = Fabric(name: "Silk Fabric", type: .silk, color: "Red")
        
        #expect(project.fabrics.isEmpty)
        
        // Add fabrics (Note: In real SwiftData usage, this would be managed by the context)
        project.fabrics.append(fabric1)
        project.fabrics.append(fabric2)
        fabric1.projects.append(project)
        fabric2.projects.append(project)
        
        #expect(project.fabrics.count == 2)
        #expect(project.fabrics.contains { $0.name == "Cotton Fabric" })
        #expect(project.fabrics.contains { $0.name == "Silk Fabric" })
    }
    
    @Test func testProjectProgressBounds() throws {
        let project = Project(name: "Test Project")
        
        // Test different progress values
        project.progress = -0.1
        #expect(project.progress == -0.1) // Model doesn't enforce bounds, just stores value
        
        project.progress = 0.0
        #expect(project.progress == 0.0)
        
        project.progress = 0.5
        #expect(project.progress == 0.5)
        
        project.progress = 1.0
        #expect(project.progress == 1.0)
        
        project.progress = 1.5
        #expect(project.progress == 1.5)
    }
    
    @Test func testProjectStatusInitFromRawValue() throws {
        #expect(ProjectStatus(rawValue: "Planning") == .planning)
        #expect(ProjectStatus(rawValue: "In Progress") == .inProgress)
        #expect(ProjectStatus(rawValue: "On Hold") == .onHold)
        #expect(ProjectStatus(rawValue: "Completed") == .completed)
        #expect(ProjectStatus(rawValue: "Invalid") == nil)
    }
}

struct PatternTests {
    
    @Test func testPatternInitialization() throws {
        let pattern = Pattern(
            name: "Test Pattern",
            brand: "Test Brand",
            category: .dress,
            difficulty: .intermediate
        )
        
        #expect(pattern.name == "Test Pattern")
        #expect(pattern.brand == "Test Brand")
        #expect(pattern.category == .dress)
        #expect(pattern.difficulty == .intermediate)
        #expect(pattern.rating == 0)
        #expect(pattern.notes == "")
        #expect(pattern.tags == "")
        #expect(pattern.pdfData == nil)
        #expect(pattern.thumbnailData == nil)
        #expect(pattern.fileName == nil)
        #expect(pattern.fileType == nil)
        #expect(pattern.projects.isEmpty)
        #expect(pattern.createdDate <= Date())
        #expect(pattern.id != UUID())
    }
    
    @Test func testPatternInitializationWithDefaults() throws {
        let pattern = Pattern(name: "Simple Pattern")
        
        #expect(pattern.name == "Simple Pattern")
        #expect(pattern.brand == "")
        #expect(pattern.category == .dress)
        #expect(pattern.difficulty == .beginner)
    }
    
    @Test func testPatternCategoryAllCases() throws {
        let allCases = PatternCategory.allCases
        #expect(allCases.count == 7)
        #expect(allCases.contains(.dress))
        #expect(allCases.contains(.top))
        #expect(allCases.contains(.pants))
        #expect(allCases.contains(.skirt))
        #expect(allCases.contains(.jacket))
        #expect(allCases.contains(.accessory))
        #expect(allCases.contains(.other))
    }
    
    @Test func testPatternDifficultyColors() throws {
        #expect(PatternDifficulty.beginner.color == "green")
        #expect(PatternDifficulty.intermediate.color == "yellow")
        #expect(PatternDifficulty.advanced.color == "orange")
        #expect(PatternDifficulty.expert.color == "red")
    }
    
    @Test func testPatternFileTypeIcons() throws {
        #expect(PatternFileType.pdf.icon == "doc.fill")
        #expect(PatternFileType.image.icon == "photo.fill")
    }
    
    @Test func testPatternFileTypeExtensions() throws {
        let pdfExtensions = PatternFileType.pdf.allowedExtensions
        let imageExtensions = PatternFileType.image.allowedExtensions
        
        #expect(pdfExtensions == ["pdf"])
        #expect(imageExtensions == ["jpg", "jpeg", "png", "heic"])
    }
    
    @Test func testPatternWithPdfData() throws {
        let pattern = Pattern(name: "PDF Pattern")
        let pdfData = "Mock PDF content".data(using: .utf8)!
        let thumbnailData = "Mock thumbnail".data(using: .utf8)!
        
        pattern.pdfData = pdfData
        pattern.thumbnailData = thumbnailData
        pattern.fileName = "pattern.pdf"
        pattern.fileType = .pdf
        
        #expect(pattern.pdfData == pdfData)
        #expect(pattern.thumbnailData == thumbnailData)
        #expect(pattern.fileName == "pattern.pdf")
        #expect(pattern.fileType == .pdf)
    }
    
    @Test func testPatternCategoryCodable() throws {
        let category = PatternCategory.dress
        
        // Test encoding
        let encoder = JSONEncoder()
        let encodedData = try encoder.encode(category)
        
        // Test decoding
        let decoder = JSONDecoder()
        let decodedCategory = try decoder.decode(PatternCategory.self, from: encodedData)
        
        #expect(decodedCategory == .dress)
    }
    
    @Test func testPatternDifficultyCodable() throws {
        let difficulty = PatternDifficulty.intermediate
        
        // Test encoding
        let encoder = JSONEncoder()
        let encodedData = try encoder.encode(difficulty)
        
        // Test decoding
        let decoder = JSONDecoder()
        let decodedDifficulty = try decoder.decode(PatternDifficulty.self, from: encodedData)
        
        #expect(decodedDifficulty == .intermediate)
    }
    
    @Test func testPatternFileTypeCodable() throws {
        let fileType = PatternFileType.pdf
        
        // Test encoding
        let encoder = JSONEncoder()
        let encodedData = try encoder.encode(fileType)
        
        // Test decoding
        let decoder = JSONDecoder()
        let decodedFileType = try decoder.decode(PatternFileType.self, from: encodedData)
        
        #expect(decodedFileType == .pdf)
    }
    
    @Test func testPatternRatingBounds() throws {
        let pattern = Pattern(name: "Test Pattern")
        
        // Test different rating values
        pattern.rating = -1
        #expect(pattern.rating == -1) // Model doesn't enforce bounds, just stores value
        
        pattern.rating = 0
        #expect(pattern.rating == 0)
        
        pattern.rating = 5
        #expect(pattern.rating == 5)
        
        pattern.rating = 10
        #expect(pattern.rating == 10)
    }
    
    @Test func testPatternWithProjects() throws {
        let pattern = Pattern(name: "Test Pattern")
        let project1 = Project(name: "Project 1", description: "First project")
        let project2 = Project(name: "Project 2", description: "Second project")
        
        #expect(pattern.projects.isEmpty)
        
        // Add projects (Note: In real SwiftData usage, this would be managed by the context)
        pattern.projects.append(project1)
        pattern.projects.append(project2)
        project1.patterns.append(pattern)
        project2.patterns.append(pattern)
        
        #expect(pattern.projects.count == 2)
        #expect(pattern.projects.contains { $0.name == "Project 1" })
        #expect(pattern.projects.contains { $0.name == "Project 2" })
    }
    
    @Test func testPatternPropertyModification() throws {
        let pattern = Pattern(name: "Original Pattern")
        
        pattern.name = "Updated Pattern"
        pattern.brand = "Updated Brand"
        pattern.category = .top
        pattern.difficulty = .expert
        pattern.rating = 5
        pattern.notes = "Great pattern!"
        pattern.tags = "summer,casual"
        
        #expect(pattern.name == "Updated Pattern")
        #expect(pattern.brand == "Updated Brand")
        #expect(pattern.category == .top)
        #expect(pattern.difficulty == .expert)
        #expect(pattern.rating == 5)
        #expect(pattern.notes == "Great pattern!")
        #expect(pattern.tags == "summer,casual")
    }
    
    @Test func testPatternUniqueIds() throws {
        let pattern1 = Pattern(name: "Pattern 1")
        let pattern2 = Pattern(name: "Pattern 2")
        
        #expect(pattern1.id != pattern2.id)
    }
}

struct FabricTests {
    
    @Test func testFabricInitialization() throws {
        let fabric = Fabric(
            name: "Test Fabric",
            type: .cotton,
            color: "Blue",
            yardage: 2.5
        )
        
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
        #expect(fabric.purchaseDate == nil)
        #expect(fabric.photoData == nil)
        #expect(fabric.projects.isEmpty)
        #expect(fabric.createdDate <= Date())
        #expect(fabric.id != UUID())
    }
    
    @Test func testFabricInitializationWithDefaults() throws {
        let fabric = Fabric(name: "Simple Fabric")
        
        #expect(fabric.name == "Simple Fabric")
        #expect(fabric.type == .cotton)
        #expect(fabric.color == "")
        #expect(fabric.yardage == 0)
    }
    
    @Test func testFabricTypeAllCases() throws {
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
    
    @Test func testFabricWithCustomValues() throws {
        let fabric = Fabric(
            name: "Premium Silk",
            type: .silk,
            color: "Red",
            yardage: 3.0
        )
        
        fabric.content = "100% Silk"
        fabric.brand = "Designer Brand"
        fabric.width = 60.0
        fabric.cost = 25.99
        fabric.store = "Fabric Store"
        fabric.careInstructions = "Dry clean only"
        fabric.notes = "Beautiful silk fabric"
        fabric.purchaseDate = Date()
        
        #expect(fabric.content == "100% Silk")
        #expect(fabric.brand == "Designer Brand")
        #expect(fabric.width == 60.0)
        #expect(fabric.cost == 25.99)
        #expect(fabric.store == "Fabric Store")
        #expect(fabric.careInstructions == "Dry clean only")
        #expect(fabric.notes == "Beautiful silk fabric")
        #expect(fabric.purchaseDate != nil)
    }
    
    @Test func testFabricUniqueIds() throws {
        let fabric1 = Fabric(name: "Fabric 1")
        let fabric2 = Fabric(name: "Fabric 2")
        
        #expect(fabric1.id != fabric2.id)
    }
}