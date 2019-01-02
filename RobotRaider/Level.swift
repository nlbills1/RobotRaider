//
//  Level.swift
//  RobotRaider
//
//  Created by Nathanael Bills on 12/2/16.
//  Copyright © 2016 invasivemachines. All rights reserved.
//

import Foundation
import SceneKit

class Level {
    var levelNumber: Int = 0
    
    var levelChallenges: LevelChallenges!
    
    var levelComponentsList: [String : FixedLevelComponent] = [ : ]
    var allDurableComponents: [String : LevelComponentType] = [ : ]         // dictionary for all components to make lookups faster
                                                                 // than using our original getLevelComponentType() function, which did string
                                                                 // comparisons.
                                                                 // This is primarily for walls, fixed level components and robots,
                                                                 // anything likely to be in the levelGrid.
    
    var randomNumGenerator: RandomNumberGenerator!
    
    // keep track of where level components are in a 2d array of
    // level component names.  The first dimension is the row and
    // the second is the column.  The row,column should match that
    // calculated by the calculateLevelRowAndColumn() function.
    var levelGrid: [[[String]]] = [[[]]]
    
    var bakeryRoom: BakeryRoom!
    var levelExitNode: SCNNode!             // The level exit, inside the doorway, needs to be touched before the player can exit.
    var levelExitDoorwayNode: SCNNode!      // the doorway surrounding the exit should not allow the player to go through it to get out.
    var levelEntranceNode: SCNNode!         // the entrance, just there for show.  The player can't go back through it.
    
    var vaultNode: SCNNode!             // The vault is used in place of the levelExitNode in the last level of the game.
    var vaultDoorwayNode: SCNNode!      // The doorway into the vault.  It surrounds the vault and the player has to go through the center of it.
    var vaultBarrierNode: SCNNode!      // This is an invisible barrier in front of the vault that prevents the player from touching the vault unless
                                        // the player has all the key parts.

    var numberOfAIRobotThrowsThatMiss: Int = 2  // right now this is hardcoded at 2.  Later we should change this if necessary to increase difficulty, or easiness.
    
    var levelMaze: Maze!            // The maze upon which the level is built.
    var numLevelComponentTypes: Int = 0     // The number of types of level components from which to randomly choose to place in level.
    var numVisibleHoles: Int = 0
    var numCamouflagedHoles: Int = 0
    
    var playerStartingPoint: LevelCoordinates!   // The starting point of the player, at the level's entrance.
    var levelExitPoint: LevelCoordinates!        // The player's destination.
    
    var emptySpacesList: EmptySpacesList!
    
    var holes: [String: Hole] = [:]             // keep track of holes.  We didn't want to do this but we see that we need to if we want to
                                                // show holes when players fall into the camouflaged ones.
    
    init (sceneView: SCNView, levelNum: Int, randomGenerator: RandomNumberGenerator) {
        // Set the level first thing.
        levelNumber = levelNum
        randomNumGenerator = randomGenerator
        randomNumGenerator = RandomNumberGenerator(seed: levelNumber)
        
        levelChallenges = allLevelChallenges[levelNumber - 1]

        // for now we make each level a simple square
        let numRows = levelChallenges.rows
        let numColumns = levelChallenges.rows
        numVisibleHoles = levelChallenges.holes
        numCamouflagedHoles = levelChallenges.camouflagedholes
        numLevelComponentTypes = levelChallenges.componenttypes
        numberOfAIRobotThrowsThatMiss = levelChallenges.numAIRobotMisses            // number of times ai robots should miss before throwing one that hits.
        
        // kludgy but it works.  We set one element of the allDurableComponents dictionary with
        // a key for the EmptyLabel.  That way whenever there is a lookup for that something
        // comes back immediately.
        allDurableComponents[emptyLabel] = .nocomponent
        
        // Note: the numRows and numColumns are the basis for the maze generation but the
        // actual number of rows and columns will be different because we've had to expand the
        // number of rows and columns to give the player the ability to navigate the maze.
        levelMaze = Maze(numRows: numRows, numCols: numColumns, level: levelNumber, randomGenerator: randomNumGenerator)
        emptySpacesList = EmptySpacesList(numRegions: defaultNumberOfRegions, maze: levelMaze.theMazeExpanded)
        
        init_level_grid(numRows: levelMaze.theMazeExpanded.count, numCols: levelMaze.theMazeExpanded[0].count)
        bakeryRoom = BakeryRoom(maze: levelMaze.theMazeExpanded, levelGrid: &levelGrid, levelNum: levelNumber)
        for (_,aWall) in bakeryRoom.walls {
            sceneView.scene?.rootNode.addChildNode(aWall.wallNode)
            allDurableComponents[aWall.wallNode.name!] = .wall     // Important: add to all components list for quick reference later
            if aWall.entranceLevelGridLocation != nil {
                let entranceLoc = aWall.entranceLevelGridLocation
                // Note: one of the four walls has to have the entrance.  Otherwise the game will crash.  But
                // one wall, the near wall, should always have the entrance.
                playerStartingPoint = LevelCoordinates(row: (entranceLoc?.row)! + 2, column: (entranceLoc?.column)!)
            }
        }
        // add the floor strip in front of the far wall to mask the look of the exit floor sticking out from the wall.
        sceneView.scene?.rootNode.addChildNode(bakeryRoom.farWallFloorStrip)
        
        // Add exit or vault after adding the walls in the room.  This is particularly important for the vault as
        // we depend on the far wall dimensions and position for placing the vault in the center of the far wall.
        if levelNumber < highestLevelNumber {
            addLevelExit(exitQuadrant: levelMaze.chosenExitQuadrant, exitWallBlocks: levelMaze.expandedMazeExit, sceneView: sceneView)
        }
        else {
            addVault(sceneView: sceneView)
        }

        placeLevelComponents(sceneView: sceneView)
        
        // After everything else has been placed into the level, place the holes.  We do this last because holes
        // represent big holes in the level where things can fall through and we don't want to place holes where
        // there  are power ups and parts because then the player wouldn't be able to get them unless he had
        // the hover_unit, which wouldn't be fair.  We don't want to place holes where there are walls or fixed
        // level components because then the player would never be in danger of running over them.  And we don't
        // want to place a hole near the exit as that might make it impossible for the player to exit the level.
        
        if numVisibleHoles + numCamouflagedHoles > 0 {
            placeHoles(sceneView: sceneView, numVisibleHoles: numVisibleHoles, numCamouflagedHoles: numCamouflagedHoles)
        }
    }

    func addLevelExit(exitQuadrant: Int, exitWallBlocks: [MazeElement], sceneView: SCNView) {
        var rows: [Int] = []
        var cols: [Int] = []
        var midpointCol: Int = 0
        
        var exitRotation: SCNVector4 = SCNVector4(0.0, 0.0, 0.0, 0.0)
        var exitLocation: SCNVector3 = SCNVector3(0.0, 0.0, 0.0)
        
        for exitWallBlock in exitWallBlocks {
            rows.append(exitWallBlock.coords.row)
            cols.append(exitWallBlock.coords.column)
        }
        
        var minRow = rows.min()
        let maxCol = cols.max()
        let minCol = cols.min()
        
        midpointCol = (maxCol! + minCol!) / 2
        
        // make sure we don't put the exit inside a left or right wall
        if midpointCol > maxCol! - 2 {
            midpointCol = maxCol! - 2
        }
        else if midpointCol < minCol! + 2 {
            midpointCol = minCol! + 2
        }
        exitRotation = SCNVector4(0.0,1.0, 0.0, Float.pi)   // rotate the exit to face south
        minRow! -= 1    // We had to move the far wall in one row because the calculations were off and the ends of the inner walls
        // were not flush against the far wall like they should have been.  With that adjustment we now also have
        // to move the exit in one row.  Otherwise it disappears inside the far wall.
        levelExitPoint = LevelCoordinates(row: minRow!, column: midpointCol)
        exitLocation = calculateSceneCoordinatesFromLevelRowAndColumn(levelCoords: levelExitPoint)
        exitLocation.z += standardWallBlockLength / 2.0 + levelExitDoorwayDimensions.z / 2.0 // put the exit just slightly inside the far wall.
        // ALWAYS remember that we're going in the -z direction so to
        // put it inside the far wall we have to add to the location, not
        // subtract.
        // if the left wall is too close to the exit (i.e. within a 4.0m fudgefactor), then move it away from the left wall.
        if abs(exitLocation.x - bakeryRoom.walls[bakeryRoom.leftWallName]!.wallNode.position.x) < standardWallBlockWidth / 2.0 + levelExitDoorwayDimensions.x / 2.0 + 4.0 {
            exitLocation.x += 2.0
        }
        else if abs(exitLocation.x - bakeryRoom.walls[bakeryRoom.rightWallName]!.wallNode.position.x) < standardWallBlockWidth / 2.0 + levelExitDoorwayDimensions.x / 2.0 + 4.0 {
            exitLocation.x -= 2.0
        }
        else {
            let innerWallRow = minRow! - 1
            var colBefore: Int = midpointCol - 1
            var colAfter: Int = midpointCol + 1
            
            if colBefore < 0 {
                colBefore = 0
            }
            // we probably shouldn't look at levelGrid directly like this to get the max columns for the levelGrid
            // but oh, well.  This is a special case.
            if colAfter > levelGrid[0].count - 1 {
                colAfter = levelGrid[0].count - 1
            }
            
            // We're going to assume that there's nothing directly in front of the exit so we just have to worry
            // about colBefore and colAfter
            // Note: while there is danger that the exit will be moved to the right and then back to the left, it
            // is highly unlikely.  The exits have always been near to an inner wall either to the left or right, but
            // never both as the distances between inner walls is usually great enough to prevent that.
            for aComponent in levelGrid[innerWallRow][colBefore] {
                let aComponentType = getLevelComponentType2(levelComponentName: aComponent, componentsDictionary: allDurableComponents)
                if aComponentType == .wall {
                    exitLocation.x += 2.0
                }
            }
            for aComponent in levelGrid[innerWallRow][colAfter] {
                let aComponentType = getLevelComponentType2(levelComponentName: aComponent, componentsDictionary: allDurableComponents)
                if aComponentType == .wall {
                    exitLocation.x -= 2.0
                }
            }
        }
        exitLocation.y = levelExitDoorwayDimensions.y / 2.0

        exitLocation.y += 0.5  // fudge a little and raise it up to show the bottom of the exit.
        
        // Add the original exit in as the doorway through which the player has to go.  We then just insert a block
        // inside that doorway for the actual exit.
        levelExitDoorwayNode = allModelsAndMaterials.levelExitModel.clone()
        levelExitDoorwayNode.name = levelExitDoorwayLabel
        levelExitDoorwayNode.position = exitLocation
        levelExitDoorwayNode.rotation = exitRotation

        // create an exit doorframe to put behind the doorway to give the sense of some transition there rather than having the doorway look
        // like it was just stuck on the wall.  That looks cheesy.
        let exitDoorFrameGeometry = SCNBox(width: CGFloat(levelExitDoorwayDimensions.x) + 1.5, height: 6, length: 0.5, chamferRadius: 2.5)
        let exitDoorFrame = SCNNode(geometry: exitDoorFrameGeometry)
        exitDoorFrame.geometry?.firstMaterial?.diffuse.contents = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        exitDoorFrame.position = exitLocation
        exitDoorFrame.position.z -= 0.5
        
        // create the real doorway with two side walls and a top composed of SCNBoxes
        let exitDoorwaySideWallGeometry  = SCNBox(width: 0.23, height: 5.0, length: 2.0, chamferRadius: 0.0)    // determined by looking at the exit model in blender
        let exitDoorwaySideWallLeft = SCNNode(geometry: exitDoorwaySideWallGeometry)
        exitDoorwaySideWallLeft.name = levelExitDoorwayLabel
        exitDoorwaySideWallLeft.geometry?.firstMaterial?.diffuse.contents = UIColor.clear
        exitDoorwaySideWallLeft.position = exitLocation
        exitDoorwaySideWallLeft.position.x -= levelExitDoorwayDimensions.x / 2.0 + 0.115   // 0.23 / 2.0 = 0.115
        exitDoorwaySideWallLeft.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        exitDoorwaySideWallLeft.physicsBody!.categoryBitMask = collisionCategoryLevelExitDoorway
        exitDoorwaySideWallLeft.physicsBody!.contactTestBitMask = collisionCategoryAIRobotBakedGood | collisionCategoryPlayerRobotBakedGood
        exitDoorwaySideWallLeft.physicsBody!.collisionBitMask = collisionCategoryGround | collisionCategoryPlayerRobot | collisionCategoryAIRobot
        let exitDoorwaySideWallRight = SCNNode(geometry: exitDoorwaySideWallGeometry)
        exitDoorwaySideWallRight.name = levelExitDoorwayLabel
        exitDoorwaySideWallRight.geometry?.firstMaterial?.diffuse.contents = UIColor.clear
        exitDoorwaySideWallRight.position = exitLocation
        exitDoorwaySideWallRight.position.x += levelExitDoorwayDimensions.x / 2.0 + 0.115 // 0.23 / 2.0 = 0.115
        exitDoorwaySideWallRight.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        exitDoorwaySideWallRight.physicsBody!.categoryBitMask = collisionCategoryLevelExitDoorway
        exitDoorwaySideWallRight.physicsBody!.contactTestBitMask = collisionCategoryAIRobotBakedGood | collisionCategoryPlayerRobotBakedGood
        exitDoorwaySideWallRight.physicsBody!.collisionBitMask = collisionCategoryGround | collisionCategoryPlayerRobot | collisionCategoryAIRobot

        let exitDoorwayTopGeometry  = SCNBox(width: CGFloat(levelExitDoorwayDimensions.x), height: 0.5, length: 2.0, chamferRadius: 0.0)
        let exitDoorwayTop = SCNNode(geometry: exitDoorwayTopGeometry)
        exitDoorwayTop.name = levelExitDoorwayLabel
        exitDoorwayTop.geometry?.firstMaterial?.diffuse.contents = UIColor.clear
        exitDoorwayTop.position = exitLocation
        exitDoorwayTop.position.y += levelExitDoorwayDimensions.y / 2.0 - 0.25
        exitDoorwayTop.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        exitDoorwayTop.physicsBody!.categoryBitMask = collisionCategoryLevelExitDoorway
        exitDoorwayTop.physicsBody!.contactTestBitMask = collisionCategoryAIRobotBakedGood | collisionCategoryPlayerRobotBakedGood
        exitDoorwayTop.physicsBody!.collisionBitMask = collisionCategoryGround | collisionCategoryPlayerRobot | collisionCategoryAIRobot
        
        // Given the rotation and location of the exit, now add the exit to the scene
        let levelExitGeometry = SCNBox(width: CGFloat(levelExitDimensions.x), height: CGFloat(levelExitDimensions.y), length: CGFloat(levelExitDimensions.z), chamferRadius: 0.0)
        levelExitNode = SCNNode(geometry: levelExitGeometry)
        
        levelExitNode.name = levelExitLabel
        levelExitNode.position = exitLocation
        levelExitNode.rotation = exitRotation
        // offset the exit to move it in front of the far wall.  Since the far wall z location is the center of
        // that wall we move the location +1/2 the thickness of that wall +1/2 the thickness of the exit since the exit's
        // location is the center of that level component.
        // set the color to yellow to match what the player sees in the map.
        levelExitNode.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
        levelExitNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        levelExitNode.physicsBody!.categoryBitMask = collisionCategoryLevelExit
        levelExitNode.physicsBody!.contactTestBitMask = collisionCategoryPlayerRobot // Just the player's robot here.  We don't care if the ai robots make contact.
        levelExitNode.physicsBody!.collisionBitMask = collisionCategoryGround
        
        sceneView.scene?.rootNode.addChildNode(exitDoorFrame)
        sceneView.scene?.rootNode.addChildNode(exitDoorwaySideWallLeft)
        sceneView.scene?.rootNode.addChildNode(exitDoorwaySideWallRight)
        sceneView.scene?.rootNode.addChildNode(exitDoorwayTop)
        sceneView.scene?.rootNode.addChildNode(levelExitDoorwayNode)
        sceneView.scene?.rootNode.addChildNode(levelExitNode)
        allDurableComponents[levelExitDoorwayNode.name!] = .levelexitdoorway
        allDurableComponents[levelExitNode.name!] = .levelexit    // important.  add to all components for quick reference for type later.

    }
    
    // add the level entrance for show but don't allow the player to go through it.  Thus, we add the player robot to the collision mask but
    // not the contactTestBitMask.  Note: the entrance is actually a little lower than the exit because we didn't make any adjustments for the
    // model's original y location like we did with the exit.  But it doesn't matter, and in fact looks fine.  The adjustment was made to move
    // the bottom of the model up so that the player could see the exit floor and see the shadow cast by a distant light.  That's covered by
    // the top of the entrance from the player's view angle so that doesn't matter for the entrance.
    func addLevelEntrance (sceneView: SCNView, playerLoc: SCNVector3) {
        var entranceLocation = playerLoc
        entranceLocation.z += 6.0      // move the entrance such that it is behind the player.
        let entranceRotation = SCNVector4(0.0, 0.0, 0.0, 0.0)   // default rotation - for now the level exit model, which we're also using for the entrance, is rotated the
                                                                // right way by default.
        levelEntranceNode = allModelsAndMaterials.levelExitModel.clone()
        levelEntranceNode.name = levelEntranceLabel
        levelEntranceNode.position = entranceLocation
        levelEntranceNode.rotation = entranceRotation
        levelEntranceNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        levelEntranceNode.physicsBody!.categoryBitMask = collisionCategoryLevelEntrance
        levelEntranceNode.physicsBody!.collisionBitMask = collisionCategoryGround | collisionCategoryPlayerRobot | collisionCategoryAIRobot | collisionCategoryAIRobotBakedGood | collisionCategoryPlayerRobotBakedGood
        sceneView.scene?.rootNode.addChildNode(levelEntranceNode)
        allDurableComponents[levelEntranceNode.name!] = .levelentrance    // important.  add to all components for quick reference for type later.
    }
    
    // The player has reached the last level of the game.  Instead of adding an
    // exit, we add a Vault.  The player has to get all the parts of an electronic
    // key to open the vault and then get to it to open it, just like going to a level exit.
    // Also, place an invisible barrier in front of the vault that prevents the player from
    // entering the vault unless all the key parts have been obtained.  Once that happens
    // then we would remove the bitmask that marks a collision.
    func addVault(sceneView: SCNView) {
        // Given the rotation and location of the exit, now add the exit to the scene
        let vaultGeometry = SCNBox(width: CGFloat(vaultDimensions.x), height: CGFloat(vaultDimensions.y), length: CGFloat(vaultDimensions.z), chamferRadius: 0.1)
        // make barrier in front of vault a very thin layer of the same y dimensions as the vault.  The x dimesion is a slightly larger
        // to prevent accident exit from the side when.
        let vaultBarrierGeometry = SCNBox(width: CGFloat(vaultBarrierDimensions.x), height: CGFloat(vaultBarrierDimensions.y), length: CGFloat(vaultBarrierDimensions.z), chamferRadius: 0.0)
        
        let farWall = bakeryRoom.walls[bakeryRoom.farWallName]!
        
        vaultNode = SCNNode(geometry: vaultGeometry)
        vaultNode.name = vaultLabel
        // The vault is at the center of the far wall, with the vault behind it.  So it's x,z position is the same as the wall's except that it's in
        // just a little bit to make it visible.  If the position were exactly the same then vault would be embedded in the wall and
        // the player would never see it.  Hmmmm...that could be a puzzle that we could add at a later time in an update.
        
        vaultNode.position.x = farWall.wallNode.position.x
        vaultNode.position.y = vaultDimensions.y / 2.0
        vaultNode.position.z = farWall.wallNode.position.z + 0.5 * vaultDimensions.z  + Float(0.5 * farWall.length)
        vaultNode.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
        vaultNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        vaultNode.physicsBody!.categoryBitMask = collisionCategoryVault
        vaultNode.physicsBody!.contactTestBitMask = collisionCategoryPlayerRobot // Just the player's robot here.  We don't care if the ai robots make contact.
        vaultNode.physicsBody!.collisionBitMask = collisionCategoryGround
        
        vaultDoorwayNode = allModelsAndMaterials.vaultModel.clone()
        vaultDoorwayNode.name = vaultDoorwayLabel
        vaultDoorwayNode.position = vaultNode.position
        vaultDoorwayNode.position.y += 1.5
        vaultDoorwayNode.position.z += 1.0
        vaultDoorwayNode.rotation = SCNVector4(0.0,1.0, 0.0, Float.pi)   // rotate vault doorway to face south.
        
        // create the real doorway with two side walls and a top composed of SCNBoxes
        let vaultDoorwaySideWallGeometry  = SCNBox(width: 0.78, height: 6.46, length: 4.15, chamferRadius: 0.0)    // determined by looking at the vault model in blender
        let vaultDoorwaySideWallLeft = SCNNode(geometry: vaultDoorwaySideWallGeometry)
        vaultDoorwaySideWallLeft.name = vaultDoorwayLabel
        vaultDoorwaySideWallLeft.geometry?.firstMaterial?.diffuse.contents = UIColor.clear
        vaultDoorwaySideWallLeft.position = vaultNode.position
        vaultDoorwaySideWallLeft.position.x -= vaultDoorwayDimensions.x / 2.0    // 0.78 / 2.0
        vaultDoorwaySideWallLeft.position.y += 1.5
        vaultDoorwaySideWallLeft.position.z += 1.15
        vaultDoorwaySideWallLeft.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        vaultDoorwaySideWallLeft.physicsBody!.categoryBitMask = collisionCategoryVaultDoorway
        vaultDoorwaySideWallLeft.physicsBody!.contactTestBitMask = collisionCategoryAIRobotBakedGood | collisionCategoryPlayerRobotBakedGood
        vaultDoorwaySideWallLeft.physicsBody!.collisionBitMask = collisionCategoryGround | collisionCategoryPlayerRobot | collisionCategoryAIRobot
        
        let vaultDoorwaySideWallRight = SCNNode(geometry: vaultDoorwaySideWallGeometry)
        vaultDoorwaySideWallRight.name = levelExitDoorwayLabel
        vaultDoorwaySideWallRight.geometry?.firstMaterial?.diffuse.contents = UIColor.clear
        vaultDoorwaySideWallRight.position = vaultNode.position
        vaultDoorwaySideWallRight.position.x += vaultDoorwayDimensions.x / 2.0  // 0.78 / 2.0
        vaultDoorwaySideWallRight.position.y += 1.5
        vaultDoorwaySideWallRight.position.z += 1.15
        vaultDoorwaySideWallRight.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        vaultDoorwaySideWallRight.physicsBody!.categoryBitMask = collisionCategoryVaultDoorway
        vaultDoorwaySideWallRight.physicsBody!.contactTestBitMask = collisionCategoryAIRobotBakedGood | collisionCategoryPlayerRobotBakedGood
        vaultDoorwaySideWallRight.physicsBody!.collisionBitMask = collisionCategoryGround | collisionCategoryPlayerRobot | collisionCategoryAIRobot
        
        let vaultDoorwayTopGeometry  = SCNBox(width: CGFloat(vaultDoorwayDimensions.x), height: 1.0, length: 4.15, chamferRadius: 0.0)
        let vaultDoorwayTop = SCNNode(geometry: vaultDoorwayTopGeometry)
        vaultDoorwayTop.name = vaultDoorwayLabel
        vaultDoorwayTop.geometry?.firstMaterial?.diffuse.contents = UIColor.clear
        vaultDoorwayTop.position = vaultNode.position
        vaultDoorwayTop.position.y += vaultDoorwayDimensions.y / 2.0 - 0.30
        vaultDoorwayTop.position.z += 1.15
        vaultDoorwayTop.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        vaultDoorwayTop.physicsBody!.categoryBitMask = collisionCategoryVaultDoorway
        vaultDoorwayTop.physicsBody!.contactTestBitMask = collisionCategoryAIRobotBakedGood | collisionCategoryPlayerRobotBakedGood
        vaultDoorwayTop.physicsBody!.collisionBitMask = collisionCategoryGround | collisionCategoryPlayerRobot | collisionCategoryAIRobot

        vaultBarrierNode = SCNNode(geometry: vaultBarrierGeometry)
        vaultBarrierNode.name = vaultBarrierLabel
        vaultBarrierNode.position = vaultNode.position
        vaultBarrierNode.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        vaultBarrierNode.geometry?.firstMaterial?.transparency = 0.20
        vaultBarrierNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        vaultBarrierNode.physicsBody!.categoryBitMask = collisionCategoryVaultBarrier
        // Make sure the player collides with the barrier rather than going through it.  If we used contactTestBitMask
        // then it would just go through the barrier.  We want collision to keep the player's robot from going through
        // to the vault until the key parts have all been gathered.  However, we also set the contactTestBitMask so we
        // are notified when the robot comes in contact with the barrier so we can change the color of the force field.
        vaultBarrierNode.physicsBody!.contactTestBitMask = collisionCategoryPlayerRobot
        vaultBarrierNode.physicsBody!.collisionBitMask = collisionCategoryGround | collisionCategoryPlayerRobot

        // add to scene and our allDurableComponents list for quick reference later.
        sceneView.scene?.rootNode.addChildNode(vaultDoorwaySideWallLeft)
        sceneView.scene?.rootNode.addChildNode(vaultDoorwaySideWallRight)
        sceneView.scene?.rootNode.addChildNode(vaultDoorwayTop)
        sceneView.scene?.rootNode.addChildNode(vaultNode)
        sceneView.scene?.rootNode.addChildNode(vaultDoorwayNode)
        sceneView.scene?.rootNode.addChildNode(vaultBarrierNode)
        allDurableComponents[vaultNode.name!] = .vault
        allDurableComponents[vaultBarrierNode.name!] = .vaultbarrier
    }
    
    // place level components in the level using the maze as a map for placing them.
    func placeLevelComponents (sceneView: SCNView) {
        let fixedComponentsList = [LevelComponentType.table, LevelComponentType.refrigerator, LevelComponentType.rack, LevelComponentType.conveyor, LevelComponentType.mixer, LevelComponentType.oven, LevelComponentType.deepfryer]
        
        // Make sure we don't go over the limit.
        if numLevelComponentTypes > fixedComponentsList.count {
            numLevelComponentTypes = fixedComponentsList.count
        }
        
        for aRow in 0...levelMaze.theMazeExpanded.count - 1 {
            for aCol in 0...levelMaze.theMazeExpanded[aRow].count - 1 {
                let coords = calculateSceneCoordinatesFromLevelRowAndColumn(levelCoords: LevelCoordinates(row: aRow, column: aCol))
                switch levelMaze.theMazeExpanded[aRow][aCol].type {
                case .fixedLevelComponent:
                    let levelComponentType = fixedComponentsList[randomNumGenerator.xorshift_randomgen() % numLevelComponentTypes]
                    let fixedComponent = FixedLevelComponent(type: levelComponentType, location: coords, levelLocation: LevelCoordinates(row: aRow, column: aCol))
                    sceneView.scene?.rootNode.addChildNode(fixedComponent.componentNode)
                    levelComponentsList[fixedComponent.componentNode.name!] = fixedComponent
                    levelGrid[aRow][aCol] = [fixedComponent.componentNode.name!]
                    // allDurableComponents gives us quick reference from name to type so we don't have to determine that with string searches.
                    allDurableComponents[fixedComponent.componentNode.name!] = levelComponentType
                    break
                default:
                    break
                }
            }
        }
    }
    
    // Here we place the powerups in one of numRegions in the level.  The regions
    // are actually long and thing and placed end-to-end to make it easier to traverse.
    // We looked into creating regions composed of 4x4 blocks but it became cumbersome
    // because we would have to take the Empty spaces list, which was linear, and
    // create virtual 4x4 areas with them.  It was a lot easier to leave the empty spaces
    // list as one long list that we break up into a number of regions.
    func placePowerUps(sceneView: SCNView, numPowerUps: Int) -> [String : PowerUp] {
        var powerUps: [String : PowerUp] = [ : ]
        var powerUpCount: Int = 0
        let emptySpacesForPowerUps: EmptySpacesList = emptySpacesList
        
        for aPowerUp in 1...numPowerUps * 2 {
            // choose region in which to place power up
            let region = aPowerUp % emptySpacesForPowerUps.numRegions
            var emptySpace: MazeElement!
            var emptySpaceIndexInRegion: Int = 0
            var powerUpLoc: LevelCoordinates = LevelCoordinates()
            
            // get just the one region of the level we're interested in, particularly all the empty spaces.
            emptySpaceIndexInRegion = randomNumGenerator.xorshift_randomgen() % emptySpacesForPowerUps.regionSize
            emptySpace = emptySpacesForPowerUps.emptySpaces[region * emptySpacesForPowerUps.regionSize + emptySpaceIndexInRegion]
            var numTries: Int = 0
            // look for either empty space that has .Space or .Robot in it.  The .PowerUp can coexist with
            // either of these in the same space.  This also means we can place the robots before the powerups if
            // we want to.
            while emptySpace.type != .space  && emptySpace.type != .robot && numTries < 3 {
                emptySpaceIndexInRegion = randomNumGenerator.xorshift_randomgen() % emptySpacesForPowerUps.regionSize
                emptySpace = emptySpacesForPowerUps.emptySpaces[region * emptySpacesForPowerUps.regionSize + emptySpaceIndexInRegion]
                numTries += 1
            }
            // convert empty space to level coordinates and screen coordinates and place part or powerup in levelGrid and scene.
            // Note: unlike the robots we don't care if the part or powerup is close to the player because it poses no danger
            // to the player, and actually helps.  We're not likely to overdo it because the algorithm moves on
            // immediately to the next region once it has placed a part in one.  And it doesn't come back to that
            // region until it has gone through all the others.
            powerUpLoc.row = (emptySpace?.coords.row)!
            powerUpLoc.column = (emptySpace?.coords.column)!
            // choose the type of part or powerup
            var powerUp: PowerUp!
            // We alternate between placing parts and power ups in regions.  We make the code alternate between them by first multiplying
            // the number of parts by 2 and then using % 2 == 1 to decide on whether or not to place a power up.  Thist forces a placement
            // ever _other_ region.  We do the same thing with parts but in that case it is % 2 == 0.
            if aPowerUp % 2 == 1 {
                var powerUpNameIndex: Int!
                powerUpNameIndex = randomNumGenerator.xorshift_randomgen() % powerUpNames.count
                powerUp = makePowerUpASceneNode(powerUpLoc: powerUpLoc, powerUpNum: powerUpCount, powerUpName: powerUpNames[powerUpNameIndex])
                powerUps[powerUpLabel + String(powerUpCount)] = powerUp
                
                // place part or power up in level grid
                levelGrid[powerUp.levelCoords.row][powerUp.levelCoords.column].append(powerUp.powerUpNode.name!)
                
                // place part or powerup in scene and in allDurableComponents list for quick reference.
                sceneView.scene?.rootNode.addChildNode((powerUps[powerUpLabel + String(powerUpCount)]?.powerUpNode)!)
                allDurableComponents[powerUp.powerUpNode.name!] = .powerup
                
                // Mark the empty space in empty spaces list has having been assigned a powerup so we don't
                // try to assign another one to it.
                emptySpacesForPowerUps.emptySpaces[region * emptySpacesForPowerUps.regionSize + emptySpaceIndexInRegion].type = .powerUp
                powerUpCount += 1
            }
        }
        return powerUps
    }
    
    // Here we place the parts in one of numRegions in the level.  The regions
    // are actually long and thing and placed end-to-end to make it easier to traverse.
    // We looked into creating regions composed of 4x4 blocks but it became cumbersome
    // because we would have to take the Empty spaces list, which was linear, and
    // create virtual 4x4 areas with them.  It was a lot easier to leave the empty spaces
    // list as one long list that we break up into a number of regions.
    func placeParts(sceneView: SCNView, partStartNum: Int, partEndNum: Int, partsList: [Int : Part]) -> [String : PartInLevel] {
        var parts: [String : PartInLevel] = [ : ]
        var partCount: Int = partStartNum
        let emptySpacesForParts: EmptySpacesList = emptySpacesList
        
        // Note: we multiple by 2 because we're adding parts to every _other_ region.  We do this because
        // we play to put a power up in the region between every two parts regions.
        let numParts = (partEndNum - partStartNum + 1) * 2
        for aPart in 0...numParts - 1 {
            
            // choose region in which to place price.
            let region = aPart % emptySpacesForParts.numRegions
            var emptySpace: MazeElement!
            var emptySpaceIndexInRegion: Int = 0
            var partLoc: LevelCoordinates = LevelCoordinates()
            
            // get just the one region of the level we're interested in, particularly all the empty spaces.
            emptySpaceIndexInRegion = randomNumGenerator.xorshift_randomgen() % emptySpacesForParts.regionSize
            emptySpace = emptySpacesForParts.emptySpaces[region * emptySpacesForParts.regionSize + emptySpaceIndexInRegion]
            var numTries: Int = 0
            // look for either empty space that has .Space or .robot in it.  The .Part can coexist with
            // either of these in the same space.  This also means we can place the robots before the parts or powerups if
            // we want to.
            while emptySpace.type != .space  && emptySpace.type != .robot && numTries < 3 {
                emptySpaceIndexInRegion = randomNumGenerator.xorshift_randomgen() % emptySpacesForParts.regionSize
                emptySpace = emptySpacesForParts.emptySpaces[region * emptySpacesForParts.regionSize + emptySpaceIndexInRegion]
                numTries += 1
            }
            
            // convert empty space to level coordinates and screen coordinates and place part in levelGrid and scene.
            // Note: unlike the robots we don't care if the part is close to the player because it poses no danger
            // to the player, and actually helps.  We're not likely to overdo it because the algorithm moves on
            // immediately to the next region once it has placed a part in one.  And it doesn't come back to that
            // region until it has gone through all the others.
            partLoc.row = (emptySpace?.coords.row)!
            partLoc.column = (emptySpace?.coords.column)!
            // We alternate between placing parts and power ups in regions.  We make the code alternate between them by first multiplying
            // the number of parts by 2 and then using % 2 == 0 to decide on whether or not to place a part.  Thist forces a placement
            // ever _other_ region.  We do the same thing with powerups but in that case it is % 2 == 1.
            var part: PartInLevel!
            if aPart % 2 == 0 && partCount <= partEndNum {
                
                // Only place a part if it hasn't already been picked up, which can happen if the player is going through
                // the level again because he missed something.
                if partsList[partCount]?.retrieved == false {
                    // assign part and then update count.
                    part = makePartASceneNode(partLoc: partLoc, partNum: partCount)
                    parts[partLabel + String(partCount)] = part
                    // place part in level grid
                    levelGrid[part.levelCoords.row][part.levelCoords.column].append(part.partNode.name!)
                    
                    // place part in scene and in allDurableComponents list for quick reference
                    sceneView.scene?.rootNode.addChildNode((parts[partLabel + String(partCount)]?.partNode)!)
                    allDurableComponents[part.partNode.name!] = .part
                    
                    // Mark the empty space in empty spaces list has having been assigned a part or powerup so we don't
                    // try to assign another one to it.
                    emptySpacesForParts.emptySpaces[region * emptySpacesForParts.regionSize + emptySpaceIndexInRegion].type = .part
                }
                partCount += 1
            }
        }
        return parts
    }
 
    // Here we place the key parts in the level.  The regions
    // are actually long and thing and placed end-to-end to make it easier to traverse.
    // We looked into creating regions composed of 4x4 blocks but it became cumbersome
    // because we would have to take the Empty spaces list, which was linear, and
    // create virtual 4x4 areas with them.  It was a lot easier to leave the empty spaces
    // list as one long list that we break up into a number of regions.
    // Unlike the regular parts we don't keep track of the key parts between levels because
    // they are only relevant to the last level.  In that case we just need to keep track of
    // whether or not all of the key parts have been obtained.
    func placeKeyParts(sceneView: SCNView, numKeyParts: Int) -> [String : PartInLevel] {
        var parts: [String : PartInLevel] = [ : ]
        var partCount: Int = 0
        let emptySpacesForParts: EmptySpacesList = emptySpacesList
        
        // Note: we go from 0 - 2*numKeyParts - 1 because we're starting off with placing
        // parts, then we alternate between placing parts and placing powerups.  This spreads
        // them out and keeps them from bunching up together.
        for aPart in 0...numKeyParts * 2 - 1 {
            
            // choose region in which to place price.
            let region = aPart % emptySpacesForParts.numRegions
            var emptySpace: MazeElement!
            var emptySpaceIndexInRegion: Int = 0
            var partLoc: LevelCoordinates = LevelCoordinates()
            
            // get just the one region of the level we're interested in, particularly all the empty spaces.
            emptySpaceIndexInRegion = randomNumGenerator.xorshift_randomgen() % emptySpacesForParts.regionSize
            emptySpace = emptySpacesForParts.emptySpaces[region * emptySpacesForParts.regionSize + emptySpaceIndexInRegion]
            var numTries: Int = 0
            // look for either empty space that has .Space or .robot in it.  The .Part can coexist with
            // either of these in the same space.  This also means we can place the robots before the parts or powerups if
            // we want to.
            while emptySpace.type != .space  && emptySpace.type != .robot && numTries < 3 {
                emptySpaceIndexInRegion = randomNumGenerator.xorshift_randomgen() % emptySpacesForParts.regionSize
                emptySpace = emptySpacesForParts.emptySpaces[region * emptySpacesForParts.regionSize + emptySpaceIndexInRegion]
                numTries += 1
            }
            
            // convert empty space to level coordinates and screen coordinates and place part in levelGrid and scene.
            // Note: unlike the robots we don't care if the part is close to the player because it poses no danger
            // to the player, and actually helps.  We're not likely to overdo it because the algorithm moves on
            // immediately to the next region once it has placed a part in one.  And it doesn't come back to that
            // region until it has gone through all the others.
            partLoc.row = (emptySpace?.coords.row)!
            partLoc.column = (emptySpace?.coords.column)!
            // We alternate between placing parts and power ups in regions.  We make the code alternate between them by first multiplying
            // the number of parts by 2 and then using % 2 == 0 to decide on whether or not to place a part.  Thist forces a placement
            // ever _other_ region.  We do the same thing with powerups but in that case it is % 2 == 1.
            var part: PartInLevel!
            if aPart % 2 == 0 {
                
                // assign part and then update count.
                part = makePartASceneNode(partLoc: partLoc, partNum: partCount)
                parts[partLabel + String(partCount)] = part
                // place part in level grid
                levelGrid[part.levelCoords.row][part.levelCoords.column].append(part.partNode.name!)
                    
                // place part in scene and in allDurableComponents list for quick reference
                sceneView.scene?.rootNode.addChildNode((parts[partLabel + String(partCount)]?.partNode)!)
                allDurableComponents[part.partNode.name!] = .part
                    
                // Mark the empty space in empty spaces list has having been assigned a part or powerup so we don't
                // try to assign another one to it.
                emptySpacesForParts.emptySpaces[region * emptySpacesForParts.regionSize + emptySpaceIndexInRegion].type = .part
                partCount += 1
            }
        }
        return parts
    }

    func makePartASceneNode(partLoc: LevelCoordinates, partNum: Int) -> PartInLevel {
        var prizeListElement: PrizeListElement!
                
        if levelNumber == highestLevelNumber {
            prizeListElement = keyPrize
        }
        else {
            prizeListElement = getPrizeElement(partNum: partNum)
        }
        
        let part = PartInLevel(partNum: partNum, levelNum: levelNumber, type: prizeListElement.partType, location: partLoc)
        return part
    }
    
    func makePowerUpASceneNode(powerUpLoc: LevelCoordinates, powerUpNum: Int, powerUpName: String) -> PowerUp {
        let powerUpListElement = powerUpList[powerUpName]
        
        let powerUp = PowerUp(powerUpNum: powerUpNum, type: (powerUpListElement?.powerUpType)!, name: powerUpName, location: powerUpLoc, levelNum: levelNumber, randomGen: randomNumGenerator)
        return powerUp
    }

    // Here we place the robots in one of numRegions in the level.  The regions
    // are actually long and thing and placed end-to-end to make it easier to traverse.
    // We looked into creating regions composed of 4x4 blocks but it became cumbersome
    // because we would have to take the Empty spaces list, which was linear, and
    // create virtual 4x4 areas with them.  It was a lot easier to leave the empty spaces 
    // list as one long list that we break up into a number of regions.
    func placeRobots(sceneView: SCNView, playerRobot: Robot, ammoChoices: [String], pInventory: Inventory) -> [String : Robot] {
        var robots: [String : Robot] = [ : ]
        let emptySpacesForRobots: EmptySpacesList = emptySpacesList
        
        let numWorkersPlusBakers = levelChallenges.workers + levelChallenges.bakers + levelChallenges.doublebakers
        let numZappersPlusSupers = levelChallenges.zappers + levelChallenges.superworkers + levelChallenges.superbakers
        let numHomersPlusPastryChefs = levelChallenges.homing + levelChallenges.ghosts + levelChallenges.pastrychefs
        let numRobotsInLevel = numWorkersPlusBakers + numZappersPlusSupers + numHomersPlusPastryChefs
        
        let robotNumMinusPastryChefs = numWorkersPlusBakers + numZappersPlusSupers + levelChallenges.homing + levelChallenges.ghosts - 1
        
        var robotNumber: Int = 0
        var minRowsAwayFromPlayer: Int = minimumRowsAwayFromPlayer
        
        while robotNumber <= numRobotsInLevel - 1 {
            var region = robotNumber % emptySpacesForRobots.numRegions
            var emptySpace: MazeElement!
            var emptySpaceIndexInRegion: Int = 0
            var robotLoc: LevelCoordinates = LevelCoordinates()
            var numTries: Int = 0
            
            // This is a little redundant as we would keep updating the min rows and min cols away from player for each
            // robot but that's not a big deal.  If we were creating thousands or hundreds of thousands then
            // we would need to revise this but with only five or so created, I think we can live with a tiny bit of
            // inefficiency.
            if levelNumber <= highestLearningLevel {
                minRowsAwayFromPlayer = learningLevelsMinimumRowsAwayFromPlayer
            }
            else if levelNumber == highestLevelNumber && robotNumber > robotNumMinusPastryChefs {
                minRowsAwayFromPlayer = minimumRowsAwayFromPlayerForPastryChefs
            }
            else {
                minRowsAwayFromPlayer = minimumRowsAwayFromPlayer
            }
            repeat {
                // get just the one region of the level we're interested in, particularly all the empty spaces.
                emptySpaceIndexInRegion = randomNumGenerator.xorshift_randomgen() % emptySpacesForRobots.regionSize
                emptySpace = emptySpacesForRobots.emptySpaces[region * emptySpacesForRobots.regionSize + emptySpaceIndexInRegion]
                var numInRegionTries: Int = 0
                // look for either empty space that has .Space or .Part or .PowerUp in it.  The .Robot can coexist with
                // either of these in the same space.  This also means we can place the parts and powerups before the robots if
                // we want to.
                while emptySpace.type != .space  && emptySpace.type != .powerUp && emptySpace.type != .part && numInRegionTries < 3 {
                    emptySpaceIndexInRegion = randomNumGenerator.xorshift_randomgen() % emptySpacesForRobots.regionSize
                    emptySpace = emptySpacesForRobots.emptySpaces[region * emptySpacesForRobots.regionSize + emptySpaceIndexInRegion]
                    numInRegionTries += 1
                }
                
                // convert empty space to level coordinates and screen coordinates and place robot in levelGrid and scene.
                robotLoc.row = (emptySpace?.coords.row)!
                robotLoc.column = (emptySpace?.coords.column)!
                
                if robotLoc.row < minRowsAwayFromPlayer {
                    // select a region farther away since the robot might be placed too close to the player.
                    region = (region + 5) % emptySpacesForRobots.numRegions
                }
                numTries += 1
                // keep trying to place robot far enough away from player to give the player a chance, but cap that to a limit of 10.
            } while robotLoc.row < minRowsAwayFromPlayer  && numTries < 10

            //if numTries >= 10 {
            //    print ("Could not place ai robot \(robotNumber) within \(numTries)")
            //}
            // TEMPORARY.  We use the if statement to just place robots of a certain type in the level.  Unfortunately, because
            // we're basing this on the number of robots placed, a number of levels will be empty if we're trying to test more
            // challenging robots.  They won't appear until the number of robots gets large.
            //if getRobotType(robotNum: robotNumber, levelChallenges: levelChallenges) == .worker {
            let robot = makeRobotASceneNode(robotLoc: robotLoc, robotNum: robotNumber, ammoChoices: ammoChoices, pInventory: pInventory)
            // place robot in level grid
            levelGrid[robot.levelCoords.row][robot.levelCoords.column].append(robot.robotNode.name!)
            
            sceneView.scene?.rootNode.addChildNode(robot.robotNode)

            // add to our robots array to make sure we're able to keep track of it.
            robots[aiRobotLabel + String(robotNumber)] = robot

            // place robot in scene and in allDurableComponents list for quick reference
            allDurableComponents[robot.robotNode.name!] = .airobot
            // place robot label in scene if it exists - for debugging purposes
            /*
            if robots[AIRobotLabel + String(robotNumber)]?.robotLabelNode != nil {
                robots[AIRobotLabel + String(robotNumber)]?.robotLabelNode.position = (robots[AIRobotLabel + String(robotNumber)]?.robotNode)!.position
                robots[AIRobotLabel + String(robotNumber)]?.robotLabelNode.position.y = (robots[AIRobotLabel + String(robotNumber)]?.robotNode)!.boundingBox.max.y + 2.0
                sceneView.scene?.rootNode.addChildNode((robots[AIRobotLabel + String(robotNumber)]?.robotLabelNode)!)
            }
            */
            // Mark the empty space in empty spaces list has having been assigned a robot so we don't
            // try to assign another robot to it.
            emptySpacesForRobots.emptySpaces[region * emptySpacesForRobots.regionSize + emptySpaceIndexInRegion].type = .robot
            //}
            robotNumber += 1        
        }
        return robots
    }

    func makeRobotASceneNode(robotLoc: LevelCoordinates, robotNum: Int, ammoChoices: [String], pInventory: Inventory) -> Robot {
        let robotSceneCoords = calculateSceneCoordinatesFromLevelRowAndColumn(levelCoords: robotLoc)
        let botType = getRobotType(robotNum: robotNum, levelChallenges: levelChallenges)
        
        let robot = Robot(robotNum: robotNum, playertype: .ai, robottype: botType, location: robotSceneCoords, robotLevelLoc: robotLoc, ammoChoices: ammoChoices, pInventory: pInventory, randomGen: randomNumGenerator, zapperEnabled: false, secondLauncherEnabled: false, bunsenBurnerEnabled: false)
                        // note: zapperEnabled, secondLauncherEnabled and bunsenBurnerEnabled are only for the player robot.
        
        // Make sure to change the withinReachDistance if the robot is homing or ghost because we vary that
        // based on how high a level the player has reached.  For the first few levels that value is high but
        // later it is lower to get those robots to get closer before setting off their EMP.
        if botType == .homing || botType == .ghost {
            robot.updateWithinReachDistance(withinReachDistance: levelChallenges.withinRangeDistance)
        }
        return robot
    }
    
    // Check the area surrounding coordinates to see if there are any fixed level components
    // nearby.  This is particularly useful for placing holes because we don't want to
    // put holes flush against a fixed object--that reduces their effectiveness.
    func isWallOrFixedLevelComponentNearby(coords: LevelCoordinates) -> Bool {
        var fixedObjectNearby: Bool = false
        
        // Note: we limit it to just 1 around the coordinate.  Any more than that and we risk 
        // always saying a wall or fixed level component is always close by and that could result
        // in no holes being placed, which will crash the game.
        var firstRow: Int = coords.row - 1
        var lastRow: Int = coords.row + 1
        var firstCol: Int = coords.column - 1
        var lastCol: Int = coords.column + 1
        
        if firstRow < 0 {
            firstRow = 0
        }
        if firstCol < 0 {
            firstCol = 0
        }
        if lastRow > levelGrid.count - 1 {
            lastRow = levelGrid.count - 1
        }
        if lastCol > levelGrid[0].count - 1 {
            lastCol = levelGrid[0].count - 1
        }
        
        for row in firstRow...lastRow {
            for col in firstCol...lastCol {
                for anElement in levelGrid[row][col] {
                    let componentType = getLevelComponentType2(levelComponentName: anElement, componentsDictionary: allDurableComponents)
                    if isLevelComponentTypeFixed(levelComponentType: componentType) {
                        fixedObjectNearby = true
                    }
                }
            }
        }
        
        return fixedObjectNearby
    }
    
    // Check the area surrounding coordinates to see if there are any fixed level components
    // nearby, but use theExpandedMaze, not the levelGrid.  This is faster because we're dealing
    // with enum values instead of strings..  This is particularly useful for placing holes because
    // we don't want to put holes flush against a fixed object--that reduces their effectiveness.
    // Note: from comments in the Maze class we try hard to make sure that he levelGrid and
    // theExpandedMaze match in row,column coordinates.  Otherwise our game breaks down.  So
    // we should be safe to use theExpandedMaze for this.
    func isWallOrFixedLevelComponentNearby2(coords: LevelCoordinates) -> Bool {
        var fixedObjectNearby: Bool = false
        
        // Note: we limit it to just 1 around the coordinate.  Any more than that and we risk
        // always saying a wall or fixed level component is always close by and that could result
        // in no holes being placed, which will crash the game.
        var firstRow: Int = coords.row - 1
        var lastRow: Int = coords.row + 1
        var firstCol: Int = coords.column - 1
        var lastCol: Int = coords.column + 1
        
        if firstRow < 0 {
            firstRow = 0
        }
        if firstCol < 0 {
            firstCol = 0
        }
        if lastRow > levelGrid.count - 1 {
            lastRow = levelGrid.count - 1
        }
        if lastCol > levelGrid[0].count - 1 {
            lastCol = levelGrid[0].count - 1
        }
        
        for row in firstRow...lastRow {
            for col in firstCol...lastCol {
                if levelMaze.theMazeExpanded[row][col].type != .space && levelMaze.theMazeExpanded[row][col].type != .robot && levelMaze.theMazeExpanded[row][col].type != .part && levelMaze.theMazeExpanded[row][col].type != .powerUp {
                    fixedObjectNearby = true
                }
            }
        }
        
        return fixedObjectNearby
    }

    // Place holes, except where:
    // a) the exit is and in front of it - this could make it impossible for the player to finish the level
    // b) where the player starts - can't have the player immediately falling into the hole before getting going
    // c) fixed level components are - player will never be in danger of going over the hole
    // d) walls are - player will never be in danger of going over the hole
    // e) power ups are - player may not be able to pick up power up
    // f) parts are - player may not be able to pick up part
    // g) there are other holes - just overlapping what's already there, degrading performance, nothing more, and
    // also may expose a camouflaged hole by placing a non-camouflaged hole on top of it.
    //
    func placeHoles (sceneView: SCNView, numVisibleHoles: Int, numCamouflagedHoles: Int) {
        let potentialSpacesForHoles: EmptySpacesList = emptySpacesList
        var spacesForHoles: [MazeElement] = []
        var visibleHoleLocations: [MazeElement] = []
        var camouflagedHoleLocations: [MazeElement] = []
        let minRowForHoles = playerStartingPoint.row + minRowDistanceAwayFromEntranceForHoles
        
        // 1) get all the spaces where we can place holes by eliminating the ones where we can't.
        // We consider both empty spaces and spaces with ai robots as candidates for placing holes as
        // the ai robots will have hover units that prevent them from falling into the holes.  Also,
        // we always use spaces that start at a minimum row distance away from entrance to avoid accidentally 
        // assigning a hole to the row, column of the player's robot.
        //
        // Also, be sure to place holes away from the outer walls, more in the general space we think the player
        // robot will go--the middle of the room.
        for aSpace in potentialSpacesForHoles.emptySpaces {
            if (aSpace.type == .space || aSpace.type == .robot) && aSpace.coords.row >= minRowForHoles && aSpace.coords.row <= levelGrid.count - minRowDistanceAwayFromExitRowForHoles && aSpace.coords.column >= minColumnDistanceAwayFromLeftWallForHoles && aSpace.coords.column <= levelGrid[0].count - minColumnDistanceAwayFromRightWallForHoles && !isWallOrFixedLevelComponentNearby2(coords: aSpace.coords) {
                spacesForHoles.append(aSpace)
            }
        }

        // 2) randomly select placement spots of numHolesToPlace holes
        
        // find places for visible holes
        if numVisibleHoles > 0 {
            for _ in 1...numVisibleHoles {
                let nextSpotToPlaceHole = randomNumGenerator.xorshift_randomgen() % spacesForHoles.count
                visibleHoleLocations.append(spacesForHoles[nextSpotToPlaceHole])
                spacesForHoles.remove(at: nextSpotToPlaceHole)    // remove the entry so we don't try to use it again.  This also changes the count use in generating
                // the next spot.  But does an array automatically readjust all the elements after one is removed in the
                // middle?  I think it does.
            }
        }
        
        // find places for camouflaged holes
        if numCamouflagedHoles > 0 {
            for _ in 1...numCamouflagedHoles {
                let nextSpotToPlaceHole = randomNumGenerator.xorshift_randomgen() % spacesForHoles.count
                camouflagedHoleLocations.append(spacesForHoles[nextSpotToPlaceHole])
                spacesForHoles.remove(at: nextSpotToPlaceHole)    // remove the entry so we don't try to use it again.  This also changes the count use in generating
                // the next spot.  But does an array automatically readjust all the elements after one is removed in the
                // middle?  I think it does.
            }
        }

        // 3) place holes, and don't forget to update the expanded maze with the placements.
        // First the visible holes
        for aHoleLocation in visibleHoleLocations {
            
            // a) update empty spaces list so we know that location is now has a hole in it.
            emptySpacesList.emptySpaces[emptySpacesList.indexByIdNumber[aHoleLocation.number]!].type = .hole
            
            // b) Make a visible hole scene node.
            let hole = Hole(holeNum: aHoleLocation.number, location: aHoleLocation.coords)
            
            // We're camouflaging all holes now to make things simpler.  This way we don't have to
            // worry about making the emp grenades fall through the hole instead of bouncing.  We're leaving
            // the code this way, with placement of 'visible' and camouflaged holes so that if we change
            // our minds later we can easily switch back by just removing the line below that camouflages
            // the hole.
            hole.camouflageHole()

            // c) Add hole to levelGrid and to our holes list
            levelGrid[hole.levelCoords.row][hole.levelCoords.column].append(hole.holeNode.name!)
            holes[hole.holeNode.name!] = hole
            
            // d) Add hole to scene and in allDurableComponents list for quick reference
            sceneView.scene?.rootNode.addChildNode(hole.holeNode)
            allDurableComponents[hole.holeNode.name!] = .hole
        }
        
        // Next, the camouflaged holes
        for aHoleLocation in camouflagedHoleLocations {
            
            // a) update empty spaces list so we know that location is now has a hole in it.
            emptySpacesList.emptySpaces[emptySpacesList.indexByIdNumber[aHoleLocation.number]!].type = .hole
            
            // b) Make a hole scene node and camouflage the hole
            let hole = Hole(holeNum: aHoleLocation.number, location: aHoleLocation.coords)
            hole.camouflageHole()
            
            // c) Add hole to levelGrid and to our holes list
            levelGrid[hole.levelCoords.row][hole.levelCoords.column].append(hole.holeNode.name!)
            holes[hole.holeNode.name!] = hole
            
            // d) Add hole to scene and to allDurableComponents list for quick reference
            sceneView.scene?.rootNode.addChildNode(hole.holeNode)
            allDurableComponents[hole.holeNode.name!] = .hole
        }
    }
    
    // Update the level Grid when a robot moves
    func updateRobotLocationInLevelGrid(robotName: String, levelCoords: LevelCoordinates, lastLevelCoords: LevelCoordinates, robots: [String : Robot]) {
        // Although we're pretty sure the robot is in the row, column passed to the function,
        // doublecheck anyway before trying to remove it from the old coordinates.
        if levelGrid[lastLevelCoords.row][lastLevelCoords.column].contains(robotName) {
            let robotIndex = levelGrid[lastLevelCoords.row][lastLevelCoords.column].index(of: robotName)
            levelGrid[lastLevelCoords.row][lastLevelCoords.column].remove(at: robotIndex!)
            levelGrid[levelCoords.row][levelCoords.column].append(robotName)
        }
        /*
        else {
            print ("robot \(robotName) _not_ at lastLevelCoords: row: \(lastLevelCoords.row), column: \(lastLevelCoords.column)!")
        }
        */
    }
    
    // Remove item - most likely the robot - from the level grid when it has been destroyed.
    func removeRobotFromLevelGrid(robotName: String, levelCoords: LevelCoordinates) {
        if levelGrid[levelCoords.row][levelCoords.column].contains(robotName) {
            let robotIndex = levelGrid[levelCoords.row][levelCoords.column].index(of: robotName)
            levelGrid[levelCoords.row][levelCoords.column].remove(at: robotIndex!)
        }
    }
    
    func init_level_grid(numRows: Int, numCols: Int) {
        
        // It's kludgy but we have to assign something to the very first row outside of our for
        // loop because the append() method tacks on elements after the first one.  Fortunately,
        // we can do that and assign a row to levelGrid[0], the very first row of columns.
        // Note: We're assigning a list of components to each levelGrid[row][column].  We do this
        // because multiple objects can occupy the same row,column coordinates because the space
        // that that represents is large, a 4x2 meter square at this point (2017-03-16).
        var oneRow = Array(repeating: [String](), count: numCols)
        for column in 0...numCols - 1 {
            oneRow[column] = [emptyLabel]
        }
        levelGrid[0] = oneRow
        for _ in 1...numRows {
            var oneRow = Array(repeating: [String](), count: numCols)
            for column in 0...numCols - 1 {
                oneRow[column] = [emptyLabel]
            }
            levelGrid.append(oneRow)
        }
    }
}
