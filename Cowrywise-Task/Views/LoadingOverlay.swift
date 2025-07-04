//
//  LoadingOverlay.swift
//  Cowrywise-Task


import UIKit

class LoadingOverlay: UIView {
    
    // MARK: - UI Components
    private var loadingContainer: UIView!
    private var loadingIndicator: UIActivityIndicatorView!
    private var loadingLabel: UILabel!
    
    // MARK: - Properties
    private weak var parentView: UIView?
    
    // MARK: - Initialization
    init(parentView: UIView) {
        self.parentView = parentView
        super.init(frame: parentView.bounds)
        setupLoadingOverlay()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLoadingOverlay()
    }
    
    // MARK: - Setup
    private func setupLoadingOverlay() {
        // Configure overlay
        backgroundColor = UIColor.black.withAlphaComponent(0.3)
        translatesAutoresizingMaskIntoConstraints = false
        isHidden = true
        
        // Create container for loading components
        loadingContainer = UIView()
        loadingContainer.backgroundColor = UIColor.systemBackground
        loadingContainer.layer.cornerRadius = 12
        loadingContainer.layer.shadowColor = UIColor.black.cgColor
        loadingContainer.layer.shadowOffset = CGSize(width: 0, height: 2)
        loadingContainer.layer.shadowOpacity = 0.2
        loadingContainer.layer.shadowRadius = 8
        loadingContainer.translatesAutoresizingMaskIntoConstraints = false
        addSubview(loadingContainer)
        
        // Create activity indicator
        loadingIndicator = UIActivityIndicatorView(style: .large)
        loadingIndicator.color = UIColor.systemBlue
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingContainer.addSubview(loadingIndicator)
        
        // Create loading label
        loadingLabel = UILabel()
        loadingLabel.text = "Processing..."
        loadingLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        loadingLabel.textColor = UIColor.label
        loadingLabel.textAlignment = .center
        loadingLabel.translatesAutoresizingMaskIntoConstraints = false
        loadingContainer.addSubview(loadingLabel)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Loading container centered
            loadingContainer.centerXAnchor.constraint(equalTo: centerXAnchor),
            loadingContainer.centerYAnchor.constraint(equalTo: centerYAnchor),
            loadingContainer.widthAnchor.constraint(equalToConstant: 200),
            loadingContainer.heightAnchor.constraint(equalToConstant: 120),
            
            // Activity indicator
            loadingIndicator.centerXAnchor.constraint(equalTo: loadingContainer.centerXAnchor),
            loadingIndicator.topAnchor.constraint(equalTo: loadingContainer.topAnchor, constant: 20),
            
            // Loading label
            loadingLabel.topAnchor.constraint(equalTo: loadingIndicator.bottomAnchor, constant: 16),
            loadingLabel.leadingAnchor.constraint(equalTo: loadingContainer.leadingAnchor, constant: 16),
            loadingLabel.trailingAnchor.constraint(equalTo: loadingContainer.trailingAnchor, constant: -16),
            loadingLabel.bottomAnchor.constraint(lessThanOrEqualTo: loadingContainer.bottomAnchor, constant: -20)
        ])
    }
    
    // MARK: - Public Methods
    
    // Add the loading overlay to a parent view
    func addToView(_ parentView: UIView) {
        self.parentView = parentView
        parentView.addSubview(self)
        
        // Pin to parent view edges
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: parentView.topAnchor),
            leadingAnchor.constraint(equalTo: parentView.leadingAnchor),
            trailingAnchor.constraint(equalTo: parentView.trailingAnchor),
            bottomAnchor.constraint(equalTo: parentView.bottomAnchor)
        ])
    }
    
    // Show the loading overlay with animation
    func show(message: String = "Processing...", disableParentInteraction: Bool = true) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Update message if provided
            self.loadingLabel.text = message
            
            // Show and start animation
            self.isHidden = false
            self.loadingIndicator.startAnimating()
            
            // Animate appearance
            self.alpha = 0
            UIView.animate(withDuration: 0.3) {
                self.alpha = 1
            }
            
            // Handle parent view interaction
            if disableParentInteraction {
                self.parentView?.isUserInteractionEnabled = false
                self.isUserInteractionEnabled = true
            }
        }
    }
    
    // Hide the loading overlay with animation
   
    func hide(completion: (() -> Void)? = nil) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Animate disappearance
            UIView.animate(withDuration: 0.3, animations: {
                self.alpha = 0
            }) { _ in
                self.isHidden = true
                self.loadingIndicator.stopAnimating()
                
                // Re-enable parent view interaction
                self.parentView?.isUserInteractionEnabled = true
          
                completion?()
            }
        }
    }
    

    
    // Check if loading overlay is currently visible
    var isVisible: Bool {
        return !isHidden && alpha > 0
    }
}

// MARK: - Convenience Extension for UIViewController
extension UIViewController {
    
    private struct AssociatedKeys {
           static var loadingOverlay: UInt8 = 0
       }
       
       // Get or create a loading overlay for this view controller
       var loadingOverlay: LoadingOverlay {
           if let overlay = objc_getAssociatedObject(self, &AssociatedKeys.loadingOverlay) as? LoadingOverlay {
               return overlay
           }
           
           let overlay = LoadingOverlay(parentView: view)
           overlay.addToView(view)
           objc_setAssociatedObject(self, &AssociatedKeys.loadingOverlay, overlay, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
           return overlay
       }
    
    // Show loading overlay with optional message
   
    func showLoading(_ message: String = "Processing...") {
        loadingOverlay.show(message: message)
    }
    
    // Hide loading overlay with optional completion
 
    func hideLoading(completion: (() -> Void)? = nil) {
        loadingOverlay.hide(completion: completion)
    }
    
}
