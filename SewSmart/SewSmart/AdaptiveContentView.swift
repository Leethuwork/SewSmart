import SwiftUI
import SwiftData

struct AdaptiveContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    var isIPad: Bool {
        horizontalSizeClass == .regular && verticalSizeClass == .regular
    }
    
    var body: some View {
        Group {
            if isIPad {
                iPadContentView()
            } else {
                ContentView()
            }
        }
    }
}

// Enhanced iPhone ContentView with iPad-aware features
struct EnhancedContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        TabView {
            ProjectsView()
                .tabItem {
                    Image(systemName: "folder")
                    Text("Projects")
                }
            
            PatternsView()
                .tabItem {
                    Image(systemName: "doc.text")
                    Text("Patterns")
                }
            
            MeasurementsView()
                .tabItem {
                    Image(systemName: "ruler")
                    Text("Measurements")
                }
            
            FabricStashView()
                .tabItem {
                    Image(systemName: "square.stack.3d.down.forward")
                    Text("Fabric")
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
        .accentColor(.purple)
    }
}

#Preview("iPhone") {
    AdaptiveContentView()
        .modelContainer(for: Project.self, inMemory: true)
        .previewDevice(PreviewDevice(rawValue: "iPhone 15"))
}

#Preview("iPad") {
    AdaptiveContentView()
        .modelContainer(for: Project.self, inMemory: true)
        .previewDevice(PreviewDevice(rawValue: "iPad Pro (12.9-inch) (6th generation)"))
}