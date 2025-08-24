import SwiftUI
import SwiftData

struct iPadProjectsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Project.createdDate, order: .reverse) private var projects: [Project]
    @State private var selectedProject: Project?
    @State private var showingAddProject = false
    @State private var searchText = ""
    @State private var selectedStatus: ProjectStatus?
    
    var filteredProjects: [Project] {
        var filtered = projects
        
        if !searchText.isEmpty {
            filtered = filtered.filter { project in
                project.name.localizedCaseInsensitiveContains(searchText) ||
                project.projectDescription.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        if let status = selectedStatus {
            filtered = filtered.filter { $0.status == status }
        }
        
        return filtered
    }
    
    var body: some View {
        NavigationSplitView {
            // Projects List
            VStack {
                // Filter Controls
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        FilterButton(title: "All", isSelected: selectedStatus == nil) {
                            selectedStatus = nil
                        }
                        
                        ForEach(ProjectStatus.allCases, id: \.self) { status in
                            FilterButton(
                                title: status.rawValue,
                                isSelected: selectedStatus == status,
                                color: Color(status.color)
                            ) {
                                selectedStatus = status
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                
                // Projects List
                List(filteredProjects) { project in
                    Button(action: { selectedProject = project }) {
                        iPadProjectRowView(project: project)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .background(selectedProject?.id == project.id ? Color.blue.opacity(0.2) : Color.clear)
                    .cornerRadius(8)
                }
                .searchable(text: $searchText, prompt: "Search projects...")
            }
            .navigationTitle("Projects")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddProject = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddProject) {
                AddProjectView()
            }
        } detail: {
            // Project Detail
            if let project = selectedProject {
                iPadProjectDetailView(project: project)
            } else {
                ProjectsEmptyStateView()
            }
        }
    }
}

struct iPadProjectRowView: View {
    let project: Project
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    if !project.projectDescription.isEmpty {
                        Text(project.projectDescription)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(project.status.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(project.status.color).opacity(0.2))
                        .foregroundColor(Color(project.status.color))
                        .cornerRadius(8)
                    
                    Text(project.createdDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Progress Section
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Progress")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(project.progress * 100))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                
                ProgressView(value: project.progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: Color(project.status.color)))
            }
            
            // Quick Info
            HStack {
                if !project.patterns.isEmpty {
                    Label("\(project.patterns.count)", systemImage: "doc.text")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if !project.fabrics.isEmpty {
                    Label("\(project.fabrics.count)", systemImage: "square.stack.3d.down.forward")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if !project.photos.isEmpty {
                    Label("\(project.photos.count)", systemImage: "photo")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if let dueDate = project.dueDate {
                    Label(dueDate.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(dueDate < Date() ? .red : .secondary)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct iPadProjectDetailView: View {
    @Bindable var project: Project
    @State private var isEditing = false
    @State private var showingPhotosPicker = false
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                // Header Section
                ProjectHeaderSection(project: project, isEditing: $isEditing)
                
                // Progress Section
                ProjectProgressSection(project: project, isEditing: $isEditing)
                
                // Photos Section
                if !project.photos.isEmpty {
                    ProjectPhotosSection(project: project)
                }
                
                // Related Items Section
                ProjectRelatedItemsSection(project: project)
                
                // Notes Section
                ProjectNotesSection(project: project, isEditing: $isEditing)
            }
            .padding()
        }
        .navigationTitle(project.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button(action: { showingPhotosPicker = true }) {
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

struct ProjectHeaderSection: View {
    @Bindable var project: Project
    @Binding var isEditing: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Project Details")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if isEditing {
                    Picker("Status", selection: $project.status) {
                        ForEach(ProjectStatus.allCases, id: \.self) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                    .pickerStyle(.menu)
                } else {
                    Text(project.status.rawValue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(project.status.color).opacity(0.2))
                        .foregroundColor(Color(project.status.color))
                        .cornerRadius(12)
                }
            }
            
            if isEditing {
                TextField("Description", text: $project.projectDescription, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(4...8)
            } else if !project.projectDescription.isEmpty {
                Text(project.projectDescription)
                    .font(.body)
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Created")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(project.createdDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline)
                }
                
                Spacer()
                
                if let dueDate = project.dueDate {
                    VStack(alignment: .trailing) {
                        Text("Due Date")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(dueDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.subheadline)
                            .foregroundColor(dueDate < Date() ? .red : .primary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct ProjectProgressSection: View {
    @Bindable var project: Project
    @Binding var isEditing: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Progress")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("\(Int(project.progress * 100))%")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(Color(project.status.color))
                    
                    Spacer()
                    
                    if isEditing {
                        Stepper("", value: $project.progress, in: 0...1, step: 0.1)
                            .labelsHidden()
                    }
                }
                
                ProgressView(value: project.progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: Color(project.status.color)))
                    .scaleEffect(y: 2)
                
                if isEditing {
                    Slider(value: $project.progress, in: 0...1, step: 0.05)
                        .accentColor(Color(project.status.color))
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct ProjectPhotosSection: View {
    let project: Project
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Photos")
                .font(.title2)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                ForEach(project.photos) { photo in
                    if let imageData = photo.imageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipped()
                            .cornerRadius(12)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct ProjectRelatedItemsSection: View {
    let project: Project
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Related Items")
                .font(.title2)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                // Patterns
                RelatedItemCard(
                    title: "Patterns",
                    count: project.patterns.count,
                    icon: "doc.text",
                    color: .green
                )
                
                // Fabrics
                RelatedItemCard(
                    title: "Fabrics",
                    count: project.fabrics.count,
                    icon: "square.stack.3d.down.forward",
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct RelatedItemCard: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color
    
    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
            
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct ProjectNotesSection: View {
    @Bindable var project: Project
    @Binding var isEditing: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes")
                .font(.title2)
                .fontWeight(.semibold)
            
            if isEditing {
                TextField("Add notes...", text: $project.notes, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(5...15)
            } else if project.notes.isEmpty {
                Text("No notes yet")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                Text(project.notes)
                    .font(.body)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct ProjectsEmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "folder")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("Select a Project")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Choose a project from the list to view details")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    var color: Color = .blue
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? color : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    iPadProjectsView()
        .modelContainer(for: Project.self, inMemory: true)
}