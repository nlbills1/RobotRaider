//
//  RobotHealth.swift
//  RobotRaider
//
//  Created by Nathanael Bills on 9/5/17.
//  Copyright © 2017 invasivemachines. All rights reserved.
//

import Foundation
import SceneKit

class RobotHealth {
    // Note: we add starting resistances, which will not change through the life
    // of the robot.  These are the full resistance values and may change for robots
    // like the superworker, superbaker, homing, camouflaged, and pastry chef
    // robots that may have resistances 2x or 3x times normal.
    var startingCorrosionResistance: Double = fullCorrosionResistance
    var startingStaticDischargeResistance: Double = fullStaticDischargeResistance
    var startingFireResistance: Double = fullFireResistance
    var startingMobility: Double = fullMobility
    
    // dynamic resistances that change over time as a robot gets hit by
    var corrosionResistance: Double = fullCorrosionResistance
    var staticDischargeResistance: Double = fullStaticDischargeResistance
    var fireResistance: Double = fullFireResistance
    var mass: Double = fullMass
    var mobility: Double = fullMobility     // how stuck the robot is from being hit by sticky ammo.  The less mobile it is the more it was hit with
    // sticky baked goods that impede its progress.
    var centerOfGravity: Float = Float(robotCenterOfGravity)      // the center of gravity for the robot, for use in determining impact location.
    // For now it's a default value but we will vary it later because the robot sizes should vary.
    
    var reloadTime: Double = 0.0            // We put reload time here because we can then change it during a power up like we can with other 
                                            // robot health items.  Philosophically, it sort of affects the robot's health by helping it stay alive
                                            // longer the lower it is.
    // We should just make an array of reload timers but for now we make specific reload timers that we
    // update only when the player has selected specific weapons to use.  It's not as elegant but is
    // specific and less error-prone.
    // These are ONLY for the player's robot.
    var zapReloadTime: Double = 0.0
    var timeZapperReloadStarted: Double = 0.0
    var zapCount: Int = 0       // keep track of how many times the zap has been done between reload times -- for player robot only.
                                // The zapping can continue as long as the zaps don't exceed a max, which we define in our global constants.
                                // We set that max to allow the player to take out weaker robots with one long continuous zap (multiple individual
                                // zaps) but that won't take out the strong robots, which is behavior we want.
    
    var flameCount: Int = 0     // keep track of how many times flames have shot out of the bunsen burner -- for the player robot only.  
                                // The flames continue as long as the flames don't exceed the max count, which we define in our global constants.
                                // We set the max to allow the player to take out weaker robots with one long continues burst from the burner (multiple
                                // individual flames) but won't take out strong robots, which is the behavior we want.  The bunsen burner will also
                                // hit multiple robots with the same damage if they all happen to be in the same row, column location in the level grid.
    
    var bunsenBurnerReloadTime: Double = 0.0
    var timeBunsenBurnerReloadStarted: Double = 0.0
    
    // Note: we don't have a timer for the second baked good reload time.  Instead
    // we choose to launch the second baked good shortly after the first.  This is simpler
    // and we don't have to keep track of another reload time.
    
    var originalReloadTime: Double = 0.0
    
    // Note: these should all remain false for ai robots, which don't get any power ups.
    var speedPowerUpApplied: Bool = false
    var throwingForcePowerUpApplied: Bool = false
    
    // the amount of time the power up will last.
    var powerUpTimeLimit: Double = 0.0
    
    var powerUpMultiple: Int = 0       // the multiple by which the health component is multipled from a power up.
    var powerUpName: String = ""        // the name of the current power up.  We use that to 
    var powerUpType: PowerUpType = .noPowerUp
    
    var powerUpEnabled: Bool = false       // flag to let us know that a power up has been enabled.  This only applies to the player's robot.
    var timePowerUpStarted: Double = 0.0
    var recoveryAmount: Double = defaultRobotRecoveryAmount    // amount robot recovers from damage during a time interval.
    
    init(playerType: PlayerType, robotType: RobotType) {
        
        setRecoveryAmount(playerType: playerType, robotType: robotType)
        if playerType == .localHumanPlayer {
            reloadTime = defaultPlayerReloadTime
        }
        else {  // for now there's only the ai robot that is not the local human player so we default to that.
            reloadTime = defaultAIRobotReloadTime
        }
        for aPrize in prizesList {
            if aPrize.prizeName.range(of: zapperWeaponLabel) != nil {
                zapReloadTime = aPrize.reloadTime
            }
        }

    }
    
    func setRecoveryAmount(playerType: PlayerType, robotType: RobotType) {
        if playerType == .localHumanPlayer {
            recoveryAmount = defaultRobotRecoveryAmount
        }
        else {
            switch robotType {
            case .superworker:
                recoveryAmount = acceleratedRobotRecoveryAmount
            case .superbaker:
                recoveryAmount = acceleratedRobotRecoveryAmount
            case .pastrychef:
                recoveryAmount = acceleratedRobotRecoveryAmount
            default:        // by default use the standard recovery amount.
                recoveryAmount = defaultRobotRecoveryAmount
                break
            }
        }
    }
    
    func setReloadTime(timeLapseForReload: Double) {
        reloadTime = timeLapseForReload
        if powerUpEnabled && powerUpType == .fasterReloadPowerUp {
            reloadTime /= Double(powerUpMultiple)
        }
        originalReloadTime = timeLapseForReload
    }
    
    func applyPowerUp(powerUp: PowerUp) {
        removePowerUp()     // be sure to remove the old power up, if any, before applying a new one.
                            // Otherwise, the cruft left behind could keep the new power up from functioning properly.
                            // We see this when the time limit may never be reached if the new power up is enabled
                            // on top of the old one--the old one goes out into limbo, never to end.
        powerUpEnabled = true
        powerUpTimeLimit = Double(powerUp.timePowerUpLasts)
        powerUpType = powerUp.powerUpType
        powerUpMultiple = powerUp.powerUpMultiple
        timePowerUpStarted = NSDate().timeIntervalSince1970
        
        switch powerUp.powerUpType {
        case .throwingForcePowerUp:
            throwingForcePowerUpApplied = true
        case .fasterReloadPowerUp:
            originalReloadTime = reloadTime
            reloadTime /= Double(powerUpMultiple)
        case .speedPowerUp:
            speedPowerUpApplied = true
            mobility = startingMobility * Double(powerUpMultiple)
            // Note: we can't update the robot's speed here.  We have to do that with
            // the updateDirectionAndVelocity() function in the Robot class.  So the
            // real application of speed has to happen after we're done here.
        default:
            break
        }
    }
    
    func removePowerUp() {
        powerUpEnabled = false
        powerUpTimeLimit = 0      // it should be zero but set it to be sure.
        powerUpMultiple = 0
        switch powerUpType {
        case .throwingForcePowerUp:
            throwingForcePowerUpApplied = false
        case .fasterReloadPowerUp:
            reloadTime = originalReloadTime
        case .speedPowerUp:
            speedPowerUpApplied = false
            mobility = startingMobility // Reset to normal mobility - a side benefit of the
                                    // speed power up is that it removes any slowdowns 
                                    // from residues even after the power up is over.  
                                    // However, we have to somehow deal with residues that
                                    // are still hanging on after the power up is over.
            // Note: we can't update the robot's speed here.  We have to do that with
            // the updateDirectionAndVelocity() function in the Robot class.  So the
            // real application of speed has to happen after we're done here.
        default:
            break
        }
        
    }
    
    func countDownPowerUpTime() -> PowerUpTimeLimitFlag {
        let currentTime = NSDate().timeIntervalSince1970
        var timeLimitFlag: PowerUpTimeLimitFlag = .timeLimitNotExceeded
        
        if currentTime - timePowerUpStarted > powerUpTimeLimit {
            timeLimitFlag = .timeLimitExceeded
        }
        return timeLimitFlag
    }
    
    // we get the fraction of power up time left here.  This directly (and I mean 1-for-1)
    // correlates to the fraction of transparency for the power up attached as a powerup
    // on the back of the player's robot.
    func getFractionOfPowerUpTimeLeft() -> Double {
        var fractionOfTimeLeft: Double = 0.0
        let currentTime = NSDate().timeIntervalSince1970
        
        // only get that fraction if the time hasn't been exceeded.  After that
        // the fraction of time remains the initial zero value because there's
        // no point in getting a fraction when the time has been exceeded.
        if currentTime - timePowerUpStarted < powerUpTimeLimit {
            fractionOfTimeLeft = 1.0 - (currentTime - timePowerUpStarted) / powerUpTimeLimit
        }
        
        return fractionOfTimeLeft
    }
    
    // functions to reduce healt of robot when hit by static discharge,
    // emp, or baked good.  The emp and zap are both static discharges.
    func hitWithStaticDischarge(staticDischarge: Double) {
        staticDischargeResistance -= staticDischarge
    }
    
    
    // bunsen burn hits.
    func hitWithFlames(flameDamage: Double) {
        fireResistance -= flameDamage
    }
    
    func corrode(byAmount: Double) {
        // The Large and Small ammounts are geared toward impact, which makes
        // them puny for corrosiveness so we multiply by 1.5 to beef them up some.
        corrosionResistance -= 1.5 * byAmount
    }
    
    func reduceMobility(stickiness: Double) {
        // sticky baked goods should have no effect on speed/mobility of
        // robot if the speed power up is in effect.
        if speedPowerUpApplied == false {
            // The Large and Small ammounts are geared toward impact, which makes
            // them puny for stickiness so we multiply by 1.5 to beef them up some.
            mobility -= 1.5 * stickiness
            if mobility < 0.0 {
                mobility = 0.0
            }
        }
    }
    
    // return true if the robot is not in 99% health in all categories.
    func isDamaged() -> Bool {
        var robotIsDamaged: Bool = false
        
        
        if corrosionResistance / startingCorrosionResistance < nearFullHealth || staticDischargeResistance / startingStaticDischargeResistance < nearFullHealth || mobility / startingMobility < nearFullHealth || fireResistance / startingFireResistance < nearFullHealth {
            robotIsDamaged = true
        }
        return robotIsDamaged
    }
    
    // get states of different health aspects of robot
    func staticHealth() -> Double {
        let health: Double = staticDischargeResistance / startingStaticDischargeResistance
        return health
    }
    
    func corrosionHealth() -> Double {
        let health: Double = corrosionResistance / startingCorrosionResistance
        return health
    }
    
    func mobilityHealth() -> Double {
        let health: Double = mobility / startingMobility
        return health
    }
    
    func fireResistantHealth() -> Double {
        let health: Double = fireResistance / startingFireResistance
        return health
    }
    
    // restoreSomeHealth() is intented to restore some health to a robot after some interval has passed.
    // This is to give the real impression that the robots will automatically recover from damage but at
    // a slow pace as internal nanobots fix things over time.
    func restoreSomeHealth() {
        // We restore all health components a little bit as time passes.
        mobility += recoveryAmount * fullMobility
        if speedPowerUpApplied == false && mobility/startingMobility > 1.0 {
            mobility = startingMobility
        }
        else if speedPowerUpApplied == true && mobility/startingMobility > Double(powerUpMultiple) {
            mobility = startingMobility * Double(powerUpMultiple)
        }
        corrosionResistance += recoveryAmount * fullCorrosionResistance
        if corrosionResistance/startingCorrosionResistance > 1.0 {
            corrosionResistance = startingCorrosionResistance
        }
        staticDischargeResistance += recoveryAmount * fullStaticDischargeResistance
        if staticDischargeResistance/startingStaticDischargeResistance > 1.0 {
            staticDischargeResistance = startingStaticDischargeResistance
        }
        fireResistance += recoveryAmount * fullFireResistance
        if fireResistance/startingFireResistance > 1.0 {
            fireResistance = startingFireResistance
        }
    }
    
    // For ai robots when we give them a higher or lower reisistance or mobility.
    // These functions are intended to be used at initial set up of robots, before any
    // interaction takes place where the resitances or mbility are changed by impact from
    // baked goods.
    func multiplyMass (by: Double) {
        mass *= by
    }
    
    func multiplyCorrosionResistance (by: Double) {
        corrosionResistance *= by
        startingCorrosionResistance = corrosionResistance
    }
    
    func multiplyStaticDischargeResistance (by: Double) {
        staticDischargeResistance *= by
        startingStaticDischargeResistance = staticDischargeResistance
    }
    
    func multiplyBurnResistance (by: Double) {
        fireResistance *= by
        startingFireResistance = fireResistance
    }
}
