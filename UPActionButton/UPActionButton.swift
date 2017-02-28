//
//  UPActionButton.swift
//  UPActionButtonDemo
//
//  Created by Paul Ulric on 28/02/2017.
//  Copyright © 2017 Paul Ulric. All rights reserved.
//

import UIKit


@objc protocol UPActionButtonDelegate {
    @objc optional func actionButtonWillOpen(_: UPActionButton)
    @objc optional func actionButtonDidOpen(_: UPActionButton)
    @objc optional func actionButtonWillClose(_: UPActionButton)
    @objc optional func actionButtonDidClose(_: UPActionButton)
}

class UPActionButton: UIView {

    // MARK: - Properties
    fileprivate var backgroundView: UIView!
    fileprivate var containerView: UIView!
    fileprivate var containerOpenSize: CGSize = .zero
    fileprivate var baseButtonOpenCenter: CGPoint = .zero
    fileprivate var isOpen = false
    fileprivate var isAnimating = false
    fileprivate var animatedItemTag: Int = 0
    
    fileprivate let superviewBoundsKeyPath = "layer.bounds"
    fileprivate var observesSuperviewBounds = false
    
    fileprivate(set) var items = [UPActionButtonItem]()
    
    var button: UIButton!
    var itemSize: CGSize = CGSize(width: 30, height: 30)
    var itemsInterSpacing: CGFloat = 10.0
    var animationDuration: TimeInterval = 0.6
    
    weak var delegate: UPActionButtonDelegate?
    
    
    // MARK: - Initialization
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        let innerFrame = CGRect(origin: .zero, size: frame.size)
        let cornerRadius = max(innerFrame.size.width, innerFrame.size.height) / 2.0
        
        backgroundView = UIView(frame: innerFrame)
        backgroundView.backgroundColor = UIColor(white: 1.0, alpha: 0.4)
        backgroundView.isHidden = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggle))
        backgroundView.addGestureRecognizer(tapGesture)
        self.addSubview(backgroundView)
        
        containerView = UIView(frame: innerFrame)
        containerView.clipsToBounds = true
        containerView.backgroundColor = UIColor.gray
        self.addSubview(containerView)
        
        button = UIButton(type: .custom)
        button.frame = innerFrame
        button.backgroundColor = UIColor.blue
        button.layer.cornerRadius = cornerRadius
        button.setTitle("B", for: .normal)
        button.setTitleColor(UIColor.white, for: .normal)
        button.setTitleColor(UIColor.lightGray, for: .highlighted)
        button.addTarget(self, action: #selector(toggle), for: .touchUpInside)
        containerView.addSubview(button)
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        if let superview = newSuperview {
            superview.addObserver(self, forKeyPath: superviewBoundsKeyPath, options: .new, context: nil)
            observesSuperviewBounds = true
        } else if let superview = self.superview, observesSuperviewBounds {
            superview.removeObserver(self, forKeyPath: superviewBoundsKeyPath)
            observesSuperviewBounds = false
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        if let superview = self.superview, observesSuperviewBounds {
            superview.removeObserver(self, forKeyPath: superviewBoundsKeyPath)
            observesSuperviewBounds = false
        }
    }
    
}


// MARK: - Public API
extension UPActionButton {
    
    /* Items management */
    
    func add(item: UPActionButtonItem) {
        add(item: item, computeSize: true)
    }
    
    func add(items: [UPActionButtonItem]) {
        items.forEach({ self.add(item: $0, computeSize: false) })
        computeOpenSize()
    }
    
    func remove(item: UPActionButtonItem) {
        remove(item: item, computeSize: true)
    }
    
    func remove(itemAt index: Int) {
        guard index >= 0 && index < items.count else { return }
        
        remove(item: items[index], computeSize: true)
    }
    
    func removeAllItems() {
        items.forEach({ self.remove(item: $0, computeSize: false) })
        computeOpenSize()
    }
    
    
    /* Interactions */
    
    func toggle() {
        if isOpen {
            close()
        } else {
            open()
        }
    }
    
    func open() {
        guard let superFrame = self.superview?.frame else { return }
        guard !isOpen && !isAnimating else { return }
        
        delegate?.actionButtonWillOpen?(self)
        
        isAnimating = true
        isOpen = true
        animatedItemTag = 0
        
        expandContainers(to: superFrame)
        expandItems()
    }
    
    func close() {
        guard isOpen && !isAnimating else { return }
        
        delegate?.actionButtonWillClose?(self)
        
        isAnimating = true
        isOpen = false
        animatedItemTag = 0
        
        reduceItems()
    }
    
    
    /* Observers */
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == superviewBoundsKeyPath {
            guard let superview = self.superview, isOpen else { return }
            
            let superFrame = CGRect(origin: .zero, size: superview.frame.size)
            self.frame = superFrame
            backgroundView.frame = superFrame
        }
    }
}


// MARK: - UPActionButtonItem Delegate Methods
extension UPActionButton: UPActionButtonItemDelegate {
    
    func didTouch(item: UPActionButtonItem) {
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
        
        items.forEach { (item: UPActionButtonItem) in
            height += item.frame.size.height + self.itemsInterSpacing
            let itemLeftOffset = CGFloat(fabs(center.x - item.itemCenter.x))
            leftOffset = max(leftOffset, itemLeftOffset)
        }
        
        if items.count > 0 {
            height += itemsInterSpacing
        }
        let width: CGFloat = leftOffset + button.frame.size.width
        
        containerOpenSize = CGSize(width: width, height: height)
        let baseButtonCenterY: CGFloat = height - button.frame.size.height / 2.0
        baseButtonOpenCenter = CGPoint(x: leftOffset + button.frame.size.width / 2.0, y: baseButtonCenterY)
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
        containerFrame.origin.x -= baseButtonOpenCenter.x - button.frame.size.width / 2.0
        let yOffset: CGFloat = baseButtonOpenCenter.y - button.frame.size.height / 2.0
        containerFrame.origin.y -= yOffset
        containerView.frame = containerFrame
        
        button.center = baseButtonOpenCenter
        
        items.forEach({ $0.itemCenter = button.center })
    }
    
    fileprivate func expandItems() {
        UIView.animate(withDuration: animationDuration) {
            self.backgroundView.alpha = 1.0
        }
        
        var y = button.frame.origin.y - itemsInterSpacing
        for (index, item) in self.items.enumerated() {
            //            let duration = Double(index+1) * animationDuration / Double(items.count)
            let duration = Double(items.count - index) * animationDuration / Double(items.count)
            
            let center = CGPoint(x: button.center.x, y: y + (item.frame.size.height / 2.0 * -1))
            let normalizedCenter = item.centerForItemCenter(center)
            
            // TODO: delay
            move(item: item, to: normalizedCenter, duration: duration, opening: true, bouncing: true)
            item.expand(animated: true, duration: duration)
            
            y += (item.frame.size.height + itemsInterSpacing) * -1
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
            let bouncingOffset: CGFloat = itemsInterSpacing * -1
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
 
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        animatedItemTag += 1
        guard animatedItemTag >= items.count else { return }
        
        if isOpen {
            delegate?.actionButtonDidOpen?(self)
        }
        else {
            reduceContainers()
            delegate?.actionButtonDidClose?(self)
        }
        
        isAnimating = false
    }
}
