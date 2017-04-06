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

public enum UPActionButtonPosition {
    case free(center: CGPoint)
    case topLeft(padding: CGPoint)
    case topRight(padding: CGPoint)
    case bottomLeft(padding: CGPoint)
    case bottomRight(padding: CGPoint)
}

public enum UPActionButtonDisplayAnimationType {
    case none
    case slideUp, slideDown, slideLeft, slideRight
    case scaleUp, scaleDown
}

public enum UPActionButtonTransitionType {
    case none
    case rotate(degrees: CGFloat)
    case crossDissolveImage(UIImage)
    case crossDissolveText(String)
}

public enum UPActionButtonOverlayType {
    case plain(UIColor)
    case blurred(UIVisualEffect)
}

public enum UPActionButtonOverlayAnimationType {
    case none
    case fade
    case bubble
}

public enum UPActionButtonItemsPosition {
    case up
    case down
    case round, roundHalfUp, roundHalfRight, roundHalfDown, roundHalfLeft
    case roundQuarterUp, roundQuarterUpRight, roundQuarterRight, roundQuarterDownRight
    case roundQuarterDown, roundQuarterDownLeft, roundQuarterLeft, roundQuarterUpLeft
}

public enum UPActionButtonItemsAnimationType {
    case none
    case fade, fadeUp, fadeDown, fadeLeft, fadeRight
    case scaleUp, scaleDown
    case slide
    case bounce
}

public enum UPActionButtonItemsAnimationOrder {
    case linear, progressive, progressiveInverse
}


open class UPActionButton: UIView {
    
    fileprivate enum ScrollDirection {
        case none, up, down
    }
    
    fileprivate typealias AnimationSteps = (preparation: (() -> Void)?, animation: (() -> Void)?, completion: (() -> Void)?)
    
    // MARK: - Properties
    fileprivate var backgroundView: UIVisualEffectView!
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
    fileprivate var isAnimatingOpenClose = false
    fileprivate var isAnimatingShowHide = false
    
    fileprivate let slideAnimationOffset: CGFloat = 20.0
    fileprivate let scaleAnimationOffset: CGFloat = 0.5
    
    fileprivate var observesSuperviewBounds = false
    fileprivate var observesSuperviewContentOffset = false
    fileprivate var observesInteractiveScrollView = false
    
    fileprivate var scrollCurrentDirection: ScrollDirection = .none
    fileprivate var scrollStartOffset: CGFloat = 0
    fileprivate var scrollLastOffset: CGFloat = 0
    fileprivate let interactiveScrollDistance: CGFloat = 64.0
    
    fileprivate(set) var items = [UPActionButtonItem]()
    public fileprivate(set) var isOpen = false
    
    public var delegate: UPActionButtonDelegate?

    @IBOutlet public var interactiveScrollView: UIScrollView? {
        didSet {
            if let scrollView = oldValue, observesInteractiveScrollView {
                scrollView.removeObserver(self, forKeyPath: "contentOffset")
                observesInteractiveScrollView = false
            }
            if let scrollView = interactiveScrollView {
                scrollView.addObserver(self, forKeyPath: "contentOffset", options: [.old, .new], context: nil)
                observesInteractiveScrollView = true
            }
        }
    }
    @IBInspectable public var floating: Bool = false {
        didSet {
            if !floating && observesSuperviewContentOffset {
                self.superview?.removeObserver(self, forKeyPath: "contentOffset")
                observesSuperviewContentOffset = false
            }
            if let superview = self.superview as? UIScrollView, floating {
                superview.addObserver(self, forKeyPath: "contentOffset", options: [.old, .new], context: nil)
                observesSuperviewContentOffset = true
            }
        }
    }
    
    /* Customization */
    public var animationDuration: TimeInterval = 0.3
    // Button
    public var position: UPActionButtonPosition = .free(center: .zero) {
        didSet {
            updateButtonPosition()
        }
    }
    public var showAnimationType: UPActionButtonDisplayAnimationType = .none
    public var hideAnimationType: UPActionButtonDisplayAnimationType = .none
    public var buttonTransitionType: UPActionButtonTransitionType = .none
    @IBInspectable public var image: UIImage? {
        get { return openTitleImageView.image }
        set {
            openTitleImageView.image = newValue
            openTitleImageView.isHidden = false
            openTitleImageView.alpha = 1.0
            openTitleLabel.text = nil
            openTitleLabel.isHidden = true
        }
    }
    @IBInspectable public var title: String? {
        get { return openTitleLabel.text }
        set {
            openTitleLabel.text = newValue
            openTitleLabel.isHidden = false
            openTitleLabel.alpha = 1.0
            openTitleImageView.image = nil
            openTitleImageView.isHidden = true
        }
    }
    @IBInspectable public var titleColor: UIColor {
        get { return openTitleLabel.textColor }
        set {
            openTitleLabel.textColor = newValue
            closedTitleLabel.textColor = newValue
        }
    }
    public var titleFont: UIFont {
        get { return openTitleLabel.font }
        set {
            openTitleLabel.font = newValue
            closedTitleLabel.font = newValue
        }
    }
    @IBInspectable public var color: UIColor? {
        get { return button.backgroundColor }
        set { button.backgroundColor = newValue }
    }
    @IBInspectable public var cornerRadius: CGFloat {
        get { return button.layer.cornerRadius }
        set { button.layer.cornerRadius = newValue }
    }
    // Overlay
    public var overlayType: UPActionButtonOverlayType? {
        didSet {
            let type: UPActionButtonOverlayType = overlayType ?? .plain(.clear)
            switch type {
            case .plain(let color):
                backgroundView.backgroundColor = color
                backgroundView.effect = nil
            case .blurred(let visualEffect):
                guard self.overlayAnimationType != .bubble else {
                    print("[UPActionButton] The blurred overlay type is not compatible with the bubble overlay animation")
                    self.overlayType = oldValue
                    return
                }
                backgroundView.backgroundColor = .clear
                backgroundView.effect = visualEffect
                print(backgroundView)
            }
        }
    }
    public var overlayAnimationType: UPActionButtonOverlayAnimationType = .none {
        didSet {
            if self.overlayType != nil, case .blurred(_) = self.overlayType!, overlayAnimationType == .bubble {
                print("[UPActionButton] The bubble overlay animation is not compatible with the blurred overlay type")
                self.overlayAnimationType = oldValue
                return
            }
        }
    }
    // Items
    public var itemsPosition: UPActionButtonItemsPosition = .up {
        didSet {
            computeOpenSize()
        }
    }
    @IBInspectable public var itemSize: CGSize = CGSize(width: 30, height: 30) {
        didSet {
            items.forEach({ $0.size = itemSize })
        }
    }
    @IBInspectable public var itemsInterSpacing: CGFloat = 10.0 {
        didSet {
            computeOpenSize()
        }
    }
    public var itemsAnimationType: UPActionButtonItemsAnimationType = .none
    public var itemsAnimationOrder: UPActionButtonItemsAnimationOrder = .linear
    
    
    // MARK: - Initialization
    
    public init(frame: CGRect, image: UIImage?, title: String?) {
        super.init(frame: frame)
        
        setupElements()
        
        if let image = image {
            self.image = image
        } else if let title = title {
            self.title = title
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setupElements()
    }
    
    deinit {
        if let superview = self.superview {
            if observesSuperviewBounds {
                superview.removeObserver(self, forKeyPath: "frame")
                observesSuperviewBounds = false
            }
            if observesSuperviewContentOffset {
                superview.removeObserver(self, forKeyPath: "contentOffset")
                observesSuperviewContentOffset = false
            }
        }
        if let scrollView = interactiveScrollView, observesInteractiveScrollView {
            scrollView.removeObserver(self, forKeyPath: "contentOffset")
            observesInteractiveScrollView = false
        }
    }
    
    
    override open func willMove(toSuperview newSuperview: UIView?) {
        if let superview = self.superview {
            if observesSuperviewBounds {
                superview.removeObserver(self, forKeyPath: "frame")
                observesSuperviewBounds = false
            }
            if observesSuperviewContentOffset {
                superview.removeObserver(self, forKeyPath: "contentOffset")
                observesSuperviewContentOffset = false
            }
        }
        
        super.willMove(toSuperview: newSuperview)
    }
    
    override open func didMoveToSuperview() {
        if let superview = self.superview {
            
            updateButtonPosition()
            
            superview.addObserver(self, forKeyPath: "frame", options: [.old, .new], context: nil)
            observesSuperviewBounds = true
            if (floating && superview is UIScrollView) {
                superview.addObserver(self, forKeyPath: "contentOffset", options: [.old, .new], context: nil)
                observesSuperviewContentOffset = true
            }
        }
        
        super.didMoveToSuperview()
    }
    
    
    // MARK: - UI Elements Setup
    
    func setupElements() {
        let innerFrame = CGRect(origin: .zero, size: self.frame.size)
        
        self.backgroundColor = .clear
        
        backgroundView = UIVisualEffectView(frame: innerFrame)
        backgroundView.isHidden = true
        let backgroundTapGesture = UITapGestureRecognizer(target: self, action: #selector(toggle))
        backgroundView.addGestureRecognizer(backgroundTapGesture)
        self.addSubview(backgroundView)
        
        containerView = UIView(frame: innerFrame)
        let containerTapGesture = UITapGestureRecognizer(target: self, action: #selector(toggle))
        containerView.addGestureRecognizer(containerTapGesture)
        self.addSubview(containerView)
        
        button = UIButton(type: .custom)
        button.frame = innerFrame
        button.addTarget(self, action: #selector(toggle), for: .touchUpInside)
        containerView.addSubview(button)
        
        openTitleLabel = UILabel()
        closedTitleLabel = UILabel()
        [openTitleLabel, closedTitleLabel].forEach { (label: UILabel) in
            label.frame = innerFrame
            label.alpha = 0.0
            label.isHidden = true
            label.textAlignment = .center
            button.addSubview(label)
        }
        
        openTitleImageView = UIImageView()
        closedTitleImageView = UIImageView()
        [openTitleImageView, closedTitleImageView].forEach { (image: UIImageView!) in
            image.frame = innerFrame
            image.alpha = 0.0
            image.isHidden = true
            image.contentMode = .scaleAspectFill
            button.addSubview(image)
        }
        
        let center = CGPoint(x: self.frame.origin.x + self.frame.size.width / 2, y: self.frame.origin.y + self.frame.size.height / 2)
        self.position = .free(center: center)
        
        setDefaultConfiguration()
    }
    
    func setDefaultConfiguration() {
        showAnimationType = .scaleUp
        hideAnimationType = .scaleDown
        color = .blue
        let midSize = min(frame.size.width, frame.size.height) / 2
        cornerRadius = midSize
        setShadow(color: .black, opacity: 0.5, radius: 3.0, offset: CGSize(width: 0, height: 2))
        titleColor = .white
        titleFont = UIFont.systemFont(ofSize: midSize)
        let inset = midSize / 2
        setTitleInset(dx: inset, dy: inset)
        overlayType = .plain(UIColor(white: 0.0, alpha: 0.3))
        overlayAnimationType = .fade
        itemsPosition = .up
        itemsAnimationType = .bounce
        itemsAnimationOrder = .progressive
        itemSize = CGSize(width: midSize, height: midSize)
    }
}


// MARK: - Public API
extension UPActionButton {
    
    /* Customization */
    
    open func setShadow(color: UIColor, opacity: Float, radius: CGFloat, offset: CGSize) {
        button.layer.shadowColor = color.cgColor
        button.layer.shadowOpacity = opacity
        button.layer.shadowRadius = radius
        button.layer.shadowOffset = offset
    }
    
    open func setTitleTextOffset(_ offset: CGPoint) {
        [openTitleLabel, closedTitleLabel].forEach { (label: UIView) in
            var anchorPoint = CGPoint(x: 0.5, y: 0.5)
            anchorPoint.x += offset.x / label.frame.size.width
            anchorPoint.y += offset.y / label.frame.size.height
            label.layer.anchorPoint = anchorPoint
        }
    }
    
    open func setTitleInset(dx: CGFloat, dy: CGFloat) {
        [openTitleLabel, closedTitleLabel, openTitleImageView, closedTitleImageView].forEach { (view: UIView) in
            view.frame = self.button.frame.insetBy(dx: dx, dy: dy)
        }
    }
    
    
    /* Display */
    
    open func show(animated: Bool = true) {
        guard isHidden && !isAnimatingShowHide else { return }
        
        if showAnimationType == .none || !animated {
            self.isHidden = false
            return
        }
        
        let animation = appearAnimations(type: showAnimationType)
        
        isAnimatingShowHide = true
        
        animation.preparation?()
        UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseInOut, animations: {
            animation.animation?()
        }) { (finished: Bool) in
            animation.completion?()
            self.isAnimatingShowHide = false
        }
    }
    
    open func hide(animated: Bool = true) {
        guard !isHidden && !isAnimatingShowHide else { return }
        
        if showAnimationType == .none || !animated {
            self.isHidden = true
            return
        }
        
        let animation = disappearAnimations(type: hideAnimationType)
        
        isAnimatingShowHide = true
        
        animation.preparation?()
        UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseInOut, animations: {
            animation.animation?()
        }) { (finished: Bool) in
            animation.completion?()
            self.isAnimatingShowHide = false
        }
    }
    
    
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
        guard !isOpen && !isAnimatingOpenClose else { return }
        
        delegate?.actionButtonWillOpen?(self)
        
        isAnimatingOpenClose = true
        expandContainers()
        expandOverlay()
        expandItems()
        transitionButtonTitle()
    }
    
    open func close() {
        guard isOpen && !isAnimatingOpenClose else { return }
        
        delegate?.actionButtonWillClose?(self)
        
        isAnimatingOpenClose = true
        reduceOverlay()
        reduceItems()
        transitionButtonTitle()
    }
    
    
    /* Observers */
    
    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let newValue = change?[.newKey] as? NSObject,
            let oldValue = change?[.oldKey] as? NSObject,
            newValue == oldValue {
            return
        }
        if (object as? UIView) == superview && keyPath == "frame" {
            guard let superview = self.superview else { return }
            
            if isOpen {
                let superFrame = CGRect(origin: .zero, size: superview.frame.size)
                self.frame = superFrame
                backgroundView.frame = superFrame
            }
            
            self.updateButtonPosition()
        }
        
        if (object as? UIView) == superview && keyPath == "contentOffset" && floating {
            guard let scrollView = self.superview as? UIScrollView else { return }
            
            if isOpen {
                var frame = self.frame
                frame.origin.y = scrollView.contentOffset.y
                self.frame = frame
            } else {
                self.updateButtonPosition()
            }
        }
        
        if (object as? UIScrollView) == interactiveScrollView && keyPath == "contentOffset" {
            guard let scrollView = interactiveScrollView, !isOpen else { return }
            
            handleInteractiveScroll(from: scrollView)
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


// MARK: - Private Helpers (Items)
extension UPActionButton/*: CAAnimationDelegate*/ {
    
    /* Items Management */
    
    fileprivate func add(item: UPActionButtonItem, computeSize compute: Bool) {
        item.delegate = self
        items.append(item)
        
        item.size = itemSize
        item.center = button.center
        
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
    
    fileprivate func expandContainers() {
        let origin = self.frame.origin
        
        var superOrigin: CGPoint = .zero
        if let superScrollview = self.superview as? UIScrollView {
            superOrigin = superScrollview.contentOffset
        }
        let superSize: CGSize = superview?.frame.size ?? .zero
        let superFrame = CGRect(origin: superOrigin, size: superSize)
        self.frame = superFrame
        
        var containerFrame = containerView.frame
        containerFrame.origin = CGPoint(x: origin.x - superOrigin.x, y: origin.y - superOrigin.y)
        containerFrame.size = containerOpenSize
        containerFrame.origin.x -= buttonOpenCenter.x - button.frame.size.width / 2.0
        containerFrame.origin.y -= buttonOpenCenter.y - button.frame.size.height / 2.0
        containerView.frame = containerFrame
        
        button.center = buttonOpenCenter
        
        items.forEach({ $0.center = button.center })
    }
    
    fileprivate func expandOverlay() {
        backgroundView.isHidden = false
        
        let animated = self.overlayAnimationType != .none
        if animated {
            let animation = self.overlayAnimations(opening: true, type: overlayAnimationType)
            animation.preparation?()
            UIView.animate(withDuration: animationDuration, delay: 0.0, options: .curveEaseInOut, animations: {
                animation.animation?()
            }, completion: { (finished: Bool) in
                animation.completion?()
                if self.itemsAnimationType == .none {
                    self.openAnimationDidStop()
                }
            })
        } else {
            backgroundView.frame = CGRect(origin: .zero, size: self.frame.size)
            backgroundView.alpha = 1.0
        }
    }
    
    fileprivate func expandItems() {
        let lastAnimatedItemIndex: Int = itemsAnimationOrder == .progressiveInverse ? 0 : self.items.count - 1
        
        for (index, item) in self.items.enumerated() {
            
            let center = self.center(forItem: item, index: index, itemsPosition: itemsPosition, opening: true)
            var duration = self.animationDuration
            var delay = 0.0
            
            switch itemsAnimationOrder {
            case .linear:
                break
            case .progressive:
                delay = Double(index) * 0.02
            case .progressiveInverse:
                delay = Double(items.count - (index+1)) * 0.02
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: {
                let animated = self.itemsAnimationType != .none
                
                item.expand(animated: animated, duration: duration)
                
                if animated {
                    var damping: CGFloat = 1.0
                    if self.itemsAnimationType == .bounce {
                        damping = 0.7
                        var durationOffset: TimeInterval = 0
                        if self.itemsAnimationOrder == .progressive {
                            durationOffset = Double(index) * duration / Double(self.items.count)
                        } else if self.itemsAnimationOrder == .progressiveInverse {
                            durationOffset = Double(self.items.count - index) * duration / Double(self.items.count)
                        }
                        duration += durationOffset
                    }
                    
                    let animation = self.openAnimations(forItem: item, to: center, type: self.itemsAnimationType)
                    animation.preparation?()
                    UIView.animate(withDuration: duration, delay: delay, usingSpringWithDamping: damping, initialSpringVelocity: 0.0, options: .curveEaseInOut, animations: {
                        animation.animation?()
                    }) { (finished: Bool) in
                        animation.completion?()
                        if index == lastAnimatedItemIndex {
                            self.openAnimationDidStop()
                        }
                    }
                } else {
                    item.center = center
                    item.alpha = 1.0
                    if self.overlayAnimationType == .none && index == lastAnimatedItemIndex {
                        self.openAnimationDidStop()
                    }
                }
            })
        }
    }
    
    
    fileprivate func reduceContainers() {
        let superview = self.superview ?? self
        let baseOrigin = containerView.convert(button.frame.origin, to: superview)
        let baseSize = button.frame.size
        let frame = CGRect(origin: baseOrigin, size: baseSize)
        let innerFrame = CGRect(origin: CGPoint(x: 0, y: 0), size: baseSize)
        
        self.frame = frame
        containerView.frame = innerFrame
        button.frame = innerFrame
        
        items.forEach({ $0.center = button.center })
    }
    
    fileprivate func reduceOverlay() {
        let animated = self.overlayAnimationType != .none
        if animated {
            let animation = self.overlayAnimations(opening: false, type: overlayAnimationType)
            animation.preparation?()
            UIView.animate(withDuration: animationDuration, delay: 0.0, options: .curveEaseInOut, animations: {
                animation.animation?()
            }, completion: { (finished: Bool) in
                animation.completion?()
                if self.itemsAnimationType == .none {
                    self.closeAnimationDidStop()
                }
            })
        } else {
            self.backgroundView.frame = CGRect(origin: .zero, size: self.frame.size)
            self.backgroundView.alpha = 0.0
            self.backgroundView.isHidden = true
        }
    }
    
    fileprivate func reduceItems() {
        let lastAnimatedItemIndex: Int = itemsAnimationOrder == .progressiveInverse ? 0 : self.items.count - 1
        
        for (index, item) in self.items.enumerated() {
            
            let center = self.center(forItem: item, index: index, itemsPosition: itemsPosition, opening: false)
            var duration = self.animationDuration
            var delay = 0.0
            
            switch itemsAnimationOrder {
            case .linear:
                break
            case .progressive:
                    delay = Double(index) * 0.02
            case .progressiveInverse:
                    delay = Double(items.count - (index+1)) * 0.02
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: {
                let animated = self.itemsAnimationType != .none
                
                item.reduce(animated: animated, duration: duration)
                
                if animated {
                    var damping: CGFloat = 1.0
                    var velocity: CGFloat = 0.0
                    if self.itemsAnimationType == .bounce {
                        damping = 1.0
                        velocity = -5
                        
                        var durationOffset: TimeInterval = 0
                        if self.itemsAnimationOrder == .progressive {
                            durationOffset = Double(index) * duration / Double(self.items.count)
                        } else if self.itemsAnimationOrder == .progressiveInverse {
                            durationOffset = Double(self.items.count - (index + 1)) * duration / Double(self.items.count)
                        }
                        duration += durationOffset
                        duration *= 2
                    }
                    
                    let animation = self.closeAnimations(forItem: item, to: center, type: self.itemsAnimationType)
                    animation.preparation?()
                    UIView.animate(withDuration: duration, delay: delay, usingSpringWithDamping: damping, initialSpringVelocity: velocity, options: .curveEaseInOut, animations: {
                        animation.animation?()
                    }) { (finished: Bool) in
                        animation.completion?()
                        if index == lastAnimatedItemIndex {
                            self.closeAnimationDidStop()
                        }
                    }
                } else {
                    item.center = center
                    item.alpha = 0.0
                    if self.overlayAnimationType == .none && index == lastAnimatedItemIndex {
                        self.closeAnimationDidStop()
                    }
                }
            })
        }
    }
    
    
    fileprivate func openAnimationDidStop() {
        guard !isOpen else { return }
        
        isOpen = true
        delegate?.actionButtonDidOpen?(self)
        
        isAnimatingOpenClose = false
    }
    
    fileprivate func closeAnimationDidStop() {
        guard isOpen else { return }
        
        isOpen = false
        reduceContainers()
        delegate?.actionButtonDidClose?(self)
        
        isAnimatingOpenClose = false
    }
    
    
    /* Geometry Computations */
    
    fileprivate func computeOpenSize() {
        let center = button.center
        
        var topLeftCorner = button.frame.origin
        var bottomRightCorner = CGPoint(x: button.frame.origin.x + button.frame.size.width, y: button.frame.origin.y + button.frame.size.height)
        for (index, item) in self.items.enumerated() {
            
            let itemLeftOffset = item.center.x - item.frame.origin.x
            let itemRightOffset = item.frame.origin.x + item.frame.size.width - item.center.x
            let itemTopOffset = item.center.y - item.frame.origin.y
            let itemBottomOffset = item.frame.origin.y + item.frame.size.height - item.center.y
            
            let itemCenter = self.center(forItem: item, index: index, itemsPosition: self.itemsPosition, opening: true)
            topLeftCorner = CGPoint(x: min(topLeftCorner.x, itemCenter.x - itemLeftOffset), y: min(topLeftCorner.y, itemCenter.y - itemTopOffset))
            bottomRightCorner = CGPoint(x: max(bottomRightCorner.x, itemCenter.x + itemRightOffset), y: max(bottomRightCorner.y, itemCenter.y + itemBottomOffset))
        }
        
        containerOpenSize = CGSize(width: bottomRightCorner.x - topLeftCorner.x, height: bottomRightCorner.y - topLeftCorner.y)
        buttonOpenCenter = CGPoint(x: abs(center.x - topLeftCorner.x), y: abs(center.y - topLeftCorner.y))
    }
   
    fileprivate func center(forItem item: UPActionButtonItem, index: Int, itemsPosition position: UPActionButtonItemsPosition, opening: Bool) -> CGPoint {
        var center = button.center
        
        if (opening) {
            let buttonFrame = button.frame
            let itemSize = item.frame.size
            let itemOffset = (itemSize.height + self.itemsInterSpacing) * CGFloat(index + 1)
            
            switch position {
            case .up:
                center.y = buttonFrame.origin.y - itemOffset + itemSize.height / 2
            case .down:
                center.y = buttonFrame.origin.y + buttonFrame.size.height + itemOffset - itemSize.height / 2
            case .round,
                 .roundHalfUp, .roundHalfRight, .roundHalfDown, .roundHalfLeft,
                 .roundQuarterUp, .roundQuarterUpRight, .roundQuarterRight, .roundQuarterDownRight,
                 .roundQuarterDown, .roundQuarterDownLeft, .roundQuarterLeft, .roundQuarterUpLeft:
                let radius = self.itemsInterSpacing + button.frame.size.width / 2 + self.itemSize.width / 2
                let angles = self.angles(forItemsRoundPosition: position)
                var count = CGFloat(self.items.count)
                if position != .round {
                    count -= 1
                }
                let angle = (angles.max / count * CGFloat(index) + angles.start)
                let xOffset = radius * cos(radians(degrees: angle)) * -1
                let yOffset = radius * sin(radians(degrees: angle)) * -1
                center.x += xOffset
                center.y += yOffset
            }
        }
        
        return center
    }
    
    fileprivate func angles(forItemsRoundPosition position: UPActionButtonItemsPosition) -> (max: CGFloat, start: CGFloat) {
        switch position {
        case .round:                    return (max: 360, start: 0)
        case .roundHalfUp:              return (max: 180, start: 0)
        case .roundHalfRight:           return (max: 180, start: 90)
        case .roundHalfDown:            return (max: 180, start: 180)
        case .roundHalfLeft:            return (max: 180, start: 270)
        case .roundQuarterUp:           return (max: 90, start: 45)
        case .roundQuarterUpRight:      return (max: 90, start: 90)
        case .roundQuarterRight:        return (max: 90, start: 135)
        case .roundQuarterDownRight:    return (max: 90, start: 180)
        case .roundQuarterDown:         return (max: 90, start: 225)
        case .roundQuarterDownLeft:     return (max: 90, start: 270)
        case .roundQuarterLeft:         return (max: 90, start: 315)
        case .roundQuarterUpLeft:       return (max: 90, start: 0)
        default:                        return (max: 0, start: 0)
        }
    }
    
    fileprivate func coveringBubbleDiameter(for center: CGPoint) -> CGFloat {
        let maxOffsetX = max(center.x, self.frame.size.width - center.x)
        let maxOffsetY = max(center.y, self.frame.size.height - center.y)
        let radius = sqrt(pow(maxOffsetX, 2) + pow(maxOffsetY, 2))
        return radius * 2
    }

    fileprivate func radians(degrees: CGFloat) -> CGFloat {
        return degrees * .pi / 180
    }
    
    /* Animations */
    
    fileprivate func overlayAnimations(opening: Bool, type: UPActionButtonOverlayAnimationType) -> AnimationSteps {
        return (preparation: {
            switch type {
            case .none: break
            case .fade:
                self.backgroundView.alpha = opening ? 0.0 : 1.0
                self.backgroundView.frame = CGRect(origin: .zero, size: self.frame.size)
            case .bubble:
                let center = self.containerView.convert(self.button.center, to: self)
                self.backgroundView.frame = CGRect(origin: .zero, size: CGSize(width: 1, height: 1))
                self.backgroundView.center = center
                self.backgroundView.layer.cornerRadius = self.backgroundView.frame.size.width / 2.0
                self.backgroundView.alpha = 1.0
                if !opening {
                    let diameter = self.coveringBubbleDiameter(for: self.backgroundView.center)
                    self.backgroundView.transform = CGAffineTransform(scaleX: diameter, y: diameter)
                }
            }
        }, animation: {
            switch type {
            case .none: break
            case .fade:
                self.backgroundView.alpha = opening ? 1.0 : 0.0
            case .bubble:
                if opening {
                    let diameter = self.coveringBubbleDiameter(for: self.backgroundView.center)
                    self.backgroundView.transform = CGAffineTransform(scaleX: diameter, y: diameter)
                } else {
                    self.backgroundView.transform = CGAffineTransform.identity
                }
            }
        }, completion: {
            if opening {
                self.backgroundView.transform = CGAffineTransform.identity
            } else {
                self.backgroundView.isHidden = true
            }
            self.backgroundView.frame = CGRect(origin: .zero, size: self.frame.size)
            self.backgroundView.layer.cornerRadius = 0
        })
    }
    
    
    fileprivate func openAnimations(forItem item: UPActionButtonItem, to: CGPoint, type: UPActionButtonItemsAnimationType) -> AnimationSteps {
        let translationOffset: CGFloat = 20.0
        let scaleOffset: CGFloat = 0.5
        
        return (preparation: {
            var alpha: CGFloat = 0.0
            switch type {
            case .none: break
            case .fade:
                item.center = to
            case .fadeDown:
                item.center = CGPoint(x: to.x, y: to.y - translationOffset)
            case .fadeUp:
                item.center = CGPoint(x: to.x, y: to.y + translationOffset)
            case .fadeLeft:
                item.center = CGPoint(x: to.x + translationOffset, y: to.y)
            case .fadeRight:
                item.center = CGPoint(x: to.x - translationOffset, y: to.y)
            case .scaleDown:
                item.center = to
                item.transform = CGAffineTransform(scaleX: 1 + scaleOffset, y: 1 + scaleOffset)
            case .scaleUp:
                item.center = to
                item.transform = CGAffineTransform(scaleX: 1 - scaleOffset, y: 1 - scaleOffset)
            case .slide: break
            case .bounce:
                alpha = 1.0
            }
            item.alpha = alpha
        }, animation: {
            item.transform = CGAffineTransform.identity
            item.center = to
            item.alpha = 1.0
        }, completion: nil)
    }
    
    fileprivate func closeAnimations(forItem item: UPActionButtonItem, to: CGPoint, type: UPActionButtonItemsAnimationType) -> AnimationSteps {
        let translationOffset: CGFloat = 20.0
        let scaleOffset: CGFloat = 0.5
        
        return (preparation: {
            item.alpha = 1.0
        }, animation: {
            var alpha: CGFloat = 0.0
            let center = item.center
            switch type {
            case .none: break
            case .fade: break
            case .fadeDown:
                item.center = CGPoint(x: center.x, y: center.y - translationOffset)
            case .fadeUp:
                item.center = CGPoint(x: center.x, y: center.y + translationOffset)
            case .fadeLeft:
                item.center = CGPoint(x: center.x + translationOffset, y: center.y)
            case .fadeRight:
                item.center = CGPoint(x: center.x - translationOffset, y: center.y)
            case .scaleDown:
                item.transform = CGAffineTransform(scaleX: 1 + scaleOffset, y: 1 + scaleOffset)
            case .scaleUp:
                item.transform = CGAffineTransform(scaleX: 1 - scaleOffset, y: 1 - scaleOffset)
            case .slide:
                item.center = to
            case .bounce:
                item.center = to
                alpha = 1.0
            }
            item.alpha = alpha
        }, completion: {
            item.transform = CGAffineTransform.identity
            item.center = to
            item.alpha = 0.0
        })
    }
    
}


// MARK: - Private Helpers (Button)
extension UPActionButton {
    
    fileprivate func updateButtonPosition() {
        let superSize: CGSize = superview?.frame.size ?? .zero
        var contentOffset: CGPoint = .zero
        if let scrollView = superview as? UIScrollView, floating {
            contentOffset = scrollView.contentOffset
        }
        if !isOpen {
            var translatedCenter = self.center
            switch position {
            case .free(let center):
                translatedCenter = center
            case .topLeft(let padding):
                translatedCenter.x = padding.x + self.frame.size.width/2
                translatedCenter.y = padding.y + self.frame.size.height/2
            case .topRight(let padding):
                translatedCenter.x = superSize.width - (padding.x + self.frame.size.width/2)
                translatedCenter.y = padding.y + self.frame.size.height/2
            case .bottomLeft(let padding):
                translatedCenter.x = padding.x + self.frame.size.width/2
                translatedCenter.y = superSize.height - (padding.y + self.frame.size.height/2)
            case .bottomRight(let padding):
                translatedCenter.x = superSize.width - (padding.x + self.frame.size.width/2)
                translatedCenter.y = superSize.height - (padding.y + self.frame.size.height/2)
            }
            translatedCenter.x += contentOffset.x
            translatedCenter.y += contentOffset.y
            self.center = translatedCenter
        }
        else {
            var containerCenter = self.containerView.center
            let centerHorizontalDistance = self.button.center.x - self.containerView.frame.size.width/2
            let centerVerticalDistance = self.button.center.y - self.containerView.frame.size.height/2
            let buttonSize = button.frame.size
            switch position {
            case .free(let center):
                containerCenter.x = center.x + centerHorizontalDistance
                containerCenter.y = center.y + centerVerticalDistance
            case .topLeft(let padding):
                containerCenter.x = padding.x - centerHorizontalDistance + buttonSize.width/2
                containerCenter.y = padding.y - centerVerticalDistance + buttonSize.height/2
            case .topRight(let padding):
                containerCenter.x = superSize.width - (padding.x + centerHorizontalDistance + buttonSize.width/2)
                containerCenter.y = padding.y - centerVerticalDistance + buttonSize.height/2
            case .bottomLeft(let padding):
                containerCenter.x = padding.x - centerHorizontalDistance + buttonSize.width/2
                containerCenter.y = superSize.height - (padding.y + centerVerticalDistance + buttonSize.height/2)
            case .bottomRight(let padding):
                containerCenter.x = superSize.width - (padding.x + centerHorizontalDistance + buttonSize.width/2)
                containerCenter.y = superSize.height - (padding.y + centerVerticalDistance + buttonSize.height/2)
            }
            self.containerView.center = containerCenter
        }
    }
    
    fileprivate func handleInteractiveScroll(from scrollView: UIScrollView) {
        let scrollCurrentOffset = scrollView.contentOffset.y
        
        let scrollableSize = scrollView.contentSize.height - scrollView.frame.size.height
        guard scrollCurrentOffset >= 0 && scrollCurrentOffset <= scrollableSize else { return }
        
        let scrolledDistance = scrollLastOffset - scrollCurrentOffset
        let direction: ScrollDirection = scrolledDistance < 0 ? .down : scrolledDistance > 0 ? .up : .none
        if direction != .none {
            if direction != scrollCurrentDirection {
                scrollCurrentDirection = direction
                scrollStartOffset = scrollCurrentOffset
            }
            else {
                if (scrollCurrentDirection == .down && !self.isHidden) || (scrollCurrentDirection == .up && self.isHidden) {
                    let totalScrolledDistance = scrollStartOffset - scrollCurrentOffset
                    if fabsf(Float(totalScrolledDistance)) > Float(interactiveScrollDistance) {
                        switch scrollCurrentDirection {
                        case .down:
                            hide()
                        case .up:
                            show()
                        default: break
                        }
                    }
                        // Show the button right away when scrolling up from the bottom of the scrollview
                    else if scrollCurrentDirection == .up && scrollLastOffset > scrollableSize - 10 {
                        show()
                    }
                }
            }
        }
        
        scrollLastOffset = scrollCurrentOffset
    }
    
    
    /* Animations */
    
    fileprivate func appearAnimations(type: UPActionButtonDisplayAnimationType) -> AnimationSteps {
        let initialContainerFrame = containerView.frame
        
        return (preparation: {
            var containerFrame = self.containerView.frame
            switch type {
            case .none: break
            case .slideDown:
                containerFrame.origin.y -= self.slideAnimationOffset
                self.containerView.frame = containerFrame
            case .slideUp:
                containerFrame.origin.y += self.slideAnimationOffset
                self.containerView.frame = containerFrame
            case .slideLeft:
                containerFrame.origin.x += self.slideAnimationOffset
                self.containerView.frame = containerFrame
            case .slideRight:
                containerFrame.origin.x -= self.slideAnimationOffset
                self.containerView.frame = containerFrame
            case .scaleDown:
                self.containerView.transform = CGAffineTransform(scaleX: 1 + self.scaleAnimationOffset, y: 1 + self.scaleAnimationOffset)
            case .scaleUp:
                self.containerView.transform = CGAffineTransform(scaleX: 1 - self.scaleAnimationOffset, y: 1 - self.scaleAnimationOffset)
            }
            
            self.isHidden = false
            self.containerView.alpha = 0.0
        }, animation: {
            self.containerView.transform = CGAffineTransform.identity
            self.containerView.frame = initialContainerFrame
            self.containerView.alpha = 1.0
        }, completion: nil)
    }
    
    fileprivate func disappearAnimations(type: UPActionButtonDisplayAnimationType) -> AnimationSteps {
        let initialContainerFrame = containerView.frame
        
        return (preparation: {
            self.containerView.alpha = 1.0
        }, animation: {
            var containerFrame = self.containerView.frame
            switch type {
            case .none: break
            case .slideDown:
                containerFrame.origin.y += self.slideAnimationOffset
                self.containerView.frame = containerFrame
            case .slideUp:
                containerFrame.origin.y -= self.slideAnimationOffset
                self.containerView.frame = containerFrame
            case .slideLeft:
                containerFrame.origin.x -= self.slideAnimationOffset
                self.containerView.frame = containerFrame
            case .slideRight:
                containerFrame.origin.x += self.slideAnimationOffset
                self.containerView.frame = containerFrame
            case .scaleDown:
                self.containerView.transform = CGAffineTransform(scaleX: 1 - self.scaleAnimationOffset, y: 1 - self.scaleAnimationOffset)
            case .scaleUp:
                self.containerView.transform = CGAffineTransform(scaleX: 1 + self.scaleAnimationOffset, y: 1 + self.scaleAnimationOffset)
            }
            
            self.containerView.alpha = 0.0
        }, completion: {
            self.isHidden = true
            self.containerView.transform = CGAffineTransform.identity
            self.containerView.frame = initialContainerFrame
        })
    }
    
    fileprivate func transitionButtonTitle() {
        let duration = animationDuration
        let opening = !isOpen
        
        switch buttonTransitionType {
        case .none: break
            
        case .rotate(let degrees):
            guard let titleView = self.visibleOpenTitleView else { return }
            let angle = radians(degrees: degrees)
            UIView.animate(withDuration: duration, delay: 0.0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.0, options: .curveEaseInOut, animations: {
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
    
}
