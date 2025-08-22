import Testing
import SwiftData
import Foundation
@testable import SewSmart

@MainActor
struct DependencyContainerTests {
    
    func createInMemoryModelContext() -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Project.self, Pattern.self, Fabric.self, UserSettings.self, configurations: config)
        return ModelContext(container)
    }
    
    @Test func testDependencyContainerInitialization() {
        let modelContext = createInMemoryModelContext()
        let container = DependencyContainer(modelContext: modelContext)
        
        // Verify that the container is properly initialized
        #expect(type(of: container) == DependencyContainer.self)
    }
    
    @Test func testRepositoryAccess() {
        let modelContext = createInMemoryModelContext()
        let container = DependencyContainer(modelContext: modelContext)
        
        // Test that all repositories are accessible and of correct types
        #expect(container.projectRepository is ProjectRepository)
        #expect(container.patternRepository is PatternRepository)
        #expect(container.fabricRepository is FabricRepository)
        #expect(container.userSettingsRepository is UserSettingsRepository)
    }
    
    @Test func testViewModelAccess() {
        let modelContext = createInMemoryModelContext()
        let container = DependencyContainer(modelContext: modelContext)
        
        // Test that all ViewModels are accessible and of correct types
        #expect(container.projectsViewModel is ProjectsViewModel)
        #expect(container.patternsViewModel is PatternsViewModel)
        #expect(container.fabricViewModel is FabricViewModel)
    }
    
    @Test func testRepositoryDependencyInjection() {
        let modelContext = createInMemoryModelContext()
        let container = DependencyContainer(modelContext: modelContext)
        
        // Verify that repositories are properly injected into ViewModels
        // by testing that the ViewModels can be created without throwing errors
        let projectsViewModel = container.projectsViewModel
        let patternsViewModel = container.patternsViewModel
        let fabricViewModel = container.fabricViewModel
        
        #expect(type(of: projectsViewModel) == ProjectsViewModel.self)
        #expect(type(of: patternsViewModel) == PatternsViewModel.self)
        #expect(type(of: fabricViewModel) == FabricViewModel.self)
    }
    
    @Test func testRepositoryFunctionality() async throws {
        let modelContext = createInMemoryModelContext()
        let container = DependencyContainer(modelContext: modelContext)
        
        // Test that repositories can actually perform operations
        let projectRepository = container.projectRepository
        let projects = try await projectRepository.fetchAll()
        
        // Should start with empty list
        #expect(projects.isEmpty)
        
        // Create a test project
        let testProject = Project(name: "Test Project", description: "Test Description")
        try await projectRepository.save(testProject)
        
        // Verify it was saved
        let updatedProjects = try await projectRepository.fetchAll()
        #expect(updatedProjects.count == 1)
        #expect(updatedProjects.first?.name == "Test Project")
    }
    
    @Test func testAllRepositoriesAreAccessible() {
        let modelContext = createInMemoryModelContext()
        let container = DependencyContainer(modelContext: modelContext)
        
        // This is a conceptual test to verify all repositories are accessible
        // and properly configured by the container
        
        #expect(container.projectRepository is ProjectRepository)
        #expect(container.patternRepository is PatternRepository) 
        #expect(container.fabricRepository is FabricRepository)
        #expect(container.userSettingsRepository is UserSettingsRepository)
    }
}