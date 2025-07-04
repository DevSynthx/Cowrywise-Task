//
//  Error.swift
//  Cowrywise-Task


enum APIError: Error {
    case invalidResponse
    case apiError(String)
    case rateLimitExceeded
    case baseCurrencyAccessRestricted
    case networkError(String)
    
    // HTTP Status Code Errors
    case badRequest(String)
    case unauthorized
    case forbidden
    case notFound(String)
    case tooManyRequests
    
    // API Specific Errors
    case invalidBaseCurrency         // 601
    case invalidSymbols              // 602
    case invalidDate                 // 603
    case invalidAmount               // 604
    case invalidTimeframe            // 605
    case weekendMarketsClosed        // 606
    case functionAccessRestricted    // 105
    
    var localizedDescription: String {
        switch self {
        case .invalidResponse:
            return "Unable to process the response from the currency service. Please try again."
        case .apiError(let message):
            return message
        case .rateLimitExceeded:
            return "Too many requests have been made. Please wait a moment and try again."
        case .baseCurrencyAccessRestricted:
            return "Access to this currency conversion is temporarily restricted. Please try a different currency pair."
        case .networkError(let message):
            return "Network connection error: \(message). Please check your internet connection."
            
        // HTTP Status Code Errors
        case .badRequest(let endpoint):
            return "Invalid request to \(endpoint). Please try again."
        case .unauthorized:
            return "Authentication failed. The currency service is temporarily unavailable."
        case .forbidden:
            return "Access denied to the currency service. Please try again later."
        case .notFound(let resource):
            return "The requested \(resource) could not be found."
        case .tooManyRequests:
            return "Service is busy. Please wait a moment and try again."
            
        // API Specific Errors
        case .invalidBaseCurrency:
            return "The selected base currency is not supported. Please choose a different currency."
        case .invalidSymbols:
            return "One or more selected currencies are not supported. Please check your currency selection."
        case .invalidDate:
            return "Invalid date specified. Please try again."
        case .invalidAmount:
            return "Please enter a valid amount greater than 0."
        case .invalidTimeframe:
            return "Invalid time period specified. Please try again."
        case .weekendMarketsClosed:
            return "Currency markets are closed over the weekend. Please try again during business hours."
        case .functionAccessRestricted:
            return "This conversion feature is temporarily unavailable. Please try again later."
        }
    }
    
    // Helper method to create APIError from HTTP status code
    static func fromHTTPStatusCode(_ statusCode: Int, endpoint: String = "", message: String? = nil) -> APIError {
        switch statusCode {
        case 400:
            return .badRequest(endpoint)
        case 401:
            return .unauthorized
        case 403:
            return .forbidden
        case 404:
            return .notFound(message ?? "resource")
        case 429:
            return .tooManyRequests
        default:
            return .networkError(message ?? "Connection error (Status: \(statusCode))")
        }
    }
    
    // Helper method to create APIError from API response code
    static func fromAPIResponse(code: Int, message: String? = nil) -> APIError {
        switch code {
        case 105:
            return .functionAccessRestricted
        case 104:
            return .rateLimitExceeded
        case 601:
            return .invalidBaseCurrency
        case 602:
            return .invalidSymbols
        case 603:
            return .invalidDate
        case 604:
            return .invalidAmount
        case 605:
            return .invalidTimeframe
        case 606:
            return .weekendMarketsClosed
        default:
            return .apiError(message ?? "Conversion service temporarily unavailable. Please try again later.")
        }
    }
}
