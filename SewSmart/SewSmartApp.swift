import SwiftUI
import SwiftData
import os.log

@main
struct SewSmartApp: App {
    @State private var modelContainer: Result<ModelContainer, SewSmartError>
    @State private var showingError: SewSmartError?
    
    private let logger = Logger(subsystem: "com.sewsmart.app", category: "AppInitialization")
    
    init() {
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
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            self.modelContainer = .success(container)
        } catch {
            self.logger.error("Failed to create ModelContainer: \(error.localizedDescription)")
            self.modelContainer = .failure(.modelContainerInitializationFailed(error))
        }
    }
    
    @MainActor
    private func dependencyContainer(for modelContext: ModelContext) -> DependencyContainer {
        DependencyContainer(modelContext: modelContext)
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                switch modelContainer {
                case .success(let container):
                    AdaptiveContentView()
                        .environmentObject(dependencyContainer(for: container.mainContext))
                        .modelContainer(container)
                case .failure(let error):
                    ErrorView(error: error) {
                        // Retry initialization
                        retryInitialization()
                    }
                }
            }
            .errorAlert($showingError)
        }
    }
    
    private func retryInitialization() {
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
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            self.modelContainer = .success(container)
        } catch {
            self.logger.error("Retry failed: \(error.localizedDescription)")
            self.showingError = .modelContainerInitializationFailed(error)
        }
    }
}

struct ErrorView: View {
    let error: SewSmartError
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Unable to Start SewSmart")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(error.errorDescription ?? "An unknown error occurred")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if let recovery = error.recoverySuggestion {
                Text(recovery)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button("Try Again") {
                retryAction()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
