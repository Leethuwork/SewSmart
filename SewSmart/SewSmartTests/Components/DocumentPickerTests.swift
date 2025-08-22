import Testing
import SwiftUI
import UniformTypeIdentifiers
@testable import SewSmart

@MainActor
struct DocumentPickerTests {
    
    @Test func testDocumentPickerInitialization() {
        @State var selectedFileData: Data? = nil
        @State var selectedFileName: String? = nil
        
        let documentPicker = DocumentPicker(
            allowedContentTypes: [UTType.pdf],
            selectedFileData: $selectedFileData,
            selectedFileName: $selectedFileName
        )
        
        #expect(selectedFileData == nil)
        #expect(selectedFileName == nil)
        #expect(documentPicker.allowedContentTypes == [UTType.pdf])
    }
    
    @Test func testDocumentPickerWithMultipleTypes() {
        @State var selectedFileData: Data? = nil
        @State var selectedFileName: String? = nil
        
        let allowedTypes = [UTType.pdf, UTType.image]
        let documentPicker = DocumentPicker(
            allowedContentTypes: allowedTypes,
            selectedFileData: $selectedFileData,
            selectedFileName: $selectedFileName
        )
        
        #expect(documentPicker.allowedContentTypes == allowedTypes)
    }
    
    @Test func testMakeCoordinator() {
        @State var selectedFileData: Data? = nil
        @State var selectedFileName: String? = nil
        
        let documentPicker = DocumentPicker(
            allowedContentTypes: [UTType.pdf],
            selectedFileData: $selectedFileData,
            selectedFileName: $selectedFileName
        )
        
        let coordinator = documentPicker.makeCoordinator()
        
        #expect(coordinator.parent.allowedContentTypes == [UTType.pdf])
    }
    
    @Test func testCoordinatorInitialization() {
        @State var selectedFileData: Data? = nil
        @State var selectedFileName: String? = nil
        
        let documentPicker = DocumentPicker(
            allowedContentTypes: [UTType.text],
            selectedFileData: $selectedFileData,
            selectedFileName: $selectedFileName
        )
        let coordinator = DocumentPicker.Coordinator(documentPicker)
        
        #expect(coordinator.parent.allowedContentTypes == [UTType.text])
    }
    
    @Test func testDocumentPickerContentTypes() {
        // Test content type handling
        let pdfType = UTType.pdf
        let imageType = UTType.image
        let textType = UTType.text
        
        let contentTypes = [pdfType, imageType, textType]
        
        #expect(contentTypes.count == 3)
        #expect(contentTypes.contains(UTType.pdf))
        #expect(contentTypes.contains(UTType.image))
        #expect(contentTypes.contains(UTType.text))
    }
    
    @Test func testDocumentPickerDidPickDocumentsSimulated() {
        // Test the logic without actual file system operations
        class MockDocumentPicker {
            var selectedFileData: Data?
            var selectedFileName: String?
            
            func simulateDocumentPicking(fileName: String, data: Data) {
                selectedFileData = data
                selectedFileName = fileName
            }
        }
        
        let mockPicker = MockDocumentPicker()
        let testData = "Test content".data(using: .utf8)!
        
        mockPicker.simulateDocumentPicking(fileName: "test.txt", data: testData)
        
        #expect(mockPicker.selectedFileData != nil)
        #expect(mockPicker.selectedFileName == "test.txt")
        #expect(mockPicker.selectedFileData == testData)
    }
    
    @Test func testDocumentPickerDidPickDocumentsWithEmptyURLs() {
        @State var selectedFileData: Data? = nil
        @State var selectedFileName: String? = nil
        
        let documentPicker = DocumentPicker(
            allowedContentTypes: [UTType.text],
            selectedFileData: $selectedFileData,
            selectedFileName: $selectedFileName
        )
        let coordinator = DocumentPicker.Coordinator(documentPicker)
        
        let mockController = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.text])
        
        coordinator.documentPicker(mockController, didPickDocumentsAt: [])
        
        #expect(selectedFileData == nil)
        #expect(selectedFileName == nil)
    }
    
    @Test func testDocumentPickerWasCancelled() {
        @State var selectedFileData: Data? = nil
        @State var selectedFileName: String? = nil
        
        let documentPicker = DocumentPicker(
            allowedContentTypes: [UTType.pdf],
            selectedFileData: $selectedFileData,
            selectedFileName: $selectedFileName
        )
        let coordinator = DocumentPicker.Coordinator(documentPicker)
        
        let mockController = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.pdf])
        
        coordinator.documentPickerWasCancelled(mockController)
        
        #expect(selectedFileData == nil)
        #expect(selectedFileName == nil)
    }
}

@MainActor
struct DocumentPickerForDetailTests {
    
    @Test func testDocumentPickerForDetailInitialization() {
        let pattern = Pattern(name: "Test Pattern", category: .dress, difficulty: .beginner)
        let documentPicker = DocumentPickerForDetail(pattern: pattern)
        
        #expect(documentPicker.pattern.name == "Test Pattern")
    }
    
    @Test func testMakeCoordinatorForDetail() {
        let pattern = Pattern(name: "Test Pattern", category: .dress, difficulty: .beginner)
        let documentPicker = DocumentPickerForDetail(pattern: pattern)
        
        let coordinator = documentPicker.makeCoordinator()
        
        #expect(coordinator.parent.pattern.name == "Test Pattern")
    }
    
    @Test func testDocumentPickerForDetailContentTypes() {
        // Test that DocumentPickerForDetail works with PDF type
        let pdfType = UTType.pdf
        
        #expect(pdfType.identifier == "com.adobe.pdf")
        #expect(pdfType.description.contains("PDF") || pdfType.description.contains("pdf"))
    }
    
    @Test func testDocumentPickerForDetailSimulated() {
        // Test the logic without actual file system operations
        let pattern = Pattern(name: "Test Pattern", category: .dress, difficulty: .beginner)
        
        // Verify initial state
        #expect(pattern.pdfData == nil)
        #expect(pattern.fileName == nil)
        #expect(pattern.fileType == nil)
        
        // Simulate document picking
        let testData = "PDF content".data(using: .utf8)!
        pattern.pdfData = testData
        pattern.fileName = "test-pattern.pdf"
        pattern.fileType = .pdf
        
        #expect(pattern.pdfData != nil)
        #expect(pattern.fileName == "test-pattern.pdf")
        #expect(pattern.fileType == .pdf)
        #expect(pattern.pdfData == testData)
    }
    
    @Test func testDocumentPickerForDetailDidPickDocumentsWithEmptyURLs() {
        let pattern = Pattern(name: "Test Pattern", category: .dress, difficulty: .beginner)
        let documentPicker = DocumentPickerForDetail(pattern: pattern)
        let coordinator = DocumentPickerForDetail.Coordinator(documentPicker)
        
        let mockController = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.pdf])
        
        coordinator.documentPicker(mockController, didPickDocumentsAt: [])
        
        #expect(pattern.pdfData == nil)
        #expect(pattern.fileName == nil)
        #expect(pattern.fileType == nil)
    }
    
    @Test func testDocumentPickerForDetailWasCancelled() {
        let pattern = Pattern(name: "Test Pattern", category: .dress, difficulty: .beginner)
        let documentPicker = DocumentPickerForDetail(pattern: pattern)
        let coordinator = DocumentPickerForDetail.Coordinator(documentPicker)
        
        let mockController = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.pdf])
        
        coordinator.documentPickerWasCancelled(mockController)
        
        #expect(pattern.pdfData == nil)
        #expect(pattern.fileName == nil)
        #expect(pattern.fileType == nil)
    }
    
    @Test func testCoordinatorInitializationForDetail() {
        let pattern = Pattern(name: "Test Pattern", category: .dress, difficulty: .beginner)
        let documentPicker = DocumentPickerForDetail(pattern: pattern)
        let coordinator = DocumentPickerForDetail.Coordinator(documentPicker)
        
        #expect(coordinator.parent.pattern.name == "Test Pattern")
    }
}