//
//  CurrencyBottomSheetVC.swift
//  Cowrywise-Task

import UIKit

protocol CurrencyBottomSheetDelegate: AnyObject {
    func didSelectCurrency(_ currency: Currency, isFromCurrency: Bool)
}

class CurrencyBottomSheetViewController: UIViewController {
    
    // MARK: - UI Properties (Programmatic - NO MORE @IBOutlet)
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let tableView = UITableView()
    private let handleView = UIView()
    private let searchTextField = UITextField()
    
    // MARK: - Data Properties
    weak var delegate: CurrencyBottomSheetDelegate?
    var isFromCurrency: Bool = true
    var selectedCurrency: Currency?
    
    private let currencies = [
        Currency(code: "USD", name: "US Dollar", flag: "🇺🇸"),
        Currency(code: "GBP", name: "British Pound", flag: "🇬🇧"),
        Currency(code: "JPY", name: "Japanese Yen", flag: "🇯🇵"),
        Currency(code: "PLN", name: "Polish Zloty", flag: "🇵🇱"),
        Currency(code: "CAD", name: "Canadian Dollar", flag: "🇨🇦"),
        Currency(code: "AUD", name: "Australian Dollar", flag: "🇦🇺"),
        Currency(code: "CHF", name: "Swiss Franc", flag: "🇨🇭"),
        Currency(code: "CNY", name: "Chinese Yuan", flag: "🇨🇳"),
        Currency(code: "NGN", name: "Nigerian Naira", flag: "🇳🇬"),
        Currency(code: "INR", name: "Indian Rupee", flag: "🇮🇳"),
        Currency(code: "BRL", name: "Brazilian Real", flag: "🇧🇷"),
        Currency(code: "ZAR", name: "South African Rand", flag: "🇿🇦"),
        Currency(code: "MXN", name: "Mexican Peso", flag: "🇲🇽"),
        Currency(code: "SEK", name: "Swedish Krona", flag: "🇸🇪"),
        Currency(code: "NOK", name: "Norwegian Krone", flag: "🇳🇴"),
        Currency(code: "DKK", name: "Danish Krone", flag: "🇩🇰"),
        Currency(code: "SGD", name: "Singapore Dollar", flag: "🇸🇬"),
        Currency(code: "HKD", name: "Hong Kong Dollar", flag: "🇭🇰"),
        Currency(code: "KRW", name: "South Korean Won", flag: "🇰🇷")
    ]
    
    private var filteredCurrencies: [Currency] = []
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
      
        setupView()
        setupConstraints()
        setupTableView()
        setupGestures()
        filteredCurrencies = currencies
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        animateIn()
    }
    
    // MARK: - Setup Methods
    private func setupView() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        // Add all subviews
        view.addSubview(containerView)
        containerView.addSubview(handleView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(searchTextField)
        containerView.addSubview(tableView)
        
        // Configure container view
        containerView.backgroundColor = UIColor.systemBackground
        containerView.layer.cornerRadius = 20
        containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        // Configure handle view
        handleView.backgroundColor = UIColor.systemGray3
        handleView.layer.cornerRadius = 2
        
        // Configure title label
        titleLabel.text = "Select Currency"
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = UIColor.label
        titleLabel.textAlignment = .center
        
        // Configure search text field
        setupSearchField()
        
        // Setup accessibility
        setupAccessibilityIdentifiers()
    }
    
    private func setupConstraints() {
        // Disable autoresizing masks
        containerView.translatesAutoresizingMaskIntoConstraints = false
        handleView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        searchTextField.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Container view
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            containerView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.7),
            
            // Handle view
            handleView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            handleView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            handleView.widthAnchor.constraint(equalToConstant: 40),
            handleView.heightAnchor.constraint(equalToConstant: 4),
            
            // Title label
            titleLabel.topAnchor.constraint(equalTo: handleView.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            // Search text field
            searchTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            searchTextField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            searchTextField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            searchTextField.heightAnchor.constraint(equalToConstant: 44),
            
            // Table view
            tableView.topAnchor.constraint(equalTo: searchTextField.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    private func setupSearchField() {
        searchTextField.placeholder = "Search currencies..."
        searchTextField.borderStyle = .roundedRect
        searchTextField.backgroundColor = UIColor.systemGray6
        searchTextField.font = UIFont.systemFont(ofSize: 16)
        searchTextField.delegate = self
        searchTextField.addTarget(self, action: #selector(searchTextChanged), for: .editingChanged)
        
        // Add search icon
        let searchIcon = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        searchIcon.tintColor = UIColor.systemGray
        searchIcon.contentMode = .scaleAspectFit
        searchIcon.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        
        let leftView = UIView(frame: CGRect(x: 0, y: 0, width: 30, height: 20))
        leftView.addSubview(searchIcon)
        searchIcon.center = leftView.center
        
        searchTextField.leftView = leftView
        searchTextField.leftViewMode = .always
    }
    
    private func setupAccessibilityIdentifiers() {
        // Bottom sheet identifiers
        containerView.accessibilityIdentifier = "currencyBottomSheet"
        titleLabel.accessibilityIdentifier = "bottomSheetTitle"
        searchTextField.accessibilityIdentifier = "currencySearchField"
        tableView.accessibilityIdentifier = "currencyTableView"
        
        // Accessibility labels
        titleLabel.accessibilityLabel = "Currency Selection"
        searchTextField.accessibilityLabel = "Search Currencies"
        tableView.accessibilityLabel = "Currency List"
    }

    
    @objc private func searchTextChanged() {
        let searchText = searchTextField.text?.lowercased() ?? ""
        
        if searchText.isEmpty {
            filteredCurrencies = currencies
        } else {
            filteredCurrencies = currencies.filter { currency in
                currency.code.lowercased().contains(searchText) ||
                currency.name.lowercased().contains(searchText)
            }
        }
        
        tableView.reloadData()
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .singleLine
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 60, bottom: 0, right: 0)
        tableView.backgroundColor = UIColor.systemBackground
        tableView.showsVerticalScrollIndicator = false
        
        //Ensure table view can receive touches
        tableView.isUserInteractionEnabled = true
        tableView.allowsSelection = true
        tableView.delaysContentTouches = false
        
        // Register cell
        tableView.register(CurrencyTableViewCell.self, forCellReuseIdentifier: "CurrencyCell")
    }
    
    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        
        // Pan gesture for dragging
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.cancelsTouchesInView = false
        containerView.addGestureRecognizer(panGesture)
    }
    
    // MARK: - Gesture Handlers
    @objc private func backgroundTapped(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: view)
        let containerFrame = containerView.frame
        
        // Only dismiss if tap is outside the container view
        if !containerFrame.contains(location) {
            print("🚪 Background tapped outside container - dismissing")
            dismissBottomSheet()
        } else {
            print("🎯 Tap inside container - not dismissing")
        }
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)
        
        switch gesture.state {
        case .changed:
            if translation.y > 0 {
                containerView.transform = CGAffineTransform(translationX: 0, y: translation.y)
            }
        case .ended:
            if translation.y > 100 || velocity.y > 500 {
                dismissBottomSheet()
            } else {
                UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut) {
                    self.containerView.transform = .identity
                }
            }
        default:
            break
        }
    }
    
    // MARK: - Animation Methods
    private func animateIn() {
        print("🎬 Starting animateIn animation")
        containerView.transform = CGAffineTransform(translationX: 0, y: view.bounds.height)
        
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut) {
            self.containerView.transform = .identity
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        } completion: { finished in
          
        }
    }
    
    private func dismissBottomSheet() {
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
            self.containerView.transform = CGAffineTransform(translationX: 0, y: self.view.bounds.height)
            self.view.backgroundColor = UIColor.clear
        } completion: { _ in
            self.dismiss(animated: false)
        }
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension CurrencyBottomSheetViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredCurrencies.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CurrencyCell", for: indexPath) as! CurrencyTableViewCell
        let currency = filteredCurrencies[indexPath.row]
        
        cell.configure(with: currency, isSelected: currency.code == selectedCurrency?.code)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let selectedCurrency = filteredCurrencies[indexPath.row]
        delegate?.didSelectCurrency(selectedCurrency, isFromCurrency: isFromCurrency)
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        dismissBottomSheet()
    }
}

// MARK: - UITextFieldDelegate
extension CurrencyBottomSheetViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - Custom Currency Cell (Same as before)
class CurrencyTableViewCell: UITableViewCell {
    
    private let flagLabel = UILabel()
    private let codeLabel = UILabel()
    private let nameLabel = UILabel()
    private let checkmarkImageView = UIImageView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCell() {
        backgroundColor = UIColor.systemBackground
        selectionStyle = .none
        
        // Flag label
        flagLabel.font = UIFont.systemFont(ofSize: 24)
        flagLabel.textAlignment = .center
        
        // Code label
        codeLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        codeLabel.textColor = UIColor.label
        
        // Name label
        nameLabel.font = UIFont.systemFont(ofSize: 14)
        nameLabel.textColor = UIColor.secondaryLabel
        
        // Checkmark
        checkmarkImageView.image = UIImage(systemName: "checkmark")
        checkmarkImageView.tintColor = UIColor.systemGreen
        checkmarkImageView.contentMode = .scaleAspectFit
        checkmarkImageView.isHidden = true
        
        // Add subviews
        [flagLabel, codeLabel, nameLabel, checkmarkImageView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        
        // Setup constraints
        NSLayoutConstraint.activate([
            // Flag
            flagLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            flagLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            flagLabel.widthAnchor.constraint(equalToConstant: 30),
            
            // Code
            codeLabel.leadingAnchor.constraint(equalTo: flagLabel.trailingAnchor, constant: 12),
            codeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            
            // Name
            nameLabel.leadingAnchor.constraint(equalTo: codeLabel.leadingAnchor),
            nameLabel.topAnchor.constraint(equalTo: codeLabel.bottomAnchor, constant: 2),
            nameLabel.trailingAnchor.constraint(equalTo: checkmarkImageView.leadingAnchor, constant: -12),
            
            // Checkmark
            checkmarkImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            checkmarkImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            checkmarkImageView.widthAnchor.constraint(equalToConstant: 20),
            checkmarkImageView.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    func configure(with currency: Currency, isSelected: Bool) {
        flagLabel.text = currency.flag
        codeLabel.text = currency.code
        nameLabel.text = currency.name
        checkmarkImageView.isHidden = !isSelected
        
        self.accessibilityIdentifier = "currencyCell_\(currency.code)"
        self.accessibilityLabel = "\(currency.name), \(currency.code)"
        
        // Highlight selected cell
        backgroundColor = isSelected ? UIColor.systemGreen.withAlphaComponent(0.1) : UIColor.systemBackground
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        
        if highlighted {
            backgroundColor = UIColor.systemGray5
        } else {
            backgroundColor = checkmarkImageView.isHidden ? UIColor.systemBackground : UIColor.systemGreen.withAlphaComponent(0.1)
        }
    }
}
