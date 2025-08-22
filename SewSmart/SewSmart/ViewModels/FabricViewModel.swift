import Foundation
import SwiftUI

@MainActor
@Observable
class FabricViewModel {
    private let fabricRepository: FabricRepositoryProtocol
    private let userSettingsRepository: UserSettingsRepositoryProtocol
    
    var fabrics: [Fabric] = []
    var isLoading = false
    var errorMessage: String?
    var showingAddFabric = false
    var selectedFabric: Fabric?
    var selectedType: FabricType? = nil
    var totalValue: Double = 0
    var totalYardage: Double = 0
    
    init(
        fabricRepository: FabricRepositoryProtocol,
        userSettingsRepository: UserSettingsRepositoryProtocol
    ) {
        self.fabricRepository = fabricRepository
        self.userSettingsRepository = userSettingsRepository
    }
    
    func loadFabrics() async {
        isLoading = true
        errorMessage = nil
        
        do {
            if let type = selectedType {
                fabrics = try await fabricRepository.fetch(by: type)
            } else {
                fabrics = try await fabricRepository.fetchAll()
            }
            
            totalValue = try await fabricRepository.getTotalValue()
            totalYardage = try await fabricRepository.getTotalYardage()
        } catch {
            errorMessage = "Failed to load fabrics: \(error.localizedDescription)"
        }
        
        isLoading = false
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
        guard !name.isEmpty else { return }
        
        let fabric = Fabric(
            name: name,
            type: type,
            color: color,
            yardage: yardage
        )
        fabric.cost = cost
        fabric.content = content
        fabric.brand = brand
        
        do {
            try await fabricRepository.save(fabric)
            try await userSettingsRepository.addHistory(
                action: .addedFabric,
                details: "\(name) - \(type.rawValue)",
                context: .fabric
            )
            await loadFabrics()
        } catch {
            errorMessage = "Failed to create fabric: \(error.localizedDescription)"
        }
    }
    
    func updateFabric(_ fabric: Fabric) async {
        do {
            try await fabricRepository.update(fabric)
            await loadFabrics()
        } catch {
            errorMessage = "Failed to update fabric: \(error.localizedDescription)"
        }
    }
    
    func deleteFabric(_ fabric: Fabric) async {
        do {
            try await fabricRepository.delete(fabric)
            try await userSettingsRepository.addHistory(
                action: .deletedFabric,
                details: fabric.name,
                context: .fabric
            )
            await loadFabrics()
        } catch {
            errorMessage = "Failed to delete fabric: \(error.localizedDescription)"
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
    
    func clearError() {
        errorMessage = nil
    }
}