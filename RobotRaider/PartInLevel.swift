//
//  PartInLevel.swift
//  RobotRaider
//
//  Created by Nathanael Bills on 8/17/17.
//  Copyright © 2017 invasivemachines. All rights reserved.
//

import Foundation
import SceneKit

class PartInLevel {
    var levelCoords: LevelCoordinates = LevelCoordinates(row: 0, column: 0)
    var partNode: SCNNode!
    var partAlreadyPickedUp: Bool = false
    var partType: PartType = .noPart
    var partNumber: Int = 0
    var prizeAssociatedWithPart: PrizeListElement!          // the prize for which this part is for, for identification purposes later.
    
    init (partNum: Int, levelNum: Int, type: PartType, location: LevelCoordinates) {
        partType = type
        partNumber = partNum
        
        if levelNum == highestLevelNumber {
            prizeAssociatedWithPart = keyPrize 
        }
        else {
            prizeAssociatedWithPart = getPrizeElement(partNum: partNumber)
        }
        let partName = partLabel + String(partNum)

        switch partType {
        case .ammoPart:
            partNode = allModelsAndMaterials.ammoPartModel.clone()
            // Can't just clone a node. We also have to copy the geometry and material to make them independent
            // copies.  Otherwise what happens to one happens to all others of the same geometry and material.
            partNode.geometry = allModelsAndMaterials.ammoPartModel.geometry?.copy() as? SCNGeometry
            partNode.geometry?.firstMaterial = allModelsAndMaterials.ammoPartModel.geometry?.firstMaterial?.copy() as? SCNMaterial
        case .equipmentPart:
            partNode = allModelsAndMaterials.equipmentPartModel.clone()
            // Can't just clone a node. We also have to copy the geometry and material to make them independent
            // copies.  Otherwise what happens to one happens to all others of the same geometry and material.
            partNode.geometry = allModelsAndMaterials.equipmentPartModel.geometry?.copy() as? SCNGeometry
            partNode.geometry?.firstMaterial = allModelsAndMaterials.equipmentPartModel.geometry?.firstMaterial?.copy() as? SCNMaterial
        case .weaponPart:
            partNode = allModelsAndMaterials.weaponPartModel.clone()
            // Can't just clone a node. We also have to copy the geometry and material to make them independent
            // copies.  Otherwise what happens to one happens to all others of the same geometry and material.
            partNode.geometry = allModelsAndMaterials.weaponPartModel.geometry?.copy() as? SCNGeometry
            partNode.geometry?.firstMaterial = allModelsAndMaterials.weaponPartModel.geometry?.firstMaterial?.copy() as? SCNMaterial
        case .keyPart:
            partNode = allModelsAndMaterials.keyPartModel.clone()
            // Can't just clone a node. We also have to copy the geometry and material to make them independent
            // copies.  Otherwise what happens to one happens to all others of the same geometry and material.
            partNode.geometry = allModelsAndMaterials.keyPartModel.geometry?.copy() as? SCNGeometry
            partNode.geometry?.firstMaterial = allModelsAndMaterials.keyPartModel.geometry?.firstMaterial?.copy() as? SCNMaterial
        default:
            break
        }
        
        partNode.name = partName
        levelCoords = location
        let sceneLocation = calculateSceneCoordinatesFromLevelRowAndColumn(levelCoords: levelCoords)
        partNode.position = sceneLocation
        partNode.position.y = 0.4       // 1/2 the height
        partNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        partNode.physicsBody!.categoryBitMask = collisionCategoryPart
        partNode.physicsBody!.contactTestBitMask = collisionCategoryPlayerRobot
    }    
}
