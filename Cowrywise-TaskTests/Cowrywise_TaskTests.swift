//
//  Cowrywise_TaskTests.swift
//  Cowrywise-TaskTests
//



import XCTest
import PromiseKit
import RealmSwift


@testable import Cowrywise_Task

class Cowrywise_TaskTests: XCTestCase {
    
    var apiService: CurrencyAPIService!
    var testRealm: Realm!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // in-memory Realm for testing
        let config = Realm.Configuration(
            inMemoryIdentifier: "TestRealm",
            deleteRealmIfMigrationNeeded: true
        )
        testRealm = try Realm(configuration: config)
        
        apiService = CurrencyAPIService.shared
        apiService.clearCache() // Clear any existing cache
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
        testRealm = nil
        apiService = nil
    }
    
    // MARK: - Currency Model Tests
    
    func testCurrencyModelInitialization() {
        // Given
        let code = "USD"
        let name = "US Dollar"
        let flag = "🇺🇸"
        
        // When
        let currency = Currency(code: code, name: name, flag: flag)
        
        // Then
        XCTAssertEqual(currency.code, code)
        XCTAssertEqual(currency.name, name)
        XCTAssertEqual(currency.flag, flag)
    }
    
    // MARK: - API Error Tests
    
    func testAPIErrorFromHTTPStatusCode() {
        // Test 400 Bad Request
        let badRequestError = APIError.fromHTTPStatusCode(400, endpoint: "latest")
        XCTAssertEqual(badRequestError.localizedDescription, "Invalid request to latest. Please try again.")
        
        // Test 401 Unauthorized
        let unauthorizedError = APIError.fromHTTPStatusCode(401)
        XCTAssertEqual(unauthorizedError.localizedDescription, "Authentication failed. The currency service is temporarily unavailable.")
        
        // Test 403 Forbidden
        let forbiddenError = APIError.fromHTTPStatusCode(403)
        XCTAssertEqual(forbiddenError.localizedDescription, "Access denied to the currency service. Please try again later.")
        
        // Test 404 Not Found
        let notFoundError = APIError.fromHTTPStatusCode(404, message: "currency")
        XCTAssertEqual(notFoundError.localizedDescription, "The requested currency could not be found.")
        
        // Test 429 Too Many Requests
        let tooManyRequestsError = APIError.fromHTTPStatusCode(429)
        XCTAssertEqual(tooManyRequestsError.localizedDescription, "Service is busy. Please wait a moment and try again.")
    }
    
    func testAPIErrorFromAPIResponse() {
        // Test rate limit exceeded
        let rateLimitError = APIError.fromAPIResponse(code: 104)
        XCTAssertEqual(rateLimitError.localizedDescription, "Too many requests have been made. Please wait a moment and try again.")
        
        // Test base currency access restricted
        let baseRestrictedError = APIError.fromAPIResponse(code: 105)
        XCTAssertEqual(baseRestrictedError.localizedDescription, "This conversion feature is temporarily unavailable. Please try again later.")
        
        // Test invalid base currency
        let invalidBaseError = APIError.fromAPIResponse(code: 601)
        XCTAssertEqual(invalidBaseError.localizedDescription, "The selected base currency is not supported. Please choose a different currency.")
        
        // Test invalid symbols
        let invalidSymbolsError = APIError.fromAPIResponse(code: 602)
        XCTAssertEqual(invalidSymbolsError.localizedDescription, "One or more selected currencies are not supported. Please check your currency selection.")
        
        // Test weekend markets closed
        let weekendError = APIError.fromAPIResponse(code: 606)
        XCTAssertEqual(weekendError.localizedDescription, "Currency markets are closed over the weekend. Please try again during business hours.")
    }
    
    // MARK: - Currency Rate Caching Tests
    
    func testCurrencyRateCaching() throws {
        // Given
        let fromCurrency = "EUR"
        let toCurrency = "USD"
        let rate = 1.0856
        let key = "\(fromCurrency)_\(toCurrency)"
        
        // When - Cache a rate
        let currencyRate = CurrencyRate()
        currencyRate.fromCurrency = key
        currencyRate.toCurrency = toCurrency
        currencyRate.rate = rate
        currencyRate.timestamp = Date()
        
        try testRealm.write {
            testRealm.add(currencyRate)
        }
        
        // Then - Verify it's cached
        let cachedRate = testRealm.object(ofType: CurrencyRate.self, forPrimaryKey: key)
        XCTAssertNotNil(cachedRate)
        XCTAssertEqual(cachedRate?.rate, rate)
        XCTAssertEqual(cachedRate?.toCurrency, toCurrency)
    }
    
    
    func testValidCacheRetrieval() throws {
        // Given - A fresh cache entry (30 minutes old)
        let fromCurrency = "EUR"
        let toCurrency = "USD"
        let rate = 1.0856
        let key = "\(fromCurrency)_\(toCurrency)"
        let recentDate = Date().addingTimeInterval(-1800) // 30 minutes ago
        
        let currencyRate = CurrencyRate()
        currencyRate.fromCurrency = key
        currencyRate.toCurrency = toCurrency
        currencyRate.rate = rate
        currencyRate.timestamp = recentDate
        
        try testRealm.write {
            testRealm.add(currencyRate)
        }
        
        // When - Check if cache is valid
        let cachedRate = testRealm.object(ofType: CurrencyRate.self, forPrimaryKey: key)
        let isValid = Date().timeIntervalSince(cachedRate!.timestamp) < 3600 // Less than 1 hour
        
        // Then
        XCTAssertTrue(isValid)
        XCTAssertEqual(cachedRate?.rate, rate)
    }
    
    // MARK: - Currency Conversion Manager Tests
    
    func testCurrencyConversionManagerInitialization() {
        // Given
        let mockDelegate = MockCurrencyConversionDelegate()
        
        // When
        let manager = CurrencyConversionManager(delegate: mockDelegate)
        
        // Then
        XCTAssertNotNil(manager)
    }
    
    func testRealTimeConversionWithValidData() {
        // Given
        let mockDelegate = MockCurrencyConversionDelegate()
        let manager = CurrencyConversionManager(delegate: mockDelegate)
        let amount = 100.0
        let rate = 1.0856
        let expectedConvertedAmount = amount * rate
        
        // When
        manager.performRealTimeConversion(amount: amount, rate: rate)
        
        // Then
        XCTAssertTrue(mockDelegate.updateConvertedAmountCalled)
        XCTAssertNotNil(mockDelegate.lastFormattedAmount)
        
        // Verify the amount is properly formatted
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.usesGroupingSeparator = true
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        let expectedFormatted = formatter.string(from: NSNumber(value: expectedConvertedAmount)) ?? "0.00"
        XCTAssertEqual(mockDelegate.lastFormattedAmount, expectedFormatted)
    }
    
    func testRealTimeConversionWithInvalidData() {
        // Given
        let mockDelegate = MockCurrencyConversionDelegate()
        let manager = CurrencyConversionManager(delegate: mockDelegate as CurrencyConversionDelegate)
        
        // When - Test with nil amount
        manager.performRealTimeConversion(amount: nil, rate: 1.0856)
        
        // Then
        XCTAssertTrue(mockDelegate.updateConvertedAmountCalled)
        XCTAssertEqual(mockDelegate.lastFormattedAmount, "0.00")
        
        // Reset delegate
        mockDelegate.reset()
        
        // When - Test with zero rate
        manager.performRealTimeConversion(amount: 100.0, rate: 0.0)
        
        // Then
        XCTAssertTrue(mockDelegate.updateConvertedAmountCalled)
        XCTAssertEqual(mockDelegate.lastFormattedAmount, "0.00")
        
        // Reset delegate
        mockDelegate.reset()
        
        // When - Test with negative amount
        manager.performRealTimeConversion(amount: -50.0, rate: 1.0856)
        
        // Then - Should still process (business logic allows negative conversions)
        XCTAssertTrue(mockDelegate.updateConvertedAmountCalled)
        XCTAssertNotEqual(mockDelegate.lastFormattedAmount, "0.00")
    }
    
    func testRealTimeConversionWithTextInput() {
        // Given
        let mockDelegate = MockCurrencyConversionDelegate()
        let manager = CurrencyConversionManager(delegate: mockDelegate)
        let inputText = "1,234.56"
        let rate = 1.0856
        let expectedAmount = 1234.56 * rate
        
        // When
        manager.performRealTimeConversionWithText(inputText, rate: rate)
        
        // Then
        XCTAssertTrue(mockDelegate.updateConvertedAmountCalled)
        XCTAssertNotNil(mockDelegate.lastFormattedAmount)
        
        // Verify conversion happened correctly (commas should be removed)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.usesGroupingSeparator = true
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        let expectedFormatted = formatter.string(from: NSNumber(value: expectedAmount)) ?? "0.00"
        XCTAssertEqual(mockDelegate.lastFormattedAmount, expectedFormatted)
    }
    
    func testRealTimeConversionWithInvalidTextInput() {
        // Given
        let mockDelegate = MockCurrencyConversionDelegate()
        let manager = CurrencyConversionManager(delegate: mockDelegate)
        
        // Test cases for invalid input
        let invalidInputs = ["", "abc", "12.34.56", "-100", "   ", "12..34"]
        
        for invalidInput in invalidInputs {
            // Reset delegate
            mockDelegate.reset()
            
            // When
            manager.performRealTimeConversionWithText(invalidInput, rate: 1.0856)
            
            // Then
            XCTAssertTrue(mockDelegate.updateConvertedAmountCalled, "Failed for input: \(invalidInput)")
            XCTAssertEqual(mockDelegate.lastFormattedAmount, "0.00", "Failed for input: \(invalidInput)")
        }
    }
    
    func testRealTimeConversionWithEdgeCases() {
        // Given
        let mockDelegate = MockCurrencyConversionDelegate()
        let manager = CurrencyConversionManager(delegate: mockDelegate)
        
        // Test very large numbers
        mockDelegate.reset()
        manager.performRealTimeConversion(amount: 999999999.99, rate: 1.0856)
        XCTAssertTrue(mockDelegate.updateConvertedAmountCalled)
        XCTAssertNotEqual(mockDelegate.lastFormattedAmount, "0.00")
        
        // Test very small numbers
        mockDelegate.reset()
        manager.performRealTimeConversion(amount: 0.01, rate: 1.0856)
        XCTAssertTrue(mockDelegate.updateConvertedAmountCalled)
        XCTAssertNotEqual(mockDelegate.lastFormattedAmount, "0.00")
        
        // Test zero amount
        mockDelegate.reset()
        manager.performRealTimeConversion(amount: 0.0, rate: 1.0856)
        XCTAssertTrue(mockDelegate.updateConvertedAmountCalled)
        XCTAssertEqual(mockDelegate.lastFormattedAmount, "0.00")
    }
    
    // MARK: - Format Testing
    
    func testCurrencyFormatting() {
        // Given
        let amounts = [
            (100.0, "100.00"),
            (1234.56, "1,234.56"),
            (1000000.99, "1,000,000.99"),
            (0.01, "0.01"),
            (999999999.99, "999,999,999.99"),
            (0.0, "0.00"),
            (12.3, "12.30")
        ]
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.usesGroupingSeparator = true
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        for (amount, expectedFormat) in amounts {
            // When
            let formattedAmount = formatter.string(from: NSNumber(value: amount)) ?? "0.00"
            
            // Then
            XCTAssertEqual(formattedAmount, expectedFormat, "Failed to format \(amount)")
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorHandling() {
        // Given
        let mockDelegate = MockCurrencyConversionDelegate()
        let testErrors: [APIError] = [
            .invalidBaseCurrency,
            .rateLimitExceeded,
            .networkError("Connection failed"),
            .unauthorized,
            .forbidden
        ]
        
        for error in testErrors {
            // Reset delegate
            mockDelegate.reset()
            
            // When
            mockDelegate.conversionDidFail(error: error)
            
            // Then
            XCTAssertTrue(mockDelegate.conversionDidFailCalled)
            XCTAssertNotNil(mockDelegate.lastError)
            
            if let apiError = mockDelegate.lastError as? APIError {
                XCTAssertFalse(apiError.localizedDescription.isEmpty)
            }
        }
    }
    
    // MARK: - Performance Tests
    
    func testConversionPerformance() {
        // Given
        let mockDelegate = MockCurrencyConversionDelegate()
        let manager = CurrencyConversionManager(delegate: mockDelegate)
        
        // When & Then
        measure {
            for i in 1...1000 {
                manager.performRealTimeConversion(amount: Double(i), rate: 1.0856)
            }
        }
    }
    
    func testFormattingPerformance() {
        // Given
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.usesGroupingSeparator = true
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        // When & Then
        measure {
            for i in 1...1000 {
                _ = formatter.string(from: NSNumber(value: Double(i) * 1.0856))
            }
        }
    }
    
    func testTextConversionPerformance() {
        // Given
        let mockDelegate = MockCurrencyConversionDelegate()
        let manager = CurrencyConversionManager(delegate: mockDelegate)
        let testTexts = ["100", "1,234.56", "999,999.99", "0.01"]
        
        // When & Then
        measure {
            for _ in 1...250 {
                for text in testTexts {
                    manager.performRealTimeConversionWithText(text, rate: 1.0856)
                }
            }
        }
    }
}



