import SwiftUI
import SwiftData

struct ContentView: View {
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
        .background(DesignSystem.backgroundColor)
        .accentColor(DesignSystem.primaryPink)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Project.self, inMemory: true)
}
