import SwiftUI
import SwiftData
import UniformTypeIdentifiers

@Observable
final class AddPatternViewModel {
    var name: String = ""
    var brand: String = ""
    var category: PatternCategory = .dress
    var difficulty: PatternDifficulty = .beginner
    var tags: String = ""
    var notes: String = ""
    var selectedFileData: Data?
    var selectedFileName: String?
    var selectedFileType: PatternFileType?
    var selectedImage: UIImage?
    
    var showingDocumentPicker: Bool = false
    var showingImageOptions: Bool = false
    var showingCamera: Bool = false
    var showingPhotoLibrary: Bool = false
    
    private let modelContext: ModelContext
    private var settingsManager: UserSettingsManager?
    
    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var hasSelectedFile: Bool {
        selectedFileName != nil && selectedFileType != nil
    }
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        setupSettingsManager()
    }
    
    private func setupSettingsManager() {
        settingsManager = UserSettingsManager(modelContext: modelContext)
    }
    
    func selectPDFDocument() {
        selectedFileType = .pdf
        showingDocumentPicker = true
    }
    
    func selectImage() {
        selectedFileType = .image
        showingImageOptions = true
    }
    
    func showCamera() {
        showingCamera = true
    }
    
    func showPhotoLibrary() {
        showingPhotoLibrary = true
    }
    
    func removeSelectedFile() {
        selectedFileData = nil
        selectedFileName = nil
        selectedFileType = nil
        selectedImage = nil
    }
    
    func handleImageSelection(_ image: UIImage?) {
        guard let image = image else { return }
        
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            selectedFileData = imageData
            selectedFileName = "pattern_image_\(Date().timeIntervalSince1970).jpg"
            selectedFileType = .image
        }
    }
    
    func savePattern() -> Bool {
        guard isFormValid else { return false }
        
        let newPattern = Pattern(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            brand: brand.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category,
            difficulty: difficulty
        )
        
        newPattern.tags = tags.trimmingCharacters(in: .whitespacesAndNewlines)
        newPattern.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let fileData = selectedFileData {
            newPattern.pdfData = fileData
            newPattern.fileName = selectedFileName
            newPattern.fileType = selectedFileType
        }
        
        do {
            modelContext.insert(newPattern)
            try modelContext.save()
            
            settingsManager?.addHistory(
                action: .addedPattern,
                details: "\(newPattern.name) - \(newPattern.category.rawValue)",
                context: .patterns
            )
            
            return true
        } catch {
            return false
        }
    }
    
    func resetForm() {
        name = ""
        brand = ""
        category = .dress
        difficulty = .beginner
        tags = ""
        notes = ""
        removeSelectedFile()
    }
    
    func validateInput(_ input: String, maxLength: Int = 100) -> String {
        String(input.prefix(maxLength))
    }
}