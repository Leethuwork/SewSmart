import SwiftUI
import SwiftData

struct ProjectsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Project.createdDate, order: .reverse) private var projects: [Project]
    @State private var showingAddProject = false
    @State private var selectedProject: Project?
    
    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.backgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Vibrant Header
                    VStack {
                        HStack {
                            Text("✂️ Projects")
                                .font(DesignSystem.largeTitleFont)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Button(action: { showingAddProject = true }) {
                                Circle()
                                    .fill(Color.white.opacity(0.9))
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Image(systemName: "plus")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(DesignSystem.primaryPink)
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
                    .background(DesignSystem.headerGradient)
                    
                    // Projects List
                    if projects.isEmpty {
                        VStack(spacing: 16) {
                            Text("🎨")
                                .font(.system(size: 64))
                            Text("No Projects Yet")
                                .font(DesignSystem.titleFont)
                                .foregroundColor(DesignSystem.primaryTextColor)
                            Text("Start your sewing journey!")
                                .font(DesignSystem.bodyFont)
                                .foregroundColor(DesignSystem.secondaryTextColor)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(DesignSystem.backgroundColor)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: DesignSystem.cardSpacing) {
                                ForEach(projects) { project in
                                    VibrantProjectRowView(project: project)
                                        .onTapGesture {
                                            selectedProject = project
                                        }
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 20)
                        }
                        .background(DesignSystem.backgroundColor)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddProject) {
                AddProjectView()
            }
            .sheet(item: $selectedProject) { project in
                ProjectDetailView(project: project)
            }
        }
    }
    
    private func deleteProjects(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(projects[index])
            }
        }
    }
}

struct VibrantProjectRowView: View {
    let project: Project
    
    private var statusColor: Color {
        DesignSystem.colorForStatus(project.status)
    }
    
    private var cardGradient: LinearGradient {
        DesignSystem.gradientForStatus(project.status)
    }
    
    private var statusEmoji: String {
        switch project.status {
        case .planning:
            return "🎯"
        case .inProgress:
            return "🌸"
        case .completed:
            return "🏆"
        case .onHold:
            return "⏸️"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with emoji and status
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 12, height: 12)
                
                Text("\(statusEmoji) \(project.name)")
                    .font(DesignSystem.titleFont)
                    .foregroundColor(DesignSystem.primaryTextColor)
                
                Spacer()
                
                Text(project.status.rawValue.uppercased())
                    .font(DesignSystem.captionFont)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(statusColor)
                    .clipShape(Capsule())
            }
            
            // Description with emoji
            if !project.projectDescription.isEmpty {
                Text("\(project.projectDescription) ✨")
                    .font(DesignSystem.bodyFont)
                    .foregroundColor(DesignSystem.secondaryTextColor)
                    .lineLimit(2)
            }
            
            // Vibrant progress bar
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    EmptyView()
                }
                .frame(height: 8)
                .background(
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(statusColor.opacity(0.2))
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(statusColor)
                                .frame(width: geometry.size.width * project.progress, height: 8)
                            
                            if project.progress > 0 {
                                Circle()
                                    .fill(statusColor)
                                    .frame(width: 8, height: 8)
                                    .offset(x: max(0, geometry.size.width * project.progress - 4))
                            }
                        }
                    }
                )
            }
            
            // Footer info
            HStack {
                Text("\(Int(project.progress * 100))% Complete")
                    .font(DesignSystem.captionFont)
                    .fontWeight(.semibold)
                    .foregroundColor(statusColor)
                
                Spacer()
                
                if project.status == .completed {
                    Text("🎉 Finished \(project.createdDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(DesignSystem.captionFont)
                        .foregroundColor(DesignSystem.secondaryTextColor)
                } else {
                    Text("📅 Started \(project.createdDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(DesignSystem.captionFont)
                        .foregroundColor(DesignSystem.secondaryTextColor)
                }
            }
        }
        .vibrantCard(gradient: cardGradient, borderColor: statusColor)
        .shadow(color: statusColor.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}

struct ProjectRowView: View {
    let project: Project
    
    var body: some View {
        VibrantProjectRowView(project: project)
    }
}

struct AddProjectView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var description = ""
    @State private var status = ProjectStatus.planning
    @State private var priority = 0
    @State private var dueDate = Date()
    @State private var hasDueDate = false
    @State private var settingsManager: UserSettingsManager?
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Project Details")) {
                    TextField("Project Name", text: $name)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                    
                    Picker("Status", selection: $status) {
                        ForEach(ProjectStatus.allCases, id: \.self) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                    
                    Picker("Priority", selection: $priority) {
                        Text("Low").tag(0)
                        Text("Medium").tag(1)
                        Text("High").tag(2)
                        Text("Urgent").tag(3)
                    }
                }
                
                Section(header: Text("Timeline")) {
                    Toggle("Set Due Date", isOn: $hasDueDate)
                    if hasDueDate {
                        DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProject()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                if settingsManager == nil {
                    settingsManager = UserSettingsManager(modelContext: modelContext)
                }
            }
        }
    }
    
    private func saveProject() {
        let newProject = Project(
            name: name,
            description: description,
            status: status,
            priority: priority
        )
        
        if hasDueDate {
            newProject.dueDate = dueDate
        }
        
        modelContext.insert(newProject)
        
        // Add to history
        settingsManager?.addHistory(
            action: .createdProject,
            details: "\(name) - \(status.rawValue)",
            context: .projects
        )
        
        dismiss()
    }
}

struct ProjectDetailView: View {
    @Bindable var project: Project
    @Environment(\.dismiss) private var dismiss
    @State private var isEditing = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Project Info Section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Status")
                                .font(.headline)
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
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(project.status.color).opacity(0.2))
                                    .foregroundColor(Color(project.status.color))
                                    .cornerRadius(8)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Progress: \(Int(project.progress * 100))%")
                                .font(.subheadline)
                            if isEditing {
                                Slider(value: $project.progress, in: 0...1, step: 0.1)
                            } else {
                                ProgressView(value: project.progress)
                                    .progressViewStyle(LinearProgressViewStyle())
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
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Photos Section
                    if !project.photos.isEmpty {
                        VStack(alignment: .leading) {
                            Text("Photos")
                                .font(.headline)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                                ForEach(project.photos) { photo in
                                    if let imageData = photo.imageData, let uiImage = UIImage(data: imageData) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 100, height: 100)
                                            .clipped()
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // Notes Section
                    VStack(alignment: .leading) {
                        Text("Notes")
                            .font(.headline)
                        
                        if isEditing {
                            TextField("Add notes...", text: $project.notes, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(3...10)
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
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle(project.name)
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
        }
    }
}

#Preview {
    ProjectsView()
        .modelContainer(for: Project.self, inMemory: true)
}