//
//  ItemCollectionViewCell.swift
//  RobotRaider
//
//  Created by Nathanael Bills on 8/31/18.
//  Copyright © 2018 invasivemachines. All rights reserved.
//

import Foundation
import UIKit

class ItemCollectionViewCell: UICollectionViewCell {
    
    var itemTypeImage: UIImageView = UIImageView()
    var itemSpecificImage: UIImageView = UIImageView()
    var itemLabel: UILabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        itemLabel.font = UIFont.systemFont(ofSize: 14.0)
        itemLabel.textColor = UIColor.black         // this is the default but we stil explicitly set it here to be sure.
        
        itemTypeImage.frame = CGRect(x: 0.0, y: 0.0, width: 0.15 * frame.size.width, height: frame.size.height)
        itemSpecificImage.frame = CGRect(x: 0.15 * frame.size.width, y: 0.0, width: 0.15 * frame.size.width, height: frame.size.height)
        itemLabel.frame = CGRect(x: 0.35 * frame.size.width, y: 0.0, width: 0.60 * frame.size.width, height: frame.size.height)
        // Set number of lines = 1 to make it single line.  Later we will set it to 0 to make an entry multi-line for ammo.
        itemLabel.numberOfLines = 1

        contentView.addSubview(itemTypeImage)
        contentView.addSubview(itemSpecificImage)
        contentView.addSubview(itemLabel)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
