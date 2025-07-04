//
//  CurrencyConversionManager.swift
//  Cowrywise-Task

import UIKit
import PromiseKit

protocol CurrencyConversionDelegate: AnyObject {
    func conversionDidSucceed(rate: Double)
    func conversionDidFail(error: Error)
    func updateConvertedAmount(_ formattedAmount: String)
}

class CurrencyConversionManager {
    weak var delegate: CurrencyConversionDelegate?
    
    init(delegate: CurrencyConversionDelegate) {
        self.delegate = delegate
    }
    
    // MARK: - Currency Conversion
    func performCurrencyConversion(from: String, to: String) {
        print("🔄 Starting currency conversion from \(from) to \(to)")
        
        CurrencyAPIService.shared.getExchangeRate(from: from, to: to)
            .done { [weak self] rate in
                print("✅ Exchange rate fetched successfully: 1 \(from) = \(rate) \(to)")
                
                DispatchQueue.main.async {
                    self?.delegate?.conversionDidSucceed(rate: rate)
                }
            }
            .catch { [weak self] error in
                print("❌ Error fetching exchange rate: \(error)")
                
                DispatchQueue.main.async {
                    self?.delegate?.conversionDidFail(error: error)
                }
            }
    }
    
    // MARK: - Real-time Conversion
    func performRealTimeConversion(amount: Double?, rate: Double) {
        guard let amount = amount, rate > 0 else {
            delegate?.updateConvertedAmount("0.00")
            return
        }
        
        let convertedAmount = amount * rate
        let formattedAmount = formatCurrency(convertedAmount)
        delegate?.updateConvertedAmount(formattedAmount)
        
        print("🔄 Real-time conversion: \(amount) × \(rate) = \(convertedAmount)")
    }
    
    func performRealTimeConversionWithText(_ text: String, rate: Double) {
        guard rate > 0 else {
            delegate?.updateConvertedAmount("0.00")
            return
        }
        
        // Remove commas before converting to Double
        let cleanText = text.replacingOccurrences(of: ",", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !cleanText.isEmpty,
              let amount = Double(cleanText),
              amount >= 0 else {
            delegate?.updateConvertedAmount("0.00")
            return
        }
        
        let convertedAmount = amount * rate
        let formattedAmount = formatCurrency(convertedAmount)
        delegate?.updateConvertedAmount(formattedAmount)
        
        print("🔄 Real-time conversion: \(amount) × \(rate) = \(convertedAmount)")
    }
    
    // MARK: - Utility Methods
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.usesGroupingSeparator = true
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        return formatter.string(from: NSNumber(value: amount)) ?? "0.00"
    }
    
    func showError(_ error: Error) {
        let message: String
        
        if let apiError = error as? APIError {
            message = apiError.localizedDescription
        } else {
            message = error.localizedDescription
        }
        
        // Find the current view controller to present alert
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            print("❌ Could not find view controller to present alert")
            return
        }
        
        let alert = UIAlertController(title: "Conversion Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        rootViewController.present(alert, animated: true)
    }
}
