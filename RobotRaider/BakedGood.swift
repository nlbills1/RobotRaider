//
//  BakedGood.swift
//  RobotRaider
//
//  Created by Nathanael Bills on 10/17/16.
//  Copyright © 2016 invasivemachines. All rights reserved.
//

import Foundation
import SceneKit

class BakedGood {

    var bakedGoodNode: SCNNode!             // node for baked good in flight.
    var residueNode: SCNNode!               // node for residue after impact.  IMPORTANT NOTE:  once the residue
                                            // has been created it needs to move just as the baked good nodes does,
                                            // which is invisible.  The reason is that the two are essentially the
                                            // same thing, we've just made the baked good node invisible but kept it
                                            // in place.  We did that to prevent the game from crashing due to a race
                                            // condition where the contact code still tried to access it while it was being
                                            // removed when we tried to remove it.  We got around that problem by just leaving
                                            // it in place until gravity took over and moved it below the floor at which point
                                            // we could safely remove it as there was nothing under the floor to make contact.
    
    var splatter: SCNNode!          // The splatter when the baked good impacts.
    
    var whoHurled: String!
    var whatWasHit: String = ""   // to track what was hit when the baked good strikes something and is turned into residue.

    var bakedGoodName: String = ""   // we need to save the name of the baked good because we will overwrite the node when we convert the 
                                     // baked good to a residue.
    
    var bakedGoodState: BakedGoodState = .bakedgood     // start of the state of the baked good as a baked good.  Switch to residue upon impact.
    
    var ammoType: PrizeListElement!                   // ammo type of this baked good.  We will need this info when we go to calculate the impact when/if it hits
                                                // the target robot.
    
    var residueLoc: SCNVector3!                 // Location where residue hit.  We want to save this because later we will use it to determine whether or
                                                // not to restore mobility, which is based on whether or not the baked good had hit below the robot's
                                                // center of gravity.
    
    var initialVelocity: SCNVector3!            // The initial velocity of the baked good.  We want to retain this as we will need it later when the baked
                                                // good has impacted a robot and there is an effect, like tipping it over.  In a case like that we want the
                                                // initial velocity to enable us to determine a force to apply to knock over the robot.  We need this because
                                                // the baked goods don't actually collide with the robots--they just make contact with them.  That's so that
                                                // we can build up an effect (such as topheaviness or corrosion) instead of having the robot react to every hit,
                                                // which could result in unknown movements that don't look right in the gam.  Also, we need this velocity to
                                                // help us determine the rotation of the launcher when it launches the baked good.
    
    var throwingForcePowerUpUsed: Bool = false          // a flag to tell us if throwing force was applied to the baked good.  If so, we may fudge and move the
                                                        // impact lower to prevent robots from spinning from impact.
    
    init (startpoint: SCNVector3, targetPoint: SCNVector3, targetLastPoint: SCNVector3, targetVelocity: SCNVector3, hurlingSpeed: Float, bakedGoodName: String, whoThrewIt: String, playerType: PlayerType, ammoUsed: PrizeListElement, robotDimensions: RobotDimensions, robotThrowingBehavior: RobotThrowingBehavior, randomGen: RandomNumberGenerator, throwingForcePowerUpUsed: Bool) {
        self.throwingForcePowerUpUsed = throwingForcePowerUpUsed
        var xVelocity: Float = 0.0
        var yVelocity: Float = 0.0
        var zVelocity: Float = 0.0
        var xzVelocity: Float = 0.0
                
        ammoType = ammoUsed
        
        let bakedGoodSizeRatio = calculateBakedGoodSizeRatio(bakedGoodThrown: ammoUsed)
        let maxDistanceToEdgeOfRobot = Float(sqrt(robotDimensions.width*robotDimensions.width + robotDimensions.length*robotDimensions.length))
        // The baked good must start flying a certain distance away from the robot.  This doesn't matter so much for baked goods from the player
        // because those don't impact it but for baked goods from ai robots, which can impact both the player and other ai robots, this is necessary
        // to prevent the baked good from impacting the robot that launched it.  Include a little fudge factor so we aren't too close to the robot at launch.
        let mandatoryStartDistanceFromRobot = Float(bakedGoodSizeRatio) * Float(pieRadius) + maxDistanceToEdgeOfRobot + 0.1
        
        if playerType == .localHumanPlayer {
            // player robot throws a baked good.  We want the baked goods to go exactly where
            // the player specifies they should go.  Oddly, the calculations below result in a baked good being
            // thrown a bit (maybe 20%) beyond the target point.  Why that is I still don't know.  But it seems
            // to work ok.  Will it look reasonble during play on the device, though?  
            let deltax = (targetPoint.x - startpoint.x)
            let deltaz = (targetPoint.z - startpoint.z)
            var xzRangeToTarget: Float = 0.0
            
            let maximumDistance = (hurlingSpeed*hurlingSpeed) * sin(2*angleForMaximumDistance)/forceOfEarthGravity
            xzRangeToTarget = sqrt(deltax*deltax + deltaz*deltaz)
            
            var throwingAngle: Float = 0.0
            // Note: given a certain hurling speed the baked good can only go as far as the AngleForMaximumDistance allows.
            // Any farther than that and the player just can't throw the baked good that far.  So if the target is too far
            // away we just try the throwing angle for maximum distance that we can get given the hurling speed.
            if xzRangeToTarget > maximumDistance {
                throwingAngle = angleForMaximumDistance
            }
            else {
                // if the height difference between target and start is neglible, then use a simple calculation to
                // get the throwing angle.
                // Note: we do not use abs() when we calculate targetPoint.y - startingPoint.y for two reasons:  1) if
                // the two are very close they are essentially at the same height, so even if we go slightly negative
                // it still works and 2) even if we go very negative it still works because in that case the player
                // is likely throwing towards the ground and we want to prevent that because most likely the player
                // is trying to throw in the direction of an ai robot that is to the side and throwing to the ground
                // would screw up the ability to hit those robots to the side.
                if targetPoint.y - startpoint.y < 0.01 {
                    throwingAngle = 0.5 * asin((xzRangeToTarget * forceOfEarthGravity)/(hurlingSpeed*hurlingSpeed))
                }
                else {
                    let yDistance = targetPoint.y - startpoint.y
                    // We can rearrange s = 1/2 gt^2 to get the time for the distance traveled:
                    // t = sqrt(2.0 * s/g)
                    // The only question then is what to do with that since we only have xzRangeToTarget and no
                    // velocity yet because we have to get the throwing angle first.
                    
                    // for now just use the same calculation that we do when the height of the target is essentially
                    // the same as that of the baker.  However, we add an angle offset to tilt the angle of
                    // the throw slightly higher.  It's not right but it should be close enough to be unnoticeable.
                    let angleOffset = atan(yDistance/xzRangeToTarget)
                    throwingAngle = 0.5 * asin((xzRangeToTarget * forceOfEarthGravity)/(hurlingSpeed*hurlingSpeed))
                    throwingAngle += angleOffset
                }

            }

            yVelocity = hurlingSpeed * sin(throwingAngle)
            xzVelocity = hurlingSpeed * cos(throwingAngle)
            xVelocity = xzVelocity * (deltax/xzRangeToTarget)
            zVelocity = xzVelocity * (deltaz/xzRangeToTarget)
        }
        else {
            // ai robot throws a baked good.  We calculate the maximum distance we can go given the hurling
            // speed.  If the distance to target is beyond that we just set the throwing angle to get the
            // baked good to the maximum distance possible using a 45-degree angle, which is the angle that
            // will always gives us maximum distance with a given speed.
            // We fudge a little bit to get the robots to throw a little higher.  Otherwise the baked goods
            // will always land just in front of the player's robot instead of on it.
            var deltax = (targetPoint.x - startpoint.x) * 1.10
            var deltaz = (targetPoint.z - startpoint.z) * 1.10
            var xzRangeToTarget = sqrt(deltax*deltax + deltaz*deltaz)
            let maximumDistance = (hurlingSpeed*hurlingSpeed)/forceOfEarthGravity

            var throwingAngle: Float = 0.0
            
            if xzRangeToTarget > maximumDistance {
                throwingAngle = angleForMaximumDistance
            }
            else {
                // Note: the calculations are slightly different that what we did for the player.  The reason for this
                // is that some of the ai robots are larger than the player and have higher starting points.  So
                // we take the absolute value to be sure that the two points are close and if not, then we calculate
                // the angle difference.
                if abs(targetPoint.y - startpoint.y) < 0.01 {
                    throwingAngle = 0.5 * asin((xzRangeToTarget * forceOfEarthGravity)/(hurlingSpeed*hurlingSpeed))
                }
                else {
                    let yDistance = targetPoint.y - startpoint.y
                    // We can rearrange s = 1/2 gt^2 to get the time for the distance traveled:
                    // t = sqrt(2.0 * s/g)
                    // The only question then is what to do with that since we only have xzRangeToTarget and no
                    // velocity yet because we have to get the throwing angle first.
                    
                    // for now just use the same calculation that we do when the height of the target is essentially
                    // the same as that of the baker.  However, we add an angle offset to tilt the angle of
                    // the throw slightly higher.  It's not right but it should be close enough to be unnoticeable.
                    let angleOffset = atan(yDistance/xzRangeToTarget)
                    throwingAngle = 0.5 * asin((xzRangeToTarget * forceOfEarthGravity)/(hurlingSpeed*hurlingSpeed))
                    // Note: this will be negative it the startingPoint.y is higher than the target point.  That is
                    // ok because that should result in a negative angle value, which should decrease the elevation
                    // to drop the flight of the baked good down.  That is what we want when, say, a pastry chef,
                    // which is 5x taller than the player's robot, throws a baked good at the player.
                    throwingAngle += angleOffset
                }
            }
            
            // From https://en.wikipedia.org/wiki/Trajectory_of_a_projectile
            // 
            // The starting velocity v used to get the baked good to target of a distance d 
            // away assuming gravity g is what we get from the gravity variable for the scene
            // follows the formula:
            //
            // d = v^2 * sin(2*theta)/g
            //
            // If theta is 45 degrees, then the equation shortens to:
            //
            // d = v^2 / g
            //
            // which we can rearrange into:
            //
            // v = sqrt(d * g)
            //
            // So we'll stick with 45 degrees as the throwing angle.  We can change it later if
            // we need to but there's really no point.  It seems to work fine.
            
            // Note: we calculate the throwing velocities slightly differently below based on whether the
            // player robot is stopped or moving.  We could combine the two calculations into one
            // but it works well enough like it is so I'm going to leave it for another day, if there's time.
            
            // Note: check that the target point and last target point are very close before considering it stopped.
            // We can do this because when it is stopped the two point will be almost exactly the same, but possibly
            // with a rouding error.  But a value of 0.01 is certainly above any modern day rounding error.
            if areSCNVect3NearlyEqual(v1: targetPoint, v2: targetLastPoint, nearnessFactor: 0.01) {
            // Rather than trying to get exactly that the robot is not moving, we look for movement less than 5%.
            // If the player robot is moving just 5% of the its normal speed, then we consider it not moving.
                let startingSpeed = hurlingSpeed * 1.05  // Add a 5% fudge factor -- seems to work better with still targets
                yVelocity = startingSpeed * sin(throwingAngle)
                xzVelocity = startingSpeed * cos(throwingAngle)
                xVelocity = xzVelocity * (deltax/xzRangeToTarget)
                zVelocity = xzVelocity * (deltaz/xzRangeToTarget)
            }
            else {
                let maxIterations = 20
                var timeToTarget: Float = 0.0
                let startingSpeed = hurlingSpeed * 1.10   // Add a 10% fudge factor -- seems to work better with moving targets.
                
                // The initial calculation because the target will have moved farther than the
                // time it takes to get to the original target point.  So we iterate until we
                // get to a point, hopefully,where it's close.
                // Source: https://www.gamedev.net/resources/_/technical/math-and-physics/leading-the-target-r4223
                for _ in 1...maxIterations {
                    let oldTimeToTarget = timeToTarget
                    let targetDistanceTraveled = multSCNVect3ByScalar(v: targetVelocity, s: timeToTarget)
                    let newTargetPoint = addTwoSCNVect3(v1: targetPoint, v2: targetDistanceTraveled)
                    timeToTarget = calcDistance(p1: startpoint, p2: newTargetPoint) / startingSpeed
                    if timeToTarget - oldTimeToTarget < 0.01 {
                        break
                    }
                }
                
                let targetDistanceTraveled = multSCNVect3ByScalar(v: targetVelocity, s: timeToTarget)
                let newTargetPoint = addTwoSCNVect3(v1: targetPoint, v2: targetDistanceTraveled)
                
                // From https://en.wikipedia.org/wiki/Trajectory_of_a_projectile
                //
                // The starting velocity v used to get the baked good to target of a distance d
                // away assuming gravity g is what we get from the gravity variable for the scene
                // follows the formula:
                //
                // d = v^2 * sin(2*theta)/g
                //
                // We know d, v, and g.  What we want is the angle theta in this case.  We would 
                // rearrange the equation to be:
                //
                // sin(2*theta) = dg / v^2
                // 
                // theta = arcsin(dg / v^2) / 2
                //
                // theta would be our throwing angle

                deltax = (newTargetPoint.x - startpoint.x)
                deltaz = (newTargetPoint.z - startpoint.z)
                xzRangeToTarget = sqrt(deltax*deltax + deltaz*deltaz)  // y not included since it starts and ends at the same value.
                
                if xzRangeToTarget > maximumDistance {
                    throwingAngle = angleForMaximumDistance
                }
                else {
                    // Note: the calculations are slightly different that what we did for the player.  The reason for this
                    // is that some of the ai robots are larger than the player and have higher starting points.  So
                    // we take the absolute value to be sure that the two points are close and if not, then we calculate
                    // the angle difference.
                    if abs(targetPoint.y - startpoint.y) < 0.01 {
                        throwingAngle = 0.5 * asin((xzRangeToTarget * forceOfEarthGravity)/(hurlingSpeed*hurlingSpeed))
                    }
                    else {
                        let yDistance = targetPoint.y - startpoint.y
                        // We can rearrange s = 1/2 gt^2 to get the time for the distance traveled:
                        // t = sqrt(2.0 * s/g)
                        // The only question then is what to do with that since we only have xzRangeToTarget and no
                        // velocity yet because we have to get the throwing angle first.
                        
                        // for now just use the same calculation that we do when the height of the target is essentially
                        // the same as that of the baker.  However, we add an angle offset to tilt the angle of
                        // the throw slightly higher.  It's not right but it should be close enough to be unnoticeable.
                        let angleOffset = atan(yDistance/xzRangeToTarget)
                        throwingAngle = 0.5 * asin((xzRangeToTarget * forceOfEarthGravity)/(hurlingSpeed*hurlingSpeed))
                        // Note: this will be negative it the startingPoint.y is higher than the target point.  That is
                        // ok because that should result in a negative angle value, which should decrease the elevation
                        // to drop the flight of the baked good down.  That is what we want when, say, a pastry chef,
                        // which is 5x taller than the player's robot, throws a baked good at the player.
                        throwingAngle += angleOffset
                    }
                }

                yVelocity = startingSpeed * sin(throwingAngle)
                xzVelocity = startingSpeed * cos(throwingAngle)
                xVelocity = xzVelocity * (deltax/xzRangeToTarget)
                zVelocity = xzVelocity * (deltaz/xzRangeToTarget)
            }
            
            if robotThrowingBehavior == .missTarget {
                let percentMiss = randomGen.xorshift_randomgen() % 20  + 20        // minimum 20% miss.  Otherwise, it's not nearly enough.
                let directionOfMiss = randomGen.xorshift_randomgen() % 20
                if abs(xVelocity) - abs(Float(percentMiss)/100.00 * xVelocity) > minimumMissDeviation {    // if the deviation greater than our minimum to miss player.
                    if directionOfMiss >= 11 {
                        // miss to the right
                        xVelocity += Float(percentMiss)/100.00 * abs(xVelocity)
                    }
                    else {
                        // miss to the left
                        xVelocity -= Float(percentMiss)/100.00 * abs(xVelocity)
                    }
                }
                else {
                    if directionOfMiss >= 11 {
                        // miss to the South
                        zVelocity += Float(percentMiss)/100.00 * abs(zVelocity)

                    }
                    else {
                        // miss to the North
                        zVelocity -= Float(percentMiss)/100.00 * abs(zVelocity)
                    }
                }
            }
            
        }
        
        let timeAtLaunchPoint = mandatoryStartDistanceFromRobot / xzVelocity
        let launchY = yVelocity * timeAtLaunchPoint + startpoint.y
        let launchX = xVelocity * timeAtLaunchPoint + startpoint.x
        let launchZ = zVelocity * timeAtLaunchPoint + startpoint.z
        
        whoHurled = whoThrewIt
        bakedGoodNode = allModelsAndMaterials.getBakedGoodModel(itemType: ammoType.prizeType, bakedGoodSizeRatio: bakedGoodSizeRatio, primaryEffect: ammoType.primaryEffect)
        
        // start off the mandatory distance away from the robot.  This isn't a big deal for the player robot but it is for the ai robot which can
        // launch baked goods that can impact the player and other ai robots.
        bakedGoodNode.position = SCNVector3(launchX, launchY, launchZ)
        bakedGoodNode.name = bakedGoodName
        self.bakedGoodName = bakedGoodName
        bakedGoodNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        if playerType == .localHumanPlayer {
            bakedGoodNode.physicsBody!.categoryBitMask = collisionCategoryPlayerRobotBakedGood
            bakedGoodNode.physicsBody!.contactTestBitMask = collisionCategoryGround | collisionCategoryWall | collisionCategoryAIRobot | collisionCategoryAIRobotBakedGood | collisionCategoryLevelEntrance | collisionCategoryLevelExitDoorway
        }
        else {
            bakedGoodNode.physicsBody!.categoryBitMask = collisionCategoryAIRobotBakedGood
            bakedGoodNode.physicsBody!.contactTestBitMask = collisionCategoryGround | collisionCategoryWall | collisionCategoryAIRobot | collisionCategoryPlayerRobot | collisionCategoryPlayerRobotBakedGood | collisionCategoryLevelEntrance | collisionCategoryLevelExitDoorway
        }
        // this may not look right.  After all, on impact all baked goods should splatter and present residue, not bounce.  We'll leave it
        // this way and see how it goes.
        bakedGoodNode.physicsBody!.collisionBitMask = collisionCategoryEMPGrenade
        bakedGoodNode.physicsBody!.velocity = SCNVector3(xVelocity, yVelocity, zVelocity)
        // Start the baked good rotating such that it will hit a target when it is vertical at a certain point.
        // But we just make the angular velocity fixed so we don't have to do any nasty calculations.
        initialVelocity = SCNVector3(xVelocity, yVelocity, zVelocity)
    }
    
    // Calculate size relative to a maximum of 1.0.  This allows us to separate
    // the size different of baked goods relative to each other without using
    // absolute values.  This enables us to specify the specific measurements
    // of a baked good elsewhere and just modify that size via a ratio.  This
    // is essentially scaling.
    func calculateBakedGoodSizeRatio(bakedGoodThrown: PrizeListElement) -> Double {
        var bakedGoodEffectiveness: Double = 0.0
        var sizeRatio: Double = 0.0
        
        switch bakedGoodThrown.primaryEffect {
        case .corrosive:
            bakedGoodEffectiveness = bakedGoodThrown.corrosiveness
        case .impact:
            bakedGoodEffectiveness = bakedGoodThrown.mass
        case .sticky:
            bakedGoodEffectiveness = bakedGoodThrown.stickiness
        default:
            // not a baked good so we don't do anything
            break
        }

        // Size are in meters so we have 0.8m for large and 0.4m for small.
        if bakedGoodEffectiveness == large {
            sizeRatio = 0.8
        }
        else {  // assume the size is small, even if value is 0.0
            sizeRatio = 0.4
        }
        return sizeRatio
    }
    
    func getBakedGoodSize(bakedGoodThrown: PrizeListElement) -> Double {
        var bakedGoodSize: Double = 0.0
        
        switch bakedGoodThrown.primaryEffect {
        case .corrosive:
            bakedGoodSize = bakedGoodThrown.corrosiveness
        case .impact:
            bakedGoodSize = bakedGoodThrown.mass
        case .sticky:
            bakedGoodSize = bakedGoodThrown.stickiness
        default:
            // not a baked good so we don't do anything
            break
        }
        return bakedGoodSize
    }
    
    // After impact, convert baked good to residue.
    // We've had trouble removing the baked good node and replacing it with a residue node, in part because
    // a crash occurs where the baked good node is removed while the collision detection code is still detecting
    // that it has collided with something.  So instead we just make the baked good invisible and let it fall
    // through the floor.  In the same spot we then put in a residue node that is visible.  Code in
    // GamePlayViewController will eventually remove both once they have fallen a certain distance
    // beneath the floor.
    func convertToResidue(bakedGoodStrikePoint: SCNVector3) {
        bakedGoodState = .residue
        bakedGoodNode.position = bakedGoodStrikePoint
        bakedGoodNode.physicsBody!.velocity = notMoving
        bakedGoodNode.physicsBody!.clearAllForces()
        residueLoc = bakedGoodStrikePoint
        bakedGoodNode.name = bakedGoodName
        bakedGoodNode.geometry?.firstMaterial?.diffuse.contents = UIColor.clear
        
        // Once we convert to residue disable all collision detection to avoid a scenario where contact is
        // made with something else just at the point where we're removing the residue from the scene.  When this
        // happens the game crashes because of a race condition where the baked good is removed but then referenced
        // by the collision detection code.  So we avoid that by disabling any interaction by the residue.
        // It still could be a problem, though, if the other object still can collide with it, though, which is
        // what we see when a baked good hits another one in the same spot.
        bakedGoodNode.physicsBody!.categoryBitMask = noCollisionCategory
        bakedGoodNode.physicsBody!.collisionBitMask = 0
        
        bakedGoodNode.physicsBody!.isAffectedByGravity = false
        
        // It makes sense to create the residue here to cut down on memory usage.  While creating the residue when the
        // baked good was created makes sense, it would be a waste of memory.  Not all residue would be created at the same
        // time so in theory we would be saving some memory by only created the residue after impact.  But it is dangerous
        // and we would have to always check that the residue exists before doing anything with it.
        
        residueNode = allModelsAndMaterials.residueModel.clone()
        residueNode.geometry = allModelsAndMaterials.residueModel.geometry?.copy() as? SCNGeometry
        residueNode.geometry?.firstMaterial = allModelsAndMaterials.residueModel.geometry?.firstMaterial?.copy() as? SCNMaterial
        residueNode.geometry?.firstMaterial?.multiply.contents = getColorForBakedGoodAndResidue(itemType: ammoType.prizeType)
        residueNode.scale = SCNVector3(0.5, 0.5, 0.5)
        
        // give the residue node the same physical characteristics as the baked good node upon impact.
        residueNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        residueNode.physicsBody!.categoryBitMask = noCollisionCategory
        residueNode.physicsBody!.collisionBitMask = 0
        residueNode.physicsBody!.isAffectedByGravity = false
        residueNode.position = residueLoc
        
        bakedGoodState = .fallingresidue
    }
    
    func showSplatter(sceneView: SCNView, componentType: LevelComponentType, locationOfComponent: SCNVector3) {
        splatter = allModelsAndMaterials.splatterModelLarge.clone()
        splatter.geometry = allModelsAndMaterials.splatterModelLarge.geometry?.copy() as? SCNGeometry
        // we have to force unwrap the geometry; Xcode complains if we use '?' so we make sure it's not nil before we use it.
        if splatter.geometry != nil {
            for i in 0...allModelsAndMaterials.splatterModelLarge.geometry!.materials.count - 1 {
                let splatterMaterial = allModelsAndMaterials.splatterModelLarge.geometry!.materials[i].copy() as! SCNMaterial
                splatter.geometry!.materials.append(splatterMaterial)
            }
        }
        // Note: material 1, not 0, the firstMaterial, is the one that we assign the pie filling color to.
        // See comments in AllModelsAndMaterials class for how we found that.
        splatter.geometry?.materials[1].multiply.contents = getColorForBakedGoodAndResidue(itemType: ammoType.prizeType)
        if componentType == .playerrobot || componentType == .airobot {
            let midX = getMidPoint(p1: bakedGoodNode.presentation.position.x, p2: locationOfComponent.x)
            let midZ = getMidPoint(p1: bakedGoodNode.presentation.position.z, p2: locationOfComponent.z)
            splatter.position = SCNVector3(x: midX, y: bakedGoodNode.presentation.position.y, z: midZ)
        }
        else {
            splatter.position = bakedGoodNode.presentation.position
        }
        
        
        splatter.scale = SCNVector3(4.0, 2.0, 4.0)
        
        var expansionFactor: CGFloat = 6.0
        let bakedGoodSize = getBakedGoodSize(bakedGoodThrown: ammoType)
        // assume large baked good by default since most are large.  But small does exist
        // so we check for that and adjust accordingly.
        if bakedGoodSize == small {
            expansionFactor = 4.0
        }

        let expandSplatter = SCNAction.scale(to: expansionFactor, duration: 0.1)
        var finalSplatterLocation = bakedGoodNode.presentation.position
        finalSplatterLocation.y = -10.0
        let waitWhileImpactAppears = SCNAction.wait(duration: 0.1)
        let moveDownward = SCNAction.move(to: finalSplatterLocation, duration: 3.0)
        let fadeAway = SCNAction.fadeOut(duration: 0.5)
        let moveDownwardSequence = SCNAction.sequence([waitWhileImpactAppears, moveDownward])
        let splatterParticles = splatterParticleSystem
        splatterParticles!.emissionDuration = 4.0
        // resize splat to a much larger splat only if the baked good is large.
        if ammoType.mass == large || ammoType.corrosiveness == large || ammoType.stickiness == large {
            splatterParticles!.particleSize = 1.30
        }
        bakedGoodNode.addParticleSystem(splatterParticles!)
        // We waited until everything was set up above and then perform the additions and actions here, to reduce any noticeable
        // performance impact.
        sceneView.scene?.rootNode.addChildNode(splatter)
        
        // run all actions at the same time to give all-happening-at-the-same-time effect(?)
        splatter.runAction(expandSplatter, forKey: "expand")
        splatter.runAction(fadeAway, forKey: "fade")
        splatter.runAction(moveDownwardSequence, forKey: "moveDown")
    }    
}
