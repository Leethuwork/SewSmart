import SwiftData
import Foundation
import os.log

@MainActor
class DependencyContainer: ObservableObject {
    private let modelContext: ModelContext
    private let logger = Logger(subsystem: "com.sewsmart.core", category: "DependencyContainer")
    
    // Actor-based repositories
    private lazy var _projectRepository: ProjectRepository = ProjectRepository(modelContext: modelContext)
    private lazy var _patternRepository: PatternRepository = PatternRepository(modelContext: modelContext)
    private lazy var _fabricRepository: FabricRepository = FabricRepository(modelContext: modelContext)
    private lazy var _userSettingsRepository: UserSettingsRepository = UserSettingsRepository(modelContext: modelContext)
    
    // ViewModels (initialized lazily with actor repositories)
    private lazy var _projectsViewModel: ProjectsViewModel = {
        logger.info("Initializing ProjectsViewModel with actor-based repositories")
        return ProjectsViewModel(
            projectRepository: _projectRepository,
            userSettingsRepository: _userSettingsRepository
        )
    }()
    
    private lazy var _patternsViewModel: PatternsViewModel = {
        logger.info("Initializing PatternsViewModel with actor-based repositories")
        return PatternsViewModel(
            patternRepository: _patternRepository,
            userSettingsRepository: _userSettingsRepository
        )
    }()
    
    private lazy var _fabricViewModel: FabricViewModel = {
        logger.info("Initializing FabricViewModel with actor-based repositories")
        return FabricViewModel(
            fabricRepository: _fabricRepository,
            userSettingsRepository: _userSettingsRepository
        )
    }()
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        logger.info("Initialized DependencyContainer with actor-based repositories")
    }
    
    // MARK: - Repository Access (Actor-based)
    var projectRepository: ProjectRepository { _projectRepository }
    var patternRepository: PatternRepository { _patternRepository }
    var fabricRepository: FabricRepository { _fabricRepository }
    var userSettingsRepository: UserSettingsRepository { _userSettingsRepository }
    
    // MARK: - ViewModel Access
    var projectsViewModel: ProjectsViewModel { _projectsViewModel }
    var patternsViewModel: PatternsViewModel { _patternsViewModel }
    var fabricViewModel: FabricViewModel { _fabricViewModel }
}