import XCTest
@testable import SewSmart

final class InputValidatorTests: XCTestCase {
    
    // MARK: - Name Validation Tests
    
    func testValidateNameSuccess() {
        let validNames = [
            "John Doe",
            "Mary-Jane",
            "O'Connor",
            "Test123",
            "Project Alpha",
            "AB" // Minimum length
        ]
        
        for name in validNames {
            let result = InputValidator.validateName(name)
            XCTAssertTrue(result.isValid, "Name '\(name)' should be valid")
            XCTAssertEqual(result.getValue<String>(), name.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }
    
    func testValidateNameFailure() {
        let testCases: [(String, String)] = [
            ("", "Name cannot be empty"),
            ("   ", "Name cannot be empty"),
            ("A", "Name must be at least 2 characters long"),
            (String(repeating: "A", count: 101), "Name cannot exceed 100 characters"),
            ("Test@Name", "Name contains invalid characters"),
            ("Test#Name", "Name contains invalid characters"),
            ("Name$", "Name contains invalid characters")
        ]
        
        for (name, expectedError) in testCases {
            let result = InputValidator.validateName(name)
            XCTAssertFalse(result.isValid, "Name '\(name)' should be invalid")
            XCTAssertEqual(result.errorMessage, expectedError)
        }
    }
    
    // MARK: - Description Validation Tests
    
    func testValidateDescriptionSuccess() {
        let validDescriptions = [
            "",
            "Short description",
            String(repeating: "A", count: 500) // Maximum length
        ]
        
        for description in validDescriptions {
            let result = InputValidator.validateDescription(description)
            XCTAssertTrue(result.isValid, "Description should be valid")
        }
    }
    
    func testValidateDescriptionFailure() {
        let longDescription = String(repeating: "A", count: 501)
        let result = InputValidator.validateDescription(longDescription)
        
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Description cannot exceed 500 characters")
    }
    
    // MARK: - Notes Validation Tests
    
    func testValidateNotesSuccess() {
        let validNotes = [
            "",
            "Short note",
            String(repeating: "A", count: 1000) // Maximum length
        ]
        
        for notes in validNotes {
            let result = InputValidator.validateNotes(notes)
            XCTAssertTrue(result.isValid, "Notes should be valid")
        }
    }
    
    func testValidateNotesFailure() {
        let longNotes = String(repeating: "A", count: 1001)
        let result = InputValidator.validateNotes(longNotes)
        
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Notes cannot exceed 1000 characters")
    }
    
    // MARK: - Size Validation Tests
    
    func testValidateSizeSuccess() {
        let validSizes = [
            "XS",
            "Small",
            "Medium",
            "Large",
            "XL",
            "2XL",
            "32/34",
            "Size 10",
            "M (Medium)"
        ]
        
        for size in validSizes {
            let result = InputValidator.validateSize(size)
            XCTAssertTrue(result.isValid, "Size '\(size)' should be valid")
        }
    }
    
    func testValidateSizeFailure() {
        let testCases: [(String, String)] = [
            ("", "Size cannot be empty"),
            ("   ", "Size cannot be empty"),
            (String(repeating: "A", count: 21), "Size cannot exceed 20 characters"),
            ("Size@", "Size contains invalid characters"),
            ("Size#", "Size contains invalid characters")
        ]
        
        for (size, expectedError) in testCases {
            let result = InputValidator.validateSize(size)
            XCTAssertFalse(result.isValid, "Size '\(size)' should be invalid")
            XCTAssertEqual(result.errorMessage, expectedError)
        }
    }
    
    // MARK: - Color Validation Tests
    
    func testValidateColorSuccess() {
        let validColors = [
            "Red",
            "Blue",
            "Green Yellow",
            "Navy-Blue",
            "Light Purple"
        ]
        
        for color in validColors {
            let result = InputValidator.validateColor(color)
            XCTAssertTrue(result.isValid, "Color '\(color)' should be valid")
        }
    }
    
    func testValidateColorFailure() {
        let testCases: [(String, String)] = [
            ("", "Color cannot be empty"),
            ("   ", "Color cannot be empty"),
            (String(repeating: "A", count: 51), "Color name cannot exceed 50 characters"),
            ("Red123", "Color contains invalid characters"),
            ("Blue@", "Color contains invalid characters")
        ]
        
        for (color, expectedError) in testCases {
            let result = InputValidator.validateColor(color)
            XCTAssertFalse(result.isValid, "Color '\(color)' should be invalid")
            XCTAssertEqual(result.errorMessage, expectedError)
        }
    }
    
    // MARK: - Quantity Validation Tests
    
    func testValidateQuantitySuccess() {
        let validQuantities: [Double] = [0.0, 0.5, 1.0, 10.5, 100.123, 9999.999]
        
        for quantity in validQuantities {
            let result = InputValidator.validateQuantity(quantity)
            XCTAssertTrue(result.isValid, "Quantity \(quantity) should be valid")
            XCTAssertEqual(result.getValue<Double>(), quantity)
        }
    }
    
    func testValidateQuantityFailure() {
        let testCases: [(Double, String)] = [
            (-1.0, "Quantity cannot be negative"),
            (-0.1, "Quantity cannot be negative"),
            (10001.0, "Quantity cannot exceed 10,000"),
            (1.1234, "Quantity can have at most 3 decimal places")
        ]
        
        for (quantity, expectedError) in testCases {
            let result = InputValidator.validateQuantity(quantity)
            XCTAssertFalse(result.isValid, "Quantity \(quantity) should be invalid")
            XCTAssertEqual(result.errorMessage, expectedError)
        }
    }
    
    // MARK: - Cost Validation Tests
    
    func testValidateCostSuccess() {
        let validCosts: [Double] = [0.0, 0.99, 1.00, 10.50, 99999.99]
        
        for cost in validCosts {
            let result = InputValidator.validateCost(cost)
            XCTAssertTrue(result.isValid, "Cost \(cost) should be valid")
            XCTAssertEqual(result.getValue<Double>(), cost)
        }
    }
    
    func testValidateCostFailure() {
        let testCases: [(Double, String)] = [
            (-1.0, "Cost cannot be negative"),
            (-0.01, "Cost cannot be negative"),
            (100001.0, "Cost cannot exceed $100,000"),
            (1.123, "Cost can have at most 2 decimal places")
        ]
        
        for (cost, expectedError) in testCases {
            let result = InputValidator.validateCost(cost)
            XCTAssertFalse(result.isValid, "Cost \(cost) should be invalid")
            XCTAssertEqual(result.errorMessage, expectedError)
        }
    }
    
    // MARK: - Progress Validation Tests
    
    func testValidateProgressSuccess() {
        let validProgress: [Double] = [0.0, 0.25, 0.5, 0.75, 1.0]
        
        for progress in validProgress {
            let result = InputValidator.validateProgress(progress)
            XCTAssertTrue(result.isValid, "Progress \(progress) should be valid")
            XCTAssertEqual(result.getValue<Double>(), progress)
        }
    }
    
    func testValidateProgressFailure() {
        let testCases: [(Double, String)] = [
            (-0.1, "Progress cannot be negative"),
            (1.1, "Progress cannot exceed 100%"),
            (2.0, "Progress cannot exceed 100%")
        ]
        
        for (progress, expectedError) in testCases {
            let result = InputValidator.validateProgress(progress)
            XCTAssertFalse(result.isValid, "Progress \(progress) should be invalid")
            XCTAssertEqual(result.errorMessage, expectedError)
        }
    }
    
    // MARK: - Priority Validation Tests
    
    func testValidatePrioritySuccess() {
        let validPriorities = [0, 1, 5, 10]
        
        for priority in validPriorities {
            let result = InputValidator.validatePriority(priority)
            XCTAssertTrue(result.isValid, "Priority \(priority) should be valid")
            XCTAssertEqual(result.getValue<Int>(), priority)
        }
    }
    
    func testValidatePriorityFailure() {
        let testCases: [(Int, String)] = [
            (-1, "Priority cannot be negative"),
            (11, "Priority cannot exceed 10")
        ]
        
        for (priority, expectedError) in testCases {
            let result = InputValidator.validatePriority(priority)
            XCTAssertFalse(result.isValid, "Priority \(priority) should be invalid")
            XCTAssertEqual(result.errorMessage, expectedError)
        }
    }
    
    // MARK: - Date Validation Tests
    
    func testValidateDueDateSuccess() {
        let calendar = Calendar.current
        let now = Date()
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
        let nextYear = calendar.date(byAdding: .year, value: 1, to: now)!
        
        let validDates: [Date?] = [nil, tomorrow, nextYear]
        
        for date in validDates {
            let result = InputValidator.validateDueDate(date)
            XCTAssertTrue(result.isValid, "Date should be valid")
        }
    }
    
    func testValidateDueDateFailure() {
        let calendar = Calendar.current
        let now = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
        let elevenYearsFromNow = calendar.date(byAdding: .year, value: 11, to: now)!
        
        let testCases: [(Date, String)] = [
            (yesterday, "Due date cannot be in the past"),
            (elevenYearsFromNow, "Due date cannot be more than 10 years in the future")
        ]
        
        for (date, expectedError) in testCases {
            let result = InputValidator.validateDueDate(date)
            XCTAssertFalse(result.isValid, "Date should be invalid")
            XCTAssertEqual(result.errorMessage, expectedError)
        }
    }
    
    // MARK: - Sanitization Tests
    
    func testSanitizeInput() {
        let testCases: [(String, String)] = [
            ("  Hello World  ", "Hello World"),
            ("Hello\tWorld", "Hello World"),
            ("Hello\r\nWorld", "Hello\nWorld"),
            ("Multiple   Spaces", "Multiple Spaces"),
            ("  \n  Line  \n  ", "Line"),
            ("\t\r\n", "")
        ]
        
        for (input, expected) in testCases {
            let result = InputValidator.sanitize(input)
            XCTAssertEqual(result, expected, "Sanitization failed for '\(input)'")
        }
    }
    
    func testSanitizeForStorage() {
        let longString = String(repeating: "A", count: 1500)
        let result = InputValidator.sanitizeForStorage(longString, maxLength: 1000)
        
        XCTAssertEqual(result.count, 1000)
        XCTAssertTrue(result.allSatisfy { $0 == "A" })
    }
    
    // MARK: - Security Tests
    
    func testContainsSuspiciousContent() {
        let suspiciousInputs = [
            "<script>alert('xss')</script>",
            "javascript:alert('xss')",
            "data:text/html,<script>alert('xss')</script>",
            "vbscript:alert('xss')",
            "onclick=alert('xss')",
            "exec('rm -rf /')",
            "eval(userInput)",
            "DROP TABLE users",
            "UNION SELECT password FROM users",
            "INSERT INTO users VALUES",
            "DELETE FROM users WHERE"
        ]
        
        for input in suspiciousInputs {
            XCTAssertTrue(InputValidator.containsSuspiciousContent(input), 
                         "Should detect suspicious content in: '\(input)'")
        }
    }
    
    func testSafeContent() {
        let safeInputs = [
            "Hello World",
            "This is a normal description",
            "Project with numbers 123",
            "Email: user@example.com",
            "URL: https://example.com",
            "Normal text with punctuation!"
        ]
        
        for input in safeInputs {
            XCTAssertFalse(InputValidator.containsSuspiciousContent(input), 
                          "Should not detect suspicious content in: '\(input)'")
        }
    }
    
    func testValidateSecureInput() {
        let result1 = InputValidator.validateSecureInput("Safe input")
        XCTAssertTrue(result1.isValid)
        XCTAssertEqual(result1.getValue<String>(), "Safe input")
        
        let result2 = InputValidator.validateSecureInput("<script>alert('xss')</script>")
        XCTAssertFalse(result2.isValid)
        XCTAssertEqual(result2.errorMessage, "Input contains potentially harmful content")
    }
}