import Testing
import Foundation
@testable import SewSmart

@MainActor
struct FabricViewModelTests {
    
    private func createMockRepositories() -> (MockFabricRepository, MockUserSettingsRepository) {
        let fabricRepo = MockFabricRepository()
        let settingsRepo = MockUserSettingsRepository()
        return (fabricRepo, settingsRepo)
    }
    
    private func createViewModel(
        fabricRepo: MockFabricRepository = MockFabricRepository(),
        settingsRepo: MockUserSettingsRepository = MockUserSettingsRepository()
    ) -> FabricViewModel {
        return FabricViewModel(
            fabricRepository: fabricRepo,
            userSettingsRepository: settingsRepo
        )
    }

    @Test func testInitialState() async throws {
        let viewModel = createViewModel()
        
        #expect(viewModel.fabrics.isEmpty)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.showingAddFabric == false)
        #expect(viewModel.selectedFabric == nil)
        #expect(viewModel.selectedType == nil)
        #expect(viewModel.totalValue == 0)
        #expect(viewModel.totalYardage == 0)
    }
    
    @Test func testLoadFabricsSuccess() async throws {
        let (fabricRepo, settingsRepo) = createMockRepositories()
        let viewModel = createViewModel(fabricRepo: fabricRepo, settingsRepo: settingsRepo)
        
        let fabric1 = Fabric(name: "Cotton Fabric", type: .cotton, color: "Blue", yardage: 2.5)
        fabric1.cost = 15.99
        let fabric2 = Fabric(name: "Silk Fabric", type: .silk, color: "Red", yardage: 1.0)
        fabric2.cost = 25.99
        
        fabricRepo.addFabric(fabric1)
        fabricRepo.addFabric(fabric2)
        fabricRepo.setTotalValue(41.98)
        fabricRepo.setTotalYardage(3.5)
        
        await viewModel.loadFabrics()
        
        #expect(fabricRepo.fetchAllCalled == true)
        #expect(fabricRepo.getTotalValueCalled == true)
        #expect(fabricRepo.getTotalYardageCalled == true)
        #expect(viewModel.fabrics.count == 2)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.totalValue == 41.98)
        #expect(viewModel.totalYardage == 3.5)
        #expect(viewModel.fabrics.contains { $0.name == "Cotton Fabric" })
        #expect(viewModel.fabrics.contains { $0.name == "Silk Fabric" })
    }
    
    @Test func testLoadFabricsFailure() async throws {
        let (fabricRepo, settingsRepo) = createMockRepositories()
        let viewModel = createViewModel(fabricRepo: fabricRepo, settingsRepo: settingsRepo)
        
        fabricRepo.shouldThrowError = true
        fabricRepo.errorToThrow = MockError.databaseError
        
        await viewModel.loadFabrics()
        
        #expect(fabricRepo.fetchAllCalled == true)
        #expect(viewModel.fabrics.isEmpty)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage?.contains("Database error") == true)
    }
    
    @Test func testCreateFabricSuccess() async throws {
        let (fabricRepo, settingsRepo) = createMockRepositories()
        let viewModel = createViewModel(fabricRepo: fabricRepo, settingsRepo: settingsRepo)
        
        await viewModel.createFabric(
            name: "New Fabric",
            type: .cotton,
            color: "Green",
            yardage: 2.0,
            cost: 20.00,
            content: "100% Cotton",
            brand: "Test Brand"
        )
        
        #expect(fabricRepo.saveCalled == true)
        #expect(settingsRepo.addHistoryCalled == true)
        #expect(fabricRepo.fetchAllCalled == true)
        #expect(fabricRepo.lastSavedFabric?.name == "New Fabric")
        #expect(fabricRepo.lastSavedFabric?.type == .cotton)
        #expect(fabricRepo.lastSavedFabric?.color == "Green")
        #expect(fabricRepo.lastSavedFabric?.yardage == 2.0)
        #expect(fabricRepo.lastSavedFabric?.cost == 20.00)
        #expect(fabricRepo.lastSavedFabric?.content == "100% Cotton")
        #expect(fabricRepo.lastSavedFabric?.brand == "Test Brand")
    }
    
    @Test func testCreateFabricWithEmptyNameShouldNotCreate() async throws {
        let (fabricRepo, settingsRepo) = createMockRepositories()
        let viewModel = createViewModel(fabricRepo: fabricRepo, settingsRepo: settingsRepo)
        
        await viewModel.createFabric(
            name: "",
            type: .cotton,
            yardage: 1.0
        )
        
        #expect(fabricRepo.saveCalled == false)
        #expect(settingsRepo.addHistoryCalled == false)
    }
    
    @Test func testUpdateFabricSuccess() async throws {
        let (fabricRepo, settingsRepo) = createMockRepositories()
        let viewModel = createViewModel(fabricRepo: fabricRepo, settingsRepo: settingsRepo)
        
        let fabric = Fabric(name: "Test Fabric", type: .cotton, color: "Blue", yardage: 1.5)
        fabric.cost = 12.99
        
        await viewModel.updateFabric(fabric)
        
        #expect(fabricRepo.updateCalled == true)
        #expect(fabricRepo.lastUpdatedFabric?.id == fabric.id)
        #expect(fabricRepo.fetchAllCalled == true)
    }
    
    @Test func testDeleteFabricSuccess() async throws {
        let (fabricRepo, settingsRepo) = createMockRepositories()
        let viewModel = createViewModel(fabricRepo: fabricRepo, settingsRepo: settingsRepo)
        
        let fabric = Fabric(name: "Test Fabric", type: .cotton, color: "Blue", yardage: 1.5)
        
        await viewModel.deleteFabric(fabric)
        
        #expect(fabricRepo.deleteCalled == true)
        #expect(settingsRepo.addHistoryCalled == true)
        #expect(fabricRepo.lastDeletedFabric?.id == fabric.id)
        #expect(settingsRepo.lastHistoryEntry?.action == .deletedFabric)
        #expect(settingsRepo.lastHistoryEntry?.details == "Test Fabric")
        #expect(settingsRepo.lastHistoryEntry?.context == .fabric)
    }
    
    @Test func testFilterFabricsByType() async throws {
        let (fabricRepo, settingsRepo) = createMockRepositories()
        let viewModel = createViewModel(fabricRepo: fabricRepo, settingsRepo: settingsRepo)
        
        await viewModel.filterFabrics(by: .silk)
        
        #expect(viewModel.selectedType == .silk)
        #expect(fabricRepo.fetchByTypeCalled == true)
        #expect(fabricRepo.lastTypeFilter == .silk)
    }
    
    @Test func testClearFilters() async throws {
        let (fabricRepo, settingsRepo) = createMockRepositories()
        let viewModel = createViewModel(fabricRepo: fabricRepo, settingsRepo: settingsRepo)
        
        // Set a filter first
        await viewModel.filterFabrics(by: .cotton)
        fabricRepo.reset()
        
        // Clear filters
        await viewModel.clearFilters()
        
        #expect(viewModel.selectedType == nil)
        #expect(fabricRepo.fetchAllCalled == true)
    }
    
    @Test func testGetFabricsByType() async throws {
        let (fabricRepo, settingsRepo) = createMockRepositories()
        let viewModel = createViewModel(fabricRepo: fabricRepo, settingsRepo: settingsRepo)
        
        let fabric1 = Fabric(name: "Cotton 1", type: .cotton, color: "Blue", yardage: 1.0)
        let fabric2 = Fabric(name: "Silk 1", type: .silk, color: "Red", yardage: 0.5)
        let fabric3 = Fabric(name: "Cotton 2", type: .cotton, color: "Green", yardage: 2.0)
        
        fabricRepo.addFabric(fabric1)
        fabricRepo.addFabric(fabric2)
        fabricRepo.addFabric(fabric3)
        
        await viewModel.loadFabrics()
        
        let cottonFabrics = viewModel.getFabricsByType(.cotton)
        let silkFabrics = viewModel.getFabricsByType(.silk)
        
        #expect(cottonFabrics.count == 2)
        #expect(silkFabrics.count == 1)
        #expect(cottonFabrics.contains { $0.name == "Cotton 1" })
        #expect(cottonFabrics.contains { $0.name == "Cotton 2" })
        #expect(silkFabrics.contains { $0.name == "Silk 1" })
    }
    
    @Test func testGetTypeDistribution() async throws {
        let (fabricRepo, settingsRepo) = createMockRepositories()
        let viewModel = createViewModel(fabricRepo: fabricRepo, settingsRepo: settingsRepo)
        
        let fabric1 = Fabric(name: "Cotton 1", type: .cotton, color: "Blue", yardage: 1.0)
        let fabric2 = Fabric(name: "Silk 1", type: .silk, color: "Red", yardage: 0.5)
        let fabric3 = Fabric(name: "Cotton 2", type: .cotton, color: "Green", yardage: 2.0)
        let fabric4 = Fabric(name: "Linen 1", type: .linen, color: "White", yardage: 1.5)
        
        fabricRepo.addFabric(fabric1)
        fabricRepo.addFabric(fabric2)
        fabricRepo.addFabric(fabric3)
        fabricRepo.addFabric(fabric4)
        
        await viewModel.loadFabrics()
        
        let distribution = viewModel.getTypeDistribution()
        
        #expect(distribution[.cotton] == 2)
        #expect(distribution[.silk] == 1)
        #expect(distribution[.linen] == 1)
        #expect(distribution[.wool] == 0)
    }
    
    @Test func testGetTypeValueDistribution() async throws {
        let (fabricRepo, settingsRepo) = createMockRepositories()
        let viewModel = createViewModel(fabricRepo: fabricRepo, settingsRepo: settingsRepo)
        
        let fabric1 = Fabric(name: "Cotton 1", type: .cotton, color: "Blue", yardage: 1.0)
        fabric1.cost = 10.0
        let fabric2 = Fabric(name: "Silk 1", type: .silk, color: "Red", yardage: 0.5)
        fabric2.cost = 25.0
        let fabric3 = Fabric(name: "Cotton 2", type: .cotton, color: "Green", yardage: 2.0)
        fabric3.cost = 15.0
        
        fabricRepo.addFabric(fabric1)
        fabricRepo.addFabric(fabric2)
        fabricRepo.addFabric(fabric3)
        
        await viewModel.loadFabrics()
        
        let valueDistribution = viewModel.getTypeValueDistribution()
        
        #expect(valueDistribution[.cotton] == 25.0) // 10.0 + 15.0
        #expect(valueDistribution[.silk] == 25.0)
        #expect(valueDistribution[.linen] == 0.0)
    }
    
    @Test func testGetAverageCostPerYard() async throws {
        let (fabricRepo, settingsRepo) = createMockRepositories()
        let viewModel = createViewModel(fabricRepo: fabricRepo, settingsRepo: settingsRepo)
        
        let fabric1 = Fabric(name: "Fabric 1", type: .cotton, color: "Blue", yardage: 2.0)
        fabric1.cost = 20.0 // $10 per yard
        let fabric2 = Fabric(name: "Fabric 2", type: .silk, color: "Red", yardage: 1.0)
        fabric2.cost = 30.0 // $30 per yard
        
        fabricRepo.addFabric(fabric1)
        fabricRepo.addFabric(fabric2)
        
        await viewModel.loadFabrics()
        
        let averageCost = viewModel.getAverageCostPerYard()
        let expectedAverage = 50.0 / 3.0 // Total cost / total yards
        
        #expect(abs(averageCost - expectedAverage) < 0.001)
    }
    
    @Test func testGetAverageCostPerYardWithZeroYardage() async throws {
        let viewModel = createViewModel()
        
        let averageCost = viewModel.getAverageCostPerYard()
        
        #expect(averageCost == 0.0)
    }
    
    @Test func testClearError() async throws {
        let (fabricRepo, settingsRepo) = createMockRepositories()
        let viewModel = createViewModel(fabricRepo: fabricRepo, settingsRepo: settingsRepo)
        
        // Set an error
        fabricRepo.shouldThrowError = true
        await viewModel.loadFabrics()
        #expect(viewModel.errorMessage != nil)
        
        // Clear the error
        viewModel.clearError()
        #expect(viewModel.errorMessage == nil)
    }
}