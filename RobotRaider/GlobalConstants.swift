//
//  GlobalConstants.swift
//  RobotRaider
//
//  Created by Nathanael Bills on 10/13/16.
//  Copyright © 2016 invasivemachines. All rights reserved.
//

import Foundation
import SceneKit
import SpriteKit

var allModelsAndMaterials: AllModelsAndMaterials = AllModelsAndMaterials()           // We load all the models and materials at game start.  That way we only do it once.

// we try to load the particle systems at game startup to avoid lag.  It looks like it's working.
let splatterParticleSystem = SCNParticleSystem(named: "BakedGoodSplatterSmall.scnp", inDirectory: nil)
let catchingFireParticleSystem = SCNParticleSystem(named: "OnFire.scnp", inDirectory: nil)
let shortCircuitingParticleSystem = SCNParticleSystem(named: "ShortCircuiting.scnp", inDirectory: nil)

var gameSounds: GameSounds = GameSounds()

let delayWhileLevelIntroSoundPlays = 3.0                // Delay 3.0 seconds while intro sound plays.  Note: Sound could go longer but we only delay this amount before robots
                                                        // can move.

let highestLevelNumber = 61                             // The highest level that can be completed.  This is based on the
                                                        // number of challenges created in the init_challenges() function in the 
                                                        // Level class.  So any changes made there would also result in this number
                                                        // having to be changed.  It's kludgy but works for now.

let noCollisionCategory = 1
let collisionCategoryGround = 2
let collisionCategoryAIRobotBakedGood = 4
let collisionCategoryAIRobot = 8
let collisionCategoryWall = 16
let collisionCategoryLevelComponent = 32
let collisionCategoryLevelExit = 64
let collisionCategoryPlayerRobot = 128
let collisionCategoryPart = 256
let collisionCategoryDyingRobot = 512
let collisionCategoryPowerUp = 1024
let collisionCategoryHole = 2048
let collisionCategoryEMPGrenade = 4096
let collisionCategoryVaultBarrier = 8192
let collisionCategoryVault = 16384
let collisionCategoryPlayerRobotBakedGood = 32768
let collisionCategoryLevelEntrance = 65536
let collisionCategoryLevelExitDoorway = 131072
let collisionCategoryBunsenBurnerRangeFinder = 262144
let collisionCategoryBunsenBurnerFlame = 524288
let collisionCategoryVaultDoorway = 1048576

// The steam cloud doesn't have a physics body so we don't call this a collision category,
// just a category.  We're using this to tell hitTest to ignore the steam cloud by ignoring
// any node that doesn't have CategoryRegisterInHitTest as its CategoryBitMask setting.  Right
// now only the ground has CategoryRegisterInHitTest set and that seems to work fine.  7/21/2018 -- nlb
let categorySteamCloud = 262144
let categoryRegisterInHitTest = 1

let wideAngleCameraLens = CGFloat(100.0)             // Use a wider camera angle to give the player more warning when robots are coming from the side.

let highestLearningLevel = 11                       // Highest level at which the player is still considered learning the game.  We specify this
                                                    // because we want to start the ai robots farther away from the player in the learning levels
                                                    // then we do in the other levels after those.

let numberOfRenderLoopsBetweenPlayerVelocityUpdates = Int64(10)  // We don't want to update the velocity at every renderer loop as that can cause jerkiness.  On the other
                                                         // hand we also want to allow the player to immediately switch directions and velocity so we have a compromise.
                                                        // This constant allows for regular updates at certain number of renderer loops.  It will be up to the code
                                                        // that updates the player's direction and velocity on how it handles a player changing direction through a swipe.

let vaultBarrierOriginalColor = UIColor.blue            // the color of the vault barrier when the player isn't touching it.
let vaultBarrierPermissionDeniedColor = UIColor.red     // the color of the vault barrier when the player touches it and doesn't have all the key parts.

// zap colors for different robot zappers.
let playerZapColor = UIColor.green
let zapperZapColor = UIColor.yellow
let pastryChefZapColor = UIColor.red

// The aura is a sort of glow around the top of the robot when it zaps.  It represents a charge buildup,
// but an instantaneous charge buildup rather than one that happens over time.  These are the parameters for
// the aura, as a cylinder.
let playerZapAuraRadius = CGFloat(0.7)
let defaultZapAuraRadius = CGFloat(0.4)
let defaultZapAuraHeight = CGFloat(0.5)
let pastryChefZapAuraRadius = CGFloat(0.7)
let pastryChefZapAuraHeight = CGFloat(0.5)

let fractionOfScreenUsedForMap = CGFloat(0.15)         // 15%
let fractionOfScreenUsedForReloadStatusBar = CGFloat(0.15)
let fractionOfScreenUsedForStatusIcon = CGFloat(0.10)
let defaultStatusBarUpdateInterval = Double(0.2)    // update reload status bars ever 1/5th of a second.
let gravityAssistForDescentIntoHole = SCNVector3(0.0, -9.8, 0.0)       // Gravity needs help.  Otherwise it takes way, way too long for the player's robot to fall.
let forwardForceIntoHole = Float(5.0)

let yValueAtWhichBakedGoodCanBeRemoved = Float(-2.0)  // When a baked good's y position is at this point, it is below the floor and can be removed
                                                       // from the game.  This happens once it is no longer sticking as residue and is falling.  At 
                                                       // some point it will fall through the floor and once it has fallen all the way through the floor
                                                       // we want to remove it.

// The camera's x and z offset from the player's robot.
let cameraFirstPersonViewYOffset = Float(1.0)           // The first person view offset -- at ground level.
let cameraFirstPersonViewZOffset = Float(5.0)
let cameraFirstPersonViewXOffset = Float(0.0)

let cameraOverheadViewYOffset = Float(100.0)             // The overhead view offset.
let cameraTwoAndAHalfDViewYOffset = Float(15.0)
let cameraTwoAndAHalfDViewZOffset = Float(10.0)

let cameraTwoAndAHalfDViewXOffset = Float(0.0)
let cameraTwoAndAHalfDViewAngle = SCNVector3(-15.0 * Double.pi / 48.0, 0.0, 0.0)

let cameraFirstPersonViewAngle = SCNVector3(0.0, 0.0, 0.0)

let pieRadius = CGFloat(1.4)
let pieHeight = CGFloat(0.6)

let bunsenBurnerFlameMaximumRadius = CGFloat(1.5)
let bunsenBurnerFlameMaximumLength = CGFloat(20.0)

let bunsenBurnerMaxLevelCoordinateRange = 6             // maximum range, either row or column wise, that the bunsen burner can reach.
let maximumBunsenBurnerFlameSize = Float(3.0)                  //  just a guess at the flame size to narrow the effectiveness of the flame.  Otherwise
                                                        // robots can be hit by flames without actually being in the flames.
let noLauncherReadyToFire = -1          // signifies that all the launchers are still reloading.
let launcherReadyToFire = 0.0           // This signifies that one launcher is ready to fire.  It is also what we use to initialize
                                        // The timeReloadStarted array.
let playerLauncherRotationDuration = 0.5        // it takes 0.5 seconds for the player's launcher to rotate, in any direction.

let minimumAIRobotThrowingRange = Float(10.0) // the minimum throwing range, in number of level coordinate rows, for the ai robots.
let mediumAIRobotThrowingRange = Float(15.0)
let maximumAIRobotThrowingRange = Float(30.0)

let minimumAIRobotHomingRange = 5 // the minimum homing range, in number of level coordinate rows, for the ai robots.
let mediumAIRobotHomingRange = 10
let maximumAIRobotHomingRange = 15  // for the homing and ghost ai robots only.

let maximumAIZapRange = Float(6.0)  // Because the zapper is such a short range weapon, we don't use level coordinates but actual
                             // scene coordinates.  This would be the distance to target in that coordinate space.
let maximumAIPastryChefZapRange = Float(8.0)   // The pastry chef has a zap range all its own, that's different, and longer range,
                                                // than the normal zapper.  Right now we make it slightly less than the player's zap range.
                                                // The advantage still goes to the pastry chef as it is more resistant.

let maximumPlayerZapRange = Float(10.0)
let minimumPlayerThrowDistance = Float(4.0)    // the minimum 3d distance away from player's robot where the player must tap in order
                                                // to throw a baked good.

let maximumWorkerAIRobotLungeReach = Float(4.0)  // The maximum distance a worker robot can lunge if player is close.
let maximumSuperWorkerAIRobotLungeReach = Float(4.0) // The maximum reach for a super worker's lunge.
let knockOverScalarForce = Float(100.0)

let maximumAIRobotBlastRadius = Float(15.0)          // blast radius for both homing and ghost robots.
let maximumEMPGrenadeBlastRadius = Float(10.0)      // for now make the blast radius of the player's emp grenade is only 2/3 the blast radius of the robots.

let initialElectromagneticPulseRadius = Float(0.5)     // the blast radius of the initial emp, before it expands.
let robotCreateEMPDuration = Double(0.5)
let empGrenadeCreateEMPDuration = robotCreateEMPDuration  // for now make the creation of emp the same time amount as that for the robots that create emp.
let empGrenadeTimeDelayFuseLength = Double(1.0)      // the time delay the grenade waits before charging and going off.

let playerZapLingerTime = 0.01
let defaultZapLingerTime = 0.01              // default zap linger time for ai robots
let lightningLingerTime = 0.01
let flameLingerTime = 0.2

let aiRobotsAddedReloadTime = 2.0   // fudge factor to increase ai robot's reload time to give the player a slight edge.
                                    // The player will need it when there are huge numbers of ai robots in the level.

let timeDelayForBackButtonToWork = 0.5      // The time delay for a tap on the back button to show a response before the segue actually happens.
let fadeOutTimeDelay = 1.0                  // The time delay we use to allow the fade out to complete.

let healthPrettyMuchGone = 0.01     // Signifies that the health, either static resistance or corrosion resistance, or fire resistance
                                    // is down to 1/100th or pretty much gone.  In that case, we consider the robot dead and should
                                    // be shut down.

let nearFullHealth = 0.99           // when the robot is near full health from any type of damage and isn't in need of repair.  This is a percentage, representing 99% healthy

// bits used to determine if the player is not within line of sight of the ai robot,
// either totally obscured by a wall or there is something else in the way.  If totally
// obscured then no ai robot, not even bakers, can attack.  If something else is in the way,
// another robot or a fixed level component, then bakers, homing and ghost robots can
// still attack but not workers, superworkers or zappers.
let pathIsNotEmpty = 1
let pathIsTotallyObscured = 2
let pathClear = 0

let normalWheelRadius = Float(0.8)          // 0.8 meters is the normal wheel radius of a robot.  We may use something different for the pastry chef.
let normalWheelCircumference = Float(2 * Float.pi * normalWheelRadius)   // We need the circumference to determine the angular velocity from the linear.

let defaultPlayerRobotThrowingAngle = Float(30 * 0.0174533) // 30 degrees, converted to radians
let defaultPlayerRobotThrowingSpeed = Float(30.0)   // IMPORTANT NOTE:  I'm not sure what the minimum is but we have to
                                                    // have a certain minimum speed.  Otherwise, when the player taps beyond a certain
                                                    // distance from the player's robot the calculations are screwed up and the baked good
                                                    // hangs in front of the player's robot.  30.0 seems to be a good speed--everything works.
let defaultPlayerRobotMovingSpeed = Float(10.0)
let fallingIntoHoleSpeed = Float(2.0)

let angleForMaximumDistance = Float(30 * 0.0174533) // 30 degrees, converted to radians

let forceOfEarthGravity = Float(9.8)              // 9.8 meters/(seconds squared)

let defaultAIRobotSpeed = Float(4.0)
let minimumAIRobotSpeed = Float(0.1)    // A minimum speed the ai robot must have to be considered moving.  Otherwise it is
                                        // considered stopped and we want to get it moving again.

let maximumRandomMovesToTryToAvoidObstacle = 3  //  Minimum random moves to get around obstacles.

let defaultAIRobotThrowingSpeed = Float(20.0)       // The speed that the baked goods start with when hurled by ai robots.

let ghostRobotTransparency = CGFloat(0.25)           // the transparency to apply to all parts of the ghost robot, the body and the wheels.
// Note: even though the default is Double if we don't specify the type for a non-Integer number, we still explicitly 
// specify Double here just to be sure.
let defaultPlayerReloadTime = Double(0.5)
let defaultAIRobotReloadTime = Double(1.0)
let defaultRobotZapperRechargeTime = Double(2.0)
let defaultRobotBunsenBurnerRechargeTime = Double(2.0)
let defaultRobotBunsenBurnerBurnTime = Double(1.0)              // the length of time the bunsen burner is supposed to keep burning before reloading.
let defaultBunsenBurnerBurnCheckIntervalTime = Double(0.1)      // the interval at which we check to see what ai robot is burning.
let defaultAIRobotSwitchDirectionDelay = Double(1.0)
let defaultRobotYCoord = Float(1.25)            // Since we're mostly interested in the x and z coordinates for the robot, we just
                                                // use a default to set the y coordinate for now.  Later this might be changed
                                                // to take into account different robot sizes.

let defaultRobotRecoveryInterval = Double(1.0)      // interval of time where robot recovers a little bit - for corrosion, static discharge and mobility only.
let defaultImpactRecoveryInterval = Double(0.5)     // interval of time where a robot recovers from impact - note that it's a lot smaller than the
                                                    // regular recovery interval that's used for corrosion, static discharge and mobility
let defaultPlayerRobotPositionUpdateTime = Double(0.5)     // update the position every 1/2 second.

let defaultRobotRecoveryAmount = 0.1                // the default amount a robot recovers each recovery interval.
let acceleratedRobotRecoveryAmount = 0.2            // an accelerated amount a robot recovers each recovery interval, possibly to be used in later levels by
                                                    // ai robots.  Maybe make this for the higher end robots, like the super* robots and the pastry chef.

let robotShutdownDuration = 2.0                     // The time, in seconds, it takes for the robot to shut down when it has been hit and has fallen over.

// action keys for the left and right wheels.  We need them for when the player's robot is stopped so that
// we can remove the turn action.  Then later when we want to add them back we can use these keys again to
// add them.  Also, we use them when we want to stop the wheel turning for the ai robots when the player robot is destroyed.
let leftWheelTurnActionKey = "leftWheelTurn"
let rightWheelTurnActionKey = "rightWheelTurn"

let maxTougherLevels = 30

let maxPowerUpMultiple = 2    // The actual max is 3 because we add +1 to a random number selected.
let maxTimePowerUpCanLast = 50   // No more than 50 seconds can a power up last.  Period.

let maxZapCountForPlayerZapperWeapon = 20    // The max number zaps a player can zap at one time.  Usually all of them hit one robot in rapid
                                            // succession, but don't have to.

let maxZapCountForAIZapperWeapon = 10    // The max number zaps an ai robot can zap at one time.  Usually all of them hit one robot in rapid
                                        // succession, but don't have to.
let maxZapCountForPastryChefZapperWeapon = 20    // The max number zaps a pastry chef can zap at one time.  Usually all of them hit one robot in rapid
// succession, but don't have to.

// structure used to record the last robot zapped.  That way the same robot keeps getting zapped.
struct LastRobotZapped {
    var robotName: String = ""
    var robotLoc: SCNVector3 = SCNVector3Zero
    init (name: String, loc: SCNVector3) {
        robotName = name
        robotLoc = loc
    }
}

let maxFlameCountForBunsenBurner = 5        // the maximum number of flames that the player can shoot out of the bunsen burner at one time.

let powerUpMessageXOffsetFromScreenCenter = CGFloat(0.65)        // offset message by 15% in the X direction.
let powerUpMessageYOffsetFromScreenCenter = CGFloat(0.65)        // offset message by 15% in the Y direction.

let partMessageXOffsetFromScreenCenter = CGFloat(0.40)        // offset message by 10% in the X direction.
let partMessageYOffsetFromScreenCenter = CGFloat(0.40)        // offset message by 10% in the Y direction.

let stepMessageXOffsetFromScreenCenter = CGFloat(0.70)        // offset message by 20% in the X direction.
let stepMessageYOffsetFromScreenCenter = CGFloat(0.40)        // offset message by 10% in the Y direction.

// Note: We make the length and width the same because we're laying out the level using a maze and each component in
// that maze was based on the width and length being the same.
let levelComponentSpaceLength = Float(4.0)  // The maximum length of a component, in the z direction.  We make the real
// length 1.8.  That way it will easily fit in a 2.0 sized space.

let levelComponentSpaceWidth = Float(4.0)   // The maximum width of a component, in the x direction.  We make the real
                                      // width 3.6 to make it fit easily within a 4.0 space.

let standardWallHeight = Float(40.0)
let outerWallHeight = Float(40.0)
let innerWallHeight = Float(3.0)
let nearWallHeight = Float(3.0)         // near wall is a special case.  It is lower than the outer wall to allow the player to see
                                        // her robot without the wall being transparent.  Yet it's higher than the inner walls because
                                        // we want to put in the level entrance to show where the robot came from.

let standardWallBlockWidth = levelComponentSpaceWidth   // standard width of a wall block is the same as the width of a space in the level.
let standardWallBlockLength = levelComponentSpaceLength // standard length of a wall block is the same as the length of a space in the level.

// quadrants for the level exit, either the left or right side of the far wall.  We used to have the left and right walls as well
// but they became a burden to accommodate because we kept having to figure out the rotations for them to make things look right.
let farWallLeft = 0
let farWallRight = 1

// The different wall types.  We want to keep track of them because we need to extend the length of
// the right and left walls and extend the thickness of the near wall to cover up emptyp space between
// the near wall and the camera, as well as between the end of the right and left walls and the camera.
enum WallType {
    case leftwall
    case rightwall
    case farwall
    case nearwall
    case innerwall
}
// Indexes in an array for the outer and inner wall materials loaded in the AllModelsAndMaterials class.  If the
// order changes or if more materials are added, then these may need to change in value.
let outerWallMaterialIndex = 0
let innerWallMaterialIndex = 1

let levelExitDoorwayDimensions = SCNVector3(4.35, 5.77, 2.0)       // The dimensions of the level exit model that we use.  It's actually the doorway but we call it the exit.
let levelExitDimensions = SCNVector3(3.0, 4.6, 0.1)        //  These are the dimensions of the true exit, which is a box inside the level exit model.  This is what the
                                                            // player needs to touch to make an exit.
let vaultDoorwayDimensions = SCNVector3 (8.0, 8.0, 4.0)     // The dimensions of the vault model surrounding the vault.
let vaultDimensions = SCNVector3(7.0, 6.0, 0.1)         // Make the vault slightly smaller so we see it appear when the door moves out of the way.
let vaultBarrierDimensions = SCNVector3(10.0, 14.0, 9.0)  // the dimensions of the force field barrier surrounding the vault.
let minimumXDistanceFromBarrier = Float(7.0)    // roughly the x distance from center of barrier and center of robot.
let minimumZDistanceFromBarrier = Float(6.0)    // roughly the z distance from center of barrier to center of robot.
let showVaultUnlockedMessageDuration = 2.0

// Movement window.  This is an invisible window where the player's robot can move without
// the camera following it.  Once the robot gets to the edge of that window the camera starts
// to follow it.
let maxMovementWindowX = Float(1.0)
let minMovementWindowX = Float(-1.0)
let maxMovementWindowZ = Float(1.0)
let minMovementWindowZ = Float(-2.0)

// Which direction the robot is facing.  These are indices pointing to the
// direction angle in the array robotFacingDirections.
let zeroDirection = 0
let west = 1
let east = 2
let north = 3
let south = 4

// Maybe we're reinventing the wheel a little bit here but we want to
// have a specific SwipeDirections type that way we can make all operations
// dealing with it atomic.
enum SwipeDirections {
    case left
    case right
    case up
    case down
    case none 
}

let gestureHandlingQueueLabel = "com.invasivemachines.gesturehandling"    // the label for our gesture handling queue, which handles setting and getting
                                                                            // variables associated with gestures.  We use GCD to keep them in sync.
let aiRobotRemovalHandlingQueueLabel = "com.invasivemachines.airemoval"   // label for our ai robot removal.  We use this to ensure that the removal happens only
                                                                            // when it's safe.

// For debugging we translate the numbers for the directions into strings that we
// can easily interpret in log output.
func convertNumToDirection(directionNum: Int) -> String {
    var directionStr: String = ""
    
    switch directionNum {
    case 0:
        directionStr = "Zero"
    case 1:
        directionStr = "West"
    case 2:
        directionStr = "East"
    case 3:
        directionStr = "North"
    case 4:
        directionStr = "South"
    default:
        break
    }
    return directionStr
}

let angleNearZero = Float.pi / 180.0        // essentially 1 degree, for testing whether or an x or z angle is near zero.
                                             // We encounter rounding errors if we use 0.0 so we use near zero, close enough
                                             // for our purposes but large enough to avoid rounding errors.

let maxRobotAngleFromVertical = Float.pi / 4.0      // An angle more than this and the robot can't recover from the impact.

// The actual rotation angles correspondingn to the direction the robot is facing.
let facingWestAngle = SCNVector4(0.0, 1.0, 0.0, 3.0 * Double.pi/2.0)
let facingEastAngle = SCNVector4(0.0, 1.0, 0.0, Double.pi/2.0)
let facingNorthAngle = SCNVector4(0.0, 0.0, 0.0, 0.0)
let facingSouthAngle = SCNVector4(0.0, 1.0, 0.0, Double.pi)


let robotFacingDirections = [SCNVector4(0.0, 0.0, 0.0, 0.0), facingWestAngle, facingEastAngle, facingNorthAngle, facingSouthAngle]

// direction of robot movements
let notMoving = SCNVector3(0.0, 0.0, 0.0)
let movingWest = SCNVector3(1.0, 0.0, 0.0)
let movingEast = SCNVector3(-1.0, 0.0, 0.0)
let movingNorth = SCNVector3(0.0, 0.0, -1.0)
let movingSouth = SCNVector3(0.0, 0.0, 1.0)

let robotMovingDirections = [SCNVector3(0.0, 0.0, 0.0), movingWest, movingEast, movingNorth, movingSouth]

// State of the robot.  It would start off as running.  It is disabled when knocked over by a hit from a
// baked good.  The randommove state is where it starts off moving around randomly.  It switches to homing
// state when the player's robot gets within range.  And it's in avoidobstacle state when
// it is heading for an obstacle which it has to go around to get to the player.
enum RobotState {
    case random
    case homing
    case avoidobstacle
}

enum PlayerType {
    case remoteHumanPlayer              // Other human player, remote or on another device.
    case localHumanPlayer  // player local to this device being used to play the game.
    case ai
    // Note: will need to add RemoteHuman and RemoteAI later, if we every make this multiplayer.
    // When/if we do make this multiplayer we'll need to disable local AI players and run AI players
    // from the server.  Or we could have a set limit of AI players running on each device that is
    // seen by other players.  That may be too complicated to manage, however.
    case noPlayer
}

enum ViewAngle {
    case firstpersonview
    case overheadview
    case twoandahalfdview
}

enum RobotType {
    case worker         // short homing range.  Can 'punch' the player's robot if it gets too close.
    case baker        // can throw baked goods at player, and can 'punch' the player as well.
    case doublebaker  // can throw baked goods two at a time.
    case zapper         // throws lightning/sparks/deathray.
    case homing         // fast, little robots that home in on the player and fire off an electromagnetic pulse.
    case ghost         // fast, little robots that are ghosts and hard to see.  They also fire off an electromagnetic pulse.
    case superworker    // can't be knocked over or blown up by the player robot's ammo but
                        // must be tricked into following the robot into the line of fire of the fixed level
                        // components, which can fire heavier baked goods or cause more fire damage with more
                        // heat from ovens or splashes from deepfryers.
    case superbaker   // same as super work but can also throw baked goods two at a time.
    case pastrychef     // The big boss at the end.
    case noRobot
}

enum RobotThrowingBehavior {
    case throwToHitTarget
    case missTarget
}

// the behavior of the robot after impact.
enum RobotImpactBehavior {
    case tippedOver             // robot was just tipped over.
    case endOverEndFlip         // robot was hit hard enough to cause it to flip end over end.
    case littleImpact               // no impact has happened.
}

// the state of the robot after impact, whether it is still reeling from the impact, hence
// the 'impacted' case, or it's recovering, or it is fully recovered.  This is different than
// the impact behavior in that this is more of the state of the robot in trying to recover.
// The impact behavior is the point at which it either can't recover or there is hardly any effect.
enum RobotImpactOrRecoveryState {
    case impacted
    case recovering
    case notImpactedOrRecovering
}

enum RobotImpactStates {
    case tippedOver             // robot was just tipped over beyond recovery.
    case endOverEndFlip         // robot was hit hard enough to cause it to flip end over end.
    case notImpactedOrRecovering               // no impact has happened.
    case impacted               // robot was first impacted.
    case recovering
}

let minimumMissDeviation = Float(5.0)   // minimum deviation in which to miss in meters.  For ai robots targeting the player.

let minPartNumIncreaseLevelInterval = 10

// This seems like a duplication because the same information can be gleamed from the
// power up name.  However, with the type we can categorize later.  At
// the same time we can give them different names and different capabilities.  We did
// this with parts where we can accumulate just the ammo prizes from which the ai robots
// would choose ammo, yet at the same time each ammo type has different capabilities.  
// So far, though, we have yet to expand the power ups this way.
enum PowerUpType {
    case speedPowerUp
    case fasterReloadPowerUp
    case throwingForcePowerUp
    case noPowerUp
}

enum PowerUpTimeLimitFlag {
    case timeLimitExceeded
    case timeLimitNotExceeded
}

enum PartType {
    case ammoPart
    case weaponPart
    case equipmentPart
    case keyPart
    case noPart
}

struct PrizeListElement {
    var partType: PartType
    var primaryEffect: PrizePrimaryEffectOnEnemyRobot = .noEffect
    var requiredNumberOfParts: Int = 0
    var partsGatheredSoFar: Int = 0
    var prizeName: String = ""
    var prizeType: SpecificPrizeType = .noprize
    var unlocked: Bool = false   // start off every prize not being unlocked.
    var mass: Double = 0.0
    var stickiness: Double = 0.0
    var corrosiveness: Double = 0.0
    var reloadTime: Double = 0.0
    var indexNum: Int = 0      // Normally we use prizeName to reference this element but sometimes, like when we want to list
                                // them out in a numeric list, we refer to them by index number.

    init(type: PartType, numParts: Int, name: String, ptype: SpecificPrizeType, mass: Double, corrosiveness: Double, stickiness: Double, reloadTime: Double, primaryEffect: PrizePrimaryEffectOnEnemyRobot) {
        requiredNumberOfParts = numParts
        partType = type
        self.prizeName = name
        self.prizeType = ptype
        self.mass = mass
        self.corrosiveness = corrosiveness
        self.stickiness = stickiness
        self.reloadTime = reloadTime
        self.primaryEffect = primaryEffect
    }
}

struct PowerUpListElement {
    var powerUpType: PowerUpType
    var powerUpName: String = ""
    var defaultTimeLimit: Int = 0   // time limit for power up, in seconds.
    init(type: PowerUpType, defaultTimeLimit: Int, name: String) {
        self.defaultTimeLimit = defaultTimeLimit
        powerUpType = type
        self.powerUpName = name
    }
}

let speedUpPowerUpName = "SpeedUp"
let throwingForcePowerUpName = "Throwing Force"
let fasterReloadPowerUpName = "Faster Reload"

let powerUpNames = [
    speedUpPowerUpName,
    throwingForcePowerUpName,
    fasterReloadPowerUpName,
]

// Note: we make numParts zero for the power ups because they will vary in number with each level
// so it makes no sense to give them a permanent number of parts.  And they are instantaneous
// rewards whereas the permanent prizes aren't available until all of their parts have been found.
let powerUpList = [
    speedUpPowerUpName : PowerUpListElement(type: .speedPowerUp, defaultTimeLimit: 20, name: speedUpPowerUpName),
    throwingForcePowerUpName : PowerUpListElement(type: .throwingForcePowerUp, defaultTimeLimit: 20, name: throwingForcePowerUpName),
    fasterReloadPowerUpName : PowerUpListElement(type: .fasterReloadPowerUp, defaultTimeLimit: 20, name: fasterReloadPowerUpName),
]

// We use this to determine the effect that a prize will have on a robot.
// This also helps us distinguish one type of baked good from another, something
// we need to do when we're assigning different colors to different types of
// baked goods to distinguish them in game play.
enum PrizePrimaryEffectOnEnemyRobot {
    case corrosive
    case impact             // can cause the robot to tip over.
    case sticky
    case staticDischarge
    case moreFirepower
    case noEffect
}


// Note: the default inventory list is the list of default ammo or prize that every player starts with at the very
// start of the game.  Hence, they have no required parts.  However, we combine the default list with the prizesList to make
// the overall inventory list of items from which the player can select items to use in the level.  The items in the prizesList
// do have required numbers of parts to obtain, which gives the player objectives to achieve.

// sizes in terms of mass, corrosion or stickiness
let small = 0.15
let large = 0.6

// Changed the values of the prizes where the nonprimary effects are set to zero and the primary effects go from 0.0 - 1.0.
// Note: if attribute doesn't apply, then it is set to 0.0.  Also we purposely made the number of parts for sticky baked goods
// smaller than the others in the progression of rising number of parts required because they are less effective than everything
// else.
let defaultInventoryList = [
    PrizeListElement(type: .ammoPart, numParts: 0, name: custardPieLabel, ptype: .custardpie, mass: large, corrosiveness: 0.0, stickiness: 0.0, reloadTime: 4.0, primaryEffect: .impact),
    PrizeListElement(type: .ammoPart, numParts: 0, name: breadDoughLabel, ptype: .breaddough, mass: 0.0, corrosiveness: 0.0, stickiness: small, reloadTime: 1.0, primaryEffect: .sticky),
]

let prizesList = [
    PrizeListElement(type: .ammoPart, numParts: 6, name: raspberryPieLabel, ptype: .raspberrypie, mass: 0.0, corrosiveness: large, stickiness: 0.0, reloadTime: 2.0, primaryEffect: .corrosive),
    PrizeListElement(type: .ammoPart, numParts: 15, name: keyLimePieLabel, ptype: .keylimepie, mass: 0.0, corrosiveness: large, stickiness: 0.0, reloadTime: 1.0, primaryEffect: .corrosive),
    PrizeListElement(type: .equipmentPart, numParts: 25, name: motionDetectorLabel, ptype: .motiondetector, mass: 0.0, corrosiveness: 0.0, stickiness: 0.0, reloadTime: 0.0, primaryEffect: .noEffect),
    PrizeListElement(type: .ammoPart, numParts: 37, name: pumpkinPieLabel, ptype: .pumpkinpie, mass: large, corrosiveness: 0.0, stickiness: 0.0, reloadTime: 1.5, primaryEffect: .impact),
    PrizeListElement(type: .ammoPart, numParts: 30, name: cookieDoughLabel, ptype: .cookiedough, mass: 0.0, corrosiveness: 0.0, stickiness: small, reloadTime: 0.5, primaryEffect: .sticky),
    PrizeListElement(type: .equipmentPart, numParts: 45, name: hoverUnitLabel, ptype: .hoverunit, mass: 0.0, corrosiveness: 0.0, stickiness: 0.00, reloadTime: 0.0, primaryEffect: .noEffect),
    PrizeListElement(type: .equipmentPart, numParts: 85, name: extraSlotLabel, ptype: .extraslot, mass: 0.0, corrosiveness: 0.0, stickiness: 0.0, reloadTime: 0.0, primaryEffect: .noEffect),
    PrizeListElement(type: .weaponPart, numParts: 55, name: zapperWeaponLabel, ptype: .zapperweapon, mass: 0.0, corrosiveness: 0.0, stickiness: 0.00, reloadTime: defaultRobotZapperRechargeTime, primaryEffect: .staticDischarge),
    PrizeListElement(type: .ammoPart, numParts: 48, name: taffyLabel, ptype: .taffy, mass: 0.0, corrosiveness: 0.0, stickiness: large, reloadTime: 0.5, primaryEffect: .sticky),
    PrizeListElement(type: .weaponPart, numParts: 65, name: anotherLauncherLabel, ptype: .anotherlauncher, mass: 0.0, corrosiveness: 0.0, stickiness: 0.0, reloadTime: 0.0, primaryEffect: .moreFirepower),
    PrizeListElement(type: .ammoPart, numParts: 78, name: lemonJellyDonutLabel, ptype: .lemonjellydonut, mass: 0.0, corrosiveness: small, stickiness: 0.0, reloadTime: 0.5, primaryEffect: .corrosive),
    PrizeListElement(type: .ammoPart, numParts: 89, name: chocolateCupcakeLabel, ptype: .chocolatecupcake, mass: small, corrosiveness: 0.0, stickiness: 0.0, reloadTime: 0.5, primaryEffect: .impact),
    PrizeListElement(type: .weaponPart, numParts: 89, name: bunsenBurnerLabel, ptype: .bunsenburner, mass: 0.0, corrosiveness: 0.0, stickiness: 0.0, reloadTime: defaultRobotBunsenBurnerRechargeTime, primaryEffect: .moreFirepower),
    // note: we give the emp grenade a tiny bit of mass.  That way it will just bounce off of anything.  With the default 1.0 kg that
    // SceneKit gives nodes that have physics bodies, the emp grenades pushes robots around on contact and we don't want that.
    PrizeListElement(type: .ammoPart, numParts: 95, name: empGrenadeLabel, ptype: .empgrenade, mass: 0.01, corrosiveness: 0.0, stickiness: 0.0, reloadTime: 0.5, primaryEffect: .staticDischarge)
]

// Important note:  the emp grenade should be the last item in the prizes list above.  That makes it easy to specify the index of it
// that we will use later to assign mass to the emp grenade.  It's klunky and maybe a little fragile but as long as we keep this index
// constant close to the prizes list in this file, it should be ok.  
let empGrenadeIndexInPrizesList = prizesList.count - 1

let keyPrize = PrizeListElement(type: .keyPart, numParts: 5, name: keyLabel, ptype: .electronickey, mass: 0.0, corrosiveness: 0.0, stickiness: 0.0, reloadTime: 0.0, primaryEffect: .noEffect)

struct Part {
    var partNumber: Int = 0
    var prizeName: String = ""
    var retrieved: Bool = false
}

// cycle through the number of parts.  We
// keep adding on the numbers of parts as the levels go higher.
// For example, each time we get to a new challenge level we might
// add +2 parts to the list of parts that would appear in the level.
// In the prizesList we have a list of number of prizes at certain
// numbers and types.  The numbers are associated with the number of
// parts required to complete the actual overall prize and can go up 
// as the number of levels.
func getPrizeElement(partNum: Int) -> PrizeListElement {
    var i: Int = 0
    var count: Int = 0
    var nextCount: Int = 0
    var prizeListElement: PrizeListElement!
    
    count = 0
    nextCount = prizesList[i].requiredNumberOfParts
    while i < prizesList.count - 1 && prizeListElement == nil {
        if count + 1 <= partNum && partNum <= nextCount {
            prizeListElement = prizesList[i]
        }
        i += 1
        count = nextCount
        nextCount += prizesList[i].requiredNumberOfParts
    }
    // if the prizeListElement to send back is still nil then that means that we've
    // gone through all but the last one in the list, which is the highest.
    // Since there is nothing higher, just assign the partType of that last
    // item in the prizes list as the one to return.
    if prizeListElement == nil {
        prizeListElement = prizesList[prizesList.count - 1]
    }
    return prizeListElement
}

func getColorForPowerUpType (type: PowerUpType) -> UIColor {
    var color: UIColor = UIColor.clear
    
    switch type {
    case  .speedPowerUp:
        color = UIColor(red: 0.8, green: 0.0, blue: 0.3, alpha: 1.0)
    case .fasterReloadPowerUp:
        color = UIColor(red: 0.7, green: 1.0, blue: 0.0, alpha: 1.0)
    case .throwingForcePowerUp:
        color = UIColor(red: 0.0, green: 0.6, blue: 0.8, alpha: 1.0)
    default:
        break
    }
    return color
}

let maxNumberOfResiduesPerRobot = 10        // max # of residues that will stick to the robot.

// return color to use for baked good and residue.  This is for the multiply value to
// change the color of the baked good.
func getColorForBakedGoodAndResidue (itemType: SpecificPrizeType) -> UIColor {
    var colorToUse: UIColor = UIColor.clear
    
    switch itemType {
    case .custardpie:
        colorToUse = UIColor.yellow
    case .breaddough:
        colorToUse = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    case .raspberrypie:
        colorToUse = UIColor.red
    case .keylimepie:
        colorToUse = UIColor.green
    case .pumpkinpie:
        colorToUse = UIColor.brown
    case .taffy:
        colorToUse = UIColor(red: 1.0, green: 0.8, blue: 1.0, alpha: 1.0)
    case .cookiedough:
        colorToUse = UIColor(red: 0.9, green: 0.7, blue: 0.5, alpha: 1.0)
    case .lemonjellydonut:
        colorToUse = UIColor.yellow
    case .chocolatecupcake:
        colorToUse = UIColor.brown 
    default:
        colorToUse = UIColor.yellow
        break
    }
    return colorToUse
}

let maxNumberOfDifferentRobotTypes = 9    // Note: if we add or remove robot types then we'll need to update this value.

// States for walls and fixed level components.  They are either opaque or 
// mostly transparent, depending on whether or not they are between the
// player's robot and the camera.
let mostlyTransparent = CGFloat(0.1)
let partiallyTransparent = CGFloat(0.3)
let opaque = CGFloat(1.0)
// The electromagnetic pulse has a different transparency to make it more visible.
let empTransparency = CGFloat(0.20)

// All the components that exist in a level.
enum LevelComponentType {
    case playerrobot
    case airobot
    case powerup
    case part
    case wall
    case entrancewall
    case exitwall
    case levelexit
    case levelexitdoorway
    case levelentrance
    case vault
    case vaultdoorway
    case vaultbarrier
    case hole
    case bakedgood
    case residue
    case emptyspace
    case table
    case refrigerator
    case rack
    case conveyor
    case mixer
    case oven
    case deepfryer            // deepfryer - for doughnuts
    case nocomponent
}

let playerRobotLabel = "playerRobot"
let aiRobotLabel = "AIrobot"
let bakedGoodLabel = "bakedgood"
let zapLabel = "zap"
let wallLabel = "wall"
let levelExitLabel = "exit"
let levelExitDoorwayLabel = "exitdoorway"
let levelEntranceLabel = "entrance"
let vaultLabel = "vault"
let vaultDoorwayLabel = "vaultdoorway"
let vaultBarrierLabel = "vaultbarrier"
let bakedGoodResidueLabel = "bakedgoodresidue"
let tableLabel = "table"
let refrigeratorLabel = "refrigerator"
let rackLabel = "rack"
let conveyorLabel = "Conveyor"
let mixerLabel = "mixer"
let ovenLabel = "oven"
let deepFryerLabel = "deepfryer"
let emptyLabel = "empty"
let dummyLabel = "dummy"            // a dummy placeholder for things like a robot shutting down.  The real robot has
// been removed in that case and dummy one put in its place for the shutdown sequence.
// We know to ignore dummies in instances like testing to see if the robot is disabled.
let groundLabel = "floor"
let partLabel = "part"
let powerUpLabel = "powerup"
let holeLabel = "hole"
let hoverUnitLabel = "Hover Unit"
let motionDetectorLabel = "Motion Detector"
let zapperWeaponLabel = "Zapper"
let extraSlotLabel = "Extra Slot"
let anotherLauncherLabel = "Another Launcher"
let bunsenBurnerLabel = "Bunsen Burner"
let empGrenadeLabel = "EMP Grenade"
let keyLabel = "Electronic Key"
let noSelectionLabel = "   "
let custardPieLabel = "Custard Pie"
let breadDoughLabel = "Bread Dough"
let raspberryPieLabel = "Raspberry Pie"
let keyLimePieLabel = "Key Lime Pie"
let pumpkinPieLabel = "Pumpkin Pie"
let taffyLabel = "Taffy"
let cookieDoughLabel = "Cookie Dough"
let lemonJellyDonutLabel = "Lemon Jelly Donut"
let chocolateCupcakeLabel = "Chocolate Cupcake"

let tutorialLabel = "tutorial"

// specific prize types corresponding to the prize labels/names.  This is for
// easier lookup using switch+case statements rather than string searches and
// if-else-if-else-if structures.
enum SpecificPrizeType {
    case motiondetector
    case hoverunit
    case zapperweapon
    case extraslot
    case anotherlauncher
    case bunsenburner
    case empgrenade
    case electronickey
    case custardpie
    case breaddough
    case raspberrypie
    case keylimepie
    case pumpkinpie
    case taffy
    case cookiedough
    case lemonjellydonut
    case chocolatecupcake
    case noprize
}

// Level component heights, particularly static components like tables, columns, etc.
let tableHeight = Float(0.6)
let refrigeratorHeight = Float(1.5)
let rackHeight = Float(1.8)
let conveyorHeight = Float(1.0)
let mixerHeight = Float(2.0)
let ovenHeight = Float(1.5)
let deepfryerHeight = Float(1.0)

enum VaultBarrierStates {
    case on                     // barrier on, will deny player access.
    case off                    // barrier/force field off.
    case denied                 // barrier has denied entry - turn barrier red.
}

enum SelectedButton {
    case overheadViewSelected
    case firstPersonViewSelected
    case selectLevelSelected
    case completeLevelSelected
    case stopRobotSelected
    case item1Selected
    case item2Selected
    case item3Selected
    case noButtonSelected
}

enum LevelStatus {
    case levelCompleted
    case levelNotCompleted
    case levelInProgress
    case levelNotStarted
}

struct LevelStats {
    // level stats info we will use for updating db and for showing in popup
    var numRobotsDestroyed: Int = 0
    var highestNumRobotsToDestroy: Int = 0
    var highestNumRobotsDestroyedSoFar: Int = 0
    var numPartsFoundSoFar: Int = 0
    var numNewPartsFound: Int = 0
    var maxPartsToFind: Int = 0
    var prizesJustUnlocked: [String] = []
}

enum BakedGoodState {
    case bakedgood
    case residue
    case fallingresidue
}


// The keys we use for accessing core data.  We specify there here so we can use the
// enum values instead to avoid mistakes.

let slot3DisabledLabel = "Slot3Disabled"
let slot3EnabledLabel = "Slot3Enabled"

enum PlayerDBKeys: String {
    case playerName = "playerName"
    case currentInventorySelected = "currentInventorySelected"
    case highestLevelSoFar = "highestLevelSoFar"
    case lastLevelSelected = "lastLevelSelected"
    case playerSelectedItem1 = "playerSelectedItem1"
    case playerSelectedItem2 = "playerSelectedItem2"
    case playerSelectedItem3 = "playerSelectedItem3"
    case playerSelectedAmmo = "playerSelectedAmmo"
    case cryptocoin = "cryptocoin"
    case hasLedger = "hasLedger"
    case hasMap = "hasMap"
    case hasRecipeBook = "hasRecipeBook"
}

let valueOfLedgerAndRecipeBookCombined = 300000   // value of ledger (100,000) plus recipe book (200,000) in cryptocoins
enum LevelInfoDBKeys: String {
    case levelNumber = "levelNumber"
    case achievementStars = "achievementStars"
    case numPartsFoundSoFar = "numPartsFoundSoFar"
    case highestNumPowerUpsFound = "highestNumPowerUpsFound"
    case highestNumRobotsDestroyed = "highestNumRobotsDestroyed"
    case lastNumPowerUpsFound = "lastNumPowerUpsFound"
    case lastNumRobotsDestroyed = "lastNumRobotsDestroyed"
    case levelCompleted = "levelCompleted"
    case partNumStart = "partNumStart"
    case partNumEnd = "partNumEnd"
    case maxRobotsToDestroy = "maxRobotsToDestroy"
    case maxPowerUpsToFind = "maxPowerUpsToFind"
}

enum PartsDBKeys: String {
    case partNumber = "partNumber"
    case prizeName = "prizeName"
    case retrieved = "retrieved"
}

enum EntityDBKeys: String {
    case playerState = "PlayerState"
    case levelInfo = "LevelInfo"
    case playerInventoryList = "PlayerInventoryList"
    case prizePartsInLevel = "PrizePartsInLevel"
    case parts = "Parts"
}

// specify reason for shutdown.  That way if there is
// a specify animation involved with it we will know.
enum ReasonForRobotShutdown {
    case corroded
    case tippedOver               // robot is already tipped over, just shut it down.
    case hitByStaticDischarge     // can happen when zapped or hit by electromagnetic pulse
    case fellIntoHole
    case hitByFlames              // from the bunsen burner
}

// states for the worker and superworker.  This tells the game whether or not
// a worker is ramming the player, has rammed it or isn't in the process of
// ramming a player.  We use the rammingPlayer and rammedPlayer to let the other
// workers know _not_ to ram the player since it has already been done.  
enum WorkerRammingState {
    case rammingPlayer
    case rammedPlayer
    case notRamming
}

// maximum times it takes for a worker or superworker to turn and then ram player.
let maximumWorkerTurnTime = 0.025
let maximumWorkerRamTime = 0.025

let nearWallRow = 0             // The near wall is always row zero.  This wall we want to keep track of because
                                // we want to make sure it is transparent so we can see the player's robot.

// The maze element in the layout of the maze of the level.  The NoWall is an intermediate
// state when we're carving out the maze.  Once we're doing carving it out, NoWall elements
// are changed to Space elements.
enum MazeElementType {
    case wall
    case noWall
    case space
    case mazeEntrance
    case mazeExit
    case fixedLevelComponent
    case robot
    case part
    case powerUp
    case hole
}

let minimumNumberOfRowsInMaze = 5
let minimumNumberOfColumnsInMaze = 5

let minRowDistanceAwayFromEntranceForHoles = 3   // this is the minimum distance away from the entrance to avoid placing holes
                                                // underneath the player at the beginning of the level.
let minRowDistanceAwayFromExitRowForHoles = 5
let minColumnDistanceAwayFromLeftWallForHoles = 5
let minColumnDistanceAwayFromRightWallForHoles = 5


let maxNumberOfLevelComponentsWide = 11
// By default we have a maze with 16 regions for placing robots and parts or powerups.
let defaultNumberOfRegions = 16

let learningLevelsMinimumRowsAwayFromPlayer = 12  // the minumum number of rows an ai robot has to start from the player's robot
                                                // when the player is still learning the ropes.

let minimumRowsAwayFromPlayer = 8   // the minimum number of rows an ai robot has to start from the player's robot.
let minimumColumnsAwayFromPlayer = 6  // the minimum number of columns the ai robot has to be away from the player's robot.

let minimumRowsAwayFromPlayerForPastryChefs = 40        // if ai robot is pastry chef, we want it far away from player to make the encounter later.

// MazeElementStatus is used in the generation of our maze.  We say a Space is
// connected when it becomes part of the carved out maze.  Once all the Spaces
// are connected, we don't use this anymore because the maze will be finished.
enum MazeElementStatus {
    case connected
    case notConnected
}

// Our level composes of predefined rows and columns.  We use these as coarse
// coordinates to place objects into the scene.  We translate the row and column
// to scene coordinates when we go to place items in the scene.
struct LevelCoordinates {
    var row: Int = 0
    var column: Int = 0
}

// An element in the maze.  This is for the initial maze generation where we just
// have walls and spaces.  Each element right now is a 2m x 2m block and the 
// entire level is composed of these blocks.  Where the block is a space it's empty.
// Where the block is a wall it is either a wall component or some other fixed level
// component like a refrigerator, table, conveyor, etc.
struct MazeElement {
    var type: MazeElementType = .space
    var coords: LevelCoordinates = LevelCoordinates()
    var status: MazeElementStatus = .notConnected
    var number: Int = 0
}

struct Ammo {
    var description: String = ""
    var mass: Double = 0.0
    var stickiness: Double = 0.0
    var corrosiveness: Double = 0.0
    var reloadTime: Double = 0.0
    init(mass: Double, corrosiveness: Double, stickiness: Double, reloadTime: Double, description: String) {
        self.mass = mass
        self.corrosiveness = corrosiveness
        self.stickiness = stickiness
        self.reloadTime = reloadTime
        self.description = description
    }
}

// Full* values where 1.0 is the highest.  This makes FullMass = 1.0 kg, which is
// what we need to make things look right.
let fullCorrosionResistance = 1.0
let fullStaticDischargeResistance = 1.0
let fullFireResistance = 1.0
let fullMass = 1.0
let fullMobility = 1.0

let robotCenterOfGravity = 1.0

let defaultRobotRecoveryScalarForce = 0.4       // 1.0 newtons?  Not sure but we have to use a recovery
                                                // force to get the robot back upright after impact.
                                                // we default to 1.0 and a multiple of this will be
                                                // needed for the larger robots.

// corroding state - the state the robot is in.  This is used by the showChangeInCorrosion() function
// in the robot class to determine whether to show the robot in a more corroded state or a healthier state.
enum CorrodingState {
    case corrode                // hit by a corrosive baked good, corrode robot
    case recover                // recovering some health from corrosing through healing
}

// corrosion colors representing the different corrosion states for a robot.  The last one is near total
// corrosion.  Use by the showChangeInCorrosion() function.
let corrosionColors = [
    UIColor(red: 1.6, green: 0.2, blue: 0.0, alpha: 1.0),       // represents most corroded state.
    UIColor(red: 1.2, green: 0.2, blue: 0.0, alpha: 1.0),
    UIColor(red: 0.6, green: 0.6, blue: 0.3, alpha: 1.0),
    UIColor(red: 0.8, green: 0.8, blue: 0.6, alpha: 1.0),
    UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0),       // represents No corrosion.
]

let mostCorrodedState = 0       // the array element in corrosionColors that represents the most corroded state.

// static discharge damage colors - used by showChangeInStaticDischargeDamage() in the robot class to determine
// and show the damage from static discharge.
let staticDischargeDamageColors = [
    UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0),       // represents most damaged state from static discharge.
    UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0),
    UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0),
    UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0),
    UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0),       // represents No static discharge damage
]    // represents the size the sparks particle system will be multiplied by.

let highestStaticDischargeDamageState = 0       // the array element representing the highest damage from static discharge.

struct PlayerInventory {
    var inventoryList: [String] = []     // the list of inventory the player actually has.
}

let noActiveAmmo = "NoAmmo" // This tells us that no active ammo has been selected by the player's robot, or the ai robot.
// This is the default when a robot is created.

// From position determine our level grid row and column.  maxRow should be count - 1 and maxCol should be count - 1
// as arrays go from 0 -- count - 1.  Otherwise this will not work as expected.
func calculateLevelRowAndColumn(objectPosition: SCNVector3, maxRow: Int, maxCol: Int) -> LevelCoordinates {
    
    var levelCoords: LevelCoordinates = LevelCoordinates()
    
    // row 0, column 0 is the bottom left corner of the maze/map/level so we should be able
    // to just take the scene coordinates and divide by the space size to get the level coordinates.
    levelCoords.row = -1 * Int(objectPosition.z / levelComponentSpaceLength)  // since z coordinates are in the -z direction we multiply by -1
    levelCoords.column = Int(objectPosition.x / levelComponentSpaceWidth)
    
    if levelCoords.row < 0 {
        levelCoords.row = 0
    }
    else if levelCoords.row > maxRow {
        levelCoords.row = maxRow
    }
    if levelCoords.column < 0 {
        levelCoords.column = 0
    }
    else if levelCoords.column > maxCol {
        levelCoords.column = maxCol
    }
    
    return levelCoords
}

func calculateSceneCoordinatesFromLevelRowAndColumn(levelCoords: LevelCoordinates) -> SCNVector3 {
    // Note: row = 0, column = 0 translates to LevelComponentSpaceWidth/2.0, -1.0 * LevelComponentSpaceLength/2.0
    // And every row and column from that point on is offset from those amounts.  Thus, row, colum of 0,0 is the bottom
    // left of the scene.  It used to be the bottom middle of the screen.  Since our entrance can now be anywhere in
    // the first row with spaces, starting off with the player's robot in the center is no longer that important.  Also
    // note that this function is for placing things into the level.
    let zeroRowZeroColumnCoordinates = SCNVector3(levelComponentSpaceWidth/2.0, 0.0, -1.0 * levelComponentSpaceLength / 2.0)
    var sceneCoords = SCNVector3(0.0, 0.0, 0.0)
    
    sceneCoords.x = Float(levelCoords.column) * levelComponentSpaceWidth + zeroRowZeroColumnCoordinates.x
    sceneCoords.z = -1.0 * Float(levelCoords.row) * levelComponentSpaceLength + zeroRowZeroColumnCoordinates.z
    
    return sceneCoords
}

func calcDistance(p1: SCNVector3, p2: SCNVector3) -> Float {
    // Sigh...for some reason the pow() function won't accept either a Float or a Double.
    // So we manually square the deltas
    let distance = sqrt((p2.x-p1.x) * (p2.x-p1.x) + (p2.y-p1.y) * (p2.y-p1.y) + (p2.z-p1.z) * (p2.z-p1.z))
    
    return distance
}

func calcDistanceLevelCoords(p1: LevelCoordinates, p2: LevelCoordinates) -> Float {
    // Sigh...for some reason the pow() function won't accept either a Float or a Double.
    // So we manually square the deltas
    let distance = sqrt(Float(p2.column-p1.column) * Float(p2.column-p1.column) + Float(p2.row-p1.row) * Float(p2.row-p1.row))
    
    return distance

}

func haveLevelCoordsChanged(levelCoords: LevelCoordinates, lastLevelCoords: LevelCoordinates) -> Bool {
    var coordsHaveChanged: Bool = false
    if levelCoords.row != lastLevelCoords.row || levelCoords.column != lastLevelCoords.column {
        coordsHaveChanged = true
    }
    return coordsHaveChanged
}

func getLevelComponentType2(levelComponentName: String, componentsDictionary: [String: LevelComponentType]) -> LevelComponentType {
    var type: LevelComponentType = .nocomponent
    
    if componentsDictionary[levelComponentName] != nil {
        type = componentsDictionary[levelComponentName]!
    }
    // Note: we commented out the backup so if the component isn't found then
    // we just return .nocomponent.  This should be ok as teh components dictionary
    // _should_ have all the robots and fixed level components and walls, and nothing
    // else, which is what we want.  This function is primarily used by the ai robots
    // to help them determine what is around them when they navigate the room.
    /*
    else {
        print ("Warning! getLevelComponentType() called for \(levelComponentName)")
        type = getLevelComponentType(levelComponentName: levelComponentName)
    }
    */
    return type
}

// From the name determine what the type of level component it is.
func getLevelComponentType(levelComponentName: String) -> LevelComponentType {
    var type: LevelComponentType = .nocomponent
    

    if levelComponentName.range(of: playerRobotLabel) != nil {
        type = .playerrobot
    }
    else if levelComponentName.range(of: aiRobotLabel) != nil {
        type = .airobot
    }
    else if levelComponentName.range(of: bakedGoodLabel) != nil {
        type = .bakedgood
    }
    else if levelComponentName.range(of: partLabel) != nil {
        type = .part
    }
    else if levelComponentName.range(of: powerUpLabel) != nil {
        type = .powerup
    }
    else if levelComponentName.range(of: wallLabel) != nil {
        type = .wall
    }
    else if levelComponentName.range(of: bakedGoodResidueLabel) != nil {
        type = .residue
    }
    else if levelComponentName.range(of: tableLabel) != nil {
        type = .table
    }
    else if levelComponentName.range(of: refrigeratorLabel) != nil {
        type = .refrigerator
    }
    else if levelComponentName.range(of: rackLabel) != nil {
        type = .rack
    }
    else if levelComponentName.range(of: conveyorLabel) != nil {
        type = .conveyor
    }
    else if levelComponentName.range(of: mixerLabel) != nil {
        type = .mixer
    }
    else if levelComponentName.range(of: ovenLabel) != nil {
        type = .oven
    }
    else if levelComponentName.range(of: deepFryerLabel) != nil {
        type = .deepfryer
    }
    else if levelComponentName.range(of: levelExitLabel) != nil {
        type = .levelexit
    }
    else if levelComponentName.range(of: holeLabel) != nil {
        type = .hole
    }
    return type
}

// is the component type fixed?  In other words, is it a static component such as a wall,
// a table, a refrigerator, a deepfryter, an oven, a conveyor, a rack, or a mixer?  If so,
// then return true.
func isLevelComponentTypeFixed (levelComponentType: LevelComponentType) -> Bool {
    var isFixed: Bool = false
    
    switch levelComponentType {
    case .wall:
        isFixed = true
    case .table:
        isFixed = true
    case .refrigerator:
        isFixed = true
    case .conveyor:
        isFixed = true
    case .rack:
        isFixed = true
    case .mixer:
        isFixed = true
    case .oven:
        isFixed = true
    case .deepfryer:
        isFixed = true
    default:
        break
    }
    return isFixed
}

func isLevelGridSpaceOccupiedByComponentToAvoid(robotMakingQuery: String, objectsInLevelGridSpace: [String], componentsDictionary: [String : LevelComponentType]) -> Bool {
    var isOccupiedBySomethingToAvoid: Bool = false
    // our set includes all the fixed level components such as tables, refrigerator, mixers, etc., other ai robots, the walls,
    // and the level exit.  These are all the things we want the ai robot to avoid.  It can ignore parts or powerups and it should go towards
    // the player.
    let objectsToAvoid: Set<LevelComponentType> = [.airobot, .wall, .table, .refrigerator, .rack, .conveyor, .mixer, .oven, .deepfryer, .levelexit]
    
    for anObject in objectsInLevelGridSpace {
        let objectType = getLevelComponentType2(levelComponentName: anObject, componentsDictionary: componentsDictionary)
        // We want to ignore the robot that is making the query
        if objectsToAvoid.contains(objectType) && anObject != robotMakingQuery {
            isOccupiedBySomethingToAvoid = true
        }
    }
    return isOccupiedBySomethingToAvoid
}

// get robot type based on the robot# being assigned.  This is for ai robots only
// and is used for assigning robots to regions within the level, where a region is
// a virtual space that is one part of a level.  The level is broken up into regions
// to allow us to spread out random placements of robots.  Otherwise we could have
// clumping even with random choosing of placement locations.
func getRobotType (robotNum: Int, levelChallenges: LevelChallenges) -> RobotType {
    var botType: RobotType
    
    let workerStartNum = 0
    let bakerStartNum = workerStartNum + levelChallenges.workers
    let doublebakerStartNum = bakerStartNum + levelChallenges.bakers
    let zapperStartNum = doublebakerStartNum + levelChallenges.doublebakers
    let superWorkerStartNum = zapperStartNum + levelChallenges.zappers
    let superbakerStartNum = superWorkerStartNum + levelChallenges.superworkers
    let homingStartNum = superbakerStartNum + levelChallenges.superbakers
    let ghostStartNum = homingStartNum + levelChallenges.homing
    let pastrychefStartNum = ghostStartNum + levelChallenges.ghosts
    
    if robotNum >= workerStartNum && robotNum < bakerStartNum {
        botType = .worker
    }
    else if robotNum >= bakerStartNum && robotNum < doublebakerStartNum {
        botType = .baker
    }
    else if robotNum >= doublebakerStartNum && robotNum < zapperStartNum {
        botType = .doublebaker
    }
    else if robotNum >= zapperStartNum && robotNum < superWorkerStartNum {
        botType = .zapper
    }
    else if robotNum >= superWorkerStartNum && robotNum < superbakerStartNum {
        botType = .superworker
    }
    else if robotNum >= superbakerStartNum && robotNum < homingStartNum {
        botType = .superbaker
    }
    else if robotNum >= homingStartNum && robotNum < ghostStartNum {
        botType = .homing
    }
    else if robotNum >= ghostStartNum && robotNum < pastrychefStartNum {
        botType = .ghost
    }
    else if robotNum >= pastrychefStartNum {
        botType = .pastrychef
    }
    else {
        botType = .noRobot
    }
    
    return botType
}

func matchRobotTypeToRobotTypeString(robotType: RobotType) -> String {
    var robotTypeString: String = ""
    
    switch robotType {
    case .worker:
        robotTypeString = "worker"
    case .baker:
        robotTypeString = "baker"
    case .doublebaker:
        robotTypeString = "doublebaker"
    case .zapper:
        robotTypeString = "zapper"
    case .homing:
        robotTypeString = "homing"
    case .ghost:
        robotTypeString = "ghost"
    case .superworker:
        robotTypeString = "superworker"
    case .superbaker:
        robotTypeString = "superbaker"
    case .pastrychef:
        robotTypeString = "pastrychef"
    case .noRobot:
        break
    }
    return robotTypeString
}


// If the vector operations are simple we just implement them directly.  Otherwise
// we use GLKit functions, such as what we did with multiplying two vectors in
// multSCNVect3BySCNVect3() below.  The reason we do this is that because we have
// to convert from SCNVector3 to GLKVector3 and then convert back to SCNVector3
// once the operation is done, it makes sense to just implement it all in SCNVector3
// if the operation is simple.

// function to check two vectors to see if they are equal.
func areSCNVect3Equal(v1: SCNVector3, v2: SCNVector3) -> Bool {
    var areEqual: Bool = false
    
    if v1.x == v2.x && v1.y == v2.y && v1.z == v2.z {
        areEqual = true
    }
    return areEqual
}

// function to check to see if one vector is nearly equal to the other.  This is useful to
// see if the robot is nearly NotMoving.
func areSCNVect3NearlyEqual(v1: SCNVector3, v2: SCNVector3, nearnessFactor: Float) -> Bool {
    var areNearlyEqual: Bool = false
    
    if abs(v1.x - v2.x) <= nearnessFactor && abs(v1.y - v2.y) <= nearnessFactor && abs(v1.z - v2.z) <= nearnessFactor {
        areNearlyEqual = true
    }
    return areNearlyEqual
}

func multSCNVect3ByScalar(v: SCNVector3, s: Float) -> SCNVector3 {
    var newVect3: SCNVector3 = v
    
    newVect3.x *= s
    newVect3.y *= s
    newVect3.z *= s
    
    return newVect3
}

func multSCNVect3BySCNVect3(v1: SCNVector3, v2: SCNVector3) -> SCNVector3 {
    let v1glk = SCNVector3ToGLKVector3(v1)
    let v2glk = SCNVector3ToGLKVector3(v2)
    let v1xv2multglk = GLKVector3Multiply(v1glk, v2glk)
    let v1xv2multscn = SCNVector3FromGLKVector3(v1xv2multglk)
    return v1xv2multscn
}

func dotProductSCNVect3(v1: SCNVector3, v2: SCNVector3) -> Float {
    let v1glk = SCNVector3ToGLKVector3(v1)
    let v2glk = SCNVector3ToGLKVector3(v2)
    let v1xv2dotProduct = GLKVector3DotProduct(v1glk, v2glk)
    return v1xv2dotProduct
}

// We use this function to get the angle between the velocity vector of the robot and the
// velocity vector of the baked good in flight.  This gives us the rotation angle for the
// baked good launcher.
func angleBetweenTwoVectors(v1: SCNVector3, v2: SCNVector3) -> Float {
    let lengthv1 = sqrt(v1.x*v1.x + v1.y*v1.y + v1.z*v1.z)
    let lengthv2 = sqrt(v2.x*v2.x + v2.y*v2.y + v2.z*v2.z)
    
    let v1Dotv2 = v1.x * v2.x + v1.y * v2.y + v1.z * v2.z
    let cosAngle = v1Dotv2 / (lengthv1 * lengthv2)
    let angle = acos(cosAngle)
    
    return angle
}


func addTwoSCNVect3(v1: SCNVector3, v2: SCNVector3) -> SCNVector3 {
    var newVect3: SCNVector3 = SCNVector3(0.0, 0.0, 0.0)
    
    newVect3.x = v1.x + v2.x
    newVect3.y = v1.y + v2.y
    newVect3.z = v1.z + v2.z
    
    return newVect3
}

// For the ai robots.  Determine if the target--the player--is within range.  This is a simple calculation.  It
// does not take into account whether or not the player is moving.  This is just for a simple 'is it in range now?'
// determination.  Sigh... we have to also have to bring in stuff from Robot.hurlBakedGood() since it has some code to
// offset the baked good slightly from the robot so the baked good doesn't hit the robot on its way to the target.
func isTargetInRange(aiRobotLocation: SCNVector3, targetPoint: SCNVector3, hurlingSpeed: Float) -> Bool {
    var targetWithinRange: Bool = false
    var aiRobotLoc = aiRobotLocation
    
    aiRobotLoc.y += 0.5  // throw from a slightly higher location to clear fixed level components and maybe hit more accurately.
    if targetPoint.z < aiRobotLoc.z {
        aiRobotLoc.z -= 1.0  // We move the baked good's starting point away from the robot so it
        // doesn't immediately make contact with it and screw up collision/contact detection.
    }
    else {
        aiRobotLoc.z += 1.0   // start baked good off behind the player's robot.
    }

    let deltax = (targetPoint.x - aiRobotLoc.x) * 1.10
    let deltaz = (targetPoint.z - aiRobotLoc.z) * 1.10
    let xzRangeToTarget = sqrt(deltax*deltax + deltaz*deltaz)
    let maximumDistance = (hurlingSpeed*hurlingSpeed)/forceOfEarthGravity
    
    if xzRangeToTarget < maximumDistance {
        targetWithinRange = true
    }
    return targetWithinRange
}

// We could probably use index(of:) instead of searching for a particularl string
// this way but this way is more general.
func isItemInSelections(item: String, selections: [String]) -> Bool {
    var itemIsInSelections: Bool = false
    for aSelection in selections {
        if aSelection.range(of: item) != nil {
            itemIsInSelections = true
        }
    }
    return itemIsInSelections
}

// We couldn't find a simple 'dimensions' structure for an SCNNode so
// we just created one for the robot dimensions.  These will be different,
// depending on the type of robot.
struct RobotDimensions {
    var width: CGFloat = 0.0
    var height: CGFloat = 0.0
    var length: CGFloat = 0.0
    init (width: CGFloat, height: CGFloat, length: CGFloat) {
        self.width = width
        self.height = height
        self.length = length
    }
}

// structure that captures the number of each type of challenge in the level, with the exception of fogTotalObscureDistance and darkness, where
// fogTotalObscureDistance is the distance from the point of view at which all objects are totally obscured, and darkness is a fraction
// representing the amount of darkness, where 0.0 is zero darkness and 1.0 is 100% darkness.
struct LevelChallenges {
    var workers: Int = 0                    // number of worker robots
    var bakers: Int = 0                   // number of baker robots
    var rows: Int = 0                   // number of more rows+columns to add to the base size for a level.
    var componenttypes: Int = 0                 // fixed level component types to add to the level, _not_ the number of components
    var doublebakers: Int = 0             // number of doublebaker robots
    var zappers: Int = 0                    // number of zapper robots
    var holes: Int = 0                      // number of holes in the floor in the room that the player robot might fall through.
    var superworkers: Int = 0               // number of super worker robots.
    var camouflagedholes: Int = 0           // number of holes in the floor that are camouflaged to be hard to see.
    var superbakers: Int = 0        // number of superbaker robots
    var homing: Int = 0                     // number of homing robots
    var fogStartDistance: CGFloat = 0.0     // distance from point of view where fog starts.
    var fogEndDistance: CGFloat = 0.0       // distance where the elements in the scene are totally obscured by fog.
    var ghosts: Int = 0                     // homing robots that are nearly invisible -- formerly camouflaged robots.
    var darkness: UIColor = UIColor.white   // UIColor representing darkness.  Default is white (i.e. no darkness)
    var pastrychefs: Int = 0                // pastry chef robots.
    var numAIRobotMisses: Int = 2           // number of throws that will miss in a level before one that one.
    var withinRangeDistance: Float = 0.0    // just used by bloodhounds and ghosts even though it could be used by workers, zappers, superworkers, pastry chefs as well.
    init(w: Int, b: Int, r: Int, c: Int, d: Int, z: Int, h: Int, sw: Int, ch: Int, sb: Int, homing: Int, fs: CGFloat, fe: CGFloat, g: Int, dk: UIColor, p: Int, nm: Int, wrd: Float) {
        workers = w
        bakers = b
        rows = r
        componenttypes = c
        doublebakers = d
        zappers = z
        holes = h
        superworkers = sw
        camouflagedholes = ch
        superbakers = sb
        self.homing = homing
        fogStartDistance = fs
        fogEndDistance = fe
        ghosts = g
        darkness = dk
        pastrychefs = p
        numAIRobotMisses = nm
        withinRangeDistance = wrd
    }
}

// Array of all the challenges for all the levels.  Note that the array starts at zero but the level is actually level 1.
// A harder level has increased number of bad guys, particularly the tougher ones.  In the easy levels we scale back the
// harder ones and substitute in more of the easier ones.  That way the number of robots doesn't change but the difficulty in
// defeating the robots does.
let allLevelChallenges = [
    LevelChallenges(w: 2, b: 0, r: 5, c: 2, d: 0, z: 0, h: 0, sw: 0, ch: 0, sb: 0, homing: 0, fs: 0.0, fe: 0.0, g: 0, dk: UIColor.white, p: 0, nm: 3, wrd: 0.0),  // 1 - easy
    LevelChallenges(w: 3, b: 0, r: 5, c: 2, d: 0, z: 0, h: 0, sw: 0, ch: 0, sb: 0, homing: 0, fs: 0.0, fe: 0.0, g: 0, dk: UIColor.white, p: 0, nm: 3, wrd: 0.0),  // 2 - easy
    LevelChallenges(w: 4, b: 0, r: 5, c: 2, d: 0, z: 0, h: 0, sw: 0, ch: 0, sb: 0, homing: 0, fs: 0.0, fe: 0.0, g: 0, dk: UIColor.white, p: 0, nm: 3, wrd: 0.0),  // 3 - easy
    LevelChallenges(w: 4, b: 3, r: 5, c: 2, d: 0, z: 0, h: 0, sw: 0, ch: 0, sb: 0, homing: 0, fs: 0.0, fe: 0.0, g: 0, dk: UIColor.white, p: 0, nm: 2, wrd: 0.0),  // 4 - harder, something new
    LevelChallenges(w: 7, b: 1, r: 5, c: 2, d: 0, z: 0, h: 0, sw: 0, ch: 0, sb: 0, homing: 0, fs: 0.0, fe: 0.0, g: 0, dk: UIColor.white, p: 0, nm: 3, wrd: 0.0),  // 5 - easy
    LevelChallenges(w: 6, b: 4, r: 5, c: 2, d: 0, z: 0, h: 0, sw: 0, ch: 0, sb: 0, homing: 0, fs: 0.0, fe: 0.0, g: 0, dk: UIColor.white, p: 0, nm: 3, wrd: 0.0),  // 6 - harder
    LevelChallenges(w: 8, b: 2, r: 5, c: 2, d: 0, z: 0, h: 0, sw: 0, ch: 0, sb: 0, homing: 0, fs: 0.0, fe: 0.0, g: 0, dk: UIColor.white, p: 0, nm: 3, wrd: 0.0),  // 7 - easy
    LevelChallenges(w: 8, b: 4, r: 6, c: 2, d: 0, z: 0, h: 0, sw: 0, ch: 0, sb: 0, homing: 0, fs: 0.0, fe: 0.0, g: 0, dk: UIColor.white, p: 0, nm: 3, wrd: 0.0),  // 8 - harder, something new
    LevelChallenges(w: 10, b: 2, r: 6, c: 2, d: 0, z: 0, h: 0, sw: 0, ch: 0, sb: 0, homing: 0, fs: 0.0, fe: 0.0, g: 0, dk: UIColor.white, p: 0, nm: 3, wrd: 0.0),  // 9 - easy
    LevelChallenges(w: 8, b: 5, r: 7, c: 3, d: 0, z: 0, h: 0, sw: 0, ch: 0, sb: 0, homing: 0, fs: 0.0, fe: 0.0, g: 0, dk: UIColor.white, p: 0, nm: 2, wrd: 0.0),   // 10 - harder
    LevelChallenges(w: 10, b: 3, r: 7, c: 3, d: 0, z: 0, h: 0, sw: 0, ch: 0, sb: 0, homing: 0, fs: 0.0, fe: 0.0, g: 0, dk: UIColor.white, p: 0, nm: 2, wrd: 0.0),  // 11 - easy
    LevelChallenges(w: 9, b: 3, r: 7, c: 3, d: 2, z: 0, h: 0, sw: 0, ch: 0, sb: 0, homing: 0, fs: 0.0, fe: 0.0, g: 0, dk: UIColor.white, p: 0, nm: 3, wrd: 0.0),  // 12 - harder, something new
    LevelChallenges(w: 11, b: 3, r: 7, c: 3, d: 1, z: 0, h: 0, sw: 0, ch: 0, sb: 0, homing: 0, fs: 0.0, fe: 0.0, g: 0, dk: UIColor.white, p: 0, nm: 3, wrd: 0.0),  // 13 - easy
    LevelChallenges(w: 8, b: 4, r: 7, c: 3, d: 3, z: 0, h: 0, sw: 0, ch: 0, sb: 0, homing: 0, fs: 0.0, fe: 0.0, g: 0, dk: UIColor.white, p: 0, nm: 2, wrd: 0.0),  // 14 - harder
    LevelChallenges(w: 12, b: 4, r: 7, c: 3, d: 1, z: 0, h: 0, sw: 0, ch: 0, sb: 0, homing: 0, fs: 0.0, fe: 0.0, g: 0, dk: UIColor.white, p: 0, nm: 3, wrd: 0.0),  // 15 - easy
    LevelChallenges(w: 12, b: 2, r: 7, c: 3, d: 1, z: 3, h: 0, sw: 0, ch: 0, sb: 0, homing: 0, fs: 0.0, fe: 0.0, g: 0, dk: UIColor.white, p: 0, nm: 3, wrd: 0.0),  // 16 - harder, something new
    LevelChallenges(w: 14, b: 3, r: 7, c: 3, d: 1, z: 1, h: 0, sw: 0, ch: 0, sb: 0, homing: 0, fs: 0.0, fe: 0.0, g: 0, dk: UIColor.white, p: 0, nm: 3, wrd: 0.0),  // 17 - easy
    LevelChallenges(w: 10, b: 4, r: 8, c: 3, d: 2, z: 4, h: 0, sw: 0, ch: 0, sb: 0, homing: 0, fs: 0.0, fe: 0.0, g: 0, dk: UIColor.white, p: 0, nm: 2, wrd: 0.0),  // 18 - harder
    LevelChallenges(w: 14, b: 3, r: 8, c: 3, d: 1, z: 2, h: 0, sw: 0, ch: 0, sb: 0, homing: 0, fs: 0.0, fe: 0.0, g: 0, dk: UIColor.white, p: 0, nm: 3, wrd: 0.0),  // 19 - easy
    LevelChallenges(w: 10, b: 4, r: 8, c: 3, d: 2, z: 5, h: 5, sw: 0, ch: 0, sb: 0, homing: 0, fs: 0.0, fe: 0.0, g: 0, dk: UIColor.white, p: 0, nm: 3, wrd: 0.0),  // 20 - harder, something new
    LevelChallenges(w: 11, b: 5, r: 8, c: 3, d: 2, z: 3, h: 3, sw: 0, ch: 0, sb: 0, homing: 0, fs: 0.0, fe: 0.0, g: 0, dk: UIColor.white, p: 0, nm: 3, wrd: 0.0),  // 21 - easy
    LevelChallenges(w: 8, b: 5, r: 8, c: 4, d: 4, z: 6, h: 7, sw: 0, ch: 0, sb: 0, homing: 0, fs: 0.0, fe: 0.0, g: 0, dk: UIColor.white, p: 0, nm: 2, wrd: 0.0),  // 22 - harder
    LevelChallenges(w: 11, b: 6, r: 8, c: 4, d: 2, z: 4, h: 5, sw: 0, ch: 0, sb: 0, homing: 0, fs: 0.0, fe: 0.0, g: 0, dk: UIColor.white, p: 0, nm: 3, wrd: 0.0),  // 23 - easy
    LevelChallenges(w: 6, b: 8, r: 8, c: 4, d: 2, z: 4, h: 7, sw: 4, ch: 0, sb: 0, homing: 0, fs: 0.0, fe: 0.0, g: 0, dk: UIColor.white, p: 0, nm: 3, wrd: 0.0),   // 24 - harder, something new
    LevelChallenges(w: 11, b: 7, r: 8, c: 4, d: 2, z: 3, h: 4, sw: 1, ch: 0, sb: 0, homing: 0, fs: 0.0, fe: 0.0, g: 0, dk: UIColor.white, p: 0, nm: 3, wrd: 0.0),  // 25 - easy
    LevelChallenges(w: 5, b: 6, r: 9, c: 4, d: 3, z: 5, h: 5, sw: 5, ch: 0, sb: 0, homing: 0, fs: 0.0, fe: 0.0, g: 0, dk: UIColor.white, p: 0, nm: 3, wrd: 0.0),   // 26 - harder
    LevelChallenges(w: 10, b: 8, r: 9, c: 4, d: 3, z: 2, h: 4, sw: 1, ch: 0, sb: 0, homing: 0, fs: 0.0, fe: 0.0, g: 0, dk: UIColor.white, p: 0, nm: 3, wrd: 0.0),  // 27 - easy
    LevelChallenges(w: 5, b: 3, r: 9, c: 4, d: 5, z: 5, h: 5, sw: 6, ch: 4, sb: 0, homing: 0, fs: 0.0, fe: 0.0, g: 0, dk: UIColor.white, p: 0, nm: 3, wrd: 0.0),   // 28 - harder, something new
    LevelChallenges(w: 7, b: 7, r: 9, c: 4, d: 3, z: 5, h: 4, sw: 3, ch: 2, sb: 0, homing: 0, fs: 0.0, fe: 0.0, g: 0, dk: UIColor.white, p: 0, nm: 3, wrd: 0.0),   // 29 - 30 robots
    LevelChallenges(w: 3, b: 7, r: 9, c: 4, d: 5, z: 4, h: 5, sw: 6, ch: 6, sb: 0, homing: 0, fs: 0.0, fe: 0.0, g: 0, dk: UIColor.white, p: 0, nm: 2, wrd: 0.0),   // 30 - harder
    LevelChallenges(w: 7, b: 8, r: 9, c: 4, d: 3, z: 3, h: 5, sw: 4, ch: 6, sb: 0, homing: 0, fs: 0.0, fe: 0.0, g: 0, dk: UIColor.white, p: 0, nm: 3, wrd: 0.0),   // 31 - easy
    LevelChallenges(w: 4, b: 4, r: 9, c: 4, d: 4, z: 6, h: 5, sw: 4, ch: 6, sb: 3, homing: 0, fs: 0.0, fe: 0.0, g: 0, dk: UIColor.white, p: 0, nm: 3, wrd: 0.0),   // 32 - harder, something new
    LevelChallenges(w: 8, b: 6, r: 9, c: 4, d: 2, z: 5, h: 4, sw: 3, ch: 0, sb: 1, homing: 0, fs: 0.0, fe: 0.0, g: 0, dk: UIColor.white, p: 0, nm: 3, wrd: 0.0),   // 33 - easy
    LevelChallenges(w: 4, b: 4, r: 10, c: 4, d: 5, z: 5, h: 5, sw: 4, ch: 3, sb: 3, homing: 0, fs: 0.0, fe: 0.0, g: 0, dk: UIColor.white, p: 0, nm: 2, wrd: 0.0),  // 34 - harder - 31 robots
    LevelChallenges(w: 6, b: 5, r: 10, c: 5, d: 3, z: 6, h: 4, sw: 4, ch: 0, sb: 1, homing: 0, fs: 0.0, fe: 0.0, g: 0, dk: UIColor.white, p: 0, nm: 3, wrd: 0.0),  // 35 - easy
    LevelChallenges(w: 2, b: 4, r: 10, c: 5, d: 4, z: 4, h: 5, sw: 6, ch: 2, sb: 5, homing: 0, fs: 0.0, fe: 0.0, g: 0, dk: UIColor.white, p: 0, nm: 2, wrd: 0.0),  // 36 - harder
    LevelChallenges(w: 4, b: 4, r: 10, c: 5, d: 3, z: 9, h: 4, sw: 4, ch: 0, sb: 1, homing: 0, fs: 0.0, fe: 0.0, g: 0, dk: UIColor.white, p: 0, nm: 3, wrd: 0.0), // 37 - easy
    LevelChallenges(w: 3, b: 5, r: 10, c: 5, d: 1, z: 7, h: 6, sw: 6, ch: 3, sb: 4, homing: 0, fs: 0.0, fe: 0.0, g: 0, dk: UIColor.white, p: 0, nm: 2, wrd: 0.0),  // 38 - harder
    LevelChallenges(w: 5, b: 8, r: 10, c: 5, d: 2, z: 7, h: 3, sw: 3, ch: 2, sb: 1, homing: 0, fs: 0.0, fe: 0.0, g: 0, dk: UIColor.white, p: 0, nm: 3, wrd: 0.0),  // 39 - easy
    LevelChallenges(w: 3, b: 4, r: 10, c: 5, d: 4, z: 6, h: 7, sw: 4, ch: 3, sb: 3, homing: 2, fs: 0.0, fe: 0.0, g: 0, dk: UIColor.white, p: 0, nm: 2, wrd: 10.0), // 40 - harder, something new
    LevelChallenges(w: 7, b: 3, r: 10, c: 5, d: 3, z: 5, h: 4, sw: 4, ch: 1, sb: 3, homing: 1, fs: 0.0, fe: 0.0, g: 0, dk: UIColor.white, p: 0, nm: 3, wrd: 10.0), // 41 - easy
    LevelChallenges(w: 3, b: 4, r: 11, c: 5, d: 3, z: 7, h: 7, sw: 5, ch: 4, sb: 1, homing: 3, fs: 0.0, fe: 0.0, g: 0, dk: UIColor.white, p: 0, nm: 2, wrd: 10.0), // 42 - harder
    LevelChallenges(w: 5, b: 5, r: 11, c: 5, d: 3, z: 6, h: 5, sw: 4, ch: 2, sb: 2, homing: 1, fs: 0.0, fe: 0.0, g: 0, dk: UIColor.white, p: 0, nm: 2, wrd: 10.0), // 43 - easy
    LevelChallenges(w: 3, b: 1, r: 11, c: 5, d: 4, z: 5, h: 2, sw: 6, ch: 6, sb: 3, homing: 4, fs: 20.0, fe: 80.0, g: 0, dk: UIColor.white, p: 0, nm: 2, wrd: 5.0), // 44 - harder, something new
    LevelChallenges(w: 4, b: 1, r: 11, c: 5, d: 4, z: 8, h: 2, sw: 4, ch: 2, sb: 3, homing: 2, fs: 0.0, fe: 0.0, g: 0, dk: UIColor.white, p: 0, nm: 2, wrd: 5.0),   // 45 - easy
    LevelChallenges(w: 1, b: 0, r: 11, c: 5, d: 4, z: 8, h: 8, sw: 5, ch: 6, sb: 5, homing: 4, fs: 20.0, fe: 100.0, g: 0, dk: UIColor.white, p: 0, nm: 2, wrd: 5.0), // 46 - harder
    LevelChallenges(w: 2, b: 3, r: 11, c: 6, d: 5, z: 7, h: 5, sw: 4, ch: 2, sb: 3, homing: 3, fs: 40.0, fe: 100.0, g: 0, dk: UIColor.white, p: 0, nm: 2, wrd: 5.0),  // 47 - easy
    LevelChallenges(w: 3, b: 1, r: 11, c: 6, d: 3, z: 7, h: 4, sw: 4, ch: 7, sb: 3, homing: 3, fs: 20.0, fe: 80.0, g: 3, dk: UIColor.white, p: 0, nm: 2, wrd: 5.0),   // 48 - harder, something new
    LevelChallenges(w: 0, b: 3, r: 11, c: 6, d: 2, z: 9, h: 5, sw: 6, ch: 2, sb: 2, homing: 3, fs: 0.0, fe: 0.0, g: 2, dk: UIColor.white, p: 0, nm: 2, wrd: 5.0),   // 49 - easy
    LevelChallenges(w: 1, b: 0, r: 12, c: 6, d: 2, z: 8, h: 10, sw: 6, ch: 7, sb: 4, homing: 3, fs: 20.0, fe: 80.0, g: 3, dk: UIColor.white, p: 0, nm: 1, wrd: 5.0), // 50 - harder
    LevelChallenges(w: 2, b: 6, r: 12, c: 6, d: 3, z: 7, h: 6, sw: 3, ch: 2, sb: 3, homing: 2, fs: 30.0, fe: 100.0, g: 1, dk: UIColor.white, p: 0, nm: 2, wrd: 5.0),   // 51 - easy
    LevelChallenges(w: 1, b: 2, r: 12, c: 6, d: 1, z: 8, h: 11, sw: 6, ch: 7, sb: 4, homing: 2, fs: 20.0, fe: 80.0, g: 3, dk: UIColor.lightGray, p: 0, nm: 2, wrd: 5.0), // 52 - harder,something new
    LevelChallenges(w: 5, b: 0, r: 12, c: 6, d: 2, z: 8, h: 6, sw: 5, ch: 3, sb: 3, homing: 2, fs: 0.0, fe: 0.0, g: 2, dk: UIColor.white, p: 0, nm: 2, wrd: 5.0),    // 53 - easy
    LevelChallenges(w: 3, b: 1, r: 12, c: 6, d: 0, z: 7, h: 12, sw: 6, ch: 8, sb: 5, homing: 3, fs: 20.0, fe: 60.0, g: 3, dk: UIColor.gray, p: 0, nm: 1, wrd: 5.0),   // 54 - harder
    LevelChallenges(w: 4, b: 0, r: 12, c: 6, d: 3, z: 8, h: 7, sw: 5, ch: 2, sb: 3, homing: 2, fs: 20.0, fe: 100.0, g: 3, dk: UIColor.white, p: 0, nm: 2, wrd: 5.0),   // 55 - easy
    LevelChallenges(w: 4, b: 2, r: 12, c: 6, d: 0, z: 9, h: 12, sw: 2, ch: 8, sb: 4, homing: 3, fs: 20.0, fe: 70.0, g: 4, dk: UIColor.darkGray, p: 0, nm: 1, wrd: 5.0),  // 56 - harder
    LevelChallenges(w: 3, b: 3, r: 12, c: 6, d: 3, z: 8, h: 10, sw: 5, ch: 2, sb: 4, homing: 3, fs: 0.0, fe: 0.0, g: 1, dk: UIColor.white, p: 0, nm: 2, wrd: 5.0),      // 57 - easy
    LevelChallenges(w: 6, b: 3, r: 13, c: 6, d: 0, z: 7, h: 16, sw: 5, ch: 10, sb: 4, homing: 2, fs: 20.0, fe: 60.0, g: 3, dk: UIColor.darkGray, p: 0, nm: 1, wrd: 5.0),    // 58 - harder
    LevelChallenges(w: 7, b: 3, r: 13, c: 7, d: 0, z: 8, h: 10, sw: 5, ch: 3, sb: 3, homing: 2, fs: 0.0, fe: 0.0, g: 2, dk: UIColor.white, p: 0, nm: 2, wrd: 5.0),      // 59 - easy
    LevelChallenges(w: 7, b: 0, r: 13, c: 7, d: 2, z: 9, h: 14, sw: 5, ch: 10, sb: 4, homing: 2, fs: 30.0, fe: 60.0, g: 1, dk: UIColor.black, p: 0, nm: 2, wrd: 5.0),      // 60 - easy
    LevelChallenges(w: 5, b: 3, r: 13, c: 7, d: 0, z: 3, h: 15, sw: 6, ch: 10, sb: 2, homing: 4, fs: 20.0, fe: 45.0, g: 3, dk: UIColor.black, p: 6, nm: 1, wrd: 5.0),      // 61 - hardest

]

// We create this simple little function to tell us if a robot has a launcher.  That way if we have
// to modify conditions we can just do it here rather than everywhere else in the code.
func doesRobotHaveLauncher(playerType: PlayerType, robotType: RobotType) -> Bool {
    var hasLauncher: Bool = false
    
    if playerType == .localHumanPlayer || robotType == .baker || robotType == .doublebaker || robotType == .superbaker || robotType == .pastrychef {
        hasLauncher = true
    }
    return hasLauncher
}

// We create this simple little function to let us know if a robot has arms.  This is needed particularly for
// those times when we need to change the color of the arms to match the corrosion or static discharge damage
// to a particular robot.  We check that the robot is not a player robot because all robots are assigend as workers
// by default and then modified later.  However, because the player robot doesn't have to be reconfigured by robot type
// since it is one particular robot, we have to check it here.  And it's good to do so because we could change this
// circumstance later and give the player robot arms.
func doesRobotHaveArms(playerType: PlayerType, robotType: RobotType) -> Bool {
    var hasArms: Bool = false
    
    if playerType != .localHumanPlayer && (robotType == .worker || robotType == .superworker) {
        hasArms = true
    }
    return hasArms
}

// simple function to print a timestamp and a message.  Since we're mostly
// concerned about what happens while we're testing we don't need the date,
// just the time so we use that here.  For now we're mainly concerned with
// performance testing so seconds is the smallest unit we're using right now.
func showTimeAndMessage(message: String) {
    let dateFormat = DateFormatter()
    dateFormat.dateFormat = "hh:mm:ss"
    dateFormat.locale = Locale.current
    let theTime = dateFormat.string(from: Date())
    print ("\(String(describing: theTime)): \(message)")

}

// we really just have two different types of tutorial steps, one a gesture and the
// other a go to location where the player has to get to a certain place in the level.
// We distinguish between the two because the gesture is handled by the 2D control panel
// and the goto locations are handled by the 3D scene.  This makes it easy for us to place
// arrows.  In the 2D control panel we don't care where the robot is in the 3D scene just
// as long as we can put in animations to inform the players the gestures we want them
// to make.  In the go to locations if we use the scene we can just place arrows above the
// locations where we want the players to go pointing downwards and don't have to keep
// track of where they are; we would just remove them when a player reaches that spot.
// The notype is just a placeholder during initialization.
enum TutorialStepType {
    case swipeleft
    case swiperight
    case swipeup
    case swipedown
    case tapstop
    case taptarget1
    case taptarget2
    case taptarget3
    case gotopart
    case gotoexit
    case notype
}

// different states for the tutorial step.  This gives us a feeling for where we are in the
// tutorial as well as where we are in that step of the tutorial.
enum TutorialStepState {
    case hasnotstartedyet
    case inprogress
    case completed
}

let defaultStepDuration = 3.0
let defaultStepLoc2D = CGPoint(x: 0.50, y: 0.70)
let defaultStepLoc3D = SCNVector3Zero

// exit's x coord relative to the player's x coord.  For use in determining which
// arrows to use in the tutorial to guide the player to the exit.
let exitXNearPlayerX = Float(15.0)
let exitXUpRightOfPlayerX = Float(40.0)
let exitXUpLeftOfPlayerX = -Float(40.0)

let goToExitLabel = "Go To Exit"

// A structure describing all the parts of a tutorial step.  We would have preferred to keep this within the
// Tutorial class but since this will be needed elsewhere, like in the control panel or the scene where
// the name and duration will be used, we needed to make it global.
struct TutorialStep {
    var durationOfStep: Double = 0.0
    var stepName: String = ""
    var stepNumber: Int = 0
    var stepState: TutorialStepState = .hasnotstartedyet
    var stepType: TutorialStepType = .notype
    var hasArrow: Bool = false
    
    // Note: the gesture steps are placed in the control panel but the parts gathering steps placed
    // in the 3D scene.  Thus, our need for the two locations below to make this structure as generic
    // as possible.  It's a little inefficient but unless we have thousands of steps in our tutorial it
    // should be low memory usage.
    var loc2D: CGPoint = CGPoint(x: 0.0, y: 0.0)  // where we should place this in the control panel
    var loc3D: SCNVector3 = SCNVector3Zero       // where we should place this in the scene.
    
    init(number: Int, name: String, type: TutorialStepType, duration: Double, state: TutorialStepState, loc2D: CGPoint, loc3D: SCNVector3, hasArrow: Bool) {
        durationOfStep = duration               // duration that covers the presentation and also an allowance of time for player to perform the step.
        stepState = state
        stepName = name
        stepNumber = number
        self.loc2D = loc2D
        self.loc3D = loc3D
        stepType = type
        self.hasArrow = hasArrow 
    }
}

enum GameSoundType {
    //case levelentry
    case buttontap
    //case gameoverman
    //case bowlingstrike
    case powerup
    //case partpickup
    //case bunsenburner
    //case crickets
    case constantspeed
    //case levelexit
}

// keys for damage and recovery.  We use the same key for impact and recovery from that impact;
// that way if a new hit comes in while the recovery is happening the sound gets overriden with
// the new impact sound, which is what we want.  The same goes for corrision damage and recovery.
// We want to override any previous sound with the latest sound.  That way the player gets instant
// feedback on what's happening.
// 
let impactOrRecoverySoundKey = "iOR"     // we use the same key for impact and recovery
let zapSoundActionKey = "zapSound"        // We use it for both the player and ai robots so we put it here
let burningSoundKey = "burn"                // for use when the robot is corroding/burning up/destroyed
let empDischargeSoundKey = "emp"
let staticDischargeSoundKey = "sd"          // when zapped or emp'ed so much that the robot is damaged, emitting static discharge.
let targetTapSoundKey = "tt"                // key for when the player taps on a target.

let backButtonCornerRadius = CGFloat(4.0)            // The corner radius for all back buttons, for consistency.

func getMidPoint (p1: Float, p2: Float) -> Float {
    let deltaP = abs(p1 - p2)
    var midPoint: Float = 0.0
    
    if p1 < p2 {
        midPoint = p1 + deltaP / 2.0
    }
    else {
        midPoint = p2 + deltaP / 2.0
    }
    return midPoint 
}
