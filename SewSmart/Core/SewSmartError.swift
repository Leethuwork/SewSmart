import SwiftUI

enum SewSmartError: LocalizedError, Identifiable {
    case dataStorageUnavailable
    case dataCorruption
    case networkUnavailable
    case invalidInput(String)
    case modelContainerInitializationFailed(Error)
    
    var id: String {
        switch self {
        case .dataStorageUnavailable:
            return "dataStorageUnavailable"
        case .dataCorruption:
            return "dataCorruption"
        case .networkUnavailable:
            return "networkUnavailable"
        case .invalidInput(let field):
            return "invalidInput_\(field)"
        case .modelContainerInitializationFailed:
            return "modelContainerInitializationFailed"
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .dataStorageUnavailable:
            return "Data storage is unavailable. Please check your device storage and try again."
        case .dataCorruption:
            return "Data corruption detected. The app may not function properly."
        case .networkUnavailable:
            return "Network connection unavailable. Some features may be limited."
        case .invalidInput(let field):
            return "Invalid input for \(field). Please check your entry and try again."
        case .modelContainerInitializationFailed(let error):
            return "Failed to initialize data storage: \(error.localizedDescription)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .dataStorageUnavailable:
            return "Free up device storage space and restart the app."
        case .dataCorruption:
            return "Contact support if the problem persists."
        case .networkUnavailable:
            return "Check your internet connection and try again."
        case .invalidInput:
            return "Please correct the highlighted fields."
        case .modelContainerInitializationFailed:
            return "Restart the app. If the problem persists, contact support."
        }
    }
}

// Error alert modifier
struct ErrorAlert: ViewModifier {
    @Binding var error: SewSmartError?
    
    func body(content: Content) -> some View {
        content
            .alert("Error", isPresented: .constant(error != nil), presenting: error) { error in
                Button("OK") {
                    self.error = nil
                }
            } message: { error in
                VStack {
                    if let description = error.errorDescription {
                        Text(description)
                    }
                    if let recovery = error.recoverySuggestion {
                        Text(recovery)
                            .font(.caption)
                    }
                }
            }
    }
}

extension View {
    func errorAlert(_ error: Binding<SewSmartError?>) -> some View {
        modifier(ErrorAlert(error: error))
    }
}