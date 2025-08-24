import SwiftUI
import SwiftData

enum TabSelection: String, CaseIterable {
    case projects = "Projects"
    case patterns = "Patterns" 
    case measurements = "Measurements"
    case fabric = "Fabric"
    case settings = "Settings"
    
    var icon: String {
        switch self {
        case .projects: return "folder"
        case .patterns: return "doc.text"
        case .measurements: return "ruler"
        case .fabric: return "square.stack.3d.down.forward"
        case .settings: return "gear"
        }
    }
    
    var selectedIcon: String {
        switch self {
        case .projects: return "folder.fill"
        case .patterns: return "doc.text.fill"
        case .measurements: return "ruler.fill"
        case .fabric: return "square.stack.3d.down.forward.fill"
        case .settings: return "gear.badge"
        }
    }
}

struct ContentView: View {
    @State private var selectedTab: TabSelection = .projects
    
    var body: some View {
        VStack(spacing: 0) {
            // Main content area
            Group {
                switch selectedTab {
                case .projects:
                    ProjectsView()
                case .patterns:
                    PatternsView()
                case .measurements:
                    MeasurementsView()
                case .fabric:
                    FabricStashView()
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Custom Tab Bar
            customTabBar
        }
        .background(DesignSystem.backgroundColor)
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
    
    private var customTabBar: some View {
        HStack {
            ForEach(TabSelection.allCases, id: \.self) { tab in
                Spacer()
                
                SewSmartTabItem(
                    title: tab.rawValue,
                    icon: tab.icon,
                    selectedIcon: tab.selectedIcon,
                    isSelected: selectedTab == tab
                ) {
                    selectedTab = tab
                }
                
                Spacer()
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(
            Rectangle()
                .fill(DesignSystem.cardBackgroundColor)
                .lightShadow()
        )
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Project.self, inMemory: true)
}
