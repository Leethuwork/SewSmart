import SwiftUI
import SwiftData
import PhotosUI

struct FabricStashView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Fabric.createdDate, order: .reverse) private var fabrics: [Fabric]
    @State private var showingAddFabric = false
    @State private var selectedFabric: Fabric?
    @State private var searchText = ""
    @State private var selectedType: FabricType?
    
    var filteredFabrics: [Fabric] {
        var filtered = fabrics
        
        if !searchText.isEmpty {
            filtered = filtered.filter { fabric in
                fabric.name.localizedCaseInsensitiveContains(searchText) ||
                fabric.color.localizedCaseInsensitiveContains(searchText) ||
                fabric.brand.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        if let type = selectedType {
            filtered = filtered.filter { $0.type == type }
        }
        
        return filtered
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.backgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Vibrant Header
                    VStack {
                        HStack {
                            Text("🧵 Fabric Stash")
                                .font(DesignSystem.largeTitleFont)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Button(action: { showingAddFabric = true }) {
                                Circle()
                                    .fill(Color.white.opacity(0.9))
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Image(systemName: "plus")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(DesignSystem.primaryPurple)
                                    )
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 20)
                        
                        // Decorative elements
                        HStack {
                            Circle()
                                .fill(Color.white.opacity(0.6))
                                .frame(width: 6, height: 6)
                                .offset(x: 20, y: -10)
                            
                            Spacer()
                            
                            Circle()
                                .fill(Color.white.opacity(0.4))
                                .frame(width: 4, height: 4)
                                .offset(x: -30, y: 15)
                            
                            Circle()
                                .fill(Color.white.opacity(0.5))
                                .frame(width: 4, height: 4)
                                .offset(x: -10, y: -5)
                        }
                        .padding(.horizontal, 50)
                    }
                    .padding(.top, 20)
                    .background(
                        LinearGradient(
                            colors: [DesignSystem.primaryPurple, DesignSystem.primaryTeal, DesignSystem.primaryOrange],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    
                    VStack {
                        // Filter Controls
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                Button("🔍 All") {
                                    selectedType = nil
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(selectedType == nil ? DesignSystem.primaryPurple : DesignSystem.secondaryBackgroundColor)
                                .foregroundColor(selectedType == nil ? .white : DesignSystem.primaryTextColor)
                                .font(DesignSystem.captionFont)
                                .fontWeight(.semibold)
                                .clipShape(Capsule())
                                
                                ForEach(FabricType.allCases, id: \.self) { type in
                                    Button("🧶 \(type.rawValue)") {
                                        selectedType = type
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(selectedType == type ? DesignSystem.primaryTeal : DesignSystem.secondaryBackgroundColor)
                                    .foregroundColor(selectedType == type ? .white : DesignSystem.primaryTextColor)
                                    .font(DesignSystem.captionFont)
                                    .fontWeight(.semibold)
                                    .clipShape(Capsule())
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                        .padding(.vertical, 16)
                
                        // Fabric Grid
                        if filteredFabrics.isEmpty {
                            VStack(spacing: 16) {
                                Text("🧵")
                                    .font(.system(size: 64))
                                Text("No Fabric Yet")
                                    .font(DesignSystem.titleFont)
                                    .foregroundColor(DesignSystem.primaryTextColor)
                                Text("Start building your fabric stash! ✨")
                                    .font(DesignSystem.bodyFont)
                                    .foregroundColor(DesignSystem.secondaryTextColor)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(DesignSystem.backgroundColor)
                        } else {
                            ScrollView {
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                                    ForEach(filteredFabrics) { fabric in
                                        VibrantFabricCardView(fabric: fabric)
                                            .onTapGesture {
                                                selectedFabric = fabric
                                            }
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                            .background(DesignSystem.backgroundColor)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .searchable(text: $searchText, prompt: "Search fabrics...")
            .sheet(isPresented: $showingAddFabric) {
                AddFabricView()
            }
            .sheet(item: $selectedFabric) { fabric in
                FabricDetailView(fabric: fabric)
            }
        }
    }
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

struct FabricCardView: View {
    let fabric: Fabric
    
    var body: some View {
        VibrantFabricCardView(fabric: fabric)
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