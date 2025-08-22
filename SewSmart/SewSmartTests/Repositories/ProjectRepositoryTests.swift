import Testing
import SwiftData
import Foundation
@testable import SewSmart

@MainActor
struct ProjectRepositoryTests {
    
    private func createInMemoryModelContext() throws -> ModelContext {
        let schema = Schema([
            Project.self,
            Pattern.self,
            Fabric.self,
            MeasurementProfile.self,
            Measurement.self,
            ProjectPhoto.self,
            ShoppingList.self,
            ShoppingItem.self,
            UserSettings.self,
            UserHistory.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        return ModelContext(container)
    }
    
    @Test func testFetchAllProjectsEmpty() async throws {
        let modelContext = try createInMemoryModelContext()
        let repository = ProjectRepository(modelContext: modelContext)
        
        let projects = try await repository.fetchAll()
        
        #expect(projects.isEmpty)
    }
    
    @Test func testSaveAndFetchProject() async throws {
        let modelContext = try createInMemoryModelContext()
        let repository = ProjectRepository(modelContext: modelContext)
        
        let project = Project(name: "Test Project", description: "Test Description", status: .planning)
        
        try await repository.save(project)
        let fetchedProjects = try await repository.fetchAll()
        
        #expect(fetchedProjects.count == 1)
        #expect(fetchedProjects[0].name == "Test Project")
        #expect(fetchedProjects[0].projectDescription == "Test Description")
        #expect(fetchedProjects[0].status == .planning)
    }
    
    @Test func testFetchProjectById() async throws {
        let modelContext = try createInMemoryModelContext()
        let repository = ProjectRepository(modelContext: modelContext)
        
        let project = Project(name: "Test Project", description: "Test Description", status: .planning)
        let projectId = project.id
        
        try await repository.save(project)
        let fetchedProject = try await repository.fetch(by: projectId)
        
        #expect(fetchedProject != nil)
        #expect(fetchedProject?.name == "Test Project")
        #expect(fetchedProject?.id == projectId)
    }
    
    @Test func testFetchProjectByIdNotFound() async throws {
        let modelContext = try createInMemoryModelContext()
        let repository = ProjectRepository(modelContext: modelContext)
        
        let nonExistentId = UUID()
        let fetchedProject = try await repository.fetch(by: nonExistentId)
        
        #expect(fetchedProject == nil)
    }
    
    @Test func testUpdateProject() async throws {
        let modelContext = try createInMemoryModelContext()
        let repository = ProjectRepository(modelContext: modelContext)
        
        let project = Project(name: "Original Project", description: "Original Description", status: .planning)
        try await repository.save(project)
        
        // Update the project
        project.name = "Updated Project"
        project.projectDescription = "Updated Description"
        project.status = .inProgress
        project.progress = 0.5
        
        let originalUpdatedDate = project.updatedDate
        
        // Wait a moment to ensure updated date changes
        try await Task.sleep(for: .milliseconds(10))
        
        try await repository.update(project)
        
        // Fetch the updated project
        let fetchedProject = try await repository.fetch(by: project.id)
        
        #expect(fetchedProject?.name == "Updated Project")
        #expect(fetchedProject?.projectDescription == "Updated Description")
        #expect(fetchedProject?.status == .inProgress)
        #expect(fetchedProject?.progress == 0.5)
        #expect(fetchedProject?.updatedDate ?? Date.distantPast > originalUpdatedDate)
    }
    
    @Test func testDeleteProject() async throws {
        let modelContext = try createInMemoryModelContext()
        let repository = ProjectRepository(modelContext: modelContext)
        
        let project1 = Project(name: "Project 1", description: "Description 1", status: .planning)
        let project2 = Project(name: "Project 2", description: "Description 2", status: .inProgress)
        
        try await repository.save(project1)
        try await repository.save(project2)
        
        // Verify both projects exist
        let allProjects = try await repository.fetchAll()
        #expect(allProjects.count == 2)
        
        // Delete project1
        try await repository.delete(project1)
        
        // Verify only project2 remains
        let remainingProjects = try await repository.fetchAll()
        #expect(remainingProjects.count == 1)
        #expect(remainingProjects[0].name == "Project 2")
    }
    
    @Test func testFetchAllProjectsSortedByCreatedDate() async throws {
        let modelContext = try createInMemoryModelContext()
        let repository = ProjectRepository(modelContext: modelContext)
        
        let project1 = Project(name: "First Project", description: "Description 1", status: .planning)
        let project2 = Project(name: "Second Project", description: "Description 2", status: .inProgress)
        let project3 = Project(name: "Third Project", description: "Description 3", status: .completed)
        
        // Save projects with small delays to ensure different creation times
        try await repository.save(project1)
        try await Task.sleep(for: .milliseconds(10))
        
        try await repository.save(project2)
        try await Task.sleep(for: .milliseconds(10))
        
        try await repository.save(project3)
        
        let fetchedProjects = try await repository.fetchAll()
        
        #expect(fetchedProjects.count == 3)
        // Should be sorted by creation date in reverse order (newest first)
        #expect(fetchedProjects[0].name == "Third Project")
        #expect(fetchedProjects[1].name == "Second Project")
        #expect(fetchedProjects[2].name == "First Project")
    }
    
    @Test func testSaveMultipleProjects() async throws {
        let modelContext = try createInMemoryModelContext()
        let repository = ProjectRepository(modelContext: modelContext)
        
        let projects = [
            Project(name: "Project A", status: .planning),
            Project(name: "Project B", status: .inProgress),
            Project(name: "Project C", status: .completed),
            Project(name: "Project D", status: .onHold)
        ]
        
        for project in projects {
            try await repository.save(project)
        }
        
        let fetchedProjects = try await repository.fetchAll()
        #expect(fetchedProjects.count == 4)
        
        let projectNames = Set(fetchedProjects.map { $0.name })
        #expect(projectNames.contains("Project A"))
        #expect(projectNames.contains("Project B"))
        #expect(projectNames.contains("Project C"))
        #expect(projectNames.contains("Project D"))
    }
    
    @Test func testProjectWithComplexData() async throws {
        let modelContext = try createInMemoryModelContext()
        let repository = ProjectRepository(modelContext: modelContext)
        
        let project = Project(name: "Complex Project", description: "Complex Description", status: .inProgress, priority: 2)
        project.progress = 0.75
        project.notes = "These are some notes"
        project.dueDate = Date().addingTimeInterval(86400) // Tomorrow
        
        try await repository.save(project)
        let fetchedProject = try await repository.fetch(by: project.id)
        
        #expect(fetchedProject?.name == "Complex Project")
        #expect(fetchedProject?.projectDescription == "Complex Description")
        #expect(fetchedProject?.status == .inProgress)
        #expect(fetchedProject?.priority == 2)
        #expect(fetchedProject?.progress == 0.75)
        #expect(fetchedProject?.notes == "These are some notes")
        #expect(fetchedProject?.dueDate != nil)
    }
}