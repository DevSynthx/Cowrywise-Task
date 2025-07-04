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
    
    func getExchangeRate(from: String, to: String) -> Promise<Double> {
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
    private func calculateCrossRate(from: String, to: String) -> Promise<Double> {
        return Promise { seal in
            let url = "\(baseURL)/latest"
            let parameters: [String: Any] = [
                "access_key": apiKey,
                "base": "EUR",
                "symbols": "\(from),\(to)"
            ]
            
            print("Calculating cross rate using EUR base for \(from) to \(to)")
            
            AF.request(url, parameters: parameters)
                .validate()
                .responseDecodable(of: FixerResponse.self) { response in
                    switch response.result {
                    case .success(let fixerResponse):
                        if fixerResponse.success {
                            let fromRate = fixerResponse.rates[from] ?? 0.0
                            let toRate = fixerResponse.rates[to] ?? 0.0
                            
                            if fromRate > 0 && toRate > 0 {
                        
                                let crossRate = toRate / fromRate
                                
                                print("EUR rates - \(from): \(fromRate), \(to): \(toRate)")
                                print("Cross rate calculated: 1 \(from) = \(crossRate) \(to)")
                                
                                seal.fulfill(crossRate)
                            } else {
                                print("Invalid rates returned - \(from): \(fromRate), \(to): \(toRate)")
                                seal.reject(APIError.invalidResponse)
                            }
                        } else {
                            let errorInfo = fixerResponse.error?.info ?? "Unknown error"
                            let errorCode = fixerResponse.error?.code ?? 0
                            print("API Error Code: \(errorCode), Info: \(errorInfo)")
                            seal.reject(APIError.fromAPIResponse(code: errorCode, message: errorInfo))
                        }
                        
                    case .failure(let error):
                        print("Network error: \(error)")
                        seal.reject(APIError.networkError(error.localizedDescription))
                    }
                }
        }
    }
    

    private func getCachedRate(from: String, to: String) -> Double? {
        let key = "\(from)_\(to)"
        if let cachedRate = realm.object(ofType: CurrencyRate.self, forPrimaryKey: key) {
            // Check if cache is still valid (less than 1 hour old)
            if Date().timeIntervalSince(cachedRate.timestamp) < 3600 {
                print("Using cached rate for \(key): \(cachedRate.rate)")
                return cachedRate.rate
            } else {
                // Remove expired cache
                try! realm.write {
                    realm.delete(cachedRate)
                }
                print("Expired cache removed for \(key)")
            }
        }
        return nil
    }
    
    private func cacheRate(from: String, to: String, rate: Double) {
        let key = "\(from)_\(to)"
        let currencyRate = CurrencyRate()
        currencyRate.fromCurrency = key
        currencyRate.toCurrency = to
        currencyRate.rate = rate
        currencyRate.timestamp = Date()
        
        do {
            try realm.write {
                realm.add(currencyRate, update: .modified)
            }
            print("Rate cached successfully: \(key) = \(rate)")
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
        let key = "\(from)_\(to)"
        if let cachedRate = realm.object(ofType: CurrencyRate.self, forPrimaryKey: key) {
            // Check if cache is still valid (less than 1 hour old)
            if Date().timeIntervalSince(cachedRate.timestamp) < 3600 {
                return cachedRate.rate
            }
        }
        return nil
    }
}
