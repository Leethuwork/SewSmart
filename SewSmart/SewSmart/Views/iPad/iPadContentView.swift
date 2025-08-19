import SwiftUI
import SwiftData

struct iPadContentView: View {
    @State private var selectedTab: AppTab = .projects
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sidebar
            SidebarView(selectedTab: $selectedTab)
                .navigationSplitViewColumnWidth(min: 250, ideal: 300, max: 350)
        } detail: {
            // Main Content
            Group {
                switch selectedTab {
                case .projects:
                    iPadProjectsView()
                case .patterns:
                    iPadPatternsView()
                case .measurements:
                    iPadMeasurementsView()
                case .fabric:
                    iPadFabricStashView()
                case .settings:
                    iPadSettingsView()
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct SidebarView: View {
    @Binding var selectedTab: AppTab
    @Environment(\.modelContext) private var modelContext
    @Query private var projects: [Project]
    @Query private var patterns: [Pattern]
    @Query private var fabrics: [Fabric]
    @Query private var measurementProfiles: [MeasurementProfile]
    
    var body: some View {
        List {
            Section("Navigation") {
                ForEach(AppTab.allCases, id: \.self) { tab in
                    Button(action: { selectedTab = tab }) {
                        HStack {
                            Image(systemName: tab.iconName)
                                .foregroundColor(tab.color)
                                .frame(width: 24)
                            Text(tab.title)
                                .foregroundColor(.primary)
                            Spacer()
                            Text("\(count(for: tab))")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .background(selectedTab == tab ? Color.blue.opacity(0.2) : Color.clear)
                    .cornerRadius(8)
                }
            }
            
            Section("Quick Stats") {
                QuickStatRow(title: "Active Projects", 
                           count: projects.filter { $0.status == .inProgress }.count,
                           icon: "folder.badge",
                           color: .blue)
                
                QuickStatRow(title: "Completed Projects", 
                           count: projects.filter { $0.status == .completed }.count,
                           icon: "checkmark.circle",
                           color: .green)
                
                QuickStatRow(title: "Fabric Yards", 
                           count: Int(fabrics.reduce(0) { $0 + $1.yardage }),
                           icon: "ruler",
                           color: .purple)
            }
        }
        .navigationTitle("SewSmart")
        .listStyle(SidebarListStyle())
    }
    
    private func count(for tab: AppTab) -> Int {
        switch tab {
        case .projects: return projects.count
        case .patterns: return patterns.count
        case .measurements: return measurementProfiles.count
        case .fabric: return fabrics.count
        case .settings: return 0
        }
    }
}

struct QuickStatRow: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            Text(title)
                .font(.caption)
            Spacer()
            Text("\(count)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

enum AppTab: String, CaseIterable {
    case projects = "Projects"
    case patterns = "Patterns"
    case measurements = "Measurements"
    case fabric = "Fabric"
    case settings = "Settings"
    
    var title: String { rawValue }
    
    var iconName: String {
        switch self {
        case .projects: return "folder"
        case .patterns: return "doc.text"
        case .measurements: return "ruler"
        case .fabric: return "square.stack.3d.down.forward"
        case .settings: return "gear"
        }
    }
    
    var color: Color {
        switch self {
        case .projects: return .blue
        case .patterns: return .green
        case .measurements: return .orange
        case .fabric: return .purple
        case .settings: return .gray
        }
    }
}

#Preview {
    iPadContentView()
        .modelContainer(for: Project.self, inMemory: true)
}