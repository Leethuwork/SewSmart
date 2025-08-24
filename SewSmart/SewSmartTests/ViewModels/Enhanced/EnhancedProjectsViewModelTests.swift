import XCTest
import SwiftData
@testable import SewSmart

@MainActor
final class EnhancedProjectsViewModelTests: XCTestCase {
    var viewModel: ProjectsViewModel!
    var mockProjectRepository: MockProjectRepository!
    var mockUserSettingsRepository: MockUserSettingsRepository!
    var modelContext: ModelContext!
    var container: ModelContainer!
    
    @MainActor
    override func setUp() {
        super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try! ModelContainer(for: Project.self, UserSettings.self, configurations: config)
        modelContext = container.mainContext
        
        mockProjectRepository = MockProjectRepository()
        mockUserSettingsRepository = MockUserSettingsRepository()
        
        viewModel = ProjectsViewModel(
            projectRepository: mockProjectRepository,
            userSettingsRepository: mockUserSettingsRepository
        )
    }
    
    override func tearDown() {
        viewModel = nil
        mockProjectRepository = nil
        mockUserSettingsRepository = nil
        modelContext = nil
        container = nil
        super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func testInitialState() {
        XCTAssertEqual(viewModel.projectsState, .idle)
        XCTAssertEqual(viewModel.createProjectState, .idle)
        XCTAssertEqual(viewModel.updateProjectState, .idle)
        XCTAssertEqual(viewModel.deleteProjectState, .idle)
        XCTAssertFalse(viewModel.showingAddProject)
        XCTAssertNil(viewModel.selectedProject)
        XCTAssertEqual(viewModel.searchText, "")
        XCTAssertNil(viewModel.selectedStatus)
    }
    
    func testComputedProperties() {
        // Test empty state
        XCTAssertTrue(viewModel.projects.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        
        // Test with loaded data
        let testProjects = [
            Project(name: "Project 1", description: "Test 1", status: .planning, priority: 0),
            Project(name: "Project 2", description: "Test 2", status: .inProgress, priority: 1)
        ]
        viewModel.projectsState = .loaded(testProjects)
        
        XCTAssertEqual(viewModel.projects.count, 2)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    // MARK: - Load Projects Tests
    
    func testLoadProjectsSuccess() async {
        let testProjects = [
            Project(name: "Test Project", description: "Test", status: .planning, priority: 0)
        ]
        mockProjectRepository.mockProjects = testProjects
        
        await viewModel.loadProjects()
        
        XCTAssertTrue(mockProjectRepository.fetchAllCalled)
        XCTAssertEqual(viewModel.projectsState.data?.count, 1)
        XCTAssertEqual(viewModel.projects.first?.name, "Test Project")
    }
    
    func testLoadProjectsWithStatus() async {
        let testProjects = [
            Project(name: "Active Project", description: "Test", status: .inProgress, priority: 0)
        ]
        mockProjectRepository.mockProjectsByStatus = testProjects
        viewModel.selectedStatus = .inProgress
        
        await viewModel.loadProjects()
        
        XCTAssertTrue(mockProjectRepository.fetchByStatusCalled)
        XCTAssertEqual(viewModel.projects.count, 1)
    }
    
    func testLoadProjectsWithSearch() async {
        let testProjects = [
            Project(name: "Searched Project", description: "Test", status: .planning, priority: 0)
        ]
        mockProjectRepository.mockSearchResults = testProjects
        viewModel.searchText = "Searched"
        
        await viewModel.loadProjects()
        
        XCTAssertTrue(mockProjectRepository.searchCalled)
        XCTAssertEqual(viewModel.projects.count, 1)
    }
    
    func testLoadProjectsFailure() async {
        mockProjectRepository.shouldFail = true
        
        await viewModel.loadProjects()
        
        XCTAssertTrue(viewModel.projectsState.isFailed)
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    // MARK: - Create Project Tests
    
    func testCreateProjectSuccess() async {
        await viewModel.createProject(
            name: "New Project",
            description: "New Description",
            status: .planning,
            priority: 1
        )
        
        XCTAssertTrue(mockProjectRepository.saveCalled)
        XCTAssertTrue(mockUserSettingsRepository.addHistoryCalled)
        XCTAssertTrue(viewModel.createProjectState.isSuccess)
    }
    
    func testCreateProjectWithEmptyName() async {
        await viewModel.createProject(
            name: "",
            description: "Test",
            status: .planning,
            priority: 0
        )
        
        XCTAssertFalse(mockProjectRepository.saveCalled)
        XCTAssertTrue(viewModel.createProjectState.isFailed)
    }
    
    func testCreateProjectWithWhitespaceOnly() async {
        await viewModel.createProject(
            name: "   ",
            description: "Test",
            status: .planning,
            priority: 0
        )
        
        XCTAssertFalse(mockProjectRepository.saveCalled)
        XCTAssertTrue(viewModel.createProjectState.isFailed)
    }
    
    func testCreateProjectFailure() async {
        mockProjectRepository.shouldFail = true
        
        await viewModel.createProject(
            name: "Test Project",
            description: "Test",
            status: .planning,
            priority: 0
        )
        
        XCTAssertTrue(viewModel.createProjectState.isFailed)
    }
    
    // MARK: - Update Project Tests
    
    func testUpdateProjectSuccess() async {
        let project = Project(name: "Test Project", description: "Test", status: .planning, priority: 0)
        
        await viewModel.updateProject(project)
        
        XCTAssertTrue(mockProjectRepository.updateCalled)
        XCTAssertTrue(viewModel.updateProjectState.isSuccess)
    }
    
    func testUpdateProjectFailure() async {
        mockProjectRepository.shouldFail = true
        let project = Project(name: "Test Project", description: "Test", status: .planning, priority: 0)
        
        await viewModel.updateProject(project)
        
        XCTAssertTrue(viewModel.updateProjectState.isFailed)
    }
    
    // MARK: - Delete Project Tests
    
    func testDeleteProjectSuccess() async {
        let project = Project(name: "Test Project", description: "Test", status: .planning, priority: 0)
        
        await viewModel.deleteProject(project)
        
        XCTAssertTrue(mockProjectRepository.deleteCalled)
        XCTAssertTrue(mockUserSettingsRepository.addHistoryCalled)
        XCTAssertTrue(viewModel.deleteProjectState.isSuccess)
    }
    
    func testDeleteProjectsAtOffsets() async {
        let projects = [
            Project(name: "Project 1", description: "Test 1", status: .planning, priority: 0),
            Project(name: "Project 2", description: "Test 2", status: .inProgress, priority: 1)
        ]
        viewModel.projectsState = .loaded(projects)
        
        await viewModel.deleteProjects(at: IndexSet([0]))
        
        XCTAssertTrue(mockProjectRepository.batchDeleteCalled)
        XCTAssertTrue(viewModel.deleteProjectState.isSuccess)
    }
    
    // MARK: - State Management Tests
    
    func testClearStates() {
        viewModel.createProjectState = .failed(.dataCorruption)
        viewModel.updateProjectState = .failed(.dataCorruption)
        viewModel.deleteProjectState = .failed(.dataCorruption)
        viewModel.projectsState = .failed(.dataCorruption)
        
        viewModel.clearCreateProjectState()
        viewModel.clearUpdateProjectState()
        viewModel.clearDeleteProjectState()
        viewModel.clearError()
        
        XCTAssertEqual(viewModel.createProjectState, .idle)
        XCTAssertEqual(viewModel.updateProjectState, .idle)
        XCTAssertEqual(viewModel.deleteProjectState, .idle)
        XCTAssertEqual(viewModel.projectsState, .idle)
    }
    
    func testSetSelectedStatus() {
        XCTAssertNil(viewModel.selectedStatus)
        
        viewModel.setSelectedStatus(.inProgress)
        
        XCTAssertEqual(viewModel.selectedStatus, .inProgress)
    }
    
    func testUpdateSearchText() {
        XCTAssertEqual(viewModel.searchText, "")
        
        viewModel.updateSearchText("test search")
        
        XCTAssertEqual(viewModel.searchText, "test search")
    }
    
    func testClearFilters() {
        viewModel.selectedStatus = .inProgress
        viewModel.searchText = "test"
        
        viewModel.clearFilters()
        
        XCTAssertNil(viewModel.selectedStatus)
        XCTAssertEqual(viewModel.searchText, "")
    }
    
    // MARK: - Business Logic Tests
    
    func testGetProjectsByStatus() {
        let projects = [
            Project(name: "Planning Project", description: "Test", status: .planning, priority: 0),
            Project(name: "In Progress Project", description: "Test", status: .inProgress, priority: 1),
            Project(name: "Completed Project", description: "Test", status: .completed, priority: 2)
        ]
        viewModel.projectsState = .loaded(projects)
        
        let planningProjects = viewModel.getProjectsByStatus(.planning)
        let inProgressProjects = viewModel.getProjectsByStatus(.inProgress)
        let completedProjects = viewModel.getProjectsByStatus(.completed)
        
        XCTAssertEqual(planningProjects.count, 1)
        XCTAssertEqual(inProgressProjects.count, 1)
        XCTAssertEqual(completedProjects.count, 1)
        XCTAssertEqual(planningProjects.first?.name, "Planning Project")
    }
    
    func testGetCompletedProjectsCount() {
        let projects = [
            Project(name: "Planning Project", description: "Test", status: .planning, priority: 0),
            Project(name: "Completed Project 1", description: "Test", status: .completed, priority: 1),
            Project(name: "Completed Project 2", description: "Test", status: .completed, priority: 2)
        ]
        viewModel.projectsState = .loaded(projects)
        
        XCTAssertEqual(viewModel.getCompletedProjectsCount(), 2)
    }
    
    func testGetInProgressProjectsCount() {
        let projects = [
            Project(name: "In Progress Project 1", description: "Test", status: .inProgress, priority: 0),
            Project(name: "In Progress Project 2", description: "Test", status: .inProgress, priority: 1),
            Project(name: "Completed Project", description: "Test", status: .completed, priority: 2)
        ]
        viewModel.projectsState = .loaded(projects)
        
        XCTAssertEqual(viewModel.getInProgressProjectsCount(), 2)
    }
    
    func testGetAverageProgress() {
        let projects = [
            Project(name: "Project 1", description: "Test", status: .planning, priority: 0),
            Project(name: "Project 2", description: "Test", status: .inProgress, priority: 1)
        ]
        projects[0].progress = 0.25
        projects[1].progress = 0.75
        viewModel.projectsState = .loaded(projects)
        
        XCTAssertEqual(viewModel.getAverageProgress(), 0.5, accuracy: 0.001)
    }
    
    func testGetAverageProgressEmptyProjects() {
        viewModel.projectsState = .loaded([])
        XCTAssertEqual(viewModel.getAverageProgress(), 0.0)
    }
}