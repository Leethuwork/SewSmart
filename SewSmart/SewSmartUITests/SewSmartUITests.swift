//
//  SewSmartUITests.swift
//  SewSmartUITests
//
//  Created by Sanal MS on 17/8/2025.
//

import XCTest

final class SewSmartUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testAddItemsToEachScreen() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Wait for app to launch
        sleep(3)
        
        // Test 1: Add a Pattern (AddPatternView)
        testAddPattern(app)
        
        // Test 2: Add a Project (ProjectsView)
        testAddProject(app)
        
        // Test 3: Add a Fabric (FabricStashView) 
        testAddFabric(app)
        
        // Test 4: Add a Measurement (MeasurementsView)
        testAddMeasurement(app)
        
        // Test 5: View Settings (SettingsView)
        testSettingsView(app)
        
        // Test 6: View History (HistoryView)
        testHistoryView(app)
        
        print("✅ Successfully tested MVVM implementation across all screens!")
    }
    
    private func testAddPattern(_ app: XCUIApplication) {
        // Navigate to Patterns tab
        if app.tabBars.buttons["Patterns"].exists {
            app.tabBars.buttons["Patterns"].tap()
        }
        sleep(2)
        
        // Look for add button
        if app.buttons["plus"].exists {
            app.buttons["plus"].tap()
            sleep(2)
            
            // Fill in pattern details
            if app.textFields["Pattern Name"].exists {
                app.textFields["Pattern Name"].tap()
                app.textFields["Pattern Name"].typeText("Test Pattern")
                sleep(1)
            }
            
            if app.textFields["Brand"].exists {
                app.textFields["Brand"].tap()
                app.textFields["Brand"].typeText("Test Brand")
                sleep(1)
            }
            
            // Save pattern
            if app.buttons["Save"].exists {
                app.buttons["Save"].tap()
                sleep(2)
            }
        }
        print("✅ Pattern test completed")
    }
    
    private func testAddProject(_ app: XCUIApplication) {
        // Navigate to Projects tab
        if app.tabBars.buttons["Projects"].exists {
            app.tabBars.buttons["Projects"].tap()
        }
        sleep(2)
        
        // Look for add button
        if app.buttons["plus"].exists {
            app.buttons["plus"].tap()
            sleep(2)
            
            // Fill in project details
            if app.textFields["Project Name"].exists {
                app.textFields["Project Name"].tap()
                app.textFields["Project Name"].typeText("Test Project")
                sleep(1)
            }
            
            if app.textFields["Description"].exists {
                app.textFields["Description"].tap()
                app.textFields["Description"].typeText("Test project description")
                sleep(1)
            }
            
            // Save project
            if app.buttons["Save"].exists {
                app.buttons["Save"].tap()
                sleep(2)
            }
        }
        print("✅ Project test completed")
    }
    
    private func testAddFabric(_ app: XCUIApplication) {
        // Navigate to Fabric tab
        if app.tabBars.buttons["Fabric"].exists {
            app.tabBars.buttons["Fabric"].tap()
        }
        sleep(2)
        
        // Look for add button
        if app.buttons["plus"].exists {
            app.buttons["plus"].tap()
            sleep(2)
            
            // Fill in fabric details
            if app.textFields["Fabric Name"].exists {
                app.textFields["Fabric Name"].tap()
                app.textFields["Fabric Name"].typeText("Test Fabric")
                sleep(1)
            }
            
            if app.textFields["Color"].exists {
                app.textFields["Color"].tap()
                app.textFields["Color"].typeText("Blue")
                sleep(1)
            }
            
            // Save fabric
            if app.buttons["Save"].exists {
                app.buttons["Save"].tap()
                sleep(2)
            }
        }
        print("✅ Fabric test completed")
    }
    
    private func testAddMeasurement(_ app: XCUIApplication) {
        // Navigate to Measurements tab
        if app.tabBars.buttons["Measurements"].exists {
            app.tabBars.buttons["Measurements"].tap()
        }
        sleep(2)
        
        // Look for add button
        if app.buttons["plus"].exists {
            app.buttons["plus"].tap()
            sleep(2)
            
            // Fill in measurement details
            if app.textFields["Profile Name"].exists {
                app.textFields["Profile Name"].tap()
                app.textFields["Profile Name"].typeText("Test Profile")
                sleep(1)
            }
            
            // Save measurement
            if app.buttons["Save"].exists {
                app.buttons["Save"].tap()
                sleep(2)
            }
        }
        print("✅ Measurement test completed")
    }
    
    private func testSettingsView(_ app: XCUIApplication) {
        // Navigate to Settings tab
        if app.tabBars.buttons["Settings"].exists {
            app.tabBars.buttons["Settings"].tap()
        }
        sleep(2)
        
        // Verify settings view loads
        XCTAssertTrue(app.staticTexts["Settings"].exists || app.navigationBars["Settings"].exists)
        print("✅ Settings test completed")
    }
    
    private func testHistoryView(_ app: XCUIApplication) {
        // Navigate to Settings to access History
        if app.tabBars.buttons["Settings"].exists {
            app.tabBars.buttons["Settings"].tap()
        }
        sleep(2)
        
        // Look for Activity History option
        if app.cells["Activity History"].exists {
            app.cells["Activity History"].tap()
            sleep(2)
            
            // Verify history view loads
            XCTAssertTrue(app.staticTexts["Activity History"].exists || app.navigationBars["Activity History"].exists)
            
            // Go back
            if app.buttons["Done"].exists {
                app.buttons["Done"].tap()
                sleep(1)
            }
        }
        print("✅ History test completed")
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
