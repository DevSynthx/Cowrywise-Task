//
//  ViewController.swift
//  Cowrywise-Task

import UIKit
import PromiseKit


class ViewController: UIViewController {
    
    @IBOutlet weak var FromButton: UIButton!
    @IBOutlet weak var ToButton: UIButton!
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var convertedAmountLabel: UILabel!
    @IBOutlet weak var convertButton: UIButton!
    @IBOutlet weak var exchangeRateLabel: UILabel!
    @IBOutlet weak var currencyFromLabel: UILabel!
    @IBOutlet weak var currencyToLabel: UILabel!
    
    // MARK: - Properties
    private let fromCurrency = Currency(code: "EUR", name: "Euro", flag: "🇪🇺")
    private var toCurrency: Currency?
    private var currentExchangeRate: Double = 0.0
    
    private lazy var uiManager = CurrencyUIManager(viewController: self)
    private lazy var conversionManager = CurrencyConversionManager(delegate: self)
    private lazy var inputHandler = CurrencyInputHandler(delegate: self)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewController()
    }
    
    // MARK: - Setup
    private func setupViewController() {
        uiManager.setupUI()
        setupDelegatesAndTargets()
        setInitialState()
        setupAccessibilityIdentifiers()
        setupTapGestureToDismissKeyboard()
    }
    
    private func setupDelegatesAndTargets() {
        amountTextField.delegate = inputHandler
        amountTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        
        FromButton.addTarget(self, action: #selector(fromButtonTapped(_:)), for: .touchUpInside)
        ToButton.addTarget(self, action: #selector(toButtonTapped(_:)), for: .touchUpInside)
        convertButton.addTarget(self, action: #selector(convertButtonTapped(_:)), for: .touchUpInside)
    }
    
    private func setInitialState() {
        formatConvertedAmountWithGrayDecimals("0.00")
        exchangeRateLabel.text = "Select currency and enter amount to convert"
        currencyFromLabel.text = fromCurrency.code
        currencyToLabel.text = ""
        
        uiManager.configureButtonWithChevron(fromCurrency: fromCurrency, toCurrency: nil)
        uiManager.updateConvertButtonState(isReady: false)
    }
    
    // MARK: - Text Field Events
    @objc private func textFieldDidChange() {
        let isReady = isReadyToConvert()
        uiManager.updateConvertButtonState(isReady: isReady)
        
        if currentExchangeRate > 0 {
            conversionManager.performRealTimeConversion(
                amount: getAmountFromTextField(),
                rate: currentExchangeRate
            )
        } else {
            formatConvertedAmountWithGrayDecimals("0.00")
        }
    }
    
    // MARK: - Button Actions
    @IBAction func fromButtonTapped(_ sender: UIButton) {
        uiManager.showFixedCurrencyAlert()
    }
    
    @IBAction func toButtonTapped(_ sender: UIButton) {
        presentCurrencyBottomSheet()
    }
    
    @IBAction func convertButtonTapped(_ sender: UIButton) {
        performConversion()
    }
    
    
    // MARK: - Private Methods
    private func presentCurrencyBottomSheet() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        let bottomSheet = CurrencyBottomSheetViewController()
        bottomSheet.delegate = self
        bottomSheet.isFromCurrency = false
        bottomSheet.selectedCurrency = toCurrency
        bottomSheet.modalPresentationStyle = .overFullScreen
        bottomSheet.modalTransitionStyle = .crossDissolve
        
        present(bottomSheet, animated: false)
    }
    
    private func performConversion() {
        guard let toCurrency = toCurrency else {
            conversionManager.showError(APIError.apiError("Please select a target currency"))
            return
        }
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        view.endEditing(true)
        showLoading("Converting...")
        uiManager.setConvertButtonLoading(true)
        
        conversionManager.performCurrencyConversion(from: fromCurrency.code, to: toCurrency.code)
    }
    
    // MARK: - UI Formatting
    private func formatConvertedAmountWithGrayDecimals(_ amount: String) {
        guard amount.contains(".") else {
            // If no decimal point, just set the text normally
            convertedAmountLabel.text = amount
            return
        }
        
        let components = amount.components(separatedBy: ".")
        guard components.count == 2 else {
            convertedAmountLabel.text = amount
            return
        }
        
        let wholeNumber = components[0]
        let decimals = components[1]
        
        let attributedString = NSMutableAttributedString()
        
        // whole number part in normal color
        let wholeNumberAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.label
        ]
        attributedString.append(NSAttributedString(string: wholeNumber, attributes: wholeNumberAttributes))
        
        // decimal places in gray
        let decimalAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.systemGray
        ]
        attributedString.append(NSAttributedString(string: ".\(decimals)", attributes: decimalAttributes))
        
        convertedAmountLabel.attributedText = attributedString
    }
    
    private func setupAccessibilityIdentifiers() {
        FromButton.accessibilityIdentifier = "fromCurrencyButton"
        ToButton.accessibilityIdentifier = "toCurrencyButton"
        convertButton.accessibilityIdentifier = "convertButton"
        amountTextField.accessibilityIdentifier = "amountTextField"
        convertedAmountLabel.accessibilityIdentifier = "convertedAmountLabel"
        exchangeRateLabel.accessibilityIdentifier = "exchangeRateLabel"
        currencyFromLabel.accessibilityIdentifier = "currencyFromLabel"
        currencyToLabel.accessibilityIdentifier = "currencyToLabel"
        
        FromButton.accessibilityLabel = "From Currency"
        ToButton.accessibilityLabel = "To Currency"
        convertButton.accessibilityLabel = "Convert Currency"
        amountTextField.accessibilityLabel = "Amount to Convert"
        convertedAmountLabel.accessibilityHint = "Shows the converted currency amount"
        exchangeRateLabel.accessibilityHint = "Shows the current exchange rate information"
        currencyFromLabel.accessibilityHint = "Source currency code"
        currencyToLabel.accessibilityHint = "Target currency code"
    }
    
    
    // MARK: - Keyboard Dismissal
    private func setupTapGestureToDismissKeyboard() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false 
        view.addGestureRecognizer(tapGesture)
    }

 
    // MARK: - Helper Methods
    private func getAmountFromTextField() -> Double? {
        guard let text = amountTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else {
            return nil
        }
        
        let cleanText = text.replacingOccurrences(of: ",", with: "")
        guard let amount = Double(cleanText), amount >= 0 else {
            return nil
        }
        
        return amount
    }
    
    private func isReadyToConvert() -> Bool {
        return toCurrency != nil
    }
}

// MARK: - CurrencyBottomSheetDelegate
extension ViewController: CurrencyBottomSheetDelegate {
    func didSelectCurrency(_ currency: Currency, isFromCurrency: Bool) {
        guard !isFromCurrency else { return }
        
        toCurrency = currency
        currencyToLabel.text = currency.code
        
        uiManager.configureButtonWithChevron(fromCurrency: fromCurrency, toCurrency: toCurrency)
        
        currentExchangeRate = 0.0
        convertedAmountLabel.text = "0.00"
        
        let isReady = isReadyToConvert()
        uiManager.updateConvertButtonState(isReady: isReady)
        
        exchangeRateLabel.text = isReady ? "Tap Convert to get latest rates" : "Select currency and enter amount to convert"
        
        let successFeedback = UINotificationFeedbackGenerator()
        successFeedback.notificationOccurred(.success)
    }
}

// MARK: - CurrencyConversionDelegate
extension ViewController: CurrencyConversionDelegate {
    func conversionDidSucceed(rate: Double) {
        hideLoading()
        
        currentExchangeRate = rate
        uiManager.updateExchangeRateLabel(rate: rate, fromCurrency: fromCurrency, toCurrency: toCurrency)
        
        conversionManager.performRealTimeConversion(amount: getAmountFromTextField(), rate: rate)
        
        uiManager.setConvertButtonLoading(false)
        uiManager.updateConvertButtonState(isReady: isReadyToConvert())
    }
    
    func conversionDidFail(error: Error) {
        hideLoading()
        currentExchangeRate = 0.0
        formatConvertedAmountWithGrayDecimals("0.00")
        conversionManager.showError(error)
        
        uiManager.setConvertButtonLoading(false)
        uiManager.updateConvertButtonState(isReady: isReadyToConvert())
    }
    
    func updateConvertedAmount(_ formattedAmount: String) {
        formatConvertedAmountWithGrayDecimals(formattedAmount)
    }
}

// MARK: - CurrencyInputDelegate
extension ViewController: CurrencyInputDelegate {
    func didUpdateInput(text: String) {
        if currentExchangeRate > 0 {
            DispatchQueue.main.async {
                self.conversionManager.performRealTimeConversionWithText(
                    text,
                    rate: self.currentExchangeRate
                )
            }
        }
    }
}

extension ViewController {
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}




