import XCTest
import SwiftData
@testable import SewSmart

@MainActor
final class FabricStashViewModelTests: XCTestCase {
    var viewModel: FabricStashViewModel!
    var modelContext: ModelContext!
    var container: ModelContainer!
    var sampleFabrics: [Fabric]!
    
    @MainActor
    override func setUp() {
        super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try! ModelContainer(for: Fabric.self, UserSettings.self, configurations: config)
        modelContext = container.mainContext
        viewModel = FabricStashViewModel(modelContext: modelContext)
        setupSampleFabrics()
    }
    
    override func tearDown() {
        viewModel = nil
        modelContext = nil
        container = nil
        sampleFabrics = nil
        super.tearDown()
    }
    
    private func setupSampleFabrics() {
        sampleFabrics = [
            Fabric(name: "Cotton Blue", type: .cotton, color: "Blue", yardage: 2.5),
            Fabric(name: "Silk Red", type: .silk, color: "Red", yardage: 1.0),
            Fabric(name: "Wool Green", type: .wool, color: "Green", yardage: 3.0),
            Fabric(name: "Linen White", type: .linen, color: "White", yardage: 2.0),
            Fabric(name: "Polyester Black", type: .polyester, color: "Black", yardage: 5.0)
        ]
        
        sampleFabrics[0].brand = "Cotton Co"
        sampleFabrics[1].brand = "Silk House"
    }
    
    // MARK: - Initialization Tests
    
    func testInitialState() {
        XCTAssertFalse(viewModel.showingAddFabric)
        XCTAssertNil(viewModel.selectedFabric)
        XCTAssertEqual(viewModel.searchText, "")
        XCTAssertNil(viewModel.selectedType)
        XCTAssertFalse(viewModel.hasActiveFilters)
    }
    
    // MARK: - Fabric Display Tests
    
    func testShowAddFabric() {
        viewModel.showAddFabric()
        XCTAssertTrue(viewModel.showingAddFabric)
    }
    
    func testHideAddFabric() {
        viewModel.showAddFabric()
        viewModel.hideAddFabric()
        XCTAssertFalse(viewModel.showingAddFabric)
    }
    
    func testSelectFabric() {
        let fabric = sampleFabrics[0]
        viewModel.selectFabric(fabric)
        XCTAssertEqual(viewModel.selectedFabric, fabric)
    }
    
    func testDeselectFabric() {
        let fabric = sampleFabrics[0]
        viewModel.selectFabric(fabric)
        viewModel.deselectFabric()
        XCTAssertNil(viewModel.selectedFabric)
    }
    
    // MARK: - Filtering Tests
    
    func testFilteredFabrics_NoFilters() {
        let filtered = viewModel.filteredFabrics(from: sampleFabrics)
        XCTAssertEqual(filtered.count, sampleFabrics.count)
        XCTAssertEqual(filtered, sampleFabrics)
    }
    
    func testFilteredFabrics_SearchByName() {
        viewModel.searchText = "cotton"
        let filtered = viewModel.filteredFabrics(from: sampleFabrics)
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.name, "Cotton Blue")
    }
    
    func testFilteredFabrics_SearchByColor() {
        viewModel.searchText = "blue"
        let filtered = viewModel.filteredFabrics(from: sampleFabrics)
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.color, "Blue")
    }
    
    func testFilteredFabrics_SearchByBrand() {
        viewModel.searchText = "silk house"
        let filtered = viewModel.filteredFabrics(from: sampleFabrics)
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.name, "Silk Red")
    }
    
    func testFilteredFabrics_SearchCaseInsensitive() {
        viewModel.searchText = "COTTON"
        let filtered = viewModel.filteredFabrics(from: sampleFabrics)
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.name, "Cotton Blue")
    }
    
    func testFilteredFabrics_SearchNoResults() {
        viewModel.searchText = "nonexistent"
        let filtered = viewModel.filteredFabrics(from: sampleFabrics)
        XCTAssertTrue(filtered.isEmpty)
    }
    
    func testFilteredFabrics_ByType() {
        viewModel.selectType(.cotton)
        let filtered = viewModel.filteredFabrics(from: sampleFabrics)
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.type, .cotton)
    }
    
    func testFilteredFabrics_SearchAndType() {
        viewModel.searchText = "red"
        viewModel.selectType(.silk)
        let filtered = viewModel.filteredFabrics(from: sampleFabrics)
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.name, "Silk Red")
    }
    
    // MARK: - Type Selection Tests
    
    func testSelectType() {
        viewModel.selectType(.cotton)
        XCTAssertEqual(viewModel.selectedType, .cotton)
    }
    
    func testSelectType_ToggleOff() {
        viewModel.selectType(.cotton)
        XCTAssertEqual(viewModel.selectedType, .cotton)
        viewModel.selectType(.cotton) // Select same type again
        XCTAssertNil(viewModel.selectedType) // Should toggle off
    }
    
    func testSelectType_ChangesType() {
        viewModel.selectType(.cotton)
        XCTAssertEqual(viewModel.selectedType, .cotton)
        viewModel.selectType(.silk)
        XCTAssertEqual(viewModel.selectedType, .silk)
    }
    
    // MARK: - Filter Management Tests
    
    func testHasActiveFilters_NoFilters() {
        XCTAssertFalse(viewModel.hasActiveFilters)
    }
    
    func testHasActiveFilters_WithSearchText() {
        viewModel.searchText = "test"
        XCTAssertTrue(viewModel.hasActiveFilters)
    }
    
    func testHasActiveFilters_WithType() {
        viewModel.selectType(.cotton)
        XCTAssertTrue(viewModel.hasActiveFilters)
    }
    
    func testHasActiveFilters_WithBothFilters() {
        viewModel.searchText = "test"
        viewModel.selectType(.cotton)
        XCTAssertTrue(viewModel.hasActiveFilters)
    }
    
    func testClearFilters() {
        viewModel.searchText = "test"
        viewModel.selectType(.cotton)
        XCTAssertTrue(viewModel.hasActiveFilters)
        
        viewModel.clearFilters()
        
        XCTAssertEqual(viewModel.searchText, "")
        XCTAssertNil(viewModel.selectedType)
        XCTAssertFalse(viewModel.hasActiveFilters)
    }
    
    // MARK: - Fabric Deletion Tests
    
    func testDeleteFabric() {
        let fabric = Fabric(name: "Test Fabric", type: .cotton, color: "Blue", yardage: 1.0)
        modelContext.insert(fabric)
        
        do {
            try modelContext.save()
        } catch {
            XCTFail("Failed to save fabric: \(error)")
        }
        
        viewModel.deleteFabric(fabric)
        
        let descriptor = FetchDescriptor<Fabric>()
        let fabrics = try! modelContext.fetch(descriptor)
        XCTAssertEqual(fabrics.count, 0)
    }
    
    func testDeleteFabrics_AtOffsets() {
        for fabric in sampleFabrics {
            modelContext.insert(fabric)
        }
        
        do {
            try modelContext.save()
        } catch {
            XCTFail("Failed to save fabrics: \(error)")
        }
        
        let offsetsToDelete = IndexSet([0, 2]) // Delete first and third fabrics
        viewModel.deleteFabrics(at: offsetsToDelete, from: sampleFabrics)
        
        let descriptor = FetchDescriptor<Fabric>()
        let remainingFabrics = try! modelContext.fetch(descriptor)
        XCTAssertEqual(remainingFabrics.count, 3) // Should have 3 fabrics left
    }
    
    // MARK: - Type Color Tests
    
    func testColorForType() {
        XCTAssertEqual(viewModel.colorForType(.cotton), DesignSystem.primaryTeal)
        XCTAssertEqual(viewModel.colorForType(.silk), DesignSystem.primaryPurple)
        XCTAssertEqual(viewModel.colorForType(.wool), DesignSystem.primaryOrange)
        XCTAssertEqual(viewModel.colorForType(.linen), DesignSystem.primaryYellow)
        XCTAssertEqual(viewModel.colorForType(.polyester), DesignSystem.primaryPink)
        XCTAssertEqual(viewModel.colorForType(.other), .gray)
    }
    
    // MARK: - Empty State Configuration Tests
    
    func testGetEmptyStateConfiguration() {
        let config = viewModel.getEmptyStateConfiguration()
        XCTAssertEqual(config.emoji, "🧵")
        XCTAssertEqual(config.title, "No Fabrics Yet")
        XCTAssertEqual(config.subtitle, "Build your fabric collection!")
        XCTAssertEqual(config.emojiSize, 64)
    }
    
    func testGetFilteredEmptyStateConfiguration() {
        let config = viewModel.getFilteredEmptyStateConfiguration()
        XCTAssertEqual(config.emoji, "🔍")
        XCTAssertEqual(config.title, "No Matching Fabrics")
        XCTAssertEqual(config.subtitle, "Try adjusting your search or filters")
        XCTAssertEqual(config.emojiSize, 64)
    }
    
    // MARK: - Performance Tests
    
    func testFilteringPerformance() {
        var largeFabricSet: [Fabric] = []
        for i in 0..<1000 {
            let fabric = Fabric(
                name: "Fabric \(i)",
                type: FabricType.allCases[i % FabricType.allCases.count],
                color: "Color \(i % 10)",
                yardage: Double(i % 10 + 1)
            )
            fabric.brand = "Brand \(i % 5)"
            largeFabricSet.append(fabric)
        }
        
        viewModel.searchText = "Fabric 5"
        
        measure {
            _ = viewModel.filteredFabrics(from: largeFabricSet)
        }
    }
    
    func testTypeFilteringPerformance() {
        var largeFabricSet: [Fabric] = []
        for i in 0..<1000 {
            let fabric = Fabric(
                name: "Fabric \(i)",
                type: FabricType.allCases[i % FabricType.allCases.count],
                color: "Color \(i)",
                yardage: Double(i + 1)
            )
            largeFabricSet.append(fabric)
        }
        
        viewModel.selectType(.cotton)
        
        measure {
            _ = viewModel.filteredFabrics(from: largeFabricSet)
        }
    }
}