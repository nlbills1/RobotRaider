//
//  PlayerPermanentData.swift
//  RobotRaider
//
//  Created by Nathanael Bills on 4/24/17.
//  Copyright © 2017 invasivemachines. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class PlayerLevelData {
    
    var numberOfPartsFound: Int = 0
    var numberOfRobotsDestroyed: Int = 0
    var maxPartsToFind: Int = 0
    var maxRobotsToDestroy: Int = 0
    
    init (maxRobots: Int, maxParts: Int) {
        maxRobotsToDestroy = maxRobots
        maxPartsToFind = maxParts
        
    }
    
    // For now we just update this.  We don't display it.
    func updateNumberOfPartsFound (numberOfParts: Int) {
        numberOfPartsFound += numberOfParts
    }
    
    func updateNumberOfRobotsDestroyed (numberOfRobots: Int) {
        numberOfRobotsDestroyed += numberOfRobots
    }
    
}
