//
//  Wall.swift
//  RobotRaider
//
//  Created by Nathanael Bills on 10/25/16.
//  Copyright © 2016 invasivemachines. All rights reserved.
//

import Foundation
import SceneKit

class Wall {
    var wallNode: SCNNode!
    var width: CGFloat = CGFloat(0.0)
    var height: CGFloat = CGFloat(0.0)
    var length: CGFloat = CGFloat(0.0)
    var name: String!
    var sceneLocation: SCNVector3!
    
    // One of three walls could have the exit.  The fourth wall, the near wall, will always
    // have the entrance.  We save the location of the exit or entrance so that we can put it
    // in the scene later.  Because once we're done here, the information won't be in the levelGrid
    // because we're trying to create simple walls and having the exit or entrance in the wall makes
    // it complicated to put in the scene and maintain because we have to then segment the wall into
    // the non-exit part(s) and the exit part, or the non-entrance part(s) and entrance part if we're
    // dealing with the near wall.  It's easier to just save the locations and then later put in an
    // object that represents the entrance or exit.
    //
    // Note: keep in mind that these are the start of the exit or entrance at the leftmost corner for
    // the entrance and if the exit is on the far wall and at the closest corner towards the zero row if
    // the exit is on the left or right wall.
    var exitLevelGridLocation: LevelCoordinates!
    var entranceLevelGridLocation: LevelCoordinates!
    
    init (maze: [[MazeElement]], levelGrid: inout [[[String]]], rowStart: Int, rowEnd: Int, colStart: Int, colEnd: Int, wallHeight: Float, wallMaterial: SCNMaterial, wallType: WallType) {
        let wallName = wallLabel + "_" + String(rowStart) + "_" + String(colStart)
        name = wallName
        for row in rowStart...rowEnd {
            for col in colStart...colEnd {
                levelGrid[row][col] = [wallName]    // market all row, column level coordinates with the same name - that way we know what wall
                                                    // is at a particularl row, column location.
                if maze[row][col].type == .mazeEntrance && entranceLevelGridLocation == nil {
                    entranceLevelGridLocation = LevelCoordinates(row: row, column: col)
                }
                if maze[row][col].type == .mazeExit && exitLevelGridLocation == nil {
                    exitLevelGridLocation = LevelCoordinates(row: row, column: col)
                }
            }
        }
        
        // Note: we add +1 to the calculations for colEnd - colStart and rowEnd - rowStart because those numbers
        // go from 0...max - 1.  To get the correct measurements for width and length we want from 1...max.
        width = CGFloat(Float(colEnd - colStart + 1) * standardWallBlockWidth)          // for now all walls are three wall blocks wide.
        height = CGFloat(wallHeight)
        length = CGFloat(Float(rowEnd - rowStart + 1) * standardWallBlockLength)
        if wallType == .leftwall || wallType == .rightwall {
            length += CGFloat(30.0)      // fudge factor to run the walls behind the camera at the start of the level.  Otherwise the near end
                                // of the right or left wall can be seen by the camera and that look wrong.
        }
        else if wallType == .nearwall {
            length += CGFloat(30.0)
        }
        
        let xcoord = (Float(colEnd - colStart + 1) / 2.0 + Float(colStart)) * standardWallBlockWidth
        let ycoord = wallHeight / 2.0
        var zcoord: Float = -1 * (Float(rowEnd - rowStart + 1) / 2.0 + Float(rowStart)) * standardWallBlockLength
        if wallType == .nearwall {
            // with the near wall's length being expanded, we have to adjust its z coordinate accordingly.
            zcoord += Float(length / 2.0) + zcoord
        }
        sceneLocation = SCNVector3(xcoord, ycoord, zcoord)
        
        // note: somehow the exhaustive switch statement above does not guarantee
        // wall creation.  So we do it here.
        if wallType == .innerwall {
            createInnerWallNode(wallMaterial: wallMaterial)
        }
        else {
            createOuterWallNode(wallMaterial: wallMaterial)
        }
        applyPhysicsToWall()
    }
    
    func createInnerWallNode(wallMaterial: SCNMaterial) {
        // find the nearest length to a storage unit or big conveyor and put those in place to block the player's robot
        // movements east-west.  These models are really inner walls so we call them that internally but to the player they
        // look like storage units or big conveyors (actually, we hope they look like storage units--not really sure).
        let nearestLength = round(length)       // nearest length in meters to one of the standard inner wall lengths
        switch nearestLength {
        case 12:
            wallNode = allModelsAndMaterials.storageunit24Model.clone()
            // Can't just clone a node. We also have to copy the geometry and material to make them independent
            // copies.  Otherwise what happens to one happens to all others of the same geometry and material.
            wallNode.geometry = allModelsAndMaterials.storageunit24Model.geometry?.copy() as? SCNGeometry
            wallNode.geometry?.firstMaterial = allModelsAndMaterials.storageunit24Model.geometry?.firstMaterial?.copy() as? SCNMaterial
            wallNode.scale = SCNVector3(1.0, 1.0, 0.5)   // shrink 24-meter length by 1/2 to make it 12 meters long
            wallNode.position = sceneLocation
            wallNode.position.y = 1.5
        case 16:
            wallNode = allModelsAndMaterials.storageunit16Model.clone()
            // Can't just clone a node. We also have to copy the geometry and material to make them independent
            // copies.  Otherwise what happens to one happens to all others of the same geometry and material.
            wallNode.geometry = allModelsAndMaterials.storageunit16Model.geometry?.copy() as? SCNGeometry
            wallNode.geometry?.firstMaterial = allModelsAndMaterials.storageunit16Model.geometry?.firstMaterial?.copy() as? SCNMaterial
            wallNode.position = sceneLocation
            wallNode.position.y = 1.5
        case 20:
            wallNode = allModelsAndMaterials.bigconveyor20Model.clone()
            // Can't just clone a node. We also have to copy the geometry and material to make them independent
            // copies.  Otherwise what happens to one happens to all others of the same geometry and material.
            wallNode.geometry = allModelsAndMaterials.bigconveyor20Model.geometry?.copy() as? SCNGeometry
            wallNode.geometry?.firstMaterial = allModelsAndMaterials.bigconveyor20Model.geometry?.firstMaterial?.copy() as? SCNMaterial
            wallNode.position = sceneLocation
            wallNode.position.y = 1.5
        case 24:
            wallNode = allModelsAndMaterials.storageunit24Model.clone()
            // Can't just clone a node. We also have to copy the geometry and material to make them independent
            // copies.  Otherwise what happens to one happens to all others of the same geometry and material.
            wallNode.geometry = allModelsAndMaterials.storageunit24Model.geometry?.copy() as? SCNGeometry
            wallNode.geometry?.firstMaterial = allModelsAndMaterials.storageunit24Model.geometry?.firstMaterial?.copy() as? SCNMaterial
            wallNode.position = sceneLocation
            wallNode.position.y = 1.5
        case 32:
            let wallSubNode1 = allModelsAndMaterials.storageunit16Model.clone()
            wallSubNode1.geometry = allModelsAndMaterials.storageunit16Model.geometry?.copy() as? SCNGeometry
            wallSubNode1.geometry?.firstMaterial = allModelsAndMaterials.storageunit16Model.geometry?.firstMaterial?.copy() as? SCNMaterial
            wallSubNode1.position = SCNVector3(0.0, 0.0, -8.0)
            let wallSubNode2 = allModelsAndMaterials.storageunit16Model.clone()
            wallSubNode2.geometry = allModelsAndMaterials.storageunit16Model.geometry?.copy() as? SCNGeometry
            wallSubNode2.geometry?.firstMaterial = allModelsAndMaterials.storageunit16Model.geometry?.firstMaterial?.copy() as? SCNMaterial
            wallSubNode2.position = SCNVector3(0.0, 0.0, 8.0)
            
            wallNode = SCNNode()
            wallNode.addChildNode(wallSubNode1)
            wallNode.addChildNode(wallSubNode2)
            wallNode.position = sceneLocation
            wallNode.position.y = 1.5
        case 36:
            wallNode = allModelsAndMaterials.bigconveyor36Model.clone()
            // Can't just clone a node. We also have to copy the geometry and material to make them independent
            // copies.  Otherwise what happens to one happens to all others of the same geometry and material.
            wallNode.geometry = allModelsAndMaterials.bigconveyor36Model.geometry?.copy() as? SCNGeometry
            wallNode.geometry?.firstMaterial = allModelsAndMaterials.bigconveyor36Model.geometry?.firstMaterial?.copy() as? SCNMaterial
            wallNode.position = sceneLocation
            wallNode.position.y = 1.5
        case 40:
            wallNode = allModelsAndMaterials.storageunit40Model.clone()
            // Can't just clone a node. We also have to copy the geometry and material to make them independent
            // copies.  Otherwise what happens to one happens to all others of the same geometry and material.
            wallNode.geometry = allModelsAndMaterials.storageunit40Model.geometry?.copy() as? SCNGeometry
            wallNode.geometry?.firstMaterial = allModelsAndMaterials.storageunit40Model.geometry?.firstMaterial?.copy() as? SCNMaterial
            wallNode.position = sceneLocation
            wallNode.position.y = 1.5
        case 44:
            wallNode = allModelsAndMaterials.bigconveyor44Model.clone()
            // Can't just clone a node. We also have to copy the geometry and material to make them independent
            // copies.  Otherwise what happens to one happens to all others of the same geometry and material.
            wallNode.geometry = allModelsAndMaterials.bigconveyor44Model.geometry?.copy() as? SCNGeometry
            wallNode.geometry?.firstMaterial = allModelsAndMaterials.bigconveyor44Model.geometry?.firstMaterial?.copy() as? SCNMaterial
            wallNode.position = sceneLocation
            wallNode.position.y = 1.5
        case 52:
            wallNode = allModelsAndMaterials.storageunit40Model.clone()
            // Can't just clone a node. We also have to copy the geometry and material to make them independent
            // copies.  Otherwise what happens to one happens to all others of the same geometry and material.
            wallNode.geometry = allModelsAndMaterials.storageunit40Model.geometry?.copy() as? SCNGeometry
            wallNode.geometry?.firstMaterial = allModelsAndMaterials.storageunit40Model.geometry?.firstMaterial?.copy() as? SCNMaterial
            wallNode.scale = SCNVector3(1.0, 1.0, 1.3)   // multiply a 40-meter model by 1.3 to make a 52-meter length model.
            wallNode.position = sceneLocation
            wallNode.position.y = 1.5
        case 56:
            wallNode = allModelsAndMaterials.storageunit40Model.clone()
            // Can't just clone a node. We also have to copy the geometry and material to make them independent
            // copies.  Otherwise what happens to one happens to all others of the same geometry and material.
            wallNode.geometry = allModelsAndMaterials.storageunit40Model.geometry?.copy() as? SCNGeometry
            wallNode.geometry?.firstMaterial = allModelsAndMaterials.storageunit40Model.geometry?.firstMaterial?.copy() as? SCNMaterial
            wallNode.scale = SCNVector3(1.0, 1.0, 1.4)   // multiply a 40-meter model by 1.4 to make a 56-meter length model.
            wallNode.position = sceneLocation
            wallNode.position.y = 1.5
        case 60:
            wallNode = allModelsAndMaterials.storageunit40Model.clone()
            // Can't just clone a node. We also have to copy the geometry and material to make them independent
            // copies.  Otherwise what happens to one happens to all others of the same geometry and material.
            wallNode.geometry = allModelsAndMaterials.storageunit40Model.geometry?.copy() as? SCNGeometry
            wallNode.geometry?.firstMaterial = allModelsAndMaterials.storageunit40Model.geometry?.firstMaterial?.copy() as? SCNMaterial
            wallNode.scale = SCNVector3(1.0, 1.0, 1.5)   // multiply a 40-meter model by 1.5 to make a 60-meter length model.
            wallNode.position = sceneLocation
            wallNode.position.y = 1.5
        case 64:
            wallNode = allModelsAndMaterials.storageunit40Model.clone()
            // Can't just clone a node. We also have to copy the geometry and material to make them independent
            // copies.  Otherwise what happens to one happens to all others of the same geometry and material.
            wallNode.geometry = allModelsAndMaterials.storageunit40Model.geometry?.copy() as? SCNGeometry
            wallNode.geometry?.firstMaterial = allModelsAndMaterials.storageunit40Model.geometry?.firstMaterial?.copy() as? SCNMaterial
            wallNode.scale = SCNVector3(1.0, 1.0, 1.6)   // multiply a 40-meter model by 1.6 to make a 64-meter length model.
            wallNode.position = sceneLocation
            wallNode.position.y = 1.5
        case 72:
            let wallSubNode1 = allModelsAndMaterials.bigconveyor36Model.clone()
            wallSubNode1.geometry = allModelsAndMaterials.bigconveyor36Model.geometry?.copy() as? SCNGeometry
            wallSubNode1.geometry?.firstMaterial = allModelsAndMaterials.bigconveyor36Model.geometry?.firstMaterial?.copy() as? SCNMaterial
            wallSubNode1.position = SCNVector3(0.0, 0.0, -18.0)
            let wallSubNode2 = allModelsAndMaterials.bigconveyor36Model.clone()
            wallSubNode2.geometry = allModelsAndMaterials.bigconveyor36Model.geometry?.copy() as? SCNGeometry
            wallSubNode2.geometry?.firstMaterial = allModelsAndMaterials.bigconveyor36Model.geometry?.firstMaterial?.copy() as? SCNMaterial
            wallSubNode2.position = SCNVector3(0.0, 0.0, 18.0)
            
            wallNode = SCNNode()
            wallNode.addChildNode(wallSubNode1)
            wallNode.addChildNode(wallSubNode2)
            wallNode.position = sceneLocation
            wallNode.position.y = 1.5
        case 76:
            let wallSubNode1 = allModelsAndMaterials.bigconveyor36Model.clone()
            wallSubNode1.geometry = allModelsAndMaterials.bigconveyor36Model.geometry?.copy() as? SCNGeometry
            wallSubNode1.geometry?.firstMaterial = allModelsAndMaterials.bigconveyor36Model.geometry?.firstMaterial?.copy() as? SCNMaterial
            wallSubNode1.position = SCNVector3(0.0, 0.0, 20.0)
            let wallSubNode2 = allModelsAndMaterials.storageunit40Model.clone()
            wallSubNode2.geometry = allModelsAndMaterials.storageunit40Model.geometry?.copy() as? SCNGeometry
            wallSubNode2.geometry?.firstMaterial = allModelsAndMaterials.storageunit40Model.geometry?.firstMaterial?.copy() as? SCNMaterial
            wallSubNode2.position = SCNVector3(0.0, 0.0, -18.0)
            
            wallNode = SCNNode()
            wallNode.addChildNode(wallSubNode1)
            wallNode.addChildNode(wallSubNode2)
            wallNode.position = sceneLocation
            wallNode.position.y = 1.5
        case 80:
            let wallSubNode1 = allModelsAndMaterials.storageunit40Model.clone()
            wallSubNode1.geometry = allModelsAndMaterials.storageunit40Model.geometry?.copy() as? SCNGeometry
            wallSubNode1.geometry?.firstMaterial = allModelsAndMaterials.storageunit40Model.geometry?.firstMaterial?.copy() as? SCNMaterial
            wallSubNode1.position = SCNVector3(0.0, 0.0, -20.0)
            let wallSubNode2 = allModelsAndMaterials.storageunit40Model.clone()
            wallSubNode2.geometry = allModelsAndMaterials.storageunit40Model.geometry?.copy() as? SCNGeometry
            wallSubNode2.geometry?.firstMaterial = allModelsAndMaterials.storageunit40Model.geometry?.firstMaterial?.copy() as? SCNMaterial
            wallSubNode2.position = SCNVector3(0.0, 0.0, 20.0)

            wallNode = SCNNode()
            wallNode.addChildNode(wallSubNode1)
            wallNode.addChildNode(wallSubNode2)
            wallNode.position = sceneLocation
            wallNode.position.y = 1.5
        case 84:
            let wallSubNode1 = allModelsAndMaterials.bigconveyor44Model.clone()
            wallSubNode1.geometry = allModelsAndMaterials.bigconveyor44Model.geometry?.copy() as? SCNGeometry
            wallSubNode1.geometry?.firstMaterial = allModelsAndMaterials.bigconveyor44Model.geometry?.firstMaterial?.copy() as? SCNMaterial
            wallSubNode1.position = SCNVector3(0.0, 0.0, 20.0)
            let wallSubNode2 = allModelsAndMaterials.storageunit40Model.clone()
            wallSubNode2.geometry = allModelsAndMaterials.storageunit40Model.geometry?.copy() as? SCNGeometry
            wallSubNode2.geometry?.firstMaterial = allModelsAndMaterials.storageunit40Model.geometry?.firstMaterial?.copy() as? SCNMaterial
            wallSubNode2.position = SCNVector3(0.0, 0.0, -22.0)
            
            wallNode = SCNNode()
            wallNode.addChildNode(wallSubNode1)
            wallNode.addChildNode(wallSubNode2)
            wallNode.position = sceneLocation
            wallNode.position.y = 1.5
        default:
            // no match for existing walls so we just create a simple block
            let wall = SCNBox(width: width, height: height, length: length, chamferRadius: 2.0)
            wallNode = SCNNode(geometry: wall)
            wallNode.geometry?.firstMaterial?.diffuse.contents = UIColor.darkGray
            wallNode.position = sceneLocation
            break
        }
        wallNode.name = name

    }
    
    // create simple blocks for the outer walls.
    func createOuterWallNode(wallMaterial: SCNMaterial) {
        let wall = SCNBox(width: width, height: height, length: length, chamferRadius: 0.0)
        wallNode = SCNNode(geometry: wall)
        wallNode.geometry?.firstMaterial = wallMaterial.copy() as? SCNMaterial
        // For some reason we couldn't set the parameters below for the material in our AllModelsAndMaterials class
        // we had to set it here to get it to work.
        wallNode.geometry?.firstMaterial?.multiply.contents = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0)
        wallNode.geometry?.firstMaterial?.diffuse.wrapS = SCNWrapMode.repeat
        wallNode.geometry?.firstMaterial?.diffuse.wrapT = SCNWrapMode.repeat
        // from https://stackoverflow.com/questions/44920519/repeating-a-texture-over-a-plane-in-scenekit
        // This sets the scale of the floor pattern to keep it from being too big or too small.  If not
        // set, then the grid becomes way to coarse.  If set too high, the grid is way too granular.
        wallNode.geometry?.firstMaterial?.diffuse.contentsTransform = SCNMatrix4MakeScale(10, 10, 0)
        wallNode.position = sceneLocation
        wallNode.name = name
    }
    
    func applyPhysicsToWall() {
        // Note: we ran into problems with the wallNodes that were based on combinations of subnodes.  So here we just
        // assign a basic shape for all of the walls.  Still have yet to figure out what to do about the conveyor belts, though,
        // that have a feeder structure that is intended to drop stuff on to the conveyor belt.  It sticks up well above the conveyor
        // belt and stuff will go right through it right now.
        let wallShape = SCNPhysicsShape(geometry: SCNBox(width: width, height: height, length: length, chamferRadius: 0.0), options: nil)
        wallNode.physicsBody = SCNPhysicsBody(type: .static, shape: wallShape)
        wallNode.physicsBody!.categoryBitMask = collisionCategoryWall
        wallNode.physicsBody!.contactTestBitMask = collisionCategoryAIRobotBakedGood | collisionCategoryPlayerRobotBakedGood
        wallNode.physicsBody!.collisionBitMask = collisionCategoryAIRobot | collisionCategoryPlayerRobot | collisionCategoryGround | collisionCategoryEMPGrenade
    }

}
