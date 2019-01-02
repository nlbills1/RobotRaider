//
//  Robot.swift
//  RobotRaider
//
//  Created by Nathanael Bills on 10/13/16.
//  Copyright © 2016 invasivemachines. All rights reserved.
//

import Foundation
import SceneKit

class Robot {
    
    var robotNumber = Int(-1)
    var playerType: PlayerType = .noPlayer
    var robotType: RobotType = .noRobot
    var robotBodyNode: SCNNode!
    var leftWheelNode: SCNNode!
    var rightWheelNode: SCNNode!
    var leftArmNode: SCNNode!
    var rightArmNode: SCNNode!
    var launcherNode: SCNNode!
    var bunsenBurnerNode: SCNNode!
    var bunsenBurnerFlameNode: SCNNode!     // node that has the flame--transparent when not on and used for detecting when ai
                                            // robots are in range.
    
    var robotNode: SCNNode!
    //var robotLabelNode: SCNNode!                // label above robot with the robot's name, for debugging only.
    var hoverUnitNode: SCNNode!      // the hover unit is attached to every robot but is normally clear
                                     // unless it is turned on or, in the case of the player's robot, not
                                     // unlocked yet.
    
    var attachedPowerUpNode: SCNNode!   // power up node that gets attached to the robot whenever the player
                                        // picks up a power up.  Later it is removed when either the time runs
                                        // out or another power up is picked up.
    
    var robotDimensions: RobotDimensions!
    
    var nearTopOfRobotNode: SCNNode!     // a node we use to tell us when the robot has tipped over.  This
                                        // is an invisible node that sits near the top of the robot.  If difference
                                        // between the y coord of this node and the y coord at the center of the robot
                                        // is 1/2 of what it normally is, then we can assume that the robot should shut down.
    
    var maxYBetweenNearTopAndRobotCenter: Float = 0.0
    
    var robotState: RobotState = .random 
    // default to mimimum ranges.  When we go to match robot number with robot type, then we
    // change this to medium or maximum if robots are the more challenging robots.
    var aiRobotThrowingRange: Float = minimumAIRobotThrowingRange
    var aiRobotHomingRange: Int = minimumAIRobotHomingRange
    
    var levelCoords = LevelCoordinates()
    var lastLevelCoords = LevelCoordinates()      // the last level coords.  We use this to keep track of when robots move from 
                                                  // one space in the level grid to another.
    
    var lastLevelCoordsWhereVelocitySet = LevelCoordinates()
    var currentDirection: Int = zeroDirection      // for ai robot, the current direction it is facing.
    var currentVelocity: SCNVector3 = notMoving    // for ai robot, the current direction and speed it is moving.
    
    var timeReloadStarted: [Double] = [launcherReadyToFire]         // we keep track of when the reload starts so we know when reload is finished and the
                                                // baker can throw again.  All robots start with just one launcher so we have just one
                                                // timeReloadStarted.  However, more can be added by the player if a second, third or fourth
                                                // launcher is selected.
    
    var timeOfLastDirectionSwitch: Double = 0.0    // the last time the ai robot switch direction.
    var switchDirectionDelayTime: Double = 0.0
    
    var robotHealth: RobotHealth!               // robot health
    
    var withinReachDistance: Float = 0.0         // distance considered within reach of either a worker's arms or a homer's blast radius
    
    var isTurningToFacePlayer: Bool = false     // for robots like workers and superworkers that will turn to face the player when very close.
                                                // we use this flag to not only let us know that the robot is turning but also as a flag to signal
                                                // not to keep moving the robot around but to leave it where it has as it's doing its turning action.
    
    var isRobotStopped: Bool = false            // for robots like homing and dodging, which will stop near the player and explode.  We use this flag
                                                // to let us know not to keep moving the robot around or try to stop it again once it has already been stopped.
                                                // Otherwise this would keep happening in the renderer() loop.
    
    var selectedAmmo: String = noActiveAmmo
    
    var robotDisabled: Bool = false             // flag to let us know if this robot has been disabled.  This is primarily used by the player robot
                                                // and lets the ai robots know that it is disabled so they don't keep trying to attack it.
    var playerInventory: Inventory!
    
    var throwCount: Int = 0                     // The number of baked goods thrown.  This applies only to ai robots that throw.  We want to
                                                // keep track of this so that we can affect the ai robot's accuracy by only allow 1 out of
                                                // so many throws to be accurate.  The number of misses that should occur in the level is
                                                // determine when the level is initialized and is stored in the numberOfAIRobotThrowsThatMiss
                                                // attribute/variable in that class.
    
    var maxRandomMovesToAvoidObstacle: Int = 0  // The number of times the ai robot moves randomly if it is trying to avoid an obstacle before switching
                                                // back to homing mode.
    
    var robotStuck: Bool = false                // a flag to tell us when the robot is stuck.  Only then would it try to go around an obstacle.
                                                // Otherwise the robot keeps switching directions as the forbidden directions determination is too
                                                // coarse and will flag directions as forbidden where the obstacle is one level row,col away, which
                                                // a huge distance since each row,col space represents a 4m x 4m space.
    
    var lastCorrodedState: Int = corrosionColors.count - 1    // The last state of corrosion for the robot.  This is based on the
                                                // number of states the corroded robot can be in
                                                // which are the number of colors in the corrosionColors array.  State count - 1 is the clear state where the
                                                // robot is not corroded at all.  Then we get to more corroded states as the corrosionResistance of the robot
                                                // erodes.
    var lastStaticDischargeDamageState: Int = staticDischargeDamageColors.count - 1   // the last state of damage for the robot just before it is in full health.
                                                //  State count - 1 is pretty much the no static discharge damage state.
    
    var lastRecoveryTime: Double = 0.0          // last time gradual recovery was invoked for the robot.  Note: This is for corrosion and static discharge.
                                                // Impact recovery is done in a differently because the reaction has to be more immediate.
    
    var lastImpactRecoveryTime: Double = 0.0    // We use a recovery action and also an adjustment at regular intervals for impact recovery because impact and
                                                // recovery are more immediate behaviors that we show in the scene.  The other types of damage and recovery
                                                // such as corrosion, mobility and static discharge are as immediately noticeable by the player so we can make
                                                // their recovery more gradual, hence the use of lastRecoveryTime for them.
    
    var deltaRobotTopPosition: Double = 0.0             // keeps track of the distance of the top of robot to where it would be in an upright position.
    var lastDeltaRobotTopPosition: Double = 0.0         // tracks the last delta so that we can tell when the robot is overcorrecting.  If it's less than
                                                        // deltaRobotTopPosition then we know that the robot needs to be adjusted.  If it's greater than
                                                        // deltaRobotTopPosition then we know the robot is moving towards the upright position.

    var lastPositionUpdateTime: Double = 0.0    // last time robot's position was tracked.  This is only for the player's robot.  We use it to
                                                // track the last time we stored the robot's position.
    var lastPositionUpdate: SCNVector3 = SCNVector3Zero     // For the player's robot only.  This track the player robot's position but only at certain
                                                            // intervals.  We use it to let the ai robot know of conditions where the player's robot velocity
                                                            // is its normal velocity, yet the robot has stopped because it has encountered a barrier.  This
                                                            // is necessary to switch the ai robot from leading the target to just throwing right at it.
    
    var impactedState: RobotImpactStates = .notImpactedOrRecovering     // the state of the robot, whether it has been impacted, recovering, tipped over, etc.
    
    var robotStoppedViaStopButton: Bool = false                 //  flag to let us know when the robot was stopped on command via the stop button - player robot.
    var originalRobotFriction: CGFloat = 0.5                    // original friction of robot before being set artificially high during an impact.
                                                                // The robots actually slide across the ground because that was easier than trying to make their wheels
                                                                // roll.
    
    var recoveryScalarForce: Double = defaultRobotRecoveryScalarForce   // recovery scalar force to be multiplied by a recovery unit vector to get the force to apply to
                                                                        // get the robot to recover to an upright position after an impact.
    
    var zapperEnabled: Bool = false                             // for player robots only.  The ai zapper robot is just a zapper so we don't have to
                                                                // enable it.
    var secondLauncherEnabled: Bool = false                     // for player robots only.  Only the player robot gets a second launcher.
    
    var zapColor: UIColor = UIColor.clear                       // zap color.  This gives us the flexibility to use different zap colors for the zapper,
                                                                // the player's zapper, and the pastry chef.
    
    var zapAuraNode: SCNNode!                                  // This would be where we show the building of the zap charge.  However, we just show an
                                                                // an instantaneous buildup and then zap.  We call it the zapAuraNode because it would be like
                                                                // robot having an aura, or halo, when the discharge occurs.  And we couldn't think of another
                                                                // name for it.
    var bunsenBurnerEnabled: Bool = false                       // for player robots only.  This tells us whether or not the bunsen burner has
                                                                // been enabled and thus whether or not to attach the bunsen burner.
    
    var haveWheelsStartedTurning: Bool = false                  // for the beginning of the level, and particularly for the ai robots.  If this is false, then the
                                                                // wheels will start turning and then this flag is set to true to prevent another starting of the wheels.
    
    var lastRobotZapped: LastRobotZapped = LastRobotZapped(name: "", loc: SCNVector3Zero)   // keep track of the last robot zapped, for players, zappers and pastrychefs.
    var crashSoundPlaying: Bool = false                         // Only set to true once the crash sound is playing -- to prevent repeats
    
    init (robotNum: Int, playertype: PlayerType, robottype: RobotType, location: SCNVector3, robotLevelLoc: LevelCoordinates, ammoChoices: [String], pInventory: Inventory, randomGen: RandomNumberGenerator, zapperEnabled: Bool, secondLauncherEnabled: Bool, bunsenBurnerEnabled: Bool) {
        
        // Note: zapperEnabled is only for the player robot because we will use a different model in that case.  This gives us more
        // flexbility in how we represent the player's robot with the zapper but it's kludgy.
        playerType = playertype
        robotType = robottype
        robotNumber = robotNum
        levelCoords = robotLevelLoc
        lastLevelCoords = robotLevelLoc
        lastLevelCoordsWhereVelocitySet = robotLevelLoc
        playerInventory = pInventory
        
        self.zapperEnabled = zapperEnabled              // keep track of this -- we will need it later if this is the player robot and it gets shut down.
                                                        // and we have to create a dummy robot with the same characteristics.
        self.secondLauncherEnabled = secondLauncherEnabled
        self.bunsenBurnerEnabled = bunsenBurnerEnabled
        
        var robotName: String = ""
        
        robotHealth = RobotHealth(playerType: playerType, robotType: robotType)      // assign robot health first thing--this also includes default reload time.
        
        // TEMPORARY: For now we make the active ammo fixed for both the player and the ai robots.  Later,
        // the player will be able to switch between two of them and the ai robots will only use
        // one, randomly picked from the list give the number of possible ammo choices up to the
        // point where the player is in level number once we have implemented unlocking of new ammow via
        // scoring milestones.
        if playertype == .localHumanPlayer {
            robotName = playerRobotLabel
            selectedAmmo = ammoChoices[0]   // default to the simplest ammo if there are no choices
            
        }
        else {
            robotName = aiRobotLabel + String(robotNum)
            // exclude the emp grenade from consideration; that should only be available to the player robot.
            var aiAmmoChoices: [String] = ammoChoices
            if let idx = aiAmmoChoices.index(of: empGrenadeLabel) {
                aiAmmoChoices.remove(at: idx)
            }
            
            let ammoChoice = randomGen.xorshift_randomgen() % aiAmmoChoices.count
            selectedAmmo = ammoChoices[ammoChoice]    // randomly select ammo for ai robot
            
        }
        
        robotHealth.setReloadTime(timeLapseForReload: (playerInventory.inventoryList[selectedAmmo]?.reloadTime)!)
        
        // increase the ai robot's reload time a little to give the player some chance since it can
        // be a case of one player against many ai robots.
        if playerType == .ai {
            robotHealth.setReloadTime(timeLapseForReload: robotHealth.reloadTime + aiRobotsAddedReloadTime)
        }
        
        // Note: In Scenekit 1.0 means 1.0 meters.  Thus, the default gravity is (0.0, -9.8, 0.0) or 9.8 m/s
        
        robotNode = SCNNode()
        robotDimensions = createRobot(robotName: robotName, zapperEnabled: zapperEnabled, secondLauncherEnabled: secondLauncherEnabled, bunsenBurnerEnabled: bunsenBurnerEnabled)

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
        // if the player's robot has the zapper enabled then we fudge a little bit and move the top of robot up
        // a little to make the aura look better.
        if playerType == .localHumanPlayer && zapperEnabled == true {
            nearTopOfRobotNode.position = SCNVector3(0.0, robotDimensions.height / 2.0 + 0.2, 0.0)
        }
        robotNode.addChildNode(nearTopOfRobotNode)         // add our invisible node to the robotNode.
        
        // Add the zapAuraNode after adding the nearTopOfRobotNode because we use the same position for both.
        var auraRadius: CGFloat = 0.0
        var auraHeight: CGFloat = 0.0
        
        if robotType == .pastrychef {
            auraRadius = pastryChefZapAuraRadius
            auraHeight = pastryChefZapAuraHeight
        }
        // We give the player a different size aura radius because at 3x speed the aura needs to
        // cover the fact that the beam will be slightly behind the center of the robot as it moves.
        else if playerType == .localHumanPlayer {
            auraRadius = playerZapAuraRadius
            auraHeight = defaultZapAuraHeight
        }
        else {
            auraRadius = defaultZapAuraRadius
            auraHeight = defaultZapAuraHeight
        }
        
        // Note: we keep the default eulerAngles orientation the way it is.  That means the
        // cylinder's length will be vertical, hence the 'height' parameter.
        let auraGeometry = SCNCylinder(radius: auraRadius, height: auraHeight)
        zapAuraNode = SCNNode(geometry: auraGeometry)
        zapAuraNode.position = nearTopOfRobotNode.position
        // we leave the color as clear.  When the robot zaps another robot, then the color is changed temporarily.
        zapAuraNode.geometry?.firstMaterial?.diffuse.contents = UIColor.clear
        robotNode.addChildNode(zapAuraNode)
        
        maxYBetweenNearTopAndRobotCenter =  Float(robotDimensions.height) / 2.0 - 0.1  // calculate and save the maximum y difference between the
                                                                                                // the top of the robot and the center.  We will use it later
                                                                                                // to determine if the robot has tipped over by seeing if the
                                                                                                // presentation y difference is <= 50% of this value
        
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
            robotNode.physicsBody!.collisionBitMask = collisionCategoryGround | collisionCategoryWall | collisionCategoryLevelComponent | collisionCategoryAIRobot | collisionCategoryEMPGrenade | collisionCategoryVaultBarrier | collisionCategoryLevelEntrance | collisionCategoryLevelExitDoorway | collisionCategoryVaultDoorway
            // Note: we also set the contactTestBitMask for the vault barrier because we also want to know when contact happens so we can
            // change the color of the force field.
            robotNode.physicsBody!.contactTestBitMask = collisionCategoryAIRobotBakedGood  | collisionCategoryLevelExit | collisionCategoryVault | collisionCategoryVaultBarrier
            robotNode.rotation = robotFacingDirections[north]
        }
        else {
            robotNode.physicsBody!.categoryBitMask = collisionCategoryAIRobot
            robotNode.physicsBody!.collisionBitMask = collisionCategoryGround | collisionCategoryWall | collisionCategoryLevelComponent | collisionCategoryAIRobot | collisionCategoryPlayerRobot | collisionCategoryEMPGrenade | collisionCategoryLevelEntrance | collisionCategoryLevelExitDoorway | collisionCategoryVaultDoorway
            robotNode.physicsBody!.contactTestBitMask = collisionCategoryPlayerRobotBakedGood  | collisionCategoryAIRobotBakedGood | collisionCategoryLevelExit | collisionCategoryVault | collisionCategoryBunsenBurnerFlame
            robotNode.rotation = robotFacingDirections[south]
            
        }
        
        robotNode.physicsBody!.angularVelocityFactor = SCNVector3(0.0, 0.0, 0.0)  // prevent robot from rotating in any direction after collision.
        robotNode.physicsBody!.restitution = 0.0  // don't bounce off of anything.
        robotNode.physicsBody!.mass = CGFloat(robotHealth.mass)     // Don't forget to assign the mass from robotHealth.  Because the masses can be different
                                                            // for different robot we need to assign this once the robot has been created.
        
        // set time of last recovery cycle from a baked good impact.  This starts the clock
        // for the robot to recover at regular intervals from baked good impacts where the robot
        // recovers a set amount each interval.
        lastRecoveryTime = NSDate().timeIntervalSince1970
    }
    
    // Add arms to robot -- should be for just the worker or superworker.  However, that is determined in the createRobot() funciton,
    // not here.  Note: we created a right and left arm with the same starting orientations around the y axis (z axis in blender)
    // but with the arm extension into the body on opposite sides of the arm.  We do this to make it such that we can use the same
    // rotation for raising both arms.  Otherwise, we'd have to adjust one arm to compensate for the 180 degree rotation which gets
    // really knarly to calculate.  It's not a simple 'just rotate around the x axis.'  The current rotation has to be factored
    // into the new rotation.  With a zero vector rotation, the calculation is simple, and works.  This isn't elegant but it works.
    func addArms(loc: SCNVector3, width: Float) {
        leftArmNode = allModelsAndMaterials.leftArmModel.clone()
        leftArmNode.geometry = allModelsAndMaterials.leftArmModel.geometry?.copy() as? SCNGeometry
        leftArmNode.geometry?.firstMaterial = allModelsAndMaterials.leftArmModel.geometry?.firstMaterial?.copy() as? SCNMaterial
        leftArmNode.position = SCNVector3(loc.x - width/2.0, loc.y, loc.z)
        
        rightArmNode = allModelsAndMaterials.rightArmModel.clone()
        rightArmNode.geometry = allModelsAndMaterials.rightArmModel.geometry?.copy() as? SCNGeometry
        rightArmNode.geometry?.firstMaterial = allModelsAndMaterials.rightArmModel.geometry?.firstMaterial?.copy() as? SCNMaterial
        rightArmNode.position = SCNVector3(loc.x + width/2.0, loc.y, loc.z)

        robotNode.addChildNode(leftArmNode)
        robotNode.addChildNode(rightArmNode)
    }
    
    // add bunsen burner and bunsen burner range finder to robot -- player robot only.  The range finder tells the
    // robot when an ai robot is in range of the bunsen burner.
    func addBunsenBurner() {
        bunsenBurnerNode = allModelsAndMaterials.bunsenBurnerModel.clone()
        bunsenBurnerNode.geometry = allModelsAndMaterials.bunsenBurnerModel.geometry?.copy() as? SCNGeometry
        bunsenBurnerNode.geometry?.firstMaterial = allModelsAndMaterials.bunsenBurnerModel.geometry?.firstMaterial?.copy() as? SCNMaterial
        
        bunsenBurnerNode.position = SCNVector3(-0.8, 1.7, 0.5)
        bunsenBurnerNode.name = bunsenBurnerLabel
        robotNode.addChildNode(bunsenBurnerNode)
        
        bunsenBurnerFlameNode = allModelsAndMaterials.bunsenBurnerFlameModel.clone()
        bunsenBurnerFlameNode.geometry = allModelsAndMaterials.bunsenBurnerFlameModel.geometry?.copy() as? SCNGeometry
        bunsenBurnerFlameNode.geometry?.firstMaterial = allModelsAndMaterials.bunsenBurnerFlameModel.geometry?.firstMaterial?.copy() as? SCNMaterial
        bunsenBurnerFlameNode.geometry?.firstMaterial?.transparency = 0.0
        bunsenBurnerFlameNode.position = bunsenBurnerNode.position
        bunsenBurnerFlameNode.position.z = -Float(bunsenBurnerFlameMaximumLength) / 2.0 - 1.8
        
        bunsenBurnerFlameNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: nil)
        bunsenBurnerFlameNode.physicsBody?.categoryBitMask = collisionCategoryBunsenBurnerFlame
        bunsenBurnerFlameNode.physicsBody?.contactTestBitMask = collisionCategoryAIRobot
        robotNode.addChildNode(bunsenBurnerFlameNode)
    }
    
    // raise arms when robot charges to hint that the ai robot is reaching out as it rams the player.
    // Also, create new physics shape that encompasses the raised arms and then change the pivot to
    // center that new physics shape such that it includes the arms but still ends at the back of
    // the robot body.
    func raiseArms() {
        leftArmNode.rotation = SCNVector4(1.0, 0.0, 0.0, Float.pi/2.0)
        rightArmNode.rotation = SCNVector4(1.0, 0.0, 0.0, Float.pi/2.0)
        // we fudge and just add 1.2 meters to the physics shape to represent the extended arms.
        let newRobotNodeShape = SCNPhysicsShape(geometry: SCNBox(width: robotDimensions.width, height: robotDimensions.height, length: robotDimensions.length + 1.2, chamferRadius: 0.0), options: nil)
        robotNode.physicsBody?.physicsShape = newRobotNodeShape
        robotNode.pivot = SCNMatrix4MakeTranslation(0.0, 0.0, -0.6)
    }

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
    
    // get the wheels rolling.  It should happen for all the robots when they're moving.
    //
    func turnWheelsAtNormalSpeed() {
        var speed: CGFloat = 0.0
        
        if playerType == .ai {
            speed = CGFloat(getAIRobotSpeed())
        }
        else {
            speed = CGFloat(getPlayerRobotSpeed())
        }

        // the normal calculations make the wheel turn too slowly so we fudge and multiply by 1.5
        //let turningSpeed = 2.0 * speed / CGFloat(NormalWheelCircumference)
        let turningSpeed = 1.5 * speed / CGFloat(normalWheelCircumference)
        let leftWheelTurnAction = SCNAction.rotateBy(x: 0.0, y: -turningSpeed, z: 0.0, duration: 1.0)
        let leftWheelTurnActionForever = SCNAction.repeatForever(leftWheelTurnAction)
        let leftWheelTurnSequence = SCNAction.sequence([leftWheelTurnActionForever])
        let rightWheelTurnAction = SCNAction.rotateBy(x: 0.0, y: turningSpeed, z: 0.0, duration: 1.0)
        let rightWheelTurnActionForever = SCNAction.repeatForever(rightWheelTurnAction)
        let rightWheelTurnSequence = SCNAction.sequence([rightWheelTurnActionForever])
        
        leftWheelNode.runAction(leftWheelTurnSequence, forKey: leftWheelTurnActionKey)
        rightWheelNode.runAction(rightWheelTurnSequence, forKey: rightWheelTurnActionKey)
    }
    
    // Turn off wheel turning by removing the actions.  Primarily for the player's robot.
    func stopTurningWheels() {
        leftWheelNode.removeAction(forKey: leftWheelTurnActionKey)
        rightWheelNode.removeAction(forKey: rightWheelTurnActionKey)
    }

    // speed up wheel turning by a certain amount.  Mainly for the player robot.
    func speedUpWheels(xspeedup: Int) {
        var speed: CGFloat = 0.0
        
        if playerType == .ai {
            speed = CGFloat(getAIRobotSpeed())
        }
        else {
            speed = CGFloat(getPlayerRobotSpeed())
        }
        // the normal calculations make the wheel turn too slowly so we fudge and multiply by 2.0
        let turningSpeed = 2.0 * CGFloat(xspeedup) * speed / CGFloat(normalWheelCircumference)
        
        let leftWheelTurnAction = SCNAction.rotateBy(x: 0.0, y: -turningSpeed, z: 0.0, duration: 1.0)
        let leftWheelTurnActionForever = SCNAction.repeatForever(leftWheelTurnAction)
        let leftWheelTurnSequence = SCNAction.sequence([leftWheelTurnActionForever])
        let rightWheelTurnAction = SCNAction.rotateBy(x: 0.0, y: turningSpeed, z: 0.0, duration: 1.0)
        let rightWheelTurnActionForever = SCNAction.repeatForever(rightWheelTurnAction)
        let rightWheelTurnSequence = SCNAction.sequence([rightWheelTurnActionForever])
        
        // Note: by using the key we overwrite the action that was in place already.  This is how we're able
        // to speed up the wheels without removing the old action and starting a new one.
        leftWheelNode.runAction(leftWheelTurnSequence, forKey: leftWheelTurnActionKey)
        rightWheelNode.runAction(rightWheelTurnSequence, forKey: rightWheelTurnActionKey)
    }
    
    func createRobot(robotName: String, zapperEnabled: Bool, secondLauncherEnabled: Bool, bunsenBurnerEnabled: Bool) -> RobotDimensions {
        var robotDimensions = RobotDimensions(width: 1.5, height: 3.3, length: 1.0)
        
        recoveryScalarForce = defaultRobotRecoveryScalarForce   // set default recovery scalar force -- should be set upon Robot object creation but
                                                                // we set it here just in case.
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
                zapColor = playerZapColor
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
            if bunsenBurnerEnabled == true  {
                addBunsenBurner()
            }
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
                withinReachDistance = maximumWorkerAIRobotLungeReach
                robotDimensions = RobotDimensions(width: 3.4, height: 5.0, length: 1.5)
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
                aiRobotHomingRange = mediumAIRobotHomingRange
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
                aiRobotThrowingRange = mediumAIRobotThrowingRange
                aiRobotHomingRange = mediumAIRobotHomingRange
                robotHealth.setReloadTime(timeLapseForReload: robotHealth.reloadTime / 2.0)   // reload in half the time to 'double' the firepower
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
                aiRobotThrowingRange = mediumAIRobotThrowingRange
                aiRobotHomingRange = mediumAIRobotHomingRange
                robotHealth.setReloadTime(timeLapseForReload: robotHealth.zapReloadTime * 2.0)
                robotDimensions = RobotDimensions(width: 2.0, height: 5.0, length: 2.0)
                zapColor = zapperZapColor
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
                withinReachDistance = maximumSuperWorkerAIRobotLungeReach
                aiRobotHomingRange = mediumAIRobotHomingRange
                
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
                robotHealth.multiplyBurnResistance(by: 3.0)
                robotHealth.multiplyCorrosionResistance(by: 3.0)
                robotHealth.multiplyMass(by: 3.0)
                robotHealth.multiplyStaticDischargeResistance(by: 3.0)
                recoveryScalarForce *= 3.0
                robotDimensions = RobotDimensions(width: 2.8, height: 6.8, length: 1.5)
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
                aiRobotThrowingRange = maximumAIRobotThrowingRange
                aiRobotHomingRange = mediumAIRobotHomingRange
                robotHealth.setReloadTime(timeLapseForReload: robotHealth.reloadTime / 2.0)   // reload in half the time to 'double' the firepower
                
                // Double resistance for the superbaker.  The player can't at this
                // point do a static discharge but we raise it anyway.  Besides, the homing and
                // ghost robots can and they will affect other ai robots.  It might be
                // a fun surprise for the player to see that this robot also survives an EMP.
                // Note: we don't change mobility.  We leave it the way it is.  The player can
                // slow them down as normal, even if they can't destroy them as easily.  Don't
                // want to make things too hard.
                // Note: we directly change the robot health here as these are not powerUps that
                // go away after a time like what the player experiences but are really health
                // enhancements.
                robotHealth.multiplyBurnResistance(by: 3.0)
                robotHealth.multiplyCorrosionResistance(by: 3.0)
                robotHealth.multiplyMass(by: 3.0)
                robotHealth.multiplyStaticDischargeResistance(by: 3.0)
                recoveryScalarForce *= 3.0

                launcherNode = allModelsAndMaterials.ailauncherModel.clone()
                launcherNode.geometry = allModelsAndMaterials.ailauncherModel.geometry?.copy() as? SCNGeometry
                launcherNode.geometry?.firstMaterial = allModelsAndMaterials.ailauncherModel.geometry?.firstMaterial?.copy() as? SCNMaterial
                launcherNode.scale = SCNVector3(1.5, 1.0, 1.5)
                launcherNode.position.y = 0.9
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
                aiRobotHomingRange = maximumAIRobotHomingRange
                withinReachDistance = maximumAIRobotBlastRadius
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
                aiRobotHomingRange = maximumAIRobotHomingRange
                withinReachDistance = maximumAIRobotBlastRadius
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
                aiRobotThrowingRange = maximumAIRobotThrowingRange
                aiRobotHomingRange = maximumAIRobotHomingRange
                robotHealth.setReloadTime(timeLapseForReload: robotHealth.reloadTime / 2.0)   // reload in half the time to 'double' the firepower
                robotHealth.multiplyBurnResistance(by: 5.0)
                robotHealth.multiplyCorrosionResistance(by: 5.0)
                robotHealth.multiplyMass(by: 5.0)
                robotHealth.multiplyStaticDischargeResistance(by: 5.0)
                recoveryScalarForce *= 5.0
                launcherNode = allModelsAndMaterials.ailauncherModel.clone()
                launcherNode.geometry = allModelsAndMaterials.ailauncherModel.geometry?.copy() as? SCNGeometry
                launcherNode.geometry?.firstMaterial = allModelsAndMaterials.ailauncherModel.geometry?.firstMaterial?.copy() as? SCNMaterial
                launcherNode.scale = SCNVector3(1.5, 1.0, 1.5)
                launcherNode.position.y = 1.0
                robotNode.addChildNode(launcherNode)
                robotDimensions = RobotDimensions(width: 3.4, height: 8.3, length: 3.4)
                zapColor = pastryChefZapColor
            default:
                break
            }
            // Add the name of the robot as a label just above it.  This is for debugging purposes only so
            // that we can associate the behavior we see in gameplay with the console messages we print to
            // explain what a robot is supposed to be doing.  However, we should save this for later and use it
            // possibly as name for a robot that has a face attached.
            /*
            if robotNode != nil {
                let robotLabelGeometry = SCNText(string: robotNode.name, extrusionDepth: 0.2)
                // Use Helvetica font and only make the text 1.0 meters in height.  Default is 36--read that somewhere.
                robotLabelGeometry.font = UIFont(name: "Helvetica", size: 1.0)
                robotLabelNode = SCNNode(geometry: robotLabelGeometry)
                robotLabelNode.eulerAngles = SCNVector3(0.0, 0.0, 0.0)
                robotLabelNode.geometry?.firstMaterial?.diffuse.contents = convertStateToTextColor()
                // Note: the label isn't added as a subnode of the robot.  Instead we leave it as a free agent because
                // we just want it to follow the robot, not turn with it.  In order to do that we would have to add it
                // to the world instead of the robot
            }
            */
        }
        return robotDimensions
    }
    
    // withinReachDistance is set with a default in createRobot().  Here we update that distance with a different
    // value.  This is useful for the bloodhound and ghost robots to make sure they get closer to the player
    // before going off.  And we can vary that distance by updating it this way.  It's kludgy but works.
    func updateWithinReachDistance(withinReachDistance: Float) {
        self.withinReachDistance = withinReachDistance
    }
    
    // By default we turn off the force effects when the robot is created. But we turn them
    // back on under special conditions, like when they've been hit by a massive baked good
    // that should knock them over.
    func turnOnForceEffects() {
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
    
    // turn on and off the aura.  Note that we use self in the functions because we may use one or the other in the
    // completion handler of an action.
    func turnOnAura() {
        self.zapAuraNode.geometry?.firstMaterial?.diffuse.contents = zapColor
    }
    
    func turnOffAura() {
        self.zapAuraNode.geometry?.firstMaterial?.diffuse.contents = UIColor.clear
    }
    
    // create zap, sparks or deathray.  For now, only AI robots do it -- 2017-04-07
    // Note: we call it a zap bolt because it's just a straight beam.  We reserve lightning
    // bolt for the pastry chef robot.
    func createZapBolt(targetPoint: SCNVector3) -> SCNNode {
        let deltax = (targetPoint.x - robotNode.presentation.position.x)
        let deltaz = (targetPoint.z - robotNode.presentation.position.z)
        let zapLength = sqrt(deltax*deltax + deltaz*deltaz)
        var zapGeometry: SCNGeometry!
        
        if robotType == .pastrychef {
            zapGeometry = SCNCylinder(radius: 0.3, height: CGFloat(zapLength))
        }
        else {
            zapGeometry = SCNCylinder(radius: 0.05, height: CGFloat(zapLength))
        }
        
        var horizontalAngleOfDischarge = asin(deltax/zapLength)
        
        // When the player is in front of the ai robot, the angle needs to be reverse.
        // Still not sure why that is.
        if targetPoint.z < robotNode.presentation.position.z {
            horizontalAngleOfDischarge = -horizontalAngleOfDischarge
        }
        
        let zapNode = SCNNode(geometry: zapGeometry)
        // get the nearTopOfRobotNode in world coordinates - we borrowed this from our adjustImpactRecovery()
        // function.
        let nWT = self.nearTopOfRobotNode.presentation.worldTransform
        let robotTop = SCNVector3(nWT.m41, nWT.m42, nWT.m43)
        let zapYLoc = (Float(robotTop.y) - targetPoint.y) / 2.0 + targetPoint.y
        zapNode.name = zapLabel + String(robotNumber)
        
        // the atan calculated is the angle from the horizontal downward.  So we add pi/2, which would
        // be the horizontal angle, to get the downward zap from the top of the robot to the target.
        // Note: we have to keep track of where the zapping robot is with respect to the target robot.
        // if the zapping robot is towards the camera and the target is further away, then we use
        // -atan.  If the zapping robot is farther away from the camera than the target, then we use
        // atan. Otherwise the robot zaps from its center toward the target's head; the angle is
        // backwards, in other words.
        var verticalAngleOfDischarge: Float = 0.0
        if robotTop.z > targetPoint.z {
            verticalAngleOfDischarge = -atan((robotTop.y - targetPoint.y)/zapLength) + Float.pi/2.0
        }
        else {
            verticalAngleOfDischarge = atan((robotTop.y - targetPoint.y)/zapLength) + Float.pi/2.0
        }
        
        zapNode.eulerAngles = SCNVector3(Double(verticalAngleOfDischarge), Double(horizontalAngleOfDischarge), 0.0)
        zapNode.position = SCNVector3(targetPoint.x - deltax/2.0, zapYLoc, targetPoint.z - deltaz/2.0)
        zapNode.geometry?.firstMaterial?.diffuse.contents = zapColor
        return zapNode
    }
        
    // Robot, AI or Player, hurls baked good.
    func hurlBakedGood(targetPoint: SCNVector3, targetLastPoint: SCNVector3, targetVelocity: SCNVector3, name: String, numThrowsThatShouldMiss: Int, randomGen: RandomNumberGenerator, levelNum: Int) -> BakedGood {
        let startpoint = robotNode.presentation.position
        var bakedGood: BakedGood!
        var robotThrowingBehavior: RobotThrowingBehavior = .throwToHitTarget
        var throwingForcePowerUpUsed: Bool = false
        
        throwCount += 1    // a baked good is being thrown so we increment the count.  This helps us determine of the
                           // throw should be accurate or not if the robot is an ai robot.
        
        // Note: we add +1 to the numThrowsThatShouldMiss to include the one throw that should _not_ miss.  That way we cover
        // all the bases--the throws that miss and the ones that don't.  Also, this prevents a % 0 condition, which will generate
        // an exception because it's a division by zero error.
        // Also note that the if condition is somewhat redundant.  If the player is throwing a baked good the numThrowsThatShouldMiss
        // passed to this function should be zero and only the throwing robots should be throwing anything but we make doubly sure
        // that this is the case.  There is a slight error with this, however, and that is that if the player type is ai and
        // the robotType is not a baker, doublebaker, superbaker or pastry chef then the robot always hits its target.
        // However, non throwing robots should _never_ call this function.
        if playerType == .ai && (robotType == .baker || robotType == .doublebaker || robotType == .superbaker || robotType == .pastrychef) && throwCount % (numThrowsThatShouldMiss + 1) != 0 {
            robotThrowingBehavior = .missTarget
            throwingForcePowerUpUsed = false
        }
        else {
            if playerType == .ai {
                throwingForcePowerUpUsed = false
            }
            else if robotHealth.powerUpEnabled == true && robotHealth.powerUpType ==  .throwingForcePowerUp {
                throwingForcePowerUpUsed = true
            }
            robotThrowingBehavior = .throwToHitTarget
        }
        
        bakedGood = BakedGood(startpoint: startpoint, targetPoint: targetPoint, targetLastPoint: targetLastPoint, targetVelocity: targetVelocity, hurlingSpeed: getRobotThrowingSpeed(), bakedGoodName: name, whoThrewIt: robotNode.name!, playerType: playerType, ammoUsed: playerInventory.inventoryList[selectedAmmo]!, robotDimensions: robotDimensions, robotThrowingBehavior: robotThrowingBehavior, randomGen: randomGen, throwingForcePowerUpUsed: throwingForcePowerUpUsed)

        // Note: even though we turn the launcher elsewhere we also turn it here such that the launcher is instantly updated
        // to the direction of the launch when the baked good is thrown.  This should keep it looking right for the most
        // part when the baked good goes flying.
        turnLauncherInDirectionOfLaunch(targetPoint: targetPoint)

        /* We apply the launcher rotation to the angular velocity we want to get the baked good rotating towards the
        target.   We do this with the code below, which isn't intuitively obvious.  Our rationale for the code:
         
         First we take the angle of rotation that is the launcher's angle of rotation and
         make that the direction of the throw, since that is what it is.
         Next we assume that that direction is the hypotenuse of a right triangle
         where the angle is that angle of direction and the hypotenuse is just 1.  Then if phi is that angle,
         we have:
         
         sin(phi) = x/1
         cos(phi) = z/1
         
         We use the z axis as our x axis and the x axis as our z axis, which would
         be in line for the coordinate system in SceneKit and how things start out.
         
         Now in our thinking since phi is the direction of the throw/launch, then
         90 degrees + phi would be the axis perpendicular to the direction of the throw.
         If we let theta be 90 degrees + phi, then:
         
         sin(theta) = x/1 = the amount of angular velocity we would apply around the x axis = avX
         cos(theta) = z/1 = the amount of angular velocity we would apply around the z axis = avZ
         
         And then if we have a speed s we want to apply, like pi/2.0, then
         
         angularVelocityAroundXAxis = avX * s
         angularVelocityAroundZAxis = avZ * s
         
         And it looks like we were close.  It appears that we have to take into account the
         direction of the robot because that also influences the direction of the launcher rotation and
         apply pi/2 if going North, 3*pi/2 if going south, nothing if going east and pi if going west.
         
         This seems to work:
        */
        let bakedGoodDirectionAngle = launcherNode.rotation.w
        var bakedGoodRotationAxis: Float = 0.0
        var directionOfAngularVelocity: Float = 1.0        // either spin forward or backward, depending on the
                                                            // the direction the robot is traveling.
        
        // This could be erroneous--probably is--but we assume that the ZeroDirection is the player robot
        // facing north but not moving.  It does have other uses with the ai robots when they are stopped
        // by a fixed level component but I'm guessing, and it's probably a wrong guess, that those conditions
        // hardly exist.
        // Note:  The directionOfAngularVelocity was obtained through trial and error.  We saw that when the
        // robot was moving east-west that the direction needed to be positive.  When the robot was going
        // north-south we noticed that the direction needed to be going negative.  I have some idea why but
        // am not nearly 100% positive on that.  We just know that the values below work for those conditions.
        if currentDirection == north || currentDirection == zeroDirection {
            bakedGoodRotationAxis = bakedGoodDirectionAngle + Float.pi / 2.0
            directionOfAngularVelocity = -1.0                    // spin in opposite direction.
        }
        else if currentDirection == south {
            bakedGoodRotationAxis = bakedGoodDirectionAngle + 3.0 * Float.pi / 2.0
            directionOfAngularVelocity = -1.0                    // spin in opposite direction.
        }
        else if currentDirection == east {
            bakedGoodRotationAxis = bakedGoodDirectionAngle
            directionOfAngularVelocity = 1.0                    // spin in forward direction.
        }
        else if currentDirection == west {
            bakedGoodRotationAxis = bakedGoodDirectionAngle + Float.pi
            directionOfAngularVelocity = 1.0                    // spin in forward direction.
        }
        let bakedGoodAngularVelocityAroundXAxis = sin(bakedGoodRotationAxis)
        let bakedGoodAngularVelocityAroundZAxis = cos(bakedGoodRotationAxis)
        //bakedGood.bakedGoodNode.physicsBody!.angularVelocity = SCNVector4(bakedGoodAngularVelocityAroundXAxis, 0.0, bakedGoodAngularVelocityAroundZAxis, directionOfAngularVelocity * 2 * Float.pi)
        bakedGood.bakedGoodNode.physicsBody!.angularVelocity = SCNVector4(bakedGoodAngularVelocityAroundXAxis, 0.0, bakedGoodAngularVelocityAroundZAxis, directionOfAngularVelocity * Float.pi / 2.0)
        return bakedGood
    }
    
    // based on the direction that the robot is going, the angle direction of rotation is either positive or negative.
    // For example, when the robot is going north, if the player taps in a location where xtap is less than robot's x
    // location, then the angle direction of rotation is positive.  However, if the location of xtap is greater than
    // the robot's x location, then the angle direction of rotation is negative.  In the positive case, we would just
    // return 1.0.  In the negative case we would return -1.0.  Note: We pass the robot direction rather than using the
    // attribute because of the case where a robot may have ZeroDirection but facing in a certain direction, like when
    // the player's robot is starting out in the level.  It is facing north but not moving, and has a current direction
    // of ZeroDirection.  Unfortunately, this is kind of legacy thing where we use ZeroDirection to determine that a robot
    // is stopped.  We should probably do something different at some point but it's too late to do anything different now.
    // The same criteria applies to the ai robots so we call the location targetLoc, not tap3DLoc.
    func getAngleDirectionOfRotation(targetLoc: SCNVector3, robotDirection: Int) -> Float {
        let robotLoc = robotNode.presentation.position
        var directionOfRotation: Float = 1.0      // default to positive.
        
        if (targetLoc.x - robotLoc.x > 0.0 && robotDirection == north) || (targetLoc.x - robotLoc.x < 0.0 && robotDirection == south) || (targetLoc.z - robotLoc.z < 0.0 && robotDirection == east) || (targetLoc.z - robotLoc.z > 0.0 && robotDirection == west) {
            directionOfRotation  = -1.0
        }
        
        return directionOfRotation
    }
    
    // when a baked good or emp grenade is launched/thrown we want to turn the launcher in the direction of
    // that launch to make it look right.  Or we want to turn the launcher into the direction where the baked
    // good will be launched.  This is particularly the case for the ai robots, whose launchers will track the player.
    // getRotationForLauncherToPointTowardTarget() fives is the angle we need to do this.
    func getRotationForLauncherToPointTowardTarget(targetPoint: SCNVector3) -> SCNVector4 {
        var directionOfRotation: Float = 1.0    // the direction of rotation for the angle of rotation, default is positive.
        var launcherTurnAngle: Float = 0.0      // the magnitude of the angle that the launcher will turn.
        
        let deltax = targetPoint.x - robotNode.presentation.position.x
        let deltay = targetPoint.y - robotNode.presentation.position.y
        let deltaz = targetPoint.z - robotNode.presentation.position.z
        
        let distanceToTarget = calcDistance(p1: robotNode.presentation.position, p2: targetPoint)
        let targetUnitVector = SCNVector3(deltax/distanceToTarget, deltay/distanceToTarget, deltaz/distanceToTarget)
        
        if areSCNVect3NearlyEqual(v1: currentVelocity, v2: notMoving, nearnessFactor: 0.001) == true {
            // code borrowed from the updateDirectionAndVelocity() function to set a velocity
            // vector if the robot had been moving in the direction it's facing.  This prevents the
            // launcher from disapearing when the robot stops and a baked good is thrown.
            var speed: Float = 0.0
            var velocityIfRobotWereMoving: SCNVector3 = SCNVector3(0.0, 0.0, 0.0)
            if playerType == .ai {
                speed = getAIRobotSpeed()
            }
            else {
                speed = getPlayerRobotSpeed()
            }
            if currentDirection == zeroDirection {
                // we assume that the direction is north if it is ZeroDirection - the start of the level and
                // the player is facing north.  Note: this is kludgy and it is possible for other instances to
                // lead to a ZeroDirection direction but for the moment only the player starts off in ZeroDirection
                // but is facing north.
                velocityIfRobotWereMoving.x = robotMovingDirections[north].x * speed
                velocityIfRobotWereMoving.z = robotMovingDirections[north].z * speed
                velocityIfRobotWereMoving.y = robotMovingDirections[north].y
                directionOfRotation = getAngleDirectionOfRotation(targetLoc: targetPoint, robotDirection: north)
            }
            else {
                velocityIfRobotWereMoving.x = robotMovingDirections[currentDirection].x * speed
                velocityIfRobotWereMoving.z = robotMovingDirections[currentDirection].z * speed
                velocityIfRobotWereMoving.y = robotMovingDirections[currentDirection].y
                directionOfRotation = getAngleDirectionOfRotation(targetLoc: targetPoint, robotDirection: currentDirection)
            }
            launcherTurnAngle = angleBetweenTwoVectors(v1: velocityIfRobotWereMoving, v2: targetUnitVector)
        }
        else {
            directionOfRotation = getAngleDirectionOfRotation(targetLoc: targetPoint, robotDirection: currentDirection)
            launcherTurnAngle = angleBetweenTwoVectors(v1: currentVelocity, v2: targetUnitVector)
        }
        // Finally, after we've gotten the turn angle and the direction of the turn, we assign that rotation to the launcher
        //launcherNode.rotation = SCNVector4(0.0, 1.0, 0.0, directionOfRotation * launcherTurnAngle)
        let rotationForLauncher = SCNVector4(0.0, 1.0, 0.0, directionOfRotation * launcherTurnAngle)
        return rotationForLauncher
    }
    
    func turnLauncherInDirectionOfLaunch(targetPoint: SCNVector3) {
        let newRotationOfLauncher = getRotationForLauncherToPointTowardTarget(targetPoint: targetPoint)
        launcherNode.rotation = newRotationOfLauncher
    }
    
    func hurlEMPGrenade(targetPoint: SCNVector3, name: String, whoThrewIt: String) -> EMPGrenade {
        let startpoint = robotNode.presentation.position
        var empGrenade: EMPGrenade!
        
        empGrenade = EMPGrenade(startingPoint: startpoint, targetPoint: targetPoint, hurlingSpeed: getRobotThrowingSpeed(), empGrenadeName: name, whoThrewIt: whoThrewIt, robotDimensions: robotDimensions)
        
        // Note: even though we turn the launcher elsewhere we also turn it here such that the launcher is instantly updated
        // to the direction of the launch when the emp grenade is thrown.  This should keep it looking right for the most
        // part when the emp grenade goes flying.
        turnLauncherInDirectionOfLaunch(targetPoint: targetPoint)
        return empGrenade
        
    }
    
    // we generate a puff of steam to launch the baked good or emp grenade.  In reality it is there just for show but
    // our goal is to make it look like the baked good is launched from the launcher.
    // From https://stackoverflow.com/questions/44186179/rotation-along-world-axis we get that
    // we can apply a rotation to a world transform with much effort.
    func generatePuffOfSteam(launchPoint: SCNVector3) -> SCNNode {
        
        // This is copied from the hurlBakedGood() function above to calculate the puff of steam's
        // rotation around an xz axis that makes it look like the robot is firing off a beked good
        // at an angle
        
        let puffOfSteamDirectionAngle = launcherNode.rotation.w
        var puffOfSteamRotationAxis: Float = 0.0
        var directionOfAngle: Float = 1.0        // either spin forward or backward, depending on the
        // the direction the robot is traveling.
        
        // This could be erroneous--probably is--but we assume that the ZeroDirection is the player robot
        // facing north but not moving.  It does have other uses with the ai robots when they are stopped
        // by a fixed level component but I'm guessing, and it's probably a wrong guess, that those conditions
        // hardly exist.
        // Note:  The directionOfAngularVelocity was obtained through trial and error.  We saw that when the
        // robot was moving east-west that the direction needed to be positive.  When the robot was going
        // north-south we noticed that the direction needed to be going negative.  I have some idea why but
        // am not nearly 100% positive on that.  We just know that the values below work for those conditions.
        if currentDirection == north || currentDirection == zeroDirection {
            puffOfSteamRotationAxis = puffOfSteamDirectionAngle + Float.pi / 2.0
            directionOfAngle = -1.0                    // spin in opposite direction.
        }
        else if currentDirection == south {
            puffOfSteamRotationAxis = puffOfSteamDirectionAngle + 3.0 * Float.pi / 2.0
            directionOfAngle = -1.0                    // spin in opposite direction.
        }
        else if currentDirection == east {
            puffOfSteamRotationAxis = puffOfSteamDirectionAngle
            directionOfAngle = 1.0                    // spin in forward direction.
        }
        else if currentDirection == west {
            puffOfSteamRotationAxis = puffOfSteamDirectionAngle + Float.pi
            directionOfAngle = 1.0                    // spin in forward direction.
        }
        let puffOfSteamAngleAroundXAxis = sin(puffOfSteamRotationAxis)
        let puffOfSteamAngleAroundZAxis = cos(puffOfSteamRotationAxis)
        
        let steamCloudNode = allModelsAndMaterials.puffOfSteamModel.clone()
        steamCloudNode.geometry = allModelsAndMaterials.puffOfSteamModel.geometry?.copy() as? SCNGeometry
        steamCloudNode.geometry?.firstMaterial = allModelsAndMaterials.puffOfSteamModel.geometry?.firstMaterial!.copy() as? SCNMaterial
        
        steamCloudNode.categoryBitMask = categorySteamCloud         // set the category bit mask to this; later hittest will just ignore nodes that
                                                                    // have this set (because right now it will ignore any node that does not have
                                                                    // its categoryBitMask set to CategoryRegisterInHitTest so a tap on an area with
                                                                    // the steam cloud in it will have the effect of ignoring the steam cloud.  We want
                                                                    // this as the steam cloud is often the closest object when a tap is done and if we
                                                                    // use it as a location to throw a baked good then the baked good goes towards the
                                                                    // player viewing the game rather than towards the intended target point in the level.
        steamCloudNode.geometry?.firstMaterial?.transparency = 0.9
        steamCloudNode.position = launchPoint
        // through trial and error we see that -5pi/8 is about the correct angle for the puff of steam to make it look right.
        steamCloudNode.rotation = SCNVector4(puffOfSteamAngleAroundXAxis, 0.0, puffOfSteamAngleAroundZAxis, directionOfAngle * -5.0 * Float.pi / 8.0)
        
        return steamCloudNode
        
    }
    
    // The number of launchers = number of values we keep to track the timeReloadStarted.
    // It's a little obfuscated but makes sense.  We don't actually have a launchers array
    // but an array of timeReloadStarted variables and it is that array that is updated.
    func updateNumberOfLaunchers(items: [String]) {
        for anItem in items {
            if anItem.range(of: anotherLauncherLabel) != nil {
                timeReloadStarted.append(launcherReadyToFire)    // add another time reload started variable to our list
                                                                 // to signify that the player has added another launcher to his/her robot.
            }
        }
    }
    
    // When player chooses different ammo to use, then update it here.   Also update the reload time as that will
    // be affected.  And reset all the timeReloadStarted variables to 0.0 to start them fresh.
    func updateSelectedAmmo(ammoSelected: String) {
        selectedAmmo = ammoSelected
        robotHealth.setReloadTime(timeLapseForReload: (playerInventory.inventoryList[selectedAmmo]?.reloadTime)!)
        for i in 0...timeReloadStarted.count - 1 {
            timeReloadStarted[i] = launcherReadyToFire
        }
    }
        
    // Also, only for AI robots.
    // Is the player robot in range of robots that can throw baked goods.
    func isPlayerRobotInThrowingRange(playerRobotLoc: LevelCoordinates) -> Bool {
        var playerRobotInRange = false
        
        let distance = calcDistanceLevelCoords(p1: levelCoords, p2: playerRobotLoc)
        
        if distance < aiRobotThrowingRange {
            playerRobotInRange = true
        }
        return playerRobotInRange
    }

    // Also, only for AI robots.
    // Is the player robot in range of ai robots that can home in on it.
    func isPlayerRobotInHomingRange(playerRobotLoc: LevelCoordinates) -> Bool {
        var playerRobotInRange = false
        
        let distance = abs(levelCoords.row - playerRobotLoc.row)
        
        if distance < aiRobotHomingRange {
            playerRobotInRange = true
        }
        return playerRobotInRange
    }
    
    // Is player within arm's reach of workers or within blast radius of exploding robots?
    func isPlayerWithinReach(playerLoc: SCNVector3) -> Bool {
        var isWithinReach: Bool = false
        
        if robotType == .worker || robotType == .superworker || robotType == .homing || robotType == .ghost {
            if calcDistance(p1: playerLoc, p2: robotNode.presentation.position) <= withinReachDistance {
                isWithinReach = true
            }
        }
        return isWithinReach
    }
    
    // check to see if there's an obstruction at a specific coordinate in the level grid.  This
    // is useful for determining if there is anything in the line-of-sight path between the ai robot
    // and the player.
    func checkCoordinateForPathObstruction(levelGridSpace: [String], componentsDictionary: [String: LevelComponentType]) -> Int {
        var pathInfo: Int = 0
        
        let toExclude: Set<LevelComponentType> = [.airobot, .playerrobot, .nocomponent, .hole, .emptyspace, .part, .powerup]
        for element in levelGridSpace {
            let type = getLevelComponentType2(levelComponentName: element, componentsDictionary: componentsDictionary)
            if !toExclude.contains(type) {
                pathInfo |= pathIsNotEmpty
            }
        }
        return pathInfo
    }

    // check a segment of the path between row and nextRow and col and nextCol to see if there is anything
    // in that segment that blocks the shot totally, or partially, from the ai robot to the player.  We use
    // the equation y = mx + b to determine the slope of the line, in level coordinates, from the ai robot to
    // the player robot. However, we do see that the slope m can be 2 or more, which causes us to skip level
    // coordinates.  This function covers that gap by looking at the block of level coordinates between
    // y1 = mx1 + b and y2 = mx2 + b.
    func checkForPathObstruction(coord: LevelCoordinates, nextCoord: LevelCoordinates, levelGrid: [[[String]]], componentsDictionary: [String : LevelComponentType]) -> Int {
        var startRow: Int = 0; var endRow: Int = 0; var startCol: Int = 0; var endCol: Int = 0
        var pathInfo: Int = 0
        
        // first establish the starting and ending rows and columns to use
        // when we get to going through the block of level coordinates looking
        // for non-robot elements in them.  This is just a doublecheck to make sure
        // that we go from min to max for both row and column.
        if coord.row < nextCoord.row {
            startRow = coord.row; endRow = nextCoord.row
        }
        else {
            startRow = nextCoord.row; endRow = coord.row
        }
        if coord.column < nextCoord.column {
            startCol = coord.column; endCol = nextCoord.column
        }
        else {
            startCol = nextCoord.column; endCol = coord.column
        }
        
        // finally, search through block of level coordinates for any obstructions
        // However, if any of the start and end row or column values are less than 0, then don't check at
        // all because we don't want to risk crashing due to trying to look at a row,column that's outside
        // of the levelGrid matrix and any row or column that is negative is always outside of the matrix
        // which goes from 0,0 ... max,max, always.
        if startRow >= 0 && endRow >= 0 && startCol >= 0 && endRow >= 0 {
            if startRow <= endRow && startCol <= endCol {
                for aRow in startRow...endRow {
                    for aCol in startCol...endCol {
                        pathInfo |= checkCoordinateForPathObstruction(levelGridSpace: levelGrid[aRow][aCol], componentsDictionary: componentsDictionary)
                    }
                }
            }
        }
        return pathInfo
    }
    
    // for ramming, the ai robot only.  We return zero direction if the path isn't clear or if neither the rows nor the columns are
    // the same for the ai robot and player robot.  We want ramming to occur only in the east, west, north, south directions, not
    // in any angular directions.  That way it is consistent with the ai robots' movements and also is easier to eliminate any path
    // where there is a fixed level component or wall element in the way.
    func directionForRamming(robotLoc: LevelCoordinates, robotSceneLoc: SCNVector3, levelGrid: [[[String]]], fixedLevelComponents: [String : FixedLevelComponent], componentsDictionary: [String : LevelComponentType]) -> Int {
        var pathInfo: Int = pathClear
        var direction: Int = zeroDirection
        
        // Only consider the player a target if it is east, west, north, or south of the ai robot.  A check for range is
        // done elsewhere.  We just check if the path is clear here.
        if robotLoc.row == levelCoords.row {
            var startCol: Int = 0
            var endCol: Int = 0
            
            if robotLoc.column <= levelCoords.column {
                startCol = robotLoc.column
                endCol = levelCoords.column
                direction = east
            }
            else {
                startCol = levelCoords.column
                endCol = robotLoc.column
                direction = west
            }
            for aCol in startCol...endCol {
                pathInfo |= checkCoordinateForPathObstruction(levelGridSpace: levelGrid[robotLoc.row][aCol], componentsDictionary: componentsDictionary)
            }
        }
        else if robotLoc.column == levelCoords.column {
            var startRow: Int = 0
            var endRow: Int = 0
            
            if robotLoc.row <= levelCoords.row {
                startRow = robotLoc.row
                endRow = levelCoords.row
                direction = south
            }
            else {
                startRow = levelCoords.row
                endRow = robotLoc.row
                direction = north
            }
            for aRow in startRow...endRow {
                pathInfo |= checkCoordinateForPathObstruction(levelGridSpace: levelGrid[aRow][robotLoc.column], componentsDictionary: componentsDictionary)
            }
        }

        // Note: direction will already be ZeroDirection if the rows are not the same and the columns are not
        // the same.  This check in case the rows are the same or the columns are the same and the path was
        // check to see if it is clear.
        if pathInfo != pathClear {
            direction = zeroDirection       // Path is not clear so we return ZeroDirection to signify that.
        }
        
        return direction
    }

    // Get info on whether or not the path between the ai robot and the player robot is
    // cleared, totally obscured because of walls, or blocked directly because of other
    // elements such as other robots or fixed level components in the way.
    func lineOfSightPath(robotLoc: LevelCoordinates, levelGrid: [[[String]]], componentsDictionary: [String : LevelComponentType]) -> Int {
        var pathInfo: Int = 0
        
        if levelCoords.row == robotLoc.row && levelCoords.column == robotLoc.column {
            // In this case there is only one space to check--the one they're both in.  For now we just check that if there is
            // a fixed level component in the same space and if so say they're not in line of sight of each other.  Technically,
            // it should only be the case if they're in the same space with the fixed level component _and_ that fixed level
            // component is in between them but that's more logic than I want to do right now.  We'll do that if there's time later -- nlb, 2017-07-27
            pathInfo |= checkCoordinateForPathObstruction(levelGridSpace: levelGrid[levelCoords.row][levelCoords.column], componentsDictionary: componentsDictionary)
        }
        else if levelCoords.row == robotLoc.row {
            var startCol: Int = levelCoords.column
            var endCol: Int = robotLoc.column
            
            if startCol > endCol {
                let tmp = endCol
                endCol = startCol
                startCol = tmp
            }
            for colStep in startCol...endCol - 1 {
                let coord = LevelCoordinates(row: levelCoords.row, column: colStep)
                let nextCoord = LevelCoordinates(row: levelCoords.row, column: colStep + 1)
                pathInfo |= checkForPathObstruction(coord: coord, nextCoord: nextCoord, levelGrid: levelGrid, componentsDictionary: componentsDictionary)
            }
            
        }
        else if levelCoords.column == robotLoc.column {
            var startRow: Int = levelCoords.row
            var endRow: Int = robotLoc.row
            
            if startRow > endRow {
                let tmp = endRow
                endRow = startRow
                startRow = tmp
            }
            for rowStep in startRow...endRow - 1 {
                let coord = LevelCoordinates(row: rowStep, column: levelCoords.column)
                let nextCoord = LevelCoordinates(row: rowStep + 1, column: levelCoords.column)
                pathInfo |= checkForPathObstruction(coord: coord, nextCoord: nextCoord, levelGrid: levelGrid, componentsDictionary: componentsDictionary)
            }
        }
        else {
            let slopeOfTheLine = Double(levelCoords.row - robotLoc.row)/Double(levelCoords.column - robotLoc.column)
            var startCol: Int = levelCoords.column
            var endCol: Int = robotLoc.column
            var startRow: Int = levelCoords.row
            var endRow: Int = robotLoc.row
            
            if startCol > endCol {
                let tmp = endCol
                endCol = startCol
                startCol = tmp
                let tmpRow = endRow
                endRow = startRow
                startRow = tmpRow
            }
            for colStep in 0...endCol - startCol - 1 {
                let row = Int(Double(colStep) * slopeOfTheLine) + startRow
                let col = colStep + startCol
                let coord = LevelCoordinates(row: row, column: col)
                let nextRow = Int(Double(colStep + 1) * slopeOfTheLine) + startRow
                let nextCol = col + 1
                let nextCoord = LevelCoordinates(row: nextRow, column: nextCol)
                pathInfo |= checkForPathObstruction(coord: coord, nextCoord: nextCoord, levelGrid: levelGrid, componentsDictionary: componentsDictionary)
            }
        }
        return pathInfo
    }
    
    // getForbiddenDirections - Determine which directions the ai robot cannot go.  Then we can focus
    // on which directions it can go.  Note: any space where the player is the ai robot can go because
    // we want the ai robot to try to collide with the player's robot to knock it out.
    func getForbiddenDirections(levelGrid: [[[String]]], componentsDictionary: [String : LevelComponentType]) -> Set<Int> {
        var forbiddenDirections: Set<Int> = []
        
        let backRow = levelGrid.count - 2   // Give us a little more buffer than just -1 to keep the robot from colliding
        // with the wall.
        let frontRow = 1   // front row always stops before row zero so we never go negative.  Doesn't really matter if it's 0 or 1 as long as it's
                            // close to the front but not beyond row zero.
        // AI Robots shouldn't
        // hit the near wall because the row with the player's robot should be in
        // front of it by one row.
        
        // Check the same row, column as the ai robot in case something is very close.  Also, note that we should
        // only have the empty label and one robot name in the level grid coordinates.  If we have two in the same one, then another
        // robot or a fixed level component is in the same row, column.  So count should be just 2.  Anything higher and the robot should
        // choose a different direction to go.
        if isLevelGridSpaceOccupiedByComponentToAvoid(robotMakingQuery: robotNode.name!, objectsInLevelGridSpace: levelGrid[levelCoords.row][levelCoords.column], componentsDictionary: componentsDictionary) {
            forbiddenDirections.insert(currentDirection)
        }
        else if currentDirection == north || currentDirection == zeroDirection {
            if levelCoords.row + 1 > backRow {
                forbiddenDirections.insert(north)
            }
                // Note: we always check that the count of elements at a specific row, column is > 1 or that
                // it isn't the EmptyLabel.  If the count is greater than 1 we know that multiple objects
                // are in the space, including possibly the EmptyLabel.  If the count is 1 but the object
                // at location 0 isn't the empty label, we can safely assume that it is and object to avoid,
                // like a fixed level component.  However, we may not care if the object is a part or powerup, so we
                // may have to revise this code later.
                // Note: in looking ahead we should just see the empty label in the next column.  If more than that then the count should
                // be higher and we want to avoid that space, unless the player is in it.
                
            else if isLevelGridSpaceOccupiedByComponentToAvoid(robotMakingQuery: robotNode.name!, objectsInLevelGridSpace: levelGrid[levelCoords.row+1][levelCoords.column], componentsDictionary: componentsDictionary) {
                forbiddenDirections.insert(north)
            }
        }
        else if currentDirection == south || currentDirection == zeroDirection {
            if levelCoords.row - 1 < frontRow {
                forbiddenDirections.insert(south)
            }
            // check one row south to see what's coming.
            else if isLevelGridSpaceOccupiedByComponentToAvoid(robotMakingQuery: robotNode.name!, objectsInLevelGridSpace: levelGrid[levelCoords.row-1][levelCoords.column], componentsDictionary: componentsDictionary) {
                forbiddenDirections.insert(south)
            }
        }
        else if currentDirection == west || currentDirection == zeroDirection {
            if levelCoords.column + 1 > maxNumberOfLevelComponentsWide - 2 {  // Give us more than just -1 column of buffer to
                // to avoid hitting the right wall.
                forbiddenDirections.insert(west)
            }
            // look one column west to see if anything's there.
            else if isLevelGridSpaceOccupiedByComponentToAvoid(robotMakingQuery: robotNode.name!, objectsInLevelGridSpace: levelGrid[levelCoords.row][levelCoords.column+1], componentsDictionary: componentsDictionary) {
                forbiddenDirections.insert(west)
            }
        }
        else if currentDirection == east || currentDirection == zeroDirection {
            // minimum column number is 1.  Should we make that a constant?  Probably.  We want to make sure it doesn't touch the left wall.
            if levelCoords.column - 1 < 1 {
                forbiddenDirections.insert(east)
            }
            // look one column east to see what's there.
            else if isLevelGridSpaceOccupiedByComponentToAvoid(robotMakingQuery: robotNode.name!, objectsInLevelGridSpace: levelGrid[levelCoords.row][levelCoords.column-1], componentsDictionary: componentsDictionary) {
                forbiddenDirections.insert(east)
            }
        }
        
        return forbiddenDirections
    }

    // ai robot speed is a default except for the zapper,
    // superworker, homing and ghost robots.  They're faster because
    // they don't have the range that throwing robots do.
    func getAIRobotSpeed () -> Float {
        var speed = defaultAIRobotSpeed
        switch robotType {
        case .superworker:
            speed *= 2.0
        case .zapper:
            speed *= 2.0
        case .homing:
            speed *= 4.0
        case .ghost:
            speed *= 4.0
        default:
            break
        }
        return speed
    }
    
    func getPlayerRobotSpeed () -> Float {
        let speed = defaultPlayerRobotMovingSpeed
        return speed
    }
    
    // get throwing speed of robot.  If the player's robot, then
    // apply longer range power up, if activated.
    func getRobotThrowingSpeed () -> Float {
        var speed: Float = 0.0
        
        if playerType == .localHumanPlayer {
            speed = defaultPlayerRobotThrowingSpeed
            if robotHealth.throwingForcePowerUpApplied == true {
                speed *= Float(robotHealth.powerUpMultiple)
            }
        }
        else {
            speed = defaultAIRobotThrowingSpeed
        }
        
        return speed
    }
    
    func getHomingDirections(playerSceneCoords: SCNVector3) -> Set<Int> {
        let aiRobotSceneCoords = robotNode.presentation.position
        var homingDirections: Set<Int> = []
        
        if aiRobotSceneCoords.z > playerSceneCoords.z {
            homingDirections.insert(north)
        }
        else {
            homingDirections.insert(south)
        }
        if aiRobotSceneCoords.x > playerSceneCoords.x {
            homingDirections.insert(east)
        }
        else {
            homingDirections.insert(west)
        }
        
        return homingDirections
    }
    
    func getDirection (forbiddenDirections: Set<Int>, maxTries: Int, randomGenerator: RandomNumberGenerator, playerLoc: SCNVector3) -> Int {
        var newDirection: Int = currentDirection        // Note: start off with the current direction.  Then choose a new direction from there, if one
                                                        // is needed.  If we set this to Zerod direction, then further down we'll always choose a new
                                                        // direction, which can result in a ping-pong effect when homing is turned on.
        var numTries = 0
        
        var randomNum: Int = 0
        
        // If homing turned on, try to move toward's the player's robot.
        if robotState == .homing {
            let homingDirections = getHomingDirections(playerSceneCoords: playerLoc)
            // if ai robot is already going in the right direction, don't bother changing it.
            if homingDirections.contains(currentDirection) {
                newDirection = currentDirection
            }
            else {
                // Otherwise, randomly pick from the possible homing directions, of which there should just be two.
                let homingDirectionsArray = Array(homingDirections)
                newDirection = homingDirectionsArray[randomGenerator.xorshift_randomgen() % homingDirectionsArray.count]
            }
            // if while homing the ai robots goes in a direction that is forbidden, there is an obstacle
            // ahead.  Switch to avoidobstacle mode and move randomly for a while.
            // if forbiddenDirections.contains(newDirection) {
            if robotStuck == true && newDirection == currentDirection {
                robotState = .avoidobstacle
                maxRandomMovesToAvoidObstacle = maximumRandomMovesToTryToAvoidObstacle
                robotStuck = false      // we reset robotStuck here even if it might still be stuck.  This prevents us
                                        // from constantly going into this if statement, which would be almost like an
                                        // infinite loop.  Almost.
            }
        }
        
        // count down number of random moves the robot makes in avoidobstacle mode.  When it gets to zero, reset
        // mode back to homing mode.  This assumes that the avoidobstacle mode always follows homing mode, never
        // following the random mode, which is the default starting mode for the ai robot.  Once the mode switches
        // to homing it then ping pongs between homing and avoidobstacle, never going back to true random mode.
        if robotState == .avoidobstacle {
            if maxRandomMovesToAvoidObstacle <= 0 {
                robotState = .homing
            }
            else {
                maxRandomMovesToAvoidObstacle -= 1
            }
        }
        
        // If homing wasn't turned on, then randomly choose a direction, making sure not to
        // choose a direction that results in running into an obstacle near the robot.
        if (robotState == .random || robotState == .avoidobstacle) && (newDirection == zeroDirection || forbiddenDirections.contains(newDirection)) {
            randomNum = randomGenerator.xorshift_randomgen() % 1024
            if randomNum < 256 {
                newDirection = west
            }
            else if randomNum >= 256 && randomNum < 512 {
                newDirection = east
            }
            else if randomNum >= 512 && randomNum < 768 {
                newDirection = north
            }
            else {
                newDirection = south
            }
            while forbiddenDirections.contains(newDirection) && numTries < maxTries {
                randomNum = randomGenerator.xorshift_randomgen() % 1024
                if randomNum < 256 {
                    newDirection = west
                }
                else if randomNum >= 256 && randomNum < 512 {
                    newDirection = east
                }
                else if randomNum >= 512 && randomNum < 768 {
                    newDirection = north
                }
                else {
                    newDirection = south
                }
                numTries += 1
            }
            if forbiddenDirections.contains(newDirection) {
                let allRealDirections: Set<Int> = [north, south, east, west]
                let allowedDirections = Array(allRealDirections.subtracting(forbiddenDirections))
                newDirection = allowedDirections[0]    // this isn't elegant--just choose the first one since we couldn't randomly
                // decided on a direction.
            }
        }
        
        return newDirection
    }
    
    // setNewAIRobotVelocity - Start robot moving if it is not.  Also, select new direction for it to
    // move if it has moved a certain distance already.  The new direction could be the same
    // as the old.  Close quarters movement has priority.  If the ai robot is very close to the player's robot
    // then we invoke the close quarters code.
    func setNewAIRobotVelocity(levelGrid: [[[String]]], randomGenerator: RandomNumberGenerator, playerPresentationLoc: SCNVector3, playerLevelLoc: LevelCoordinates, componentsDictionary: [String: LevelComponentType]) {
        let robotVelocity = (robotNode.physicsBody?.velocity)!
        
        // First, make sure mobility isn't zero.  If it is then the robot should be stuck, not moving so there's nothing to do here
        // in the case.
        
        if robotHealth.mobilityHealth() > healthPrettyMuchGone {
            var forbiddenDirections: Set<Int> = []
            
            forbiddenDirections = getForbiddenDirections(levelGrid: levelGrid, componentsDictionary: componentsDictionary)
            
            // if the robot isn't moving it obviously can't continue in the direction it's going.  But make sure the
            // direction isn't ZeroDirection because that means it hasn't even started moving yet.
            
            if (abs(robotVelocity.x) <= minimumAIRobotSpeed && abs(robotVelocity.y) <= minimumAIRobotSpeed && abs(robotVelocity.z) <= minimumAIRobotSpeed) && currentDirection != zeroDirection {
                // Force the robot to go in a different direction.
                forbiddenDirections.insert(currentDirection)
                robotStuck = true
            }
             
            if isTimeToSwitchDirection() {

                let newDirection = getDirection(forbiddenDirections: forbiddenDirections, maxTries: 5, randomGenerator: randomGenerator, playerLoc: playerPresentationLoc)
                updateDirectionAndVelocity(newDirection: newDirection)
                
                lastLevelCoordsWhereVelocitySet = levelCoords
                
                // market the time of this current direction switch.  That way we can track how long it's been since the last
                // direction switch and if enough time has passed, switch directions again.
                let currentTime = NSDate().timeIntervalSince1970
                timeOfLastDirectionSwitch = currentTime
                // make the delay a standard delay time, nothing fancy
                switchDirectionDelayTime = defaultAIRobotSwitchDirectionDelay
            }            
        }
        // Lastly, don't forget to update the color of the label above the robot if the robot is
        // an ai robot.  We don't really care if the state changes or not, we just set it here.
        // It's a little inefficient but since this is only for debugging, we don't care.
        /*
        if playerType == .ai {
            robotLabelNode.geometry?.firstMaterial?.diffuse.contents = convertStateToTextColor()
        }
        */
    }
    
    // this applies to the player's robot only.  We activate a power up by updating the robot's health and then 
    // performing the power up.
    func activatePowerUp (powerUp: PowerUp) {
        // if there was an old powerup and it was a speedup and the new one isn't a speedup, then go back to
        // normal wheel turning speed.
        if robotHealth.speedPowerUpApplied == true && powerUp.powerUpType != .speedPowerUp {
            turnWheelsAtNormalSpeed()
        }
        
        robotHealth.applyPowerUp(powerUp: powerUp)
        if robotHealth.speedPowerUpApplied == true {
            updateDirectionAndVelocity(newDirection: currentDirection)
            speedUpWheels(xspeedup: robotHealth.powerUpMultiple)
        }
        
        // attach powerup powerpack to robot here.  It will be part of the player's robot but will
        // also _not_ be able to make contact with anything.  It's just there to let the player know
        // the state of the powerup, nothing more.  First we remove one if one is already attached, and
        // then attach the new power up.
        removePowerUpAsPowerPack()
        attachPowerUpAsPowerPack(powerUpName: powerUp.powerUpName, type: powerUp.powerUpType)
    }
    
    // remove powerup/powerpack from the back of robot either when it's done or when replaced by
    // another one.
    func removePowerUpAsPowerPack () {
        if attachedPowerUpNode != nil {
            if attachedPowerUpNode.parent != nil {
                attachedPowerUpNode.removeFromParentNode()
            }
            attachedPowerUpNode = nil   // remove powerup so we start fresh.
        }
    }
    
    func attachPowerUpAsPowerPack (powerUpName: String, type: PowerUpType) {
        switch type {
        case .fasterReloadPowerUp:
            attachedPowerUpNode = allModelsAndMaterials.reloadPowerUpModel.clone()
            // Can't just clone a node. We also have to copy the geometry and material to make them independent
            // copies.  Otherwise what happens to one happens to all others of the same geometry and material.
            attachedPowerUpNode.geometry = allModelsAndMaterials.reloadPowerUpModel.geometry?.copy() as? SCNGeometry
            attachedPowerUpNode.geometry?.firstMaterial = allModelsAndMaterials.reloadPowerUpModel.geometry?.firstMaterial?.copy() as? SCNMaterial
        case .speedPowerUp:
            attachedPowerUpNode = allModelsAndMaterials.speedPowerUpModel.clone()
            // Can't just clone a node. We also have to copy the geometry and material to make them independent
            // copies.  Otherwise what happens to one happens to all others of the same geometry and material.
            attachedPowerUpNode.geometry = allModelsAndMaterials.speedPowerUpModel.geometry?.copy() as? SCNGeometry
            attachedPowerUpNode.geometry?.firstMaterial = allModelsAndMaterials.speedPowerUpModel.geometry?.firstMaterial?.copy() as? SCNMaterial
        case .throwingForcePowerUp:
            attachedPowerUpNode = allModelsAndMaterials.forcePowerUpModel.clone()
            // Can't just clone a node. We also have to copy the geometry and material to make them independent
            // copies.  Otherwise what happens to one happens to all others of the same geometry and material.
            attachedPowerUpNode.geometry = allModelsAndMaterials.forcePowerUpModel.geometry?.copy() as? SCNGeometry
            attachedPowerUpNode.geometry?.firstMaterial = allModelsAndMaterials.forcePowerUpModel.geometry?.firstMaterial?.copy() as? SCNMaterial
        default:
            break
        }
        // shrink it down in size _before_ we rotate it.  Otherwise we lose track of how it's supposed to be
        // and we have to rethink the scale taking the rotation into account.  We shrink it down so that it will
        // fit behind the head of the robot without looking odd, yet still viewable by the player.
        attachedPowerUpNode.scale = SCNVector3(0.5, 0.5, 0.5)
        
        // flip powerup 90 degrees around x and z axis to make it look like a power pack.  Later it will be attached
        // to the back of the robot.
        switch currentDirection {
        case east:
            attachedPowerUpNode.rotation = SCNVector4(0.0, 0.0, 1.0, Double.pi / 2.0)
            attachedPowerUpNode.position = SCNVector3(0.0, -0.4, robotDimensions.length / 2.0)
        case west:
            attachedPowerUpNode.rotation = SCNVector4(0.0, 0.0, 1.0, Double.pi / 2.0)
            attachedPowerUpNode.position = SCNVector3(0.0, -0.4, robotDimensions.length / 2.0)
        case north:
            // From https://stackoverflow.com/questions/32126632/scenkit-eulerangles-strange-values-during-rotation
            // We get this weird behavior with eulerAngles:
            // That's how Euler angles work. They have two quirks (I'll refer to x, y, and z as pitch, yaw, and roll respectively):
            //
            // * roll and yaw increase with counterclockwise rotation from 0 to π (180 degrees) and then jump to -π (-180 degrees) and
            //   continue to increase to 0 as the rotation completes a circle; but pitch increases to π/2 (90 degrees) and then decreases
            //   to 0, then decreases to -π/2 (-90 degrees) and increases to 0.
            // * Values become inaccurate in certain orientations. In particular, when pitch is ±90 degrees, roll and yaw become
            // erratic. See the wikipedia article on gimbal lock.
            //
            // We have to use eulerAngles with North and South because we need to rotate in two direction.  When we do that
            // using the rotation property instead the powerup is angled at a 45 degree angle rather than 90.  Even though we're
            // modifying the eulerAngle about the x axis as well as the z axis we haven't seen any problem with it they way
            // we're rotating it.  It probably helps that we're sticking with 90 degree angles.
            attachedPowerUpNode.eulerAngles = SCNVector3(Double.pi/2.0, 0.0, Double.pi/2.0)
            attachedPowerUpNode.position = SCNVector3(0.0, -0.4, robotDimensions.length / 2.0)
        case south:
            //attachedPowerUpNode.rotation = SCNVector4(1.0, 0.0, 1.0, Double.pi / 2.0)
            // We use eulerAngles rather than rotation for the same reason we did that with North but not with East or West.  See comment
            // for the North case above.
            //attachedPowerUpNode.eulerAngles = SCNVector3(0.0, Double.pi/2.0, Double.pi/2.0)
            attachedPowerUpNode.eulerAngles = SCNVector3(Double.pi/2.0, 0.0, Double.pi/2.0)
            attachedPowerUpNode.position = SCNVector3(0.0, -0.4, robotDimensions.length / 2.0)
        default:
            break
        }
        attachedPowerUpNode.name = powerUpName
        nearTopOfRobotNode.addChildNode(attachedPowerUpNode)
    }
    
    // when the robot changes direction, update the velocity to move the robot in that new direction.
    func updateDirectionAndVelocity(newDirection: Int) {
        var thisIsADirectionChange: Bool = false
        var speed: Float = 0.0

        if currentDirection != newDirection {
            thisIsADirectionChange = true
        }
        
        currentDirection = newDirection
        
        if impactedState == .notImpactedOrRecovering {
            // Note: From http://stackoverflow.com/questions/34092588/why-scnphysicsbody-resets-position-when-set-eulerangles
            // we see that we have to save the robot's presentation position before changing the eulerAngles and then
            // reassiging the location back to the robot afterwards.  Apparently, when we change the eulerAngles that resets
            // the physics simulation for that node.  This works far, far better than removing the node, applying the
            // change to eulerAngles and putting the node back in like we were doing before, which didn't always work.
            // Note: even though we've switched from eulerAngles to rotation for the the robotFacingDirection, we still keep
            // the link above to remind us that we have to use the presentation node position to put the robot back in place.
            let robotSavedLocation = robotNode.presentation.position
            robotNode.rotation = robotFacingDirections[currentDirection]
            
            // if the robot is the player's robot, reset that launcher to be facing the same direction as the
            // robot when the direction changes, but only when the direction changes.  But only do this for the
            // player's robot.  It looks right for that robot but not right when we do the same thing with the
            // ai robots.  For some reason they look right without doing this but don't look right when we do.
            
            if thisIsADirectionChange == true && playerType == .localHumanPlayer {
                launcherNode.rotation = SCNVector4(0.0, 1.0, 0.0, 0.0)
            }
            robotNode.position = robotSavedLocation
            
            if playerType == .ai {
                speed = getAIRobotSpeed()
            }
            else {
                speed = getPlayerRobotSpeed()
                if robotStoppedViaStopButton == true {
                    speed = 0.0
                }
            }
            
            // Velocity is simple: North, West, East, or South.  Thus, all directions are zero except for the one
            // in which the robot is moving.  So we simply multiply all directions by the same speed to get our velocity.
            // And since we're just dealing with robot movement in the xz plane, we just multiply those by the speed.
            // Note: things would have to be done differently if we had drones but we don't.  Also note that we multiply
            // both x and z by speed.  This works out because if x is nonzero then z is zero and vice versa.  So there's
            // never any problem with the calculation causing the robot to go in a diagonal direction.
            currentVelocity.x = robotMovingDirections[currentDirection].x * speed
            currentVelocity.z = robotMovingDirections[currentDirection].z * speed
            currentVelocity.y = robotMovingDirections[currentDirection].y
            
            // Don't forget to reduce speed if mobility is impaired by hits from sticky baked goods.  Or increase
            // speed if a power up has been applied to the player's robot.
            currentVelocity = multSCNVect3ByScalar(v: currentVelocity, s: Float(robotHealth.mobilityHealth()))
            
            robotNode.physicsBody?.velocity = currentVelocity
        }
    }
    
    // All robots recover slowly from damage, from corrosion damage, from staticDischarge damage,
    // and from fire damanage.  The only damage they don't recover from is impact damage, but that
    // is because impact damage is all-or-nothing.  We make the tougher robots harder to tip over
    // by reducing the target area where the impact baked good is effective.  For all the other types
    // of damage we check the clock and if a certain amount of time has passed, we restore a little
    // bit more health to the robot.
    func recoverFromDamage() {
        robotHealth.restoreSomeHealth()
        showChangeInCorrosion()     // we run this here in case the robot recovers enough from
                                    // corrosion to show a change.
        showChangeInStaticDischargeDamage()
        updateDirectionAndVelocity(newDirection: currentDirection)    // we update the velocity and direction, well,
    }
        
    // when a robot is hit with a corrosive baked good, show the change
    // in its corroded state.  Also, if it has recovered a little, show
    // the change in the corroded state to a healthier state.
    func showChangeInCorrosion() {
        let resistancePerCorrosionState = robotHealth.startingCorrosionResistance/Double(corrosionColors.count)
        let newCorrosionState = Int(robotHealth.corrosionResistance/resistancePerCorrosionState)
        
        if newCorrosionState >= 0 && newCorrosionState < corrosionColors.count {
            if newCorrosionState != lastCorrodedState {
                if newCorrosionState < lastCorrodedState {
                    // robot was hit with a new corrosive baked good, play fry sound
                    let waitForImpactToTakeEffectAction = SCNAction.wait(duration: 0.2)
                    let frySoundAction = SCNAction.playAudio(NodeSound.fry!, waitForCompletion: false)
                    let frySoundSequence = SCNAction.sequence([waitForImpactToTakeEffectAction, frySoundAction])
                    // using a key to keep it separate from anything else to prevent it from being removed
                    // with an unrelated action, just in case.
                    robotNode.runAction(frySoundSequence, forKey: burningSoundKey)
                }
                lastCorrodedState = newCorrosionState

                SCNTransaction.begin()
                SCNTransaction.animationDuration = 3.0
                // Note: we only change the first material.  There should only be one material as we have
                // just one texture and one material in every model.  Doubleheck the .dae file in the scene editor to be sure.
                let materials = (robotBodyNode.geometry?.materials)! as [SCNMaterial]
                let material = materials[0]
                material.multiply.contents = corrosionColors[newCorrosionState]
                if doesRobotHaveLauncher(playerType: playerType, robotType: robotType) == true {
                    let launcherMaterials = (launcherNode.geometry?.materials)! as [SCNMaterial]
                    let launcherMaterial = launcherMaterials[0]
                    launcherMaterial.multiply.contents = corrosionColors[newCorrosionState]
                }
                if doesRobotHaveArms(playerType: playerType, robotType: robotType) == true {
                    let leftArmMaterial = leftArmNode.geometry?.firstMaterial
                    leftArmMaterial?.multiply.contents = corrosionColors[newCorrosionState]
                    let rightArmMaterial = rightArmNode.geometry?.firstMaterial
                    rightArmMaterial?.multiply.contents = corrosionColors[newCorrosionState]
                }
                SCNTransaction.commit()
            }
        }        
    }
    
    // When a robot is hit with a static discharge, show the change in its damage state.  Also,
    // if it has recovered a little, show the change in the damage state to a healthier state.
    func showChangeInStaticDischargeDamage() {
        let resistancePerDamageState = robotHealth.startingStaticDischargeResistance/Double(staticDischargeDamageColors.count)
        let newDamageState = Int(robotHealth.staticDischargeResistance/resistancePerDamageState)
        
        if newDamageState >= 0 && newDamageState < staticDischargeDamageColors.count {
            if newDamageState != lastStaticDischargeDamageState {
                if newDamageState < lastStaticDischargeDamageState {
                    // robot was hit with a new corrosive baked good, play fry sound
                    let staticDischargeSoundAction = SCNAction.playAudio(NodeSound.staticDischarge!, waitForCompletion: true)
                    let staticDischargeSoundSequence = SCNAction.sequence([staticDischargeSoundAction])
                    // using a key to keep it separate from anything else to prevent it from being removed
                    // with an unrelated action, just in case.
                    robotNode.runAction(staticDischargeSoundSequence, forKey: staticDischargeSoundKey)
                }
                lastStaticDischargeDamageState = newDamageState
                
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 1.0
                // Note: we only change the first material.  There should only be one material as we have
                // just one texture and one material in every model.  Doublecheck the .dae file in the scene editor to be sure.
                let materials = (robotBodyNode.geometry?.materials)! as [SCNMaterial]
                let material = materials[0]
                material.multiply.contents = staticDischargeDamageColors[newDamageState]
                if doesRobotHaveLauncher(playerType: playerType, robotType: robotType) == true {
                    let launcherMaterials = (launcherNode.geometry?.materials)! as [SCNMaterial]
                    let launcherMaterial = launcherMaterials[0]
                    launcherMaterial.multiply.contents = staticDischargeDamageColors[newDamageState]
                }
                if doesRobotHaveArms(playerType: playerType, robotType: robotType) == true {
                    let leftArmMaterial = leftArmNode.geometry?.firstMaterial
                    leftArmMaterial?.multiply.contents = staticDischargeDamageColors[newDamageState]
                    let rightArmMaterial = rightArmNode.geometry?.firstMaterial
                    rightArmMaterial?.multiply.contents = staticDischargeDamageColors[newDamageState]
                }
                SCNTransaction.commit()
            }
        }
    }
    
    // show impact from baked good using real physics.  And show recovery, if there is one.  This time use the dot
    // product for v^2 instead of the cross product.  And then multiply the results times the unit vectory of the velocity.
    func showImpactAndRecovery(sceneView: SCNView, pointOfImpact: SCNVector3, impactVelocity: SCNVector3, mass: Double, throwingForcePowerUpUsed: Bool) {
        // From the url https://www.engineeringtoolbox.com/impact-force-d_1780.html we use the formula for
        // calculating the impact force:
        //
        // F = mv^2 / s
        //
        // where:
        //
        // F = impact force
        // m = mass of the object
        // v = velocity of the object
        // s = deformation distance
        //
        // For deformation distance we'll use 0.1 meters to start.  If it doesn't look right
        // we'll change it.
        
        let deformationDistance =  Float(0.1)
        let impactVelocitySquared = dotProductSCNVect3(v1: impactVelocity, v2: impactVelocity)
        
        // It may not look like it but the equation below is essentially F = mv^2/s, with a fudge factor that we divide mass by 1000.0.
        // Otherwise the force is way too much.
        let scalarImpactForce = Float(mass/1000.0) * impactVelocitySquared / deformationDistance
        
        let impactVelocityMagnitude = sqrt(impactVelocitySquared)
        let impactVelocityUnitVector = SCNVector3(impactVelocity.x/impactVelocityMagnitude, impactVelocity.y/impactVelocityMagnitude, impactVelocity.z/impactVelocityMagnitude)
        var impactForce: SCNVector3 = multSCNVect3ByScalar(v: impactVelocityUnitVector, s: scalarImpactForce)
        
        let impactWaitAction = SCNAction.wait(duration: 1.0)
        let recoveryAction = SCNAction.customAction(duration: 1.0, action: { _,_ in
            // set up to make the first adjustment happen.  It doesn't matter what the values are for lastDeltaRobotTopPosition
            // and deltaRobotTopPosition as long as lastDeltaRobotTopPosition < deltaRobotTopPosition to force the first adjustment.
            // Note: deltaRobotTopPosition will be assigned to last and then a new one calculated, which should generally be > 0.0.
            // If not, then no adjustment is necessary and we're done anyway.
            self.deltaRobotTopPosition = 0.0
            self.adjustImpactRecovery()
            self.lastImpactRecoveryTime = NSDate().timeIntervalSince1970    // recovery has started so mark this as the last recovery time for reference later when adjustments
                                                                            // to the recovery are made at regular time intervals.
        })
        
        //let waitForImpactToTakeEffectAction = SCNAction.wait(duration: 0.2)
        //let soakUpImpactSoundAction = SCNAction.playAudio(NodeSound.soakUpImpact!, waitForCompletion: false)
        //let soakUPImpactSoundSequence = SCNAction.sequence([waitForImpactToTakeEffectAction, soakUpImpactSoundAction])
        
        let impactSequence = SCNAction.sequence([impactWaitAction, recoveryAction])
        // Note: we have to convert the point of impact to the robot's coordinate system because the applyForce
        // has to be applied to the point in the robotNode's local coordinate system.  That's the way applyForce works.
        let realRobotLoc = robotNode.presentation.position
        //var contactPointInRobotCoordinateSpace: SCNVector3 =  (sceneView.scene?.rootNode.convertPosition(pointOfImpact, to: robotNode.presentation))!
        var contactPointInRobotCoordinateSpace: SCNVector3 = SCNVector3(pointOfImpact.x - realRobotLoc.x, pointOfImpact.y - realRobotLoc.y, pointOfImpact.z - realRobotLoc.z)
        // If hit in the lower 2/3 of the robot, then it's a push, not a tip.  So we center the y component at teh
        // robot's center to make it a push.  Or if the player robot used a throwing force power up behind the throw.
        if contactPointInRobotCoordinateSpace.y < robotNode.presentation.position.y * 1.33 {
            contactPointInRobotCoordinateSpace.y = robotNode.presentation.position.y
            impactForce.y = 0.0
        }
        
        turnOnForceEffects()
        robotNode.physicsBody!.velocity = SCNVector3(0.0, 0.0, 0.0)   // immediately stop the robot to let the impact take effect.
        robotNode.physicsBody!.friction = 0.95      // force a pivot around wheels by making friction so high that it's almost like pinning the robot to the floor
            // at the spot where it is.
        // if throwing power up is used we want to allow less angular movement.  Otherwise the robot will spin.
        if throwingForcePowerUpUsed == true {
            robotNode.physicsBody!.angularVelocityFactor = SCNVector3(0.2, 0.0, 0.2)
        }
        robotNode.physicsBody!.applyForce(impactForce, at: contactPointInRobotCoordinateSpace, asImpulse: true)
        
        impactedState = .impacted
        self.robotNode.physicsBody!.friction = self.originalRobotFriction
        
        let showImpactAndRecoveryActionKey = "ShowImpactAndRecovery"        // the key we use for the showImpactAndRecovery sequence of actions.  That way, if another impact
                                                                            // happens the action is overwritten rather than being stacked.  This is only used here so
                                                                            // we don't make it global.
        
        // play crashing sound unless the robots are the larger ones that are much harder to knock over.  In those case
        // we just play the regular sound.
        if throwingForcePowerUpUsed == true && robotType != .superworker && robotType != .superbaker && robotType != .pastrychef {
            // we set up crashing sound here instead of at the top because this should happen a lot less often.
            // play the crashing sound to give the player a satisfying crash/crunch when the robot gets hit by a high-velocity
            // baked good.
            let crashingSoundAction = SCNAction.playAudio(NodeSound.crash!, waitForCompletion: false)
            // set this true to keep the sound from being played again when/if it is determined later that the robot is near horizontal (i.e. tipped over and crashing to the floor.
            crashSoundPlaying = true
            robotNode.runAction(crashingSoundAction, forKey: impactOrRecoverySoundKey)
        }
        /*
        else {
            robotNode.runAction(soakUPImpactSoundSequence, forKey: ImpactOrRecoverySoundKey)
        }
        */
        
        robotNode.runAction(impactSequence, forKey: showImpactAndRecoveryActionKey, completionHandler: {
            // after impact has taken effect, turn forces back off and let the robot move normally if it
            // hasn't been impacted beyond recovery.  If it has, then we just leave the impactedState they way
            // it is because later the robot will be shut down.
            if self.impactedState != .tippedOver && self.impactedState != .endOverEndFlip {
                self.robotNode.physicsBody!.friction = self.originalRobotFriction
                self.turnOffForceEffects()
                self.updateDirectionAndVelocity(newDirection: self.currentDirection)
                self.impactedState = .notImpactedOrRecovering        // impact is over, robot no longer affected by it.
            }
        })
    }

    // The impact recovery is one adjustment after another as the robot tries to right itself.  Even the
    // very first recovery force on a robot is an adjustment.
    func adjustImpactRecovery() {
        let rWT = self.robotNode.presentation.worldTransform
        let nWT = self.nearTopOfRobotNode.presentation.worldTransform
        let robotCenter = SCNVector3(rWT.m41, rWT.m42, rWT.m43)
        let robotTop = SCNVector3(nWT.m41, nWT.m42, nWT.m43)
        let modelRobotTop = self.nearTopOfRobotNode.position
        
        // calculate xz vector to top of robot from center and then the -xz vector will be the vector that
        // we will use to put the robot back to the upright position.  Actually, we will use the unit vectory
        // of -xz and use an arbitrary scalar force multiplied by that unit vector to get the robot tipping
        // back towards the upright position.
        let deltaxsquared = (robotTop.x - robotCenter.x) * (robotTop.x - robotCenter.x)
        let deltazsquared = (robotTop.z - robotCenter.z) * (robotTop.z - robotCenter.z)
        let xzdistance = sqrt(deltaxsquared + deltazsquared)
        // the unit recovery vectory is -xz/xzdistance
        let recoveryUnitVector = SCNVector3(-(robotTop.x - robotCenter.x)/xzdistance, 0, -(robotTop.z - robotCenter.z)/xzdistance)
        let recoveryForce = multSCNVect3ByScalar(v: recoveryUnitVector, s: Float(self.recoveryScalarForce))
        
        if robotTop.y - robotCenter.y < 0.66 * self.maxYBetweenNearTopAndRobotCenter {
            self.impactedState = .tippedOver
        }
        else if self.robotNode.physicsBody!.angularVelocity.w > 4.0 {
            self.impactedState = .endOverEndFlip
        }
        else if self.impactedState != .tippedOver && self.impactedState != .endOverEndFlip {  // not enough impact to do anything.  recover.
            self.lastDeltaRobotTopPosition = self.deltaRobotTopPosition
            self.deltaRobotTopPosition = Double(xzdistance)
            if self.deltaRobotTopPosition > self.lastDeltaRobotTopPosition {
                // Important Note:  note that we're applying the recovery force to the modelRobotTop, _not_ the presentation node robot top.
                // We do this because the physicsBody is associated with the model node, not the presentation node.  We tried to apply
                // the force to the location of the nearTopOfRobotNode's presentation position and got strange behavior.  But when
                // we applied the force to the location of the model node's nearTopOfRobotNode position it worked as expected.
                self.robotNode.physicsBody!.applyForce(recoveryForce, at: modelRobotTop, asImpulse: true )
            }
            // If the state wasn't recovering before then it has just started recovering and we play the sound.
            // Otherwise it is in a recovering state already and the sound is already playing.
            /*
            if self.impactedState != .recovering && self.impactedState == .impacted {
                let recoverSoundAction = SCNAction.playAudio(NodeSound.recoverFromImpact!, waitForCompletion: false)
                self.robotNode.runAction(recoverSoundAction, forKey: ImpactOrRecoverySoundKey)
            }
            */
            self.impactedState = .recovering
        }
    }
    
    // Note: this function is similar to the recovery action in the showImpactAndRecovery() function above.
    // But this is used for a check in every renderer loop
    // to see if a robot meets the criteria for having tipped over too far, or is flipping end-over-end.
    // In each of those two cases we set the impactedState but do nothing else as we don't
    // want to have the robot shutting down immediately when the tip over criteria is met.  Instead, we
    // want a) to wait until the robot is in recovery and at that point if it is seen as being tipped
    // too far don't initiate robot recovery and b) shut down the robot after recovery but not at the
    // end of the showImpactAndRecovery action because we're not sure that would work correctly with the shutdown
    // code removing the node that is running it.  That could cause a crash.
    func updateImpactStatus() {
        let rWT = self.robotNode.presentation.worldTransform
        let nWT = self.nearTopOfRobotNode.presentation.worldTransform
        let robotCenter = SCNVector3(rWT.m41, rWT.m42, rWT.m43)
        let robotTop = SCNVector3(nWT.m41, nWT.m42, nWT.m43)
        
        if robotTop.y - robotCenter.y < 0.66 * self.maxYBetweenNearTopAndRobotCenter {
            self.impactedState = .tippedOver
        }
        else if self.robotNode.physicsBody!.angularVelocity.w > 4.0 {
            self.impactedState = .endOverEndFlip
        }
    }
    
    // check to see if the robot is in near-horizontal orientation.  We do this to check
    // to see if it has truly fallen over and if so play a crashing sound.
    func isRobotNearlyHorizontal() -> Bool {
        let rWT = self.robotNode.presentation.worldTransform
        let nWT = self.nearTopOfRobotNode.presentation.worldTransform
        let robotCenter = SCNVector3(rWT.m41, rWT.m42, rWT.m43)
        let robotTop = SCNVector3(nWT.m41, nWT.m42, nWT.m43)
        
        var robotNearlyHorizontal: Bool = false
        if abs(robotTop.y - robotCenter.y) < 0.1 {
            robotNearlyHorizontal = true
        }
        return robotNearlyHorizontal
    }
    
    // used for shutting down a corroded robot.  First we want to go to the most
    // corroded state before shutting it down so this function should run before
    // the shutdownRobot() function.  And they should both be separate SCNActions.
    // Otherwise we get the two SCNTransactions running simultaneously, which doesn't
    // look right.
    func goToMostCorrodedState() {
        // First, start playing the audio indicating a burning robot
        let corrosionSoundAction = SCNAction.playAudio(NodeSound.fry!, waitForCompletion: false)
        robotNode.runAction(corrosionSoundAction, forKey: burningSoundKey)
        // Next, go to the most corroded state.
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
        if doesRobotHaveArms(playerType: playerType, robotType: robotType) == true {
            let leftArmMaterial = leftArmNode.geometry?.firstMaterial
            leftArmMaterial?.multiply.contents = corrosionColors[mostCorrodedState]
            let rightArmMaterial = rightArmNode.geometry?.firstMaterial
            rightArmMaterial?.multiply.contents = corrosionColors[mostCorrodedState]
        }
        SCNTransaction.commit()
    }
    
    // This transitions the color of the robot body to dark gray to
    // signify that the robot is shutting down.
    func shutdownRobot () {
        robotDisabled = true        // robot is shutting down so it is disabled.
        SCNTransaction.begin()
        SCNTransaction.animationDuration = robotShutdownDuration
        let materials = (robotBodyNode.geometry?.materials)! as [SCNMaterial]
        let material = materials[0]
        //material.diffuse.contents = UIColor.darkGray
        material.multiply.contents = UIColor.darkGray
        if doesRobotHaveLauncher(playerType: playerType, robotType: robotType) == true {
            let launcherMaterials = (launcherNode.geometry?.materials)! as [SCNMaterial]
            let launcherMaterial = launcherMaterials[0]
            launcherMaterial.multiply.contents = UIColor.darkGray
        }
        if doesRobotHaveArms(playerType: playerType, robotType: robotType) == true {
            let leftArmMaterial = leftArmNode.geometry?.firstMaterial
            leftArmMaterial?.multiply.contents = UIColor.darkGray
            let rightArmMaterial = rightArmNode.geometry?.firstMaterial
            rightArmMaterial?.multiply.contents = UIColor.darkGray
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
    
    // for the player robot, and possibly any ai robot that has more than one weapon, to
    // find which launcher is ready to fire.  This is just for baked good launchers. 
    // IMPORTANT NOTE: We assume that only one reloadTime is used because the player can only
    // select one ammo to use at a time.  Thus, the reload time is the same for all launchers.
    // This could present a slight problem when the player switches from a slow-reloading ammo
    // to a fast reloading one and the reload is still going on for the slow ammo.  I suppose
    // we could clear out all the timeReloadStarted elements when different ammo is selected.
    func whichLauncherHasFinishedReloading(currentTime: Double) -> Int {
        var launcherThatHasFinishedReloading: Int = noLauncherReadyToFire
        var i: Int = 0
        
        while i < timeReloadStarted.count && launcherThatHasFinishedReloading == noLauncherReadyToFire {
            // Note: Elsewhere we set timeReloadStarted to 0.0 to reset it.  Even though this works just
            // fine with the currentTime - timeReloadedStarted[i] calculation because the resulting time
            // difference is likely to be greater than the reload time we still check to see if the value
            // is 0.0 anyway to be sure.  Actually, should call that value LauncherNotReloading just to make
            // it clearer and also not hard code the value in case we want to change it later.
            if timeReloadStarted[i] == launcherReadyToFire || currentTime - timeReloadStarted[i] > robotHealth.reloadTime {
                launcherThatHasFinishedReloading = i
            }
            i += 1
        }
        return launcherThatHasFinishedReloading
    }
    
    // Check the reload time to see if robot has finished reloading.  This is primarily used by the ai 
    // robots, most of which have only one weapon.
    func robotFinishedReloading(currentTime: Double) -> Bool {
        var robotHasFinishedReloading: Bool = false
        
        if playerType == .localHumanPlayer {
            for aTimeReloadStarted in timeReloadStarted {
                if currentTime - aTimeReloadStarted > robotHealth.reloadTime {
                    robotHasFinishedReloading = true
                }
            }
        }
        else if playerType == .ai {
            // ai robot _only_ has one launcher/baker so always go with
            // element 0.  Or if it is a worker and has just rammed the player.
            if currentTime - timeReloadStarted[0] > robotHealth.reloadTime {
                robotHasFinishedReloading = true
            }
        }
        
        return robotHasFinishedReloading
    }
    
    // check reload time of zapper weapon for the player, or for an ai robot that zaps, like the zapper or
    // the pastry chef.
    func robotFinishedZapperReloading(currentTime: Double) -> Bool {
        var robotHasFinishedReloading: Bool = false
        
        if robotHealth.timeZapperReloadStarted == 0.0 || currentTime - robotHealth.timeZapperReloadStarted > robotHealth.zapReloadTime {
            robotHasFinishedReloading = true
        }
        
        return robotHasFinishedReloading
    }
    
    // check reload time of bunsen burner for the player
    func robotFinishedBunsenBurnerReloading(currentTime: Double) -> Bool {
        var robotHasFinishedReloading: Bool = false
        
        if currentTime - robotHealth.timeBunsenBurnerReloadStarted > robotHealth.bunsenBurnerReloadTime {
            robotHasFinishedReloading = true
        }
        return robotHasFinishedReloading
    }
    
    // check to see if it is time for the ai robot to switch direction
    func isTimeToSwitchDirection() -> Bool {
        var timeToSwitchDirection: Bool = false
        
        let currentTime = NSDate().timeIntervalSince1970
        if currentTime - timeOfLastDirectionSwitch > switchDirectionDelayTime {
            timeToSwitchDirection = true
        }
        return timeToSwitchDirection
    }
    
    // convert robot state to stream to show above robot
    func convertStateToTextColor() -> UIColor {
        var stateColor: UIColor = UIColor.white
        
        switch robotState {
        case .random:
            stateColor = UIColor.white
        case .homing:
            stateColor = UIColor.red
        case .avoidobstacle:
            stateColor = UIColor.yellow
        }
        return stateColor
    }
}
