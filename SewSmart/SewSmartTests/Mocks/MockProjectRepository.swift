import Foundation
@testable import SewSmart

class MockProjectRepository: ProjectRepositoryProtocol {
    private var projects: [Project] = []
    var shouldThrowError = false
    var shouldFail = false
    var errorToThrow: Error = MockError.testError
    
    // Mock data for different scenarios
    var mockProjects: [Project] = []
    var mockProjectsByStatus: [Project] = []
    var mockSearchResults: [Project] = []
    
    // Tracking calls for verification
    var fetchAllCalled = false
    var fetchByIdCalled = false
    var fetchByStatusCalled = false
    var fetchActiveCalled = false
    var searchCalled = false
    var saveCalled = false
    var deleteCalled = false
    var updateCalled = false
    var batchDeleteCalled = false
    var lastSavedProject: Project?
    var lastDeletedProject: Project?
    var lastUpdatedProject: Project?
    
    func fetchAll() async throws -> [Project] {
        fetchAllCalled = true
        if shouldThrowError || shouldFail {
            throw errorToThrow
        }
        return mockProjects.isEmpty ? projects.sorted { $0.createdDate > $1.createdDate } : mockProjects
    }
    
    func fetch(by id: UUID) async throws -> Project? {
        fetchByIdCalled = true
        if shouldThrowError || shouldFail {
            throw errorToThrow
        }
        let allProjects = mockProjects.isEmpty ? projects : mockProjects
        return allProjects.first { $0.id == id }
    }
    
    func fetch(by status: ProjectStatus) async throws -> [Project] {
        fetchByStatusCalled = true
        if shouldThrowError || shouldFail {
            throw errorToThrow
        }
        return mockProjectsByStatus.isEmpty ? projects.filter { $0.status == status } : mockProjectsByStatus
    }
    
    func fetchActive() async throws -> [Project] {
        fetchActiveCalled = true
        if shouldThrowError || shouldFail {
            throw errorToThrow
        }
        return projects.filter { $0.status == .inProgress || $0.status == .planning }
    }
    
    func search(query: String) async throws -> [Project] {
        searchCalled = true
        if shouldThrowError || shouldFail {
            throw errorToThrow
        }
        if !mockSearchResults.isEmpty {
            return mockSearchResults
        }
        let searchTerm = query.lowercased()
        return projects.filter { 
            $0.name.lowercased().contains(searchTerm) || 
            $0.projectDescription.lowercased().contains(searchTerm)
        }
    }
    
    func save(_ project: Project) async throws {
        saveCalled = true
        lastSavedProject = project
        if shouldThrowError || shouldFail {
            throw errorToThrow
        }
        projects.append(project)
    }
    
    func delete(_ project: Project) async throws {
        deleteCalled = true
        lastDeletedProject = project
        if shouldThrowError || shouldFail {
            throw errorToThrow
        }
        projects.removeAll { $0.id == project.id }
    }
    
    func update(_ project: Project) async throws {
        updateCalled = true
        lastUpdatedProject = project
        if shouldThrowError || shouldFail {
            throw errorToThrow
        }
        project.updatedDate = Date()
    }
    
    func batchDelete(_ projects: [Project]) async throws {
        batchDeleteCalled = true
        if shouldThrowError || shouldFail {
            throw errorToThrow
        }
        for project in projects {
            self.projects.removeAll { $0.id == project.id }
        }
    }
    
    // Test helpers
    func addProject(_ project: Project) {
        projects.append(project)
    }
    
    func removeAll() {
        projects.removeAll()
    }
    
    func reset() {
        projects.removeAll()
        mockProjects.removeAll()
        mockProjectsByStatus.removeAll()
        mockSearchResults.removeAll()
        shouldThrowError = false
        shouldFail = false
        fetchAllCalled = false
        fetchByIdCalled = false
        fetchByStatusCalled = false
        fetchActiveCalled = false
        searchCalled = false
        saveCalled = false
        deleteCalled = false
        updateCalled = false
        batchDeleteCalled = false
        lastSavedProject = nil
        lastDeletedProject = nil
        lastUpdatedProject = nil
    }
}

enum MockError: Error, LocalizedError {
    case testError
    case networkError
    case databaseError
    
    var errorDescription: String? {
        switch self {
        case .testError:
            return "Test error"
        case .networkError:
            return "Network error"
        case .databaseError:
            return "Database error"
        }
    }
}