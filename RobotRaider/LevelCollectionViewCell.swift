//
//  LevelCollectionViewCell.swift
//  RobotRaider
//
//  Created by Nathanael Bills on 4/5/18.
//  Copyright © 2018 invasivemachines. All rights reserved.
//

import UIKit

class LevelCollectionViewCell: UICollectionViewCell {

    var levelNumLabel: UILabel = UILabel()
    var robotTallyLabel: UILabel = UILabel()
    var partTallyLabel: UILabel = UILabel()

    var genericRobotImageView: UIImageView = UIImageView()
    var robotImageView: UIImageView = UIImageView()
    var partImageView: UIImageView = UIImageView()
    var star1ImageView: UIImageView = UIImageView()
    var star2ImageView: UIImageView = UIImageView()
    var star3ImageView: UIImageView = UIImageView()
    
    var starImageViewSize: CGSize!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        starImageViewSize = CGSize(width: 0.25 * frame.size.width, height: 0.25 * frame.size.height)
        
        levelNumLabel.frame = CGRect(x: 0.25 * frame.size.width, y: 0.0, width: 0.50 * frame.size.width, height: 0.25 * frame.size.height)
        levelNumLabel.font = UIFont.systemFont(ofSize: 30.0)
        levelNumLabel.textColor = UIColor.yellow
        levelNumLabel.adjustsFontSizeToFitWidth = true
        levelNumLabel.textAlignment = NSTextAlignment.center
        
        robotImageView.frame = CGRect(x: 0.10 * frame.size.width, y: 0.30 * frame.size.height, width: 0.25 * frame.size.width, height: 0.25 * frame.size.height)
        robotImageView.image = allModelsAndMaterials.robotImage
        partImageView.frame = CGRect(x: 0.10 * frame.size.width, y: 0.50 * frame.size.height, width: 0.25 * frame.size.width, height: 0.25 * frame.size.height)
        partImageView.image = allModelsAndMaterials.partImage
        
        genericRobotImageView.frame = CGRect(x: 0.10 * frame.size.width, y: 0.10 * frame.size.height, width: 0.80 * frame.size.width, height: 0.80 * frame.size.height)
        genericRobotImageView.image = nil       // no image yet.  Only addit when we update the cells to show which ones are not unlocked yet.
        
        robotTallyLabel.frame = CGRect(x: 0.60 * frame.size.width, y: 0.30 * frame.size.height, width: 0.35 * frame.size.width, height: 0.25 * frame.size.height)
        robotTallyLabel.font = UIFont.systemFont(ofSize: 20.0)
        robotTallyLabel.textColor = UIColor.yellow
        robotTallyLabel.adjustsFontSizeToFitWidth = true

        partTallyLabel.frame = CGRect(x: 0.60 * frame.size.width, y: 0.50 * frame.size.height, width: 0.35 * frame.size.width, height: 0.25 * frame.size.height)
        partTallyLabel.font = UIFont.systemFont(ofSize: 20.0)
        partTallyLabel.textColor = UIColor.yellow
        partTallyLabel.adjustsFontSizeToFitWidth = true 
        
        star1ImageView.frame = CGRect(x: 0.10 * frame.size.width, y: 0.70 * frame.size.height, width: starImageViewSize.width, height: starImageViewSize.height)
        star1ImageView.image = allModelsAndMaterials.emptyStarImage
 
        star2ImageView.frame = CGRect(x: 0.35 * frame.size.width, y: 0.70 * frame.size.height, width: starImageViewSize.width, height: starImageViewSize.height)
        star2ImageView.image = allModelsAndMaterials.emptyStarImage

        star3ImageView.frame = CGRect(x: 0.60 * frame.size.width, y: 0.70 * frame.size.height, width: starImageViewSize.width, height: starImageViewSize.height)
        star3ImageView.image = allModelsAndMaterials.emptyStarImage
        

        backgroundColor = UIColor(red: 0.25, green: 0.15, blue: 0.25, alpha: 1.0)
        contentView.addSubview(levelNumLabel)
        contentView.addSubview(robotImageView)
        contentView.addSubview(partImageView)
        contentView.addSubview(robotTallyLabel)
        contentView.addSubview(partTallyLabel)
        contentView.addSubview(star1ImageView)
        contentView.addSubview(star2ImageView)
        contentView.addSubview(star3ImageView)
        contentView.addSubview(genericRobotImageView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
