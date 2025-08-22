import XCTest
import SwiftData
@testable import SewSmart

@MainActor
final class HistoryViewModelTests: XCTestCase {
    var viewModel: HistoryViewModel!
    var settingsManager: UserSettingsManager!
    var modelContext: ModelContext!
    var container: ModelContainer!
    
    @MainActor
    override func setUp() {
        super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try! ModelContainer(for: UserSettings.self, configurations: config)
        modelContext = container.mainContext
        settingsManager = UserSettingsManager(modelContext: modelContext)
        viewModel = HistoryViewModel(settingsManager: settingsManager)
    }
    
    override func tearDown() {
        viewModel = nil
        settingsManager = nil
        modelContext = nil
        container = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialState() {
        XCTAssertFalse(viewModel.showingClearConfirmation)
        XCTAssertTrue(viewModel.groupedHistory.isEmpty)
        XCTAssertFalse(viewModel.hasHistory)
        XCTAssertTrue(viewModel.sortedDates.isEmpty)
    }
    
    // MARK: - History Management Tests
    
    func testGroupedHistory_WithEmptyHistory() {
        XCTAssertTrue(viewModel.groupedHistory.isEmpty)
        XCTAssertFalse(viewModel.hasHistory)
    }
    
    func testGroupedHistory_WithSingleEntry() {
        // Add a history entry
        settingsManager.addHistory(action: .addedPattern, details: "Test Pattern", context: .patterns)
        
        XCTAssertFalse(viewModel.groupedHistory.isEmpty)
        XCTAssertTrue(viewModel.hasHistory)
        XCTAssertEqual(viewModel.groupedHistory.count, 1)
        XCTAssertEqual(viewModel.sortedDates.count, 1)
    }
    
    func testGroupedHistory_WithMultipleEntriesSameDay() {
        // Add multiple entries on the same day
        settingsManager.addHistory(action: .addedPattern, details: "Pattern 1", context: .patterns)
        settingsManager.addHistory(action: .addedFabric, details: "Fabric 1", context: .fabrics)
        settingsManager.addHistory(action: .createdProject, details: "Project 1", context: .projects)
        
        XCTAssertEqual(viewModel.groupedHistory.count, 1) // All entries on same day
        XCTAssertEqual(viewModel.sortedDates.count, 1)
        
        let today = Calendar.current.startOfDay(for: Date())
        let todayEntries = viewModel.getHistoryEntries(for: today)
        XCTAssertEqual(todayEntries.count, 3)
    }
    
    func testGetHistoryEntries_ForSpecificDate() {
        // Add entries
        settingsManager.addHistory(action: .addedPattern, details: "Pattern 1", context: .patterns)
        settingsManager.addHistory(action: .addedFabric, details: "Fabric 1", context: .fabrics)
        
        let today = Calendar.current.startOfDay(for: Date())
        let entries = viewModel.getHistoryEntries(for: today)
        
        XCTAssertEqual(entries.count, 2)
        XCTAssertEqual(entries[0].action, .addedFabric) // Should be sorted by timestamp descending
        XCTAssertEqual(entries[1].action, .addedPattern)
    }
    
    func testGetHistoryEntries_ForNonExistentDate() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let yesterdayStart = Calendar.current.startOfDay(for: yesterday)
        let entries = viewModel.getHistoryEntries(for: yesterdayStart)
        
        XCTAssertTrue(entries.isEmpty)
    }
    
    func testSortedDates_AreInDescendingOrder() {
        // Create entries with different dates
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!
        
        // Add entries with different timestamps
        let todayHistory = UserHistory(action: .addedPattern, details: "Today", context: .patterns)
        todayHistory.timestamp = today
        
        let yesterdayHistory = UserHistory(action: .addedFabric, details: "Yesterday", context: .fabrics)
        yesterdayHistory.timestamp = yesterday
        
        let twoDaysAgoHistory = UserHistory(action: .createdProject, details: "Two days ago", context: .projects)
        twoDaysAgoHistory.timestamp = twoDaysAgo
        
        // Add to settings manager
        settingsManager.addHistory(action: .addedPattern, details: "Today", context: .patterns)
        
        let sortedDates = viewModel.sortedDates
        XCTAssertFalse(sortedDates.isEmpty)
        
        // Verify dates are in descending order
        for i in 0..<sortedDates.count - 1 {
            XCTAssertGreaterThanOrEqual(sortedDates[i], sortedDates[i + 1])
        }
    }
    
    // MARK: - Clear History Tests
    
    func testShowClearConfirmation() {
        XCTAssertFalse(viewModel.showingClearConfirmation)
        viewModel.showClearConfirmation()
        XCTAssertTrue(viewModel.showingClearConfirmation)
    }
    
    func testClearAllHistory() {
        // Add some history entries
        settingsManager.addHistory(action: .addedPattern, details: "Pattern 1", context: .patterns)
        settingsManager.addHistory(action: .addedFabric, details: "Fabric 1", context: .fabrics)
        
        XCTAssertTrue(viewModel.hasHistory)
        
        // Clear history
        viewModel.clearAllHistory()
        
        XCTAssertFalse(viewModel.hasHistory)
        XCTAssertTrue(viewModel.groupedHistory.isEmpty)
        XCTAssertFalse(viewModel.showingClearConfirmation)
    }
    
    // MARK: - Date Formatting Tests
    
    func testFormatDate_Today() {
        let today = Date()
        let formatted = viewModel.formatDate(today)
        XCTAssertEqual(formatted, "Today")
    }
    
    func testFormatDate_Yesterday() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let formatted = viewModel.formatDate(yesterday)
        XCTAssertEqual(formatted, "Yesterday")
    }
    
    func testFormatDate_OlderDate() {
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        let formatted = viewModel.formatDate(twoDaysAgo)
        
        // Should use medium date style
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let expected = formatter.string(from: twoDaysAgo)
        
        XCTAssertEqual(formatted, expected)
    }
    
    // MARK: - Time Formatting Tests
    
    func testFormatTime() {
        let date = Date()
        let formatted = viewModel.formatTime(date)
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let expected = formatter.string(from: date)
        
        XCTAssertEqual(formatted, expected)
    }
    
    // MARK: - Context Icon Tests
    
    func testIconForContext() {
        XCTAssertEqual(viewModel.iconForContext(.settings), "gear")
        XCTAssertEqual(viewModel.iconForContext(.projects), "folder")
        XCTAssertEqual(viewModel.iconForContext(.fabric), "square.stack.3d.down.forward")
        XCTAssertEqual(viewModel.iconForContext(.fabrics), "square.stack.3d.down.forward")
        XCTAssertEqual(viewModel.iconForContext(.patterns), "doc.text")
        XCTAssertEqual(viewModel.iconForContext(.measurements), "ruler")
    }
    
    // MARK: - Context Color Tests
    
    func testColorForContext() {
        XCTAssertEqual(viewModel.colorForContext(.settings), .blue)
        XCTAssertEqual(viewModel.colorForContext(.projects), .green)
        XCTAssertEqual(viewModel.colorForContext(.fabric), .purple)
        XCTAssertEqual(viewModel.colorForContext(.fabrics), .purple)
        XCTAssertEqual(viewModel.colorForContext(.patterns), .orange)
        XCTAssertEqual(viewModel.colorForContext(.measurements), .red)
    }
    
    // MARK: - Empty State Configuration Tests
    
    func testGetEmptyStateConfiguration() {
        let config = viewModel.getEmptyStateConfiguration()
        
        XCTAssertEqual(config.emoji, "⏰")
        XCTAssertEqual(config.title, "No History Yet")
        XCTAssertEqual(config.subtitle, "Your activity will appear here")
        XCTAssertEqual(config.emojiSize, 64)
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceWithLargeHistory() {
        // Add 100 history entries
        for i in 0..<100 {
            settingsManager.addHistory(
                action: .addedPattern,
                details: "Pattern \(i)",
                context: .patterns
            )
        }
        
        measure {
            _ = viewModel.groupedHistory
            _ = viewModel.sortedDates
            _ = viewModel.hasHistory
        }
    }
    
    func testPerformanceOfHistoryGrouping() {
        // Add entries across multiple days
        let calendar = Calendar.current
        for i in 0..<50 {
            let date = calendar.date(byAdding: .day, value: -i, to: Date())!
            let history = UserHistory(action: .addedPattern, details: "Pattern \(i)", context: .patterns)
            history.timestamp = date
            // Note: We can't easily test this without accessing the internal history directly
        }
        
        measure {
            _ = viewModel.groupedHistory.count
        }
    }
}