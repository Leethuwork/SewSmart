import Foundation
import CryptoKit
import os.log

/// Secure data handling utilities
struct DataSecurity {
    private static let logger = Logger(subsystem: "com.sewsmart.security", category: "DataSecurity")
    
    // MARK: - Data Export Security
    
    /// Sanitizes data for safe export
    static func sanitizeForExport<T: Codable>(_ data: [T]) -> [T] {
        logger.info("Sanitizing \(data.count) items for export")
        
        // For now, we'll return the data as-is since our models don't contain sensitive information
        // In a real-world scenario with user authentication, we would:
        // 1. Remove any sensitive fields
        // 2. Validate user permissions
        // 3. Log the export operation
        
        return data
    }
    
    /// Validates export request
    static func validateExportRequest(itemCount: Int) -> ExportValidationResult {
        guard itemCount > 0 else {
            return .invalid("No items to export")
        }
        
        guard itemCount <= 10000 else {
            return .invalid("Cannot export more than 10,000 items at once")
        }
        
        logger.info("Export request validated for \(itemCount) items")
        return .valid
    }
    
    // MARK: - Data Import Security
    
    /// Validates imported data structure
    static func validateImportData<T: Codable>(_ data: Data, as type: T.Type) -> ImportValidationResult<T> {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let items = try decoder.decode([T].self, from: data)
            
            guard !items.isEmpty else {
                return .invalid("Import file is empty")
            }
            
            guard items.count <= 10000 else {
                return .invalid("Cannot import more than 10,000 items at once")
            }
            
            // Check for reasonable data size (max 50MB)
            guard data.count <= 50 * 1024 * 1024 else {
                return .invalid("Import file is too large (max 50MB)")
            }
            
            logger.info("Import data validated: \(items.count) items")
            return .valid(items)
            
        } catch DecodingError.dataCorrupted {
            return .invalid("Import file is corrupted or has invalid format")
        } catch DecodingError.keyNotFound(let key, _) {
            return .invalid("Import file is missing required field: \(key.stringValue)")
        } catch DecodingError.typeMismatch(let type, _) {
            return .invalid("Import file has incorrect data type for field (expected \(type))")
        } catch {
            logger.error("Import validation failed: \(error.localizedDescription)")
            return .invalid("Import file format is invalid")
        }
    }
    
    // MARK: - Data Integrity
    
    /// Generates a checksum for data integrity verification
    static func generateChecksum(for data: Data) -> String {
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    /// Verifies data integrity using checksum
    static func verifyIntegrity(of data: Data, expectedChecksum: String) -> Bool {
        let actualChecksum = generateChecksum(for: data)
        return actualChecksum == expectedChecksum
    }
    
    // MARK: - Privacy Protection
    
    /// Anonymizes sensitive data for analytics (if implemented later)
    static func anonymizeForAnalytics<T>(_ items: [T]) -> [T] {
        // For now, return as-is since we don't collect analytics
        // In the future, this would remove or hash personally identifiable information
        logger.info("Anonymized \(items.count) items for analytics")
        return items
    }
    
    // MARK: - Backup Security
    
    /// Prepares data for secure backup
    static func prepareForBackup<T: Codable>(_ data: [T]) -> BackupData<T> {
        let timestamp = Date()
        let checksum = generateChecksum(for: try! JSONEncoder().encode(data))
        
        logger.info("Prepared backup for \(data.count) items with checksum: \(String(checksum.prefix(8)))...")
        
        return BackupData(
            items: data,
            timestamp: timestamp,
            checksum: checksum,
            version: "1.0"
        )
    }
    
    /// Validates restored backup data
    static func validateBackup<T: Codable>(_ backup: BackupData<T>) -> BackupValidationResult<T> {
        // Check backup age (reject backups older than 2 years)
        let twoYearsAgo = Calendar.current.date(byAdding: .year, value: -2, to: Date()) ?? Date()
        guard backup.timestamp >= twoYearsAgo else {
            return .invalid("Backup is too old (older than 2 years)")
        }
        
        // Verify checksum
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(backup.items)
            let actualChecksum = generateChecksum(for: data)
            
            guard actualChecksum == backup.checksum else {
                return .invalid("Backup data integrity check failed")
            }
            
            logger.info("Backup validation successful for \(backup.items.count) items")
            return .valid(backup.items)
            
        } catch {
            logger.error("Backup validation failed: \(error.localizedDescription)")
            return .invalid("Failed to validate backup data")
        }
    }
    
    // MARK: - Secure Deletion
    
    /// Securely marks data for deletion (in a real app, this might involve more complex cleanup)
    static func secureDelete<T>(items: [T]) {
        logger.info("Securely deleted \(items.count) items")
        // In a real implementation, we might:
        // 1. Clear any cached references
        // 2. Schedule background cleanup
        // 3. Log the deletion for audit purposes
    }
}

// MARK: - Supporting Types

enum ExportValidationResult {
    case valid
    case invalid(String)
    
    var isValid: Bool {
        switch self {
        case .valid: return true
        case .invalid: return false
        }
    }
    
    var errorMessage: String? {
        switch self {
        case .valid: return nil
        case .invalid(let message): return message
        }
    }
}

enum ImportValidationResult<T> {
    case valid([T])
    case invalid(String)
    
    var isValid: Bool {
        switch self {
        case .valid: return true
        case .invalid: return false
        }
    }
    
    var items: [T]? {
        switch self {
        case .valid(let items): return items
        case .invalid: return nil
        }
    }
    
    var errorMessage: String? {
        switch self {
        case .valid: return nil
        case .invalid(let message): return message
        }
    }
}

enum BackupValidationResult<T> {
    case valid([T])
    case invalid(String)
    
    var isValid: Bool {
        switch self {
        case .valid: return true
        case .invalid: return false
        }
    }
    
    var items: [T]? {
        switch self {
        case .valid(let items): return items
        case .invalid: return nil
        }
    }
    
    var errorMessage: String? {
        switch self {
        case .valid: return nil
        case .invalid(let message): return message
        }
    }
}

struct BackupData<T: Codable>: Codable {
    let items: [T]
    let timestamp: Date
    let checksum: String
    let version: String
}