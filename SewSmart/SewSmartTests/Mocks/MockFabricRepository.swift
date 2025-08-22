import Foundation
@testable import SewSmart

class MockFabricRepository: FabricRepositoryProtocol {
    private var fabrics: [Fabric] = []
    private var totalValue: Double = 0
    private var totalYardage: Double = 0
    
    var shouldThrowError = false
    var errorToThrow: Error = MockError.testError
    
    // Tracking calls for verification
    var fetchAllCalled = false
    var fetchByIdCalled = false
    var fetchByTypeCalled = false
    var saveCalled = false
    var deleteCalled = false
    var updateCalled = false
    var getTotalValueCalled = false
    var getTotalYardageCalled = false
    
    var lastSavedFabric: Fabric?
    var lastDeletedFabric: Fabric?
    var lastUpdatedFabric: Fabric?
    var lastTypeFilter: FabricType?
    
    func fetchAll() async throws -> [Fabric] {
        fetchAllCalled = true
        if shouldThrowError {
            throw errorToThrow
        }
        return fabrics.sorted { $0.createdDate > $1.createdDate }
    }
    
    func fetch(by id: UUID) async throws -> Fabric? {
        fetchByIdCalled = true
        if shouldThrowError {
            throw errorToThrow
        }
        return fabrics.first { $0.id == id }
    }
    
    func fetch(by type: FabricType) async throws -> [Fabric] {
        fetchByTypeCalled = true
        lastTypeFilter = type
        if shouldThrowError {
            throw errorToThrow
        }
        return fabrics.filter { $0.type == type }.sorted { $0.createdDate > $1.createdDate }
    }
    
    func save(_ fabric: Fabric) async throws {
        saveCalled = true
        lastSavedFabric = fabric
        if shouldThrowError {
            throw errorToThrow
        }
        fabrics.append(fabric)
        updateTotals()
    }
    
    func delete(_ fabric: Fabric) async throws {
        deleteCalled = true
        lastDeletedFabric = fabric
        if shouldThrowError {
            throw errorToThrow
        }
        fabrics.removeAll { $0.id == fabric.id }
        updateTotals()
    }
    
    func update(_ fabric: Fabric) async throws {
        updateCalled = true
        lastUpdatedFabric = fabric
        if shouldThrowError {
            throw errorToThrow
        }
        updateTotals()
    }
    
    func getTotalValue() async throws -> Double {
        getTotalValueCalled = true
        if shouldThrowError {
            throw errorToThrow
        }
        return totalValue
    }
    
    func getTotalYardage() async throws -> Double {
        getTotalYardageCalled = true
        if shouldThrowError {
            throw errorToThrow
        }
        return totalYardage
    }
    
    // Test helpers
    func addFabric(_ fabric: Fabric) {
        fabrics.append(fabric)
        updateTotals()
    }
    
    func removeAll() {
        fabrics.removeAll()
        updateTotals()
    }
    
    func setTotalValue(_ value: Double) {
        totalValue = value
    }
    
    func setTotalYardage(_ yardage: Double) {
        totalYardage = yardage
    }
    
    private func updateTotals() {
        totalValue = fabrics.reduce(0) { $0 + $1.cost }
        totalYardage = fabrics.reduce(0) { $0 + $1.yardage }
    }
    
    func reset() {
        fabrics.removeAll()
        totalValue = 0
        totalYardage = 0
        shouldThrowError = false
        
        fetchAllCalled = false
        fetchByIdCalled = false
        fetchByTypeCalled = false
        saveCalled = false
        deleteCalled = false
        updateCalled = false
        getTotalValueCalled = false
        getTotalYardageCalled = false
        
        lastSavedFabric = nil
        lastDeletedFabric = nil
        lastUpdatedFabric = nil
        lastTypeFilter = nil
    }
}