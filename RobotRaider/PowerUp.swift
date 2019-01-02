//
//  PowerUp.swift
//  RobotRaider
//
//  Created by Nathanael Bills on 8/17/17.
//  Copyright © 2017 invasivemachines. All rights reserved.
//

import Foundation
import SceneKit

class PowerUp {
    var levelCoords: LevelCoordinates = LevelCoordinates(row: 0, column: 0)
    var timePowerUpLasts: Int = 0     // in seconds
    var powerUpNode: SCNNode!
    var powerUpAlreadyPickedUp: Bool = false
    var powerUpType: PowerUpType = .noPowerUp
    var powerUpMultiple: Int = 0
    var powerUpText: String = ""
    var powerUpName: String = ""
    
    init (powerUpNum: Int, type: PowerUpType, name: String, location: LevelCoordinates, levelNum: Int, randomGen: RandomNumberGenerator) {
        powerUpType = type
        powerUpName = name
        let powerUpGenericName = powerUpLabel + String(powerUpNum)

        switch powerUpType {
        case .fasterReloadPowerUp:
            powerUpNode = allModelsAndMaterials.reloadPowerUpModel.clone()
            // Can't just clone a node. We also have to copy the geometry and material to make them independent
            // copies.  Otherwise what happens to one happens to all others of the same geometry and material.
            powerUpNode.geometry = allModelsAndMaterials.reloadPowerUpModel.geometry?.copy() as? SCNGeometry
            powerUpNode.geometry?.firstMaterial = allModelsAndMaterials.reloadPowerUpModel.geometry?.firstMaterial?.copy() as? SCNMaterial
        case .speedPowerUp:
            powerUpNode = allModelsAndMaterials.speedPowerUpModel.clone()
            // Can't just clone a node. We also have to copy the geometry and material to make them independent
            // copies.  Otherwise what happens to one happens to all others of the same geometry and material.
            powerUpNode.geometry = allModelsAndMaterials.speedPowerUpModel.geometry?.copy() as? SCNGeometry
            powerUpNode.geometry?.firstMaterial = allModelsAndMaterials.speedPowerUpModel.geometry?.firstMaterial?.copy() as? SCNMaterial
        case .throwingForcePowerUp:
            powerUpNode = allModelsAndMaterials.forcePowerUpModel.clone()
            // Can't just clone a node. We also have to copy the geometry and material to make them independent
            // copies.  Otherwise what happens to one happens to all others of the same geometry and material.
            powerUpNode.geometry = allModelsAndMaterials.forcePowerUpModel.geometry?.copy() as? SCNGeometry
            powerUpNode.geometry?.firstMaterial = allModelsAndMaterials.forcePowerUpModel.geometry?.firstMaterial?.copy() as? SCNMaterial
        default:
            break
        }

        powerUpNode.name = powerUpGenericName
        levelCoords = location
        let sceneLocation = calculateSceneCoordinatesFromLevelRowAndColumn(levelCoords: levelCoords)
        powerUpNode.position = sceneLocation
        powerUpNode.position.y = 0.5           // 1/2 the height.
        powerUpNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        powerUpNode.physicsBody!.categoryBitMask = collisionCategoryPowerUp
        powerUpNode.physicsBody!.contactTestBitMask = collisionCategoryPlayerRobot
        
        // This is the multiple we use when calculating 2x, 3x, 4x, etc. of a power up.  Thus a powerUp multiple
        // of 2 for speedup increases speed to 2x original speed.  At the same time a 2x powerup of faster reload
        // reduces reload time to 1/2 so we divide by the powerup multiple to get a fraction of the original
        // reload time.
        powerUpMultiple = randomGen.xorshift_randomgen() % maxPowerUpMultiple + 2   // We add 2 because if we didn't the lowest multiple
                                                                                    // could be zero and we want a power up to always be
                                                                                    // a multiple of normal capability.  If it was just 1
                                                                                    // then power up would just be the same as normal.  With
                                                                                    // a minimum of 2 we then get at least 2x of anything or 1/2
                                                                                    // if the goal is to reduce time.
        
        // The multipler is used to affect the time
        // the reload time or the speed of a baked good, or the speed up of the robot lasts;
        // it remains relatively fixed, but progressive.
        powerUpText = String(powerUpMultiple) + "x " + powerUpName
        timePowerUpLasts = levelNum / 4 + (powerUpList[powerUpName]?.defaultTimeLimit)!
        // cap the time a power up can last so it can't go too high.
        if timePowerUpLasts > maxTimePowerUpCanLast {
            timePowerUpLasts = maxTimePowerUpCanLast
        }
    }
}
