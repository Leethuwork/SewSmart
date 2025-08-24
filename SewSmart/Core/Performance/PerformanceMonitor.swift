import Foundation
import SwiftUI
import os.log
import UIKit

/// Performance monitoring and metrics collection
actor PerformanceMonitor {
    static let shared = PerformanceMonitor()
    
    private let logger = Logger(subsystem: "com.sewsmart.performance", category: "PerformanceMonitor")
    private var metrics: [String: PerformanceMetric] = [:]
    private var memoryWarningCount = 0
    
    private init() {
        observeMemoryWarnings()
        startMemoryMonitoring()
    }
    
    // MARK: - Timing Measurements
    
    func startMeasuring(_ operation: String) -> MeasurementToken {
        let token = MeasurementToken(operation: operation)
        logger.debug("Started measuring: \(operation)")
        return token
    }
    
    func finishMeasuring(_ token: MeasurementToken) {
        let duration = token.finish()
        
        let metric = PerformanceMetric(
            operation: token.operation,
            duration: duration,
            timestamp: Date(),
            memoryUsage: getCurrentMemoryUsage()
        )
        
        metrics[token.operation] = metric
        logger.info("Finished measuring: \(token.operation) - Duration: \(String(format: "%.1f", duration * 1000))ms")
        
        // Log slow operations
        if duration > 0.5 { // 500ms threshold
            logger.warning("Slow operation detected: \(token.operation) took \(String(format: "%.1f", duration * 1000))ms")
        }
    }
    
    // MARK: - Memory Monitoring
    
    func getCurrentMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let memoryUsageMB = Double(info.resident_size) / 1024.0 / 1024.0
            return memoryUsageMB
        }
        
        return 0
    }
    
    private func observeMemoryWarnings() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                await self?.recordMemoryWarning()
            }
        }
    }
    
    private func recordMemoryWarning() {
        memoryWarningCount += 1
        let memoryUsage = getCurrentMemoryUsage()
        logger.warning("Memory warning #\(self.memoryWarningCount) - Current usage: \(String(format: "%.1f", memoryUsage))MB")
    }
    
    private func startMemoryMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task {
                await self?.logMemoryUsage()
            }
        }
    }
    
    private func logMemoryUsage() {
        let memoryUsage = getCurrentMemoryUsage()
        if memoryUsage > 100 { // Log if over 100MB
            logger.info("High memory usage: \(String(format: "%.1f", memoryUsage))MB")
        }
    }
    
    // MARK: - SwiftData Performance
    
    func measureSwiftDataOperation<T>(_ operation: String, _ block: () async throws -> T) async rethrows -> T {
        let token = startMeasuring("SwiftData.\(operation)")
        defer {
            Task {
                await finishMeasuring(token)
            }
        }
        
        return try await block()
    }
    
    // MARK: - Metrics Reporting
    
    func getPerformanceReport() -> PerformanceReport {
        let allMetrics = Array(metrics.values)
        let currentMemory = getCurrentMemoryUsage()
        
        return PerformanceReport(
            metrics: allMetrics,
            currentMemoryUsage: currentMemory,
            memoryWarningCount: memoryWarningCount,
            averageOperationTime: calculateAverageOperationTime(allMetrics),
            slowOperations: allMetrics.filter { $0.duration > 0.5 }
        )
    }
    
    private func calculateAverageOperationTime(_ metrics: [PerformanceMetric]) -> Double {
        guard !metrics.isEmpty else { return 0 }
        return metrics.reduce(0) { $0 + $1.duration } / Double(metrics.count)
    }
    
    func clearMetrics() {
        metrics.removeAll()
        logger.info("Cleared performance metrics")
    }
}

// MARK: - Supporting Types

struct MeasurementToken {
    let operation: String
    private let startTime: CFAbsoluteTime
    
    init(operation: String) {
        self.operation = operation
        self.startTime = CFAbsoluteTimeGetCurrent()
    }
    
    func finish() -> TimeInterval {
        return CFAbsoluteTimeGetCurrent() - startTime
    }
}

struct PerformanceMetric {
    let operation: String
    let duration: TimeInterval
    let timestamp: Date
    let memoryUsage: Double
    
    var durationInMilliseconds: Double {
        return duration * 1000
    }
}

struct PerformanceReport {
    let metrics: [PerformanceMetric]
    let currentMemoryUsage: Double
    let memoryWarningCount: Int
    let averageOperationTime: Double
    let slowOperations: [PerformanceMetric]
    
    var formattedReport: String {
        var report = "=== Performance Report ===\n"
        report += "Current Memory: \(String(format: "%.1f", currentMemoryUsage))MB\n"
        report += "Memory Warnings: \(memoryWarningCount)\n"
        report += "Average Operation Time: \(String(format: "%.1f", averageOperationTime * 1000))ms\n"
        report += "Total Operations: \(metrics.count)\n"
        
        if !slowOperations.isEmpty {
            report += "\nSlow Operations (\(slowOperations.count)):\n"
            for op in slowOperations {
                report += "- \(op.operation): \(String(format: "%.1f", op.durationInMilliseconds))ms\n"
            }
        }
        
        return report
    }
}

// MARK: - View Extensions for Performance Monitoring

extension View {
    func measurePerformance(_ operation: String) -> some View {
        self.onAppear {
            Task {
                let token = await PerformanceMonitor.shared.startMeasuring(operation)
                // Small delay to capture view rendering time
                try? await Task.sleep(for: .milliseconds(10))
                await PerformanceMonitor.shared.finishMeasuring(token)
            }
        }
    }
}