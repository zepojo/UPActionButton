//
//  ListViewController.swift
//  UPActionButtonDemo
//
//  Created by Paul Ulric on 28/02/2017.
//  Copyright © 2017 Paul Ulric. All rights reserved.
//

import UIKit

class ListViewController: UITableViewController, UPActionButtonDelegate {
    
    var rowCount = 1
    var actionButton: UPActionButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Action Button"
        
        self.tableView.register(UINib(nibName: "DemoTableViewCell", bundle: nil), forCellReuseIdentifier: "DemoTableViewCell")
        
        actionButton = createActionButton()
        
        var buttonFrame = actionButton.frame
        buttonFrame.origin.x = self.view.frame.size.width - buttonFrame.size.width - 20
        buttonFrame.origin.y = self.view.frame.size.height - buttonFrame.size.height - 20
        actionButton.frame = buttonFrame
        self.navigationController?.view.addSubview(actionButton)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        actionButton.show()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        actionButton.hide()
    }
    
    fileprivate func createActionButton() -> UPActionButton {
        let color = UIColor(red: 112/255, green: 47/255, blue: 168/255, alpha: 1)
        
        let button = UPActionButton(frame: CGRect(x: 200, y: 200, width: 60, height: 60), image: nil, title: "+")
        button.titleFont = UIFont.systemFont(ofSize: 40)
        button.buttonTransitionType = .rotate(degrees: 135)
        button.setTitleTextOffset(CGPoint(x: 0, y: 3))
        button.color = color
        button.itemSize = CGSize(width: 40, height: 40)
        button.floating = true
        button.interactiveScrollView = self.tableView
        button.delegate = self
        
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
            item.color = UIColor(red: 112/255, green: 47/255, blue: 168/255, alpha: 1)
            item.titleInsets = UIEdgeInsets(top: 4.0, left: 10.0, bottom: 4.0, right: 10.0)
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
extension ListViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rowCount
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DemoTableViewCell", for: indexPath) as! DemoTableViewCell
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 95
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        self.performSegue(withIdentifier: "DetailSegue", sender: nil)
    }
    
}

