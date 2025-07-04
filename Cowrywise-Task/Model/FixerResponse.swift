//
//  FixerResponse.swift
//  Cowrywise-Task

struct FixerResponse: Codable {
    let success: Bool
    let timestamp: Int?
    let base: String?
    let date: String?
    let rates: [String: Double]
    let error: FixerError?
}

struct FixerError: Codable {
    let code: Int
    let type: String?
    let info: String?
}
