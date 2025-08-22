import XCTest
import SwiftData
@testable import SewSmart

@MainActor
final class AddPatternViewModelTests: XCTestCase {
    var viewModel: AddPatternViewModel!
    var modelContext: ModelContext!
    var container: ModelContainer!
    
    @MainActor
    override func setUp() {
        super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try! ModelContainer(for: Pattern.self, UserSettings.self, configurations: config)
        modelContext = container.mainContext
        viewModel = AddPatternViewModel(modelContext: modelContext)
    }
    
    override func tearDown() {
        viewModel = nil
        modelContext = nil
        container = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialState() {
        XCTAssertEqual(viewModel.name, "")
        XCTAssertEqual(viewModel.brand, "")
        XCTAssertEqual(viewModel.category, .dress)
        XCTAssertEqual(viewModel.difficulty, .beginner)
        XCTAssertEqual(viewModel.tags, "")
        XCTAssertEqual(viewModel.notes, "")
        XCTAssertNil(viewModel.selectedFileData)
        XCTAssertNil(viewModel.selectedFileName)
        XCTAssertNil(viewModel.selectedFileType)
        XCTAssertNil(viewModel.selectedImage)
        XCTAssertFalse(viewModel.showingDocumentPicker)
        XCTAssertFalse(viewModel.showingImageOptions)
        XCTAssertFalse(viewModel.showingCamera)
        XCTAssertFalse(viewModel.showingPhotoLibrary)
    }
    
    // MARK: - Form Validation Tests
    
    func testIsFormValid_WithEmptyName() {
        viewModel.name = ""
        XCTAssertFalse(viewModel.isFormValid)
    }
    
    func testIsFormValid_WithWhitespaceOnlyName() {
        viewModel.name = "   "
        XCTAssertFalse(viewModel.isFormValid)
    }
    
    func testIsFormValid_WithValidName() {
        viewModel.name = "Test Pattern"
        XCTAssertTrue(viewModel.isFormValid)
    }
    
    func testIsFormValid_WithNameContainingWhitespace() {
        viewModel.name = "  Test Pattern  "
        XCTAssertTrue(viewModel.isFormValid)
    }
    
    // MARK: - File Selection Tests
    
    func testHasSelectedFile_WithNoFile() {
        XCTAssertFalse(viewModel.hasSelectedFile)
    }
    
    func testHasSelectedFile_WithFileNameOnly() {
        viewModel.selectedFileName = "test.pdf"
        XCTAssertFalse(viewModel.hasSelectedFile)
    }
    
    func testHasSelectedFile_WithFileTypeOnly() {
        viewModel.selectedFileType = .pdf
        XCTAssertFalse(viewModel.hasSelectedFile)
    }
    
    func testHasSelectedFile_WithBothFileNameAndType() {
        viewModel.selectedFileName = "test.pdf"
        viewModel.selectedFileType = .pdf
        XCTAssertTrue(viewModel.hasSelectedFile)
    }
    
    func testSelectPDFDocument() {
        viewModel.selectPDFDocument()
        XCTAssertEqual(viewModel.selectedFileType, .pdf)
        XCTAssertTrue(viewModel.showingDocumentPicker)
    }
    
    func testSelectImage() {
        viewModel.selectImage()
        XCTAssertEqual(viewModel.selectedFileType, .image)
        XCTAssertTrue(viewModel.showingImageOptions)
    }
    
    func testShowCamera() {
        viewModel.showCamera()
        XCTAssertTrue(viewModel.showingCamera)
    }
    
    func testShowPhotoLibrary() {
        viewModel.showPhotoLibrary()
        XCTAssertTrue(viewModel.showingPhotoLibrary)
    }
    
    func testRemoveSelectedFile() {
        // Setup: Add a file
        viewModel.selectedFileData = Data()
        viewModel.selectedFileName = "test.pdf"
        viewModel.selectedFileType = .pdf
        viewModel.selectedImage = UIImage()
        
        // Action
        viewModel.removeSelectedFile()
        
        // Assertions
        XCTAssertNil(viewModel.selectedFileData)
        XCTAssertNil(viewModel.selectedFileName)
        XCTAssertNil(viewModel.selectedFileType)
        XCTAssertNil(viewModel.selectedImage)
    }
    
    // MARK: - Image Handling Tests
    
    func testHandleImageSelection_WithNilImage() {
        viewModel.handleImageSelection(nil)
        XCTAssertNil(viewModel.selectedFileData)
        XCTAssertNil(viewModel.selectedFileName)
    }
    
    func testHandleImageSelection_WithValidImage() {
        let image = UIImage(systemName: "star")!
        viewModel.handleImageSelection(image)
        
        XCTAssertNotNil(viewModel.selectedFileData)
        XCTAssertNotNil(viewModel.selectedFileName)
        XCTAssertEqual(viewModel.selectedFileType, .image)
        XCTAssertTrue(viewModel.selectedFileName!.contains("pattern_image_"))
        XCTAssertTrue(viewModel.selectedFileName!.hasSuffix(".jpg"))
    }
    
    // MARK: - Save Pattern Tests
    
    func testSavePattern_WithInvalidForm() {
        viewModel.name = ""
        let result = viewModel.savePattern()
        XCTAssertFalse(result)
    }
    
    func testSavePattern_WithValidForm() {
        viewModel.name = "Test Pattern"
        viewModel.brand = "Test Brand"
        viewModel.category = .top
        viewModel.difficulty = .intermediate
        viewModel.tags = "casual, summer"
        viewModel.notes = "Test notes"
        
        let result = viewModel.savePattern()
        XCTAssertTrue(result)
        
        // Verify pattern was saved to context
        let descriptor = FetchDescriptor<Pattern>()
        let patterns = try! modelContext.fetch(descriptor)
        XCTAssertEqual(patterns.count, 1)
        
        let savedPattern = patterns.first!
        XCTAssertEqual(savedPattern.name, "Test Pattern")
        XCTAssertEqual(savedPattern.brand, "Test Brand")
        XCTAssertEqual(savedPattern.category, .top)
        XCTAssertEqual(savedPattern.difficulty, .intermediate)
        XCTAssertEqual(savedPattern.tags, "casual, summer")
        XCTAssertEqual(savedPattern.notes, "Test notes")
    }
    
    func testSavePattern_WithFileData() {
        viewModel.name = "Test Pattern"
        viewModel.selectedFileData = Data([1, 2, 3, 4, 5])
        viewModel.selectedFileName = "test.pdf"
        viewModel.selectedFileType = .pdf
        
        let result = viewModel.savePattern()
        XCTAssertTrue(result)
        
        let descriptor = FetchDescriptor<Pattern>()
        let patterns = try! modelContext.fetch(descriptor)
        let savedPattern = patterns.first!
        
        XCTAssertEqual(savedPattern.pdfData, Data([1, 2, 3, 4, 5]))
        XCTAssertEqual(savedPattern.fileName, "test.pdf")
        XCTAssertEqual(savedPattern.fileType, .pdf)
    }
    
    func testSavePattern_TrimsWhitespace() {
        viewModel.name = "  Test Pattern  "
        viewModel.brand = "  Test Brand  "
        viewModel.tags = "  casual, summer  "
        viewModel.notes = "  Test notes  "
        
        let result = viewModel.savePattern()
        XCTAssertTrue(result)
        
        let descriptor = FetchDescriptor<Pattern>()
        let patterns = try! modelContext.fetch(descriptor)
        let savedPattern = patterns.first!
        
        XCTAssertEqual(savedPattern.name, "Test Pattern")
        XCTAssertEqual(savedPattern.brand, "Test Brand")
        XCTAssertEqual(savedPattern.tags, "casual, summer")
        XCTAssertEqual(savedPattern.notes, "Test notes")
    }
    
    // MARK: - Reset Form Tests
    
    func testResetForm() {
        // Setup: Fill form with data
        viewModel.name = "Test Pattern"
        viewModel.brand = "Test Brand"
        viewModel.category = .jacket
        viewModel.difficulty = .expert
        viewModel.tags = "test"
        viewModel.notes = "test notes"
        viewModel.selectedFileData = Data()
        viewModel.selectedFileName = "test.pdf"
        viewModel.selectedFileType = .pdf
        viewModel.selectedImage = UIImage()
        
        // Action
        viewModel.resetForm()
        
        // Assertions
        XCTAssertEqual(viewModel.name, "")
        XCTAssertEqual(viewModel.brand, "")
        XCTAssertEqual(viewModel.category, .dress)
        XCTAssertEqual(viewModel.difficulty, .beginner)
        XCTAssertEqual(viewModel.tags, "")
        XCTAssertEqual(viewModel.notes, "")
        XCTAssertNil(viewModel.selectedFileData)
        XCTAssertNil(viewModel.selectedFileName)
        XCTAssertNil(viewModel.selectedFileType)
        XCTAssertNil(viewModel.selectedImage)
    }
    
    // MARK: - Input Validation Tests
    
    func testValidateInput_WithinLimit() {
        let result = viewModel.validateInput("Test", maxLength: 10)
        XCTAssertEqual(result, "Test")
    }
    
    func testValidateInput_ExceedsLimit() {
        let longString = String(repeating: "a", count: 150)
        let result = viewModel.validateInput(longString, maxLength: 100)
        XCTAssertEqual(result.count, 100)
        XCTAssertEqual(result, String(repeating: "a", count: 100))
    }
    
    func testValidateInput_EmptyString() {
        let result = viewModel.validateInput("", maxLength: 100)
        XCTAssertEqual(result, "")
    }
}