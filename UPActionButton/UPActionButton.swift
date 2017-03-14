//
//  UPActionButton.swift
//  UPActionButtonDemo
//
//  Created by Paul Ulric on 28/02/2017.
//  Copyright © 2017 Paul Ulric. All rights reserved.
//

import UIKit


@objc public protocol UPActionButtonDelegate {
    @objc optional func actionButtonWillOpen(_: UPActionButton)
    @objc optional func actionButtonDidOpen(_: UPActionButton)
    @objc optional func actionButtonWillClose(_: UPActionButton)
    @objc optional func actionButtonDidClose(_: UPActionButton)
}

public enum UPActionButtonItemsPosition {
    case up
    case down
}

public enum UPActionButtonTransitionType {
    case none
    case rotate(CGFloat)
    case crossDissolveImage(UIImage)
    case crossDissolveText(String)
}

public enum UPActionButtonDisplayAnimationType {
    case none
    case slideUp
    case slideDown
    case slideLeft
    case slideRight
    case scaleUp
    case scaleDown
}

open class UPActionButton: UIView {
    
    // MARK: - Properties
    fileprivate var backgroundView: UIView!
    fileprivate var containerView: UIView!
    fileprivate var button: UIButton!
    fileprivate var openTitleLabel: UILabel!
    fileprivate var closedTitleLabel: UILabel!
    fileprivate var openTitleImageView: UIImageView!
    fileprivate var closedTitleImageView: UIImageView!
    fileprivate var visibleOpenTitleView: UIView? {
        if openTitleImageView.image != nil {
            return openTitleImageView
        }
        if openTitleLabel.text != nil {
            return openTitleLabel
        }
        return nil
    }
    
    fileprivate var containerOpenSize: CGSize = .zero
    fileprivate var buttonOpenCenter: CGPoint = .zero
    fileprivate var isAnimating = false
    fileprivate var animatedItemTag: Int = 0
    
    fileprivate let superviewBoundsKeyPath = "layer.bounds"
    fileprivate var observesSuperviewBounds = false
    fileprivate let scrollviewScrollKeyPath = "contentOffset"
    fileprivate var observesScrollview = false
    
    fileprivate(set) var items = [UPActionButtonItem]()
    
    public var delegate: UPActionButtonDelegate?
    
    public var observedScrollView: UIScrollView? {
        didSet {
            if let scrollView = oldValue, observesScrollview {
                scrollView.removeObserver(self, forKeyPath: scrollviewScrollKeyPath)
                observesScrollview = false
            }
            if let scrollView = observedScrollView {
                scrollView.addObserver(self, forKeyPath: scrollviewScrollKeyPath, options: .new, context: nil)
                observesScrollview = true
            }
        }
    }
    
    public var isOpen = false
    
    /* Customization */
    public var itemsPosition: UPActionButtonItemsPosition = .up {
        didSet {
            computeOpenSize()
        }
    }
    public var itemSize: CGSize = CGSize(width: 30, height: 30) {
        didSet {
            items.forEach({ $0.size = itemSize })
        }
    }
    public var itemsInterSpacing: CGFloat = 10.0
    public var animationDuration: TimeInterval = 0.6
    public var transitionType: UPActionButtonTransitionType = .none
    public var showAnimationType: UPActionButtonDisplayAnimationType = .none
    public var hideAnimationType: UPActionButtonDisplayAnimationType = .none
    public var image: UIImage? {
        get { return openTitleImageView.image }
        set {
            openTitleImageView.image = newValue
            openTitleImageView.isHidden = false
            openTitleLabel.text = nil
            openTitleLabel.isHidden = true
        }
    }
    public var title: String? {
        get { return openTitleLabel.text }
        set {
            openTitleLabel.text = newValue
            openTitleLabel.isHidden = false
            openTitleImageView.image = nil
            openTitleImageView.isHidden = true
        }
    }
    public var titleColor: UIColor {
        get { return openTitleLabel.textColor }
        set {
            openTitleLabel.textColor = newValue
            closedTitleLabel.textColor = newValue
        }
    }
    public var font: UIFont {
        get { return openTitleLabel.font }
        set {
            openTitleLabel.font = newValue
            closedTitleLabel.font = newValue
        }
    }
    public var color: UIColor? {
        get { return button.backgroundColor }
        set { button.backgroundColor = newValue }
    }
    public var cornerRadius: CGFloat {
        get { return button.layer.cornerRadius }
        set { button.layer.cornerRadius = newValue }
    }
    public var overlayColor: UIColor? {
        get { return backgroundView.backgroundColor }
        set { backgroundView.backgroundColor = newValue }
    }
    
    
    // MARK: - Initialization
    public init(frame: CGRect, image: UIImage?, title: String?) {
        super.init(frame: frame)
        
        let innerFrame = CGRect(origin: .zero, size: frame.size)
        
        backgroundView = UIView(frame: innerFrame)
        backgroundView.isHidden = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggle))
        backgroundView.addGestureRecognizer(tapGesture)
        self.overlayColor = UIColor(white: 1.0, alpha: 0.4)
        self.addSubview(backgroundView)
        
        containerView = UIView(frame: innerFrame)
        //        containerView.clipsToBounds = true
        self.addSubview(containerView)
        
        button = UIButton(type: .custom)
        button.frame = innerFrame
        button.addTarget(self, action: #selector(toggle), for: .touchUpInside)
        containerView.addSubview(button)
        
        openTitleLabel = UILabel()
        closedTitleLabel = UILabel()
        [openTitleLabel, closedTitleLabel].forEach { (label: UILabel) in
            label.frame = innerFrame.insetBy(dx: 10, dy: 10)
            label.alpha = 0.0
            label.isHidden = true
            label.textAlignment = .center
            button.addSubview(label)
        }
        
        openTitleImageView = UIImageView()
        closedTitleImageView = UIImageView()
        [openTitleImageView, closedTitleImageView].forEach { (image: UIImageView!) in
            image.frame = innerFrame.insetBy(dx: 10, dy: 10)
            image.alpha = 0.0
            image.isHidden = true
            image.contentMode = .scaleAspectFill
            button.addSubview(image)
        }
        
        if let image = image {
            self.image = image
            openTitleImageView.alpha = 1.0
        } else if let title = title {
            self.title = title
            openTitleLabel.alpha = 1.0
        }
    }
    
    override open func willMove(toSuperview newSuperview: UIView?) {
        if let superview = newSuperview {
            superview.addObserver(self, forKeyPath: superviewBoundsKeyPath, options: .new, context: nil)
            observesSuperviewBounds = true
        } else if let superview = self.superview, observesSuperviewBounds {
            superview.removeObserver(self, forKeyPath: superviewBoundsKeyPath)
            observesSuperviewBounds = false
        }
        
        super.willMove(toSuperview: newSuperview)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        if let superview = self.superview, observesSuperviewBounds {
            superview.removeObserver(self, forKeyPath: superviewBoundsKeyPath)
            observesSuperviewBounds = false
        }
        if let scrollView = observedScrollView, observesScrollview {
            scrollView.removeObserver(self, forKeyPath: scrollviewScrollKeyPath)
            observesScrollview = false
        }
    }
    
}


// MARK: - Public API
extension UPActionButton {
    
    /* Items management */
    
    open func add(item: UPActionButtonItem) {
        add(item: item, computeSize: true)
    }
    
    open func add(items: [UPActionButtonItem]) {
        items.forEach({ self.add(item: $0, computeSize: false) })
        computeOpenSize()
    }
    
    open func remove(item: UPActionButtonItem) {
        remove(item: item, computeSize: true)
    }
    
    open func remove(itemAt index: Int) {
        guard index >= 0 && index < items.count else { return }
        
        remove(item: items[index], computeSize: true)
    }
    
    open func removeAllItems() {
        items.forEach({ self.remove(item: $0, computeSize: false) })
        computeOpenSize()
    }
    
    
    /* Interactions */
    
    open func toggle() {
        if isOpen {
            close()
        } else {
            open()
        }
    }
    
    open func open() {
        guard let superFrame = self.superview?.frame else { return }
        guard !isOpen && !isAnimating else { return }
        
        delegate?.actionButtonWillOpen?(self)
        
        isAnimating = true
        animatedItemTag = 0
        
        expandContainers(to: superFrame)
        expandItems()
        transitionButtonTitle()
    }
    
    open func close() {
        guard isOpen && !isAnimating else { return }
        
        delegate?.actionButtonWillClose?(self)
        
        isAnimating = true
        animatedItemTag = 0
        
        reduceItems()
        transitionButtonTitle()
    }
    
    
    /* Display */
    
    open func show(animated: Bool = true) {
        guard isHidden else { return }
        
        if showAnimationType == .none || !animated {
            self.isHidden = false
            return
        }
        
        let animation = appearAnimations(type: showAnimationType)
        
        animation.preparation?()
        UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseInOut, animations: {
            animation.animation?()
        }) { (finished: Bool) in
            animation.completion?()
        }
    }
    
    open func hide(animated: Bool = true) {
        guard !isHidden else { return }
        
        if showAnimationType == .none || !animated {
            self.isHidden = true
            return
        }
        
        let animation = disappearAnimations(type: hideAnimationType)
        
        animation.preparation?()
        UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseInOut, animations: {
            animation.animation?()
        }) { (finished: Bool) in
            animation.completion?()
        }
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
        if keyPath == superviewBoundsKeyPath {
            guard let superview = self.superview, isOpen else { return }
            
            let superFrame = CGRect(origin: .zero, size: superview.frame.size)
            self.frame = superFrame
            backgroundView.frame = superFrame
        }
        else if keyPath == scrollviewScrollKeyPath {
            // TODO
            //print(observedScrollView?.contentOffset)
        }
    }
}


// MARK: - UPActionButtonItem Delegate Methods
extension UPActionButton: UPActionButtonItemDelegate {
    
    public func didTouch(item: UPActionButtonItem) {
        guard item.closeOnTap else { return }
        self.close()
    }
    
}


// MARK: - Private Helpers
extension UPActionButton: CAAnimationDelegate {
    
    /* Items Management */
    
    fileprivate func add(item: UPActionButtonItem, computeSize compute: Bool) {
        item.delegate = self
        items.append(item)
        
        item.size = itemSize
        item.reduce(animated: false, duration: 0)
        item.itemCenter = button.center
        
        containerView.insertSubview(item, at: 0)
        
        if compute {
            computeOpenSize()
        }
    }
    
    fileprivate func remove(item: UPActionButtonItem, computeSize compute: Bool) {
        guard let index = items.index(of: item) else { return }
        
        item.removeFromSuperview()
        items.remove(at: index)
        
        if compute {
            computeOpenSize()
        }
    }
    
    
    /* Interactions */
    
    fileprivate func computeOpenSize() {
        let center = CGPoint(x: button.frame.size.width / 2.0, y: button.frame.size.height / 2.0)
        var height: CGFloat = button.frame.size.height
        var leftOffset: CGFloat = 0
        var rightOffset: CGFloat = 0
        
        items.forEach { (item: UPActionButtonItem) in
            height += item.frame.size.height + self.itemsInterSpacing
            
            switch item.titlePosition {
            case .left:
                let itemLeftOffset = CGFloat(fabs(center.x - item.itemCenter.x))
                leftOffset = max(leftOffset, itemLeftOffset)
            case .right:
                let itemRightOffset = CGFloat(fabs(item.frame.size.width - item.itemCenter.x - center.x))
                rightOffset = max(rightOffset, itemRightOffset)
            }
            
        }
        
        if items.count > 0 {
            height += itemsInterSpacing
        }
        let width: CGFloat = leftOffset + button.frame.size.width + rightOffset
        
        containerOpenSize = CGSize(width: width, height: height)
        var baseButtonCenterY: CGFloat = 0
        
        switch itemsPosition {
        case .up:
            baseButtonCenterY = containerOpenSize.height - button.frame.size.height / 2.0
        case .down:
            baseButtonCenterY = button.frame.size.height / 2.0
        }
        
        buttonOpenCenter = CGPoint(x: leftOffset + button.frame.size.width / 2.0, y: baseButtonCenterY)
    }
    
    fileprivate func expandContainers(to: CGRect) {
        let origin = self.frame.origin
        
        let superFrame = CGRect(origin: .zero, size: to.size)
        self.frame = superFrame
        backgroundView.frame = superFrame
        backgroundView.alpha = 0.0
        backgroundView.isHidden = false
        
        var containerFrame = containerView.frame
        containerFrame.origin = origin
        containerFrame.size = containerOpenSize
        containerFrame.origin.x -= buttonOpenCenter.x - button.frame.size.width / 2.0
        if itemsPosition == .up {
            let yOffset: CGFloat = buttonOpenCenter.y - button.frame.size.height / 2.0
            containerFrame.origin.y -= yOffset
        }
        containerView.frame = containerFrame
        
        button.center = buttonOpenCenter
        
        items.forEach({ $0.itemCenter = button.center })
    }
    
    fileprivate func expandItems() {
        UIView.animate(withDuration: animationDuration) {
            self.backgroundView.alpha = 1.0
        }
        
        var way: CGFloat = -1
        var y = button.frame.origin.y - itemsInterSpacing
        if itemsPosition == .down {
            way = 1
            y = button.frame.origin.y + button.frame.size.height + itemsInterSpacing
        }
        for (index, item) in self.items.enumerated() {
            //            let duration = Double(index+1) * animationDuration / Double(items.count)
            let duration = Double(items.count - index) * animationDuration / Double(items.count)
            
            let center = CGPoint(x: button.center.x, y: y + (item.frame.size.height / 2.0 * way))
            let normalizedCenter = item.centerForItemCenter(center)
            
            // TODO: delay
            move(item: item, to: normalizedCenter, duration: duration, opening: true, bouncing: true)
            item.expand(animated: true, duration: duration)
            
            y += (item.frame.size.height + itemsInterSpacing) * way
        }
    }
    
    fileprivate func reduceContainers() {
        let baseOrigin = containerView.convert(button.frame.origin, to: self)
        let baseSize = button.frame.size
        let frame = CGRect(origin: baseOrigin, size: baseSize)
        let innerFrame = CGRect(origin: CGPoint(x: 0, y: 0), size: baseSize)
        
        backgroundView.frame = frame
        backgroundView.isHidden = true
        self.frame = frame
        containerView.frame = innerFrame
        button.frame = innerFrame
        
        items.forEach({ $0.itemCenter = button.center })
    }
    
    fileprivate func reduceItems() {
        
        for (index, item) in self.items.enumerated() {
            //            let duration = Double(index+1) * animationDuration / Double(items.count)
            let duration = Double(items.count - index) * animationDuration / Double(items.count)
            
            let normalizedCenter = item.centerForItemCenter(button.center)
            
            // TODO: delay
            move(item: item, to: normalizedCenter, duration: duration, opening: false, bouncing: true)
            item.reduce(animated: true, duration: duration)
        }
        
        UIView.animate(withDuration: animationDuration, animations: {
            self.backgroundView.alpha = 0.0
        }) { (finished: Bool) in
            
        }
    }
    
    fileprivate func move(item: UPActionButtonItem, to center: CGPoint, duration: TimeInterval, opening: Bool, bouncing: Bool) {
        let animation = CAKeyframeAnimation(keyPath: "position")
        
        let path = CGMutablePath()
        path.move(to: item.center)
        if bouncing {
            var bouncingOffset: CGFloat = itemsInterSpacing
            if itemsPosition == .up {
                bouncingOffset *= -1
            }
            if opening {
                path.addLine(to: CGPoint(x: center.x, y: center.y + bouncingOffset))
                path.addLine(to: CGPoint(x: center.x, y: center.y - (bouncingOffset / 2.0)))
            } else {
                path.addLine(to: CGPoint(x: item.center.x, y: item.center.y + bouncingOffset))
            }
        }
        path.addLine(to: center)
        animation.path = path
        
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
        animation.delegate = self
        item.layer.add(animation, forKey: "positionAnimation")
        
        item.center = center
    }
    
    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        animatedItemTag += 1
        guard animatedItemTag >= items.count else { return }
        
        isOpen = !isOpen
        if isOpen {
            delegate?.actionButtonDidOpen?(self)
        }
        else {
            reduceContainers()
            delegate?.actionButtonDidClose?(self)
        }
        
        isAnimating = false
    }
    
    fileprivate func transitionButtonTitle() {
        let duration = animationDuration / 2.0
        let opening = !isOpen
        
        switch transitionType {
        case .none: break
            
        case .rotate(let angle):
            guard let titleView = self.visibleOpenTitleView else { return }
            UIView.animate(withDuration: duration, delay: 0.0, usingSpringWithDamping: 0.7, initialSpringVelocity: 5.0, options: .curveEaseInOut, animations: {
                titleView.transform = opening ? CGAffineTransform(rotationAngle: angle) : CGAffineTransform.identity
            }, completion: nil)
            
        case .crossDissolveText(let title):
            if opening {
                closedTitleLabel.text = title
            }
            closedTitleLabel.isHidden = false
            visibleOpenTitleView?.isHidden = false
            UIView.animate(withDuration: duration, animations: {
                self.visibleOpenTitleView?.alpha = opening ? 0.0 : 1.0
                self.closedTitleLabel.alpha = opening ? 1.0 : 0.0
            }, completion: { (finished: Bool) in
                self.visibleOpenTitleView?.isHidden = opening
                self.closedTitleLabel.isHidden = !opening
            })
            
        case .crossDissolveImage(let image):
            if opening {
                closedTitleImageView.image = image
            }
            closedTitleImageView.isHidden = false
            visibleOpenTitleView?.isHidden = false
            UIView.animate(withDuration: duration, animations: {
                self.visibleOpenTitleView?.alpha = opening ? 0.0 : 1.0
                self.closedTitleImageView.alpha = opening ? 1.0 : 0.0
            }, completion: { (finished: Bool) in
                self.visibleOpenTitleView?.isHidden = opening
                self.closedTitleImageView.isHidden = !opening
            })
        }
    }
    
    fileprivate func appearAnimations(type: UPActionButtonDisplayAnimationType) -> (preparation: (() -> Void)?, animation: (() -> Void)?, completion: (() -> Void)?) {
        
        let initialContainerFrame = containerView.frame
        let translationOffset: CGFloat = 20.0
        let scaleOffset: CGFloat = 0.5
        
        return (preparation: {
            var containerFrame = self.containerView.frame
            switch type {
            case .none: break
            case .slideDown:
                containerFrame.origin.y -= translationOffset
                self.containerView.frame = containerFrame
            case .slideUp:
                containerFrame.origin.y += translationOffset
                self.containerView.frame = containerFrame
            case .slideLeft:
                containerFrame.origin.x += translationOffset
                self.containerView.frame = containerFrame
            case .slideRight:
                containerFrame.origin.x -= translationOffset
                self.containerView.frame = containerFrame
            case .scaleDown:
                self.containerView.transform = CGAffineTransform(scaleX: 1 + scaleOffset, y: 1 + scaleOffset)
            case .scaleUp:
                self.containerView.transform = CGAffineTransform(scaleX: 1 - scaleOffset, y: 1 - scaleOffset)
            }
            
            self.isHidden = false
            self.containerView.alpha = 0.0
        }, animation: {
            self.containerView.transform = CGAffineTransform.identity
            self.containerView.frame = initialContainerFrame
            self.containerView.alpha = 1.0
        }, completion: nil)
    }
    
    fileprivate func disappearAnimations(type: UPActionButtonDisplayAnimationType) -> (preparation: (() -> Void)?, animation: (() -> Void)?, completion: (() -> Void)?) {
        
        let initialContainerFrame = containerView.frame
        let translationOffset: CGFloat = 20.0
        let scaleOffset: CGFloat = 0.5
        
        return (preparation: {
            self.containerView.alpha = 1.0
        }, animation: {
            var containerFrame = self.containerView.frame
            switch type {
            case .none: break
            case .slideDown:
                containerFrame.origin.y += translationOffset
                self.containerView.frame = containerFrame
            case .slideUp:
                containerFrame.origin.y -= translationOffset
                self.containerView.frame = containerFrame
            case .slideLeft:
                containerFrame.origin.x -= translationOffset
                self.containerView.frame = containerFrame
            case .slideRight:
                containerFrame.origin.x += translationOffset
                self.containerView.frame = containerFrame
            case .scaleDown:
                self.containerView.transform = CGAffineTransform(scaleX: 1 - scaleOffset, y: 1 - scaleOffset)
            case .scaleUp:
                self.containerView.transform = CGAffineTransform(scaleX: 1 + scaleOffset, y: 1 + scaleOffset)
            }
            
            self.containerView.alpha = 0.0
        }, completion: {
            self.isHidden = true
            self.containerView.transform = CGAffineTransform.identity
            self.containerView.frame = initialContainerFrame
        })
    }
}
