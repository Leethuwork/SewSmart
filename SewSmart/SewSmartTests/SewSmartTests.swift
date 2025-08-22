/* 
Commenting out Swift Testing tests that conflict with XCTest implementation
import Testing
import Foundation
@testable import SewSmart

@MainActor
struct ProjectsViewModelSwiftTestingTests {
    
    private func createMockRepositories() -> (MockProjectRepository, MockUserSettingsRepository) {
        let projectRepo = MockProjectRepository()
        let settingsRepo = MockUserSettingsRepository()
        return (projectRepo, settingsRepo)
    }
    
    private func createViewModel(
        projectRepo: MockProjectRepository = MockProjectRepository(),
        settingsRepo: MockUserSettingsRepository = MockUserSettingsRepository()
    ) -> ProjectsViewModel {
        return ProjectsViewModel(
            projectRepository: projectRepo,
            userSettingsRepository: settingsRepo
        )
    }

    @Test func testInitialState() async throws {
        let viewModel = createViewModel()
        
        #expect(viewModel.projects.isEmpty)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.showingAddProject == false)
        #expect(viewModel.selectedProject == nil)
    }
    
    @Test func testLoadProjectsSuccess() async throws {
        let (projectRepo, settingsRepo) = createMockRepositories()
        let viewModel = createViewModel(projectRepo: projectRepo, settingsRepo: settingsRepo)
        
        // Add test projects to mock repository
        let project1 = Project(name: "Test Project 1", description: "Description 1", status: .planning)
        let project2 = Project(name: "Test Project 2", description: "Description 2", status: .inProgress)
        projectRepo.addProject(project1)
        projectRepo.addProject(project2)
        
        await viewModel.loadProjects()
        
        #expect(projectRepo.fetchAllCalled == true)
        #expect(viewModel.projects.count == 2)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.projects.contains { $0.name == "Test Project 1" })
        #expect(viewModel.projects.contains { $0.name == "Test Project 2" })
    }
    
    @Test func testLoadProjectsFailure() async throws {
        let (projectRepo, settingsRepo) = createMockRepositories()
        let viewModel = createViewModel(projectRepo: projectRepo, settingsRepo: settingsRepo)
        
        projectRepo.shouldThrowError = true
        projectRepo.errorToThrow = MockError.networkError
        
        await viewModel.loadProjects()
        
        #expect(projectRepo.fetchAllCalled == true)
        #expect(viewModel.projects.isEmpty)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage?.contains("Network error") == true)
    }
    
    @Test func testCreateProjectSuccess() async throws {
        let (projectRepo, settingsRepo) = createMockRepositories()
        let viewModel = createViewModel(projectRepo: projectRepo, settingsRepo: settingsRepo)
        
        await viewModel.createProject(
            name: "New Project",
            description: "New Description",
            status: .planning,
            priority: 1
        )
        
        #expect(projectRepo.saveCalled == true)
        #expect(settingsRepo.addHistoryCalled == true)
        #expect(projectRepo.fetchAllCalled == true) // Called by loadProjects
        #expect(projectRepo.lastSavedProject?.name == "New Project")
        #expect(projectRepo.lastSavedProject?.projectDescription == "New Description")
        #expect(projectRepo.lastSavedProject?.status == .planning)
        #expect(projectRepo.lastSavedProject?.priority == 1)
    }
    
    @Test func testCreateProjectWithEmptyNameShouldNotCreate() async throws {
        let (projectRepo, settingsRepo) = createMockRepositories()
        let viewModel = createViewModel(projectRepo: projectRepo, settingsRepo: settingsRepo)
        
        await viewModel.createProject(
            name: "",
            description: "Description",
            status: .planning,
            priority: 0
        )
        
        #expect(projectRepo.saveCalled == false)
        #expect(settingsRepo.addHistoryCalled == false)
    }
    
    @Test func testCreateProjectFailure() async throws {
        let (projectRepo, settingsRepo) = createMockRepositories()
        let viewModel = createViewModel(projectRepo: projectRepo, settingsRepo: settingsRepo)
        
        projectRepo.shouldThrowError = true
        projectRepo.errorToThrow = MockError.databaseError
        
        await viewModel.createProject(
            name: "Test Project",
            description: "Description",
            status: .planning,
            priority: 0
        )
        
        #expect(projectRepo.saveCalled == true)
        #expect(viewModel.errorMessage?.contains("Database error") == true)
    }
    
    @Test func testUpdateProjectSuccess() async throws {
        let (projectRepo, settingsRepo) = createMockRepositories()
        let viewModel = createViewModel(projectRepo: projectRepo, settingsRepo: settingsRepo)
        
        let project = Project(name: "Test Project", description: "Description", status: .planning)
        project.progress = 0.5
        
        await viewModel.updateProject(project)
        
        #expect(projectRepo.updateCalled == true)
        #expect(projectRepo.lastUpdatedProject?.id == project.id)
        #expect(projectRepo.fetchAllCalled == true) // Called by loadProjects
    }
    
    @Test func testDeleteProjectSuccess() async throws {
        let (projectRepo, settingsRepo) = createMockRepositories()
        let viewModel = createViewModel(projectRepo: projectRepo, settingsRepo: settingsRepo)
        
        let project = Project(name: "Test Project", description: "Description", status: .planning)
        
        await viewModel.deleteProject(project)
        
        #expect(projectRepo.deleteCalled == true)
        #expect(settingsRepo.addHistoryCalled == true)
        #expect(projectRepo.lastDeletedProject?.id == project.id)
        #expect(settingsRepo.lastHistoryEntry?.action == .deletedProject)
        #expect(settingsRepo.lastHistoryEntry?.details == "Test Project")
    }
    
    @Test func testGetProjectsByStatus() async throws {
        let (projectRepo, settingsRepo) = createMockRepositories()
        let viewModel = createViewModel(projectRepo: projectRepo, settingsRepo: settingsRepo)
        
        let project1 = Project(name: "Project 1", status: .planning)
        let project2 = Project(name: "Project 2", status: .inProgress)
        let project3 = Project(name: "Project 3", status: .planning)
        
        projectRepo.addProject(project1)
        projectRepo.addProject(project2)
        projectRepo.addProject(project3)
        
        await viewModel.loadProjects()
        
        let planningProjects = viewModel.getProjectsByStatus(.planning)
        let inProgressProjects = viewModel.getProjectsByStatus(.inProgress)
        
        #expect(planningProjects.count == 2)
        #expect(inProgressProjects.count == 1)
        #expect(planningProjects.contains { $0.name == "Project 1" })
        #expect(planningProjects.contains { $0.name == "Project 3" })
        #expect(inProgressProjects.contains { $0.name == "Project 2" })
    }
    
    @Test func testGetCompletedProjectsCount() async throws {
        let (projectRepo, settingsRepo) = createMockRepositories()
        let viewModel = createViewModel(projectRepo: projectRepo, settingsRepo: settingsRepo)
        
        let project1 = Project(name: "Project 1", status: .completed)
        let project2 = Project(name: "Project 2", status: .inProgress)
        let project3 = Project(name: "Project 3", status: .completed)
        
        projectRepo.addProject(project1)
        projectRepo.addProject(project2)
        projectRepo.addProject(project3)
        
        await viewModel.loadProjects()
        
        #expect(viewModel.getCompletedProjectsCount() == 2)
    }
    
    @Test func testGetInProgressProjectsCount() async throws {
        let (projectRepo, settingsRepo) = createMockRepositories()
        let viewModel = createViewModel(projectRepo: projectRepo, settingsRepo: settingsRepo)
        
        let project1 = Project(name: "Project 1", status: .inProgress)
        let project2 = Project(name: "Project 2", status: .inProgress)
        let project3 = Project(name: "Project 3", status: .completed)
        
        projectRepo.addProject(project1)
        projectRepo.addProject(project2)
        projectRepo.addProject(project3)
        
        await viewModel.loadProjects()
        
        #expect(viewModel.getInProgressProjectsCount() == 2)
    }
    
    @Test func testGetAverageProgress() async throws {
        let (projectRepo, settingsRepo) = createMockRepositories()
        let viewModel = createViewModel(projectRepo: projectRepo, settingsRepo: settingsRepo)
        
        let project1 = Project(name: "Project 1", status: .inProgress)
        project1.progress = 0.2
        let project2 = Project(name: "Project 2", status: .inProgress)
        project2.progress = 0.6
        let project3 = Project(name: "Project 3", status: .completed)
        project3.progress = 1.0
        
        projectRepo.addProject(project1)
        projectRepo.addProject(project2)
        projectRepo.addProject(project3)
        
        await viewModel.loadProjects()
        
        let expectedAverage = (0.2 + 0.6 + 1.0) / 3.0
        #expect(abs(viewModel.getAverageProgress() - expectedAverage) < 0.001)
    }
    
    @Test func testGetAverageProgressEmptyProjects() async throws {
        let viewModel = createViewModel()
        
        #expect(viewModel.getAverageProgress() == 0.0)
    }
    
    @Test func testClearError() async throws {
        let (projectRepo, settingsRepo) = createMockRepositories()
        let viewModel = createViewModel(projectRepo: projectRepo, settingsRepo: settingsRepo)
        
        // Set an error
        projectRepo.shouldThrowError = true
        await viewModel.loadProjects()
        #expect(viewModel.errorMessage != nil)
        
        // Clear the error
        viewModel.clearError()
        #expect(viewModel.errorMessage == nil)
    }
    
    @Test func testCreateProjectWithDueDate() async throws {
        let (projectRepo, settingsRepo) = createMockRepositories()
        let viewModel = createViewModel(projectRepo: projectRepo, settingsRepo: settingsRepo)
        
        let dueDate = Date().addingTimeInterval(86400) // Tomorrow
        
        await viewModel.createProject(
            name: "Project with Due Date",
            description: "Description",
            status: .planning,
            priority: 2,
            dueDate: dueDate
        )
        
        #expect(projectRepo.saveCalled == true)
        #expect(projectRepo.lastSavedProject?.dueDate == dueDate)
    }
}
*/
