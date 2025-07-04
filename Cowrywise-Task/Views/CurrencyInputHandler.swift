//
//  CurrencyInputHandler.swift
//  Cowrywise-Task
//


import UIKit

protocol CurrencyInputDelegate: AnyObject {
    func didUpdateInput(text: String)
}

class CurrencyInputHandler: NSObject {
    weak var delegate: CurrencyInputDelegate?
    
    init(delegate: CurrencyInputDelegate) {
        self.delegate = delegate
        super.init()
    }
    
    // MARK: - Text Formatting
    private func formatAmountText(_ text: String) -> String {
        let cleanText = text.replacingOccurrences(of: ",", with: "")
        guard !cleanText.isEmpty, cleanText != "." else { return cleanText }
        
        let components = cleanText.components(separatedBy: ".")
        let integerPart = components[0]
        let decimalPart = components.count > 1 ? components[1] : nil
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.usesGroupingSeparator = true
        
        let number = Double(integerPart) ?? 0
        let formattedInteger = formatter.string(from: NSNumber(value: number)) ?? integerPart
        
        if let decimalPart = decimalPart {
            return "\(formattedInteger).\(decimalPart)"
        } else {
            return formattedInteger
        }
    }
    
    // MARK: - Input Validation
    private func isValidInput(_ string: String) -> Bool {
        let allowedCharacters = CharacterSet(charactersIn: "0123456789.")
        let characterSet = CharacterSet(charactersIn: string)
        return allowedCharacters.isSuperset(of: characterSet)
    }
    
    private func hasValidDecimalPoints(_ newText: String) -> Bool {
        let decimalCount = newText.components(separatedBy: ".").count - 1
        return decimalCount <= 1
    }
}

// MARK: - UITextFieldDelegate
extension CurrencyInputHandler: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Validate input characters
        guard isValidInput(string) else { return false }
        
        let currentText = textField.text ?? ""
        let newText = (currentText as NSString).replacingCharacters(in: range, with: string)
        
        // Validate decimal points
        guard hasValidDecimalPoints(newText) else { return false }
        
        // Format the text with commas
        let formattedText = formatAmountText(newText)
        textField.text = formattedText
        
        // Notify delegate of input change
        delegate?.didUpdateInput(text: newText)
        
        return false
    }
}

