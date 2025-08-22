import Foundation
import SwiftUI

@MainActor
@Observable
class ProjectsViewModel {
    private let projectRepository: ProjectRepositoryProtocol
    private let userSettingsRepository: UserSettingsRepositoryProtocol
    
    var projects: [Project] = []
    var isLoading = false
    var errorMessage: String?
    var showingAddProject = false
    var selectedProject: Project?
    
    init(
        projectRepository: ProjectRepositoryProtocol,
        userSettingsRepository: UserSettingsRepositoryProtocol
    ) {
        self.projectRepository = projectRepository
        self.userSettingsRepository = userSettingsRepository
    }
    
    func loadProjects() async {
        isLoading = true
        errorMessage = nil
        
        do {
            projects = try await projectRepository.fetchAll()
        } catch {
            errorMessage = "Failed to load projects: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func createProject(
        name: String,
        description: String,
        status: ProjectStatus,
        priority: Int,
        dueDate: Date? = nil
    ) async {
        guard !name.isEmpty else { return }
        
        let project = Project(
            name: name,
            description: description,
            status: status,
            priority: priority
        )
        
        project.dueDate = dueDate
        
        do {
            try await projectRepository.save(project)
            try await userSettingsRepository.addHistory(
                action: .createdProject,
                details: "\(name) - \(status.rawValue)",
                context: .projects
            )
            await loadProjects()
        } catch {
            errorMessage = "Failed to create project: \(error.localizedDescription)"
        }
    }
    
    func updateProject(_ project: Project) async {
        do {
            try await projectRepository.update(project)
            await loadProjects()
        } catch {
            errorMessage = "Failed to update project: \(error.localizedDescription)"
        }
    }
    
    func deleteProject(_ project: Project) async {
        do {
            try await projectRepository.delete(project)
            try await userSettingsRepository.addHistory(
                action: .deletedProject,
                details: project.name,
                context: .projects
            )
            await loadProjects()
        } catch {
            errorMessage = "Failed to delete project: \(error.localizedDescription)"
        }
    }
    
    func deleteProjects(at offsets: IndexSet) async {
        for index in offsets {
            await deleteProject(projects[index])
        }
    }
    
    func getProjectsByStatus(_ status: ProjectStatus) -> [Project] {
        return projects.filter { $0.status == status }
    }
    
    func getCompletedProjectsCount() -> Int {
        return projects.filter { $0.status == .completed }.count
    }
    
    func getInProgressProjectsCount() -> Int {
        return projects.filter { $0.status == .inProgress }.count
    }
    
    func getAverageProgress() -> Double {
        guard !projects.isEmpty else { return 0 }
        let totalProgress = projects.reduce(0) { $0 + $1.progress }
        return totalProgress / Double(projects.count)
    }
    
    func clearError() {
        errorMessage = nil
    }
}