import XCTest
import CryptoKit
@testable import SewSmart

final class DataSecurityTests: XCTestCase {
    
    // MARK: - Export Security Tests
    
    func testSanitizeForExport() {
        let projects = [
            Project(name: "Test Project 1", description: "Description 1", status: .planning, priority: 1),
            Project(name: "Test Project 2", description: "Description 2", status: .inProgress, priority: 2)
        ]
        
        let sanitized = DataSecurity.sanitizeForExport(projects)
        XCTAssertEqual(sanitized.count, 2)
        XCTAssertEqual(sanitized[0].name, "Test Project 1")
        XCTAssertEqual(sanitized[1].name, "Test Project 2")
    }
    
    func testValidateExportRequestSuccess() {
        let result1 = DataSecurity.validateExportRequest(itemCount: 1)
        XCTAssertTrue(result1.isValid)
        
        let result2 = DataSecurity.validateExportRequest(itemCount: 5000)
        XCTAssertTrue(result2.isValid)
        
        let result3 = DataSecurity.validateExportRequest(itemCount: 10000)
        XCTAssertTrue(result3.isValid)
    }
    
    func testValidateExportRequestFailure() {
        let result1 = DataSecurity.validateExportRequest(itemCount: 0)
        XCTAssertFalse(result1.isValid)
        XCTAssertEqual(result1.errorMessage, "No items to export")
        
        let result2 = DataSecurity.validateExportRequest(itemCount: 10001)
        XCTAssertFalse(result2.isValid)
        XCTAssertEqual(result2.errorMessage, "Cannot export more than 10,000 items at once")
    }
    
    // MARK: - Import Security Tests
    
    func testValidateImportDataSuccess() throws {
        let projects = [
            Project(name: "Import Test 1", description: "Description 1", status: .planning, priority: 1),
            Project(name: "Import Test 2", description: "Description 2", status: .inProgress, priority: 2)
        ]
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(projects)
        
        let result = DataSecurity.validateImportData(data, as: Project.self)
        XCTAssertTrue(result.isValid)
        XCTAssertEqual(result.items?.count, 2)
        XCTAssertEqual(result.items?.first?.name, "Import Test 1")
    }
    
    func testValidateImportDataFailure() {
        // Test empty data
        let emptyData = "[]".data(using: .utf8)!
        let result1 = DataSecurity.validateImportData(emptyData, as: Project.self)
        XCTAssertFalse(result1.isValid)
        XCTAssertEqual(result1.errorMessage, "Import file is empty")
        
        // Test invalid JSON
        let invalidData = "invalid json".data(using: .utf8)!
        let result2 = DataSecurity.validateImportData(invalidData, as: Project.self)
        XCTAssertFalse(result2.isValid)
        XCTAssertTrue(result2.errorMessage?.contains("invalid format") == true)
        
        // Test too large data
        let largeData = Data(count: 60 * 1024 * 1024) // 60MB
        let result3 = DataSecurity.validateImportData(largeData, as: Project.self)
        XCTAssertFalse(result3.isValid)
        XCTAssertEqual(result3.errorMessage, "Import file is too large (max 50MB)")
    }
    
    // MARK: - Data Integrity Tests
    
    func testGenerateChecksum() {
        let data1 = "Hello, World!".data(using: .utf8)!
        let checksum1 = DataSecurity.generateChecksum(for: data1)
        XCTAssertFalse(checksum1.isEmpty)
        XCTAssertEqual(checksum1.count, 64) // SHA256 produces 64 character hex string
        
        let data2 = "Hello, World!".data(using: .utf8)!
        let checksum2 = DataSecurity.generateChecksum(for: data2)
        XCTAssertEqual(checksum1, checksum2) // Same data should produce same checksum
        
        let data3 = "Different data".data(using: .utf8)!
        let checksum3 = DataSecurity.generateChecksum(for: data3)
        XCTAssertNotEqual(checksum1, checksum3) // Different data should produce different checksums
    }
    
    func testVerifyIntegrity() {
        let data = "Test data for integrity check".data(using: .utf8)!
        let checksum = DataSecurity.generateChecksum(for: data)
        
        // Valid verification
        XCTAssertTrue(DataSecurity.verifyIntegrity(of: data, expectedChecksum: checksum))
        
        // Invalid verification with wrong checksum
        XCTAssertFalse(DataSecurity.verifyIntegrity(of: data, expectedChecksum: "invalid_checksum"))
        
        // Invalid verification with corrupted data
        let corruptedData = "Corrupted data".data(using: .utf8)!
        XCTAssertFalse(DataSecurity.verifyIntegrity(of: corruptedData, expectedChecksum: checksum))
    }
    
    // MARK: - Privacy Tests
    
    func testAnonymizeForAnalytics() {
        let projects = [
            Project(name: "Project 1", description: "Description 1", status: .planning, priority: 1),
            Project(name: "Project 2", description: "Description 2", status: .inProgress, priority: 2)
        ]
        
        let anonymized = DataSecurity.anonymizeForAnalytics(projects)
        XCTAssertEqual(anonymized.count, projects.count)
        // In the current implementation, data is returned as-is
        // In a real app with user data, this would anonymize personal information
    }
    
    // MARK: - Backup Security Tests
    
    func testPrepareForBackup() throws {
        let projects = [
            Project(name: "Backup Test 1", description: "Description 1", status: .planning, priority: 1),
            Project(name: "Backup Test 2", description: "Description 2", status: .inProgress, priority: 2)
        ]
        
        let backup = DataSecurity.prepareForBackup(projects)
        
        XCTAssertEqual(backup.items.count, 2)
        XCTAssertEqual(backup.version, "1.0")
        XCTAssertFalse(backup.checksum.isEmpty)
        
        // Verify timestamp is recent (within last minute)
        let now = Date()
        let oneMinuteAgo = now.addingTimeInterval(-60)
        XCTAssertTrue(backup.timestamp >= oneMinuteAgo)
        XCTAssertTrue(backup.timestamp <= now)
    }
    
    func testValidateBackupSuccess() throws {
        let projects = [
            Project(name: "Backup Test", description: "Description", status: .planning, priority: 1)
        ]
        
        let backup = DataSecurity.prepareForBackup(projects)
        let result = DataSecurity.validateBackup(backup)
        
        XCTAssertTrue(result.isValid)
        XCTAssertEqual(result.items?.count, 1)
        XCTAssertEqual(result.items?.first?.name, "Backup Test")
    }
    
    func testValidateBackupFailure() throws {
        let projects = [
            Project(name: "Backup Test", description: "Description", status: .planning, priority: 1)
        ]
        
        // Test old backup
        let threeYearsAgo = Calendar.current.date(byAdding: .year, value: -3, to: Date())!
        let oldBackup = BackupData(
            items: projects,
            timestamp: threeYearsAgo,
            checksum: "valid_checksum",
            version: "1.0"
        )
        let result1 = DataSecurity.validateBackup(oldBackup)
        XCTAssertFalse(result1.isValid)
        XCTAssertEqual(result1.errorMessage, "Backup is too old (older than 2 years)")
        
        // Test corrupted backup (wrong checksum)
        let corruptedBackup = BackupData(
            items: projects,
            timestamp: Date(),
            checksum: "wrong_checksum",
            version: "1.0"
        )
        let result2 = DataSecurity.validateBackup(corruptedBackup)
        XCTAssertFalse(result2.isValid)
        XCTAssertEqual(result2.errorMessage, "Backup data integrity check failed")
    }
    
    // MARK: - Secure Deletion Tests
    
    func testSecureDelete() {
        let projects = [
            Project(name: "To Delete 1", description: "Description 1", status: .planning, priority: 1),
            Project(name: "To Delete 2", description: "Description 2", status: .inProgress, priority: 2)
        ]
        
        // This test mainly verifies the function runs without error
        // In a real implementation, this would test more complex cleanup logic
        DataSecurity.secureDelete(items: projects)
        
        // No assertions needed as this is primarily a logging operation in the current implementation
    }
    
    // MARK: - Edge Cases and Error Handling
    
    func testLargeDatasetHandling() throws {
        // Test with maximum allowed items
        var largeDataset: [Project] = []
        for i in 1...10000 {
            largeDataset.append(Project(name: "Project \(i)", description: "Description \(i)", status: .planning, priority: 1))
        }
        
        let exportResult = DataSecurity.validateExportRequest(itemCount: largeDataset.count)
        XCTAssertTrue(exportResult.isValid)
        
        let sanitized = DataSecurity.sanitizeForExport(largeDataset)
        XCTAssertEqual(sanitized.count, 10000)
        
        let backup = DataSecurity.prepareForBackup(largeDataset)
        XCTAssertEqual(backup.items.count, 10000)
    }
    
    func testEmptyDataHandling() {
        let emptyProjects: [Project] = []
        
        let sanitized = DataSecurity.sanitizeForExport(emptyProjects)
        XCTAssertTrue(sanitized.isEmpty)
        
        let backup = DataSecurity.prepareForBackup(emptyProjects)
        XCTAssertTrue(backup.items.isEmpty)
        XCTAssertFalse(backup.checksum.isEmpty) // Should still generate checksum for empty data
        
        DataSecurity.secureDelete(items: emptyProjects)
        // Should not crash with empty data
    }
}