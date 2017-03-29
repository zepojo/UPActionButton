//
//  UPActionButtonItem.swift
//  UPActionButtonDemo
//
//  Created by Paul Ulric on 28/02/2017.
//  Copyright © 2017 Paul Ulric. All rights reserved.
//

import UIKit


public protocol UPActionButtonItemDelegate {
    func didTouch(item: UPActionButtonItem)
}


public enum UPActionButtonItemTitlePosition {
    case left
    case right
}


open class UPActionButtonItem: UIView {
    
    // MARK: - Properties
    fileprivate var tapButton: UIButton!
    fileprivate var button: UIButton!
    fileprivate var titleLabel: UILabel!
    fileprivate var titleContainer: UIView!
    fileprivate var action: (() -> Void)?
    fileprivate var isExpanded: Bool = false
    fileprivate var isAnimating: Bool = false
    
    fileprivate var titleLabelSize: CGSize {
        guard let title = titleLabel.text else {
            return .zero
        }
        return (title as NSString).size(attributes: [NSFontAttributeName: titleLabel.font])
    }
    
    fileprivate var titleContainerSize: CGSize {
        let titleLabelSize = self.titleLabelSize
        guard titleLabelSize != .zero else {
            return .zero
        }
        return CGSize(width: titleLabelSize.width + titleInsets.left * 2, height: titleLabelSize.height + titleInsets.top * 2)
    }
    
    public var size: CGSize = .zero {
        didSet {
            updateElementsSizes()
            layoutElements()
        }
    }
    public var titleInsets = UIEdgeInsets(top: 2.0, left: 5.0, bottom: 2.0, right: 5.0) {
        didSet {
            updateElementsSizes()
            layoutElements()
        }
    }
    
    public var delegate: UPActionButtonItemDelegate?
    
    /* Customization */
    public var titlePosition: UPActionButtonItemTitlePosition = .left {
        didSet {
            layoutElements()
        }
    }
    public var internMargin: CGFloat = 5.0
    public var closeOnTap: Bool = true
    public var color: UIColor? {
        get { return button.backgroundColor }
        set { button.backgroundColor = newValue }
    }
    public var cornerRadius: CGFloat {
        get { return button.layer.cornerRadius }
        set { button.layer.cornerRadius = newValue }
    }
    public var titleColor: UIColor {
        get { return titleLabel.textColor }
        set { titleLabel.textColor = newValue }
    }
    public var titleFont: UIFont {
        get { return titleLabel.font }
        set { titleLabel.font = newValue }
    }
    public var titleBackgroundColor: UIColor? {
        get { return titleContainer.backgroundColor }
        set { titleContainer.backgroundColor = newValue }
    }
    public var titleCornerRadius: CGFloat {
        get { return titleContainer.layer.cornerRadius }
        set { titleContainer.layer.cornerRadius = newValue }
    }
    
    
    // MARK: - Initialization
    public init(title: String?, buttonImage: UIImage?, buttonText: String?, action: (() -> Void)?) {
        super.init(frame: .zero)
        
        titleContainer = UIView()
        titleContainer.clipsToBounds = true
        titleContainer.alpha = 0.0
        self.addSubview(titleContainer)
        
        titleLabel = UILabel()
        titleLabel.text = title
        titleContainer.addSubview(titleLabel)
        
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
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        tapButton.removeObserver(self, forKeyPath: "highlighted")
    }
    
}


// MARK: - Public API
extension UPActionButtonItem {
    
    /* Interactions */
    
    open func expand(animated: Bool, duration: TimeInterval) {
        guard !isExpanded && !isAnimating else { return }
        
        isExpanded = true
        
        let operations = {
            var titleFrame = self.titleContainer.frame
            switch self.titlePosition {
            case .left:
                titleFrame.origin.x = 0
            case .right:
                titleFrame.origin.x = self.button.frame.size.width + self.internMargin
            }
            titleFrame.size.width = self.titleContainerSize.width
            self.titleContainer.frame = titleFrame
            self.titleContainer.alpha = 1.0
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
    
    open func reduce(animated: Bool, duration: TimeInterval) {
        guard isExpanded && !isAnimating else { return }
        
        isExpanded = false
        
        let operations = {
            var titleFrame = self.titleContainer.frame
            titleFrame.origin.x = self.button.center.x
            titleFrame.size.width = 0
            self.titleContainer.frame = titleFrame
            self.titleContainer.alpha = 0.0
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
    
    func didTouch(sender: UIButton) {
        self.delegate?.didTouch(item: self)
        self.action?()
    }
    
    
    /* Customization */
    
    open func setShadow(color: UIColor, opacity: Float, radius: CGFloat, offset: CGSize) {
        button.layer.shadowColor = color.cgColor
        button.layer.shadowOpacity = opacity
        button.layer.shadowRadius = radius
        button.layer.shadowOffset = offset
    }
    
    
    /* Observers */
    
    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if (object as? UIButton) === tapButton && keyPath == "highlighted" {
            button.isHighlighted = tapButton.isHighlighted
        }
    }
}


// MARK: - Private Helpers
extension UPActionButtonItem {

    /* Interactions */
    
    fileprivate func updateElementsSizes() {
        let titleSize = titleContainerSize
        
        var frame = self.frame
        frame.size.width = titleSize.width + internMargin + size.width
        frame.size.height = max(titleSize.height, size.height)
        self.frame = frame
        
        titleContainer.frame = CGRect(origin: .zero, size: titleSize)
        titleLabel.frame = CGRect(origin: CGPoint(x: titleInsets.left, y: titleInsets.top), size: titleLabelSize)
        button.frame = CGRect(origin: .zero, size: size)
        button.layer.cornerRadius = min(size.width, size.height) / 2.0
    }
    
    fileprivate func layoutElements() {
        let titleSize = titleContainer.frame.size
        let buttonSize = button.frame.size
        
        switch titlePosition {
        case .left:
            titleContainer.center = CGPoint(x: titleSize.width/2.0, y: self.frame.size.height/2.0)
            button.center = CGPoint(x: self.frame.size.width - buttonSize.width/2.0, y: self.frame.size.height/2.0)
        case .right:
            button.center = CGPoint(x: buttonSize.width/2.0, y: self.frame.size.height/2.0)
            titleContainer.center = CGPoint(x: self.frame.size.width - titleSize.width/2.0, y: self.frame.size.height/2.0)
        }
        
        var anchorPoint = CGPoint(x: 0.5, y: 0.5)
        if self.frame.size.width > 0 {
            anchorPoint.x = button.center.x / self.frame.size.width
        }
        if self.frame.size.height > 0 {
            anchorPoint.y = button.center.y / self.frame.size.height
        }
        self.layer.anchorPoint = anchorPoint
        
        if isExpanded {
            isExpanded = false
            expand(animated: false, duration: 0)
        } else {
            isExpanded = true
            reduce(animated: false, duration: 0)
        }
    }

}
