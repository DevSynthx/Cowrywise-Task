//
//  Cowrywise_TaskUITests.swift
//  Cowrywise-TaskUITests

import XCTest

final class Cowrywise_TaskUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
        
        XCTAssertTrue(app.staticTexts["EUR"].waitForExistence(timeout: 10),
                     "App should load with EUR as base currency")
        
        print("🚀 App launched successfully with EUR as base currency")
    }
    
    override func tearDownWithError() throws {
        app.terminate()
        app = nil
    }
    
    // MARK: - Complete User Journey Test
    
    func testCompleteUserJourneyEndToEnd() throws {
        print("🎯 Starting complete user journey test...")
        let currency = "USD"
        
        // Verify initial app state
        verifyInitialAppState()
        
        // Select currency
        selectCurrency(currency)
        
        // Perform conversion
        performInitialConversion(currency: currency)
        
        // Enter amount and verify real-time conversion
        enterAmountAndVerifyConversion(amount: "10000", currency: currency)
        
        print("✅ Complete user journey test completed successfully!")
    }
    
    // MARK: - Verify Initial App State
    
    private func verifyInitialAppState() {
        
        // Verify EUR is shown as base currency
        let eurLabel = app.staticTexts["EUR"]
        XCTAssertTrue(eurLabel.exists, "EUR should be visible as base currency")
        
        // Verify "From" currency button shows EUR flag and code
        let fromCurrencyButton = app.buttons["fromCurrencyButton"]
        XCTAssertTrue(fromCurrencyButton.exists, "From currency button should exist")
        
        // Verify "To" currency shows "Select" initially
        let toCurrencyButton = app.buttons["toCurrencyButton"]
        XCTAssertTrue(toCurrencyButton.exists, "To currency button should exist")
        
        // Verify essential UI elements exist
        let amountTextField = app.textFields["amountTextField"]
        XCTAssertTrue(amountTextField.exists, "Amount text field should exist")
        
        let convertButton = app.buttons["convertButton"]
        XCTAssertTrue(convertButton.exists, "Convert button should exist")
        
        // Verify initial converted amount is 0.00
        let convertedAmountLabel = app.staticTexts["convertedAmountLabel"]
        XCTAssertTrue(convertedAmountLabel.exists, "Converted amount label should exist")
        XCTAssertEqual(convertedAmountLabel.label, "0.00", "Initial converted amount should be 0.00")
        
        // Verify convert button is initially disabled
        XCTAssertFalse(convertButton.isEnabled, "Convert button should be disabled initially")
        
        print("✅ Initial app state verified successfully")
    }
    
    // MARK: - Select Currency
    
    private func selectCurrency(_ currency: String) {
        
        // Tap the "To" currency button to open bottom sheet
        let toCurrencyButton = app.buttons.containing(.staticText, identifier: "Select").element
        XCTAssertTrue(toCurrencyButton.exists, "To currency button (Select) should exist")
        
        toCurrencyButton.tap()
        
        // Wait for bottom sheet to appear
        let bottomSheetTitle = app.staticTexts["bottomSheetTitle"]
        XCTAssertTrue(bottomSheetTitle.waitForExistence(timeout: 7),
                     "Currency selection bottom sheet should appear")
        
        
        // Look for currency in the currency list
        let currencyCell = app.cells.containing(.staticText, identifier: currency).element
        
        if currencyCell.waitForExistence(timeout: 3) {
            print("   👀 Found \(currency) in currency list")
            currencyCell.tap()
        } else {
            // If currency is not immediately visible, try using search
            print(" 🔍 \(currency) not immediately visible, using search...")
            
            let searchField = app.textFields["Search currencies..."]
            XCTAssertTrue(searchField.waitForExistence(timeout: 3), "Search field should appear")
            
            searchField.tap()
            searchField.typeText("\(currency)")
            
            // Wait for filtered results
            let filteredCell = app.cells.containing(.staticText, identifier: currency).element
            XCTAssertTrue(filteredCell.waitForExistence(timeout: 3),
                         "\(currency) should appear in search results")
            
            print("🎯 Found \(currency) in search results")
            filteredCell.tap()
        }
        
        // Verify currency was selected (bottom sheet should dismiss and currency should be shown)
        XCTAssertTrue(app.staticTexts["\(currency)"].waitForExistence(timeout: 5),
                     "\(currency) should be selected and visible")
        
        // Verify bottom sheet is dismissed
        XCTAssertFalse(bottomSheetTitle.exists, "Bottom sheet should be dismissed after selection")
        
        // Verify "To" currency label shows
        let toCurrencyLabel = app.staticTexts["currencyToLabel"]
        XCTAssertEqual(toCurrencyLabel.label, "\(currency)", "To currency label should show \(currency)")
        
        // Verify convert button is now enabled
        let convertButton = app.buttons.containing(.staticText, identifier: "Convert").element
        XCTAssertTrue(convertButton.isEnabled, "Convert button should be enabled after selecting currency")
        
        print("✅ \(currency) selected successfully")
    }
    
    // MARK: - Perform Initial Conversion
    
    private func performInitialConversion(currency: String) {
        
        let convertButton = app.buttons["convertButton"]
        XCTAssertTrue(convertButton.isEnabled, "Convert button should be enabled")
        
        convertButton.tap()
        
        // The exchange rate label should update to show the rate
        let exchangeRateLabel = app.staticTexts["exchangeRateLabel"]
        
        // Wait for exchange rate to be established
        let rateEstablished = waitForExchangeRateToBeEstablished(timeout: 15, currency: currency)
        XCTAssertTrue(rateEstablished, "Exchange rate should be established within 15 seconds")
        
        // Get the exchange rate text for verification
        let rateText = exchangeRateLabel.label
        XCTAssertTrue(rateText.contains("EUR"), "Exchange rate should mention EUR")
        XCTAssertTrue(rateText.contains(currency), "Exchange rate should mention \(currency)")
        
        print("✅ Initial conversion completed - Exchange rate: \(rateText)")
    }
    
    // MARK: - Step 4: Enter Amount and Verify Real-time Conversion
    
    private func enterAmountAndVerifyConversion(amount: String, currency: String) {
        
        let amountField = app.textFields["amountTextField"]
        XCTAssertTrue(amountField.exists, "Amount text field should exist")
        
        amountField.tap()
        
        // Enter  amount
        let testAmount = amount
        print("⌨️ Entering amount: \(testAmount)")
        
        amountField.typeText(testAmount)
        
        // Wait a moment for real-time conversion to process
        Thread.sleep(forTimeInterval: 1.0)
        
        // Check for real-time conversion
        let convertedAmountLabel = app.staticTexts["convertedAmountLabel"]
        let currentResult = convertedAmountLabel.label
        
        // Should not be 0.00 if exchange rate is established
        if currentResult != "0.00" {
            print("✨ Real-time conversion working: \(currentResult) \(currency)")
        }
        
        // Verify the amount field shows formatted text
        let finalFieldValue = amountField.value as? String ?? ""
        
        // For large numbers, should have comma formatting
        if testAmount.count >= 4 { // 4 or more digits should get comma formatting
            XCTAssertTrue(finalFieldValue.contains(","),
                          "Large amounts should be formatted with commas. Actual: '\(finalFieldValue)'")
            print("   📝 Amount formatted with commas: \(finalFieldValue)")
        }
        
        print("✅ Amount '\(testAmount)' entered successfully, field shows: '\(finalFieldValue)'")
    }

    
    // MARK: - Helper Methods
    
    private func waitForExchangeRateToBeEstablished(timeout: TimeInterval, currency: String) -> Bool {
        let startTime = Date()
        let exchangeRateLabel = app.staticTexts["exchangeRateLabel"]
        
        while Date().timeIntervalSince(startTime) < timeout {
            let currentText = exchangeRateLabel.label
            
            // Check if the text contains both currencies (indicating rate is established)
            if currentText.contains("EUR") && currentText.contains(currency) && !currentText.contains("Select target") {
                return true
            }
            
            Thread.sleep(forTimeInterval: 0.5)
        }
        
        return false
    }
    
}


