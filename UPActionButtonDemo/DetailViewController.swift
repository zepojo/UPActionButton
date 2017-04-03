//
//  DetailViewController.swift
//  UPActionButtonDemo
//
//  Created by Paul Ulric on 30/03/2017.
//  Copyright © 2017 Paul Ulric. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController, UPActionButtonDelegate {

    @IBOutlet weak var shareButton: UPActionButton!
    @IBOutlet weak var scrollView: UIScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        createItems()
        customizeButton()
    }

    func createItems() {
        var items = [UPActionButtonItem]()
        
        let facebookItem = UPActionButtonItem(title: nil, buttonImage: #imageLiteral(resourceName: "facebook"), buttonText: nil) {
            print("Share on Facebook")
        }
        items.append(facebookItem)
        
        let twitterItem = UPActionButtonItem(title: nil, buttonImage: #imageLiteral(resourceName: "twitter"), buttonText: nil) {
            print("Share on Twitter")
        }
        items.append(twitterItem)
        
        let emailItem = UPActionButtonItem(title: nil, buttonImage: #imageLiteral(resourceName: "mail"), buttonText: nil) {
            print("Share via email")
        }
        items.append(emailItem)
        
        items.forEach { (item: UPActionButtonItem) in
            item.cornerRadius = min(shareButton.itemSize.width, shareButton.itemSize.height) / 2
            item.color = .black
        }
        
        shareButton.add(items: items)
    }
    
    func customizeButton() {
        shareButton.buttonTransitionType = .crossDissolveImage(#imageLiteral(resourceName: "close"))
        shareButton.overlayAnimationType = .bubble
        shareButton.itemsPosition = .roundQuarterUp
        shareButton.itemsInterSpacing = 30
        shareButton.setShadow(color: .clear, opacity: 0, radius: 0, offset: .zero)
    }

}
