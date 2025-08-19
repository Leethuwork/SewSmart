import SwiftUI
import SwiftData

struct HistoryView: View {
    let settingsManager: UserSettingsManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingClearConfirmation = false
    
    var groupedHistory: [Date: [UserHistory]] {
        let history = settingsManager.getRecentHistory(limit: 100)
        let calendar = Calendar.current
        
        return Dictionary(grouping: history) { entry in
            calendar.startOfDay(for: entry.timestamp)
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if groupedHistory.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 64))
                            .foregroundColor(.gray)
                        Text("No History Yet")
                            .font(.title2)
                            .foregroundColor(.primary)
                        Text("Your activity will appear here")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 50)
                } else {
                    ForEach(groupedHistory.keys.sorted(by: >), id: \.self) { date in
                        Section(header: Text(formatDate(date))) {
                            ForEach(groupedHistory[date]?.sorted { $0.timestamp > $1.timestamp } ?? [], id: \.id) { entry in
                                HistoryRowView(entry: entry)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Activity History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                if !groupedHistory.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Clear") {
                            showingClearConfirmation = true
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .confirmationDialog("Clear History", isPresented: $showingClearConfirmation) {
                Button("Clear All History", role: .destructive) {
                    settingsManager.clearHistory()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will permanently delete all your activity history. This action cannot be undone.")
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
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
}

struct HistoryRowView: View {
    let entry: UserHistory
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon based on context
            Image(systemName: iconForContext(entry.context))
                .font(.title3)
                .foregroundColor(colorForContext(entry.context))
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.action.rawValue)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(entry.details)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Text(entry.context.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(colorForContext(entry.context).opacity(0.2))
                        .foregroundColor(colorForContext(entry.context))
                        .cornerRadius(4)
                    
                    Spacer()
                    
                    Text(formatTime(entry.timestamp))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private func iconForContext(_ context: HistoryContext) -> String {
        switch context {
        case .settings: return "gear"
        case .projects: return "folder"
        case .fabrics: return "square.stack.3d.down.forward"
        case .patterns: return "doc.text"
        case .measurements: return "ruler"
        }
    }
    
    private func colorForContext(_ context: HistoryContext) -> Color {
        switch context {
        case .settings: return .blue
        case .projects: return .green
        case .fabrics: return .purple
        case .patterns: return .orange
        case .measurements: return .red
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: UserSettings.self, configurations: config)
    let context = container.mainContext
    
    let manager = UserSettingsManager(modelContext: context)
    
    // Add some sample history
    manager.addHistory(action: .changedMeasurementUnit, details: "From inches to centimeters", context: .settings)
    manager.addHistory(action: .addedFabric, details: "Cotton fabric - Blue", context: .fabrics)
    manager.addHistory(action: .createdProject, details: "Summer Dress Project", context: .projects)
    
    return HistoryView(settingsManager: manager)
}