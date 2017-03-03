//
//  UPActionButtonItem.swift
//  UPActionButtonDemo
//
//  Created by Paul Ulric on 28/02/2017.
//  Copyright © 2017 Paul Ulric. All rights reserved.
//

import UIKit


protocol UPActionButtonItemDelegate {
    func didTouch(item: UPActionButtonItem)
}


class UPActionButtonItem: UIView {

    // MARK: - Properties
    fileprivate var tapButton: UIButton!
    fileprivate var titleLabel: UILabel!
    fileprivate var action: (() -> Void)?
    fileprivate var isExpanded: Bool = false
    fileprivate var isAnimating: Bool = false
    
    fileprivate var titleLabelSize: CGSize {
        guard let title = titleLabel.text else {
            return .zero
        }
        return (title as NSString).size(attributes: [NSFontAttributeName: titleLabel.font])
    }
    
    var button: UIButton!
    
    var size: CGSize = .zero {
        didSet {
            let titleSize = titleLabelSize
            
            var frame = self.frame
            frame.size.width = titleSize.width + internMargin + size.width
            frame.size.height = max(titleSize.height, size.height)
            self.frame = frame
            
            titleLabel.frame = CGRect(origin: .zero, size: titleSize)
            titleLabel.center = CGPoint(x: titleSize.width/2.0, y: frame.size.height/2.0)
            
            button.frame = CGRect(origin: .zero, size: size)
            button.center = CGPoint(x: frame.size.width - size.width/2.0, y: frame.size.height/2.0)
            button.layer.cornerRadius = min(size.width, size.height) / 2.0
        }
    }
    
    var itemCenter: CGPoint {
        get { return button.center }
        set { self.center = self.centerForItemCenter(newValue) }
    }
    
    var delegate: UPActionButtonItemDelegate?
    
    /* Customization */
    var internMargin: CGFloat = 5.0
    var closeOnTap: Bool = true
    var titleColor: UIColor {
        get { return titleLabel.textColor }
        set { titleLabel.textColor = newValue }
    }
    var titleFont: UIFont {
        get { return titleLabel.font }
        set { titleLabel.font = newValue }
    }
    var color: UIColor? {
        get { return button.backgroundColor }
        set { button.backgroundColor = newValue }
    }
    var cornerRadius: CGFloat {
        get { return button.layer.cornerRadius }
        set { button.layer.cornerRadius = newValue }
    }
    
    // MARK: - Initialization
    init(title: String, buttonImage: UIImage?, buttonText: String?, action: (() -> Void)?) {
        super.init(frame: .zero)
        
        titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.alpha = 0.0
        self.addSubview(titleLabel)
        
        button = UIButton(type: .custom)
        button.isUserInteractionEnabled = false
        if let image = buttonImage {
            button.setImage(image, for: .normal)
        } else if let text = buttonText {
            button.setTitle(text, for: .normal)
        }
        self.addSubview(button)
        
        tapButton = UIButton(type: .custom)
        tapButton.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        tapButton.addTarget(self, action: #selector(didTouch), for: .touchUpInside)
        tapButton.addObserver(self, forKeyPath: "highlighted", options: .new, context: nil)
        self.addSubview(tapButton)
        
        self.action = action
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        tapButton.removeObserver(self, forKeyPath: "highlighted")
    }
    
}


// MARK: - Public API
extension UPActionButtonItem {
    
    /* Interactions */
    
    func expand(animated: Bool, duration: TimeInterval) {
        guard !isExpanded && !isAnimating else { return }
        
        isExpanded = true
        
        let operations = {
            var titleFrame = self.titleLabel.frame
            titleFrame.origin.x = 0
            titleFrame.size.width = self.titleLabelSize.width
            self.titleLabel.frame = titleFrame
            self.titleLabel.alpha = 1.0
        }
        
        if animated {
            isAnimating = true
            UIView.animate(withDuration: duration, delay: 0.0, options: .curveEaseIn, animations: {
                operations()
            }, completion: { (finished: Bool) in
                self.isAnimating = false
            })
        } else {
            operations()
        }
    }
    
    func reduce(animated: Bool, duration: TimeInterval) {
        guard isExpanded && !isAnimating else { return }
        
        isExpanded = false
        
        let operations = {
            var titleFrame = self.titleLabel.frame
            titleFrame.origin.x = self.button.center.x
            titleFrame.size.width = 0
            self.titleLabel.frame = titleFrame
            self.titleLabel.alpha = 0.0
        }
        
        if animated {
            isAnimating = true
            UIView.animate(withDuration: duration, delay: 0.0, options: .curveEaseIn, animations: {
                operations()
            }, completion: { (finished: Bool) in
                self.isAnimating = false
            })
        } else {
            operations()
        }
    }
    
    func centerForItemCenter(_ center: CGPoint) -> CGPoint {
        let offsetX = button.center.x - self.frame.size.width/2.0
        let offsetY = button.center.y - self.frame.size.height/2.0
        return CGPoint(x: center.x - offsetX, y: center.y - offsetY)
    }
    
    func didTouch(sender: UIButton) {
        self.delegate?.didTouch(item: self)
        self.action?()
    }
    
    
    /* Customization */
    
    func setShadow(color: UIColor, opacity: Float, radius: CGFloat, offset: CGSize) {
        button.layer.shadowColor = color.cgColor
        button.layer.shadowOpacity = opacity
        button.layer.shadowRadius = radius
        button.layer.shadowOffset = offset
    }
    
    
    /* Observers */
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if (object as? UIButton) === tapButton && keyPath == "highlighted" {
            button.isHighlighted = tapButton.isHighlighted
        }
    }
}
