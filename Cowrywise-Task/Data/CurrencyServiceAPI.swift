//
//  CurrencyServiceAPI.swift
//  Cowrywise-Task

import RealmSwift
import PromiseKit
import SwiftyJSON
import Foundation
import Alamofire

class CurrencyAPIService {
    static let shared = CurrencyAPIService()
    private let baseURL = "https://data.fixer.io/api"
    private let apiKey = "432953976ea8b1084555e9380e10fb9b"
    private let realm = try! Realm()
    
    private init() {}
    
    func getExchangeRate(from: String, to: String) -> Promise<FixerResponse> {
        return Promise { seal in
            // First try to get rate from cache
            if let cachedRate = getCachedRate(from: from, to: to) {
                print("Using cached rate: \(cachedRate)")
                seal.fulfill(cachedRate)
                return
            }
            
            calculateCrossRate(from: from, to: to)
                .done { rate in
                    self.cacheRate(from: from, to: to, rate: rate)
                    seal.fulfill(rate)
                }
                .catch { error in
                    seal.reject(error)
                }
        }
    }
    
    // Method to calculate cross rate using EUR as base
    private func calculateCrossRate(from: String, to: String) -> Promise<FixerResponse> {
        return Promise { seal in
            let url = "\(baseURL)/latest"
            let parameters: [String: Any] = [
                "access_key": apiKey,
                "base": "EUR",
                "symbols": "\(from),\(to)"
            ]
            
            print("Calculating cross rate using EUR base for \(from) to \(to)")
            print("Request URL: \(url)")
            print("Parameters: \(parameters)")
            
            AF.request(url, parameters: parameters)
                .validate()
                .responseDecodable(of: FixerResponse.self) { response in
                    
                    if let data = response.data {
                        print("Raw Response Data: \(String(data: data, encoding: .utf8) ?? "Unable to convert data")")
                    }
                    
                    switch response.result {
                    case .success(let fixerResponse):
                        print("Decoded Response: \(fixerResponse)")
                        
                        if fixerResponse.success {
                            let rate = fixerResponse.rates ?? 0.0
                                    
                            if rate > 0 {
                                print("Rate: \(rate)")
                                seal.fulfill(fixerResponse)
                            } else {
                                print("Invalid rate returned: \(rate)")
                                seal.reject(APIError.invalidResponse)
                            }
                            
                        } else {
                            let errorInfo = fixerResponse.error?.info ?? "Unknown error"
                            let errorCode = fixerResponse.error?.code ?? 0
                            print("API Error Code: \(errorCode), Info: \(errorInfo)")
                            seal.reject(APIError.fromAPIResponse(code: errorCode, message: errorInfo))
                        }
                        
                    case .failure(let error):
                        print("Decoding error: \(error)")
                        print("Network error: \(error)")
                        seal.reject(APIError.networkError(error.localizedDescription))
                    }
                }
        }
    }
    
    private func getCachedRate(from: String, to: String) -> FixerResponse? {
      
        if let cachedRate = realm.objects(CurrencyRate.self)
            .filter("fromCurrency == %@ AND toCurrency == %@", from, to).first {
            
            // Check if cache is still valid (less than 1 hour old)
            if Date().timeIntervalSince(cachedRate.timestamp) < 3600 {
                print("Using cached rate for \(from)_\(to): \(cachedRate.rate)")
                
                return FixerResponse(
                    success: true,
                    timestamp: Int(cachedRate.timestamp.timeIntervalSince1970),
                    base: cachedRate.fromCurrency,
                    rate: cachedRate.rate,
                    error: nil
                )
            } else {
              
                try! realm.write {
                    realm.delete(cachedRate)
                }
                print("Expired cache removed for \(from)_\(to)")
            }
        }
        return nil
    }
    
    private func cacheRate(from: String, to: String, rate: FixerResponse) {
        let currencyRate = CurrencyRate()
         
        currencyRate.fromCurrency = from
        currencyRate.toCurrency = to
        currencyRate.rate = rate.rates ?? 0.0
        currencyRate.timestamp = Date(timeIntervalSince1970: TimeInterval(rate.timestamp ?? 0))
        
        do {
            try realm.write {
                // Delete existing record first to avoid duplicates
                if let existing = realm.objects(CurrencyRate.self)
                    .filter("fromCurrency == %@ AND toCurrency == %@", from, to).first {
                    realm.delete(existing)
                }
                realm.add(currencyRate)
            }
            print("Rate cached successfully: \(from)_\(to) = \(rate.rates ?? 0.0)")
        } catch {
            print("Failed to cache rate: \(error)")
        }
    }
    
    // Method to clear all cached rates
    func clearCache() {
        do {
            try realm.write {
                let cachedRates = realm.objects(CurrencyRate.self)
                realm.delete(cachedRates)
            }
            print("Cache cleared successfully")
        } catch {
            print("Failed to clear cache: \(error)")
        }
    }
    
    // Method to get all cached rates (for debugging)
    func getAllCachedRates() -> [CurrencyRate] {
        return Array(realm.objects(CurrencyRate.self))
    }
    
    // Method to get cached rate for testing
    func getCachedRateForTesting(from: String, to: String) -> Double? {
        if let cachedRate = realm.objects(CurrencyRate.self)
            .filter("fromCurrency == %@ AND toCurrency == %@", from, to).first {
            // Check if cache is still valid (less than 1 hour old)
            if Date().timeIntervalSince(cachedRate.timestamp) < 3600 {
                return cachedRate.rate
            }
        }
        return nil
    }
}
