import SwiftUI
import Foundation

@Observable
final class HistoryViewModel {
    var showingClearConfirmation: Bool = false
    
    private let settingsManager: UserSettingsManager
    
    var groupedHistory: [Date: [UserHistory]] {
        let history = settingsManager.getRecentHistory(limit: 100)
        let calendar = Calendar.current
        
        return Dictionary(grouping: history) { entry in
            calendar.startOfDay(for: entry.timestamp)
        }
    }
    
    var hasHistory: Bool {
        !groupedHistory.isEmpty
    }
    
    var sortedDates: [Date] {
        groupedHistory.keys.sorted(by: >)
    }
    
    init(settingsManager: UserSettingsManager) {
        self.settingsManager = settingsManager
    }
    
    func getHistoryEntries(for date: Date) -> [UserHistory] {
        groupedHistory[date]?.sorted { $0.timestamp > $1.timestamp } ?? []
    }
    
    func showClearConfirmation() {
        showingClearConfirmation = true
    }
    
    func clearAllHistory() {
        settingsManager.clearHistory()
        showingClearConfirmation = false
    }
    
    func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
    
    func iconForContext(_ context: HistoryContext) -> String {
        switch context {
        case .settings: return "gear"
        case .projects: return "folder"
        case .fabric: return "square.stack.3d.down.forward"
        case .fabrics: return "square.stack.3d.down.forward"
        case .patterns: return "doc.text"
        case .measurements: return "ruler"
        }
    }
    
    func colorForContext(_ context: HistoryContext) -> Color {
        switch context {
        case .settings: return .blue
        case .projects: return .green
        case .fabric: return .purple
        case .fabrics: return .purple
        case .patterns: return .orange
        case .measurements: return .red
        }
    }
    
    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    func getEmptyStateConfiguration() -> EmptyStateConfiguration {
        EmptyStateConfiguration(
            emoji: "⏰",
            title: "No History Yet",
            subtitle: "Your activity will appear here",
            emojiSize: 64
        )
    }
}

