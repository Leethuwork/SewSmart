import SwiftUI
import SwiftData

struct PatternDetailView: View {
    @Bindable var pattern: Pattern
    @Environment(\.dismiss) private var dismiss
    @State private var isEditing = false
    @State private var showingPrint = false
    @State private var showingShare = false
    @State private var showingDocumentPicker = false
    @State private var showingImageOptions = false
    @State private var showingCamera = false
    @State private var showingPhotoLibrary = false
    @State private var selectedImage: UIImage?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Pattern File Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Pattern File")
                            .font(.headline)
                        
                        if let fileData = pattern.pdfData, 
                           let fileName = pattern.fileName,
                           let fileType = pattern.fileType {
                            HStack {
                                Image(systemName: fileType.icon)
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                
                                VStack(alignment: .leading) {
                                    Text(fileName)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text(fileType.rawValue)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if isEditing {
                                    Button("Remove", role: .destructive) {
                                        pattern.pdfData = nil
                                        pattern.fileName = nil
                                        pattern.fileType = nil
                                    }
                                } else {
                                    HStack(spacing: 12) {
                                        Button(action: { showingPrint = true }) {
                                            Image(systemName: "printer")
                                                .font(.title3)
                                                .foregroundColor(.blue)
                                        }
                                        
                                        Button(action: { showingShare = true }) {
                                            Image(systemName: "square.and.arrow.up")
                                                .font(.title3)
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        } else if isEditing {
                            VStack(spacing: 12) {
                                Button(action: {
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
                        } else {
                            Text("No pattern file attached")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .italic()
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Pattern Info
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Category")
                                .font(.headline)
                            Spacer()
                            if isEditing {
                                Picker("Category", selection: $pattern.category) {
                                    ForEach(PatternCategory.allCases, id: \.self) { category in
                                        Text(category.rawValue).tag(category)
                                    }
                                }
                                .pickerStyle(.menu)
                            } else {
                                Text(pattern.category.rawValue)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.2))
                                    .foregroundColor(.blue)
                                    .cornerRadius(8)
                            }
                        }
                        
                        HStack {
                            Text("Difficulty")
                                .font(.headline)
                            Spacer()
                            if isEditing {
                                Picker("Difficulty", selection: $pattern.difficulty) {
                                    ForEach(PatternDifficulty.allCases, id: \.self) { difficulty in
                                        Text(difficulty.rawValue).tag(difficulty)
                                    }
                                }
                                .pickerStyle(.menu)
                            } else {
                                Text(pattern.difficulty.rawValue)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(pattern.difficulty.color).opacity(0.2))
                                    .foregroundColor(Color(pattern.difficulty.color))
                                    .cornerRadius(8)
                            }
                        }
                        
                        if isEditing {
                            TextField("Brand", text: $pattern.brand)
                                .textFieldStyle(.roundedBorder)
                        } else if !pattern.brand.isEmpty {
                            Text("Brand: \(pattern.brand)")
                                .font(.subheadline)
                        }
                        
                        // Rating
                        HStack {
                            Text("Rating")
                                .font(.headline)
                            Spacer()
                            HStack(spacing: 4) {
                                ForEach(1...5, id: \.self) { star in
                                    Button(action: {
                                        if isEditing {
                                            pattern.rating = star
                                        }
                                    }) {
                                        Image(systemName: star <= pattern.rating ? "star.fill" : "star")
                                            .foregroundColor(.yellow)
                                    }
                                    .disabled(!isEditing)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Tags
                    VStack(alignment: .leading) {
                        Text("Tags")
                            .font(.headline)
                        
                        if isEditing {
                            TextField("Tags (comma separated)", text: $pattern.tags)
                                .textFieldStyle(.roundedBorder)
                        } else if pattern.tags.isEmpty {
                            Text("No tags")
                                .foregroundColor(.secondary)
                                .italic()
                        } else {
                            Text(pattern.tags)
                                .font(.body)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Notes
                    VStack(alignment: .leading) {
                        Text("Notes")
                            .font(.headline)
                        
                        if isEditing {
                            TextField("Notes", text: $pattern.notes, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(3...10)
                        } else if pattern.notes.isEmpty {
                            Text("No notes")
                                .foregroundColor(.secondary)
                                .italic()
                        } else {
                            Text(pattern.notes)
                                .font(.body)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle(pattern.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "Save" : "Edit") {
                        isEditing.toggle()
                    }
                }
            }
            .sheet(isPresented: $showingPrint) {
                if let fileData = pattern.pdfData,
                   let fileName = pattern.fileName,
                   let fileType = pattern.fileType {
                    PrintController(data: fileData, fileName: fileName, fileType: fileType)
                }
            }
            .sheet(isPresented: $showingShare) {
                if let fileData = pattern.pdfData,
                   let fileName = pattern.fileName {
                    let tempURL = createTempFile(data: fileData, fileName: fileName)
                    ShareSheet(items: [tempURL])
                }
            }
            .sheet(isPresented: $showingDocumentPicker) {
                DocumentPickerForDetail(pattern: pattern)
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
                    pattern.pdfData = imageData
                    pattern.fileName = "pattern_image_\(Date().timeIntervalSince1970).jpg"
                    pattern.fileType = .image
                }
            }
        }
    }
    
    private func createTempFile(data: Data, fileName: String) -> URL {
        let tempDirectory = FileManager.default.temporaryDirectory
        let tempURL = tempDirectory.appendingPathComponent(fileName)
        try? data.write(to: tempURL)
        return tempURL
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Pattern.self, configurations: config)
    let context = container.mainContext
    
    let samplePattern = Pattern(name: "Summer Dress", brand: "Burda", category: .dress, difficulty: .intermediate)
    context.insert(samplePattern)
    
    return PatternDetailView(pattern: samplePattern)
        .modelContainer(container)
}