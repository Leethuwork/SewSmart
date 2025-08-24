import SwiftUI
import SwiftData

struct ProjectsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Project.createdDate, order: .reverse) private var projects: [Project]
    @State private var viewModel: ProjectsViewViewModel?
    
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
                                .accessibilityLabel("Projects")
                            
                            Spacer()
                            
                            Button(action: { viewModel?.showAddProject() }) {
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
                            .accessibilityLabel("Add new project")
                            .accessibilityHint("Creates a new sewing project")
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
                        let config = viewModel?.getEmptyStateConfiguration()
                        VStack(spacing: 16) {
                            Text(config?.emoji ?? "🎨")
                                .font(.system(size: config?.emojiSize ?? 64))
                            Text(config?.title ?? "No Projects Yet")
                                .font(DesignSystem.titleFont)
                                .foregroundColor(DesignSystem.primaryTextColor)
                            Text(config?.subtitle ?? "Start your sewing journey!")
                                .font(DesignSystem.bodyFont)
                                .foregroundColor(DesignSystem.secondaryTextColor)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(DesignSystem.backgroundColor)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: DesignSystem.cardSpacing) {
                                ForEach(projects) { project in
                                    VibrantProjectRowView(project: project, viewModel: viewModel)
                                        .onTapGesture {
                                            viewModel?.selectProject(project)
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
            .sheet(isPresented: Binding(
                get: { viewModel?.showingAddProject ?? false },
                set: { _ in viewModel?.hideAddProject() }
            )) {
                AddProjectView()
            }
            .sheet(item: Binding(
                get: { viewModel?.selectedProject },
                set: { _ in viewModel?.deselectProject() }
            )) { project in
                ProjectDetailView(project: project)
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = ProjectsViewViewModel(modelContext: modelContext)
                }
            }
        }
    }
    
    private func deleteProjects(offsets: IndexSet) {
        withAnimation {
            viewModel?.deleteProjects(at: offsets, from: projects)
        }
    }
}

struct VibrantProjectRowView: View {
    let project: Project
    let viewModel: ProjectsViewViewModel?
    
    private var statusColor: Color {
        viewModel?.statusColor(for: project.status) ?? DesignSystem.colorForStatus(project.status)
    }
    
    private var cardGradient: LinearGradient {
        viewModel?.statusGradient(for: project.status) ?? DesignSystem.gradientForStatus(project.status)
    }
    
    private var statusEmoji: String {
        viewModel?.statusEmoji(for: project.status) ?? "🎯"
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
    let viewModel: ProjectsViewViewModel?
    
    var body: some View {
        VibrantProjectRowView(project: project, viewModel: viewModel)
    }
}

struct AddProjectView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: AddProjectViewModel?
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Project Details")) {
                    TextField("Project Name", text: Binding(
                        get: { viewModel?.name ?? "" },
                        set: { viewModel?.name = $0 }
                    ))
                    TextField("Description", text: Binding(
                        get: { viewModel?.description ?? "" },
                        set: { viewModel?.description = $0 }
                    ), axis: .vertical)
                        .lineLimit(3...6)
                    
                    Picker("Status", selection: Binding(
                        get: { viewModel?.status ?? .planning },
                        set: { viewModel?.status = $0 }
                    )) {
                        ForEach(ProjectStatus.allCases, id: \.self) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                    
                    Picker("Priority", selection: Binding(
                        get: { viewModel?.priority ?? 0 },
                        set: { viewModel?.priority = $0 }
                    )) {
                        Text("Low").tag(0)
                        Text("Medium").tag(1)
                        Text("High").tag(2)
                        Text("Urgent").tag(3)
                    }
                }
                
                Section(header: Text("Timeline")) {
                    Toggle("Set Due Date", isOn: Binding(
                        get: { viewModel?.hasDueDate ?? false },
                        set: { viewModel?.hasDueDate = $0 }
                    ))
                    if viewModel?.hasDueDate == true {
                        DatePicker("Due Date", selection: Binding(
                            get: { viewModel?.dueDate ?? Date() },
                            set: { viewModel?.dueDate = $0 }
                        ), displayedComponents: .date)
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
                        if viewModel?.saveProject() == true {
                            dismiss()
                        }
                    }
                    .disabled(!(viewModel?.isFormValid ?? false))
                }
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = AddProjectViewModel(modelContext: modelContext)
                }
            }
        }
    }
}

struct ProjectDetailView: View {
    @Bindable var project: Project
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = ProjectDetailViewModel()
    
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
                            if viewModel.isEditing {
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
                            Text("Progress: \(viewModel.formatProgress(project.progress))")
                                .font(.subheadline)
                            if viewModel.isEditing {
                                Slider(value: $project.progress, in: 0...1, step: 0.1)
                            } else {
                                ProgressView(value: project.progress)
                                    .progressViewStyle(LinearProgressViewStyle())
                            }
                        }
                        
                        if viewModel.isEditing {
                            TextField("Description", text: $project.projectDescription, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(4...8)
                        } else if viewModel.hasDescription(project) {
                            Text(project.projectDescription)
                                .font(.body)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Photos Section
                    if viewModel.hasPhotos(project) {
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
                        
                        if viewModel.isEditing {
                            TextField("Add notes...", text: $project.notes, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(3...10)
                        } else if !viewModel.hasNotes(project) {
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
                    Button(viewModel.isEditing ? "Save" : "Edit") {
                        viewModel.toggleEditing()
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