//
//  DestroyedRobot.swift
//  RobotRaider
//
//  Created by Nathanael Bills on 7/20/18.
//  Copyright © 2018 invasivemachines. All rights reserved.
//

import Foundation
import SceneKit

class DestroyedRobot {
    
    var robotNumber = Int(-1)
    var playerType: PlayerType = .noPlayer
    var robotType: RobotType = .noRobot
    var robotBodyNode: SCNNode!
    var leftWheelNode: SCNNode!
    var rightWheelNode: SCNNode!
    var leftArmNode: SCNNode!
    var rightArmNode: SCNNode!
    var launcherNode: SCNNode!
    
    var robotNode: SCNNode!
    var robotLabelNode: SCNNode!                // label above robot with the robot's name, for debugging only.
    var hoverUnitNode: SCNNode!      // the hover unit is attached to every robot but is normally clear
    // unless it is turned on or, in the case of the player's robot, not
    // unlocked yet.
    
    var robotDimensions: RobotDimensions!
    
    var nearTopOfRobotNode: SCNNode!     // a node we use to tell us when the robot has tipped over.  This
    // is an invisible node that sits near the top of the robot.  If difference
    // between the y coord of this node and the y coord at the center of the robot
    // is 1/2 of what it normally is, then we can assume that the robot should shut down.
    
    var currentDirection: Int = zeroDirection      // for ai robot, the current direction it is facing.
    var currentVelocity: SCNVector3 = notMoving    // for ai robot, the current direction and speed it is moving.
    
    var robotHealth: RobotHealth!               // robot health
    
    var robotDisabled: Bool = false             // flag to let us know if this robot has been disabled.  This is primarily used by the player robot
    // and lets the ai robots know that it is disabled so they don't keep trying to attack it.
    
    var originalRobotFriction: CGFloat = 0.5                    // original friction of robot before being set artificially high during an impact.
    // The robots actually slide across the ground because that was easier than trying to make their wheels
    // roll.
    
    var zapperEnabled: Bool = false                             // for player robots only.  The ai zapper robot is just a zapper so we don't have to
    // enable it.
    var secondLauncherEnabled: Bool = false                     // for player robots only.  Only the player robot gets a second launcher.
    
    init (robotNum: Int, playertype: PlayerType, robottype: RobotType, location: SCNVector3, zapperEnabled: Bool, secondLauncherEnabled: Bool) {
        
        // Note: zapperEnabled is only for the player robot because we will use a different model in that case.  This gives us more
        // flexbility in how we represent the player's robot with the zapper but it's kludgy.
        playerType = playertype
        robotType = robottype
        robotNumber = robotNum
        
        self.zapperEnabled = zapperEnabled              // keep track of this -- we will need it later if this is the player robot and it gets shut down.
        // and we have to create a dummy robot with the same characteristics.
        self.secondLauncherEnabled = secondLauncherEnabled
        
        var robotName: String = ""
        
        robotHealth = RobotHealth(playerType: playerType, robotType: robotType)      // assign robot health first thing--this also includes default reload time.

        if playertype == .localHumanPlayer {
            robotName = playerRobotLabel
        }
        else {
            robotName = aiRobotLabel + String(robotNum)
        }

        robotNode = SCNNode()
        robotDimensions = createRobot(robotName: robotName, zapperEnabled: zapperEnabled, secondLauncherEnabled: secondLauncherEnabled)
        
        let hoverUnitGeometry = SCNCylinder(radius: robotDimensions.width / 2.0, height: 0.1)
        hoverUnitNode = SCNNode(geometry: hoverUnitGeometry)
        hoverUnitNode.geometry?.firstMaterial?.diffuse.contents = UIColor.clear
        hoverUnitNode.position = SCNVector3(0.0, -robotDimensions.height / 2.0, 0.0)
        hoverUnitNode.name = robotName
        robotNode.addChildNode(hoverUnitNode)
        
        robotNode.position = location
        robotNode.position.y = Float(robotDimensions.height) / 2.0 + 0.1  // add +0.1 for a fudge factor.
        
        let nearTopOfRobotNodeGeometry = SCNBox(width: 0.01, height: 0.01, length: 0.01, chamferRadius: 0.0)
        nearTopOfRobotNode = SCNNode(geometry: nearTopOfRobotNodeGeometry)
        nearTopOfRobotNode.position = SCNVector3(0.0, robotDimensions.height / 2.0 - 0.02, 0.0)
        // If the robot is a zapper, we fudge a little bit and move the top of robot down a little to make the
        // aura look better
        if robotType == .zapper {
            nearTopOfRobotNode.position = SCNVector3(0.0, robotDimensions.height / 2.0 - 0.4, 0.0)
        }
        robotNode.addChildNode(nearTopOfRobotNode)         // add our invisible node to the robotNode.
        
        // It's difficult to see what the dimension is
        // in scenekit but we can see it in blender in the Properties shelf in the transform section where we see the
        // x, y, z dimension.  Note that the axis are different in blender than anywhere else so it is necessary to look
        // at which ones are which when looking at the sizes.  For example, the z axis is actually up/down in blender.  We
        // would normally think of that as the y axis.
        
        // Note: this robot shape only works for workers right now, and the arms still go through things.  Sigh.
        let robotNodeShape = SCNPhysicsShape(geometry: SCNBox(width: robotDimensions.width, height: robotDimensions.height, length: robotDimensions.length, chamferRadius: 0.0), options: nil)
        robotNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: robotNodeShape)
        
        if playerType == .localHumanPlayer {
            robotNode.physicsBody!.categoryBitMask = collisionCategoryPlayerRobot
            // Note: make sure the player's robot collides with the vault barrier to prevent it from getting to the vault unless it has all the key parts.
            robotNode.physicsBody!.collisionBitMask = collisionCategoryGround | collisionCategoryWall | collisionCategoryLevelComponent | collisionCategoryAIRobot | collisionCategoryEMPGrenade | collisionCategoryVaultBarrier | collisionCategoryLevelEntrance | collisionCategoryLevelExitDoorway
            // Note: we also set the contactTestBitMask for the vault barrier because we also want to know when contact happens so we can
            // change the color of the force field.
            robotNode.physicsBody!.contactTestBitMask = collisionCategoryAIRobotBakedGood  | collisionCategoryLevelExit | collisionCategoryVault | collisionCategoryVaultBarrier
            //robotNode.eulerAngles = robotFacingDirections[North]
            robotNode.rotation = robotFacingDirections[north]
        }
        else {
            robotNode.physicsBody!.categoryBitMask = collisionCategoryAIRobot
            robotNode.physicsBody!.collisionBitMask = collisionCategoryGround | collisionCategoryWall | collisionCategoryLevelComponent | collisionCategoryAIRobot | collisionCategoryPlayerRobot | collisionCategoryEMPGrenade | collisionCategoryLevelEntrance | collisionCategoryLevelExitDoorway
            robotNode.physicsBody!.contactTestBitMask = collisionCategoryPlayerRobotBakedGood  | collisionCategoryAIRobotBakedGood | collisionCategoryLevelExit | collisionCategoryVault
            //robotNode.eulerAngles = robotFacingDirections[South]
            robotNode.rotation = robotFacingDirections[south]
        }
        
        robotNode.physicsBody!.angularVelocityFactor = SCNVector3(0.0, 0.0, 0.0)  // prevent robot from rotating in any direction after collision.
        robotNode.physicsBody!.restitution = 0.0  // don't bounce off of anything.
        robotNode.physicsBody!.mass = CGFloat(robotHealth.mass)     // Don't forget to assign the mass from robotHealth.  Because the masses can be different
        // for different robot we need to assign this once the robot has been created.
    }
    
    func addArms(loc: SCNVector3, width: Float) {
        leftArmNode = allModelsAndMaterials.leftArmModel.clone()
        leftArmNode.geometry = allModelsAndMaterials.leftArmModel.geometry?.copy() as? SCNGeometry
        leftArmNode.geometry?.firstMaterial = allModelsAndMaterials.leftArmModel.geometry?.firstMaterial?.copy() as? SCNMaterial
        leftArmNode.position = SCNVector3(loc.x - width/2.0, loc.y, loc.z)
        leftArmNode.rotation = SCNVector4(0.0, 1.0, 0.0, Float.pi)
        
        rightArmNode = allModelsAndMaterials.rightArmModel.clone()
        rightArmNode.geometry = allModelsAndMaterials.rightArmModel.geometry?.copy() as? SCNGeometry
        rightArmNode.geometry?.firstMaterial = allModelsAndMaterials.rightArmModel.geometry?.firstMaterial?.copy() as? SCNMaterial
        rightArmNode.position = SCNVector3(loc.x + width/2.0, loc.y, loc.z)
        
        robotNode.addChildNode(leftArmNode)
        robotNode.addChildNode(rightArmNode)
    }
    
    // Note: in the destroyed robots we're not turning the wheels.  This is the one difference between the addWheels here and
    // the addWheels in the normal robot.
    func addWheels(loc: SCNVector3) {
        leftWheelNode = allModelsAndMaterials.wheelModel.clone()
        leftWheelNode.geometry = allModelsAndMaterials.wheelModel.geometry?.copy() as? SCNGeometry
        leftWheelNode.geometry?.firstMaterial = allModelsAndMaterials.wheelModel.geometry?.firstMaterial?.copy() as? SCNMaterial
        leftWheelNode.position = SCNVector3(loc.x - 1.0, loc.y, loc.z)
        leftWheelNode.rotation = SCNVector4(0.0, 0.0, 1.0, -Float.pi/2.0)
        
        rightWheelNode = allModelsAndMaterials.wheelModel.clone()
        rightWheelNode.geometry = allModelsAndMaterials.wheelModel.geometry?.copy() as? SCNGeometry
        rightWheelNode.geometry?.firstMaterial = allModelsAndMaterials.wheelModel.geometry?.firstMaterial?.copy() as? SCNMaterial
        rightWheelNode.position = SCNVector3(loc.x + 1.0, loc.y, loc.z)
        rightWheelNode.rotation = SCNVector4(0.0, 0.0, 1.0, Float.pi/2.0)
        
        if robotType == .ghost {
            leftWheelNode.geometry?.firstMaterial?.transparency = ghostRobotTransparency
            rightWheelNode.geometry?.firstMaterial?.transparency = ghostRobotTransparency
        }
        robotNode.addChildNode(leftWheelNode)
        robotNode.addChildNode(rightWheelNode)
        
    }
    
    func createRobot(robotName: String, zapperEnabled: Bool, secondLauncherEnabled: Bool) -> RobotDimensions {
        var robotDimensions = RobotDimensions(width: 1.5, height: 3.3, length: 1.0)
        
        if playerType == .localHumanPlayer {
            if secondLauncherEnabled == true {
                launcherNode = allModelsAndMaterials.duallaunchersModel.clone()
                launcherNode.geometry = allModelsAndMaterials.duallaunchersModel.geometry?.copy() as? SCNGeometry
                launcherNode.geometry?.firstMaterial = allModelsAndMaterials.duallaunchersModel.geometry?.firstMaterial?.copy() as? SCNMaterial
            }
            else {
                launcherNode = allModelsAndMaterials.launcherModel.clone()
                launcherNode.geometry = allModelsAndMaterials.launcherModel.geometry?.copy() as? SCNGeometry
                launcherNode.geometry?.firstMaterial = allModelsAndMaterials.launcherModel.geometry?.firstMaterial?.copy() as? SCNMaterial
            }
            if zapperEnabled == true {
                robotBodyNode = allModelsAndMaterials.playerZapperModel.clone()
                // Can't just clone a node. We also have to copy the geometry and material to make them independent
                // copies.  Otherwise what happens to one happens to all others of the same geometry and material.
                robotBodyNode.geometry = allModelsAndMaterials.playerZapperModel.geometry?.copy() as? SCNGeometry
                robotBodyNode.geometry?.firstMaterial = allModelsAndMaterials.playerZapperModel.geometry?.firstMaterial?.copy() as? SCNMaterial
            }
            else {
                robotBodyNode = allModelsAndMaterials.playerModel.clone()
                // Can't just clone a node. We also have to copy the geometry and material to make them independent
                // copies.  Otherwise what happens to one happens to all others of the same geometry and material.
                robotBodyNode.geometry = allModelsAndMaterials.playerModel.geometry?.copy() as? SCNGeometry
                robotBodyNode.geometry?.firstMaterial = allModelsAndMaterials.playerModel.geometry?.firstMaterial?.copy() as? SCNMaterial
            }
            
            robotBodyNode.name = robotName
            
            // Note: the robotNode is composed of the robot body, about 4.2 m in height and
            // the wheels, about 1.6 m in height.  However, because the center of the wheels
            // sit at the bottom of the body the combined height is actually 4.2m + 0.8m for
            // a total height of about 5m.
            robotBodyNode.position.y = 0.8
            launcherNode.position.y = 0.4
            robotNode.addChildNode(robotBodyNode)
            robotNode.addChildNode(launcherNode)
            addWheels(loc: SCNVector3(0.0, -1.4, 0.0))
            robotNode.name = robotName
            robotDimensions = RobotDimensions(width: 2.4, height: 5.0, length: 2.4)
        }
        else {
            switch robotType {
            case .worker:
                robotBodyNode = allModelsAndMaterials.workerModel.clone()
                // Can't just clone a node. We also have to copy the geometry and material to make them independent
                // copies.  Otherwise what happens to one happens to all others of the same geometry and material.
                robotBodyNode.geometry = allModelsAndMaterials.workerModel.geometry?.copy() as? SCNGeometry
                robotBodyNode.geometry?.firstMaterial = allModelsAndMaterials.workerModel.geometry?.firstMaterial?.copy() as? SCNMaterial
                robotBodyNode.name = robotName
                
                // Note: just as we did for the player's robot, we also shift the robot body
                // for the worker upwards in the robotNode coordinate system and then place
                // the wheels below it.
                robotBodyNode.position.y = 0.4
                robotNode.addChildNode(robotBodyNode)
                addWheels(loc: SCNVector3(0.0, -1.35, 0.0))
                addArms(loc: SCNVector3(0.0, 1.0, 0.0), width: 3.2)
                robotNode.name = robotName
                robotDimensions = RobotDimensions(width: 1.5, height: 4.3, length: 1.0)
            case .baker:
                robotBodyNode = allModelsAndMaterials.bakerModel.clone()
                // Can't just clone a node. We also have to copy the geometry and material to make them independent
                // copies.  Otherwise what happens to one happens to all others of the same geometry and material.
                robotBodyNode.geometry = allModelsAndMaterials.bakerModel.geometry?.copy() as? SCNGeometry
                robotBodyNode.geometry?.firstMaterial = allModelsAndMaterials.bakerModel.geometry?.firstMaterial?.copy() as? SCNMaterial
                
                robotBodyNode.name = robotName
                robotBodyNode.position.y = 0.8
                robotNode.addChildNode(robotBodyNode)
                addWheels(loc: SCNVector3(0.0, -1.75, 0.0))
                robotNode.name = robotName
                launcherNode = allModelsAndMaterials.ailauncherModel.clone()
                launcherNode.geometry = allModelsAndMaterials.ailauncherModel.geometry?.copy() as? SCNGeometry
                launcherNode.geometry?.firstMaterial = allModelsAndMaterials.ailauncherModel.geometry?.firstMaterial?.copy() as? SCNMaterial
                launcherNode.position.y = 0.4
                robotNode.addChildNode(launcherNode)
                robotDimensions = RobotDimensions(width: 2.4, height: 5.0, length: 2.4)
            case .doublebaker:
                robotBodyNode = allModelsAndMaterials.doublebakerModel.clone()
                // Can't just clone a node. We also have to copy the geometry and material to make them independent
                // copies.  Otherwise what happens to one happens to all others of the same geometry and material.
                robotBodyNode.geometry = allModelsAndMaterials.doublebakerModel.geometry?.copy() as? SCNGeometry
                robotBodyNode.geometry?.firstMaterial = allModelsAndMaterials.doublebakerModel.geometry?.firstMaterial?.copy() as? SCNMaterial
                
                robotBodyNode.name = robotName
                robotBodyNode.position.y = 0.8
                robotNode.addChildNode(robotBodyNode)
                addWheels(loc: SCNVector3(0.0, -1.75, 0.0))
                robotNode.name = robotName
                launcherNode = allModelsAndMaterials.ailauncherModel.clone()
                launcherNode.geometry = allModelsAndMaterials.ailauncherModel.geometry?.copy() as? SCNGeometry
                launcherNode.geometry?.firstMaterial = allModelsAndMaterials.ailauncherModel.geometry?.firstMaterial?.copy() as? SCNMaterial
                launcherNode.position.y = 0.4
                robotNode.addChildNode(launcherNode)
                robotDimensions = RobotDimensions(width: 2.4, height: 5.0, length: 2.4)
            case .zapper:
                robotBodyNode = allModelsAndMaterials.zapperModel.clone()
                // Can't just clone a node. We also have to copy the geometry and material to make them independent
                // copies.  Otherwise what happens to one happens to all others of the same geometry and material.
                robotBodyNode.geometry = allModelsAndMaterials.zapperModel.geometry?.copy() as? SCNGeometry
                robotBodyNode.geometry?.firstMaterial = allModelsAndMaterials.zapperModel.geometry?.firstMaterial?.copy() as? SCNMaterial
                
                robotBodyNode.name = robotName
                robotBodyNode.position.y = 0.4
                robotNode.addChildNode(robotBodyNode)
                addWheels(loc: SCNVector3(0.0, -1.35, 0.0))
                robotNode.name = robotName
                robotDimensions = RobotDimensions(width: 1.5, height: 4.3, length: 1.2)
            case .superworker:
                robotBodyNode = allModelsAndMaterials.superworkerModel.clone()
                // Can't just clone a node. We also have to copy the geometry and material to make them independent
                // copies.  Otherwise what happens to one happens to all others of the same geometry and material.
                robotBodyNode.geometry = allModelsAndMaterials.superworkerModel.geometry?.copy() as? SCNGeometry
                robotBodyNode.geometry?.firstMaterial = allModelsAndMaterials.superworkerModel.geometry?.firstMaterial?.copy() as? SCNMaterial
                
                robotBodyNode.name = robotName
                robotBodyNode.position.y = 1.2
                robotNode.addChildNode(robotBodyNode)
                addWheels(loc: SCNVector3(0.0, -2.6, 0.0))
                addArms(loc: SCNVector3(0.0, 2.0, 0.0), width: 3.1)
                robotNode.name = robotName
                
                // triple resistance for the Superworker.  The player can't at this point
                // do a static discharge but we raise it anyway.  Besides, the homing and
                // ghost robots can and they will affect other ai robots.  It might
                // be a fun surprise for the player that this robot also survives an EMP.
                // Note: we don't change mobility.  We leave it the way it is.  The player can
                // slow them down as normal, even if they can't destroy them as easily.  Don't
                // want to make things too hard.
                // Note: we directly change the robot health here as these are not powerUps that
                // go away after a time like what the player experiences but are really health
                // enhancements.
                robotHealth.multiplyMass(by: 3.0)
                robotDimensions = RobotDimensions(width: 2.0, height: 6.8, length: 1.5)
            case .superbaker:
                robotBodyNode = allModelsAndMaterials.superbakerModel.clone()
                // Can't just clone a node. We also have to copy the geometry and material to make them independent
                // copies.  Otherwise what happens to one happens to all others of the same geometry and material.
                robotBodyNode.geometry = allModelsAndMaterials.superbakerModel.geometry?.copy() as? SCNGeometry
                robotBodyNode.geometry?.firstMaterial = allModelsAndMaterials.superbakerModel.geometry?.firstMaterial?.copy() as? SCNMaterial
                
                robotBodyNode.name = robotName
                robotBodyNode.position.y = 1.2
                robotNode.addChildNode(robotBodyNode)
                addWheels(loc: SCNVector3(0.0, -2.6, 0.0))
                robotNode.name = robotName
                // triple the mass because the superbaker should be harder to topple over.  Here we want the same mass as the original
                // so that if it is knocked over it behaves the same as the original.
                robotHealth.multiplyMass(by: 3.0)
                
                launcherNode = allModelsAndMaterials.ailauncherModel.clone()
                launcherNode.geometry = allModelsAndMaterials.ailauncherModel.geometry?.copy() as? SCNGeometry
                launcherNode.geometry?.firstMaterial = allModelsAndMaterials.ailauncherModel.geometry?.firstMaterial?.copy() as? SCNMaterial
                launcherNode.scale = SCNVector3(1.5, 1.0, 1.5)
                launcherNode.position.y = 1.0
                robotNode.addChildNode(launcherNode)
                robotDimensions = RobotDimensions(width: 3.4, height: 6.8, length: 3.4)
            case .homing:
                robotBodyNode = allModelsAndMaterials.homingModel.clone()
                // Can't just clone a node. We also have to copy the geometry and material to make them independent
                // copies.  Otherwise what happens to one happens to all others of the same geometry and material.
                robotBodyNode.geometry = allModelsAndMaterials.homingModel.geometry?.copy() as? SCNGeometry
                robotBodyNode.geometry?.firstMaterial = allModelsAndMaterials.homingModel.geometry?.firstMaterial?.copy() as? SCNMaterial
                
                robotBodyNode.name = robotName
                robotBodyNode.position.y = 0.4
                robotNode.addChildNode(robotBodyNode)
                addWheels(loc: SCNVector3(0.0, -0.47, 0.0))
                robotNode.name = robotName
                robotDimensions = RobotDimensions(width: 1.0, height: 2.54, length: 2.0)
            case .ghost:
                robotBodyNode = allModelsAndMaterials.ghostModel.clone()
                // Can't just clone a node. We also have to copy the geometry and material to make them independent
                // copies.  Otherwise what happens to one happens to all others of the same geometry and material.
                robotBodyNode.geometry = allModelsAndMaterials.ghostModel.geometry?.copy() as? SCNGeometry
                robotBodyNode.geometry?.firstMaterial = allModelsAndMaterials.ghostModel.geometry?.firstMaterial?.copy() as? SCNMaterial
                
                robotBodyNode.name = robotName
                robotBodyNode.position.y = 0.4
                robotNode.addChildNode(robotBodyNode)
                addWheels(loc: SCNVector3(0.0, -0.47, 0.0))
                robotNode.name = robotName
                // make our camo robot transparent to make it harder to see.  Later we
                // need to somehow make a glass texture for it for a more interesting effect
                // if it doesn't adversely affect performance.
                let materials = (robotBodyNode.geometry?.materials)!
                for aMaterial in materials {
                    aMaterial.transparency = ghostRobotTransparency
                }
                robotDimensions = RobotDimensions(width: 1.0, height: 2.54, length: 2.0)
            case .pastrychef:
                robotBodyNode = allModelsAndMaterials.pastrychefModel.clone()
                // Can't just clone a node. We also have to copy the geometry and material to make them independent
                // copies.  Otherwise what happens to one happens to all others of the same geometry and material.
                robotBodyNode.geometry = allModelsAndMaterials.pastrychefModel.geometry?.copy() as? SCNGeometry
                robotBodyNode.geometry?.firstMaterial = allModelsAndMaterials.pastrychefModel.geometry?.firstMaterial?.copy() as? SCNMaterial
                
                robotBodyNode.name = robotName
                robotBodyNode.position.y = 2.0
                robotNode.addChildNode(robotBodyNode)
                addWheels(loc: SCNVector3(0.0, -3.0, 0.0))
                robotNode.name = robotName
                // be sure to set the mass the same as the working pastry chef.  That way if it is knocked over it will behave the
                // same as the original.
                robotHealth.multiplyMass(by: 5.0)
                launcherNode = allModelsAndMaterials.ailauncherModel.clone()
                launcherNode.geometry = allModelsAndMaterials.ailauncherModel.geometry?.copy() as? SCNGeometry
                launcherNode.geometry?.firstMaterial = allModelsAndMaterials.ailauncherModel.geometry?.firstMaterial?.copy() as? SCNMaterial
                launcherNode.scale = SCNVector3(1.5, 1.0, 1.5)
                launcherNode.position.y = 1.0
                robotNode.addChildNode(launcherNode)
                robotDimensions = RobotDimensions(width: 3.4, height: 8.3, length: 3.4)
            default:
                break
            }
        }
        return robotDimensions
    }
    
    // By default we turn off the force effects when the robot is created. But we turn them
    // back on under special conditions, like when they've been hit by a massive baked good
    // that should knock them over.
    func turnOnForceEffects() {
        //robotNode.physicsBody!.angularVelocityFactor = SCNVector3(1.0, 1.0, 1.0)  // allow robot to rotate in any direction after collision.
        robotNode.physicsBody!.angularVelocityFactor = SCNVector3(0.5, 0.0, 0.5)  // allow robot to rotate in mostly x and z directions after collision.
        robotNode.physicsBody!.restitution = 0.1  // bounce off of anything but not that much.
        
    }
    
    // if the robot is rammed but it wasn't enough to knock over the robot, then we turn the
    // force effects back off so that it doesn't start to tip over, which can happen slowly
    // after a contact is made.
    func turnOffForceEffects() {
        robotNode.physicsBody!.angularVelocityFactor = SCNVector3(0.0, 0.0, 0.0)  // prevent robot from rotating in any direction after collision.
        robotNode.physicsBody!.angularVelocity = SCNVector4Zero   // robot may still be rotating so we stop that rotation here.
        robotNode.physicsBody!.restitution = 0.0  // don't bounce off of anything.
    }
    
    // used for shutting down a corroded robot.  First we want to go to the most
    // corroded state before shutting it down so this function should run before
    // the shutdownRobot() function.  And they should both be separate SCNActions.
    // Otherwise we get the two SCNTransactions running simultaneously, which doesn't
    // look right.
    func goToMostCorrodedState() {
        // First, go to the most corroded state.
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 1.0
        let materials = (robotBodyNode.geometry?.materials)! as [SCNMaterial]
        let material = materials[0]
        material.multiply.contents = corrosionColors[mostCorrodedState]
        if doesRobotHaveLauncher(playerType: playerType, robotType: robotType) == true {
            let launcherMaterials = (launcherNode.geometry?.materials)! as [SCNMaterial]
            let launcherMaterial = launcherMaterials[0]
            launcherMaterial.multiply.contents = corrosionColors[mostCorrodedState]
        }
        SCNTransaction.commit()
    }
    
    // This transitions the color of the robot body to dark gray to
    // signify that the robot is shutting down.
    func shutdownRobot () {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = robotShutdownDuration
        let materials = (robotBodyNode.geometry?.materials)! as [SCNMaterial]
        let material = materials[0]
        material.multiply.contents = UIColor.darkGray
        if doesRobotHaveLauncher(playerType: playerType, robotType: robotType) == true {
            let launcherMaterials = (launcherNode.geometry?.materials)! as [SCNMaterial]
            let launcherMaterial = launcherMaterials[0]
            launcherMaterial.multiply.contents = UIColor.darkGray
        }
        if playerType == .ai && (robotType == .worker || robotType == .superworker) {
            let leftArmMaterials = (leftArmNode.geometry?.materials)! as [SCNMaterial]
            let leftArmMaterial = leftArmMaterials[0]
            leftArmMaterial.multiply.contents = UIColor.black
            let rightArmMaterials = (rightArmNode.geometry?.materials)! as [SCNMaterial]
            let rightArmMaterial = rightArmMaterials[0]
            rightArmMaterial.multiply.contents = UIColor.black
        }
        SCNTransaction.commit()
    }
    
    func chargeEMP () {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = robotCreateEMPDuration
        let materials = (robotBodyNode.geometry?.materials)! as [SCNMaterial]
        let material = materials[0]
        material.diffuse.contents = UIColor.white
        SCNTransaction.commit()
    }
    
    // Remove all collision and contact detection for the robot but leave the floor.  Otherwise the robot immediately falls
    // through the floor.  This should only happen when it is shutting down or
    // blowing up.
    func removeCollisionAndContactExceptForFloor() {
        robotNode.physicsBody!.categoryBitMask = collisionCategoryDyingRobot
        robotNode.physicsBody!.collisionBitMask = collisionCategoryGround
        robotNode.physicsBody!.contactTestBitMask = 0
        
    }
}
