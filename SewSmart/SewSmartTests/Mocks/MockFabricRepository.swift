import Foundation
@testable import SewSmart

class MockFabricRepository: FabricRepositoryProtocol {
    private var fabrics: [Fabric] = []
    private var totalValue: Double = 0
    private var totalYardage: Double = 0
    
    var shouldThrowError = false
    var shouldFail = false
    var errorToThrow: Error = MockError.testError
    
    // Mock data for different scenarios
    var mockFabrics: [Fabric] = []
    var mockFabricsByType: [Fabric] = []
    var mockSearchResults: [Fabric] = []
    
    // Tracking calls for verification
    var fetchAllCalled = false
    var fetchByIdCalled = false
    var fetchByTypeCalled = false
    var searchCalled = false
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
        if shouldThrowError || shouldFail {
            throw errorToThrow
        }
        return mockFabrics.isEmpty ? fabrics.sorted { $0.createdDate > $1.createdDate } : mockFabrics
    }
    
    func fetch(by id: UUID) async throws -> Fabric? {
        fetchByIdCalled = true
        if shouldThrowError || shouldFail {
            throw errorToThrow
        }
        let allFabrics = mockFabrics.isEmpty ? fabrics : mockFabrics
        return allFabrics.first { $0.id == id }
    }
    
    func fetch(by type: FabricType) async throws -> [Fabric] {
        fetchByTypeCalled = true
        lastTypeFilter = type
        if shouldThrowError || shouldFail {
            throw errorToThrow
        }
        return mockFabricsByType.isEmpty ? fabrics.filter { $0.type == type }.sorted { $0.createdDate > $1.createdDate } : mockFabricsByType
    }
    
    func search(query: String) async throws -> [Fabric] {
        searchCalled = true
        if shouldThrowError || shouldFail {
            throw errorToThrow
        }
        if !mockSearchResults.isEmpty {
            return mockSearchResults
        }
        let searchTerm = query.lowercased()
        return fabrics.filter { 
            $0.name.lowercased().contains(searchTerm) || 
            $0.color.lowercased().contains(searchTerm)
        }
    }
    
    func save(_ fabric: Fabric) async throws {
        saveCalled = true
        lastSavedFabric = fabric
        if shouldThrowError || shouldFail {
            throw errorToThrow
        }
        fabrics.append(fabric)
        updateTotals()
    }
    
    func delete(_ fabric: Fabric) async throws {
        deleteCalled = true
        lastDeletedFabric = fabric
        if shouldThrowError || shouldFail {
            throw errorToThrow
        }
        fabrics.removeAll { $0.id == fabric.id }
        updateTotals()
    }
    
    func update(_ fabric: Fabric) async throws {
        updateCalled = true
        lastUpdatedFabric = fabric
        if shouldThrowError || shouldFail {
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
        mockFabrics.removeAll()
        mockFabricsByType.removeAll()
        mockSearchResults.removeAll()
        totalValue = 0
        totalYardage = 0
        shouldThrowError = false
        shouldFail = false
        
        fetchAllCalled = false
        fetchByIdCalled = false
        fetchByTypeCalled = false
        searchCalled = false
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