import Testing
import Foundation
@testable import SewSmart

struct MeasurementProfileTests {
    
    @Test func testMeasurementProfileInitialization() {
        let profile = MeasurementProfile(name: "Test Profile", isDefault: true)
        
        #expect(profile.name == "Test Profile")
        #expect(profile.isDefault == true)
        #expect(profile.notes == "")
        #expect(profile.measurements.isEmpty)
    }
    
    @Test func testMeasurementProfileInitializationWithDefaults() {
        let profile = MeasurementProfile(name: "Default Profile")
        
        #expect(profile.name == "Default Profile")
        #expect(profile.isDefault == false)
        #expect(profile.notes == "")
        #expect(profile.measurements.isEmpty)
    }
    
    @Test func testMeasurementProfileIdUniqueness() {
        let profile1 = MeasurementProfile(name: "Profile 1")
        let profile2 = MeasurementProfile(name: "Profile 2")
        
        #expect(profile1.id != profile2.id)
    }
    
    @Test func testMeasurementProfileCreatedDateIsSet() {
        let beforeCreation = Date()
        let profile = MeasurementProfile(name: "Test Profile")
        let afterCreation = Date()
        
        #expect(profile.createdDate >= beforeCreation)
        #expect(profile.createdDate <= afterCreation)
    }
    
    @Test func testMeasurementProfilePropertyModification() {
        let profile = MeasurementProfile(name: "Original Name", isDefault: false)
        
        profile.name = "Updated Name"
        profile.isDefault = true
        profile.notes = "Updated notes"
        
        #expect(profile.name == "Updated Name")
        #expect(profile.isDefault == true)
        #expect(profile.notes == "Updated notes")
    }
    
    @Test func testMeasurementProfileWithMeasurements() {
        let profile = MeasurementProfile(name: "Test Profile")
        let measurement1 = Measurement(name: "Chest", value: 38.0, unit: .inches, category: .body)
        let measurement2 = Measurement(name: "Waist", value: 32.0, unit: .inches, category: .body)
        
        // Initially empty
        #expect(profile.measurements.isEmpty)
        
        // Add measurements (Note: In real SwiftData usage, this would be managed by the context)
        profile.measurements.append(measurement1)
        profile.measurements.append(measurement2)
        measurement1.profile = profile
        measurement2.profile = profile
        
        #expect(profile.measurements.count == 2)
        #expect(profile.measurements.contains { $0.name == "Chest" })
        #expect(profile.measurements.contains { $0.name == "Waist" })
    }
}

struct MeasurementTests {
    
    @Test func testMeasurementInitialization() {
        let measurement = Measurement(
            name: "Bust",
            value: 36.5,
            unit: .inches,
            category: .body
        )
        
        #expect(measurement.name == "Bust")
        #expect(measurement.value == 36.5)
        #expect(measurement.unit == .inches)
        #expect(measurement.category == .body)
        #expect(measurement.profile == nil)
    }
    
    @Test func testMeasurementInitializationWithDefaults() {
        let measurement = Measurement(name: "Test Measurement")
        
        #expect(measurement.name == "Test Measurement")
        #expect(measurement.value == 0)
        #expect(measurement.unit == .inches)
        #expect(measurement.category == .body)
        #expect(measurement.profile == nil)
    }
    
    @Test func testMeasurementIdUniqueness() {
        let measurement1 = Measurement(name: "Measurement 1")
        let measurement2 = Measurement(name: "Measurement 2")
        
        #expect(measurement1.id != measurement2.id)
    }
    
    @Test func testMeasurementCreatedDateIsSet() {
        let beforeCreation = Date()
        let measurement = Measurement(name: "Test Measurement")
        let afterCreation = Date()
        
        #expect(measurement.createdDate >= beforeCreation)
        #expect(measurement.createdDate <= afterCreation)
    }
    
    @Test func testMeasurementPropertyModification() {
        let measurement = Measurement(name: "Original Name", value: 10.0, unit: .inches, category: .body)
        
        measurement.name = "Updated Name"
        measurement.value = 15.5
        measurement.unit = .centimeters
        measurement.category = .garment
        
        #expect(measurement.name == "Updated Name")
        #expect(measurement.value == 15.5)
        #expect(measurement.unit == .centimeters)
        #expect(measurement.category == .garment)
    }
    
    @Test func testMeasurementWithProfile() {
        let profile = MeasurementProfile(name: "Test Profile")
        let measurement = Measurement(name: "Hip", value: 40.0, unit: .inches, category: .body)
        
        #expect(measurement.profile == nil)
        
        measurement.profile = profile
        
        #expect(measurement.profile?.name == "Test Profile")
    }
    
    @Test func testMeasurementWithDifferentUnits() {
        let inchMeasurement = Measurement(name: "Length", value: 12.0, unit: .inches, category: .garment)
        let cmMeasurement = Measurement(name: "Width", value: 30.0, unit: .centimeters, category: .garment)
        
        #expect(inchMeasurement.unit == .inches)
        #expect(inchMeasurement.value == 12.0)
        #expect(cmMeasurement.unit == .centimeters)
        #expect(cmMeasurement.value == 30.0)
    }
    
    @Test func testMeasurementWithDifferentCategories() {
        let bodyMeasurement = Measurement(name: "Chest", value: 38.0, unit: .inches, category: .body)
        let garmentMeasurement = Measurement(name: "Sleeve Length", value: 24.0, unit: .inches, category: .garment)
        let fitMeasurement = Measurement(name: "Ease", value: 2.0, unit: .inches, category: .fit)
        
        #expect(bodyMeasurement.category == .body)
        #expect(garmentMeasurement.category == .garment)
        #expect(fitMeasurement.category == .fit)
    }
}

struct MeasurementUnitTests {
    
    @Test func testMeasurementUnitRawValues() {
        #expect(MeasurementUnit.inches.rawValue == "inches")
        #expect(MeasurementUnit.centimeters.rawValue == "cm")
    }
    
    @Test func testMeasurementUnitAbbreviations() {
        #expect(MeasurementUnit.inches.abbreviation == "in")
        #expect(MeasurementUnit.centimeters.abbreviation == "cm")
    }
    
    @Test func testMeasurementUnitAllCases() {
        let allCases = MeasurementUnit.allCases
        
        #expect(allCases.count == 2)
        #expect(allCases.contains(.inches))
        #expect(allCases.contains(.centimeters))
    }
    
    @Test func testMeasurementUnitCodable() throws {
        let unit = MeasurementUnit.inches
        
        // Test encoding
        let encoder = JSONEncoder()
        let encodedData = try encoder.encode(unit)
        
        // Test decoding
        let decoder = JSONDecoder()
        let decodedUnit = try decoder.decode(MeasurementUnit.self, from: encodedData)
        
        #expect(decodedUnit == .inches)
    }
    
    @Test func testMeasurementUnitInitFromRawValue() {
        #expect(MeasurementUnit(rawValue: "inches") == .inches)
        #expect(MeasurementUnit(rawValue: "cm") == .centimeters)
        #expect(MeasurementUnit(rawValue: "invalid") == nil)
    }
    
    @Test func testMeasurementUnitEquality() {
        #expect(MeasurementUnit.inches == MeasurementUnit.inches)
        #expect(MeasurementUnit.inches != MeasurementUnit.centimeters)
    }
}

struct MeasurementCategoryTests {
    
    @Test func testMeasurementCategoryRawValues() {
        #expect(MeasurementCategory.body.rawValue == "Body")
        #expect(MeasurementCategory.garment.rawValue == "Garment")
        #expect(MeasurementCategory.fit.rawValue == "Fit Preferences")
    }
    
    @Test func testMeasurementCategoryAllCases() {
        let allCases = MeasurementCategory.allCases
        
        #expect(allCases.count == 3)
        #expect(allCases.contains(.body))
        #expect(allCases.contains(.garment))
        #expect(allCases.contains(.fit))
    }
    
    @Test func testMeasurementCategoryCodable() throws {
        let category = MeasurementCategory.body
        
        // Test encoding
        let encoder = JSONEncoder()
        let encodedData = try encoder.encode(category)
        
        // Test decoding
        let decoder = JSONDecoder()
        let decodedCategory = try decoder.decode(MeasurementCategory.self, from: encodedData)
        
        #expect(decodedCategory == .body)
    }
    
    @Test func testMeasurementCategoryInitFromRawValue() {
        #expect(MeasurementCategory(rawValue: "Body") == .body)
        #expect(MeasurementCategory(rawValue: "Garment") == .garment)
        #expect(MeasurementCategory(rawValue: "Fit Preferences") == .fit)
        #expect(MeasurementCategory(rawValue: "invalid") == nil)
    }
    
    @Test func testMeasurementCategoryEquality() {
        #expect(MeasurementCategory.body == MeasurementCategory.body)
        #expect(MeasurementCategory.body != MeasurementCategory.garment)
    }
    
    @Test func testMeasurementCategoryStringRepresentation() {
        #expect("\(MeasurementCategory.body)" == "body")
        #expect("\(MeasurementCategory.garment)" == "garment")
        #expect("\(MeasurementCategory.fit)" == "fit")
    }
}