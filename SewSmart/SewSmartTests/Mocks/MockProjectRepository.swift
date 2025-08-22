import Foundation
@testable import SewSmart

class MockProjectRepository: ProjectRepositoryProtocol {
    private var projects: [Project] = []
    var shouldThrowError = false
    var errorToThrow: Error = MockError.testError
    
    // Tracking calls for verification
    var fetchAllCalled = false
    var fetchByIdCalled = false
    var saveCalled = false
    var deleteCalled = false
    var updateCalled = false
    var lastSavedProject: Project?
    var lastDeletedProject: Project?
    var lastUpdatedProject: Project?
    
    func fetchAll() async throws -> [Project] {
        fetchAllCalled = true
        if shouldThrowError {
            throw errorToThrow
        }
        return projects.sorted { $0.createdDate > $1.createdDate }
    }
    
    func fetch(by id: UUID) async throws -> Project? {
        fetchByIdCalled = true
        if shouldThrowError {
            throw errorToThrow
        }
        return projects.first { $0.id == id }
    }
    
    func save(_ project: Project) async throws {
        saveCalled = true
        lastSavedProject = project
        if shouldThrowError {
            throw errorToThrow
        }
        projects.append(project)
    }
    
    func delete(_ project: Project) async throws {
        deleteCalled = true
        lastDeletedProject = project
        if shouldThrowError {
            throw errorToThrow
        }
        projects.removeAll { $0.id == project.id }
    }
    
    func update(_ project: Project) async throws {
        updateCalled = true
        lastUpdatedProject = project
        if shouldThrowError {
            throw errorToThrow
        }
        project.updatedDate = Date()
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
        shouldThrowError = false
        fetchAllCalled = false
        fetchByIdCalled = false
        saveCalled = false
        deleteCalled = false
        updateCalled = false
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