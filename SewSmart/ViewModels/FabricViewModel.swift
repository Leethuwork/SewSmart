import Foundation
import SwiftUI
import os.log

struct FabricMetrics: Equatable {
    let totalValue: Double
    let totalYardage: Double
}

@MainActor
@Observable
class FabricViewModel {
    private let fabricRepository: FabricRepository
    private let userSettingsRepository: UserSettingsRepository
    private let logger = Logger(subsystem: "com.sewsmart.viewmodel", category: "FabricViewModel")
    private let userFeedback = UserFeedbackSystem.shared
    private let offlineManager = OfflineManager.shared
    
    // State Management
    private(set) var fabricsState: LoadingState<[Fabric]> = .idle
    private(set) var createFabricState: SimpleLoadingState = .idle
    private(set) var updateFabricState: SimpleLoadingState = .idle
    private(set) var deleteFabricState: SimpleLoadingState = .idle
    private(set) var metricsState: LoadingState<FabricMetrics> = .idle
    
    // UI State
    var showingAddFabric = false
    var selectedFabric: Fabric?
    var selectedType: FabricType? = nil
    var searchText = ""
    
    // Computed properties for backward compatibility
    var fabrics: [Fabric] {
        fabricsState.data ?? []
    }
    
    var isLoading: Bool {
        fabricsState.isLoading
    }
    
    var errorMessage: String? {
        fabricsState.error?.localizedDescription
    }
    
    var totalValue: Double {
        metricsState.data?.totalValue ?? 0
    }
    
    var totalYardage: Double {
        metricsState.data?.totalYardage ?? 0
    }
    
    init(
        fabricRepository: FabricRepository,
        userSettingsRepository: UserSettingsRepository
    ) {
        self.fabricRepository = fabricRepository
        self.userSettingsRepository = userSettingsRepository
        logger.info("Initialized FabricViewModel with actor-based repositories")
    }
    
    func loadFabrics() async {
        fabricsState.setLoading()
        
        do {
            let fetchedFabrics: [Fabric]
            
            if !searchText.isEmpty {
                fetchedFabrics = try await fabricRepository.search(query: searchText)
            } else if let type = selectedType {
                fetchedFabrics = try await fabricRepository.fetch(by: type)
            } else {
                fetchedFabrics = try await fabricRepository.fetchAll()
            }
            
            fabricsState.setLoaded(fetchedFabrics)
            logger.info("Loaded \(fetchedFabrics.count) fabrics")
            
            // Load metrics concurrently
            await loadMetrics()
        } catch let error as SewSmartError {
            fabricsState.setFailed(error)
            logger.error("Failed to load fabrics: \(error.localizedDescription)")
        } catch {
            fabricsState.setFailed(.dataCorruption)
            logger.error("Failed to load fabrics: \(error.localizedDescription)")
        }
    }
    
    private func loadMetrics() async {
        metricsState.setLoading()
        
        do {
            async let totalValueTask = fabricRepository.getTotalValue()
            async let totalYardageTask = fabricRepository.getTotalYardage()
            
            let totalValue = try await totalValueTask
            let totalYardage = try await totalYardageTask
            
            metricsState.setLoaded(FabricMetrics(totalValue: totalValue, totalYardage: totalYardage))
            logger.info("Loaded fabric metrics - Value: $\(totalValue), Yardage: \(totalYardage)")
        } catch let error as SewSmartError {
            metricsState.setFailed(error)
            logger.error("Failed to load fabric metrics: \(error.localizedDescription)")
        } catch {
            metricsState.setFailed(.dataCorruption)
            logger.error("Failed to load fabric metrics: \(error.localizedDescription)")
        }
    }
    
    func createFabric(
        name: String,
        type: FabricType,
        color: String = "",
        yardage: Double = 0,
        cost: Double = 0,
        content: String = "",
        brand: String = ""
    ) async {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            createFabricState.setFailed(.invalidInput("Fabric name cannot be empty"))
            return
        }
        
        guard yardage >= 0 else {
            createFabricState.setFailed(.invalidInput("Yardage must be positive"))
            return
        }
        
        guard cost >= 0 else {
            createFabricState.setFailed(.invalidInput("Cost must be positive"))
            return
        }
        
        createFabricState.setLoading()
        
        let fabric = Fabric(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            type: type,
            color: color.trimmingCharacters(in: .whitespacesAndNewlines),
            yardage: yardage
        )
        fabric.cost = cost
        fabric.content = content.trimmingCharacters(in: .whitespacesAndNewlines)
        fabric.brand = brand.trimmingCharacters(in: .whitespacesAndNewlines)
        
        do {
            try await fabricRepository.save(fabric)
            try await userSettingsRepository.addHistory(
                action: .addedFabric,
                details: "\(name) - \(type.rawValue)",
                context: .fabric
            )
            createFabricState.setSuccess()
            await loadFabrics()
            logger.info("Created fabric: \(name)")
        } catch let error as SewSmartError {
            createFabricState.setFailed(error)
            logger.error("Failed to create fabric: \(error.localizedDescription)")
        } catch {
            createFabricState.setFailed(.dataStorageUnavailable)
            logger.error("Failed to create fabric: \(error.localizedDescription)")
        }
    }
    
    func updateFabric(_ fabric: Fabric) async {
        updateFabricState.setLoading()
        
        do {
            try await fabricRepository.update(fabric)
            updateFabricState.setSuccess()
            await loadFabrics()
            logger.info("Updated fabric: \(fabric.name)")
        } catch let error as SewSmartError {
            updateFabricState.setFailed(error)
            logger.error("Failed to update fabric: \(error.localizedDescription)")
        } catch {
            updateFabricState.setFailed(.dataStorageUnavailable)
            logger.error("Failed to update fabric: \(error.localizedDescription)")
        }
    }
    
    func deleteFabric(_ fabric: Fabric) async {
        deleteFabricState.setLoading()
        
        do {
            try await fabricRepository.delete(fabric)
            try await userSettingsRepository.addHistory(
                action: .deletedFabric,
                details: fabric.name,
                context: .fabric
            )
            deleteFabricState.setSuccess()
            await loadFabrics()
            logger.info("Deleted fabric: \(fabric.name)")
        } catch let error as SewSmartError {
            deleteFabricState.setFailed(error)
            logger.error("Failed to delete fabric: \(error.localizedDescription)")
        } catch {
            deleteFabricState.setFailed(.dataStorageUnavailable)
            logger.error("Failed to delete fabric: \(error.localizedDescription)")
        }
    }
    
    func filterFabrics(by type: FabricType?) async {
        selectedType = type
        await loadFabrics()
    }
    
    func clearFilters() async {
        selectedType = nil
        await loadFabrics()
    }
    
    func getFabricsByType(_ type: FabricType) -> [Fabric] {
        return fabrics.filter { $0.type == type }
    }
    
    func getTypeDistribution() -> [FabricType: Int] {
        var distribution: [FabricType: Int] = [:]
        for type in FabricType.allCases {
            distribution[type] = fabrics.filter { $0.type == type }.count
        }
        return distribution
    }
    
    func getTypeValueDistribution() -> [FabricType: Double] {
        var distribution: [FabricType: Double] = [:]
        for type in FabricType.allCases {
            let typeTotal = fabrics.filter { $0.type == type }.reduce(0) { $0 + $1.cost }
            distribution[type] = typeTotal
        }
        return distribution
    }
    
    func getAverageCostPerYard() -> Double {
        let totalCost = fabrics.reduce(0) { $0 + $1.cost }
        let totalYards = fabrics.reduce(0) { $0 + $1.yardage }
        return totalYards > 0 ? totalCost / totalYards : 0
    }
    
    // State management methods
    func clearError() {
        if fabricsState.isFailed {
            fabricsState.setIdle()
        }
        if metricsState.isFailed {
            metricsState.setIdle()
        }
    }
    
    func clearCreateFabricState() {
        createFabricState.setIdle()
    }
    
    func clearUpdateFabricState() {
        updateFabricState.setIdle()
    }
    
    func clearDeleteFabricState() {
        deleteFabricState.setIdle()
    }
    
    func updateSearchText(_ text: String) {
        searchText = text
        Task {
            // Debounce search if needed
            try await Task.sleep(for: .milliseconds(300))
            if searchText == text { // Check if search text hasn't changed
                await loadFabrics()
            }
        }
    }
    
    // Memory cleanup
    deinit {
        logger.info("FabricViewModel deinitialized")
    }
}