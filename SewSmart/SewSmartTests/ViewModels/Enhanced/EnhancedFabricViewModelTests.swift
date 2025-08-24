import XCTest
import SwiftData
@testable import SewSmart

@MainActor
final class EnhancedFabricViewModelTests: XCTestCase {
    var viewModel: FabricViewModel!
    var mockRepository: MockFabricRepository!
    var modelContext: ModelContext!
    var container: ModelContainer!
    
    @MainActor
    override func setUp() {
        super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try! ModelContainer(for: Fabric.self, configurations: config)
        modelContext = container.mainContext
        
        mockRepository = MockFabricRepository()
        viewModel = FabricViewModel(repository: mockRepository)
    }
    
    override func tearDown() {
        viewModel = nil
        mockRepository = nil
        modelContext = nil
        container = nil
        super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func testInitialState() {
        XCTAssertEqual(viewModel.fabricsState, .idle)
        XCTAssertEqual(viewModel.createFabricState, .idle)
        XCTAssertEqual(viewModel.updateFabricState, .idle)
        XCTAssertEqual(viewModel.deleteFabricState, .idle)
        XCTAssertFalse(viewModel.showingAddFabric)
        XCTAssertNil(viewModel.selectedFabric)
        XCTAssertEqual(viewModel.searchText, "")
        XCTAssertNil(viewModel.selectedType)
    }
    
    func testComputedProperties() {
        // Test empty state
        XCTAssertTrue(viewModel.fabrics.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        
        // Test with loaded data
        let testFabrics = [
            Fabric(name: "Cotton", type: .cotton, color: "White", quantity: 5.0, unit: .yards, costPerUnit: 10.0),
            Fabric(name: "Silk", type: .silk, color: "Blue", quantity: 3.0, unit: .meters, costPerUnit: 25.0)
        ]
        viewModel.fabricsState = .loaded(testFabrics)
        
        XCTAssertEqual(viewModel.fabrics.count, 2)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    // MARK: - Load Fabrics Tests
    
    func testLoadFabricsSuccess() async {
        let testFabrics = [
            Fabric(name: "Test Fabric", type: .cotton, color: "Red", quantity: 2.0, unit: .yards, costPerUnit: 15.0)
        ]
        mockRepository.mockFabrics = testFabrics
        
        await viewModel.loadFabrics()
        
        XCTAssertTrue(mockRepository.fetchAllCalled)
        XCTAssertEqual(viewModel.fabricsState.data?.count, 1)
        XCTAssertEqual(viewModel.fabrics.first?.name, "Test Fabric")
    }
    
    func testLoadFabricsWithType() async {
        let testFabrics = [
            Fabric(name: "Cotton Fabric", type: .cotton, color: "White", quantity: 3.0, unit: .yards, costPerUnit: 12.0)
        ]
        mockRepository.mockFabricsByType = testFabrics
        viewModel.selectedType = .cotton
        
        await viewModel.loadFabrics()
        
        XCTAssertTrue(mockRepository.fetchByTypeCalled)
        XCTAssertEqual(viewModel.fabrics.count, 1)
    }
    
    func testLoadFabricsWithSearch() async {
        let testFabrics = [
            Fabric(name: "Searched Fabric", type: .cotton, color: "Blue", quantity: 1.0, unit: .meters, costPerUnit: 20.0)
        ]
        mockRepository.mockSearchResults = testFabrics
        viewModel.searchText = "Searched"
        
        await viewModel.loadFabrics()
        
        XCTAssertTrue(mockRepository.searchCalled)
        XCTAssertEqual(viewModel.fabrics.count, 1)
    }
    
    func testLoadFabricsFailure() async {
        mockRepository.shouldFail = true
        
        await viewModel.loadFabrics()
        
        XCTAssertTrue(viewModel.fabricsState.isFailed)
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    // MARK: - Create Fabric Tests
    
    func testCreateFabricSuccess() async {
        await viewModel.createFabric(
            name: "New Fabric",
            type: .cotton,
            color: "Green",
            quantity: 4.0,
            unit: .yards,
            costPerUnit: 18.0
        )
        
        XCTAssertTrue(mockRepository.saveCalled)
        XCTAssertTrue(viewModel.createFabricState.isSuccess)
    }
    
    func testCreateFabricWithEmptyName() async {
        await viewModel.createFabric(
            name: "",
            type: .cotton,
            color: "Green",
            quantity: 4.0,
            unit: .yards,
            costPerUnit: 18.0
        )
        
        XCTAssertFalse(mockRepository.saveCalled)
        XCTAssertTrue(viewModel.createFabricState.isFailed)
    }
    
    func testCreateFabricWithInvalidQuantity() async {
        await viewModel.createFabric(
            name: "Test Fabric",
            type: .cotton,
            color: "Green",
            quantity: -1.0,
            unit: .yards,
            costPerUnit: 18.0
        )
        
        XCTAssertFalse(mockRepository.saveCalled)
        XCTAssertTrue(viewModel.createFabricState.isFailed)
    }
    
    func testCreateFabricFailure() async {
        mockRepository.shouldFail = true
        
        await viewModel.createFabric(
            name: "Test Fabric",
            type: .cotton,
            color: "Green",
            quantity: 4.0,
            unit: .yards,
            costPerUnit: 18.0
        )
        
        XCTAssertTrue(viewModel.createFabricState.isFailed)
    }
    
    // MARK: - Update Fabric Tests
    
    func testUpdateFabricSuccess() async {
        let fabric = Fabric(name: "Test Fabric", type: .cotton, color: "White", quantity: 2.0, unit: .yards, costPerUnit: 10.0)
        
        await viewModel.updateFabric(fabric)
        
        XCTAssertTrue(mockRepository.updateCalled)
        XCTAssertTrue(viewModel.updateFabricState.isSuccess)
    }
    
    func testUpdateFabricFailure() async {
        mockRepository.shouldFail = true
        let fabric = Fabric(name: "Test Fabric", type: .cotton, color: "White", quantity: 2.0, unit: .yards, costPerUnit: 10.0)
        
        await viewModel.updateFabric(fabric)
        
        XCTAssertTrue(viewModel.updateFabricState.isFailed)
    }
    
    // MARK: - Delete Fabric Tests
    
    func testDeleteFabricSuccess() async {
        let fabric = Fabric(name: "Test Fabric", type: .cotton, color: "White", quantity: 2.0, unit: .yards, costPerUnit: 10.0)
        
        await viewModel.deleteFabric(fabric)
        
        XCTAssertTrue(mockRepository.deleteCalled)
        XCTAssertTrue(viewModel.deleteFabricState.isSuccess)
    }
    
    // MARK: - State Management Tests
    
    func testClearStates() {
        viewModel.createFabricState = .failed(.dataCorruption)
        viewModel.updateFabricState = .failed(.dataCorruption)
        viewModel.deleteFabricState = .failed(.dataCorruption)
        viewModel.fabricsState = .failed(.dataCorruption)
        
        viewModel.clearCreateFabricState()
        viewModel.clearUpdateFabricState()
        viewModel.clearDeleteFabricState()
        viewModel.clearError()
        
        XCTAssertEqual(viewModel.createFabricState, .idle)
        XCTAssertEqual(viewModel.updateFabricState, .idle)
        XCTAssertEqual(viewModel.deleteFabricState, .idle)
        XCTAssertEqual(viewModel.fabricsState, .idle)
    }
    
    func testSetSelectedType() {
        XCTAssertNil(viewModel.selectedType)
        
        viewModel.setSelectedType(.cotton)
        
        XCTAssertEqual(viewModel.selectedType, .cotton)
    }
    
    func testUpdateSearchText() {
        XCTAssertEqual(viewModel.searchText, "")
        
        viewModel.updateSearchText("test search")
        
        XCTAssertEqual(viewModel.searchText, "test search")
    }
    
    func testClearFilters() {
        viewModel.selectedType = .cotton
        viewModel.searchText = "test"
        
        viewModel.clearFilters()
        
        XCTAssertNil(viewModel.selectedType)
        XCTAssertEqual(viewModel.searchText, "")
    }
    
    // MARK: - Business Logic Tests
    
    func testGetFabricsByType() {
        let fabrics = [
            Fabric(name: "Cotton Fabric", type: .cotton, color: "White", quantity: 2.0, unit: .yards, costPerUnit: 10.0),
            Fabric(name: "Silk Fabric", type: .silk, color: "Blue", quantity: 3.0, unit: .meters, costPerUnit: 25.0),
            Fabric(name: "Another Cotton", type: .cotton, color: "Red", quantity: 1.0, unit: .yards, costPerUnit: 12.0)
        ]
        viewModel.fabricsState = .loaded(fabrics)
        
        let cottonFabrics = viewModel.getFabricsByType(.cotton)
        let silkFabrics = viewModel.getFabricsByType(.silk)
        
        XCTAssertEqual(cottonFabrics.count, 2)
        XCTAssertEqual(silkFabrics.count, 1)
        XCTAssertEqual(cottonFabrics.first?.name, "Cotton Fabric")
    }
    
    func testGetTotalValue() {
        let fabrics = [
            Fabric(name: "Fabric 1", type: .cotton, color: "White", quantity: 2.0, unit: .yards, costPerUnit: 10.0),
            Fabric(name: "Fabric 2", type: .silk, color: "Blue", quantity: 1.0, unit: .meters, costPerUnit: 30.0)
        ]
        viewModel.fabricsState = .loaded(fabrics)
        
        let totalValue = viewModel.getTotalValue()
        
        XCTAssertEqual(totalValue, 50.0, accuracy: 0.01) // (2*10) + (1*30) = 50
    }
    
    func testGetTotalQuantityInYards() {
        let fabrics = [
            Fabric(name: "Fabric 1", type: .cotton, color: "White", quantity: 2.0, unit: .yards, costPerUnit: 10.0),
            Fabric(name: "Fabric 2", type: .silk, color: "Blue", quantity: 1.0, unit: .meters, costPerUnit: 30.0)
        ]
        viewModel.fabricsState = .loaded(fabrics)
        
        let totalYards = viewModel.getTotalQuantityInYards()
        
        // 2 yards + 1 meter (≈1.094 yards) ≈ 3.094 yards
        XCTAssertEqual(totalYards, 3.094, accuracy: 0.1)
    }
    
    func testGetLowStockFabrics() {
        let fabrics = [
            Fabric(name: "Low Stock", type: .cotton, color: "White", quantity: 0.5, unit: .yards, costPerUnit: 10.0),
            Fabric(name: "Good Stock", type: .silk, color: "Blue", quantity: 5.0, unit: .meters, costPerUnit: 30.0)
        ]
        viewModel.fabricsState = .loaded(fabrics)
        
        let lowStockFabrics = viewModel.getLowStockFabrics(threshold: 1.0)
        
        XCTAssertEqual(lowStockFabrics.count, 1)
        XCTAssertEqual(lowStockFabrics.first?.name, "Low Stock")
    }
}