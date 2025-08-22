import SwiftData
import Foundation

@MainActor
class DependencyContainer: ObservableObject {
    private let modelContext: ModelContext
    
    // Repositories
    private lazy var _projectRepository: ProjectRepositoryProtocol = ProjectRepository(modelContext: modelContext)
    private lazy var _patternRepository: PatternRepositoryProtocol = PatternRepository(modelContext: modelContext)
    private lazy var _fabricRepository: FabricRepositoryProtocol = FabricRepository(modelContext: modelContext)
    private lazy var _userSettingsRepository: UserSettingsRepositoryProtocol = UserSettingsRepository(modelContext: modelContext)
    
    // ViewModels
    private lazy var _projectsViewModel: ProjectsViewModel = ProjectsViewModel(
        projectRepository: _projectRepository,
        userSettingsRepository: _userSettingsRepository
    )
    
    private lazy var _patternsViewModel: PatternsViewModel = PatternsViewModel(
        patternRepository: _patternRepository,
        userSettingsRepository: _userSettingsRepository
    )
    
    private lazy var _fabricViewModel: FabricViewModel = FabricViewModel(
        fabricRepository: _fabricRepository,
        userSettingsRepository: _userSettingsRepository
    )
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Repository Access
    var projectRepository: ProjectRepositoryProtocol { _projectRepository }
    var patternRepository: PatternRepositoryProtocol { _patternRepository }
    var fabricRepository: FabricRepositoryProtocol { _fabricRepository }
    var userSettingsRepository: UserSettingsRepositoryProtocol { _userSettingsRepository }
    
    // MARK: - ViewModel Access
    var projectsViewModel: ProjectsViewModel { _projectsViewModel }
    var patternsViewModel: PatternsViewModel { _patternsViewModel }
    var fabricViewModel: FabricViewModel { _fabricViewModel }
}