//
//  ViewController.swift
//  UPActionButtonDemo
//
//  Created by Paul Ulric on 28/02/2017.
//  Copyright © 2017 Paul Ulric. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.white
        createActionButton()
    }
    
    fileprivate func createActionButton() {
        let ab = UPActionButton(frame: CGRect(x: 200, y: 200, width: 50, height: 50), image: nil, title: "+")
        ab.transitionType = .rotate(2.35)
        ab.titleColor = UIColor.white
        ab.font = UIFont.systemFont(ofSize: 32)
        ab.color = UIColor.blue
        ab.cornerRadius = 25.0
        ab.setShadow(color: .black, opacity: 0.5, radius: 3.0, offset: CGSize(width: 0, height: 2))
        ab.showAnimationType = .scaleUp
        
        let item = UPActionButtonItem(title: "Item", buttonImage: nil, buttonText: "👼") {
            print("Item tapped")
        }
        let item2 = UPActionButtonItem(title: "Item 2 next one", buttonImage: nil, buttonText: "😉") {
            print("Item 2 tapped")
        }
        item2.titlePosition = .right
        let item3 = UPActionButtonItem(title: "Item 3 the", buttonImage: nil, buttonText: "🐦") {
            print("Item 3 tapped")
        }
        [item, item2, item3].forEach { (item: UPActionButtonItem) in
            item.cornerRadius = 15.0
            item.color = UIColor.blue
            item.titleColor = UIColor.black
        }
        ab.add(item: item)
        ab.add(item: item2)
        ab.add(item: item3)
        
        ab.hide(animated: false)
        view.addSubview(ab)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            ab.show()
        }
    }

}

