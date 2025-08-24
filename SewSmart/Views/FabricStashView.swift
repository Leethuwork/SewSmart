import SwiftUI
import SwiftData
import PhotosUI

struct FabricStashView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: FabricViewModel?
    @EnvironmentObject private var dependencyContainer: DependencyContainer
    
    private var filteredFabrics: [Fabric] {
        viewModel?.fabrics ?? []
    }
    
    var body: some View {
        SewSmartNavigationStack {
            VStack(spacing: 0) {
                // Custom Navigation Bar with Stats
                SewSmartNavigationBar(
                    title: "Fabric Stash",
                    subtitle: String(format: "%.1f yards • $%.0f", viewModel?.totalYardage ?? 0, viewModel?.totalValue ?? 0),
                    trailingIcon: "plus",
                    trailingAction: { viewModel?.showingAddFabric = true }
                )
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Fabric Stash. Total: \(String(format: "%.1f", viewModel?.totalYardage ?? 0)) yards, worth \(String(format: "$%.0f", viewModel?.totalValue ?? 0))")
                .accessibilityHint("Add new fabric button available")
                
                VStack(spacing: DesignSystemExtended.mediumSpacing) {
                    // Search Bar
                    SewSmartSearchBar(
                        searchText: Binding(
                            get: { viewModel?.searchText ?? "" },
                            set: { viewModel?.updateSearchText($0) }
                        ),
                        placeholder: "Search fabrics..."
                    )
                    .padding(.horizontal, DesignSystem.cardPadding)
                    
                    // Type Filter
                    FilterChipsView(
                        options: FabricType.allCases,
                        selectedOption: Binding(
                            get: { viewModel?.selectedType },
                            set: { type in
                                viewModel?.selectedType = type
                                Task {
                                    await viewModel?.loadFabrics()
                                }
                            }
                        )
                    )
                }
                .padding(.top, DesignSystemExtended.smallSpacing)
                
                // Content Area with Loading States
                LoadingStateView(
                    state: viewModel?.fabricsState ?? .idle,
                    retryAction: {
                        Task {
                            await viewModel?.loadFabrics()
                        }
                    }
                ) { fabrics in
                    if fabrics.isEmpty {
                        EmptyStateView(
                            title: "No Fabrics Found",
                            description: viewModel?.selectedType != nil || !(viewModel?.searchText.isEmpty ?? true) ?
                                "Try adjusting your search or filters" :
                                "Build your fabric stash by adding your first fabric",
                            systemImage: "square.stack.3d.down.forward.fill",
                            actionTitle: "Add Fabric",
                            action: { viewModel?.showingAddFabric = true }
                        )
                    } else {
                        ScrollView {
                            LazyVGrid(columns: gridColumns, spacing: DesignSystem.cardSpacing) {
                                ForEach(fabrics) { fabric in
                                    FabricCardView(fabric: fabric)
                                        .onTapGesture {
                                            viewModel?.selectedFabric = fabric
                                        }
                                }
                            }
                            .padding(.horizontal, DesignSystem.cardPadding)
                            .padding(.bottom, 100) // Tab bar spacing
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: Binding(
                get: { viewModel?.showingAddFabric ?? false },
                set: { _ in viewModel?.showingAddFabric = false }
            )) {
                AddFabricView()
            }
            .sheet(item: Binding(
                get: { viewModel?.selectedFabric },
                set: { _ in viewModel?.selectedFabric = nil }
            )) { fabric in
                FabricDetailView(fabric: fabric)
            }
            .task {
                if viewModel == nil {
                    viewModel = dependencyContainer.fabricViewModel
                    await viewModel?.loadFabrics()
                }
            }
        }
    }
    
    private let gridColumns = [
        GridItem(.flexible(), spacing: DesignSystem.cardSpacing),
        GridItem(.flexible(), spacing: DesignSystem.cardSpacing)
    ]
}

struct VibrantFabricCardView: View {
    let fabric: Fabric
    
    private var typeColor: Color {
        switch fabric.type {
        case .cotton:
            return DesignSystem.primaryTeal
        case .silk:
            return DesignSystem.primaryPurple
        case .wool:
            return DesignSystem.primaryOrange
        case .linen:
            return DesignSystem.primaryYellow
        case .polyester:
            return DesignSystem.primaryPink
        case .rayon:
            return DesignSystem.primaryPink
        case .denim:
            return Color.blue
        case .jersey:
            return Color.green
        case .fleece:
            return Color.purple
        case .other:
            return Color.gray
        }
    }
    
    private var cardGradient: LinearGradient {
        LinearGradient(
            colors: [typeColor.opacity(0.1), typeColor.opacity(0.05)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Photo or placeholder with vibrant border
            RoundedRectangle(cornerRadius: DesignSystem.smallCornerRadius)
                .fill(typeColor.opacity(0.1))
                .frame(height: 120)
                .overlay(
                    Group {
                        if let photoData = fabric.photoData, let uiImage = UIImage(data: photoData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 120)
                                .clipped()
                                .cornerRadius(DesignSystem.smallCornerRadius)
                        } else {
                            VStack {
                                Text("🧵")
                                    .font(.title)
                                Text("No Photo")
                                    .font(DesignSystem.captionFont)
                                    .foregroundColor(typeColor)
                            }
                        }
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.smallCornerRadius)
                        .stroke(typeColor, lineWidth: 2)
                )
            
            VStack(alignment: .leading, spacing: 6) {
                Text("✨ \(fabric.name)")
                    .font(DesignSystem.headlineFont)
                    .foregroundColor(DesignSystem.primaryTextColor)
                    .lineLimit(1)
                
                HStack {
                    Text("🏷️ \(fabric.type.rawValue)")
                        .font(DesignSystem.captionFont)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(typeColor)
                        .clipShape(Capsule())
                    
                    Spacer()
                    
                    Text("📏 \(String(format: "%.1f", fabric.yardage)) yds")
                        .font(DesignSystem.captionFont)
                        .fontWeight(.bold)
                        .foregroundColor(typeColor)
                }
                
                if !fabric.color.isEmpty {
                    Text("🎨 \(fabric.color)")
                        .font(DesignSystem.captionFont)
                        .foregroundColor(DesignSystem.secondaryTextColor)
                }
            }
        }
        .vibrantCard(gradient: cardGradient, borderColor: typeColor)
        .shadow(color: typeColor.opacity(0.2), radius: 6, x: 0, y: 3)
    }
}


struct AddFabricView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var settingsManager: UserSettingsManager?
    
    @State private var name = ""
    @State private var type = FabricType.cotton
    @State private var color = ""
    @State private var content = ""
    @State private var brand = ""
    @State private var width: Double = 45
    @State private var yardage: Double = 0
    @State private var cost: Double = 0
    @State private var store = ""
    @State private var purchaseDate = Date()
    @State private var hasPurchaseDate = false
    @State private var careInstructions = ""
    @State private var notes = ""
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingPhotoOptions = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Photo")) {
                    if let selectedImage = selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 200)
                            .cornerRadius(12)
                            .onTapGesture {
                                showingPhotoOptions = true
                            }
                    } else {
                        Button("Add Photo") {
                            showingPhotoOptions = true
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 100)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            VStack {
                                Image(systemName: "camera.fill")
                                    .font(.title2)
                                    .foregroundColor(.gray)
                                Text("Add Photo")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        )
                    }
                }
                
                Section(header: Text("Fabric Details")) {
                    TextField("Fabric Name", text: $name)
                    
                    Picker("Type", selection: $type) {
                        ForEach(FabricType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    
                    TextField("Color", text: $color)
                    TextField("Content (e.g., 100% Cotton)", text: $content)
                    TextField("Brand", text: $brand)
                }
                
                Section(header: Text("Measurements & Cost")) {
                    HStack {
                        Text("Width")
                        Spacer()
                        TextField("Width", value: $width, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                            .keyboardType(.decimalPad)
                        Text(settingsManager?.userSettings.preferredMeasurementUnit.abbreviation ?? "in")
                    }
                    
                    HStack {
                        Text("Yardage")
                        Spacer()
                        TextField("Yardage", value: $yardage, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                            .keyboardType(.decimalPad)
                        Text(settingsManager?.userSettings.preferredLengthUnit.abbreviation ?? "yd")
                    }
                    
                    HStack {
                        Text("Cost")
                        Spacer()
                        TextField("Cost", value: $cost, format: .currency(code: "USD"))
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                            .keyboardType(.decimalPad)
                    }
                }
                
                Section(header: Text("Purchase Info")) {
                    TextField("Store", text: $store)
                    
                    Toggle("Set Purchase Date", isOn: $hasPurchaseDate)
                    if hasPurchaseDate {
                        DatePicker("Purchase Date", selection: $purchaseDate, displayedComponents: .date)
                    }
                }
                
                Section(header: Text("Care & Notes")) {
                    TextField("Care Instructions", text: $careInstructions, axis: .vertical)
                        .lineLimit(2...4)
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Fabric")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveFabric()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .confirmationDialog("Add Photo", isPresented: $showingPhotoOptions) {
                Button("Take Photo") {
                    showingCamera = true
                }
                Button("Choose from Library") {
                    showingImagePicker = true
                }
                if selectedImage != nil {
                    Button("Remove Photo", role: .destructive) {
                        selectedImage = nil
                    }
                }
                Button("Cancel", role: .cancel) { }
            }
            .sheet(isPresented: $showingCamera) {
                ImagePicker(selectedImage: $selectedImage, sourceType: .camera)
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImage: $selectedImage, sourceType: .photoLibrary)
            }
            .onAppear {
                if settingsManager == nil {
                    settingsManager = UserSettingsManager(modelContext: modelContext)
                }
            }
        }
    }
    
    private func saveFabric() {
        let newFabric = Fabric(
            name: name,
            type: type,
            color: color,
            yardage: yardage
        )
        newFabric.content = content
        newFabric.brand = brand
        newFabric.width = width
        newFabric.cost = cost
        newFabric.store = store
        newFabric.careInstructions = careInstructions
        newFabric.notes = notes
        
        if hasPurchaseDate {
            newFabric.purchaseDate = purchaseDate
        }
        
        if let selectedImage = selectedImage {
            newFabric.photoData = selectedImage.jpegData(compressionQuality: 0.8)
        }
        
        modelContext.insert(newFabric)
        
        // Add to history
        settingsManager?.addHistory(
            action: .addedFabric,
            details: "\(name) - \(type.rawValue)",
            context: .fabrics
        )
        
        dismiss()
    }
}

struct FabricDetailView: View {
    @Bindable var fabric: Fabric
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var isEditing = false
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingPhotoOptions = false
    @State private var settingsManager: UserSettingsManager?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Photo Section
                    if let photoData = fabric.photoData, let uiImage = UIImage(data: photoData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 200)
                            .cornerRadius(12)
                            .onTapGesture {
                                if isEditing {
                                    showingPhotoOptions = true
                                }
                            }
                            .overlay(
                                isEditing ? 
                                VStack {
                                    Spacer()
                                    HStack {
                                        Spacer()
                                        Button("Edit") {
                                            showingPhotoOptions = true
                                        }
                                        .padding(8)
                                        .background(.ultraThinMaterial)
                                        .cornerRadius(8)
                                        .padding()
                                    }
                                } : nil
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 200)
                            .overlay(
                                VStack {
                                    Image(systemName: "photo")
                                        .font(.title)
                                        .foregroundColor(.gray)
                                    Text(isEditing ? "Tap to Add Photo" : "No Photo")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            )
                            .onTapGesture {
                                if isEditing {
                                    showingPhotoOptions = true
                                }
                            }
                    }
                    
                    // Fabric Info
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Type")
                                .font(.headline)
                            Spacer()
                            if isEditing {
                                Picker("Type", selection: $fabric.type) {
                                    ForEach(FabricType.allCases, id: \.self) { type in
                                        Text(type.rawValue).tag(type)
                                    }
                                }
                                .pickerStyle(.menu)
                            } else {
                                Text(fabric.type.rawValue)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.2))
                                    .foregroundColor(.blue)
                                    .cornerRadius(8)
                            }
                        }
                        
                        if isEditing {
                            TextField("Color", text: $fabric.color)
                                .textFieldStyle(.roundedBorder)
                        } else if !fabric.color.isEmpty {
                            Text("Color: \(fabric.color)")
                                .font(.subheadline)
                        }
                        
                        if isEditing {
                            TextField("Brand", text: $fabric.brand)
                                .textFieldStyle(.roundedBorder)
                        } else if !fabric.brand.isEmpty {
                            Text("Brand: \(fabric.brand)")
                                .font(.subheadline)
                        }
                        
                        HStack {
                            Text("Yardage")
                                .font(.subheadline)
                            Spacer()
                            if isEditing {
                                TextField("Yardage", value: $fabric.yardage, format: .number)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 80)
                                    .keyboardType(.decimalPad)
                            } else {
                                Text(String(format: "%.1f %@", fabric.yardage, settingsManager?.userSettings.preferredLengthUnit.abbreviation ?? "yd"))
                                    .fontWeight(.semibold)
                            }
                        }
                        
                        if fabric.cost > 0 {
                            HStack {
                                Text("Cost")
                                    .font(.subheadline)
                                Spacer()
                                if isEditing {
                                    TextField("Cost", value: $fabric.cost, format: .currency(code: "USD"))
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 100)
                                        .keyboardType(.decimalPad)
                                } else {
                                    Text(fabric.cost, format: .currency(code: "USD"))
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Care Instructions
                    if !fabric.careInstructions.isEmpty || isEditing {
                        VStack(alignment: .leading) {
                            Text("Care Instructions")
                                .font(.headline)
                            
                            if isEditing {
                                TextField("Care instructions", text: $fabric.careInstructions, axis: .vertical)
                                    .textFieldStyle(.roundedBorder)
                                    .lineLimit(2...4)
                            } else if fabric.careInstructions.isEmpty {
                                Text("No care instructions")
                                    .foregroundColor(.secondary)
                                    .italic()
                            } else {
                                Text(fabric.careInstructions)
                                    .font(.body)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // Notes
                    VStack(alignment: .leading) {
                        Text("Notes")
                            .font(.headline)
                        
                        if isEditing {
                            TextField("Notes", text: $fabric.notes, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(3...10)
                        } else if fabric.notes.isEmpty {
                            Text("No notes")
                                .foregroundColor(.secondary)
                                .italic()
                        } else {
                            Text(fabric.notes)
                                .font(.body)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle(fabric.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "Save" : "Edit") {
                        if isEditing {
                            // Save photo if a new one was selected
                            if let selectedImage = selectedImage {
                                fabric.photoData = selectedImage.jpegData(compressionQuality: 0.8)
                            }
                        }
                        isEditing.toggle()
                    }
                }
            }
            .confirmationDialog("Photo Options", isPresented: $showingPhotoOptions) {
                Button("Take Photo") {
                    showingCamera = true
                }
                Button("Choose from Library") {
                    showingImagePicker = true
                }
                if fabric.photoData != nil {
                    Button("Remove Photo", role: .destructive) {
                        fabric.photoData = nil
                    }
                }
                Button("Cancel", role: .cancel) { }
            }
            .sheet(isPresented: $showingCamera) {
                ImagePicker(selectedImage: $selectedImage, sourceType: .camera)
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImage: $selectedImage, sourceType: .photoLibrary)
            }
            .onAppear {
                if settingsManager == nil {
                    settingsManager = UserSettingsManager(modelContext: modelContext)
                }
            }
        }
    }
}


#Preview {
    FabricStashView()
        .modelContainer(for: Fabric.self, inMemory: true)
}