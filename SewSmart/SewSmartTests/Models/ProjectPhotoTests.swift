import Testing
import Foundation
@testable import SewSmart

struct ProjectPhotoTests {
    
    @Test func testProjectPhotoInitialization() {
        let imageData = "Mock image data".data(using: .utf8)!
        let photo = ProjectPhoto(
            imageData: imageData,
            caption: "Progress photo",
            stage: .fitting
        )
        
        #expect(photo.imageData == imageData)
        #expect(photo.caption == "Progress photo")
        #expect(photo.stage == .fitting)
        #expect(photo.project == nil)
    }
    
    @Test func testProjectPhotoInitializationWithDefaults() {
        let photo = ProjectPhoto()
        
        #expect(photo.imageData == nil)
        #expect(photo.caption == "")
        #expect(photo.stage == .inProgress)
        #expect(photo.project == nil)
    }
    
    @Test func testProjectPhotoIdUniqueness() {
        let photo1 = ProjectPhoto(caption: "Photo 1")
        let photo2 = ProjectPhoto(caption: "Photo 2")
        
        #expect(photo1.id != photo2.id)
    }
    
    @Test func testProjectPhotoCreatedDateIsSet() {
        let beforeCreation = Date()
        let photo = ProjectPhoto(caption: "Test Photo")
        let afterCreation = Date()
        
        #expect(photo.createdDate >= beforeCreation)
        #expect(photo.createdDate <= afterCreation)
    }
    
    @Test func testProjectPhotoPropertyModification() {
        let photo = ProjectPhoto()
        let newImageData = "New image data".data(using: .utf8)!
        
        photo.imageData = newImageData
        photo.caption = "Updated caption"
        photo.stage = .finished
        
        #expect(photo.imageData == newImageData)
        #expect(photo.caption == "Updated caption")
        #expect(photo.stage == .finished)
    }
    
    @Test func testProjectPhotoWithProject() {
        let project = Project(name: "Test Project")
        let photo = ProjectPhoto(caption: "Project photo", stage: .inProgress)
        
        #expect(photo.project == nil)
        
        photo.project = project
        
        #expect(photo.project?.name == "Test Project")
    }
    
    @Test func testProjectPhotoWithAllStages() {
        let stages: [PhotoStage] = [.planning, .cutting, .inProgress, .fitting, .finished, .detail]
        
        for stage in stages {
            let photo = ProjectPhoto(caption: "Stage test", stage: stage)
            #expect(photo.stage == stage)
        }
    }
    
    @Test func testProjectPhotoWithNilImageData() {
        let photo = ProjectPhoto(imageData: nil, caption: "No image", stage: .planning)
        
        #expect(photo.imageData == nil)
        #expect(photo.caption == "No image")
        #expect(photo.stage == .planning)
    }
    
    @Test func testProjectPhotoWithEmptyCaption() {
        let photo = ProjectPhoto(caption: "", stage: .detail)
        
        #expect(photo.caption == "")
        #expect(photo.stage == .detail)
    }
    
    @Test func testProjectPhotoMultiplePhotosForProject() {
        let project = Project(name: "Multi-Photo Project")
        let photo1 = ProjectPhoto(caption: "Photo 1", stage: .cutting)
        let photo2 = ProjectPhoto(caption: "Photo 2", stage: .inProgress)
        let photo3 = ProjectPhoto(caption: "Photo 3", stage: .finished)
        
        // Add photos to project (Note: In real SwiftData usage, this would be managed by the context)
        project.photos.append(photo1)
        project.photos.append(photo2)
        project.photos.append(photo3)
        photo1.project = project
        photo2.project = project
        photo3.project = project
        
        #expect(project.photos.count == 3)
        #expect(photo1.project?.name == "Multi-Photo Project")
        #expect(photo2.project?.name == "Multi-Photo Project")
        #expect(photo3.project?.name == "Multi-Photo Project")
    }
}

struct PhotoStageTests {
    
    @Test func testPhotoStageRawValues() {
        #expect(PhotoStage.planning.rawValue == "Planning")
        #expect(PhotoStage.cutting.rawValue == "Cutting")
        #expect(PhotoStage.inProgress.rawValue == "In Progress")
        #expect(PhotoStage.fitting.rawValue == "Fitting")
        #expect(PhotoStage.finished.rawValue == "Finished")
        #expect(PhotoStage.detail.rawValue == "Detail")
    }
    
    @Test func testPhotoStageAllCases() {
        let allCases = PhotoStage.allCases
        
        #expect(allCases.count == 6)
        #expect(allCases.contains(.planning))
        #expect(allCases.contains(.cutting))
        #expect(allCases.contains(.inProgress))
        #expect(allCases.contains(.fitting))
        #expect(allCases.contains(.finished))
        #expect(allCases.contains(.detail))
    }
    
    @Test func testPhotoStageCodable() throws {
        let stage = PhotoStage.fitting
        
        // Test encoding
        let encoder = JSONEncoder()
        let encodedData = try encoder.encode(stage)
        
        // Test decoding
        let decoder = JSONDecoder()
        let decodedStage = try decoder.decode(PhotoStage.self, from: encodedData)
        
        #expect(decodedStage == .fitting)
    }
    
    @Test func testPhotoStageInitFromRawValue() {
        #expect(PhotoStage(rawValue: "Planning") == .planning)
        #expect(PhotoStage(rawValue: "Cutting") == .cutting)
        #expect(PhotoStage(rawValue: "In Progress") == .inProgress)
        #expect(PhotoStage(rawValue: "Fitting") == .fitting)
        #expect(PhotoStage(rawValue: "Finished") == .finished)
        #expect(PhotoStage(rawValue: "Detail") == .detail)
        #expect(PhotoStage(rawValue: "Invalid") == nil)
    }
    
    @Test func testPhotoStageEquality() {
        #expect(PhotoStage.planning == PhotoStage.planning)
        #expect(PhotoStage.planning != PhotoStage.finished)
    }
    
    @Test func testPhotoStageStringRepresentation() {
        #expect("\(PhotoStage.planning)" == "planning")
        #expect("\(PhotoStage.cutting)" == "cutting")
        #expect("\(PhotoStage.inProgress)" == "inProgress")
        #expect("\(PhotoStage.fitting)" == "fitting")
        #expect("\(PhotoStage.finished)" == "finished")
        #expect("\(PhotoStage.detail)" == "detail")
    }
    
    @Test func testPhotoStageDefaultValue() {
        // Test that the default stage in ProjectPhoto initializer is inProgress
        let photo = ProjectPhoto()
        #expect(photo.stage == .inProgress)
    }
}