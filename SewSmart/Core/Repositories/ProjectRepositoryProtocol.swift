import Foundation
import SwiftData
import os.log

protocol ProjectRepositoryProtocol: Sendable {
    func fetchAll() async throws -> [Project]
    func fetch(by id: UUID) async throws -> Project?
    func fetch(by status: ProjectStatus) async throws -> [Project]
    func fetchActive() async throws -> [Project]
    func search(query: String) async throws -> [Project]
    func save(_ project: Project) async throws
    func delete(_ project: Project) async throws
    func update(_ project: Project) async throws
    func batchDelete(_ projects: [Project]) async throws
}

actor ProjectRepository: ProjectRepositoryProtocol {
    private let modelContext: ModelContext
    private let logger = Logger(subsystem: "com.sewsmart.repository", category: "ProjectRepository")
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func fetchAll() async throws -> [Project] {
        return try await PerformanceMonitor.shared.measureSwiftDataOperation("fetchAllProjects") { () -> [Project] in
            do {
                let descriptor = FetchDescriptor<Project>(
                    sortBy: [SortDescriptor(\.updatedDate, order: .reverse)]
                )
                let projects = try modelContext.fetch(descriptor)
                logger.info("Successfully fetched \(projects.count) projects")
                return projects
            } catch {
                logger.error("Failed to fetch all projects: \(error.localizedDescription)")
                throw SewSmartError.dataCorruption
            }
        }
    }
    
    func fetch(by id: UUID) async throws -> Project? {
        do {
            let descriptor = FetchDescriptor<Project>(
                predicate: #Predicate { $0.id == id }
            )
            let project = try modelContext.fetch(descriptor).first
            logger.info("Fetched project with ID: \(id)")
            return project
        } catch {
            logger.error("Failed to fetch project by ID \(id): \(error.localizedDescription)")
            throw SewSmartError.dataCorruption
        }
    }
    
    func fetch(by status: ProjectStatus) async throws -> [Project] {
        do {
            let descriptor = FetchDescriptor<Project>(
                predicate: #Predicate { $0.status == status },
                sortBy: [SortDescriptor(\.updatedDate, order: .reverse)]
            )
            let projects = try modelContext.fetch(descriptor)
            logger.info("Fetched \(projects.count) projects with status: \(status.rawValue)")
            return projects
        } catch {
            logger.error("Failed to fetch projects by status \(status.rawValue): \(error.localizedDescription)")
            throw SewSmartError.dataCorruption
        }
    }
    
    func fetchActive() async throws -> [Project] {
        do {
            let descriptor = FetchDescriptor<Project>(
                sortBy: [SortDescriptor(\.updatedDate, order: .reverse)]
            )
            let allProjects = try modelContext.fetch(descriptor)
            let activeProjects = allProjects.filter { 
                $0.status == .inProgress || $0.status == .planning 
            }
            logger.info("Fetched \(activeProjects.count) active projects")
            return activeProjects
        } catch {
            logger.error("Failed to fetch active projects: \(error.localizedDescription)")
            throw SewSmartError.dataCorruption
        }
    }
    
    func search(query: String) async throws -> [Project] {
        return try await PerformanceMonitor.shared.measureSwiftDataOperation("searchProjects") { () -> [Project] in
            do {
                let searchTerm = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                guard !searchTerm.isEmpty else { return [] }
                
                let descriptor = FetchDescriptor<Project>(
                    predicate: #Predicate { project in
                        project.name.localizedStandardContains(searchTerm) ||
                        project.projectDescription.localizedStandardContains(searchTerm)
                    },
                    sortBy: [SortDescriptor(\.updatedDate, order: .reverse)]
                )
                let projects = try modelContext.fetch(descriptor)
                logger.info("Search for '\(query)' returned \(projects.count) projects")
                return projects
            } catch {
                logger.error("Failed to search projects with query '\(query)': \(error.localizedDescription)")
                throw SewSmartError.dataCorruption
            }
        }
    }
    
    func save(_ project: Project) async throws {
        try await PerformanceMonitor.shared.measureSwiftDataOperation("saveProject") { () -> Void in
            do {
                modelContext.insert(project)
                try modelContext.save()
                logger.info("Successfully saved project: \(project.name)")
            } catch {
                logger.error("Failed to save project \(project.name): \(error.localizedDescription)")
                throw SewSmartError.dataStorageUnavailable
            }
        }
    }
    
    func delete(_ project: Project) async throws {
        do {
            modelContext.delete(project)
            try modelContext.save()
            logger.info("Successfully deleted project: \(project.name)")
        } catch {
            logger.error("Failed to delete project \(project.name): \(error.localizedDescription)")
            throw SewSmartError.dataStorageUnavailable
        }
    }
    
    func update(_ project: Project) async throws {
        do {
            project.updatedDate = Date()
            try modelContext.save()
            logger.info("Successfully updated project: \(project.name)")
        } catch {
            logger.error("Failed to update project \(project.name): \(error.localizedDescription)")
            throw SewSmartError.dataStorageUnavailable
        }
    }
    
    func batchDelete(_ projects: [Project]) async throws {
        do {
            for project in projects {
                modelContext.delete(project)
            }
            try modelContext.save()
            logger.info("Successfully batch deleted \(projects.count) projects")
        } catch {
            logger.error("Failed to batch delete projects: \(error.localizedDescription)")
            throw SewSmartError.dataStorageUnavailable
        }
    }
}