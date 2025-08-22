import Foundation
import SwiftData

protocol ProjectRepositoryProtocol {
    func fetchAll() async throws -> [Project]
    func fetch(by id: UUID) async throws -> Project?
    func save(_ project: Project) async throws
    func delete(_ project: Project) async throws
    func update(_ project: Project) async throws
}

class ProjectRepository: ProjectRepositoryProtocol {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func fetchAll() async throws -> [Project] {
        let descriptor = FetchDescriptor<Project>(
            sortBy: [SortDescriptor(\.createdDate, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    func fetch(by id: UUID) async throws -> Project? {
        let descriptor = FetchDescriptor<Project>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }
    
    func save(_ project: Project) async throws {
        modelContext.insert(project)
        try modelContext.save()
    }
    
    func delete(_ project: Project) async throws {
        modelContext.delete(project)
        try modelContext.save()
    }
    
    func update(_ project: Project) async throws {
        project.updatedDate = Date()
        try modelContext.save()
    }
}