import XCTest
import SwiftData
@testable import SewSmart

@MainActor
final class ProjectsViewModelTests: XCTestCase {
    var viewModel: ProjectsViewViewModel!
    var addProjectViewModel: AddProjectViewModel!
    var detailViewModel: ProjectDetailViewModel!
    var modelContext: ModelContext!
    var container: ModelContainer!
    
    @MainActor
    override func setUp() {
        super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try! ModelContainer(for: Project.self, UserSettings.self, configurations: config)
        modelContext = container.mainContext
        viewModel = ProjectsViewViewModel(modelContext: modelContext)
        addProjectViewModel = AddProjectViewModel(modelContext: modelContext)
        detailViewModel = ProjectDetailViewModel()
    }
    
    override func tearDown() {
        viewModel = nil
        addProjectViewModel = nil
        detailViewModel = nil
        modelContext = nil
        container = nil
        super.tearDown()
    }
    
    // MARK: - ProjectsViewViewModel Tests
    
    func testInitialState() {
        XCTAssertFalse(viewModel.showingAddProject)
        XCTAssertNil(viewModel.selectedProject)
    }
    
    func testShowAddProject() {
        viewModel.showAddProject()
        XCTAssertTrue(viewModel.showingAddProject)
    }
    
    func testHideAddProject() {
        viewModel.showAddProject()
        viewModel.hideAddProject()
        XCTAssertFalse(viewModel.showingAddProject)
    }
    
    func testSelectProject() {
        let project = Project(name: "Test Project", description: "Test", status: .planning, priority: 0)
        viewModel.selectProject(project)
        XCTAssertEqual(viewModel.selectedProject, project)
    }
    
    func testDeselectProject() {
        let project = Project(name: "Test Project", description: "Test", status: .planning, priority: 0)
        viewModel.selectProject(project)
        viewModel.deselectProject()
        XCTAssertNil(viewModel.selectedProject)
    }
    
    func testStatusColor() {
        XCTAssertEqual(viewModel.statusColor(for: .planning), DesignSystem.colorForStatus(.planning))
        XCTAssertEqual(viewModel.statusColor(for: .inProgress), DesignSystem.colorForStatus(.inProgress))
        XCTAssertEqual(viewModel.statusColor(for: .completed), DesignSystem.colorForStatus(.completed))
        XCTAssertEqual(viewModel.statusColor(for: .onHold), DesignSystem.colorForStatus(.onHold))
    }
    
    func testStatusEmoji() {
        XCTAssertEqual(viewModel.statusEmoji(for: .planning), "🎯")
        XCTAssertEqual(viewModel.statusEmoji(for: .inProgress), "🌸")
        XCTAssertEqual(viewModel.statusEmoji(for: .completed), "🏆")
        XCTAssertEqual(viewModel.statusEmoji(for: .onHold), "⏸️")
    }
    
    func testDeleteProject() {
        let project = Project(name: "Test Project", description: "Test", status: .planning, priority: 0)
        modelContext.insert(project)
        
        do {
            try modelContext.save()
        } catch {
            XCTFail("Failed to save project: \(error)")
        }
        
        viewModel.deleteProject(project)
        
        let descriptor = FetchDescriptor<Project>()
        let projects = try! modelContext.fetch(descriptor)
        XCTAssertEqual(projects.count, 0)
    }
    
    // MARK: - AddProjectViewModel Tests
    
    func testAddProjectInitialState() {
        XCTAssertEqual(addProjectViewModel.name, "")
        XCTAssertEqual(addProjectViewModel.description, "")
        XCTAssertEqual(addProjectViewModel.status, .planning)
        XCTAssertEqual(addProjectViewModel.priority, 0)
        XCTAssertFalse(addProjectViewModel.hasDueDate)
        XCTAssertFalse(addProjectViewModel.isFormValid)
    }
    
    func testFormValidation() {
        addProjectViewModel.name = ""
        XCTAssertFalse(addProjectViewModel.isFormValid)
        
        addProjectViewModel.name = "   "
        XCTAssertFalse(addProjectViewModel.isFormValid)
        
        addProjectViewModel.name = "Test Project"
        XCTAssertTrue(addProjectViewModel.isFormValid)
    }
    
    func testSaveProject() {
        addProjectViewModel.name = "Test Project"
        addProjectViewModel.description = "Test Description"
        addProjectViewModel.status = .inProgress
        addProjectViewModel.priority = 2
        
        let result = addProjectViewModel.saveProject()
        XCTAssertTrue(result)
        
        let descriptor = FetchDescriptor<Project>()
        let projects = try! modelContext.fetch(descriptor)
        XCTAssertEqual(projects.count, 1)
        
        let savedProject = projects.first!
        XCTAssertEqual(savedProject.name, "Test Project")
        XCTAssertEqual(savedProject.projectDescription, "Test Description")
        XCTAssertEqual(savedProject.status, .inProgress)
        XCTAssertEqual(savedProject.priority, 2)
    }
    
    func testSaveProjectWithDueDate() {
        addProjectViewModel.name = "Test Project"
        addProjectViewModel.hasDueDate = true
        let dueDate = Date()
        addProjectViewModel.dueDate = dueDate
        
        let result = addProjectViewModel.saveProject()
        XCTAssertTrue(result)
        
        let descriptor = FetchDescriptor<Project>()
        let projects = try! modelContext.fetch(descriptor)
        let savedProject = projects.first!
        XCTAssertNotNil(savedProject.dueDate)
    }
    
    func testResetForm() {
        addProjectViewModel.name = "Test"
        addProjectViewModel.description = "Test Desc"
        addProjectViewModel.status = .completed
        addProjectViewModel.priority = 3
        addProjectViewModel.hasDueDate = true
        
        addProjectViewModel.resetForm()
        
        XCTAssertEqual(addProjectViewModel.name, "")
        XCTAssertEqual(addProjectViewModel.description, "")
        XCTAssertEqual(addProjectViewModel.status, .planning)
        XCTAssertEqual(addProjectViewModel.priority, 0)
        XCTAssertFalse(addProjectViewModel.hasDueDate)
    }
    
    func testPriorityText() {
        XCTAssertEqual(addProjectViewModel.priorityText(for: 0), "Low")
        XCTAssertEqual(addProjectViewModel.priorityText(for: 1), "Medium")
        XCTAssertEqual(addProjectViewModel.priorityText(for: 2), "High")
        XCTAssertEqual(addProjectViewModel.priorityText(for: 3), "Urgent")
        XCTAssertEqual(addProjectViewModel.priorityText(for: 99), "Low")
    }
    
    // MARK: - ProjectDetailViewModel Tests
    
    func testDetailViewModelInitialState() {
        XCTAssertFalse(detailViewModel.isEditing)
    }
    
    func testToggleEditing() {
        XCTAssertFalse(detailViewModel.isEditing)
        detailViewModel.toggleEditing()
        XCTAssertTrue(detailViewModel.isEditing)
        detailViewModel.toggleEditing()
        XCTAssertFalse(detailViewModel.isEditing)
    }
    
    func testFormatProgress() {
        XCTAssertEqual(detailViewModel.formatProgress(0.0), "0%")
        XCTAssertEqual(detailViewModel.formatProgress(0.5), "50%")
        XCTAssertEqual(detailViewModel.formatProgress(1.0), "100%")
        XCTAssertEqual(detailViewModel.formatProgress(0.333), "33%")
    }
    
    func testFormatDate() {
        let date = Date()
        let startedText = detailViewModel.formatDate(date, isCompleted: false)
        let completedText = detailViewModel.formatDate(date, isCompleted: true)
        
        XCTAssertTrue(startedText.contains("📅 Started"))
        XCTAssertTrue(completedText.contains("🎉 Finished"))
    }
    
    func testHasPhotos() {
        let project = Project(name: "Test", description: "", status: .planning, priority: 0)
        XCTAssertFalse(detailViewModel.hasPhotos(project))
        
        // Note: Would need to create ProjectPhoto objects to test true case
    }
    
    func testHasNotes() {
        let project = Project(name: "Test", description: "", status: .planning, priority: 0)
        XCTAssertFalse(detailViewModel.hasNotes(project))
        
        project.notes = "Some notes"
        XCTAssertTrue(detailViewModel.hasNotes(project))
    }
    
    func testHasDescription() {
        let project = Project(name: "Test", description: "", status: .planning, priority: 0)
        XCTAssertFalse(detailViewModel.hasDescription(project))
        
        project.projectDescription = "Some description"
        XCTAssertTrue(detailViewModel.hasDescription(project))
    }
}