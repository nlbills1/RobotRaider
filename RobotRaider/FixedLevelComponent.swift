//
//  FixedLevelComponent.swift
//  RobotRaider
//
//  Created by Nathanael Bills on 12/7/16.
//  Copyright © 2016 invasivemachines. All rights reserved.
//

import Foundation
import SceneKit

// Create a component in the level that is fixed, or not moving.  Most of 
// these are static/stationary robots.  The table is not a robots at all
// but all the other component types are static robots, even the column, 
// which has an arm that it can spin around (as of 03/20/2017, the arm
// still needs to be added)
class FixedLevelComponent {
    
    var componentNode: SCNNode!
    var playerRobotInRange: Bool = false
    
    init (type: LevelComponentType, location: SCNVector3, levelLocation: LevelCoordinates) {
        switch type {
        case .table:
            createTable(location: location, levelLoc: levelLocation)
            applyPhysicsToComponent()
        case .refrigerator:
            createRefrigerator(location: location, levelLoc: levelLocation)
            applyPhysicsToComponent()
        case .rack:
            createRack(location: location, levelLoc: levelLocation)
            applyPhysicsToComponent()
        case .conveyor:
            createConveyorBelt(location: location, levelLoc: levelLocation)
            applyPhysicsToComponent()
        case .mixer:
            createIndustrialMixer(location: location, levelLoc: levelLocation)
            applyPhysicsToComponent()
        case .oven:
            createOven(location: location, levelLoc: levelLocation)
            applyPhysicsToComponent()
        case .deepfryer:
            createDeepFryer(location: location, levelLoc: levelLocation)
            applyPhysicsToComponent()
        case .wall:
            createWallBlock(location: location, levelLoc: levelLocation)
            applyPhysicsToComponent()
        case .entrancewall:
            createEntranceWallBlock(location: location, levelLoc: levelLocation)
            applyPhysicsToComponent()
        case .exitwall:
            createExitWallBlock(location: location, levelLoc: levelLocation)
            applyPhysicsToComponent()
        default:   // default to empty space
            break
        }
    }
    
    func applyPhysicsToComponent() {
        componentNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        componentNode.physicsBody!.categoryBitMask = collisionCategoryLevelComponent
        componentNode.physicsBody!.contactTestBitMask = collisionCategoryAIRobotBakedGood | collisionCategoryPlayerRobotBakedGood
        componentNode.physicsBody!.collisionBitMask = collisionCategoryAIRobot | collisionCategoryPlayerRobot | collisionCategoryGround | collisionCategoryDyingRobot | collisionCategoryEMPGrenade
    }
    
    func createWallBlock(location: SCNVector3, levelLoc: LevelCoordinates) {
        let wallBlock = SCNBox(width: CGFloat(levelComponentSpaceWidth), height: CGFloat(innerWallHeight), length: CGFloat(levelComponentSpaceLength), chamferRadius: 0.0)
        componentNode = SCNNode(geometry: wallBlock)
        componentNode.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        componentNode.position = location
        componentNode.name = wallLabel + "_" + String(levelLoc.row) + "_" + String(levelLoc.column)
    }
    
    func createExitWallBlock(location: SCNVector3, levelLoc: LevelCoordinates) {
        let wallBlock = SCNBox(width: CGFloat(levelComponentSpaceWidth), height: CGFloat(standardWallHeight), length: CGFloat(levelComponentSpaceLength), chamferRadius: 0.0)
        componentNode = SCNNode(geometry: wallBlock)
        componentNode.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
        componentNode.position = location
        componentNode.name = wallLabel + "_" + String(levelLoc.row) + "_" + String(levelLoc.column)
    }

    func createEntranceWallBlock(location: SCNVector3, levelLoc: LevelCoordinates) {
        let wallBlock = SCNBox(width: CGFloat(levelComponentSpaceWidth), height: CGFloat(standardWallHeight), length: CGFloat(levelComponentSpaceLength), chamferRadius: 0.0)
        componentNode = SCNNode(geometry: wallBlock)
        componentNode.geometry?.firstMaterial?.diffuse.contents = UIColor.purple
        componentNode.position = location
        componentNode.name = wallLabel + "_" + String(levelLoc.row) + "_" + String(levelLoc.column)
    }

    func createTable(location: SCNVector3, levelLoc: LevelCoordinates) {
        componentNode = allModelsAndMaterials.tableModel.clone()
        componentNode.position = location
        componentNode.position.y = tableHeight
        componentNode.name = tableLabel + "_" + String(levelLoc.row) + "_" + String(levelLoc.column)
    }
    
    func createRefrigerator(location: SCNVector3, levelLoc: LevelCoordinates) {
        componentNode = allModelsAndMaterials.refrigeratorModel.clone()
        componentNode.position = location
        componentNode.position.y = refrigeratorHeight
        componentNode.name = refrigeratorLabel + "_" + String(levelLoc.row) + "_" + String(levelLoc.column)
    }
    
    func createRack(location: SCNVector3, levelLoc: LevelCoordinates) {
        componentNode = allModelsAndMaterials.rackModel.clone()
        componentNode.position = location
        componentNode.position.y = rackHeight
        componentNode.name = rackLabel + "_" + String(levelLoc.row) + "_" + String(levelLoc.column)
    }
    
    func createConveyorBelt(location: SCNVector3, levelLoc: LevelCoordinates) {
        componentNode = allModelsAndMaterials.conveyorModel.clone()
        componentNode.position = location
        componentNode.position.y = conveyorHeight
        componentNode.name = conveyorLabel + "_" + String(levelLoc.row) + "_" + String(levelLoc.column)
    }
    
    func createIndustrialMixer(location: SCNVector3, levelLoc: LevelCoordinates) {
        componentNode = allModelsAndMaterials.mixerModel.clone()
        componentNode.position = location
        componentNode.position.y = mixerHeight
        componentNode.name = mixerLabel + "_" + String(levelLoc.row) + "_" + String(levelLoc.column)
    }
    
    func createOven(location: SCNVector3, levelLoc: LevelCoordinates) {
        componentNode = allModelsAndMaterials.ovenModel.clone()
        componentNode.position = location
        componentNode.position.y = ovenHeight
        componentNode.name = ovenLabel + "_" + String(levelLoc.row) + "_" + String(levelLoc.column)
    }
    
    func createDeepFryer(location: SCNVector3, levelLoc: LevelCoordinates) {
        componentNode = allModelsAndMaterials.deepfryerModel.clone()
        componentNode.position = location
        componentNode.position.y = deepfryerHeight
        componentNode.name = deepFryerLabel + "_" + String(levelLoc.row) + "_" + String(levelLoc.column)
    }
}
