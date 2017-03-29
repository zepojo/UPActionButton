//
//  DemoTableViewCell.swift
//  UPActionButtonDemo
//
//  Created by Paul Ulric on 29/03/2017.
//  Copyright © 2017 Paul Ulric. All rights reserved.
//

import UIKit

class DemoTableViewCell: UITableViewCell {
    
    @IBOutlet weak var firstLineView: UIView!
    @IBOutlet weak var secondLineWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var thirdLineWidthConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let maxWidth: CGFloat = firstLineView.frame.size.width
        let minWidth: CGFloat = 40
        let range = maxWidth - minWidth
        [secondLineWidthConstraint, thirdLineWidthConstraint].forEach { (constraint: NSLayoutConstraint) in
            constraint.constant = CGFloat(arc4random_uniform(UInt32(range))) + minWidth
        }
    }
    
}
