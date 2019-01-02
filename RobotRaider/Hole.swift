//
//  Hole.swift
//  RobotRaider
//
//  Created by Nathanael Bills on 1/9/18.
//  Copyright © 2018 invasivemachines. All rights reserved.
//

import Foundation
import SceneKit

// holes - essentially holes in the floor that a robot can fall through unless they use
// the hover unit.  We used to call them pits but holes make more sense, and we can leave
// them as squares instead of trying to make them circular.  They can be the result of
// floor tiles being picked up to make holes.
class Hole {
    var levelCoords: LevelCoordinates = LevelCoordinates(row: 0, column: 0)
    var holeNode: SCNNode!
    var camouflaged: Bool = true
    
    init (holeNum: Int, location: LevelCoordinates) {
        let holeColor = UIColor.black
        let holeName = holeLabel + String(holeNum)
        // Note: through trial-and-error we see that we need to add 30% to the width and 50% to the length to make it look like the
        // robot is actually falling through the hole when it is fully in the hole.  Otherwise it will look like it is falling in
        // when it has one wheel on edge.  With these increases in size it does look like it is falling in.  The one downside might
        // be when holes are next to each other.  We will have to test that.
        let holeGeometry = SCNBox(width: CGFloat(levelComponentSpaceWidth) * 1.30, height: 0.05, length: CGFloat(levelComponentSpaceLength) * 1.50, chamferRadius: 0.0)
        holeNode = SCNNode(geometry: holeGeometry)
        holeNode.geometry?.firstMaterial?.diffuse.contents = holeColor
        holeNode.name = holeName
        levelCoords = location
        let sceneLocation = calculateSceneCoordinatesFromLevelRowAndColumn(levelCoords: levelCoords)
        holeNode.position = sceneLocation
        holeNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        holeNode.physicsBody!.categoryBitMask = collisionCategoryHole
        holeNode.physicsBody!.contactTestBitMask = collisionCategoryPlayerRobot | collisionCategoryAIRobot
    }
    
    func camouflageHole() {
        camouflaged = true
        let camouflageColor = UIColor.black 
        holeNode.geometry?.firstMaterial?.diffuse.contents = camouflageColor
        holeNode.geometry?.firstMaterial?.transparency = 0.30
    }
    
    // make the hole plainly visible when player goes over it.
    func uncamouflageHole() {
        camouflaged = false 
        let holeColor = UIColor.black
        holeNode.geometry?.firstMaterial?.diffuse.contents = holeColor
        holeNode.geometry?.firstMaterial?.transparency = 1.0
    }
}

