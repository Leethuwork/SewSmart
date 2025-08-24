import Foundation
import SwiftUI
import os.log

@MainActor
@Observable
class ProjectsViewModel {
    private let projectRepository: ProjectRepository
    private let userSettingsRepository: UserSettingsRepository
    private let logger = Logger(subsystem: "com.sewsmart.viewmodel", category: "ProjectsViewModel")
    private let userFeedback = UserFeedbackSystem.shared
    private let offlineManager = OfflineManager.shared
    
    // State Management
    private(set) var projectsState: LoadingState<[Project]> = .idle
    private(set) var createProjectState: SimpleLoadingState = .idle
    private(set) var updateProjectState: SimpleLoadingState = .idle
    private(set) var deleteProjectState: SimpleLoadingState = .idle
    
    // UI State
    var showingAddProject = false
    var selectedProject: Project?
    var searchText = ""
    var selectedStatus: ProjectStatus?
    
    // Computed properties for backward compatibility
    var projects: [Project] {
        projectsState.data ?? []
    }
    
    var isLoading: Bool {
        projectsState.isLoading
    }
    
    var errorMessage: String? {
        projectsState.error?.localizedDescription
    }
    
    init(
        projectRepository: ProjectRepository,
        userSettingsRepository: UserSettingsRepository
    ) {
        self.projectRepository = projectRepository
        self.userSettingsRepository = userSettingsRepository
        logger.info("Initialized ProjectsViewModel with actor-based repositories")
    }
    
    func loadProjects() async {
        projectsState.setLoading()
        
        // Check if offline and show appropriate feedback
        if !offlineManager.isConnected {
            userFeedback.showToast(ToastMessage(
                type: .info,
                title: "Offline Mode",
                message: "Loading cached projects - you're offline",
                icon: "wifi.slash"
            ))
        }
        
        do {
            let fetchedProjects: [Project]
            
            if let status = selectedStatus {
                fetchedProjects = try await projectRepository.fetch(by: status)
            } else if !searchText.isEmpty {
                fetchedProjects = try await projectRepository.search(query: searchText)
            } else {
                fetchedProjects = try await projectRepository.fetchAll()
            }
            
            projectsState.setLoaded(fetchedProjects)
            logger.info("Loaded \(fetchedProjects.count) projects")
        } catch let error as SewSmartError {
            projectsState.setFailed(error)
            logger.error("Failed to load projects: \(error.localizedDescription)")
            userFeedback.showToast(ToastMessage(
                type: .error,
                title: "Load Failed",
                message: "Failed to load projects",
                icon: "exclamationmark.triangle"
            ))
        } catch {
            projectsState.setFailed(.dataCorruption)
            logger.error("Failed to load projects: \(error.localizedDescription)")
            userFeedback.showToast(ToastMessage(
                type: .error,
                title: "Data Error",
                message: "Data error while loading projects",
                icon: "exclamationmark.triangle"
            ))
        }
    }
    
    func createProject(
        name: String,
        description: String,
        status: ProjectStatus,
        priority: Int,
        dueDate: Date? = nil
    ) async {
        createProjectState.setLoading()
        
        // Comprehensive input validation
        let nameValidation = InputValidator.validateName(name)
        guard nameValidation.isValid else {
            createProjectState.setFailed(.invalidInput(nameValidation.errorMessage ?? "Invalid name"))
            return
        }
        
        let descriptionValidation = InputValidator.validateDescription(description)
        guard descriptionValidation.isValid else {
            createProjectState.setFailed(.invalidInput(descriptionValidation.errorMessage ?? "Invalid description"))
            return
        }
        
        let priorityValidation = InputValidator.validatePriority(priority)
        guard priorityValidation.isValid else {
            createProjectState.setFailed(.invalidInput(priorityValidation.errorMessage ?? "Invalid priority"))
            return
        }
        
        let dueDateValidation = InputValidator.validateDueDate(dueDate)
        guard dueDateValidation.isValid else {
            createProjectState.setFailed(.invalidInput(dueDateValidation.errorMessage ?? "Invalid due date"))
            return
        }
        
        // Security validation
        let secureNameValidation = InputValidator.validateSecureInput(name)
        guard secureNameValidation.isValid else {
            createProjectState.setFailed(.invalidInput("Project name contains invalid content"))
            return
        }
        
        let secureDescValidation = InputValidator.validateSecureInput(description)
        guard secureDescValidation.isValid else {
            createProjectState.setFailed(.invalidInput("Project description contains invalid content"))
            return
        }
        
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
            createProjectState.setSuccess()
            await loadProjects()
            logger.info("Created project: \(name)")
            
            // Provide success feedback
            userFeedback.showToast(ToastMessage(
                type: .success,
                title: "Success",
                message: "Project created successfully!",
                icon: "checkmark.circle"
            ))
        } catch let error as SewSmartError {
            createProjectState.setFailed(error)
            logger.error("Failed to create project: \(error.localizedDescription)")
            userFeedback.showToast(ToastMessage(
                type: .error,
                title: "Creation Failed",
                message: "Failed to create project",
                icon: "xmark.circle"
            ))
        } catch {
            createProjectState.setFailed(.dataStorageUnavailable)
            logger.error("Failed to create project: \(error.localizedDescription)")
            userFeedback.showToast(ToastMessage(
                type: .error,
                title: "Storage Error",
                message: "Storage error creating project",
                icon: "externaldrive.badge.xmark"
            ))
        }
    }
    
    func updateProject(_ project: Project) async {
        updateProjectState.setLoading()
        
        // Validate the project before updating
        guard project.isValid else {
            let errors = project.validationErrors.joined(separator: ", ")
            updateProjectState.setFailed(.invalidInput("Validation failed: \(errors)"))
            return
        }
        
        do {
            try await projectRepository.update(project)
            updateProjectState.setSuccess()
            await loadProjects()
            logger.info("Updated project: \(project.name)")
        } catch let error as SewSmartError {
            updateProjectState.setFailed(error)
            logger.error("Failed to update project: \(error.localizedDescription)")
        } catch {
            updateProjectState.setFailed(.dataStorageUnavailable)
            logger.error("Failed to update project: \(error.localizedDescription)")
        }
    }
    
    func deleteProject(_ project: Project) async {
        deleteProjectState.setLoading()
        
        do {
            try await projectRepository.delete(project)
            try await userSettingsRepository.addHistory(
                action: .deletedProject,
                details: project.name,
                context: .projects
            )
            deleteProjectState.setSuccess()
            await loadProjects()
            logger.info("Deleted project: \(project.name)")
            
            // Provide success feedback
            userFeedback.showToast(ToastMessage(
                type: .success,
                title: "Deleted",
                message: "Project deleted successfully",
                icon: "trash"
            ))
        } catch let error as SewSmartError {
            deleteProjectState.setFailed(error)
            logger.error("Failed to delete project: \(error.localizedDescription)")
            userFeedback.showToast(ToastMessage(
                type: .error,
                title: "Delete Failed",
                message: "Failed to delete project",
                icon: "xmark.circle"
            ))
        } catch {
            deleteProjectState.setFailed(.dataStorageUnavailable)
            logger.error("Failed to delete project: \(error.localizedDescription)")
            userFeedback.showToast(ToastMessage(
                type: .error,
                title: "Storage Error",
                message: "Storage error deleting project",
                icon: "externaldrive.badge.xmark"
            ))
        }
    }
    
    func deleteProjects(at offsets: IndexSet) async {
        deleteProjectState.setLoading()
        
        let projectsToDelete = offsets.map { projects[$0] }
        
        do {
            try await projectRepository.batchDelete(projectsToDelete)
            
            // Add history for each deleted project
            for project in projectsToDelete {
                try await userSettingsRepository.addHistory(
                    action: .deletedProject,
                    details: project.name,
                    context: .projects
                )
            }
            
            deleteProjectState.setSuccess()
            await loadProjects()
            logger.info("Batch deleted \(projectsToDelete.count) projects")
        } catch let error as SewSmartError {
            deleteProjectState.setFailed(error)
            logger.error("Failed to batch delete projects: \(error.localizedDescription)")
        } catch {
            deleteProjectState.setFailed(.dataStorageUnavailable)
            logger.error("Failed to batch delete projects: \(error.localizedDescription)")
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
    
    // State management methods
    func clearError() {
        if projectsState.isFailed {
            projectsState.setIdle()
        }
    }
    
    func clearCreateProjectState() {
        createProjectState.setIdle()
    }
    
    func clearUpdateProjectState() {
        updateProjectState.setIdle()
    }
    
    func clearDeleteProjectState() {
        deleteProjectState.setIdle()
    }
    
    func setSelectedStatus(_ status: ProjectStatus?) {
        selectedStatus = status
        Task {
            await loadProjects()
        }
    }
    
    func updateSearchText(_ text: String) {
        searchText = text
        Task {
            // Debounce search if needed
            try await Task.sleep(for: .milliseconds(300))
            if searchText == text { // Check if search text hasn't changed
                await loadProjects()
            }
        }
    }
    
    func clearFilters() {
        selectedStatus = nil
        searchText = ""
        Task {
            await loadProjects()
        }
    }
    
    // Memory cleanup
    deinit {
        logger.info("ProjectsViewModel deinitialized")
    }
}