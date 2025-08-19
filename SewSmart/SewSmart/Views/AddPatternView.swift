import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct AddPatternView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var brand = ""
    @State private var category = PatternCategory.dress
    @State private var difficulty = PatternDifficulty.beginner
    @State private var tags = ""
    @State private var notes = ""
    @State private var settingsManager: UserSettingsManager?
    @State private var showingDocumentPicker = false
    @State private var showingImageOptions = false
    @State private var showingCamera = false
    @State private var showingPhotoLibrary = false
    @State private var selectedFileData: Data?
    @State private var selectedFileName: String?
    @State private var selectedFileType: PatternFileType?
    @State private var selectedImage: UIImage?
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Pattern Details")) {
                    TextField("Pattern Name", text: $name)
                    TextField("Brand", text: $brand)
                    
                    Picker("Category", selection: $category) {
                        ForEach(PatternCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                    
                    Picker("Difficulty", selection: $difficulty) {
                        ForEach(PatternDifficulty.allCases, id: \.self) { difficulty in
                            Text(difficulty.rawValue).tag(difficulty)
                        }
                    }
                }
                
                Section(header: Text("Additional Info")) {
                    TextField("Tags (comma separated)", text: $tags)
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section(header: Text("Pattern File")) {
                    if let fileName = selectedFileName, let fileType = selectedFileType {
                        HStack {
                            Image(systemName: fileType.icon)
                                .foregroundColor(.blue)
                            VStack(alignment: .leading) {
                                Text(fileName)
                                    .font(.headline)
                                Text(fileType.rawValue)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button("Remove", role: .destructive) {
                                selectedFileData = nil
                                selectedFileName = nil
                                selectedFileType = nil
                                selectedImage = nil
                            }
                        }
                    } else {
                        VStack(spacing: 12) {
                            Button(action: {
                                selectedFileType = .pdf
                                showingDocumentPicker = true
                            }) {
                                HStack {
                                    Image(systemName: "doc.fill")
                                        .foregroundColor(.red)
                                    Text("Add PDF Document")
                                        .fontWeight(.medium)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .foregroundColor(.primary)
                                .cornerRadius(8)
                            }
                            
                            Button(action: {
                                selectedFileType = .image
                                showingImageOptions = true
                            }) {
                                HStack {
                                    Image(systemName: "photo.fill")
                                        .foregroundColor(.blue)
                                    Text("Add Image")
                                        .fontWeight(.medium)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .foregroundColor(.primary)
                                .cornerRadius(8)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Pattern")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        savePattern()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                if settingsManager == nil {
                    settingsManager = UserSettingsManager(modelContext: modelContext)
                }
            }
            .sheet(isPresented: $showingDocumentPicker) {
                DocumentPicker(
                    allowedContentTypes: [UTType.pdf],
                    selectedFileData: $selectedFileData,
                    selectedFileName: $selectedFileName
                )
            }
            .actionSheet(isPresented: $showingImageOptions) {
                ActionSheet(
                    title: Text("Add Image"),
                    message: Text("Choose photo source"),
                    buttons: [
                        .default(Text("Take Photo")) {
                            showingCamera = true
                        },
                        .default(Text("Choose from Library")) {
                            showingPhotoLibrary = true
                        },
                        .cancel()
                    ]
                )
            }
            .sheet(isPresented: $showingCamera) {
                ImagePicker(selectedImage: $selectedImage, sourceType: .camera)
            }
            .sheet(isPresented: $showingPhotoLibrary) {
                ImagePicker(selectedImage: $selectedImage, sourceType: .photoLibrary)
            }
            .onChange(of: selectedImage) { newImage in
                if let image = newImage, let imageData = image.jpegData(compressionQuality: 0.8) {
                    selectedFileData = imageData
                    selectedFileName = "pattern_image_\(Date().timeIntervalSince1970).jpg"
                    selectedFileType = .image
                }
            }
        }
    }
    
    private func savePattern() {
        let newPattern = Pattern(
            name: name,
            brand: brand,
            category: category,
            difficulty: difficulty
        )
        newPattern.tags = tags
        newPattern.notes = notes
        
        // Save file data
        if let fileData = selectedFileData {
            newPattern.pdfData = fileData
            newPattern.fileName = selectedFileName
            newPattern.fileType = selectedFileType
        }
        
        modelContext.insert(newPattern)
        
        // Add to history
        settingsManager?.addHistory(
            action: .addedPattern,
            details: "\(name) - \(category.rawValue)",
            context: .patterns
        )
        
        dismiss()
    }
}

#Preview {
    AddPatternView()
        .modelContainer(for: Pattern.self, inMemory: true)
}