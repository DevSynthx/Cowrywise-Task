//
//  CurrencyUIManager.swift
//  Cowrywise-Task

import UIKit


class CurrencyUIManager {
    private weak var viewController: ViewController?
    
    init(viewController: ViewController) {
        self.viewController = viewController
    }
    
    // MARK: - UI Setup
    func setupUI() {
        guard let vc = viewController else { return }
        
        setupTextField(vc.amountTextField)
        setupLabels(vc)
        setupCurrencyButtons(vc)
        setupConvertButton(vc.convertButton)
    }
    
    private func setupTextField(_ textField: UITextField) {
        textField.borderStyle = .none
        textField.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        textField.textColor = UIColor.black
        textField.placeholder = "Enter amount"
        textField.keyboardType = .decimalPad
        
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: viewController, action: #selector(ViewController.dismissKeyboard))
        toolbar.setItems([doneButton], animated: false)
        textField.inputAccessoryView = toolbar
    }
    
    private func setupLabels(_ vc: ViewController) {
        // Currency labels
        vc.currencyFromLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        vc.currencyFromLabel.textColor = UIColor.black
        
        vc.currencyToLabel.text = ""
        vc.currencyToLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        vc.currencyToLabel.textColor = UIColor.lightGray
        
        // Converted amount label
        vc.convertedAmountLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        vc.convertedAmountLabel.textColor = UIColor.black
        vc.convertedAmountLabel.text = "0.00"
        
        // Exchange rate label
        vc.exchangeRateLabel.font = UIFont.systemFont(ofSize: 14)
        vc.exchangeRateLabel.textColor = UIColor.systemBlue
        vc.exchangeRateLabel.text = "Select currency and enter amount to convert"
    }
    
    private func setupCurrencyButtons(_ vc: ViewController) {
        // From Button styling
        vc.FromButton.layer.borderWidth = 1.0
        vc.FromButton.layer.borderColor = UIColor.systemGray4.cgColor
        vc.FromButton.layer.cornerRadius = 8
        vc.FromButton.backgroundColor = UIColor.systemGray6
        
        // To Button styling
        vc.ToButton.layer.borderWidth = 1.0
        vc.ToButton.layer.borderColor = UIColor.lightGray.cgColor
        vc.ToButton.layer.cornerRadius = 8
        vc.ToButton.backgroundColor = UIColor.white
    }
    
    private func setupConvertButton(_ button: UIButton) {
        button.setTitle("Convert", for: .normal)
        button.setTitleColor(UIColor.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        button.layer.cornerRadius = 8
        
        // Initial state - disabled
        button.isEnabled = false
        button.backgroundColor = UIColor.systemGray4
    }
    
    // MARK: - Button Configuration
    func configureButtonWithChevron(fromCurrency: Currency, toCurrency: Currency?) {
        guard let vc = viewController else { return }
        
        // FROM Button Configuration - Fixed to EUR (no dropdown)
        var fromConfig = UIButton.Configuration.plain()
        fromConfig.title = "\(fromCurrency.flag)  \(fromCurrency.code)"
        fromConfig.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
        fromConfig.baseForegroundColor = UIColor.systemGray2
        
        vc.FromButton.configuration = fromConfig
        vc.FromButton.isUserInteractionEnabled = false
        
        // TO Button Configuration with dropdown chevron
        var toConfig = UIButton.Configuration.plain()
        if let toCurrency = toCurrency {
            toConfig.title = "\(toCurrency.flag)  \(toCurrency.code)"
        } else {
            toConfig.title = "Select"
        }
        toConfig.image = UIImage(systemName: "chevron.down")
        toConfig.imagePlacement = .trailing
        toConfig.imagePadding = 10
        toConfig.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 12)
        toConfig.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
        toConfig.baseForegroundColor = toCurrency != nil ? UIColor.black : UIColor.lightGray
        
        vc.ToButton.configuration = toConfig
    }
    
    // MARK: - UI Updates
    func updateConvertButtonState(isReady: Bool) {
        guard let vc = viewController else { return }
        
        vc.convertButton.isEnabled = isReady
        vc.convertButton.backgroundColor = isReady ? UIColor.systemGreen : UIColor.systemGray4
        
        if !isReady {
            vc.convertButton.setTitle("Convert", for: .normal)
        }
    }
    
    func setConvertButtonLoading(_ isLoading: Bool) {
        guard let vc = viewController else { return }
        
        if isLoading {
            vc.convertButton.setTitle("Converting...", for: .normal)
            vc.convertButton.isEnabled = false
        } else {
            vc.convertButton.setTitle("Convert", for: .normal)
        }
    }
    
    func updateExchangeRateLabel(rate: Double, fromCurrency: Currency, toCurrency: Currency?) {
        guard let vc = viewController,
              let toCurrency = toCurrency else { return }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let timeString = formatter.string(from: Date())
        
        let rateText = String(format: "1 %@ = %.4f %@ • %@ UTC",
                             fromCurrency.code,
                             rate,
                             toCurrency.code,
                             timeString)
        
        vc.exchangeRateLabel.text = rateText
    }
    
    func showFixedCurrencyAlert() {
        guard let vc = viewController else { return }
        
        let alert = UIAlertController(title: "Base Currency Fixed",
                                    message: "EUR is set as the base currency for this free plan.",
                                    preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        vc.present(alert, animated: true)
    }
}



extension ViewController {
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
