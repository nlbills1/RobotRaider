//
//  EMPGrenade.swift
//  RobotRaider
//
//  Created by Nathanael Bills on 9/15/17.
//  Copyright © 2017 invasivemachines. All rights reserved.
//

import Foundation
import SceneKit

class EMPGrenade {
    var empGrenadeNode: SCNNode!
    var whoHurled: String!                      // For now just the player throws but we try to keep this general in
                                                // case in a future update the ai robots throw emp grenades.
    var empGrenadeName: String = ""
    
    var initialVelocity: SCNVector3!
    
    var spent: Bool = false                     // spent grenade.  In other words the emp has gone off and now it's just a husk.
                                                // We use this to tell us when the grenade can be removed from the 
    
    init (startingPoint: SCNVector3, targetPoint: SCNVector3, hurlingSpeed: Float, empGrenadeName: String, whoThrewIt: String, robotDimensions: RobotDimensions) {
        var xVelocity: Float = 0.0
        var yVelocity: Float = 0.0
        var zVelocity: Float = 0.0
        
        let empGrenadeRadius = CGFloat(0.4)
        
        let maxDistanceToEdgeOfRobot = Float(sqrt(robotDimensions.width*robotDimensions.width + robotDimensions.length*robotDimensions.length))
        // The baked good must start flying a certain distance away from the robot.  This doesn't matter so much for baked goods from the player
        // because those don't impact it but for baked goods from ai robots, which can impact both the player and other ai robots, this is necessary
        // to prevent the baked good from impacting the robot that launched it.  Include a little fudge factor so we aren't too close to the robot at launch.
        let mandatoryStartDistanceFromRobot =  Float(empGrenadeRadius) + maxDistanceToEdgeOfRobot + 0.4

        // player robot throws an emp grenade.  We want the grenade to go exactly where
        // the player specifies they should go.  Oddly, the calculations below result in a grenade being
        // thrown a bit (maybe 20%) beyond the target point.  Why that is I still don't know.  But it seems
        // to work ok.  Will it look reasonble during play on the device, though?
        let deltax = (targetPoint.x - startingPoint.x)
        let deltaz = (targetPoint.z - startingPoint.z)
        var xzRangeToTarget: Float = 0.0
            
        let maximumDistance = (hurlingSpeed*hurlingSpeed) * sin(2*angleForMaximumDistance)/forceOfEarthGravity
        xzRangeToTarget = sqrt(deltax*deltax + deltaz*deltaz)
            
        var throwingAngle: Float = 0.0
        // Note: given a certain hurling speed the grenade can only go as far as the AngleForMaximumDistance allows.
        // Any farther than that and the player just can't throw the grenade that far.  So if the target is too far
        // away we just try the throwing angle for maximum distance that we can get given the hurling speed.
        if xzRangeToTarget > maximumDistance {
            throwingAngle = angleForMaximumDistance
        }
        else {
            // Note: we _assume_ the height of the target is pretty much the same as that of the player's robot
            // because only the player is throwing the emp grenade (for now).  This is much different than the
            // baked good because the superbaker and the pastry chef are a bit taller than the player so their
            // height increases have to be taken into account when they throw.  But we don't have that problem
            // here because the emp grenade is only thrown by the player.
            throwingAngle = 0.5 * asin((xzRangeToTarget * forceOfEarthGravity)/(hurlingSpeed*hurlingSpeed))
                
        }
        
        if throwingAngle > defaultPlayerRobotThrowingAngle {
            throwingAngle = defaultPlayerRobotThrowingAngle
        }
            
        yVelocity = hurlingSpeed * sin(throwingAngle)
        let xzVelocity = hurlingSpeed * cos(throwingAngle)
        xVelocity = xzVelocity * (deltax/xzRangeToTarget)
        zVelocity = xzVelocity * (deltaz/xzRangeToTarget)
        
        let timeAtLaunchPoint = mandatoryStartDistanceFromRobot / xzVelocity
        let launchY = yVelocity * timeAtLaunchPoint + startingPoint.y
        let launchX = xVelocity * timeAtLaunchPoint + startingPoint.x
        let launchZ = zVelocity * timeAtLaunchPoint + startingPoint.z
    
        whoHurled = whoThrewIt
        let empGrenadeGeometry = SCNSphere(radius: empGrenadeRadius)
        empGrenadeNode = SCNNode(geometry: empGrenadeGeometry)
        empGrenadeNode.position = SCNVector3(launchX, launchY, launchZ)
        empGrenadeNode.name = empGrenadeName
        self.empGrenadeName = empGrenadeName
        empGrenadeNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        // Be sure to assign the mass we have for the emp grenade.  Otherwise the default 1.0 kg that SceneKit uses will
        // be assigned and that causes the emp grenade to be as massive as robots, pushing them around upon contact.
        empGrenadeNode.physicsBody!.mass = CGFloat(prizesList[empGrenadeIndexInPrizesList].mass)
        
        // We add collision category mainly to make the grenade bounce off things.  It doesn't matter what
        // it makes contact with because it goes off in after a set time has passed.  
        empGrenadeNode.physicsBody!.categoryBitMask = collisionCategoryEMPGrenade
        empGrenadeNode.physicsBody!.collisionBitMask = collisionCategoryGround | collisionCategoryWall | collisionCategoryAIRobot | collisionCategoryPlayerRobot | collisionCategoryAIRobotBakedGood | collisionCategoryPlayerRobotBakedGood | collisionCategoryLevelComponent
        // Note: when the grenade hits a hole or the exit, we just want it to disappear.  But all the rest we want to bounce yet
        // also be detected for a collision so we can play a bounce sound.  Hence, our inclusion of all the components for contact
        // detection.
        empGrenadeNode.physicsBody!.contactTestBitMask = collisionCategoryHole | collisionCategoryLevelExit | collisionCategoryGround | collisionCategoryWall | collisionCategoryAIRobot | collisionCategoryPlayerRobot | collisionCategoryAIRobotBakedGood | collisionCategoryPlayerRobotBakedGood | collisionCategoryLevelComponent
        empGrenadeNode.physicsBody!.velocity = SCNVector3(xVelocity, yVelocity, zVelocity)
        initialVelocity = SCNVector3(xVelocity, yVelocity, zVelocity)
        empGrenadeNode.geometry?.firstMaterial?.diffuse.contents = UIColor.gray 
    }
    
    func chargeEMP () {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = empGrenadeCreateEMPDuration
        let materials = (empGrenadeNode.geometry?.materials)! as [SCNMaterial]
        let material = materials[0]
        material.diffuse.contents = UIColor.white
        SCNTransaction.commit()
    }
}
