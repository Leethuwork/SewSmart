import SwiftUI
import SwiftData

@main
struct SewSmartApp: App {
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Project.self,
            Pattern.self,
            Fabric.self,
            MeasurementProfile.self,
            Measurement.self,
            ProjectPhoto.self,
            ShoppingList.self,
            ShoppingItem.self,
            UserSettings.self,
            UserHistory.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            AdaptiveContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
