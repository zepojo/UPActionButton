//
//  ViewController.swift
//  UPActionButtonDemo
//
//  Created by Paul Ulric on 28/02/2017.
//  Copyright © 2017 Paul Ulric. All rights reserved.
//

import UIKit

class ViewController: UITableViewController {
    
    var rowCount = 30
    var actionButton: UPActionButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Action Button"
        
        actionButton = createActionButton()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        var buttonFrame = actionButton.frame
        buttonFrame.origin.x = self.view.frame.size.width - buttonFrame.size.width - 20
        buttonFrame.origin.y = self.view.frame.size.height - buttonFrame.size.height - 20
        actionButton.frame = buttonFrame
        tableView.addSubview(actionButton)
    }
    
    fileprivate func createActionButton() -> UPActionButton {
        let button = UPActionButton(frame: CGRect(x: 200, y: 200, width: 60, height: 60), image: nil, title: "+")
        button.transitionType = .rotate(2.35)
        button.titleColor = UIColor.white
        button.font = UIFont.systemFont(ofSize: 40)
        button.color = UIColor.blue
        button.cornerRadius = 30.0
        button.setShadow(color: .black, opacity: 0.5, radius: 3.0, offset: CGSize(width: 0, height: 2))
        button.showAnimationType = .scaleUp
        button.overlayColor = UIColor(white: 0.0, alpha: 0.3)
        button.itemSize = CGSize(width: 40, height: 40)
        button.floating = true
        button.observedScrollView = self.tableView
        
        var items = [UPActionButtonItem]()
        
        let firstItem = UPActionButtonItem(title: "Add 1 row", buttonImage: nil, buttonText: "1") {
            self.addRows(1)
        }
        items.append(firstItem)
        
        let secondItem = UPActionButtonItem(title: "Add 5 rows", buttonImage: nil, buttonText: "5") {
            self.addRows(5)
        }
        items.append(secondItem)
        
        let thirdItem = UPActionButtonItem(title: "Add 10 rows", buttonImage: nil, buttonText: "10") {
            self.addRows(10)
        }
        items.append(thirdItem)
        
        items.forEach { (item: UPActionButtonItem) in
            item.cornerRadius = 20.0
            item.color = UIColor.blue
            item.titleColor = UIColor.black
        }
        
        button.add(items: items)
        
        return button
    }
    
    fileprivate func addRows(_ rows: Int) {
        rowCount += rows
        self.tableView.reloadData()
    }

}


// MARK: - UITableView Delegate / DataSource
extension ViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rowCount
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UPActionButtonDemoCell", for: indexPath)
        cell.textLabel?.text = "Cell \(indexPath.row)"
        return cell
    }
    
}

