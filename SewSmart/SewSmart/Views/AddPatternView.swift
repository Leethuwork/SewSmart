import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct AddPatternView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: AddPatternViewModel?
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Pattern Details")) {
                    TextField("Pattern Name", text: Binding(
                        get: { viewModel?.name ?? "" },
                        set: { viewModel?.name = $0 }
                    ))
                    TextField("Brand", text: Binding(
                        get: { viewModel?.brand ?? "" },
                        set: { viewModel?.brand = $0 }
                    ))
                    
                    Picker("Category", selection: Binding(
                        get: { viewModel?.category ?? .dress },
                        set: { viewModel?.category = $0 }
                    )) {
                        ForEach(PatternCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                    
                    Picker("Difficulty", selection: Binding(
                        get: { viewModel?.difficulty ?? .beginner },
                        set: { viewModel?.difficulty = $0 }
                    )) {
                        ForEach(PatternDifficulty.allCases, id: \.self) { difficulty in
                            Text(difficulty.rawValue).tag(difficulty)
                        }
                    }
                }
                
                Section(header: Text("Additional Info")) {
                    TextField("Tags (comma separated)", text: Binding(
                        get: { viewModel?.tags ?? "" },
                        set: { viewModel?.tags = $0 }
                    ))
                    TextField("Notes", text: Binding(
                        get: { viewModel?.notes ?? "" },
                        set: { viewModel?.notes = $0 }
                    ), axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section(header: Text("Pattern File")) {
                    if let fileName = viewModel?.selectedFileName, let fileType = viewModel?.selectedFileType {
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
                                viewModel?.removeSelectedFile()
                            }
                        }
                    } else {
                        VStack(spacing: 12) {
                            Button(action: {
                                viewModel?.selectPDFDocument()
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
                            .buttonStyle(PlainButtonStyle())
                            
                            Button(action: {
                                viewModel?.selectImage()
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
                            .buttonStyle(PlainButtonStyle())
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
                        if viewModel?.savePattern() == true {
                            dismiss()
                        }
                    }
                    .disabled(!(viewModel?.isFormValid ?? false))
                }
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = AddPatternViewModel(modelContext: modelContext)
                }
            }
            .sheet(isPresented: Binding(
                get: { viewModel?.showingDocumentPicker ?? false },
                set: { viewModel?.showingDocumentPicker = $0 }
            )) {
                DocumentPicker(
                    allowedContentTypes: [UTType.pdf],
                    selectedFileData: Binding(
                        get: { viewModel?.selectedFileData },
                        set: { viewModel?.selectedFileData = $0 }
                    ),
                    selectedFileName: Binding(
                        get: { viewModel?.selectedFileName },
                        set: { viewModel?.selectedFileName = $0 }
                    )
                )
            }
            .actionSheet(isPresented: Binding(
                get: { viewModel?.showingImageOptions ?? false },
                set: { viewModel?.showingImageOptions = $0 }
            )) {
                ActionSheet(
                    title: Text("Add Image"),
                    message: Text("Choose photo source"),
                    buttons: [
                        .default(Text("Take Photo")) {
                            viewModel?.showCamera()
                        },
                        .default(Text("Choose from Library")) {
                            viewModel?.showPhotoLibrary()
                        },
                        .cancel()
                    ]
                )
            }
            .sheet(isPresented: Binding(
                get: { viewModel?.showingCamera ?? false },
                set: { viewModel?.showingCamera = $0 }
            )) {
                ImagePicker(selectedImage: Binding(
                    get: { viewModel?.selectedImage },
                    set: { viewModel?.selectedImage = $0 }
                ), sourceType: .camera)
            }
            .sheet(isPresented: Binding(
                get: { viewModel?.showingPhotoLibrary ?? false },
                set: { viewModel?.showingPhotoLibrary = $0 }
            )) {
                ImagePicker(selectedImage: Binding(
                    get: { viewModel?.selectedImage },
                    set: { viewModel?.selectedImage = $0 }
                ), sourceType: .photoLibrary)
            }
            .onChange(of: viewModel?.selectedImage) { newImage in
                viewModel?.handleImageSelection(newImage)
            }
        }
    }
}

#Preview {
    AddPatternView()
        .modelContainer(for: Pattern.self, inMemory: true)
}