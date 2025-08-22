import SwiftUI
import SwiftData

@Observable
final class ProjectsViewViewModel {
    var showingAddProject: Bool = false
    var selectedProject: Project?
    
    private let modelContext: ModelContext
    private var settingsManager: UserSettingsManager?
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        setupSettingsManager()
    }
    
    private func setupSettingsManager() {
        settingsManager = UserSettingsManager(modelContext: modelContext)
    }
    
    func showAddProject() {
        showingAddProject = true
    }
    
    func hideAddProject() {
        showingAddProject = false
    }
    
    func selectProject(_ project: Project) {
        selectedProject = project
    }
    
    func deselectProject() {
        selectedProject = nil
    }
    
    func deleteProject(_ project: Project) {
        modelContext.delete(project)
        
        do {
            try modelContext.save()
            settingsManager?.addHistory(
                action: .deletedProject,
                details: project.name,
                context: .projects
            )
        } catch {
            // Handle error silently for now
        }
    }
    
    func deleteProjects(at offsets: IndexSet, from projects: [Project]) {
        for index in offsets {
            deleteProject(projects[index])
        }
    }
    
    func getEmptyStateConfiguration() -> EmptyStateConfiguration {
        EmptyStateConfiguration(
            emoji: "🎨",
            title: "No Projects Yet",
            subtitle: "Start your sewing journey!",
            emojiSize: 64
        )
    }
    
    func statusColor(for status: ProjectStatus) -> Color {
        DesignSystem.colorForStatus(status)
    }
    
    func statusGradient(for status: ProjectStatus) -> LinearGradient {
        DesignSystem.gradientForStatus(status)
    }
    
    func statusEmoji(for status: ProjectStatus) -> String {
        switch status {
        case .planning: return "🎯"
        case .inProgress: return "🌸"
        case .completed: return "🏆"
        case .onHold: return "⏸️"
        }
    }
}

// MARK: - AddProjectViewModel
@Observable
final class AddProjectViewModel {
    var name: String = ""
    var description: String = ""
    var status: ProjectStatus = .planning
    var priority: Int = 0
    var dueDate: Date = Date()
    var hasDueDate: Bool = false
    
    private let modelContext: ModelContext
    private var settingsManager: UserSettingsManager?
    
    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        setupSettingsManager()
    }
    
    private func setupSettingsManager() {
        settingsManager = UserSettingsManager(modelContext: modelContext)
    }
    
    func saveProject() -> Bool {
        guard isFormValid else { return false }
        
        let newProject = Project(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            status: status,
            priority: priority
        )
        
        if hasDueDate {
            newProject.dueDate = dueDate
        }
        
        do {
            modelContext.insert(newProject)
            try modelContext.save()
            
            settingsManager?.addHistory(
                action: .createdProject,
                details: "\(newProject.name) - \(status.rawValue)",
                context: .projects
            )
            
            return true
        } catch {
            return false
        }
    }
    
    func resetForm() {
        name = ""
        description = ""
        status = .planning
        priority = 0
        dueDate = Date()
        hasDueDate = false
    }
    
    func priorityText(for priority: Int) -> String {
        switch priority {
        case 0: return "Low"
        case 1: return "Medium"
        case 2: return "High"
        case 3: return "Urgent"
        default: return "Low"
        }
    }
}

// MARK: - ProjectDetailViewModel
@Observable
final class ProjectDetailViewModel {
    var isEditing: Bool = false
    
    func toggleEditing() {
        isEditing.toggle()
    }
    
    func formatProgress(_ progress: Double) -> String {
        "\(Int(progress * 100))%"
    }
    
    func formatDate(_ date: Date, isCompleted: Bool = false) -> String {
        let prefix = isCompleted ? "🎉 Finished" : "📅 Started"
        return "\(prefix) \(date.formatted(date: .abbreviated, time: .omitted))"
    }
    
    func hasPhotos(_ project: Project) -> Bool {
        !project.photos.isEmpty
    }
    
    func hasNotes(_ project: Project) -> Bool {
        !project.notes.isEmpty
    }
    
    func hasDescription(_ project: Project) -> Bool {
        !project.projectDescription.isEmpty
    }
}