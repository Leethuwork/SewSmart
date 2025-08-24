import Foundation

/// Comprehensive input validation utility
struct InputValidator {
    
    // MARK: - String Validation
    
    static func validateName(_ name: String) -> ValidationResult {
        let trimmedName = sanitize(name)
        
        guard !trimmedName.isEmpty else {
            return .invalid("Name cannot be empty")
        }
        
        guard trimmedName.count >= 2 else {
            return .invalid("Name must be at least 2 characters long")
        }
        
        guard trimmedName.count <= 100 else {
            return .invalid("Name cannot exceed 100 characters")
        }
        
        // Check for valid characters (letters, numbers, spaces, hyphens, apostrophes)
        let allowedCharacterSet = CharacterSet.alphanumerics
            .union(.whitespaces)
            .union(CharacterSet(charactersIn: "-'"))
        
        guard trimmedName.unicodeScalars.allSatisfy(allowedCharacterSet.contains) else {
            return .invalid("Name contains invalid characters")
        }
        
        return .valid(trimmedName)
    }
    
    static func validateDescription(_ description: String) -> ValidationResult {
        let trimmedDescription = sanitize(description)
        
        guard trimmedDescription.count <= 500 else {
            return .invalid("Description cannot exceed 500 characters")
        }
        
        return .valid(trimmedDescription)
    }
    
    static func validateNotes(_ notes: String) -> ValidationResult {
        let trimmedNotes = sanitize(notes)
        
        guard trimmedNotes.count <= 1000 else {
            return .invalid("Notes cannot exceed 1000 characters")
        }
        
        return .valid(trimmedNotes)
    }
    
    static func validateSize(_ size: String) -> ValidationResult {
        let trimmedSize = sanitize(size)
        
        guard !trimmedSize.isEmpty else {
            return .invalid("Size cannot be empty")
        }
        
        guard trimmedSize.count <= 20 else {
            return .invalid("Size cannot exceed 20 characters")
        }
        
        // Allow alphanumeric characters, spaces, hyphens, and common size indicators
        let allowedCharacterSet = CharacterSet.alphanumerics
            .union(.whitespaces)
            .union(CharacterSet(charactersIn: "-/()"))
        
        guard trimmedSize.unicodeScalars.allSatisfy(allowedCharacterSet.contains) else {
            return .invalid("Size contains invalid characters")
        }
        
        return .valid(trimmedSize)
    }
    
    static func validateColor(_ color: String) -> ValidationResult {
        let trimmedColor = sanitize(color)
        
        guard !trimmedColor.isEmpty else {
            return .invalid("Color cannot be empty")
        }
        
        guard trimmedColor.count <= 50 else {
            return .invalid("Color name cannot exceed 50 characters")
        }
        
        // Allow letters, spaces, hyphens for color descriptions
        let allowedCharacterSet = CharacterSet.letters
            .union(.whitespaces)
            .union(CharacterSet(charactersIn: "-"))
        
        guard trimmedColor.unicodeScalars.allSatisfy(allowedCharacterSet.contains) else {
            return .invalid("Color contains invalid characters")
        }
        
        return .valid(trimmedColor)
    }
    
    // MARK: - Numeric Validation
    
    static func validateQuantity(_ quantity: Double) -> ValidationResult {
        guard quantity >= 0 else {
            return .invalid("Quantity cannot be negative")
        }
        
        guard quantity <= 10000 else {
            return .invalid("Quantity cannot exceed 10,000")
        }
        
        // Check for reasonable precision (max 3 decimal places)
        let rounded = (quantity * 1000).rounded() / 1000
        guard abs(quantity - rounded) < 0.0001 else {
            return .invalid("Quantity can have at most 3 decimal places")
        }
        
        return .valid(quantity)
    }
    
    static func validateCost(_ cost: Double) -> ValidationResult {
        guard cost >= 0 else {
            return .invalid("Cost cannot be negative")
        }
        
        guard cost <= 100000 else {
            return .invalid("Cost cannot exceed $100,000")
        }
        
        // Check for reasonable precision (max 2 decimal places for currency)
        let rounded = (cost * 100).rounded() / 100
        guard abs(cost - rounded) < 0.001 else {
            return .invalid("Cost can have at most 2 decimal places")
        }
        
        return .valid(cost)
    }
    
    static func validateProgress(_ progress: Double) -> ValidationResult {
        guard progress >= 0.0 else {
            return .invalid("Progress cannot be negative")
        }
        
        guard progress <= 1.0 else {
            return .invalid("Progress cannot exceed 100%")
        }
        
        return .valid(progress)
    }
    
    static func validatePriority(_ priority: Int) -> ValidationResult {
        guard priority >= 0 else {
            return .invalid("Priority cannot be negative")
        }
        
        guard priority <= 10 else {
            return .invalid("Priority cannot exceed 10")
        }
        
        return .valid(priority)
    }
    
    // MARK: - Date Validation
    
    static func validateDueDate(_ date: Date?) -> ValidationResult {
        guard let date = date else {
            return .valid("")
        }
        
        let now = Date()
        let calendar = Calendar.current
        let tenYearsFromNow = calendar.date(byAdding: .year, value: 10, to: now) ?? now
        
        guard date >= now else {
            return .invalid("Due date cannot be in the past")
        }
        
        guard date <= tenYearsFromNow else {
            return .invalid("Due date cannot be more than 10 years in the future")
        }
        
        return .valid(date)
    }
    
    // MARK: - Input Sanitization
    
    static func sanitize(_ input: String) -> String {
        return input
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\t", with: " ")  // Replace tabs with spaces
            .replacingOccurrences(of: "\r", with: "")   // Remove carriage returns
            .components(separatedBy: .newlines)         // Split by newlines
            .map { $0.trimmingCharacters(in: .whitespaces) } // Trim each line
            .joined(separator: "\n")                    // Rejoin with clean newlines
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression) // Normalize multiple spaces
    }
    
    static func sanitizeForStorage(_ input: String, maxLength: Int = 1000) -> String {
        let sanitized = sanitize(input)
        
        if sanitized.count > maxLength {
            let endIndex = sanitized.index(sanitized.startIndex, offsetBy: maxLength)
            return String(sanitized[..<endIndex])
        }
        
        return sanitized
    }
    
    // MARK: - Security Validation
    
    static func containsSuspiciousContent(_ input: String) -> Bool {
        let suspiciousPatterns = [
            "<script",
            "javascript:",
            "data:text/html",
            "vbscript:",
            "on\\w+\\s*=",  // Event handlers like onclick=
            "\\bexec\\b",
            "\\beval\\b",
            "\\bdrop\\s+table\\b",
            "\\bunion\\s+select\\b",
            "\\binsert\\s+into\\b",
            "\\bdelete\\s+from\\b"
        ]
        
        let lowercaseInput = input.lowercased()
        
        for pattern in suspiciousPatterns {
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
                let range = NSRange(location: 0, length: input.utf16.count)
                if regex.firstMatch(in: input, options: [], range: range) != nil {
                    return true
                }
            } catch {
                // If regex compilation fails, skip this pattern
                continue
            }
        }
        
        return false
    }
    
    static func validateSecureInput(_ input: String) -> ValidationResult {
        let sanitized = sanitize(input)
        
        guard !containsSuspiciousContent(sanitized) else {
            return .invalid("Input contains potentially harmful content")
        }
        
        return .valid(sanitized)
    }
}

// MARK: - ValidationResult

enum ValidationResult: Equatable {
    case valid(Any)
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
    
    func getValue<T>() -> T? {
        switch self {
        case .valid(let value): return value as? T
        case .invalid: return nil
        }
    }
    
    static func == (lhs: ValidationResult, rhs: ValidationResult) -> Bool {
        switch (lhs, rhs) {
        case (.valid, .valid): return true
        case (.invalid(let lhsMessage), .invalid(let rhsMessage)): return lhsMessage == rhsMessage
        default: return false
        }
    }
}

// MARK: - Model Extensions

extension Project {
    func validate() -> [ValidationResult] {
        var results: [ValidationResult] = []
        
        results.append(InputValidator.validateName(name))
        results.append(InputValidator.validateDescription(projectDescription))
        results.append(InputValidator.validateNotes(notes ?? ""))
        results.append(InputValidator.validateProgress(progress))
        results.append(InputValidator.validatePriority(priority))
        results.append(InputValidator.validateDueDate(dueDate))
        
        return results
    }
    
    var isValid: Bool {
        return validate().allSatisfy { $0.isValid }
    }
    
    var validationErrors: [String] {
        return validate().compactMap { $0.errorMessage }
    }
}

extension Pattern {
    func validate() -> [ValidationResult] {
        var results: [ValidationResult] = []
        
        results.append(InputValidator.validateName(name))
        results.append(InputValidator.validateDescription(notes))
        results.append(InputValidator.validateName(brand))
        
        return results
    }
    
    var isValid: Bool {
        return validate().allSatisfy { $0.isValid }
    }
    
    var validationErrors: [String] {
        return validate().compactMap { $0.errorMessage }
    }
}

extension Fabric {
    func validate() -> [ValidationResult] {
        var results: [ValidationResult] = []
        
        results.append(InputValidator.validateName(name))
        results.append(InputValidator.validateColor(color))
        results.append(InputValidator.validateQuantity(yardage))
        results.append(InputValidator.validateCost(cost))
        results.append(InputValidator.validateNotes(notes))
        
        return results
    }
    
    var isValid: Bool {
        return validate().allSatisfy { $0.isValid }
    }
    
    var validationErrors: [String] {
        return validate().compactMap { $0.errorMessage }
    }
}