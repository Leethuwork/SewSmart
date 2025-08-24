import Foundation

/// Represents the loading state of any async operation
enum LoadingState<T>: Equatable where T: Equatable {
    case idle
    case loading
    case loaded(T)
    case failed(SewSmartError)
    
    var isLoading: Bool {
        switch self {
        case .loading:
            return true
        default:
            return false
        }
    }
    
    var isLoaded: Bool {
        switch self {
        case .loaded:
            return true
        default:
            return false
        }
    }
    
    var isFailed: Bool {
        switch self {
        case .failed:
            return true
        default:
            return false
        }
    }
    
    var data: T? {
        switch self {
        case .loaded(let data):
            return data
        default:
            return nil
        }
    }
    
    var error: SewSmartError? {
        switch self {
        case .failed(let error):
            return error
        default:
            return nil
        }
    }
    
    static func == (lhs: LoadingState<T>, rhs: LoadingState<T>) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case (.loading, .loading):
            return true
        case let (.loaded(lhsData), .loaded(rhsData)):
            return lhsData == rhsData
        case let (.failed(lhsError), .failed(rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}

/// Convenience extensions for common operations
extension LoadingState {
    mutating func setLoading() {
        self = .loading
    }
    
    mutating func setLoaded(_ data: T) {
        self = .loaded(data)
    }
    
    mutating func setFailed(_ error: SewSmartError) {
        self = .failed(error)
    }
    
    mutating func setIdle() {
        self = .idle
    }
}

/// Simple loading state without data
enum SimpleLoadingState: Equatable {
    case idle
    case loading
    case success
    case failed(SewSmartError)
    
    var isLoading: Bool {
        switch self {
        case .loading:
            return true
        default:
            return false
        }
    }
    
    var isSuccess: Bool {
        switch self {
        case .success:
            return true
        default:
            return false
        }
    }
    
    var isFailed: Bool {
        switch self {
        case .failed:
            return true
        default:
            return false
        }
    }
    
    var error: SewSmartError? {
        switch self {
        case .failed(let error):
            return error
        default:
            return nil
        }
    }
    
    static func == (lhs: SimpleLoadingState, rhs: SimpleLoadingState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading), (.success, .success):
            return true
        case let (.failed(lhsError), .failed(rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}

extension SimpleLoadingState {
    mutating func setLoading() {
        self = .loading
    }
    
    mutating func setSuccess() {
        self = .success
    }
    
    mutating func setFailed(_ error: SewSmartError) {
        self = .failed(error)
    }
    
    mutating func setIdle() {
        self = .idle
    }
}