//
//  CurrencyRate.swift
//  Cowrywise-Task

import RealmSwift
import Foundation


class CurrencyRate: Object {
    @Persisted var fromCurrency: String = ""
    @Persisted var toCurrency: String = ""
    @Persisted var rate: Double = 0.0
    @Persisted var timestamp: Date = Date()
    
    override static func primaryKey() -> String? {
        return "fromCurrency"
    }
}
