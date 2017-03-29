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
    // case round, halfRoundUp, halfRoundDown ...
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
    fileprivate var animatedItemTag: Int = 0
    
    fileprivate var isAnimatingShowHide = false
    
    fileprivate let superviewBoundsKeyPath = "layer.bounds"
    fileprivate var observesSuperviewBounds = false
    fileprivate var observesSuperviewContentOffset = false
    fileprivate var observesInteractiveScrollView = false
    
    fileprivate var scrollCurrentDirection: ScrollDirection = .none
    fileprivate var scrollStartOffset: CGFloat = 0
    fileprivate var scrollLastOffset: CGFloat = 0
    fileprivate let interactiveScrollDistance: CGFloat = 64.0
    
    fileprivate(set) var items = [UPActionButtonItem]()
    
    public var delegate: UPActionButtonDelegate?
    
    public var interactiveScrollView: UIScrollView? {
        didSet {
            if let scrollView = oldValue, observesInteractiveScrollView {
                scrollView.removeObserver(self, forKeyPath: "contentOffset")
                observesInteractiveScrollView = false
            }
            if let scrollView = interactiveScrollView {
                scrollView.addObserver(self, forKeyPath: "contentOffset", options: .new, context: nil)
                observesInteractiveScrollView = true
            }
        }
    }
    
    public var isOpen = false
    
    /* Customization */
    public var floating: Bool = false {
        didSet {
            if !floating && observesSuperviewContentOffset {
                self.superview?.removeObserver(self, forKeyPath: "contentOffset")
                observesSuperviewContentOffset = false
            }
            if let superview = self.superview as? UIScrollView, floating {
                superview.addObserver(self, forKeyPath: "contentOffset", options: .new, context: nil)
                observesSuperviewContentOffset = true
            }
        }
    }
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
    public var itemsInterSpacing: CGFloat = 10.0 {
        didSet {
            computeOpenSize()
        }
    }
    public var itemsAnimationType: UPActionButtonItemsAnimationType = .none
    public var itemsAnimationOrder: UPActionButtonItemsAnimationOrder = .linear
    public var animationDuration: TimeInterval = 1.0
    public var showAnimationType: UPActionButtonDisplayAnimationType = .none
    public var hideAnimationType: UPActionButtonDisplayAnimationType = .none
    public var buttonTransitionType: UPActionButtonTransitionType = .none
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
    public var titleFont: UIFont {
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
    
    
    // MARK: - Initialization
    public init(frame: CGRect, image: UIImage?, title: String?) {
        super.init(frame: frame)
        
        let innerFrame = CGRect(origin: .zero, size: frame.size)
        
        backgroundView = UIVisualEffectView(frame: innerFrame)
        backgroundView.isHidden = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggle))
        backgroundView.addGestureRecognizer(tapGesture)
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
        
        self.setTitleInset(dx: 10, dy: 10)
        
        if let image = image {
            self.image = image
            openTitleImageView.alpha = 1.0
        } else if let title = title {
            self.title = title
            openTitleLabel.alpha = 1.0
        }
    }
    
    override open func willMove(toSuperview newSuperview: UIView?) {
        if let superview = self.superview {
            if observesSuperviewBounds {
                superview.removeObserver(self, forKeyPath: superviewBoundsKeyPath)
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
            superview.addObserver(self, forKeyPath: superviewBoundsKeyPath, options: .new, context: nil)
            observesSuperviewBounds = true
            if (floating && superview is UIScrollView) {
                superview.addObserver(self, forKeyPath: "contentOffset", options: .new, context: nil)
                observesSuperviewContentOffset = true
            }
        }
        
        super.didMoveToSuperview()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        if let superview = self.superview {
            if observesSuperviewBounds {
                superview.removeObserver(self, forKeyPath: superviewBoundsKeyPath)
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
        animatedItemTag = 0
        
        expandContainers()
        expandOverlay()
        expandItems()
        transitionButtonTitle()
    }
    
    open func close() {
        guard isOpen && !isAnimatingOpenClose else { return }
        
        delegate?.actionButtonWillClose?(self)
        
        isAnimatingOpenClose = true
        animatedItemTag = 0
        
        reduceOverlay()
        reduceItems()
        transitionButtonTitle()
    }
    
    
    /* Observers */
    
    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if (object as? UIView) == superview && keyPath == superviewBoundsKeyPath {
            guard let superview = self.superview, isOpen else { return }
            
            let superFrame = CGRect(origin: .zero, size: superview.frame.size)
            self.frame = superFrame
            backgroundView.frame = superFrame
        }
        
        if (object as? UIView) == superview && keyPath == "contentOffset" && floating {
            guard let scrollView = self.superview as? UIScrollView else { return }
            
            let margin: CGFloat = isOpen ? 0 : 20
            var frame = self.frame
            frame.origin.y = scrollView.frame.size.height - frame.size.height - margin + scrollView.contentOffset.y
            self.frame = frame
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
        if itemsPosition == .up {
            let yOffset: CGFloat = buttonOpenCenter.y - button.frame.size.height / 2.0
            containerFrame.origin.y -= yOffset
        }
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
                //                duration = Double(index+1) * animationDuration / Double(items.count)
                delay = Double(index) * 0.2
            case .progressiveInverse:
                //                duration = Double(items.count - index) * animationDuration / Double(items.count)
                delay = Double(items.count - (index+1)) * 0.2
            }
            
            // TODO: adjust for bounce effect
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: {
                
                let animated = self.itemsAnimationType != .none
                if animated {
                    var damping: CGFloat = 1.0
                    if self.itemsAnimationType == .bounce {
                        damping = 0.7
                        duration = Double(index) * self.animationDuration / Double(self.items.count) + self.animationDuration
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
                
                item.expand(animated: animated, duration: duration)
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
            let duration = self.animationDuration
            var delay = 0.0
            
            switch itemsAnimationOrder {
            case .linear:
                break
            case .progressive:
                //                duration = Double(index+1) * animationDuration / Double(items.count)
                delay = Double(index) * 0.2
            case .progressiveInverse:
                //                duration = Double(items.count - index) * animationDuration / Double(items.count)
                delay = Double(items.count - (index+1)) * 0.2
            }
            
            // TODO: adjust for bounce effect
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: {
                
                let animated = self.itemsAnimationType != .none
                if animated {
                    var damping: CGFloat = 1.0
                    var velocity: CGFloat = 0.0
                    if self.itemsAnimationType == .bounce {
                        damping = 0.7
                        velocity = -5.0
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
                
                item.reduce(animated: animated, duration: duration)
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
        let center = CGPoint(x: button.frame.size.width / 2.0, y: button.frame.size.height / 2.0)
        var height: CGFloat = button.frame.size.height
        var leftOffset: CGFloat = 0
        var rightOffset: CGFloat = 0
        
        items.forEach { (item: UPActionButtonItem) in
            height += item.frame.size.height + self.itemsInterSpacing
            
            switch item.titlePosition {
            case .left:
                let itemLeftOffset = item.center.x - item.frame.origin.x - center.x
                leftOffset = max(leftOffset, itemLeftOffset)
            case .right:
                let itemRightOffset = item.frame.size.width - item.center.x - center.x
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
            }
        }
        
        return center
    }
    
    fileprivate func coveringBubbleDiameter(for center: CGPoint) -> CGFloat {
        let maxOffsetX = max(center.x, self.frame.size.width - center.x)
        let maxOffsetY = max(center.y, self.frame.size.width - center.y)
        let radius = sqrt(pow(maxOffsetX, 2) + pow(maxOffsetY, 2))
        return radius * 2
    }

    
//    fileprivate func move(item: UPActionButtonItem, to center: CGPoint, duration: TimeInterval, opening: Bool, bouncing: Bool) {
//        let animation = CAKeyframeAnimation(keyPath: "position")
//        
//        let path = CGMutablePath()
//        path.move(to: item.center)
//        if bouncing {
//            var bouncingOffset: CGFloat = itemsInterSpacing
//            if itemsPosition == .up {
//                bouncingOffset *= -1
//            }
//            if opening {
//                path.addLine(to: CGPoint(x: center.x, y: center.y + bouncingOffset))
//                path.addLine(to: CGPoint(x: center.x, y: center.y - (bouncingOffset / 2.0)))
//            } else {
//                path.addLine(to: CGPoint(x: item.center.x, y: item.center.y + bouncingOffset))
//            }
//        }
//        path.addLine(to: center)
//        animation.path = path
//        
//        animation.duration = duration
//        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
//        animation.delegate = self
//        item.layer.add(animation, forKey: "positionAnimation")
//        
//        item.center = center
//    }
    
//    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
//        itemAnimationDidStop()
//    }
    
//    fileprivate func itemAnimationDidStop() {
//        animatedItemTag += 1
//        guard animatedItemTag >= items.count else { return }
//        
//        isOpen = !isOpen
//        if isOpen {
//            delegate?.actionButtonDidOpen?(self)
//        }
//        else {
//            reduceContainers()
//            delegate?.actionButtonDidClose?(self)
//        }
//        
//        isAnimatingOpenClose = false
//    }
    
    /* Animations */
    
    fileprivate func overlayAnimations(opening: Bool, type: UPActionButtonOverlayAnimationType) -> AnimationSteps {
        return (preparation: {
            switch type {
            case .none: break
            case .fade:
                self.backgroundView.alpha = 0.0
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
                self.backgroundView.alpha = 1.0
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
    
    fileprivate func disappearAnimations(type: UPActionButtonDisplayAnimationType) -> AnimationSteps {
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
    
    fileprivate func transitionButtonTitle() {
        let duration = animationDuration
        let opening = !isOpen
        
        switch buttonTransitionType {
        case .none: break
            
        case .rotate(let degrees):
            guard let titleView = self.visibleOpenTitleView else { return }
            let radians = degrees * .pi / 180
            UIView.animate(withDuration: duration, delay: 0.0, usingSpringWithDamping: 0.7, initialSpringVelocity: 5.0, options: .curveEaseInOut, animations: {
                titleView.transform = opening ? CGAffineTransform(rotationAngle: radians) : CGAffineTransform.identity
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
