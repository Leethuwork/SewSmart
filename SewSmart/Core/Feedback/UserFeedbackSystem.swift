import SwiftUI
import UIKit
import Foundation
import os.log

/// Comprehensive user feedback system with toast messages, progress indicators, and feedback collection
@MainActor
@Observable
class UserFeedbackSystem {
    static let shared = UserFeedbackSystem()
    
    private let logger = Logger(subsystem: "com.sewsmart.feedback", category: "UserFeedbackSystem")
    
    // MARK: - Toast Messages
    
    private(set) var currentToast: ToastMessage?
    private var toastTimer: Timer?
    
    // MARK: - Loading States
    
    private(set) var loadingStates: [String: LoadingIndicator] = [:]
    
    // MARK: - Success/Error Tracking
    
    private(set) var recentFeedback: [FeedbackEntry] = []
    private let maxRecentFeedback = 50
    
    private init() {
        logger.info("UserFeedbackSystem initialized")
    }
    
    // MARK: - Toast Messages
    
    func showToast(_ message: ToastMessage) {
        toastTimer?.invalidate()
        currentToast = message
        
        let logMsg = "Showing toast: \(message.title) - \(message.type.rawValue)"
        logger.info("\(logMsg, privacy: .public)")
        
        // Auto-dismiss based on type
        var duration: TimeInterval
        switch message.type {
        case .success: duration = 3.0
        case .error: duration = 5.0
        case .warning: duration = 4.0
        case .info: duration = 3.0
        }
        
        toastTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.dismissToast()
            }
        }
        
        // Add to recent feedback
        let entry = FeedbackEntry(
            timestamp: Date(),
            type: message.type.feedbackType,
            title: message.title,
            message: message.message
        )
        addFeedbackEntry(entry)
        
        // Haptic feedback
        generateHapticFeedback(for: message.type)
    }
    
    func showSuccess(_ title: String, message: String? = nil) {
        let toast = ToastMessage(
            type: .success,
            title: title,
            message: message,
            icon: "checkmark.circle.fill"
        )
        showToast(toast)
    }
    
    func showError(_ title: String, message: String? = nil, error: Error? = nil) {
        let errorMessage = message ?? error?.localizedDescription
        let toast = ToastMessage(
            type: .error,
            title: title,
            message: errorMessage,
            icon: "xmark.circle.fill"
        )
        showToast(toast)
    }
    
    func showWarning(_ title: String, message: String? = nil) {
        let toast = ToastMessage(
            type: .warning,
            title: title,
            message: message,
            icon: "exclamationmark.triangle.fill"
        )
        showToast(toast)
    }
    
    func showInfo(_ title: String, message: String? = nil) {
        let toast = ToastMessage(
            type: .info,
            title: title,
            message: message,
            icon: "info.circle.fill"
        )
        showToast(toast)
    }
    
    func dismissToast() {
        toastTimer?.invalidate()
        withAnimation(.easeOut(duration: 0.3)) {
            currentToast = nil
        }
    }
    
    // MARK: - Loading Indicators
    
    func showLoading(_ message: String, for key: String = "default") {
        let indicator = LoadingIndicator(
            message: message,
            startTime: Date(),
            isVisible: true
        )
        loadingStates[key] = indicator
        logger.info("Showing loading indicator: \(message) for key: \(key)")
    }
    
    func updateLoadingMessage(_ message: String, for key: String = "default") {
        if var indicator = loadingStates[key] {
            indicator.message = message
            loadingStates[key] = indicator
            logger.info("Updated loading message: \(message) for key: \(key)")
        }
    }
    
    func hideLoading(for key: String = "default") {
        loadingStates.removeValue(forKey: key)
        logger.info("Hidden loading indicator for key: \(key)")
    }
    
    func hideAllLoading() {
        loadingStates.removeAll()
        logger.info("Hidden all loading indicators")
    }
    
    // MARK: - Progress Indicators
    
    func showProgress(_ progress: Double, message: String, for key: String = "default") {
        let indicator = LoadingIndicator(
            message: message,
            startTime: Date(),
            isVisible: true,
            progress: progress
        )
        loadingStates[key] = indicator
    }
    
    func updateProgress(_ progress: Double, message: String? = nil, for key: String = "default") {
        if var indicator = loadingStates[key] {
            indicator.progress = progress
            if let message = message {
                indicator.message = message
            }
            loadingStates[key] = indicator
        }
    }
    
    // MARK: - Operation Feedback
    
    func trackOperation<T>(
        _ operation: () async throws -> T,
        loadingMessage: String,
        successMessage: String,
        errorTitle: String = "Operation Failed",
        key: String = "default"
    ) async -> T? {
        showLoading(loadingMessage, for: key)
        
        do {
            let result = try await operation()
            hideLoading(for: key)
            showSuccess(successMessage)
            return result
        } catch {
            hideLoading(for: key)
            showError(errorTitle, error: error)
            return nil
        }
    }
    
    // MARK: - Feedback History
    
    private func addFeedbackEntry(_ entry: FeedbackEntry) {
        recentFeedback.append(entry)
        
        // Keep only recent feedback
        if recentFeedback.count > maxRecentFeedback {
            recentFeedback = Array(recentFeedback.suffix(maxRecentFeedback))
        }
    }
    
    func getFeedbackHistory(type: FeedbackType? = nil) -> [FeedbackEntry] {
        if let type = type {
            return recentFeedback.filter { $0.type == type }
        }
        return recentFeedback
    }
    
    func clearFeedbackHistory() {
        recentFeedback.removeAll()
        logger.info("Cleared feedback history")
    }
    
    // MARK: - Haptic Feedback
    
    private func generateHapticFeedback(for type: ToastType) {
        let impact: UIImpactFeedbackGenerator.FeedbackStyle
        
        switch type {
        case .success:
            let feedback = UINotificationFeedbackGenerator()
            feedback.notificationOccurred(.success)
            return
        case .error:
            let feedback = UINotificationFeedbackGenerator()
            feedback.notificationOccurred(.error)
            return
        case .warning:
            let feedback = UINotificationFeedbackGenerator()
            feedback.notificationOccurred(.warning)
            return
        case .info:
            impact = .light
        }
        
        let feedback = UIImpactFeedbackGenerator(style: impact)
        feedback.impactOccurred()
    }
    
    // MARK: - Accessibility
    
    func announceToScreenReader(_ message: String) {
        UIAccessibility.post(notification: .announcement, argument: message)
    }
    
    func announcePageChange(_ title: String) {
        UIAccessibility.post(notification: .screenChanged, argument: title)
    }
    
    // MARK: - Statistics
    
    func getFeedbackStats() -> FeedbackStats {
        let successCount = recentFeedback.filter { $0.type == .success }.count
        let errorCount = recentFeedback.filter { $0.type == .error }.count
        let warningCount = recentFeedback.filter { $0.type == .warning }.count
        let infoCount = recentFeedback.filter { $0.type == .info }.count
        
        return FeedbackStats(
            totalFeedback: recentFeedback.count,
            successCount: successCount,
            errorCount: errorCount,
            warningCount: warningCount,
            infoCount: infoCount,
            successRate: recentFeedback.isEmpty ? 0 : Double(successCount) / Double(recentFeedback.count)
        )
    }
}

// MARK: - Supporting Types

struct ToastMessage: Identifiable, Equatable {
    let id = UUID()
    let type: ToastType
    let title: String
    let message: String?
    let icon: String?
    let timestamp = Date()
    
    static func == (lhs: ToastMessage, rhs: ToastMessage) -> Bool {
        lhs.id == rhs.id
    }
}

enum ToastType: String, CaseIterable {
    case success, error, warning, info
    
    var color: Color {
        switch self {
        case .success: return .green
        case .error: return .red
        case .warning: return .orange
        case .info: return .blue
        }
    }
    
    var feedbackType: FeedbackType {
        switch self {
        case .success: return .success
        case .error: return .error
        case .warning: return .warning
        case .info: return .info
        }
    }
}

struct LoadingIndicator {
    var message: String
    let startTime: Date
    var isVisible: Bool
    var progress: Double?
    
    var duration: TimeInterval {
        Date().timeIntervalSince(startTime)
    }
    
    var isIndeterminate: Bool {
        progress == nil
    }
}

struct FeedbackEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let type: FeedbackType
    let title: String
    let message: String?
}

enum FeedbackType: String, CaseIterable {
    case success, error, warning, info
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .success: return .green
        case .error: return .red
        case .warning: return .orange
        case .info: return .blue
        }
    }
}

struct FeedbackStats {
    let totalFeedback: Int
    let successCount: Int
    let errorCount: Int
    let warningCount: Int
    let infoCount: Int
    let successRate: Double
    
    var hasErrors: Bool {
        errorCount > 0
    }
    
    var hasWarnings: Bool {
        warningCount > 0
    }
}

// MARK: - SwiftUI Views

struct ToastView: View {
    let toast: ToastMessage
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            if let icon = toast.icon {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(toast.type.color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(toast.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if let message = toast.message {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
            }
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        )
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(toast.type.rawValue.capitalized): \(toast.title)")
        .accessibilityValue(toast.message ?? "")
        .accessibilityAction(named: "Dismiss") {
            onDismiss()
        }
    }
}

struct LoadingOverlay: View {
    let indicator: LoadingIndicator
    
    var body: some View {
        VStack(spacing: 16) {
            if let progress = indicator.progress {
                ProgressView(value: progress)
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
            }
            
            Text(indicator.message)
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading: \(indicator.message)")
        .accessibilityValue(indicator.progress.map { "\(Int($0 * 100)) percent complete" } ?? "In progress")
    }
}

// MARK: - View Extensions

extension View {
    func toastOverlay() -> some View {
        self.overlay(alignment: .top) {
            if let toast = UserFeedbackSystem.shared.currentToast {
                ToastView(toast: toast) {
                    UserFeedbackSystem.shared.dismissToast()
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .opacity
                ))
                .zIndex(999)
            }
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: UserFeedbackSystem.shared.currentToast?.id)
    }
    
    func loadingOverlay(key: String = "default") -> some View {
        self.overlay {
            if let indicator = UserFeedbackSystem.shared.loadingStates[key], indicator.isVisible {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    LoadingOverlay(indicator: indicator)
                }
                .transition(.opacity)
                .zIndex(998)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: UserFeedbackSystem.shared.loadingStates[key]?.isVisible)
    }
    
    func userFeedback() -> some View {
        self
            .toastOverlay()
            .loadingOverlay()
    }
}