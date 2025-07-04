//
//  MockCurrencyConversionDelegate.swift
//  Cowrywise-Task
//


class MockCurrencyConversionDelegate: CurrencyConversionDelegate {
    var conversionDidSucceedCalled = false
    var conversionDidFailCalled = false
    var updateConvertedAmountCalled = false
    
    var lastRate: Double?
    var lastError: Error?
    var lastFormattedAmount: String?
    
    func conversionDidSucceed(rate: Double) {
        conversionDidSucceedCalled = true
        lastRate = rate
    }
    
    func conversionDidFail(error: Error) {
        conversionDidFailCalled = true
        lastError = error
    }
    
    func updateConvertedAmount(_ formattedAmount: String) {
        updateConvertedAmountCalled = true
        lastFormattedAmount = formattedAmount
    }
    
    func reset() {
        conversionDidSucceedCalled = false
        conversionDidFailCalled = false
        updateConvertedAmountCalled = false
        lastRate = nil
        lastError = nil
        lastFormattedAmount = nil
    }
}
