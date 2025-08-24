import SwiftUI
import SwiftData

struct iPadSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var projects: [Project]
    @Query private var patterns: [Pattern]
    @Query private var fabrics: [Fabric]
    @Query private var measurementProfiles: [MeasurementProfile]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Statistics Dashboard
                    StatisticsDashboard(
                        projects: projects,
                        patterns: patterns,
                        fabrics: fabrics,
                        measurementProfiles: measurementProfiles
                    )
                    
                    // Quick Actions
                    QuickActionsSection()
                    
                    // Data Management
                    DataManagementSection()
                    
                    // App Information
                    AppInformationSection()
                }
                .padding()
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct StatisticsDashboard: View {
    let projects: [Project]
    let patterns: [Pattern]
    let fabrics: [Fabric]
    let measurementProfiles: [MeasurementProfile]
    
    var activeProjects: Int {
        projects.filter { $0.status == .inProgress }.count
    }
    
    var completedProjects: Int {
        projects.filter { $0.status == .completed }.count
    }
    
    var totalFabricValue: Double {
        fabrics.reduce(0) { $0 + $1.cost }
    }
    
    var totalFabricYardage: Double {
        fabrics.reduce(0) { $0 + $1.yardage }
    }
    
    var completionRate: Int {
        let total = max(projects.count, 1)
        let completed = completedProjects
        return Int(Double(completed) / Double(total) * 100)
    }
    
    var totalProjectsText: String {
        "\(projects.count)"
    }
    
    var activeProjectsText: String {
        "\(activeProjects) active"
    }
    
    var completedProjectsText: String {
        "\(completedProjects)"
    }
    
    var completionRateText: String {
        "\(completionRate)% completion rate"
    }
    
    var patternsCountText: String {
        "\(patterns.count)"
    }
    
    var fabricsCountText: String {
        "\(fabrics.count)"
    }
    
    var yardageText: String {
        String(format: "%.1f yards", totalFabricYardage)
    }
    
    var stashValueText: String {
        totalFabricValue.formatted(.currency(code: "USD"))
    }
    
    var measurementProfilesText: String {
        "\(measurementProfiles.count)"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Statistics")
                .font(.title2)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                // Projects Stats
                StatCard(
                    title: "Total Projects",
                    value: totalProjectsText,
                    subtitle: activeProjectsText,
                    icon: "folder",
                    color: .blue
                )
                
                StatCard(
                    title: "Completed",
                    value: completedProjectsText,
                    subtitle: completionRateText,
                    icon: "checkmark.circle",
                    color: .green
                )
                
                StatCard(
                    title: "Pattern Library",
                    value: patternsCountText,
                    subtitle: "patterns stored",
                    icon: "doc.text",
                    color: .orange
                )
                
                StatCard(
                    title: "Fabric Stash",
                    value: fabricsCountText,
                    subtitle: yardageText,
                    icon: "square.stack.3d.down.forward",
                    color: .purple
                )
                
                StatCard(
                    title: "Stash Value",
                    value: stashValueText,
                    subtitle: "total investment",
                    icon: "dollarsign.circle",
                    color: .mint
                )
                
                StatCard(
                    title: "Measurements",
                    value: measurementProfilesText,
                    subtitle: "profiles saved",
                    icon: "ruler",
                    color: .cyan
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

struct QuickActionsSection: View {
    @State private var showingExportOptions = false
    @State private var showingImportOptions = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.title2)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                ActionButton(
                    title: "Export Data",
                    subtitle: "Backup your data",
                    icon: "square.and.arrow.up",
                    color: .blue
                ) {
                    showingExportOptions = true
                }
                
                ActionButton(
                    title: "Import Data",
                    subtitle: "Restore from backup",
                    icon: "square.and.arrow.down",
                    color: .green
                ) {
                    showingImportOptions = true
                }
                
                ActionButton(
                    title: "Clear Cache",
                    subtitle: "Free up storage",
                    icon: "trash",
                    color: .orange
                ) {
                    // Clear cache action
                }
                
                ActionButton(
                    title: "Share App",
                    subtitle: "Tell friends about SewSmart",
                    icon: "square.and.arrow.up",
                    color: .pink
                ) {
                    // Share app action
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .sheet(isPresented: $showingExportOptions) {
            ExportOptionsView()
        }
        .sheet(isPresented: $showingImportOptions) {
            ImportOptionsView()
        }
    }
}

struct ActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DataManagementSection: View {
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Data Management")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                DataManagementRow(
                    title: "Sync with iCloud",
                    subtitle: "Keep data synced across devices",
                    icon: "icloud",
                    color: .blue,
                    action: {}
                )
                
                DataManagementRow(
                    title: "Automatic Backups",
                    subtitle: "Daily backups to iCloud",
                    icon: "clock.arrow.circlepath",
                    color: .green,
                    action: {}
                )
                
                DataManagementRow(
                    title: "Data Usage",
                    subtitle: "View storage and usage statistics",
                    icon: "chart.bar",
                    color: .orange,
                    action: {}
                )
                
                Divider()
                
                DataManagementRow(
                    title: "Reset All Data",
                    subtitle: "Permanently delete all data",
                    icon: "exclamationmark.triangle",
                    color: .red,
                    action: { showingDeleteConfirmation = true }
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .alert("Reset All Data", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                // Reset all data
            }
        } message: {
            Text("This action cannot be undone. All your projects, patterns, fabrics, and measurements will be permanently deleted.")
        }
    }
}

struct DataManagementRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AppInformationSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("About SewSmart")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Image(systemName: "swift")
                        .foregroundColor(.orange)
                        .frame(width: 24)
                    Text("Built with SwiftUI & SwiftData")
                }
                
                HStack {
                    Image(systemName: "heart")
                        .foregroundColor(.red)
                        .frame(width: 24)
                    Text("Made for sewists, by sewists")
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("SewSmart")
                        .font(.headline)
                    
                    Text("Your complete sewing companion for managing projects, patterns, measurements, and fabric inventory. Designed to help you organize your creative journey and make sewing more enjoyable.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct ExportOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Export Options")
                    .font(.title)
                    .fontWeight(.semibold)
                
                Text("Choose what data to export")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Export options would go here
                Text("Export functionality would be implemented here")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ImportOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Import Options")
                    .font(.title)
                    .fontWeight(.semibold)
                
                Text("Choose data to import")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Import options would go here
                Text("Import functionality would be implemented here")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    iPadSettingsView()
        .modelContainer(for: Project.self, inMemory: true)
}