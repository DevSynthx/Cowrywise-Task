//
//  FixerResponse.swift
//  Cowrywise-Task

struct FixerResponse: Codable {
    let success: Bool
    let timestamp: Int?
    let base: String?
    let rates: Double?
    let error: FixerError?
    
    private enum CodingKeys: String, CodingKey {
        case success, timestamp, base, error
        case rates
    }
    
    init(success: Bool, timestamp: Int?, base: String?, rate: Double?, error: FixerError?) {
        self.success = success
        self.timestamp = timestamp
        self.base = base
        self.rates = rate
        self.error = error
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        success = try container.decode(Bool.self, forKey: .success)
        timestamp = try container.decodeIfPresent(Int.self, forKey: .timestamp)
        base = try container.decodeIfPresent(String.self, forKey: .base)
        error = try container.decodeIfPresent(FixerError.self, forKey: .error)
        
        if let ratesDict = try container.decodeIfPresent([String: Double].self, forKey: .rates) {
            print("Rates dictionary: \(ratesDict)")
            
            if let baseCurrency = base {
                let nonBaseRates = ratesDict.filter { $0.key != baseCurrency }
                rates = nonBaseRates.first?.value
            } else {
               
                rates = ratesDict.values.first
            }
            
        } else {
            rates = nil
        }
    }
}



struct FixerError: Codable {
    let code: Int
    let type: String?
    let info: String?
}
