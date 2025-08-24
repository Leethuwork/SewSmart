import SwiftUI
import SwiftData

struct HistoryView: View {
    let settingsManager: UserSettingsManager
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: HistoryViewModel
    
    init(settingsManager: UserSettingsManager) {
        self.settingsManager = settingsManager
        self._viewModel = State(initialValue: HistoryViewModel(settingsManager: settingsManager))
    }
    
    var body: some View {
        NavigationStack {
            List {
                if !viewModel.hasHistory {
                    let config = viewModel.getEmptyStateConfiguration()
                    VStack(spacing: 16) {
                        Text(config.emoji)
                            .font(.system(size: config.emojiSize))
                            .foregroundColor(.gray)
                        Text(config.title)
                            .font(.title2)
                            .foregroundColor(.primary)
                        Text(config.subtitle)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 50)
                } else {
                    ForEach(viewModel.sortedDates, id: \.self) { date in
                        Section(header: Text(viewModel.formatDate(date))) {
                            ForEach(viewModel.getHistoryEntries(for: date), id: \.id) { entry in
                                HistoryRowView(entry: entry, viewModel: viewModel)
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
                
                if viewModel.hasHistory {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Clear") {
                            viewModel.showClearConfirmation()
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .confirmationDialog("Clear History", isPresented: Binding(
                get: { viewModel.showingClearConfirmation },
                set: { viewModel.showingClearConfirmation = $0 }
            )) {
                Button("Clear All History", role: .destructive) {
                    viewModel.clearAllHistory()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will permanently delete all your activity history. This action cannot be undone.")
            }
        }
    }
}

struct HistoryRowView: View {
    let entry: UserHistory
    let viewModel: HistoryViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: viewModel.iconForContext(entry.context))
                .font(.title3)
                .foregroundColor(viewModel.colorForContext(entry.context))
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
                        .background(viewModel.colorForContext(entry.context).opacity(0.2))
                        .foregroundColor(viewModel.colorForContext(entry.context))
                        .cornerRadius(4)
                    
                    Spacer()
                    
                    Text(viewModel.formatTime(entry.timestamp))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
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