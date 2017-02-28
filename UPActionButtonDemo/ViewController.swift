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
        
        self.view.backgroundColor = UIColor.black
        createActionButton()
    }
    
    fileprivate func createActionButton() {
        let ab = UPActionButton(frame: CGRect(x: 200, y: 200, width: 50, height: 50))
        let item = UPActionButtonItem(title: "Item", iconImage: nil, iconText: "👼") {
            print("Item tapped")
        }
        let item2 = UPActionButtonItem(title: "Item 2 next one", iconImage: nil, iconText: "😉") {
            print("Item 2 tapped")
        }
        let item3 = UPActionButtonItem(title: "Item 3 the", iconImage: nil, iconText: "🐦") {
            print("Item 3 tapped")
        }
        ab.add(item: item)
        ab.add(item: item2)
        ab.add(item: item3)
        
        view.addSubview(ab)
    }

}

