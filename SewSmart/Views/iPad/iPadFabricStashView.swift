import SwiftUI
import SwiftData

struct iPadFabricStashView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Fabric.createdDate, order: .reverse) private var fabrics: [Fabric]
    @State private var selectedFabric: Fabric?
    @State private var showingAddFabric = false
    @State private var searchText = ""
    @State private var selectedType: FabricType?
    @State private var viewMode: ViewMode = .grid
    
    enum ViewMode: String, CaseIterable {
        case grid = "Grid"
        case list = "List"
        
        var icon: String {
            switch self {
            case .grid: return "square.grid.2x2"
            case .list: return "list.bullet"
            }
        }
    }
    
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
        NavigationSplitView {
            // Fabric List/Grid
            VStack {
                // Filter and View Controls
                VStack(spacing: 8) {
                    // Type Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            FilterButton(title: "All Types", isSelected: selectedType == nil) {
                                selectedType = nil
                            }
                            
                            ForEach(FabricType.allCases, id: \.self) { type in
                                FilterButton(
                                    title: type.rawValue,
                                    isSelected: selectedType == type,
                                    color: .purple
                                ) {
                                    selectedType = type
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // View Mode Toggle
                    HStack {
                        Spacer()
                        Picker("View Mode", selection: $viewMode) {
                            ForEach(ViewMode.allCases, id: \.self) { mode in
                                Label(mode.rawValue, systemImage: mode.icon).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 200)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                
                // Fabric Content
                if filteredFabrics.isEmpty {
                    FabricEmptyGridView()
                } else {
                    Group {
                        if viewMode == .grid {
                            FabricGridView(fabrics: filteredFabrics, selectedFabric: $selectedFabric)
                        } else {
                            FabricListView(fabrics: filteredFabrics, selectedFabric: $selectedFabric)
                        }
                    }
                }
            }
            .navigationTitle("Fabric Stash")
            .searchable(text: $searchText, prompt: "Search fabrics...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddFabric = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddFabric) {
                AddFabricView()
            }
        } detail: {
            // Fabric Detail
            if let fabric = selectedFabric {
                iPadFabricDetailView(fabric: fabric)
            } else {
                FabricEmptyStateView()
            }
        }
    }
}

struct FabricGridView: View {
    let fabrics: [Fabric]
    @Binding var selectedFabric: Fabric?
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                ForEach(fabrics) { fabric in
                    iPadFabricGridCardView(fabric: fabric, isSelected: selectedFabric?.id == fabric.id)
                        .onTapGesture {
                            selectedFabric = fabric
                        }
                }
            }
            .padding()
        }
    }
}

struct FabricListView: View {
    let fabrics: [Fabric]
    @Binding var selectedFabric: Fabric?
    
    var body: some View {
        List(fabrics) { fabric in
            Button(action: { selectedFabric = fabric }) {
                iPadFabricListRowView(fabric: fabric)
            }
            .buttonStyle(PlainButtonStyle())
            .background(selectedFabric?.id == fabric.id ? Color.blue.opacity(0.2) : Color.clear)
            .cornerRadius(8)
        }
    }
}

struct iPadFabricGridCardView: View {
    let fabric: Fabric
    let isSelected: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Photo
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.3))
                .frame(height: 120)
                .overlay(
                    Group {
                        if let photoData = fabric.photoData, let uiImage = UIImage(data: photoData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 120)
                                .clipped()
                                .cornerRadius(12)
                        } else {
                            VStack {
                                Image(systemName: "photo")
                                    .font(.title)
                                    .foregroundColor(.gray)
                                Text("No Photo")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                )
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(fabric.name)
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                HStack {
                    Text(fabric.type.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.purple.opacity(0.2))
                        .foregroundColor(.purple)
                        .cornerRadius(4)
                    
                    Spacer()
                    
                    Text(String(format: "%.1f yds", fabric.yardage))
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                
                if !fabric.color.isEmpty {
                    Text(fabric.color)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                if fabric.cost > 0 {
                    Text(fabric.cost, format: .currency(code: "USD"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? Color.purple : Color.clear, lineWidth: 2)
        )
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

struct iPadFabricListRowView: View {
    let fabric: Fabric
    
    var body: some View {
        HStack(spacing: 12) {
            // Photo Thumbnail
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 60, height: 60)
                .overlay(
                    Group {
                        if let photoData = fabric.photoData, let uiImage = UIImage(data: photoData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 60, height: 60)
                                .clipped()
                                .cornerRadius(8)
                        } else {
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        }
                    }
                )
            
            // Info
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(fabric.name)
                        .font(.headline)
                    
                    Spacer()
                    
                    Text(fabric.type.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.purple.opacity(0.2))
                        .foregroundColor(.purple)
                        .cornerRadius(6)
                }
                
                HStack {
                    if !fabric.color.isEmpty {
                        Label(fabric.color, systemImage: "paintpalette")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if !fabric.brand.isEmpty {
                        Label(fabric.brand, systemImage: "tag")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                HStack {
                    Text(String(format: "%.1f yards", fabric.yardage))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    if fabric.width > 0 {
                        Text(String(format: "• %.0f\" wide", fabric.width))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if fabric.cost > 0 {
                        Text(fabric.cost, format: .currency(code: "USD"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct iPadFabricDetailView: View {
    @Bindable var fabric: Fabric
    @State private var isEditing = false
    @State private var showingImagePicker = false
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                // Photo Section
                FabricPhotoSection(fabric: fabric, showingImagePicker: $showingImagePicker)
                
                // Basic Info Section
                FabricBasicInfoSection(fabric: fabric, isEditing: $isEditing)
                
                // Measurements Section
                FabricMeasurementsSection(fabric: fabric, isEditing: $isEditing)
                
                // Purchase Info Section
                FabricPurchaseInfoSection(fabric: fabric, isEditing: $isEditing)
                
                // Care Instructions Section
                if !fabric.careInstructions.isEmpty || isEditing {
                    FabricCareSection(fabric: fabric, isEditing: $isEditing)
                }
                
                // Projects Section
                if !fabric.projects.isEmpty {
                    FabricProjectsSection(fabric: fabric)
                }
                
                // Notes Section
                FabricNotesSection(fabric: fabric, isEditing: $isEditing)
            }
            .padding()
        }
        .navigationTitle(fabric.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button(action: { showingImagePicker = true }) {
                        Image(systemName: "camera")
                    }
                    
                    Button(isEditing ? "Save" : "Edit") {
                        isEditing.toggle()
                    }
                }
            }
        }
    }
}

struct FabricPhotoSection: View {
    @Bindable var fabric: Fabric
    @Binding var showingImagePicker: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Photo")
                .font(.title2)
                .fontWeight(.semibold)
            
            Button(action: { showingImagePicker = true }) {
                if let photoData = fabric.photoData, let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 250)
                        .cornerRadius(12)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 200)
                        .overlay(
                            VStack {
                                Image(systemName: "camera")
                                    .font(.title)
                                    .foregroundColor(.gray)
                                Text("Add Photo")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        )
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct FabricBasicInfoSection: View {
    @Bindable var fabric: Fabric
    @Binding var isEditing: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Basic Information")
                .font(.title2)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                InfoCard(title: "Type", value: fabric.type.rawValue, isEditing: false)
                InfoCard(title: "Color", value: fabric.color.isEmpty ? "Not specified" : fabric.color, isEditing: false)
                InfoCard(title: "Brand", value: fabric.brand.isEmpty ? "Not specified" : fabric.brand, isEditing: false)
                InfoCard(title: "Content", value: fabric.content.isEmpty ? "Not specified" : fabric.content, isEditing: false)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct FabricMeasurementsSection: View {
    @Bindable var fabric: Fabric
    @Binding var isEditing: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Measurements")
                .font(.title2)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                MeasurementCard(
                    title: "Yardage",
                    value: fabric.yardage,
                    unit: "yards",
                    isEditing: isEditing,
                    binding: $fabric.yardage
                )
                
                MeasurementCard(
                    title: "Width",
                    value: fabric.width,
                    unit: "inches",
                    isEditing: isEditing,
                    binding: $fabric.width
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct FabricPurchaseInfoSection: View {
    @Bindable var fabric: Fabric
    @Binding var isEditing: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Purchase Information")
                .font(.title2)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                InfoCard(title: "Store", value: fabric.store.isEmpty ? "Not specified" : fabric.store, isEditing: false)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Cost")
                        .font(.headline)
                    
                    if isEditing {
                        TextField("Cost", value: $fabric.cost, format: .currency(code: "USD"))
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.decimalPad)
                    } else {
                        Text(fabric.cost > 0 ? fabric.cost.formatted(.currency(code: "USD")) : "Not specified")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                
                if let purchaseDate = fabric.purchaseDate {
                    InfoCard(title: "Purchase Date", value: purchaseDate.formatted(date: .abbreviated, time: .omitted), isEditing: false)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct FabricCareSection: View {
    @Bindable var fabric: Fabric
    @Binding var isEditing: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Care Instructions")
                .font(.title2)
                .fontWeight(.semibold)
            
            if isEditing {
                TextField("Care instructions", text: $fabric.careInstructions, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...6)
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
        .cornerRadius(16)
    }
}

struct FabricProjectsSection: View {
    let fabric: Fabric
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Used in Projects")
                .font(.title2)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(fabric.projects) { project in
                    ProjectMiniCard(project: project)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct FabricNotesSection: View {
    @Bindable var fabric: Fabric
    @Binding var isEditing: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes")
                .font(.title2)
                .fontWeight(.semibold)
            
            if isEditing {
                TextField("Add notes...", text: $fabric.notes, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(5...15)
            } else if fabric.notes.isEmpty {
                Text("No notes yet")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                Text(fabric.notes)
                    .font(.body)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct InfoCard: View {
    let title: String
    let value: String
    let isEditing: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(value == "Not specified" ? .secondary : .primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct MeasurementCard: View {
    let title: String
    let value: Double
    let unit: String
    let isEditing: Bool
    @Binding var binding: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            
            if isEditing {
                TextField("Value", value: $binding, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad)
            } else {
                HStack(alignment: .bottom, spacing: 4) {
                    Text(value, format: .number)
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct FabricEmptyGridView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "square.stack.3d.down.forward")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Fabrics Found")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("Try adjusting your search or filters")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct FabricEmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "square.stack.3d.down.forward")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("Select a Fabric")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Choose a fabric from your stash to view details")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    iPadFabricStashView()
        .modelContainer(for: Fabric.self, inMemory: true)
}