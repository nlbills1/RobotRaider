//
//  ViewController.swift
//  RobotRaider
//
//  Created by Nathanael Bills on 10/13/16.
//  Copyright © 2016 invasivemachines. All rights reserved.
//

import UIKit
import SceneKit
import CoreData
import AVFoundation

class GamePlayViewController: UIViewController, SCNSceneRendererDelegate, SCNPhysicsContactDelegate {

    // Data passed to this Class from the LevelSelectViewController
    var levelNum: Int = 0
    var screenSize: CGSize!
    var playerInventory: PlayerInventory = PlayerInventory()
    var playerInventoryList: Inventory = Inventory()
    var playerItem1: String = ""
    var playerItem2: String = ""
    var playerItem3: String = ""
    // end of data passed by LevelSelectViewController
    
    var newPlayerDirectionJustSwiped: Int = zeroDirection   // track direction just swiped by player - just for pass through from the swipe gesture
                                                            // recognizer to the updatePlayer() function.  We use it to minimize the possibility of a race
                                                            // condition.
    var swipeCountJustUpdated: Int = 0                      // tracks swipe count just updated - just for pass through from the swipe gesture
                                                            // recognizer to the updatePlayer() function.  We use it to minimize the possibility of a race
                                                            // condition.
    
    var newPlayerDirection: Int = zeroDirection             // The new direction the robot goes after a swipe.  This is our internal equivalent of a
                                                            // swipe direction.  We use this to totally divorce the internals of the game from the gesture
                                                            // recognizer code in the sdk.  We update the player's direction from this _outside_ of the
                                                            // gesture recognizer function.  The gesture recognizer functions run in the main thread and
                                                            // we run into a race condition if we do anything in the gesture recognizer functions and
                                                            // also work with any of the same data elsewhere in the game.  Thus, we use this instead of
                                                            // and swipe gesture sdk components to keep things separated.
    
    var swipeCount: Int = 0                                 // This is used as a flag without us having to reset it later.  Each time a swipe is made we update
                                                            // the count. Each time the player's robot direction is updated in updatePlayerRobot due to the change
                                                            // in swipeCount, we update lastSwipeCount.  In this way we keep a flag going on and off correctly without
                                                            // having to reset the flag in updatePlayerRobot().  That way we don't have to worry about synchronization
                                                            // and race conditions.
    var lastSwipeCount: Int = 0
    
    var tap2DLocationJustTapped: CGPoint = CGPoint(x: 0, y: 0)    // track tap just made - just for pass through from the tap gesture recognizer to the
                                                                // updatePlayer() function.  We use it to minimize the possibility of a race condition.
    var tapCountJustUpdated: Int = 0                            // track tap count just updated - just for pass through from the gap gesture recognizer to the
                                                                // updatePlayer() function.  We use it to minimize the possibility of a race condition.
    
    var tap2DLocation: CGPoint = CGPoint(x: 0, y: 0)            // tap 2d location saved each time player taps on the screen.
    var tapCount: Int = 0                                   // tapCount keeps track of the number of taps the player has made.  This is used as a flag and lets us
                                                            // know of another tap without us having to reset a flag after each time one has been detected.  This way
                                                            // we don't run into any race conditions or worry about synchronization for the same reason we don't
                                                            // have to worry about swipes because of our use of swipeCount as a flag.  We update lastTapCount when
                                                            // we handle the tap.
    var lastTapCount: Int = 0
    
    var sceneView: SCNView!
    var controlPanel: ControlPanelOverlay!
    var playerLevelData: PlayerLevelData!
    var ground: SCNNode!
    var primaryCam: SCNNode!
    
    var randomNumGenerator: RandomNumberGenerator!
    
    var parts: [String : PartInLevel] = [ : ]
    var entirePartsList: [Int : Part] = [ : ]           // all of the parts in the game--which we update as the level progresses.
    var powerUps: [String : PowerUp] = [ : ]
    
    var aiRobots: [String : Robot] = [ : ]
    var playerRobot: Robot!
    var playerStartingLocation: SCNVector3!
    
    var bakedGoods: [String : BakedGood] = [ : ]
    var empGrenades: [String : EMPGrenade] = [ : ]
    var bakedGoodsCount: Int = 0    // number of baked goods hurled so far.  Used as a label in a baked good's name.
    var empGrenadeCount: Int = 0    // number of grenades hurled so far.  Used as a label in the grenade's name.
    
    // Note: we don't have to keep track of the number of walls in the bakery.  We can just get walls.count
    // from the bakeryRoom object.  As of 2016-10-25 the walls are just 'leftwall', 'rightwall', 'farwall', 'nearwall'
    // and ceiling anyway.
    
    var lastPlayerRobotPosition: SCNVector3 = SCNVector3(0.0, 0.0, 0.0)
    var lastPlayerRobotLevelPos: LevelCoordinates = LevelCoordinates()
    
    var currentLevel: Level!
    
    var levelStatus: LevelStatus = .levelInProgress
    
    var viewAngle: ViewAngle = .firstpersonview    // the view angle, either first person or overhead.  Used for debugging.
    
    var selectedAmmo: String = ""
    
    // parameters to get from level select view controller so we can then place parts.
    var partsStart: Int = 0
    var partsEnd: Int = 0
    var numPowerUps: Int = 0
    
    var preexistingNumPartsFound: Int = 0   // preexisting number of parts already found.  This happens when the player has
                                            // visited the level before and had gathered some parts already.  Otherwise, this
                                            // should be zero.  This will be passed by the level select view controller.
    
    var vaultOpened: Bool = false    // only set to true in the last level when the player has defeated all the robots and
    // unlocked the vault door.  This should be returned to the Level Select view controller,
    // which would then use it to display what was found in the vault.
    
    var cameraXOffset: Float = 0.0
    var cameraZOffset: Float = 0.0
    var cameraYOffset: Float = 0.0

    var ammoIsUsedInLevel: Bool = true      // assume player is using ammo in the level.  Later, when we initialize the level we set this to
                                            // false if that is not the case.  Then we use it later when determining whether or not to throw
                                            // a baked good when the player taps on the screen.
    var zapperIsUsedInLevel: Bool = false                   // assume zapper isn't used, then correct it as we enter the level.
    var bunsenBurnerIsUsedInLevel: Bool = false             // assume bunsen burner isn't used, then correct it as we enter the level.
    var motionDetectorIsUsedInLevel: Bool = false           // assume same thing for motion detector
    var hoverUnitIsUsedInLevel: Bool = false                // assume same thing for hover unit.
    var secondLauncherIsUsedInLevel: Bool = false           // assume same thing for second launcher
    
    var bunsenBurnerOn: Bool = false                        // tells us when the bunsen burner is on.
    var bunsenBurnerFlameStartTime: Double = 0.0                // keep track of when the flame started so we know when to turn it off.
    var bunsenBurnerBurnIntervalTime: Double = 0.0              // keep track of the interval between burn checks; otherwise the ai robot will be burned up too quickly
    
    var workingRobotsAlreadyUpdated: Set<String> = []       // keep track of robots already updated in the level.  We want to update only one
                                                            // ai robot per renderer loop to reduce the impact to overall game performance.
                                                            // In order to do that we have to keep track of those that were already updated to
                                                            // avoid updating them again while others have not been updated.  After they have all
                                                            // been updated, workingRobotsAlreadyUpdated should be reset to the null set to start
                                                            // the process over again.
    
    var workerRammingPlayer: WorkerRammingState = .notRamming   // let the game know when a worker is ramming the player or has rammed it to keep others from doing it.
    var playerReloadStatusLastCheckTime: Double = 0.0
    
    var currentVaultBarrierState: VaultBarrierStates = .on     // default to the on state.  Even if the player isn't in the last level, this is a safety measure.
    
    var hasUnwindSegueBeenInitiated: Bool = false
    var backButtonTapped: Bool = false                          // set when back button tapped -- to let level select know that's what was done to get back to that screen.
    
    // a queue to handle the variables associated with the gestures.  We use this so that we can use GCD to avoid
    // data race conditions as we pass data from the gesture recognizer functions, which run
    // on the main thread, to our gesture handling code, which runs on another thread, wherever
    // the renderer seems to run.   Important Note:  This is a serial queue because we want there to be
    // absolutely _no_ data race conditions because we're dealing with data that needs sychronization.
    // I'm worried that the use of a serial queue could slow the game down a bit.  We'll see.
    var gestureHandlingQueue: DispatchQueue = DispatchQueue(label: gestureHandlingQueueLabel, qos: DispatchQoS.userInteractive)
    
    var timeBackToLevelSelectInitiated: Double = 0.0        // we have to use a kludgy timer just to get a simple time delay between the back button/level select button
                                                            // pressed and the segue back to the level select screen.
    var timeFadeOutInitiated: Double = 0.0                  // save the time fade out was initiated.  then check it against a constant fade out delay.
    
    var playerUpdateCount: Int64 = 0                        // we keep track of the update count to avoid updating the player's velocity at every update because
                                                            // that can cause jerkiness.  However, we still want to leave open the possibility of an update through
                                                            // a change in direction via a swipe.
    
    var isTutorialEnabled: Bool = false                     // flag to tell us if tutorial is one.  This tells us to create the tutorial and then
                                                            // step through it.
    var tutorial: Tutorial!                                 // tutorial on how to play.  Only created when the game starts for the very first time, or when
                                                            // the player has turned it on in the level select screen.
    
    var musicPlayer = AVAudioPlayer()                       // For the intro to level music.
    
    var introDelayDone: Bool = false                        // intro delay to let the player get situated.

    // prefer to hide the status bar, which interferes with the experience.
    override var prefersStatusBarHidden: Bool {
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        createScene()
        self.view.backgroundColor = UIColor.black // we set the view background to black--otherwise we see a white
                                        // screen before the scenekit scene loads.
        self.view.alpha = 0.0           // make it black--we will fade it in as soon as the view appears.
    }
    
    // We need this function so we can play the level sound when the level starts.
    override func viewDidAppear(_ animated: Bool) {
        fadeIn(view: self.view, duration: 1.0)
        //gameSounds.playSound(soundToPlay: .levelentry)
        gameSounds.playSound(soundToPlay: .constantspeed)
    }
    
    // create the ground, lighting, robots, etc. for the scene.
    func createScene() {
        sceneView = SCNView(frame: self.view.frame)
        // We have to set delegate as self for the sceneView to get the renderer function farther below to work.
        sceneView.delegate = self
        self.view.addSubview(sceneView)
        sceneView.scene = SCNScene()
        
        // preload the ammo models for use in the level to prevent stutter later.  Otherwise the ammo is lazy loaded and
        // that causes a couple of freezes early on, one for when the player launches a baked good and one for when it impacts
        // and creates residue.  Also, we could see freezes if the ai robots launched ammo not already preloaded.
        sceneView.prepare([allModelsAndMaterials.custardPieModel, allModelsAndMaterials.pumpkinPieModel, allModelsAndMaterials.chocolateCupcakeModel,
                           allModelsAndMaterials.raspberryPieModel, allModelsAndMaterials.keylimePieModel, allModelsAndMaterials.lemonJellyDonutModel,
                           allModelsAndMaterials.residueModel, allModelsAndMaterials.stickyDoughMaterial, allModelsAndMaterials.puffOfSteamModel,
                           allModelsAndMaterials.splatterModelLarge, allModelsAndMaterials.threeDArrowModel], completionHandler: nil)
        
        // Note: we preload the sounds the we think might be used in middle of the level.  If sound
        // is only played at the beginning or the end we don't worry about it.
        // preload all node audio sounds used in a level, whether we need them or not.
        NodeSound.launcherturn?.load()
        NodeSound.puffOfSteam?.load()
        //NodeSound.bigZap?.load()
        //NodeSound.soakUpImpact?.load()
        //NodeSound.recoverFromImpact?.load()
        NodeSound.splat?.load()
        NodeSound.fry?.load()
        //NodeSound.fallandcrash?.load()
        //NodeSound.pop?.load()
        //NodeSound.empDischarge?.load()
        //NodeSound.bounce?.load()
        NodeSound.staticDischarge?.load()
        NodeSound.crash?.load()
        NodeSound.targetTap?.load()
        
        // preload general sounds
        gameSounds.sounds[.buttontap]?.prepareToPlay()
        gameSounds.sounds[.powerup]?.prepareToPlay()
        //gameSounds.sounds[.partpickup]?.prepareToPlay()
        
        // Sigh.  It appears that setting the orientation to landscape doesn't change what iOS thinks is the width and height of the screen.  It still
        // treats it like it's in portrait mode in terms of width and height.  However, this only happens with some devices, like iPhones.  With iPads,
        // particularly the iPad Pro the values are correct after the switch to landscape orientation.  So rather than try to anticipate every
        // possible result we fudge and say that the larger value is always the width and the smaller value is always the height because the game
        // is only in landscape mode.
        
        if self.view.bounds.size.height > self.view.bounds.size.width {
            screenSize = CGSize(width: self.view.bounds.size.height, height: self.view.bounds.size.width)
        }
        else {
            screenSize = self.view.bounds.size
        }
        
        sceneView.backgroundColor = UIColor.black
        sceneView.scene?.physicsWorld.contactDelegate = self
        
        // fire up our random generator here and pass it around as needed to other classes.
        randomNumGenerator = RandomNumberGenerator(seed: levelNum)
        
        //showTimeAndMessage(message: "Scene creation just before level creation")
        // Note: allModelsAndMaterials is global.  This was the only way we could think to load it only once instead of
        // at each instance of game play
        currentLevel = Level(sceneView: sceneView, levelNum: levelNum, randomGenerator: randomNumGenerator)
        //showTimeAndMessage(message: "Scene creation just after level creation")
        sceneView.isUserInteractionEnabled = true  // make sure user interaction is enabled for the view.
        
        sceneView.overlaySKScene = ControlPanelOverlay(size: screenSize)
        controlPanel = sceneView.overlaySKScene as? ControlPanelOverlay
        
        sceneView.overlaySKScene?.isUserInteractionEnabled = false
        controlPanel.updateDisplayedLevelNumber(num: levelNum)
        
        let groundGeometry = SCNFloor()
        groundGeometry.reflectivity = 0.0
        let groundMaterial = SCNMaterial()
        groundMaterial.diffuse.contents = "components.scnassets/grid.png"
        
        // vary floor color depending on the level number to add some variety.
        if levelNum % 7 == 0 {
            groundMaterial.multiply.contents = UIColor(red: 0.3, green: 0.3, blue: 0.1, alpha: 1.0)
        }
        else if levelNum % 5 == 0 {
            groundMaterial.multiply.contents = UIColor(red: 0.2, green: 0.2, blue: 0.4, alpha: 1.0)
        }
        else if levelNum % 3 == 0 {
            groundMaterial.multiply.contents = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        }
        else {
            groundMaterial.multiply.contents = UIColor.darkGray
        }
        groundMaterial.diffuse.wrapS = SCNWrapMode.repeat
        groundMaterial.diffuse.wrapT = SCNWrapMode.repeat
        // from https://stackoverflow.com/questions/44920519/repeating-a-texture-over-a-plane-in-scenekit
        // This sets the scale of the floor pattern to keep it from being too big or too small.  If not
        // set, then the grid becomes way to coarse.  If set too high, the grid is way too granular.
        groundMaterial.diffuse.contentsTransform = SCNMatrix4MakeScale(20, 20, 0)
        ground = SCNNode(geometry: groundGeometry)
        // IMPORTANT NOTE:  The ground is the _ONLY_ thing that has a category bit mask set for the node.  This enables
        // us to tap anywhere on the floor and the baked good will be launched there.  This works because we have the
        // camera angled such that no matter where the player taps, they will eventually tap on the floor. After some initial
        // testing I see that it seems to work fine.  If it didn't work right, like if the camera angle was parallel to the
        // floor rather than angled towards it, then a tap on anything but the floor would not result in a baked good
        // being launched.  We do this to get around the problem of the steam cloud being the result returned from
        // a tap and the baked good being thrown towards the player's view rather than toward the target.  This is a little
        // dangerous in that only the floor will generate a hitTest result.  However, after some initial testing I think
        // it's fine.  We just have to always, always keep this in mind.  The alternative was to assign the
        // same categoryBitMask to _every_ node except the steam cloud node, which would have been a huge amount of work.
        // This simple assignment to the floor saves us a lot of work and troubleshooting.  Plus we get the added bonus
        // of the hitTest not returning things like the zap bolt, a baked good in flight, or anything else like that
        // that is transient, although at some point we might want the baked good to come back in a hitTest.  We'll see.
        ground.categoryBitMask = categoryRegisterInHitTest
        ground.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        ground.physicsBody!.categoryBitMask = collisionCategoryGround
        ground.physicsBody!.contactTestBitMask = collisionCategoryAIRobotBakedGood | collisionCategoryPlayerRobotBakedGood
        ground.physicsBody!.collisionBitMask =  collisionCategoryAIRobot | collisionCategoryPlayerRobot | collisionCategoryDyingRobot | collisionCategoryEMPGrenade
        ground.geometry?.firstMaterial = groundMaterial
        ground.name = groundLabel
        ground.position = SCNVector3Zero    // this is the default but we explicitly set it to be sure.
        sceneView.scene?.rootNode.addChildNode(ground)

        // Add all the gesture recognizers we'll use.
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(GamePlayViewController.tapDetected))
        sceneView.addGestureRecognizer(tapRecognizer)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(GamePlayViewController.swipeResponse))
        swipeRight.direction = UISwipeGestureRecognizerDirection.right
        sceneView.addGestureRecognizer(swipeRight)
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(GamePlayViewController.swipeResponse))
        swipeLeft.direction = UISwipeGestureRecognizerDirection.left
        sceneView.addGestureRecognizer(swipeLeft)
        
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(GamePlayViewController.swipeResponse))
        swipeUp.direction = UISwipeGestureRecognizerDirection.up
        sceneView.addGestureRecognizer(swipeUp)
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(GamePlayViewController.swipeResponse))
        swipeDown.direction = UISwipeGestureRecognizerDirection.down
        sceneView.addGestureRecognizer(swipeDown)
        
        let camera = SCNCamera()
        camera.zFar = 500
        camera.zNear = 0.1         // According to the documentation, zNear can't be zero.  But it doesn't say it can't be close.
        primaryCam = SCNNode()
        primaryCam.camera = camera
        primaryCam.camera?.fieldOfView = wideAngleCameraLens
        
        sceneView.scene?.rootNode.addChildNode(primaryCam)
  
        playerStartingLocation = calculateSceneCoordinatesFromLevelRowAndColumn(levelCoords: currentLevel.playerStartingPoint)
        // Note: allModelsAndMaterials is global.  This was the only way we could think to load it only once instead of
        // at each instance of game play
        
        // check to see what weapons or equipment is used in the level.
        if isItemInSelections(item: zapperWeaponLabel, selections: [playerItem1, playerItem2, playerItem3]) == true {
            zapperIsUsedInLevel = true
        }
        else {
            zapperIsUsedInLevel = false             // even though this is the default, we set it again here, just to be safe
        }
        if isItemInSelections(item: anotherLauncherLabel, selections: [playerItem1, playerItem2, playerItem3]) == true {
            secondLauncherIsUsedInLevel  = true
        }
        else {
            secondLauncherIsUsedInLevel = false      // even though this is the default, we set it again here, just to be safe
        }
        if isItemInSelections(item: motionDetectorLabel, selections: [playerItem1, playerItem2, playerItem3]) == true {
            motionDetectorIsUsedInLevel = true
        }
        
        if isItemInSelections(item: hoverUnitLabel, selections: [playerItem1, playerItem2, playerItem3]) == true {
            hoverUnitIsUsedInLevel = true
        }

        if isItemInSelections(item: bunsenBurnerLabel, selections: [playerItem1, playerItem2, playerItem3]) == true {
            bunsenBurnerIsUsedInLevel = true
        }
        
        playerRobot = Robot(robotNum: 0, playertype: .localHumanPlayer, robottype: .worker, location: playerStartingLocation, robotLevelLoc: currentLevel.playerStartingPoint, ammoChoices: playerInventoryList.getUnlockedAmmoListByName(), pInventory: playerInventoryList, randomGen: randomNumGenerator, zapperEnabled: zapperIsUsedInLevel, secondLauncherEnabled: secondLauncherIsUsedInLevel, bunsenBurnerEnabled: bunsenBurnerIsUsedInLevel)

        // Add entrance, from which the player robot emerged.
        currentLevel.addLevelEntrance(sceneView: sceneView, playerLoc: playerStartingLocation)
        
        // Note: we have to wait until after the player robot has been created to set the reload time
        if bunsenBurnerIsUsedInLevel == true {
            // set the reload time only once.  It's used for determining when the bunsen burner has finished reloading
            // and is constant.
            for aPrize in prizesList {
                if aPrize.prizeName.range(of: bunsenBurnerLabel) != nil {
                    playerRobot.robotHealth.bunsenBurnerReloadTime = aPrize.reloadTime
                }
            }
            // preload flame sound.
            //gameSounds.sounds[.bunsenburner]?.prepareToPlay()
        }
        

        // Ammo is always the first item - enforced in the item select view controller.
        //ammoIsUsedInLevel = false
        selectedAmmo = playerItem1
        ammoIsUsedInLevel = true
        
        playerRobot.updateSelectedAmmo(ammoSelected: selectedAmmo)
        playerRobot.updateNumberOfLaunchers(items: [playerItem1, playerItem2, playerItem3])
        sceneView.scene?.rootNode.addChildNode((playerRobot?.robotNode)!)
        // Dont' forget to add it to allDurableComponents in the level instance for quick reference
        currentLevel.allDurableComponents[(playerRobot?.robotNode)!.name!] = .playerrobot
        // place camera behind player's robot once it has been put in the scene.
        primaryCam.position = SCNVector3(x: cameraXOffset + playerRobot.robotNode.position.x, y: cameraYOffset + playerRobot.robotNode.position.y, z: cameraZOffset + playerRobot.robotNode.position.z)
        switchToTwoAndAHalfDView()
        //switchToFirstPersonView()


        // record the player's location in the level by row and column at the start of the level.
        lastPlayerRobotLevelPos = calculateLevelRowAndColumn(objectPosition: playerRobot.robotNode.position, maxRow: currentLevel.levelGrid.count - 1, maxCol: currentLevel.levelGrid[0].count - 1)
        playerRobot.levelCoords = lastPlayerRobotLevelPos
        playerRobot.lastLevelCoords = lastPlayerRobotLevelPos
        playerRobot.lastLevelCoordsWhereVelocitySet = lastPlayerRobotLevelPos
        currentLevel.levelGrid[playerRobot.levelCoords.row][playerRobot.levelCoords.column].append(playerRobot.robotNode.name!)
        
        //showTimeAndMessage(message: "Scene creation just before placing ai robots")
        // Note: allModelsAndMaterials is global.  This was the only way we could think to load it only once instead of
        // at each instance of game play
        aiRobots = currentLevel.placeRobots(sceneView: sceneView, playerRobot: playerRobot, ammoChoices: playerInventoryList.getUnlockedAmmoListByName(), pInventory: playerInventoryList)
        
        //showTimeAndMessage(message: "Scene creation just after placing ai robots")
        // get the player inventory data from what was passed from the Level Select TableView controller and
        // then update the player's robot health using that data.  These two steps _must_ be done in this order.
        // Note: the player inventory data is passed from the Level Select View Controller so it is already
        // updated when we get into GamePlayViewController.
        if levelNum == highestLevelNumber {
            playerLevelData = PlayerLevelData(maxRobots: aiRobots.count, maxParts: keyPrize.requiredNumberOfParts)
            currentVaultBarrierState = .on     // barrier should be on by default but turn it on here anyway.
        }
        else {
            playerLevelData = PlayerLevelData(maxRobots: aiRobots.count, maxParts: partsEnd - partsStart + 1)
        }
        playerLevelData.numberOfPartsFound = preexistingNumPartsFound
        if levelNum == highestLevelNumber {
            // note: we only place parts when the player hasn't found them all.  Actually, it should be
            // an all-or-nothing thing.  So if the statement below is true then the player will not have
            // previously completed the vault level.
            if playerLevelData.numberOfPartsFound < playerLevelData.maxPartsToFind {
                parts = currentLevel.placeKeyParts(sceneView: sceneView, numKeyParts: keyPrize.requiredNumberOfParts)
            }
            else { // the player has already completed the highest level, so we turn off the barrier because the key parts have already
                // been obtained.
                turnOffVaultBarrier()
            }
        }
        else {
            parts = currentLevel.placeParts( sceneView: sceneView, partStartNum: partsStart, partEndNum: partsEnd, partsList: entirePartsList)
        }
        //showTimeAndMessage(message: "Scene creation just after placing parts")
        powerUps = currentLevel.placePowerUps( sceneView: sceneView, numPowerUps: numPowerUps)
        //showTimeAndMessage(message: "Scene creation just after placing powerups")
        
        // After we've added parts to the scene, then draw the map with the player, the exit and the parts.
        controlPanel.drawMap(theLevel: currentLevel, playerLoc: playerRobot.levelCoords, parts: parts)
        if motionDetectorIsUsedInLevel == true {
            controlPanel.addAIRobotsToMap(theLevel: currentLevel, aiRobots: aiRobots, motionDetectorUsed: motionDetectorIsUsedInLevel)
        }
        
        // Add reload status bars
        controlPanel.drawAndInitReloadingStatusBar(numberOfBars: playerRobot.timeReloadStarted.count)
        if zapperIsUsedInLevel == true {
            controlPanel.drawAndInitZapStatusBar()
        }
        if bunsenBurnerIsUsedInLevel == true {
            controlPanel.drawAndInitBunsenBurnerStatusBar()
        }
        
        controlPanel.updateDisplayedPartsFound(numPartsFound: playerLevelData.numberOfPartsFound, maxPartsToFind: playerLevelData.maxPartsToFind)
        controlPanel.updateDisplayedRobotsDestroyed(numRobotsDestroyed: playerLevelData.numberOfRobotsDestroyed, maxRobotsToDestroy: playerLevelData.maxRobotsToDestroy)
        //sceneView.showsStatistics = true   // show our fps for testing
        //sceneView.debugOptions = .showPhysicsShapes  // show bounding boxes around objects for collision detection debugging.
        
        // If there's fog, then the fogTotalObscureDistance is not zero.  And if not zero, then we set the fogEndDistance.
        // The fogStartDistance we leave as the default 0.0 distance.
        //  When performance in simulator is slow, then comment out the fog code below.  That should speed things up.  Just
        // remember to uncomment the code later to bring fog back.
        // TEMPORARY: we comment out the code below when testing in the simulator because it really slows things down.  Otherwise
        // it should be enabled.
        
        if currentLevel.levelChallenges.fogEndDistance > 0.0 {
            sceneView.scene?.fogEndDistance = currentLevel.levelChallenges.fogEndDistance
            sceneView.scene?.fogStartDistance = currentLevel.levelChallenges.fogStartDistance
            sceneView.scene?.fogColor = currentLevel.levelChallenges.darkness
            // the text color at the top is normally yellow, which we can see in white fog, so we make it a dark
            // color instead.
            if currentLevel.levelChallenges.darkness == UIColor.white {
                controlPanel.makeTopTextColorDark()
            }
        }
        
        if isTutorialEnabled == true {
            if levelNum < highestLevelNumber {
                tutorial = Tutorial(parts: parts, exitLoc: currentLevel.levelExitNode.position)
            }
            else {
                tutorial = Tutorial(parts: parts, exitLoc: currentLevel.vaultNode.position)
            }
            controlPanel.setUpTutorial()
        }
        //showTimeAndMessage(message: "Scene creation done")
    }

    @objc func tapDetected(recognizer: UITapGestureRecognizer) {
        // put the gesture handling code into a queue asynchronously.  We only write to
        // tap2DLocation and tapCount here and we don't want to wait for them to finish.
        // otherwise we might screw up the interactiveness of gesture.
        
        let tapLoc = recognizer.location(in: self.sceneView)
        gestureHandlingQueue.async(execute: {
            self.tap2DLocationJustTapped = tapLoc
            self.tapCountJustUpdated += 1
        })
    }
        
    @objc func swipeResponse(swipeGesture: UISwipeGestureRecognizer) {
        let swipeGesture = swipeGesture as UISwipeGestureRecognizer
        // put the gesture handling code into a queue asynchronously.  We only write to
        // newDirection and swipeCount here and we don't want to wait for them to finish.
        // otherwise we might screw up the interactiveness of gesture.
        let swipeDirection = swipeGesture.direction
        var newDirection: Int = zeroDirection
        switch swipeDirection {
        case UISwipeGestureRecognizerDirection.right:
            newDirection = west
        case UISwipeGestureRecognizerDirection.left:
            newDirection = east
        case UISwipeGestureRecognizerDirection.up:
            newDirection = north
        case UISwipeGestureRecognizerDirection.down:
            newDirection = south
        default:
            break
        }
        gestureHandlingQueue.async(execute: {
            self.newPlayerDirectionJustSwiped = newDirection
            self.swipeCountJustUpdated += 1
        })
    }
    
    // We want to update all the residue velocities to match those of the ones of the moving
    // objects to which they are attached.  We don't care about the ones attached to objects
    // not moving, like walls.
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
        // Important Note: we are dependent upon the levelentry sound being played right when the level starts.
        // if that sound never plays, or is in some way reset, then the ai robots won't start moving.
        // So we must be careful with this.  Also, we have to always be sure to only run this sound once per
        // level.  Otherwise the robots may freeze while they wait for the levelentry to progress.
        /*
        if gameSounds.sounds[.levelentry]!.currentTime > delayWhileLevelIntroSoundPlays {
            introDelayDone = true
        }
        */
        introDelayDone = true   // Note: we set this to true; otherwise the robots never start moving.  We only do this
                                // here because the above code to play the intro sound has been commented out since the
                                // sound we're using for that is a GarageBand loop, which has some restrictions so we can't
                                // just give it away for any use.
        
        let currentTime = NSDate().timeIntervalSince1970
        // Note: we don't include the check of the state of hasUnwindSegueBeenInitiated in the top level if statement because
        // the top level checks the time but also acts to stop any more updates when that time limite has been reached.  That
        // way we don't get any spurious activity going on in the scene that could cause problems.
        if timeBackToLevelSelectInitiated > 0.001 && currentTime - timeBackToLevelSelectInitiated > timeDelayForBackButtonToWork {
            if hasUnwindSegueBeenInitiated == false {
                hasUnwindSegueBeenInitiated = true
                backButtonTapped = true
                // Segue but wait 0.5 seconds to make sure all animations clear out.  Otherwise, we get a nasty
                // warning message in the log from iOS.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                    self.performSegue(withIdentifier: "unwindSegueToLevelSelect", sender: self)
                })
            }
        }
        else if timeFadeOutInitiated > 0.001 && currentTime - timeFadeOutInitiated >  fadeOutTimeDelay {
            if hasUnwindSegueBeenInitiated == false {
                hasUnwindSegueBeenInitiated = true
                // Segue but wait 0.5 seconds to make sure all animations clear out.  Otherwise, we get a nasty
                // warning message in the log from iOS.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                    self.performSegue(withIdentifier: "unwindSegueToLevelSelect", sender: self)
                })
            }
        }
        else {
            if currentLevel.holes.isEmpty == false {
                updateHoles()
            }
            updateBakedGoods()
            updateEMPGrenades()
            if levelNum == highestLevelNumber && currentVaultBarrierState == .denied {
                checkVaultBarrierStatus()
            }
            if !playerRobot.robotDisabled {
                // Note: Only keep ai robots from moving while intro sound played.  Allow player to move around or go back to
                // level select.
                updatePlayerRobot()
                if introDelayDone == true {
                    updateAIRobots()
                }
            }
            else {
                // be sure to stop the wheels turning on all the ai robots if the player's robot is destroyed.
                // Otherwise it looks odd to see the wheels turning as the robots stop.
                for (_,aRobot) in aiRobots {
                    aRobot.stopTurningWheels()
                }
            }
        }
    }
    
    // This function checks to see whether or not the player's robot is near the vault barrier
    // if not then it resets it to .on instead of denied.
    func checkVaultBarrierStatus() {
        let zdistance = abs(playerRobot.robotNode.presentation.position.z - currentLevel.vaultBarrierNode.position.z)
        let xdistance = abs(playerRobot.robotNode.presentation.position.x - currentLevel.vaultBarrierNode.position.x)    // use abs() since robot can be on either side of vault.
        if zdistance > minimumZDistanceFromBarrier || xdistance > minimumXDistanceFromBarrier {
            currentLevel.vaultBarrierNode.geometry?.firstMaterial?.diffuse.contents = vaultBarrierOriginalColor
            currentVaultBarrierState = .on
        }
    }
    
    // here we update holes to cover them back up if the player is no longer close to them.  This
    // makes them devious and hard to spot.
    func updateHoles() {
        let holes = currentLevel.holes
        
        for (_, aHole) in holes {
            if aHole.camouflaged == false {
                let deltax = abs(aHole.holeNode.position.x - playerRobot.robotNode.position.x)
                let deltaz = abs(aHole.holeNode.position.z - playerRobot.robotNode.position.z)
                let distance = sqrt(deltax*deltax + deltaz*deltaz)
                let halfHoleWidth = Float(levelComponentSpaceWidth) * 1.30 / 2.0
                let halfHoleLength = Float(levelComponentSpaceLength) * 1.50 / 2.0
                let minSafeDistanceFromHole = sqrt(halfHoleWidth*halfHoleWidth + halfHoleLength*halfHoleLength) * 1.10  // 10% fudge factor
                if distance > minSafeDistanceFromHole {
                    aHole.camouflageHole()
                }
            }
        }
    }
    
    // track all baked goods everywhere and remove those that have fallen through the floor.
    func updateBakedGoods() {
        var bakedGoodsToRemove: [String] = []
        // Next, remove any baked goods that have turned into residues that have fallen
        // through the floor.
        for (aBakedGoodName,aBakedGood) in bakedGoods {
            if aBakedGood.bakedGoodState == .fallingresidue {
                if aBakedGood.bakedGoodNode.presentation.position.y < yValueAtWhichBakedGoodCanBeRemoved {
                    bakedGoodsToRemove.append(aBakedGoodName)
                }
            }
        }
        for aBakedGoodToRemove in bakedGoodsToRemove {
            let theBakedGoodToRemove = bakedGoods[aBakedGoodToRemove]
            if theBakedGoodToRemove != nil {
                if bakedGoods[aBakedGoodToRemove]?.bakedGoodNode != nil {
                    // remove baked good and any children it might have
                    bakedGoods[aBakedGoodToRemove]?.bakedGoodNode.enumerateChildNodes { (node, stop) in
                        node.enumerateHierarchy { (cnode, _) in
                            cnode.removeFromParentNode()
                        }
                    }

                }
                if bakedGoods[aBakedGoodToRemove]?.residueNode != nil {
                    // remove residue and any children it might have
                    bakedGoods[aBakedGoodToRemove]?.residueNode.enumerateChildNodes { (node, stop) in
                        node.enumerateHierarchy { (cnode, _) in
                            cnode.removeFromParentNode()
                        }
                    }
                }
                if bakedGoods[aBakedGoodToRemove]?.splatter != nil {
                    bakedGoods[aBakedGoodToRemove]?.splatter.enumerateChildNodes { (node, stop) in
                        node.enumerateHierarchy { (cnode, _) in
                            cnode.removeFromParentNode()
                        }
                    }
                }
                bakedGoods.removeValue(forKey: aBakedGoodToRemove)
            }
        }
    }
    
    // Once the grenades are spent they can be removed from our list of active emp grenades.
    func updateEMPGrenades() {
        let empGrenadeNames = empGrenades.keys
        for aGrenadeName in empGrenadeNames {
            if empGrenades[aGrenadeName]?.spent == true {
                empGrenades[aGrenadeName]?.empGrenadeNode.enumerateChildNodes { (node, stop) in
                    node.enumerateHierarchy { (cnode, _) in
                        cnode.removeFromParentNode()
                    }
                }
                empGrenades.removeValue(forKey: aGrenadeName)
            }
        }
    }
    
    // update player's movement and also residue status
    func updatePlayerRobot() {
        let currentTime = NSDate().timeIntervalSince1970   // we get the current time early but use it throughout this function.
                                                            // it doesn't matter if it is off just a tiny bit because if the performance
                                                            // is so bad that this is too much off from what we need later in this function
                                                            // then we have much bigger problems.
        
        // we know that if the bunsen burner is on it will burn until shut off.  So we
        // check that here.
        if bunsenBurnerOn == true && currentTime - bunsenBurnerFlameStartTime >= defaultRobotBunsenBurnerBurnTime {
                turnOffBunsenBurner()
        }
        
        // throw a baked good if player has tapped.  Note: we allow this even when the player
        // has been hit by a high-impact baked good.
        // Note: we wait for any tasks in the queue where the gesture recognizers have updated the
        // data we're going to access.  Using sync makes me nervous as this part of the code will
        // stop player movement until the sync is satisfied.  On the other hand it seems unlikely
        // that this will block because the code run on the queue should be short and quick.
        // IMPORTANT NOTE:  Only allow player controls when _no_ ai robots are ramming.  When one is,
        // it should be game over for the player so controls should not work.  We don't want anything
        // to interfere with the ram.  If the player robot switches direction in the middle of a ram
        // we could see an instance where a ghost of the player appears and the player is not damaged
        // yet the ai robots don't see that it exists anymore.  We don't want that to happen and one
        // way of preventing it is to disable controls once an ai robot has started the ramming process.
        // Also, only accept commands if the level hasn't been completed.  If it has been completed, then
        // the player's robot will still move forward through the exit for a brief time before the segue
        // back to the level select screen so we want no commands to take effect in that brief time because
        // that could result in undesirable behavior.
        if workerRammingPlayer == .notRamming && levelStatus != .levelCompleted {
            gestureHandlingQueue.sync(execute: {
                // tap2DLocationJustTapped, tapCountJustUpdated, newPlayerDirectionJustSwiped, and
                // swipeCountJustUpdated are essentially just pipes between
                // the gesture recognizer and the updatePlayer() function.  We're trying to minimize
                // what happens in the GCD queue to minimize the possibility of a race condition.
                self.tap2DLocation = self.tap2DLocationJustTapped
                self.tapCount = self.tapCountJustUpdated
                self.newPlayerDirection = self.newPlayerDirectionJustSwiped
                self.swipeCount = self.swipeCountJustUpdated
            })
        }

        if self.lastTapCount != self.tapCount {
            self.lastTapCount = self.tapCount
            self.handleTap(twoDLocation: self.tap2DLocation)
        }
        // first, check to see if it can't recovery from impact.
        if playerRobot.impactedState != .notImpactedOrRecovering {
            playerRobot.updateImpactStatus()
        }
        // We keep updating the velocity because over time friction will slow the robot down to zero velocity.
        // But _only_ if the player's robot isn't still affected by an impact and not tipped over to the point of failure.
        if playerRobot.impactedState == .notImpactedOrRecovering {
            if self.lastSwipeCount != self.swipeCount {
                // Even though the player direction is already established, we still use a switch statement
                // here just in the off chance that its zero direction.  It should never be so but that doesn't
                // mean it absolutely won't.
                switch self.newPlayerDirection {
                case west:
                    self.playerRobot.robotStoppedViaStopButton = false
                    self.playerRobot?.updateDirectionAndVelocity(newDirection: west)
                    self.playerRobot?.turnWheelsAtNormalSpeed()
                    self.lastSwipeCount = swipeCount
                    if isTutorialEnabled == true {
                        tutorial.completedGestureStep(type: .swiperight)
                    }
                case east:
                    self.playerRobot.robotStoppedViaStopButton = false
                    self.playerRobot?.updateDirectionAndVelocity(newDirection: east)
                    self.playerRobot?.turnWheelsAtNormalSpeed()
                    self.lastSwipeCount = swipeCount
                    if isTutorialEnabled == true {
                        tutorial.completedGestureStep(type: .swipeleft)
                    }
                case north:
                    self.playerRobot.robotStoppedViaStopButton = false
                    self.playerRobot?.updateDirectionAndVelocity(newDirection: north)
                    self.playerRobot?.turnWheelsAtNormalSpeed()
                    self.lastSwipeCount = swipeCount
                    if isTutorialEnabled == true {
                        tutorial.completedGestureStep(type: .swipeup)
                    }
                case south:
                    self.playerRobot.robotStoppedViaStopButton = false
                    self.playerRobot?.updateDirectionAndVelocity(newDirection: south)
                    self.playerRobot?.turnWheelsAtNormalSpeed()
                    self.lastSwipeCount = swipeCount
                    if isTutorialEnabled == true {
                        tutorial.completedGestureStep(type: .swipedown)
                    }
                default:
                    break
                }
            }
            
            // update only every so often to avoid jerkiness in the player's robot.  However, gestures
            // by the player can override this as they happen first.
            playerUpdateCount += 1
            if playerUpdateCount % numberOfRenderLoopsBetweenPlayerVelocityUpdates == 0 {
                playerRobot.robotNode.physicsBody?.velocity = (playerRobot?.currentVelocity)!
            }
            
            // track the state of the tutorial here
            if isTutorialEnabled == true {
                let tutorialStep = tutorial.getCurrentTutorialStep()
                
                if tutorialStep.stepState == .hasnotstartedyet && controlPanel.isShowTutorialStepInProgress() == false {
                    if tutorialStep.stepType == .gotopart && tutorial.partsTutorialStepsAddedToScene == false {
                        // only add the parts tutorial steps the scene once.  After this we don't need to do it
                        // again.  Also, the states of all gotopart steps are marked as being in progress.  That way
                        // we switch from the 2D control panel to the 3D scene for the rest of the tutorial steps.
                        // we do this by having none of the parts tutorial states in the .hasnotstartedyet state after
                        // this function runs.  That way there is no check for tutorial step in progress in the control
                        // panel.  It's a little kludgy but should work fine.
                        tutorial.addPartsPickupStepsToSceneOnlyOnceAndSetStateToInProgress(sceneView: sceneView, parts: parts)
                    }
                    else if tutorialStep.stepType != .notype {
                        // it's a gesture
                        controlPanel.showTutorialStep(step: tutorialStep, playerX: playerRobot.robotNode.presentation.position.x, exitX: currentLevel.levelExitNode.position.x)
                        tutorial.setCurrentStepState(state: .inprogress)
                    }
                    // else it is no step at all--THIS SHOULD NEVER BE THE CASE.  That pretty much guarantees there will be a case;
                    // I just haven't encountered it yet.
                }
                else if tutorialStep.stepState == .inprogress && tutorialStep.stepType != .gotopart {
                    if tutorialStep.stepType != .notype && controlPanel.isShowTutorialStepInProgress() == false {
                        // Note: we don't set the tutorial step state here, we just keep showing the tutorial
                        // step on screen.  The idea is to keep showing the step until the player performs the
                        // action.  We set the state above because at that point the tutorial step hadn't started yet.
                        // But in this case the step is in progress and so we're waiting for the player to complete
                        // that step by performing the action.  And here we just keep showing the action until that happens.
                        controlPanel.showTutorialStep(step: tutorialStep, playerX: playerRobot.robotNode.presentation.position.x, exitX: currentLevel.levelExitNode.position.x)
                    }
                }
                else if tutorial.haveAllPartsBeenGathered() == false && tutorial.areAllTheGestureStepsDone() == true && controlPanel.isShowTutorialStepInProgress() == false {
                    controlPanel.showCollectPartsTutorialStep()
                }
            }
        }

        // Check to see if player's robot has been impacted by baked good and if so check it's status and recovery
        // efforts.
        if playerRobot.impactedState != .notImpactedOrRecovering {
            playerRobot.updateImpactStatus()
            // Note: we want to check for the full upright position _only_ if the robot is recovering.  If we do this
            // when the robot is in the impacted state then it never reels from impact because this code would immediately set
            // it back to a normal state before the robot has had a chance to feel the effects of the impact.
            if playerRobot.impactedState != .tippedOver && playerRobot.impactedState != .endOverEndFlip {
                // adjust the recovery at certain intervals.  And keep track of the last time it was adjusted so that
                // we know when the next adjustment is needed.
                if currentTime - playerRobot.lastImpactRecoveryTime > defaultImpactRecoveryInterval && playerRobot.impactedState == .recovering {
                    playerRobot.adjustImpactRecovery()
                    playerRobot.lastImpactRecoveryTime = currentTime
                }
                
                let robotTilt = playerRobot.robotNode.presentation.orientation
                // Experimentation with 0.05, 0.1, 0.15 and 0.2 leads us to concluded that 0.1 looks the best.
                if playerRobot.impactedState == .recovering && abs(robotTilt.x) <= 0.1 && abs(robotTilt.z) <= 0.1 {
                    playerRobot.impactedState = .notImpactedOrRecovering         // impact is over, robot no longer affected by it.
                    playerRobot.robotNode.physicsBody!.friction = playerRobot.originalRobotFriction
                    playerRobot.turnOffForceEffects()
                    playerRobot.updateDirectionAndVelocity(newDirection: playerRobot.currentDirection)
                }
            }
            else if playerRobot.impactedState == .tippedOver && playerRobot.isRobotNearlyHorizontal() == true && playerRobot.crashSoundPlaying == false {
                let playCrashSound = SCNAction.playAudio(NodeSound.crash!, waitForCompletion: false)
                playerRobot.robotNode.runAction(playCrashSound)
                playerRobot.crashSoundPlaying = true
            }
        }
        
        // Get the  human player's robot position so that we can update the camera position
        let hRobotPos = (playerRobot?.robotNode.presentation.position)!
        // Always calculate player's robot position in level coordinates to keep it up-to-date.
        // This is used for range detection by the ai robots.
            
        playerRobot.lastLevelCoords = playerRobot.levelCoords  // don't forget to update the player's lastLevelCoords in case the robot has moved.
        playerRobot.levelCoords = calculateLevelRowAndColumn(objectPosition: hRobotPos, maxRow: currentLevel.levelGrid.count - 1, maxCol: currentLevel.levelGrid[0].count - 1)
        
        // This is kludgy but we tried using physicsworld(_:didEnd contact:) and that didn't work so this
        // was an alternative.  The physicsworld(_:didBegin contact:) worked to turn it on but it stays
        // on and the hole is stored as the last contact and it stays that way until the player's robot contacts
        // something else.  This worked fine to get rid of our problem with baked goods but doesn't work
        // well for the hover unit.  Hence, we turn it on and off here instead.
        let components = currentLevel.levelGrid[playerRobot.levelCoords.row][playerRobot.levelCoords.column]
        var playerNotAboveHole: Bool = true
        for aComponent in components {
            if getLevelComponentType2(levelComponentName: aComponent, componentsDictionary: currentLevel.allDurableComponents) == .hole {
                playerNotAboveHole = false
            }
        }
        if playerNotAboveHole == true {
            playerRobot.hoverUnitNode.geometry?.firstMaterial?.diffuse.contents = UIColor.clear
        }
        else {
            // We add a check here to make sure that the hover unit hasn't been selected.  And we check that the robot isn't already
            // disabled before disabling it.  And we check that the player isn't currently using a speedup powerup.  The idea with the
            // speedup powerup is that the robot is going fast enough to cross the hole without falling into it.  Will this be too
            // confusing for the player?  Or does it add another dimension to the game.  It seems to work well if we use a speedup
            // of 3x or better.
            // Otherwise the code will shut down the player's robot with each render cycle and we see
            // a stream of robots heading down into the hole.
            // Note: the player's robot needs to always make it over the hole if using the hover unit.  Always.
            if hoverUnitIsUsedInLevel != true && playerRobot.robotDisabled != true && playerRobot.robotHealth.speedPowerUpApplied != true {
                // show the hole if it was camouflaged before
                for aComponent in components {
                    if getLevelComponentType2(levelComponentName: aComponent, componentsDictionary: currentLevel.allDurableComponents) == .hole {
                        if currentLevel.holes[aComponent]?.camouflaged == true {
                            currentLevel.holes[aComponent]?.uncamouflageHole()
                        }
                    }
                }
                shutdownAndRemoveRobot(robotToShutdown: playerRobot, pointOfImpact: SCNVector3(0.0, 0.0, 0.0), impactVelocity: SCNVector3(0.0, 0.0, 0.0),reasonForShutdown: ReasonForRobotShutdown.fellIntoHole)
            }
            else if hoverUnitIsUsedInLevel != true && playerRobot.robotHealth.speedPowerUpApplied == true && playerRobot.robotDisabled != true {
                // player always makes it to the other side of the hole if speedup used.
                // show the hole if it was camouflaged before
                for aComponent in components {
                    if getLevelComponentType2(levelComponentName: aComponent, componentsDictionary: currentLevel.allDurableComponents) == .hole {
                        if currentLevel.holes[aComponent]?.camouflaged == true {
                            currentLevel.holes[aComponent]?.uncamouflageHole()
                        }
                    }
                }
            }
            else {
                playerRobot.hoverUnitNode.geometry?.firstMaterial?.diffuse.contents = UIColor.cyan
            }
        }
        
        // Note: we have to negate the effect of the x,z offsets so we add them to our calculations
        // in the if statements to perform that negation.  We only move the camera when the player's
        // robot goes beyond an invisible window.  This gives the illusion of the robot moving
        // independent of the camera, yet at the same time still keeping the robot roughly in the
        // center of the screen.
        
        // only update the camera if the player hasn't completed the level yet.  If the player has, then
        // don't update the camera because at that point the player is going through the exit and we don't
        // want the camera to show what's beyond the wall.
        if levelStatus != .levelCompleted {
            if hRobotPos.x - primaryCam.position.x + cameraXOffset <= minMovementWindowX ||  hRobotPos.x - primaryCam.position.x + cameraXOffset >= maxMovementWindowX {
                primaryCam.position.x += hRobotPos.x - lastPlayerRobotPosition.x
                // If after we move the camera it is still outside invisible window, we force an adjustment
                // of the camera's position to be right behind the player's robot.  This can happen if the player's
                // robot hits a 2x speedup and zooms to the left or right too quick for the camera to keep up.
                if hRobotPos.x - primaryCam.position.x + cameraXOffset <= minMovementWindowX ||  hRobotPos.x - primaryCam.position.x + cameraXOffset >= maxMovementWindowX {
                    primaryCam.position.x = hRobotPos.x + cameraXOffset
                }
            }
            
            if hRobotPos.z - primaryCam.position.z + cameraZOffset <= minMovementWindowZ || hRobotPos.z - primaryCam.position.z + cameraZOffset >= maxMovementWindowZ {
                primaryCam.position.z += hRobotPos.z - lastPlayerRobotPosition.z
                // If after we move the camera it is still outside invisible window, we force an adjustment
                // of the camera's position to be right behind the player's robot.  This can happen if the player's
                // robot hits a 2x speedup and zooms forward or back too quick for the camera to keep up.
                if hRobotPos.z - primaryCam.position.z + cameraZOffset <= minMovementWindowZ || hRobotPos.z - primaryCam.position.z + cameraZOffset >= maxMovementWindowZ {
                    primaryCam.position.z = hRobotPos.z + cameraZOffset
                }
            }
        }
        
        if haveLevelCoordsChanged(levelCoords: playerRobot.levelCoords, lastLevelCoords: playerRobot.lastLevelCoords) {
            currentLevel.updateRobotLocationInLevelGrid(robotName: playerRobot.robotNode.name!, levelCoords: playerRobot.levelCoords, lastLevelCoords: playerRobot.lastLevelCoords, robots: aiRobots)
            controlPanel.updatePlayerInMap(playerLoc: playerRobot.levelCoords)
        }
            
        lastPlayerRobotPosition = hRobotPos
            
        let newLevelPos = calculateLevelRowAndColumn(objectPosition: hRobotPos, maxRow: currentLevel.levelGrid.count - 1, maxCol: currentLevel.levelGrid[0].count - 1)
        lastPlayerRobotLevelPos = newLevelPos
            
        // update reload status bars if it's time.
        if currentTime - playerReloadStatusLastCheckTime >= defaultStatusBarUpdateInterval {
            controlPanel.updateReloadingStatusBar(currentTime: currentTime, reloadStartTimes: playerRobot.timeReloadStarted, timeReloadTakes: playerRobot.robotHealth.reloadTime)
            if zapperIsUsedInLevel == true {
                controlPanel.updateZapStatusBar(currentTime: currentTime, zapCount: playerRobot.robotHealth.zapCount, zapReloadStartTime: playerRobot.robotHealth.timeZapperReloadStarted, timeZapReloadTakes: playerRobot.robotHealth.zapReloadTime, zapperFinishedReloading: playerRobot.robotFinishedZapperReloading(currentTime: currentTime))
            }
            if bunsenBurnerIsUsedInLevel == true {
                controlPanel.updateBunsenBurnerStatusBar(currentTime: currentTime, flameCount: playerRobot.robotHealth.flameCount, bunsenBurnerReloadStartTime: playerRobot.robotHealth.timeBunsenBurnerReloadStarted, timeBunsenBurnerReloadTakes: playerRobot.robotHealth.bunsenBurnerReloadTime, bunsenBurnerFinishedReloading: playerRobot.robotFinishedBunsenBurnerReloading(currentTime: currentTime))
            }
            playerReloadStatusLastCheckTime = currentTime
        }
        
        if currentTime - playerRobot.lastPositionUpdateTime >= defaultPlayerRobotPositionUpdateTime {
            playerRobot.lastPositionUpdateTime = currentTime
            playerRobot.lastPositionUpdate = playerRobot.robotNode.presentation.position
        }
        
        if currentTime - playerRobot.lastRecoveryTime >= defaultRobotRecoveryInterval {
            playerRobot.lastRecoveryTime = currentTime
            
            // if robot tipped over or is flipping end over end, then shutdown.  Otherwise, the robot will have recovered
            // in the recovery section in Robot.showImpactAndRecovery().
            if playerRobot.impactedState == .tippedOver {
                shutdownAndRemoveRobot(robotToShutdown: playerRobot, pointOfImpact: SCNVector3(0.0, 0.0, 0.0), impactVelocity: SCNVector3(0.0, 0.0, 0.0), reasonForShutdown: ReasonForRobotShutdown.tippedOver)
            }
            else if playerRobot.impactedState == .endOverEndFlip {
                shutdownAndRemoveRobot(robotToShutdown: playerRobot, pointOfImpact: SCNVector3(0.0, 0.0, 0.0), impactVelocity: SCNVector3(0.0, 0.0, 0.0), reasonForShutdown: ReasonForRobotShutdown.tippedOver)
            }

            // restore health at a constant rate.
            if playerRobot.robotHealth.isDamaged() {
                playerRobot.recoverFromDamage()
            }
        }
        
        // burn through power up.
        if playerRobot.robotHealth.powerUpEnabled == true {
            let powerUpTransparency = CGFloat(playerRobot.robotHealth.getFractionOfPowerUpTimeLeft())
            if playerRobot.attachedPowerUpNode != nil && Int(powerUpTransparency * 10.0) % 3 == 0 {
                playerRobot.attachedPowerUpNode.geometry?.firstMaterial?.transparency = powerUpTransparency
            }
            if playerRobot.robotHealth.countDownPowerUpTime() == .timeLimitExceeded {
                // powerup done was a speedup, return wheels to normal speed.
                if playerRobot.robotHealth.speedPowerUpApplied == true {
                    playerRobot.turnWheelsAtNormalSpeed()
                }
                playerRobot.robotHealth.removePowerUp()
                playerRobot.removePowerUpAsPowerPack() 
            }
        }
        
        // Lastly, don't forget to zap ai robot if player has selected zapper weapon and an ai robot
        // is within range.
        // the zapper has to be within range and cleared to engage (meaning nothing in between it and the player)
    
        if zapperIsUsedInLevel == true && playerRobot.robotFinishedZapperReloading(currentTime: currentTime) && aiRobots.isEmpty == false {
            var distances: [Float: String] = [:]
            
            // calculate distances.  Note: if two or more ai robots have the same distances then the last one is kept.  
            // That's the simplest way to do it.  We could save all of them and then randomly choose one but at this point
            // there's no sense in adding more complexity.
            for (robotName, robot) in aiRobots {
                let distance = calcDistance(p1: playerRobot.robotNode.presentation.position, p2: robot.robotNode.presentation.position)
                distances[distance] = robotName
            }
            
            let sortedDistances = distances.keys.sorted()
            let aiRobotWithShortestDistance = aiRobots[distances[sortedDistances[0]]!]
            if playerRobot.lastRobotZapped.robotName.isEmpty == false || (sortedDistances[0] <= maximumPlayerZapRange && playerRobot.lineOfSightPath(robotLoc: (aiRobotWithShortestDistance?.levelCoords)!, levelGrid: currentLevel.levelGrid, componentsDictionary: currentLevel.allDurableComponents) == pathClear) {
                // zap the player, then remove the zap
                // Note: we call it a "bolt of zap"  It used to be called bolt of lightning but we changed it
                // to be zap because the normal zapper is just a straight beam.  We reserve the lightning for
                // the pastry chef robot
                var boltOfZap: SCNNode!
                var robotBeingZapped: Robot!
                
                if playerRobot.lastRobotZapped.robotName.isEmpty == false {
                    if aiRobots[playerRobot.lastRobotZapped.robotName] != nil {
                        // zap the last robot zapped, if it hasn't been destroyed.
                        boltOfZap = playerRobot.createZapBolt(targetPoint: aiRobots[playerRobot.lastRobotZapped.robotName]!.robotNode.presentation.position)
                        robotBeingZapped = aiRobots[playerRobot.lastRobotZapped.robotName]
                    }
                    else {
                        // otherwise zap where it was, until the zapping is done.  Note: this will (not might, not possibly, but will)
                        // result in nil being assigned to robotBeingZapped because it will no longer exist.
                        boltOfZap = playerRobot.createZapBolt(targetPoint: (playerRobot.lastRobotZapped.robotLoc))
                        robotBeingZapped = aiRobots[playerRobot.lastRobotZapped.robotName]
                    }
                }
                else {
                    boltOfZap = playerRobot.createZapBolt(targetPoint: (aiRobotWithShortestDistance?.robotNode.presentation.position)!)
                    playerRobot.lastRobotZapped.robotName = (aiRobotWithShortestDistance?.robotNode.name)!
                    playerRobot.lastRobotZapped.robotLoc = (aiRobotWithShortestDistance?.robotNode.presentation.position)!
                    robotBeingZapped = aiRobotWithShortestDistance
                }
                
                let turnOnAuraAction = SCNAction.customAction(duration: 0.0, action: { _,_ in
                    self.playerRobot.turnOnAura()
                })
                
                let lingerAction = SCNAction.wait(duration: playerZapLingerTime)
                let removeZap = SCNAction.removeFromParentNode()
                
                //let lingerSequence = SCNAction.sequence([turnOnAuraAction, zapSoundAction, lingerAction, removeZap])
                let lingerSequence = SCNAction.sequence([turnOnAuraAction, lingerAction, removeZap])
                sceneView.scene?.rootNode.addChildNode(boltOfZap)
                // we don't have a zap level component type so we don't both to add such a thing to the allDurableComponents dictionary in the Level class for
                // quick reference.
                
                // play zap sound from robot and show zap at roughly the same time.
                //let zapSoundAction = SCNAction.playAudio(NodeSound.zap!, waitForCompletion: false)
                //playerRobot.robotNode.runAction(zapSoundAction, forKey: zapSoundActionKey)
                boltOfZap.runAction(lingerSequence, completionHandler: {
                    self.playerRobot.turnOffAura()
                    // Danger:  We may be trying to change the state of a robot that has already shut down.  That could
                    // be problematic.
                    if robotBeingZapped != nil {
                        robotBeingZapped.showChangeInStaticDischargeDamage()
                    }
                })
                
                // increment zap count.  If above the maximum zap count number, we institute a reload time.
                // Otherwise, reload time is zero until that zap count is reached.  This gives us a continuous zap effect,
                // which is kind of cool.  And it instantly kills the weaker ai robots but may not take out the tougher ones,
                // which is what we want.  We can't have an all-powerful zapper.
                playerRobot.robotHealth.zapCount += 1
                
                // When the player has zapped a certain number of times we then force a reload.
                // Note: it is important to use >= here, not >, because we use the zapCount also in the control panel to
                // determine the height of the zapper status bar.  If set it to just > there is a point where the status bar
                // stays zero for a while until that one last zap happens to meet this condition because of the way we calculate
                // the fraction that is multiplied by the height of the status bar.
                if playerRobot.robotHealth.zapCount >= maxZapCountForPlayerZapperWeapon {
                    playerRobot.robotHealth.zapCount = 0  // Don't forget to reset the count to zero.  Otherwise, the player won't zap anymore.
                    playerRobot.robotHealth.timeZapperReloadStarted = currentTime     // time reload starts so we know that the player has to wait for reload.
                    // reset the last robot zapped to be nothing.  That way when the zap is over the player's robot won't keep continuing to zap when it shouldn't.
                    playerRobot.lastRobotZapped.robotName = ""
                    playerRobot.lastRobotZapped.robotLoc = SCNVector3Zero
                }
                else {      // otherwise, the player can continue to zap away.
                    playerRobot.robotHealth.timeZapperReloadStarted = 0.0
                }
                
                // Immediately stop ai robot being zapped but don't affect the player's robot.  Also, only try to stop this robot if is still exists; if we're
                // still zapping in the place where it was even though it no longer exists, then don't do anything here.
                if robotBeingZapped != nil {
                    robotBeingZapped.currentVelocity = notMoving
                    robotBeingZapped.currentDirection = zeroDirection
                    robotBeingZapped.robotNode.physicsBody!.velocity = robotBeingZapped.currentVelocity
                    robotBeingZapped.robotHealth.hitWithStaticDischarge(staticDischarge: fullStaticDischargeResistance * 0.07)   // hurt the ai robot, but only a little.
                    // Note: we use FullStaticDischargeResistance here, not the ai robot's startingStaticDischarge resistance.  This is in the event that robots like the pastry chef, or
                    // any of the super* robots, are hit by the zap.  They would be less affected than normal robots.  If we used startingStaticDischarge, the effect would be the same for
                    // all robots, it would just be larger for the super* and pastry chef robots, which also have proportionally larger resistances.
                    if robotBeingZapped.robotHealth.staticHealth() <= healthPrettyMuchGone {
                        shutdownAndRemoveRobot(robotToShutdown: robotBeingZapped, pointOfImpact: SCNVector3(0.0, 0.0, 0.0), impactVelocity: SCNVector3(0.0, 0.0, 0.0), reasonForShutdown: ReasonForRobotShutdown.hitByStaticDischarge)
                        
                    }
                }
            }
        }        
    }
    
    // handleTap() - throw a baked good when the player has tapped, or stop robot or go back to level select,
    // depending on where the player tapped.  We put all the mechanics of doing those things here instead of
    // in the tap gesture recognizer because when we do a lot of work in that gesture recognizer the game crashes
    // because we're seeing a race condition of some sort.  The gesture recognizer runs in the main thread but the
    // rest of the game runs in the renderer loop which runs in a different thread.  So we actually will call this
    // function in the renderer loop to keep things in sync.
    func handleTap(twoDLocation: CGPoint) {
        var result: SCNHitTestResult!
        
        let whichButtonSelected = controlPanel.buttonSelected(location: twoDLocation)
        // Note: we get the current time as we use is in several places to tell if a launcher is ready.  Even
        // though we do it early in the function it should still work; this function should not take that long
        // to complete.  If it does we would have serious performance problems.
        let currentTime = NSDate().timeIntervalSince1970
        
        if whichButtonSelected == .selectLevelSelected {
            levelStatus = .levelNotCompleted
            controlPanel.showSelectLevelButtonTapped()
            controlPanel.fadeOutScene(duration: 0.1)  // fade out very quickly to hide any artifacts from particle systems.
            gameSounds.playSound(soundToPlay: .buttontap)
            // wait 1/2 second before going back.
            if timeBackToLevelSelectInitiated <= 0.001 {
                timeBackToLevelSelectInitiated = NSDate().timeIntervalSince1970
            }
        }
        else if whichButtonSelected == .stopRobotSelected {
            // stop robot button has been tapped so we stop the robot
            playerRobot.robotStoppedViaStopButton = true
            playerRobot.currentVelocity = notMoving
            playerRobot?.robotNode.physicsBody!.velocity = playerRobot.currentVelocity
            playerRobot?.stopTurningWheels()
            controlPanel.highlightNonItemButton(whichButtonSelected)
            gameSounds.playSound(soundToPlay: .buttontap)
            if isTutorialEnabled == true {
                tutorial.completedGestureStep(type: .tapstop)
            }
        }
        else {
            
            if isTutorialEnabled == true {
                let tutorialStep = tutorial.getCurrentTutorialStep()
                let launcherThatIsReadyToFire = playerRobot.whichLauncherHasFinishedReloading(currentTime: currentTime)
                // tap on target tutorial steps has changed to just be a single tap anywhere on the screen to keep it
                // simple -- nlb, 2018-09-08
                if tutorialStep.stepType == .taptarget1 && launcherThatIsReadyToFire != noLauncherReadyToFire {
                    tutorial.completedGestureStep(type: .taptarget1)
                }
            }
            // default to checking for a tap indicating that the player is throwing something.
            // Note: the steam cloud is set to a certain categoryBitMask.  Then we set the floor to a totally
            // different categoryBitMask and then only perform a hitTest with the floor's categoryBitMask so that
            // we get the tap on the floor as the target point.  This works pretty much for all cases even though
            // technically it is far from ideal (ideally, all non-steam-cloud nodes should be set to
            // the CategoryRegisterInHitTest categoryBitMask but we see that that really isn't necessary).
            //let hitResults = sceneView.hitTest(twoDLocation, options: [SCNHitTestOption.clipToZRange: true, SCNHitTestOption.categoryBitMask: 0])
            let hitResults = sceneView.hitTest(twoDLocation, options: [SCNHitTestOption.clipToZRange: true, SCNHitTestOption.categoryBitMask: categoryRegisterInHitTest])
            
            if hitResults.isEmpty == false && ammoIsUsedInLevel == true {
                
                result = hitResults[0]   // the first thing hit.
                
                let tap3DLocation = result.worldCoordinates
                let distanceBetweenTapAndPlayerRobot = calcDistance(p1: tap3DLocation, p2: playerRobot.robotNode.presentation.position)
                
                //let currentTime = NSDate().timeIntervalSince1970
                let launcherThatIsReadyToFire = playerRobot.whichLauncherHasFinishedReloading(currentTime: currentTime)

                // highlight the tap here works but it also highlights the tap when the player's robot
                // hasn't finished reloading yet.  Is that what we want?  Or do we want to only highlight the
                // tap when the player's robot can throw again?
                if distanceBetweenTapAndPlayerRobot >= minimumPlayerThrowDistance {
                    if launcherThatIsReadyToFire == noLauncherReadyToFire {
                        controlPanel.highlightLocationTapped(twoDLocation: twoDLocation, colorToUse: UIColor.yellow)
                    }
                    else {
                        controlPanel.highlightLocationTapped(twoDLocation: twoDLocation, colorToUse: UIColor.green)
                    }
                }
                else {
                    controlPanel.highlightLocationTapped(twoDLocation: twoDLocation, colorToUse: UIColor.gray)
                }
                
                if launcherThatIsReadyToFire != noLauncherReadyToFire && distanceBetweenTapAndPlayerRobot >= minimumPlayerThrowDistance {
                    // hurl baked good or emp grenade.  And give it a unique name we can use to identify it later, when it makes impact.
                    // We pass NotMoving as the target velocity for the ai robot that the player's throwing just to conform
                    // to the parameter list.  For the player we also depend on the targetPoint.                    
                    if selectedAmmo.range(of: empGrenadeLabel) != nil {
                        // delay launch of emp grenade until _after_ the launcher has turned, which takes 0.5 seconds
                        let newRotationOfLauncher: SCNVector4 = playerRobot.getRotationForLauncherToPointTowardTarget(targetPoint: tap3DLocation)
                        // Note: we have to give the custom action a duration; we can't just assume the transaction duration
                        // will keep the action going until it's over because the two are separate.  The customAction duration
                        // makes the action wait for that duration, which is enough time for the transaction to complete and give
                        // us the turn animation we want.
                        let rotateSoundAction = SCNAction.playAudio(NodeSound.launcherturn!, waitForCompletion: false)
                        let rotateAction = SCNAction.customAction(duration: playerLauncherRotationDuration, action: { _,_ in
                            SCNTransaction.begin()
                            SCNTransaction.animationDuration = playerLauncherRotationDuration
                            self.playerRobot.launcherNode.rotation = newRotationOfLauncher
                            SCNTransaction.commit()
                        })
                        let rotateSequence = SCNAction.sequence([rotateSoundAction, rotateAction])
                        playerRobot.launcherNode.runAction(rotateSequence, completionHandler: {
                            let anEMPGrenade = self.playerRobot?.hurlEMPGrenade(targetPoint: tap3DLocation, name: empGrenadeLabel + String(self.empGrenadeCount), whoThrewIt: self.playerRobot.robotNode.name!)
                            self.empGrenades[empGrenadeLabel + String(self.empGrenadeCount)] = anEMPGrenade
                            self.empGrenadeCount += 1  // keep incrementing this count to provide more unique identifiers.
                            let puffOfSteamSoundAction = SCNAction.playAudio(NodeSound.puffOfSteam!, waitForCompletion: false)
                            let puffOfSteam = self.playerRobot?.generatePuffOfSteam(launchPoint: anEMPGrenade!.empGrenadeNode.position)
                            let fadeAction = SCNAction.fadeOut(duration: 0.5)
                            let removeAction = SCNAction.removeFromParentNode()
                            let fadeSequence = SCNAction.sequence([puffOfSteamSoundAction, fadeAction, removeAction])
                            self.sceneView.scene?.rootNode.addChildNode(puffOfSteam!)
                            self.sceneView.scene?.rootNode.addChildNode((anEMPGrenade?.empGrenadeNode)!)
                            puffOfSteam!.runAction(fadeSequence)
                            // Normally we would add anything that was added to the scene to the allDurableComponents list in the Level instance
                            // but we don't even have a level component type for the empgrenade so we don't bother.  We we need it we'll
                            // create an empgrenade level component type but we have to be sure to assign it here.
                            
                            // Note: we detonate right after hurling the emp grenade because it takes time to charge and then fire.  That time
                            // it takes charging is the time, roughly, that it's in flight.
                            self.runDelayTimerAndDetonateEMPGrenade(empGrenade: anEMPGrenade!)

                        })
                        
                    }
                    else {
                        // delay launch of baked good until _after_ the launcher has turned, which takes 0.5 seconds
                        let newRotationOfLauncher: SCNVector4 = playerRobot.getRotationForLauncherToPointTowardTarget(targetPoint: tap3DLocation)
                        // Note: we have to give the custom action a duration; we can't just assume the transaction duration
                        // will keep the action going until it's over because the two are separate.  The customAction duration
                        // makes the action wait for that duration, which is enough time for the transaction to complete and give
                        // us the turn animation we want.
                        let rotateSoundAction = SCNAction.playAudio(NodeSound.launcherturn!, waitForCompletion: false)
                        let rotateAction = SCNAction.customAction(duration: playerLauncherRotationDuration, action: { _,_ in
                            SCNTransaction.begin()
                            SCNTransaction.animationDuration = playerLauncherRotationDuration
                            self.playerRobot.launcherNode.rotation = newRotationOfLauncher
                            SCNTransaction.commit()
                        })
                        let rotateSequence = SCNAction.sequence([rotateSoundAction, rotateAction])
                        playerRobot.launcherNode.runAction(rotateSequence, completionHandler: {
                            let aBakedGood = self.playerRobot?.hurlBakedGood(targetPoint: tap3DLocation, targetLastPoint: SCNVector3Zero, targetVelocity: notMoving, name: bakedGoodLabel + String(self.bakedGoodsCount), numThrowsThatShouldMiss: 0, randomGen: self.randomNumGenerator, levelNum: self.levelNum)
                            self.bakedGoods[bakedGoodLabel + String(self.bakedGoodsCount)] = aBakedGood
                            self.bakedGoodsCount += 1  // keep incrementing this count to provide more unique identifiers.
                            let puffOfSteamSoundAction = SCNAction.playAudio(NodeSound.puffOfSteam!, waitForCompletion: false)
                            let puffOfSteam = self.playerRobot?.generatePuffOfSteam(launchPoint: aBakedGood!.bakedGoodNode.position)
                            let fadeAction = SCNAction.fadeOut(duration: 0.5)
                            let removeAction = SCNAction.removeFromParentNode()
                            let fadeSequence = SCNAction.sequence([puffOfSteamSoundAction, fadeAction, removeAction])
                            self.sceneView.scene?.rootNode.addChildNode(puffOfSteam!)
                            self.sceneView.scene?.rootNode.addChildNode((aBakedGood?.bakedGoodNode)!)
                            puffOfSteam!.runAction(fadeSequence)
                        })
                    }
                    playerRobot.timeReloadStarted[launcherThatIsReadyToFire] = currentTime  // start reload immediately
                }
            }
            // We know that a tap was done and a button not selected so we play a generic target tap sound to
            // give the player feedback.  Notes: we adjust the volume here because for some reason we're
            // having trouble adjusting it in GarageBand where the sound originated.  Also, we play the sound
            // as an action on the node rather than playing in the level in general because doing that causes
            // odd streaks to appear on the screen.
            // Note: we play the sound at the end of the tap instead of at the beginning to maybe cut down on the
            // appearance of streaks that seem to happen when the player taps.
            let targetTapSound = NodeSound.targetTap!
            //targetTapSound.volume = 0.2
            targetTapSound.volume = 4.0
            let briefWait = SCNAction.wait(duration: 0.05)
            
            let targetTapSoundAction = SCNAction.playAudio(targetTapSound, waitForCompletion: false)
            let targetTapSoundSequence = SCNAction.sequence([briefWait, targetTapSoundAction])
            // play targettap sound but with a brief wait to wait for the above code to run to get the drawing of
            // the targeting circle started.  We do this in the hopes of preventing yellow or green streaks from appearing
            // in the game, which happens sometimes when the player taps.  It seems to be very much related to the tap
            // gesture and the sound.  We never saw this behavior before we started using sound.
            playerRobot?.robotNode.runAction(targetTapSoundSequence)
        }

    }
    
    // update movement and also residue status of ai robots.  Also test to see if they're in homing range or throwing range, or
    // zapping range or emp range, depending on the type of robot.
    func updateAIRobots() {
        let numberOfAIRobotsToUpdatePerRendererLoop = 5      // this only applies to this function so we declare it here rather than globally.
        let robotNames = Array(aiRobots.keys)
        let currentTime = NSDate().timeIntervalSince1970    // Note: we get the current time here and use it through this function.  There could
                                                            // be some delay but it should be within the time of one renderer loop, which should
                                                            // be at least 1/30th of a second.  That should be close enough for our purposes.  We need
                                                            // at worst 1/10th of a second.
        
        // first check _all_ ai robots to see if they have been tipped over or are doing end-over-end flipping because
        // of impact from a baked good.  But don't do anything here other that was is done internally in updateImpactStatus()
        // The impactedState will be affected and that is what we'll use later to determine whether or not to shut down the robot.
        for aRobot in robotNames {
            let robot = aiRobots[aRobot]!
            if robot.impactedState != .notImpactedOrRecovering {
                robot.updateImpactStatus()
                // Note: we want to check for the full upright position _only_ if the robot is recovering.  If we do this
                // when the robot is in the impacted state then it never reels from impact because this code would immediately set
                // it back to a normal state before the robot has had a chance to feel the effects of the impact.
                if robot.impactedState != .tippedOver && robot.impactedState != .endOverEndFlip {
                    // adjust the recovery at certain intervals.  And keep track of the last time it was adjusted so that
                    // we know when the next adjustment is needed.
                    
                    if currentTime - robot.lastImpactRecoveryTime > defaultImpactRecoveryInterval && robot.impactedState == .recovering {
                        robot.adjustImpactRecovery()
                        robot.lastImpactRecoveryTime = currentTime
                    }
                    
                    let robotTilt = robot.robotNode.presentation.orientation
                    // Experimentation with 0.05, 0.1, 0.15 and 0.2 leads us to concluded that 0.1 looks the best.
                    if robot.impactedState == .recovering && abs(robotTilt.x) <= 0.1 && abs(robotTilt.z) <= 0.1 {
                        //robot.robotNode.removeAllActions()              // We're setting things back to normal so remove any impact+recovery actions
                        robot.impactedState = .notImpactedOrRecovering         // impact is over, robot no longer affected by it.
                        robot.robotNode.physicsBody!.friction = robot.originalRobotFriction
                        robot.turnOffForceEffects()
                        robot.updateDirectionAndVelocity(newDirection: robot.currentDirection)
                    }
                }
                else if robot.impactedState == .tippedOver && robot.isRobotNearlyHorizontal() == true && robot.crashSoundPlaying == false {
                    let playCrashSound = SCNAction.playAudio(NodeSound.crash!, waitForCompletion: false)
                    robot.robotNode.runAction(playCrashSound)
                    robot.crashSoundPlaying = true
                }
            }
            // We check the zappers and pastry chefs every cycle because the zappers zap in very small increments and if we don't
            // do it here it doesn't look right because the gap is huge between zaps.  It looks more like a flicker and then a long
            // wait for the next flicker instead of a continuous zap.  So we do the check for all zappers and pastry chefs at _every_
            // call to updateAIRobot().  That way the zap looks more like the zap that the player robot displays, which looks more like
            // a zap should look.  This could impact performance.
            // the zapper has to be within range and cleared to engage (meaning nothing in between it and the player)
            if robot.robotType == .zapper && robot.robotFinishedZapperReloading(currentTime: currentTime) {
                
                // only turn on zapping against the player robot if the a) the player robot isn't already being zapped, b) the distance between
                // the ai robot and the player is within range and c) there's nothing in between the two.
                if robot.lastRobotZapped.robotName.isEmpty == true && calcDistance(p1: robot.robotNode.presentation.position, p2: playerRobot.robotNode.presentation.position) <= maximumAIZapRange && robot.lineOfSightPath(robotLoc: playerRobot.levelCoords, levelGrid: currentLevel.levelGrid, componentsDictionary: currentLevel.allDurableComponents) == pathClear {
                    robot.lastRobotZapped.robotName = playerRobotLabel
                    robot.lastRobotZapped.robotLoc = playerRobot.robotNode.presentation.position
                }
                
                // zapping is turned on when the lastRobotZapped is assigned something.  Then the ai robot zaps away until
                // the zap count has been reached and it starts reloading.
                if robot.lastRobotZapped.robotName.isEmpty == false {
                    // zap the player, then remove the bolt of zap
                    // Note: we call it a "bolt of zap"  It used to be called bolt of lightning but we changed it
                    // to be zap because the normal zapper is just a straight beam.  We reserve the lightning for
                    // the pastry chef robot
                    
                    // IMPORTANT NOTE: in the shutdownAndRemoveRobot() function we don't remove the player robot
                    // but just make it invisible and put in a dummy to show the shutdown.  So here we don't have
                    // keep saving the player's location and then zapping that location when it's gone because it
                    // never is gone.  The ai robots are removed when they have been zapped so the player does
                    // have to keep track of the ai robot's position in case it keeps zapping that position after
                    // the robot has been removed.  That is not a problem here.
                    let boltOfZap = robot.createZapBolt(targetPoint: playerRobot.robotNode.presentation.position)
                    
                    let turnOnAuraAction = SCNAction.customAction(duration: 0.0, action: { _,_ in
                        robot.turnOnAura()
                    })
                    let lingerAction = SCNAction.wait(duration: defaultZapLingerTime)
                    let removeZap = SCNAction.removeFromParentNode()
                    let lingerSequence = SCNAction.sequence([turnOnAuraAction, lingerAction, removeZap])
                    sceneView.scene?.rootNode.addChildNode(boltOfZap)
                    
                    // play zap sound and show zap at roughly the same time.
                    //let zapSoundAction = SCNAction.playAudio(NodeSound.zap!, waitForCompletion: false)
                    //robot.robotNode.runAction(zapSoundAction, forKey: zapSoundActionKey)
                    boltOfZap.runAction(lingerSequence, completionHandler: {
                        robot.turnOffAura()
                        // Danger:  We may be trying to change the state of a robot that has already shut down.  That could
                        // be problematic.
                        self.playerRobot.showChangeInStaticDischargeDamage()
                    })
                    
                    // increment zap count.  If above the maximum zap count number, we institute a reload time.
                    // Otherwise, reload time is zero until that zap count is reached.  This gives us a continuous zap effect,
                    // which is kind of cool.
                    robot.robotHealth.zapCount += 1
                    
                    // When the ai robot has zapped a certain number of times we then force a reload.
                    if robot.robotHealth.zapCount >= maxZapCountForAIZapperWeapon {
                        robot.robotHealth.zapCount = 0  // Don't forget to reset the count to zero.  Otherwise, the robot won't zap anymore.
                        robot.robotHealth.timeZapperReloadStarted = currentTime     // time reload starts so we know that the robot has to wait for reload.
                        robot.lastRobotZapped.robotName = ""                        // reset last robot zapped to nothing to signify that we're not zapping the player now.
                        robot.lastRobotZapped.robotLoc = SCNVector3Zero
                    }
                    else {      // otherwise, the ai robot can continue to zap away.
                        robot.robotHealth.timeZapperReloadStarted = 0.0
                    }
                    
                    // Immediately the zapper that shot the zap bolt.  The player keeps on going.
                    // the zapper stops because its power has been
                    // drained and it needs to recover.
                    robot.currentVelocity = notMoving
                    robot.currentDirection = zeroDirection
                    robot.robotNode.physicsBody!.velocity = robot.currentVelocity
                    playerRobot?.robotHealth.hitWithStaticDischarge(staticDischarge: fullStaticDischargeResistance * 0.07)   // hurt the player's robot, but only a little per zap since the player will be zapped multiple times.
                    if (playerRobot?.robotHealth.staticHealth())! <= healthPrettyMuchGone {
                        shutdownAndRemoveRobot(robotToShutdown: playerRobot, pointOfImpact: SCNVector3(0.0, 0.0, 0.0), impactVelocity: SCNVector3(0.0, 0.0, 0.0), reasonForShutdown: ReasonForRobotShutdown.hitByStaticDischarge)
                        
                    }
                }
            }
            
            // the pastry chef has to be within range and cleared to engage (meaning nothing in between it and the player)
            if robot.robotType == .pastrychef && robot.robotFinishedZapperReloading(currentTime: currentTime) {
                
                if robot.lastRobotZapped.robotName.isEmpty == true && calcDistance(p1: robot.robotNode.presentation.position, p2: playerRobot.robotNode.presentation.position) <= maximumAIPastryChefZapRange && robot.lineOfSightPath(robotLoc: playerRobot.levelCoords, levelGrid: currentLevel.levelGrid, componentsDictionary: currentLevel.allDurableComponents) == pathClear {
                    robot.lastRobotZapped.robotName = playerRobotLabel
                    robot.lastRobotZapped.robotLoc = playerRobot.robotNode.presentation.position
                }
                
                // zapping is turned on when the lastRobotZapped is assigned something.  Then the ai robot zaps away until
                // the zap count has been reached and it starts reloading.
                if robot.lastRobotZapped.robotName.isEmpty == false {
                    // Zap player with bolt of lightning.  Actually, right now it is just a big red beam but we hope
                    // to make it lightning at some point so we leave the lightning in the variable/constant names.
                    // But we'll probably only make it lightning if we have spare time to do so, and that doesn't seem likely.
                    
                    // IMPORTANT NOTE: in the ShutdownAndRemoveRobot() function we don't remove the player robot
                    // but just make it invisible and put in a dummy to show the shutdown.  So here we don't have
                    // keep saving the player's location and then zapping that location when it's gone because it
                    // never is gone.  The ai robots are removed when they have been zapped so the player does
                    // have to keep track of the ai robot's position in case it keeps zapping that position after
                    // the robot has been removed.  That is not a problem here.
                    let boltOfLightning = robot.createZapBolt(targetPoint: playerRobot.robotNode.presentation.position)
                    let turnOnAuraAction = SCNAction.customAction(duration: 0.0, action: { _,_ in
                        robot.turnOnAura()
                    })
                    let lingerAction = SCNAction.wait(duration: lightningLingerTime)
                    let removeZap = SCNAction.removeFromParentNode()
                    let lingerSequence = SCNAction.sequence([turnOnAuraAction,lingerAction, removeZap])
                    sceneView.scene?.rootNode.addChildNode(boltOfLightning)
                    
                    // play zap sound and show zap at roughly the same time.
                    //let zapSoundAction = SCNAction.playAudio(NodeSound.bigZap!, waitForCompletion: false)
                    //robot.robotNode.runAction(zapSoundAction, forKey: zapSoundActionKey)
                    boltOfLightning.runAction(lingerSequence, completionHandler: {
                        robot.turnOffAura()
                        // Danger:  We may be trying to change the state of a robot that has already shut down.  That could
                        // be problematic.
                        self.playerRobot.showChangeInStaticDischargeDamage()
                    })
                    
                    // increment zap count.  If above the maximum zap count number, we institute a reload time.
                    // Otherwise, reload time is zero until that zap count is reached.  This gives us a continuous zap effect,
                    // which is kind of cool.
                    robot.robotHealth.zapCount += 1
                    
                    // When the ai robot has zapped a certain number of times we then force a reload.
                    if robot.robotHealth.zapCount >= maxZapCountForPastryChefZapperWeapon {
                        robot.robotHealth.zapCount = 0  // Don't forget to reset the count to zero.  Otherwise, the robot won't zap anymore.
                        robot.robotHealth.timeZapperReloadStarted = currentTime     // time reload starts so we know that the robot has to wait for reload.
                        robot.lastRobotZapped.robotName = ""                        // reset last robot zapped to nothing to signify that we're not zapping the player now - with
                                                                                    // the pastry chef this is unlikely as its zap is far more lethal than the regular zapper's zap.
                        robot.lastRobotZapped.robotLoc = SCNVector3Zero
                    }
                    else {      // otherwise, the ai robot can continue to zap away.
                        robot.robotHealth.timeZapperReloadStarted = 0.0
                    }
                    
                    // Immediately stop the pastry chef that shot the zap bolt.  The pastry chef stops because its power has been
                    // drained and it needs to recover.
                    robot.currentVelocity = notMoving
                    robot.robotNode.physicsBody!.velocity = robot.currentVelocity
                    playerRobot?.robotHealth.hitWithStaticDischarge(staticDischarge: fullStaticDischargeResistance * 0.2)   // hurt the player's robot, a LOT.  Note: we use FullStaticDischargeResistance
                    if (playerRobot?.robotHealth.staticHealth())! <= healthPrettyMuchGone {
                        shutdownAndRemoveRobot(robotToShutdown: playerRobot, pointOfImpact: SCNVector3(0.0, 0.0, 0.0), impactVelocity: SCNVector3(0.0, 0.0, 0.0), reasonForShutdown: ReasonForRobotShutdown.hitByStaticDischarge)
                        
                    }
                }
            }
        }
        
        let allWorkingRobots = Set(robotNames)
        var robotsToUpdate: Set<String> =  allWorkingRobots.subtracting(workingRobotsAlreadyUpdated)
        
        if robotsToUpdate.isEmpty == true {
            workingRobotsAlreadyUpdated = []
            robotsToUpdate = allWorkingRobots
        }
        
        let arrayOfAllRobotsToUpdate = Array(robotsToUpdate)
        var arrayOfRobotsToUpdate: Array<String> = []
        if arrayOfAllRobotsToUpdate.count > numberOfAIRobotsToUpdatePerRendererLoop {
            arrayOfRobotsToUpdate = Array(arrayOfAllRobotsToUpdate[0...numberOfAIRobotsToUpdatePerRendererLoop - 1])
        }
        else {
            arrayOfRobotsToUpdate = arrayOfAllRobotsToUpdate
        }
        
        if arrayOfRobotsToUpdate.isEmpty == false {
            for botToUpdateName in arrayOfRobotsToUpdate {
                let aRobot = aiRobots[botToUpdateName]!
                
                // start turning the wheels if they haven't started turning.  This should happen right after
                // the intro to the level sound is done but not before then.
                if aRobot.haveWheelsStartedTurning == false {
                    aRobot.turnWheelsAtNormalSpeed()
                    aRobot.haveWheelsStartedTurning = true
                }
                
                if currentTime - aRobot.lastRecoveryTime >= defaultRobotRecoveryInterval {
                    aRobot.lastRecoveryTime = currentTime
                    
                    // if robot tipped over or is flipping end over end, then shutdown.  Otherwise, the robot will have recovered
                    // in the recovery section in Robot.showImpactAndRecovery().
                    if aRobot.impactedState == .tippedOver {
                        shutdownAndRemoveRobot(robotToShutdown: aRobot, pointOfImpact: SCNVector3(0.0, 0.0, 0.0), impactVelocity: SCNVector3(0.0, 0.0, 0.0), reasonForShutdown: ReasonForRobotShutdown.tippedOver)
                    }
                    else if aRobot.impactedState == .endOverEndFlip {
                        shutdownAndRemoveRobot(robotToShutdown: aRobot, pointOfImpact: SCNVector3(0.0, 0.0, 0.0), impactVelocity: SCNVector3(0.0, 0.0, 0.0), reasonForShutdown: ReasonForRobotShutdown.tippedOver)
                    }
                    
                    // restore health at a constant rate
                    if aRobot.robotHealth.isDamaged() {
                        aRobot.recoverFromDamage()
                    }
                    
                }
                
                // Turn off robot wheels if player robot is destroy--the game is in the process of going back to the level select screen
                // anyway.  And it looks odd to see the robots not moving yet the wheels still turning.
                if playerRobot.robotDisabled == true {
                    aRobot.leftWheelNode.removeAction(forKey: leftWheelTurnActionKey)
                    aRobot.rightWheelNode.removeAction(forKey: rightWheelTurnActionKey)
                }
                
                //for (robotName,aRobot) in aiRobots {
                // Only move the ai robots around and attack the player if the player hasn't been disabled.  We do this here rather than
                // doing it at the beginning of the for loop because an ai robot could attack the player while all the robots are updating.
                // If that happens and the player's robot is disabled then we want all the ai robots to immediately be aware of it.
                // This will only make all the remaining ai robots in this cycle aware of it.  But it will make the rest of them aware of
                // it the next cycle.  It seems to work.
                // Check whether or not robot has been shut down.  This flag corresponds to the flag that would be set
                // above if aRobot has been tipped too far over to recover.  If it has, then the rest of the code below
                // should be skipped for aRobot, but not necessarily for other aRobots that will be updated in this run of
                // updateAIRobot().  Also note that we don't do this for the player's robot.  That's because
                // the player's robot will go through a segue on shutdown that pretty much ends game play in
                // the level.  It's a little sloppy but should be ok.
                if !playerRobot.robotDisabled  && !aRobot.robotDisabled {
                    // Move the label above ai robot if there is any to keep the name above it, for debugging purposes.
                    // This is how we would tell which robot is which; otherwise we don't know which robot is doing what
                    // when we're debugging.
                    /*
                    if aRobot.robotLabelNode != nil {
                        aRobot.robotLabelNode.position = aRobot.robotNode.presentation.position
                        // put the label 2 meters above the top of the robot node's bounding box.  That way we can see it.
                        aRobot.robotLabelNode.position.y = aRobot.robotNode.boundingBox.max.y + 2.0
                    }
                    */
                    // Always update the ai robot's level coordinates because that's used for range
                    // detection to detect when the player's robot is within throwing range.  It is also
                    // used by the ai robots to detect imminent collisions with other ai robots or fixed
                    // level components and avoid them.  Player robots are not avoided since the ai robots
                    // are trying to hit it.
                    aRobot.lastLevelCoords = aRobot.levelCoords  // don't forget to update the lastLevelCoords in case the robot has moved.
                    aRobot.levelCoords = calculateLevelRowAndColumn(objectPosition: aRobot.robotNode.presentation.position, maxRow: currentLevel.levelGrid.count - 1, maxCol: currentLevel.levelGrid[0].count - 1)
                    if haveLevelCoordsChanged(levelCoords: aRobot.levelCoords, lastLevelCoords: aRobot.lastLevelCoords) {
                        currentLevel.updateRobotLocationInLevelGrid(robotName: aRobot.robotNode.name!, levelCoords: aRobot.levelCoords, lastLevelCoords: aRobot.lastLevelCoords, robots: aiRobots)
                        if motionDetectorIsUsedInLevel == true {
                            controlPanel.updateAIRobotsInMap(aiRobots: aiRobots, motionDetectorUsed: motionDetectorIsUsedInLevel)
                        }
                    }
                    // This is kludgy but we tried using physicsworld(_:didEnd contact:) and that didn't work so this
                    // was an alternative.  The physicsworld(_:didBegin contact:) worked to turn it on but it stays
                    // on and the hole is stored as the last contact and it stays that way until the player's robot contacts
                    // something else.  This worked fine to get rid of our problem with baked goods but doesn't work
                    // well for the hover unit.  Hence, we turn it on and off here instead.
                    let components = currentLevel.levelGrid[aRobot.levelCoords.row][aRobot.levelCoords.column]
                    var aiRobotNotAboveHole: Bool = true
                    for aComponent in components {
                        if getLevelComponentType2(levelComponentName: aComponent, componentsDictionary: currentLevel.allDurableComponents) == .hole {
                            aiRobotNotAboveHole = false
                        }
                    }
                    
                    if aiRobotNotAboveHole == true {
                        aRobot.hoverUnitNode.geometry?.firstMaterial?.diffuse.contents = UIColor.clear
                    }
                    else {
                        aRobot.hoverUnitNode.geometry?.firstMaterial?.diffuse.contents = UIColor.cyan
                    }
                    
                    if aRobot.isPlayerWithinReach(playerLoc: playerRobot.robotNode.presentation.position) {
                        if (aRobot.robotType == .worker || aRobot.robotType == .superworker) && aRobot.directionForRamming(robotLoc: (playerRobot?.levelCoords)!, robotSceneLoc: playerRobot.robotNode.presentation.position, levelGrid: currentLevel.levelGrid, fixedLevelComponents: currentLevel.levelComponentsList, componentsDictionary: currentLevel.allDurableComponents) != zeroDirection && aRobot.isTurningToFacePlayer == false && aRobot.robotFinishedReloading(currentTime: currentTime) == true && workerRammingPlayer == .notRamming {
                            aRobot.isTurningToFacePlayer  = true
                            // note: when robot turns and charges it is so close that there's no way it won't hit the player.
                            turnAIRobotAndRamPlayer(playerLoc: playerRobot.robotNode.presentation.position, playerVelocity: playerRobot.robotNode.physicsBody!.velocity, aiRobot: aRobot)
                            // immediately stop robot.  Must do this _after_ we start ai robot turning
                            // towards the player because we use the ai robot's current velocity in the angle calculation.  If we set it
                            // to NotMoving before we use it, that screws up the calculation because the velocity goes from whatever it was
                            // to zero.  This results in a division by zero error, which swift is kind enough to give us a 'nan' result instead
                            // of crashing.  We stop the robot to prevent it from continuing to move in the current velocity, which could make
                            // it look wrong if the robot is facing a different direction than it is moving.
                            aRobot.currentVelocity = notMoving
                            aRobot.timeReloadStarted[0] = currentTime  // start reload -- essentially the worker is exhausted and needs to recharge briefly
                            // Note: the current time includes some time that has passed while the ai robot rammed the player but
                            // that should be small compared to the default reload time so it should look ok, even if it isn't
                            // technically correct.
                        }
                        else if aRobot.robotType == .homing && aRobot.isRobotStopped == false && aRobot.lineOfSightPath(robotLoc: (playerRobot?.levelCoords)!, levelGrid: currentLevel.levelGrid, componentsDictionary: currentLevel.allDurableComponents) & pathIsTotallyObscured == 0 {
                            chargeAndFireTheEMP(robotChargingEMP: aRobot)
                        }
                        else if aRobot.robotType == .ghost && aRobot.isRobotStopped == false && aRobot.lineOfSightPath(robotLoc: (playerRobot?.levelCoords)!, levelGrid: currentLevel.levelGrid, componentsDictionary: currentLevel.allDurableComponents) & pathIsTotallyObscured == 0 {
                            chargeAndFireTheEMP(robotChargingEMP: aRobot)
                        }
                        
                        // note: no default action - in case we want to add another one here.  Also we don't want to default to a particular
                        // robot just in case it isn't that robot.  We would rather do nothing instead.
                    }
                    
                    // if the player is close enough to ai robot, then start homing in on it.
                    if aRobot.isPlayerRobotInHomingRange(playerRobotLoc: playerRobot.levelCoords) {
                        aRobot.robotState = .homing
                    }
                    // Check to see if the ai robot is a baker type robot and if the player's robot is in range.
                    // We've added a reload delay to prevent instantaneous launching of infinite numbers of baked goods
                    // but this should probably be reworked as it is a straight copy of the reload delay that the player's
                    // robot uses.  Note: the zapper doesn't throw baked goods.  It throws zap/sparks/deathray so we have to use
                    // a different check for it.
                    // use the current time to determine if the ai robot has finished reloading, particularly the zapper and all
                    // the throwing robots.
                    // make sure bakers are in range but also that lineOfSightPath isn't totally obscurred by a wall
                    if playerRobot.robotDisabled == false && playerRobot.impactedState != .tippedOver && playerRobot.impactedState != .endOverEndFlip && (aRobot.robotType == .baker || aRobot.robotType == .doublebaker || aRobot.robotType == .superbaker || aRobot.robotType == .pastrychef) && aRobot.robotFinishedReloading(currentTime: currentTime) && aRobot.isPlayerRobotInThrowingRange(playerRobotLoc: playerRobot.levelCoords)  && aRobot.lineOfSightPath(robotLoc: playerRobot.levelCoords, levelGrid: currentLevel.levelGrid, componentsDictionary: currentLevel.allDurableComponents) & pathIsTotallyObscured == 0 && isTargetInRange(aiRobotLocation: aRobot.robotNode.presentation.position, targetPoint: playerRobot.robotNode.presentation.position, hurlingSpeed: aRobot.getRobotThrowingSpeed()) == true {
                        // Note: substitute the if statement below for the one above if we need to test the pastry chef robots without a lot of stuff flying through
                        // the air.  The pastry chef's ability to throw stuff usually makes it difficult for us to test to see how the pastry chef looks when it is impacted.  It
                        // also makes it hard to see what the pasty chef's zap looks like.  We could almost do away with it but that might make them too easy to take out.
                    //if playerRobot.robotDisabled == false && playerRobot.impactedState != .tippedOver && playerRobot.impactedState != .endOverEndFlip && (aRobot.robotType == .baker || aRobot.robotType == .doublebaker || aRobot.robotType == .superbaker) && aRobot.robotFinishedReloading(currentTime: currentTime) && aRobot.isPlayerRobotInThrowingRange(playerRobotLoc: playerRobot.levelCoords)  && aRobot.lineOfSightPath(robotLoc: playerRobot.levelCoords, levelGrid: currentLevel.levelGrid, componentsDictionary: currentLevel.allDurableComponents) & PathIsTotallyObscured == 0 && isTargetInRange(aiRobotLocation: aRobot.robotNode.presentation.position, targetPoint: playerRobot.robotNode.presentation.position, hurlingSpeed: aRobot.getRobotThrowingSpeed()) == true {
                        // throw baked good from ai robot.
                        let aBakedGood = aRobot.hurlBakedGood(targetPoint: playerRobot.robotNode.presentation.position, targetLastPoint: playerRobot.lastPositionUpdate, targetVelocity: playerRobot.robotNode.physicsBody!.velocity, name: bakedGoodLabel + String(bakedGoodsCount), numThrowsThatShouldMiss: currentLevel.numberOfAIRobotThrowsThatMiss, randomGen: randomNumGenerator, levelNum: levelNum)

                        bakedGoods[bakedGoodLabel + String(bakedGoodsCount)] = aBakedGood
                        bakedGoodsCount += 1  // keep incrementing this count to provide more unique identifiers.
                        let puffOfSteamSoundAction = SCNAction.playAudio(NodeSound.puffOfSteam!, waitForCompletion: false)
                        let puffOfSteam = aRobot.generatePuffOfSteam(launchPoint: aBakedGood.bakedGoodNode.position)
                        let fadeAction = SCNAction.fadeOut(duration: 0.5)
                        let removeAction = SCNAction.removeFromParentNode()
                        let fadeSequence = SCNAction.sequence([puffOfSteamSoundAction, fadeAction, removeAction])
                        sceneView.scene?.rootNode.addChildNode((aBakedGood.bakedGoodNode)!)
                        sceneView.scene?.rootNode.addChildNode(puffOfSteam)
                        puffOfSteam.runAction(fadeSequence)
                        
                        // ai robots _only_ have one weapon so we only have one timeReloadStarted to track.
                        aRobot.timeReloadStarted[0] = currentTime  // start reload immediately
                    }
                    
                    // Change the robot's velocity if a) it is zero, or b) the robot is going to collide with something else.
                    // However, if the robot is a zapper with reload action running, then don't do anything as it is stopped, recharging
                    // for the duration of that reload time.  Also, if robot is turning to face the player it is either a worker or a superworker
                    // getting ready to push over the player.  In that case, also don't change the robot's velocity.
                    
                    // if robot is not worker, superworker or zapper, which uses the reloadTime to determine how long it should remain stopped after an attack on a
                    // player, then we constantly update the robot's velocity.
                    if aRobot.robotType != .worker && aRobot.robotType != .superworker && aRobot.robotType != .zapper {
                        aRobot.setNewAIRobotVelocity(levelGrid: currentLevel.levelGrid, randomGenerator: randomNumGenerator, playerPresentationLoc: playerRobot.robotNode.presentation.position, playerLevelLoc: playerRobot.levelCoords, componentsDictionary: currentLevel.allDurableComponents)
                        // keep launcher pointed at player.
                        if doesRobotHaveLauncher(playerType: aRobot.playerType, robotType: aRobot.robotType) == true {
                            aRobot.turnLauncherInDirectionOfLaunch(targetPoint: playerRobot.robotNode.presentation.position)
                        }
                    }
                    else if (aRobot.robotType == .worker || aRobot.robotType == .superworker) && aRobot.isTurningToFacePlayer == false && aRobot.robotFinishedReloading(currentTime: currentTime) == true {
                        aRobot.setNewAIRobotVelocity(levelGrid: currentLevel.levelGrid, randomGenerator: randomNumGenerator, playerPresentationLoc: playerRobot.robotNode.presentation.position, playerLevelLoc: playerRobot.levelCoords, componentsDictionary: currentLevel.allDurableComponents)
                    }
                    else if aRobot.robotType == .zapper && aRobot.robotFinishedReloading(currentTime: currentTime) == true {
                        aRobot.setNewAIRobotVelocity(levelGrid: currentLevel.levelGrid, randomGenerator: randomNumGenerator, playerPresentationLoc: playerRobot.robotNode.presentation.position, playerLevelLoc: playerRobot.levelCoords, componentsDictionary: currentLevel.allDurableComponents)
                    }
                }
                //}
                // After we're done updating this ai robot don't forget to add the robot just updated to our set of robots already updated.
                workingRobotsAlreadyUpdated.insert(botToUpdateName)
            }
        }
    }
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {

        if contact.nodeA.physicsBody!.categoryBitMask == collisionCategoryAIRobotBakedGood || contact.nodeA.physicsBody!.categoryBitMask == collisionCategoryPlayerRobotBakedGood {
                contact.nodeA.physicsBody!.categoryBitMask = noCollisionCategory   // remove baked good as an object that makes contact so we avoid multiple contacts
                createResidue(bakedGoodNode: contact.nodeA, whatHitNode: contact.nodeB, pointOfContact: contact.contactPoint)
            
        }
        else if contact.nodeB.physicsBody!.categoryBitMask == collisionCategoryAIRobotBakedGood || contact.nodeB.physicsBody!.categoryBitMask == collisionCategoryPlayerRobotBakedGood {
                contact.nodeB.physicsBody!.categoryBitMask = noCollisionCategory   // remove baked good as an object that makes contact so we avoid multiple contacts
                createResidue(bakedGoodNode: contact.nodeB, whatHitNode: contact.nodeA, pointOfContact: contact.contactPoint)
        }
        /* emp grenade should make a bounce sound when it bounces off things, until it goes off that is.  The bounce sound
           is commented out below because it's an Apple GarageBand loop so we may not be able to include it in our open source.
        else if contact.nodeA.physicsBody!.categoryBitMask == collisionCategoryEMPGrenade {
                let playEMPGrenadeBounceSound = SCNAction.playAudio(NodeSound.bounce!, waitForCompletion: false)
                let empGrenadeName = contact.nodeA.name!
                let empGrenade = empGrenades[empGrenadeName]!
                empGrenade.empGrenadeNode.runAction(playEMPGrenadeBounceSound)
        }
        else if contact.nodeB.physicsBody!.categoryBitMask == collisionCategoryEMPGrenade {
                let playEMPGrenadeBounceSound = SCNAction.playAudio(NodeSound.bounce!, waitForCompletion: false)
                let empGrenadeName = contact.nodeB.name!
                let empGrenade = empGrenades[empGrenadeName]!
                empGrenade.empGrenadeNode.runAction(playEMPGrenadeBounceSound)
        }
        */
            // Note: there's a multiple bounce problem where the robot is seen as contacting the exit multiple times.  Why that is is still a mystery because
            // everything should be reset when the player exits the level and enters a new one.  However, it seems like it
            // hits the exit of the next two levels immediately after they are entered and we get a problem where the game skips a few
            // levels each time the exit is reached.  So we only set the levelStatus to .LevelCompleted when it hasn't already been set that
            // to prevent this from happening.
        else if contact.nodeA.physicsBody!.categoryBitMask == collisionCategoryLevelExit && contact.nodeB.physicsBody!.categoryBitMask == collisionCategoryPlayerRobot && levelStatus != .levelCompleted {
            // exit level
            levelStatus = .levelCompleted
            // essentially remove player robot from the scene so it no longer interacts with the exit
            // And clear the exit so it no longer tries to interact.
            playerRobot.removeCollisionAndContactExceptForFloor()
            currentLevel.levelExitNode.physicsBody!.contactTestBitMask = 0
            // clear the player robot from wall collision to let it through.
            // IMPORTANT NOTE:  this depends very much on our scene-to-levelgrid-coordinates conversion automatically
            // caps any illegal row,col calculation to the minrow,mincol - maxrow, maxcol range.  This was originally
            // intended to prevent crashes if something accidentally went beyond the room.  And now we use it purposely
            // to make it look like the player robot is going through the exit.
            let farWallName = currentLevel.bakeryRoom.farWallName
            // let the player through the wall
            currentLevel.bakeryRoom.walls[farWallName]!.wallNode.physicsBody!.collisionBitMask ^= collisionCategoryPlayerRobot
            //gameSounds.playSound(soundToPlay: .levelexit)
            if isTutorialEnabled == true {
                tutorial.completedGoToStep(type: .gotoexit, stepName: goToExitLabel)
            }
            //let waitWhileRobotGoesThroughExitAction = SCNAction.wait(duration: 6.0)
            let waitWhileRobotGoesThroughExitAction = SCNAction.wait(duration: 3.0)
            playerRobot.robotNode.runAction(waitWhileRobotGoesThroughExitAction, completionHandler: {
                self.fadeOutScene()
            })
            
        }
        else if contact.nodeB.physicsBody!.categoryBitMask == collisionCategoryLevelExit && contact.nodeA.physicsBody!.categoryBitMask == collisionCategoryPlayerRobot && levelStatus != .levelCompleted {
            // exit level
            levelStatus = .levelCompleted
            // essentially remove player robot from the scene so it no longer interacts with the exit
            // And clear the exit so it no longer tries to interact.
            playerRobot.removeCollisionAndContactExceptForFloor()
            currentLevel.levelExitNode.physicsBody!.contactTestBitMask = 0
            // clear the player robot from wall collision to let it through.
            // IMPORTANT NOTE:  this depends very much on our scene-to-levelgrid-coordinates conversion automatically
            // caps any illegal row,col calculation to the minrow,mincol - maxrow, maxcol range.  This was originally
            // intended to prevent crashes if something accidentally went beyond the room.  And now we use it purposely
            // to make it look like the player robot is going through the exit.
            let farWallName = currentLevel.bakeryRoom.farWallName
            // let the player through the wall
            currentLevel.bakeryRoom.walls[farWallName]!.wallNode.physicsBody!.collisionBitMask ^= collisionCategoryPlayerRobot
            //gameSounds.playSound(soundToPlay: .levelexit)
            if isTutorialEnabled == true {
                tutorial.completedGoToStep(type: .gotoexit, stepName: goToExitLabel)
            }
            //let waitWhileRobotGoesThroughExitAction = SCNAction.wait(duration: 6.0)
            let waitWhileRobotGoesThroughExitAction = SCNAction.wait(duration: 3.0)
            playerRobot.robotNode.runAction(waitWhileRobotGoesThroughExitAction, completionHandler: {
                self.fadeOutScene()
            })
        }
        else if contact.nodeA.physicsBody!.categoryBitMask == collisionCategoryVault && contact.nodeB.physicsBody!.categoryBitMask == collisionCategoryPlayerRobot && levelStatus != .levelCompleted {
            // exit level - this will only happen when the barrier has gone into the off state.
            levelStatus = .levelCompleted
            // note: we set the position to the player's starting location to get rid of the multiple contacts of the exit.  However, we still keep
            // the condition in the if statement that the levelStatus must not be .LevelCompleted just in case there is somehow a double bounce.
            // essentially remove player robot from the scene so it no longer interacts with the vault
            // And clear the exit so it no longer tries to interact.
            playerRobot.removeCollisionAndContactExceptForFloor()
            currentLevel.vaultNode.physicsBody!.contactTestBitMask = 0
            
            // clear the player robot from wall collision to let it through.
            // IMPORTANT NOTE:  this depends very much on our scene-to-levelgrid-coordinates conversion automatically
            // caps any illegal row,col calculation to the minrow,mincol - maxrow, maxcol range.  This was originally
            // intended to prevent crashes if something accidentally went beyond the room.  And now we use it purposely
            // to make it look like the player robot is going through the exit.
            let farWallName = currentLevel.bakeryRoom.farWallName
            // let the player through the wall
            currentLevel.bakeryRoom.walls[farWallName]!.wallNode.physicsBody!.collisionBitMask ^= collisionCategoryPlayerRobot
            //gameSounds.playSound(soundToPlay: .levelexit)
            if isTutorialEnabled == true {
                tutorial.completedGoToStep(type: .gotoexit, stepName: goToExitLabel)
            }
            let waitWhileRobotGoesThroughVaultAction = SCNAction.wait(duration: 3.0)
            playerRobot.robotNode.runAction(waitWhileRobotGoesThroughVaultAction, completionHandler: {
                self.fadeOutScene()
            })
        }
        else if contact.nodeB.physicsBody!.categoryBitMask == collisionCategoryVault && contact.nodeA.physicsBody!.categoryBitMask == collisionCategoryPlayerRobot && levelStatus != .levelCompleted {
            // exit level - this will only happen when the barrier has gone into the off state.
            levelStatus = .levelCompleted
            // essentially remove player robot from the scene so it no longer interacts with the vault
            // And clear the exit so it no longer tries to interact.
            playerRobot.removeCollisionAndContactExceptForFloor()
            currentLevel.vaultNode.physicsBody!.contactTestBitMask = 0
            
            // clear the player robot from wall collision to let it through.
            // IMPORTANT NOTE:  this depends very much on our scene-to-levelgrid-coordinates conversion automatically
            // caps any illegal row,col calculation to the minrow,mincol - maxrow, maxcol range.  This was originally
            // intended to prevent crashes if something accidentally went beyond the room.  And now we use it purposely
            // to make it look like the player robot is going through the exit.
            let farWallName = currentLevel.bakeryRoom.farWallName
            // let the player through the wall
            currentLevel.bakeryRoom.walls[farWallName]!.wallNode.physicsBody!.collisionBitMask ^= collisionCategoryPlayerRobot
            //gameSounds.playSound(soundToPlay: .levelexit)
            if isTutorialEnabled == true {
                tutorial.completedGoToStep(type: .gotoexit, stepName: goToExitLabel)
            }
            let waitWhileRobotGoesThroughVaultAction = SCNAction.wait(duration: 3.0)
            playerRobot.robotNode.runAction(waitWhileRobotGoesThroughVaultAction, completionHandler: {
                self.fadeOutScene()
            })
        }
        else if contact.nodeA.physicsBody!.categoryBitMask == collisionCategoryVaultBarrier && contact.nodeB.physicsBody!.categoryBitMask == collisionCategoryPlayerRobot {
            currentLevel.vaultBarrierNode.geometry?.firstMaterial?.diffuse.contents = vaultBarrierPermissionDeniedColor
            currentVaultBarrierState = .denied
        }
        else if contact.nodeB.physicsBody!.categoryBitMask == collisionCategoryVaultBarrier && contact.nodeA.physicsBody!.categoryBitMask == collisionCategoryPlayerRobot {
            currentLevel.vaultBarrierNode.geometry?.firstMaterial?.diffuse.contents = vaultBarrierPermissionDeniedColor
            currentVaultBarrierState = .denied
        }
        else if contact.nodeA.physicsBody!.categoryBitMask == collisionCategoryPart  && contact.nodeB.physicsBody!.categoryBitMask == collisionCategoryPlayerRobot && parts[contact.nodeA.name!]?.partAlreadyPickedUp == false {
            playerLevelData.updateNumberOfPartsFound(numberOfParts: 1)
            controlPanel.updateDisplayedPartsFound(numPartsFound: playerLevelData.numberOfPartsFound, maxPartsToFind: playerLevelData.maxPartsToFind)
            // make it look like the part was picked up by making it disappear
            contact.nodeA.geometry?.firstMaterial?.diffuse.contents = UIColor.clear
            controlPanel.showPartGathered(part: parts[contact.nodeA.name!]!)
            controlPanel.removePartFromMap(partName: contact.nodeA.name!)
            // update that player has picked up the part, both in the local parts list that just has parts for the level
            // and in the global one that has all the parts in the game.
            parts[contact.nodeA.name!]?.partAlreadyPickedUp = true
            if isTutorialEnabled == true {
                tutorial.removePartPickupStepFromSceneAndMarkStepDone(stepName: contact.nodeA.name!)
                if tutorial.haveAllPartsBeenGathered() == true {
                    tutorial.fastForwardToGoToExitStep()
                }
            }
            // Only update the entire parts list if we're not at the last level - the key parts are not treated the same way.
            // Key parts in the last level are all or nothing.  We only save whether or not they have all been gathered so that
            // we know if the player has already gone through the vault or not.  This prevents double scoring, essentially and
            // we would show the vault as already open when the player goes in to the last level again.
            if levelNum == highestLevelNumber {
                if playerLevelData.numberOfPartsFound == playerLevelData.maxPartsToFind {
                    turnOffVaultBarrier()
                }
            }
            else {
                entirePartsList[(parts[contact.nodeA.name!]?.partNumber)!]?.retrieved = true
            }
            //gameSounds.playSound(soundToPlay: .partpickup)
        }
        else if contact.nodeA.physicsBody!.categoryBitMask == collisionCategoryPowerUp && contact.nodeB.physicsBody!.categoryBitMask == collisionCategoryPlayerRobot && powerUps[contact.nodeA.name!]?.powerUpAlreadyPickedUp == false {
            // However, we still mark that it's been picked up no matter what it is to keep from
            // duplicating the pick up, which cheapens the powerup
            contact.nodeA.geometry?.firstMaterial?.diffuse.contents = UIColor.clear
            powerUps[contact.nodeA.name!]?.powerUpAlreadyPickedUp = true
            controlPanel.showPowerUpAchieved(powerUp: (powerUps[contact.nodeA.name!])!)
            playerRobot.activatePowerUp(powerUp: powerUps[contact.nodeA.name!]!)
            gameSounds.playSound(soundToPlay: .powerup)
        }
        else if contact.nodeA.physicsBody!.categoryBitMask == collisionCategoryPlayerRobot && contact.nodeB.physicsBody!.categoryBitMask == collisionCategoryPart && parts[contact.nodeB.name!]!.partAlreadyPickedUp == false {
            playerLevelData.updateNumberOfPartsFound(numberOfParts: 1)
            controlPanel.updateDisplayedPartsFound(numPartsFound: playerLevelData.numberOfPartsFound, maxPartsToFind: playerLevelData.maxPartsToFind)
            // make it look like the part was picked up by making it disappear
            contact.nodeB.geometry?.firstMaterial?.diffuse.contents = UIColor.clear
            controlPanel.showPartGathered(part: parts[contact.nodeB.name!]!)
            controlPanel.removePartFromMap(partName: contact.nodeB.name!)
            // update that player has picked up the part, both in the local parts list that just has parts for the level
            // and in the global one that has all the parts in the game.
            parts[contact.nodeB.name!]?.partAlreadyPickedUp = true
            if isTutorialEnabled == true {
                tutorial.removePartPickupStepFromSceneAndMarkStepDone(stepName: contact.nodeB.name!)
                if tutorial.haveAllPartsBeenGathered() == true {
                    tutorial.fastForwardToGoToExitStep()
                }
            }
            // Only update the entire parts list if we're not at the last level - the key parts are not treated the same way.
            // Key parts in the last level are all or nothing.  We only save whether or not they have all been gathered so that
            // we know if the player has already gone through the vault or not.  This prevents double scoring, essentially and
            // we would show the vault as already open when the player goes in to the last level again.
            if levelNum == highestLevelNumber {
                if playerLevelData.numberOfPartsFound == playerLevelData.maxPartsToFind {
                    turnOffVaultBarrier()
                }
            }
            else {
                entirePartsList[(parts[contact.nodeB.name!]?.partNumber)!]?.retrieved = true
            }
            //gameSounds.playSound(soundToPlay: .partpickup)
        }
        else if contact.nodeA.physicsBody!.categoryBitMask == collisionCategoryPlayerRobot && contact.nodeB.physicsBody!.categoryBitMask == collisionCategoryPowerUp && powerUps[contact.nodeB.name!]?.powerUpAlreadyPickedUp == false {
            // However, we still mark that it's been picked up no matter what it is to keep from
            // duplicating the pick up, which cheapens the powerup
            contact.nodeB.geometry?.firstMaterial?.diffuse.contents = UIColor.clear
            powerUps[contact.nodeB.name!]?.powerUpAlreadyPickedUp = true
            controlPanel.showPowerUpAchieved(powerUp: (powerUps[contact.nodeB.name!])!)
            playerRobot.activatePowerUp(powerUp: powerUps[contact.nodeB.name!]!)
            gameSounds.playSound(soundToPlay: .powerup)
        }
        else if contact.nodeA.physicsBody!.categoryBitMask == collisionCategoryLevelComponent && contact.nodeB.physicsBody!.categoryBitMask == collisionCategoryPlayerRobot {
            let playerVelocityAfterImpact = playerRobot.robotNode.physicsBody?.velocity
            // if player is hardly moving, then set player to not be moving.  Otherwise we see drift when we set
            // the player's robot to be it's current velocity, odd as that sounds.
            let speed = playerRobot.getPlayerRobotSpeed()
            if calcDistance(p1: playerVelocityAfterImpact!, p2: notMoving) < 0.05 * calcDistance(p1: movingWest, p2: notMoving) * speed {
                playerRobot.currentVelocity = notMoving
            }
        }
        else if contact.nodeB.physicsBody!.categoryBitMask == collisionCategoryLevelComponent && contact.nodeA.physicsBody!.categoryBitMask == collisionCategoryPlayerRobot {
            let playerVelocityAfterImpact = playerRobot.robotNode.physicsBody?.velocity
            // if player is hardly moving, then set player to not be moving.  Otherwise we see drift when we set
            // the player's robot to be it's current velocity, odd as that sounds.
            let speed = playerRobot.getPlayerRobotSpeed()
            if calcDistance(p1: playerVelocityAfterImpact!, p2: notMoving) < 0.05 * calcDistance(p1: movingWest, p2: notMoving) * speed {
                playerRobot.currentVelocity = notMoving
            }
        }
        else if contact.nodeA.physicsBody!.categoryBitMask == collisionCategoryAIRobot && contact.nodeB.physicsBody!.categoryBitMask == collisionCategoryBunsenBurnerFlame && contact.nodeA.name!.range(of: aiRobotLabel) != nil {
            let aiRobotToBurn = aiRobots[contact.nodeA.name!]
            // for now we just change the color of the range finder when the path is clear and contact has been made.  this is just to show
            // that this could work.
            let currentTime = NSDate().timeIntervalSince1970
            if playerRobot.lineOfSightPath(robotLoc: (aiRobotToBurn?.levelCoords)!, levelGrid: currentLevel.levelGrid, componentsDictionary: currentLevel.allDurableComponents) == pathClear && playerRobot.robotFinishedBunsenBurnerReloading(currentTime: currentTime) == true {
                burnAIRobot(aiRobotToBurn: aiRobotToBurn!)
                turnOnBunsenBurner()
            }
        }
        else if contact.nodeB.physicsBody!.categoryBitMask == collisionCategoryAIRobot && contact.nodeA.physicsBody!.categoryBitMask == collisionCategoryBunsenBurnerFlame && contact.nodeB.name!.range(of: aiRobotLabel) != nil {
            let aiRobotToBurn = aiRobots[contact.nodeB.name!]
            // for now we just change the color of the range finder when the path is clear and contact has been made.  this is just to show
            // that this could work.
            let currentTime = NSDate().timeIntervalSince1970
            if playerRobot.lineOfSightPath(robotLoc: (aiRobotToBurn?.levelCoords)!, levelGrid: currentLevel.levelGrid, componentsDictionary: currentLevel.allDurableComponents) == pathClear && playerRobot.robotFinishedBunsenBurnerReloading(currentTime: currentTime) == true {
                burnAIRobot(aiRobotToBurn: aiRobotToBurn!)
                turnOnBunsenBurner()
            }
        }
    }
    
    // if vault barrier was touched before and that touch has just ended, then reset color and reset vault barrier
    // state from denied to on.  Note: This doesn't always work so we also check in a different function called
    // checkVaultBarrierStatus() for how far away the robot is from the vault in the z direction or the x direction.
    // We also change the status of the barrier in that function if it has been found that the player is far enough away.
    func physicsWorld(_ world: SCNPhysicsWorld, didEnd contact: SCNPhysicsContact) {
        if contact.nodeA.physicsBody!.categoryBitMask == collisionCategoryVaultBarrier && contact.nodeB.physicsBody!.categoryBitMask == collisionCategoryPlayerRobot {
            currentLevel.vaultBarrierNode.geometry?.firstMaterial?.diffuse.contents = vaultBarrierOriginalColor
            currentVaultBarrierState = .on
        }
        else if contact.nodeB.physicsBody!.categoryBitMask == collisionCategoryVaultBarrier && contact.nodeA.physicsBody!.categoryBitMask == collisionCategoryPlayerRobot {
            currentLevel.vaultBarrierNode.geometry?.firstMaterial?.diffuse.contents = vaultBarrierOriginalColor
            currentVaultBarrierState = .on
        }
        else if contact.nodeA.physicsBody!.categoryBitMask == collisionCategoryHole && contact.nodeB.physicsBody!.categoryBitMask == collisionCategoryPlayerRobot {
            let hole = currentLevel.holes[contact.nodeA.name!]
            if hole != nil {
                // hole somehow gets camouflaged instantly after the player goes over it so we
                // leave it uncamouflaged after the player goes over it, if going over it from
                // the side or at high speed.  That's why we're uncamouflaging it rather than
                // camouflaging it at the end of the contact.
                //hole?.camouflageHole()
                hole?.uncamouflageHole()
            }
        }
        else if contact.nodeB.physicsBody!.categoryBitMask == collisionCategoryHole && contact.nodeA.physicsBody!.categoryBitMask == collisionCategoryPlayerRobot {
            let hole = currentLevel.holes[contact.nodeB.name!]
            if hole != nil {
                // hole somehow gets camouflaged instantly after the player goes over it so we
                // leave it uncamouflaged after the player goes over it, if going over it from
                // the side or at high speed.  That's why we're uncamouflaging it rather than
                // camouflaging it at the end of the contact.
                //hole?.camouflageHole()
                hole?.uncamouflageHole()
            }

        }
    }
    
    func turnOnBunsenBurner() {
        let currentTime = NSDate().timeIntervalSince1970
        if bunsenBurnerOn == false && aiRobots.isEmpty == false {
            // start the sound playing
            //gameSounds.playSound(soundToPlay: .bunsenburner)
            playerRobot.bunsenBurnerFlameNode.geometry?.firstMaterial?.transparency = 0.8
            //playerRobot.bunsenBurnerFlameNode.addParticleSystem(bunsenBurnerFlame!)
            // we don't have a bunsen burner flame level component type so we don't bother to try to add anything to the
            // allDurableComponents dictionary for quick access.  allDurableComponents is in the level class.
            bunsenBurnerOn = true
            bunsenBurnerFlameStartTime = currentTime
        }
    }
    
    func turnOffBunsenBurner() {
        bunsenBurnerOn = false
        bunsenBurnerFlameStartTime = 0.0
        playerRobot.bunsenBurnerFlameNode.geometry?.firstMaterial?.transparency = 0.0
        // it should have already stopped by now but if not, stop the sound.
        //gameSounds.stopSound(soundToStop: .bunsenburner)
        let currentTime = NSDate().timeIntervalSince1970
        playerRobot.robotHealth.timeBunsenBurnerReloadStarted = currentTime // start reload immediately
    }
    
    func burnAIRobot(aiRobotToBurn: Robot) {
        let currentTime = NSDate().timeIntervalSince1970
        if currentTime - bunsenBurnerBurnIntervalTime >= defaultBunsenBurnerBurnCheckIntervalTime {
            // Immediately stop ai robot being burned but don't affect the player's robot.
            aiRobotToBurn.currentVelocity = notMoving
            aiRobotToBurn.robotNode.physicsBody!.velocity = aiRobotToBurn.currentVelocity
            aiRobotToBurn.robotHealth.hitWithFlames(flameDamage: fullFireResistance * 0.40)   // hurt the ai robot, but only a bit.  Note: we use FullFireResistance instead of
            // startingFireResistance in case the robot has boosted resistance from the start, like the super* robots and the pastry chef.
            if aiRobotToBurn.robotHealth.fireResistantHealth() <= healthPrettyMuchGone {
                shutdownAndRemoveRobot(robotToShutdown: aiRobotToBurn, pointOfImpact: SCNVector3(0.0, 0.0, 0.0), impactVelocity: SCNVector3(0.0, 0.0, 0.0), reasonForShutdown: ReasonForRobotShutdown.hitByFlames)
            }
            bunsenBurnerBurnIntervalTime = currentTime
        }
    }
    
    // player has gathered all the keys.  We turn off the vault barrier when that happens.
    // There are a number of things to do, like making the barrier clear, setting its state to .off,
    // giving feedback to the player that the barrier is off, and finally removing the collision detection
    // between barrier and player robot to allow the player to go through the barrier.
    func turnOffVaultBarrier() {
        currentLevel.vaultBarrierNode.geometry?.firstMaterial?.diffuse.contents = UIColor.clear
        currentVaultBarrierState = .off
        controlPanel.showVaultBarrierOffMessage()
        // turn off collision detection between barrier and player robot to allow the player to go through.
        playerRobot.robotNode.physicsBody!.contactTestBitMask ^= collisionCategoryVaultBarrier
        playerRobot.robotNode.physicsBody!.collisionBitMask ^= collisionCategoryVaultBarrier
        currentLevel.vaultBarrierNode.physicsBody!.contactTestBitMask ^= collisionCategoryPlayerRobot
        currentLevel.vaultBarrierNode.physicsBody!.collisionBitMask ^= collisionCategoryPlayerRobot
    }
    
    // worker and super worker robots turn and ram the player when the player is too close.
    // Note: no amount of extra mass should stop the player's robot from being tipped
    // over from a ram.  It should be too much mass to resist.
    func turnAIRobotAndRamPlayer(playerLoc: SCNVector3, playerVelocity: SCNVector3, aiRobot: Robot) {
        workerRammingPlayer = .rammingPlayer    // immediately set flag to prevent other ai robots from ramming player.
        // get distance player traveled in the time it takes for the ai robot to turn and then ram.
        let targetDistanceTraveled = multSCNVect3ByScalar(v: playerVelocity, s: Float(maximumWorkerTurnTime + maximumWorkerRamTime))
        let playerIntersectPoint = addTwoSCNVect3(v1: playerLoc, v2: targetDistanceTraveled)
        let xdelta = aiRobot.robotNode.presentation.position.x - playerIntersectPoint.x
        let zdelta = aiRobot.robotNode.presentation.position.z - playerIntersectPoint.z
                
        var turnAngle: Float = 0.0
        
        // This looks like it works, although I'm still not quite sure why.
        // But we do get the correct angles to turn to using the if statement
        // below.  It bugs me that I don't know exactly why it works.  I know
        // why the first one works and that is because we have to rotate the
        // angle 90 degrees because for the robots the -z direction is zero not the
        // x direction.  But when the player's x location is greater than the ai
        // robot's we have to subtract it from 270 degrees not, 90.  I suspect it
        // has something to do with the cycle of angles.  The results of sine for
        // a 'sine' wave that goes negative by the same amount as it does positive.
        // I suspect that we're getting into the negative part when playerX is greater
        // than aiRobotX and we have to subtract the resulting angle from an additional 180
        // degrees to correct the angle and get it behaving the same as when playerX is less
        // than aiRobotX.
        if playerIntersectPoint.x < aiRobot.robotNode.presentation.position.x {
            turnAngle = Float.pi / 2.0 - atan(zdelta/xdelta)
        }
        else {
            turnAngle = 3.0 * Float.pi / 2.0 - atan(zdelta/xdelta)
        }
        
        let turnAction = SCNAction.rotateTo(x: 0.0, y: CGFloat(turnAngle), z: 0.0, duration: maximumWorkerTurnTime)
        let moveAction = SCNAction.move(to: playerIntersectPoint, duration: maximumWorkerRamTime)
        
        // Hate to do it but we have to copy code from our shutdownAndRemoveRobot() function further below
        // because we have to turn the ai robot, ram the player, and then shut down the player robot, all in
        // sequence.  And we can't do that if we do the turning and ramming here and then try to do the shutdown
        // in the other function.  The two sequences of actions would run independently, which could result in 
        // things not looking right.
        // We do know it's the player's robot so we don't have to test to see which robot is shutting down, however.
        
        let distance = sqrt(xdelta*xdelta + zdelta*zdelta)
        let knockOverForceUnitVector = SCNVector3(xdelta/distance, 0.1, zdelta/distance)  // mostly horizontal force but add a little vertical in
                                                                                          // case the worker/superworker is ramming the player into
                                                                                          // a wall or fixed level component.
        // Somehow we got the force backwards, so we multiply by -1.0 to make it right.  What a kludge.
        let knockOverForce = multSCNVect3ByScalar(v: knockOverForceUnitVector, s: -1.0 * knockOverScalarForce)
        let pointOfImpact = SCNVector3(playerIntersectPoint.x, Float(1.50 * playerRobot.robotHealth.centerOfGravity), playerIntersectPoint.z)
        
        // Yes, we know velocity is not force but the baked good velocity is all we have to go by to determine how to knock over
        // the robot.  So we crudely just assign the velocity as a force and see what happens.  But we also have to cut it down as
        // it results in a way-too-powerful force.
        
        // Note: allModelsAndMaterials is global.  This was the only way we could think to load it only once instead of
        // at each instance of game play
        
        let shutdownAction = SCNAction.customAction(duration: 0.0, action: { _,_ in
            let catchingFire = catchingFireParticleSystem
            self.playerRobot.nearTopOfRobotNode.addParticleSystem(catchingFire!)
            self.playerRobot.shutdownRobot()
        })
        
        //let waitAction = SCNAction.wait(duration: RobotShutdownDuration + 0.2)
        let waitAction = SCNAction.wait(duration: 0.2)
        
        let removeAction = SCNAction.removeFromParentNode()
        let pauseAfterRemovalAction = SCNAction.wait(duration: 0.10)
        
        let tipOverWaitAction = SCNAction.wait(duration: 2.0)
        let contactPointInRobotCoordinateSpace =  sceneView.scene?.rootNode.convertPosition(pointOfImpact, to: playerRobot.robotNode)
        let tipOverAction = SCNAction.customAction(duration: 0.0, action: { _,_ in
            // tip the robot over and disable it so that other ai robots won't try to attack it now.
            self.workerRammingPlayer = .rammedPlayer
            self.playerRobot.turnOnForceEffects()
            self.playerRobot.robotNode.physicsBody!.applyForce(knockOverForce, at: contactPointInRobotCoordinateSpace!, asImpulse: true)
            //gameSounds.playSound(soundToPlay: .bowlingstrike)
        })
        let tipOverPlayerRobotAndGoToLevelSelectSequence = SCNAction.sequence([tipOverAction, shutdownAction, tipOverWaitAction, waitAction, removeAction, pauseAfterRemovalAction])
        // we didn't want to do this but I see no choice.  We have to run the ai robot turn sequence and once it
        // is complete, then run the tip over and shutdown sequence in its completionHandler.
        let turnSequence = SCNAction.sequence([turnAction, moveAction])
        aiRobot.robotNode.runAction(turnSequence, completionHandler: {
            aiRobot.raiseArms()
            self.playerRobot.robotNode.runAction(tipOverPlayerRobotAndGoToLevelSelectSequence, completionHandler: {
                self.levelStatus = .levelNotCompleted
                self.fadeOutScene()
            })
        })
    }
    
    // Create residue - we really don't create anything new.  We change the baked good from a baked good to a
    // residue by chaning the baked good state from .bakedgood to .residue.  From that point on we treat is 
    // as residue.
    // create residue - show splatter and tack on residue to robot.  Also changed baked good state from
    // .bakedgood to .residue.  From that point on it starts to fall through the floor, but the residue
    // attached to the robot stays until a later hit removes it.
    func createResidue(bakedGoodNode: SCNNode, whatHitNode: SCNNode, pointOfContact: SCNVector3) {
        let bakedGoodName = bakedGoodNode.name
        let residueLoc = pointOfContact
        let whatHit = whatHitNode.name
        var whatHitLoc: SCNVector3 = SCNVector3Zero
        
        let typeOfComponentHit = getLevelComponentType2(levelComponentName: whatHit!, componentsDictionary: currentLevel.allDurableComponents)
        
        // only create residue if this is the first time the baked good is making contact.  Since
        // contact can happen multiple times in Scenekit, this keeps us from trying to create the residue
        // again, and more importantly not try to remove a baked good in flight again that has already 
        // been removed.
        bakedGoods[bakedGoodName!]?.convertToResidue(bakedGoodStrikePoint: residueLoc)
        // Since we overwrote the existing contents of bakedGoodNode with a new SCNNode in convertToResidue()
        // we have to add the new node into the scene.  But what happened to the old node?  Is it automatically
        // cleaned up and removed from the node tree or is it hanging around just chewing up memory?
        // Note:  we comment this out to see if it makes any difference.  The reason we're doing this is
        // that after looking at the convertToResidue code we don't see in that function that we're
        // ever even replacing the node.  So if we're not replacing the node, then why are we
        // adding it back into the scene again?
        // We created a residue node in convertToResidue, and made the baked good node invisible, effectively
        // taking it out of the scene.  The residue node now takes the spotlight so we add it to the scene.
        // This gives the effect of the baked good creating residue after impact.  The residue has no real
        // effect on anything but gives the player some feedback that his/her throw made an impact.
        // Also, if the residue doesn't exist then there's no point in going further.  Although it in itself doesn't
        // affect the robot, we shouldn't see any effect on the robot if the residue doesn't appear.  This should
        // never happen but we make sure of that by checking it here.
        if bakedGoods[bakedGoodName!]!.residueNode != nil {
            sceneView.scene?.rootNode.addChildNode((bakedGoods[bakedGoodName!]!.residueNode)!)

            // Every time a residue is created, there should be a splat sound.
            let splatSoundAction = SCNAction.playAudio(NodeSound.splat!, waitForCompletion: false)
            bakedGoods[bakedGoodName!]!.residueNode.runAction(splatSoundAction)
            bakedGoods[bakedGoodName!]?.whatWasHit = whatHit!
            
            switch typeOfComponentHit {
            case .playerrobot:
                whatHitLoc = playerRobot.robotNode.presentation.position
                // give the residue the same velocity as the player robot so that the hit doesn't look like it is behind it.
                // the baked good should have been made invisible by now so we don't do anything with it.
                if playerRobot.robotNode != nil {
                    bakedGoods[bakedGoodName!]?.residueNode.physicsBody!.velocity = playerRobot.robotNode.physicsBody!.velocity
                }
                // when baked goods hit it can either corrode, try to tip over, or slow down by sticking to the robot.
                // because a baked good can be a combination of these, we apply all of them.
                playerRobot?.robotHealth.corrode(byAmount: (bakedGoods[bakedGoodName!]?.ammoType.corrosiveness)!)
                playerRobot?.robotHealth.reduceMobility(stickiness: (bakedGoods[bakedGoodName!]?.ammoType.stickiness)!)
                
                // If the player's robot has corroded more, then we show that change - note we don't check for the change in corrosion color
                // here but in showChangeInCorrosion() instead because it involves several calculations, not just a single value check.
                // Note: we change the corrosion color if the the robot hasn't been corroded to the point where it shuts down, as the
                // first if statement above will do.  We save the change in corrosion to this point to prevent both the shutdown and the
                // change to a new corrosion color from happening at the same time which results in an immediate switch to the last
                // corrosion color before shutdown rather than a smooth transition to the shutdown color.
                // Only show the primary effect
                switch bakedGoods[bakedGoodName!]!.ammoType.primaryEffect {
                case .corrosive:
                    if (playerRobot?.robotHealth.corrosionHealth())! <= healthPrettyMuchGone {
                        shutdownAndRemoveRobot(robotToShutdown: playerRobot!, pointOfImpact: pointOfContact, impactVelocity: (bakedGoods[bakedGoodName!]?.initialVelocity)!, reasonForShutdown: ReasonForRobotShutdown.corroded)
                    }
                    else {
                        playerRobot?.showChangeInCorrosion()
                    }
                case .impact:
                    // we only show the impact and recovery if robot isn't disabled.  Otherwise we get the soak up impact sound when we shouldn't.
                    if playerRobot?.robotDisabled == false {
                        playerRobot?.showImpactAndRecovery(sceneView: sceneView, pointOfImpact: pointOfContact, impactVelocity: (bakedGoods[bakedGoodName!]?.initialVelocity)!, mass: (bakedGoods[bakedGoodName!]?.ammoType.mass)!, throwingForcePowerUpUsed: false)  // note: player is never hit with a powered up throw
                    }
                default:
                    break
                }
            case .airobot:
                // make sure the ai robot hasn't been removed before we go checking the impact or corrosion.  This
                // prevents a crash.
                if aiRobots[whatHit!] != nil {
                    whatHitLoc = aiRobots[whatHit!]!.robotNode.presentation.position
                    bakedGoods[bakedGoodName!]?.residueNode.physicsBody!.velocity = aiRobots[whatHit!]!.robotNode.physicsBody!.velocity
                    aiRobots[whatHit!]?.robotHealth.corrode(byAmount: (bakedGoods[bakedGoodName!]?.ammoType.corrosiveness)!)
                    aiRobots[whatHit!]?.robotHealth.reduceMobility(stickiness: (bakedGoods[bakedGoodName!]?.ammoType.stickiness)!)
                    
                    // if the ai robot has corroded more, then we show that change - note we don't check for the change in corrosion color
                    // here but in showChangeInCorrosion() instead because it involves several calculations, not just a single value check.
                    // Note: we change the corrosion color if the the robot hasn't been corroded to the point where it shuts down, as the
                    // first if statement above will do.  We save the change in corrosion to this point to prevent both the shutdown and the
                    // change to a new corrosion color from happening at the same time which results in an immediate switch to the last
                    // corrosion color before shutdown rather than a smooth transition to the shutdown color.
                    // Only show the primary effect.
                    switch bakedGoods[bakedGoodName!]!.ammoType.primaryEffect {
                    case .corrosive:
                        if (aiRobots[whatHit!]?.robotHealth.corrosionHealth())! <= healthPrettyMuchGone {
                            shutdownAndRemoveRobot(robotToShutdown: aiRobots[whatHit!]!, pointOfImpact: pointOfContact, impactVelocity: (bakedGoods[bakedGoodName!]?.initialVelocity)!, reasonForShutdown: ReasonForRobotShutdown.corroded)
                        }
                        else {
                            aiRobots[whatHit!]?.showChangeInCorrosion()
                        }
                    case .impact:
                        if aiRobots[whatHit!]?.robotDisabled == false {
                            // we only show the impact and recovery if robot isn't disabled.  Otherwise we get the soak up impact sound when we shouldn't.
                            aiRobots[whatHit!]?.showImpactAndRecovery(sceneView: sceneView, pointOfImpact: pointOfContact, impactVelocity: (bakedGoods[bakedGoodName!]?.initialVelocity)!, mass: (bakedGoods[bakedGoodName!]?.ammoType.mass)!, throwingForcePowerUpUsed: bakedGoods[bakedGoodName!]!.throwingForcePowerUpUsed)
                        }
                    default:
                        break
                    }
                }
            default:
                break
            }
            // Note: we show the splatter after the robot starts to shut down or explode if it is going to do that.
            // So we need to always be sure to keep the robot explosion or shut down going long enough for the splatter to go away.
            bakedGoods[bakedGoodName!]?.showSplatter(sceneView: sceneView, componentType: typeOfComponentHit, locationOfComponent: whatHitLoc)
            // apply force to make the baked good and residue fall.  We do this last after any other velocities or forces have
            // been imposed.  Otherwise the residue hangs in midair, floating gently in front of the robot.
            let higherGravityForce = SCNVector3(0.0, -forceOfEarthGravity * 1.5, 0.0)
            let gravityForce = SCNVector3(0.0, -forceOfEarthGravity * 0.5, 0.0)
            bakedGoods[bakedGoodName!]!.bakedGoodNode.physicsBody!.applyForce(higherGravityForce, asImpulse: true)
            bakedGoods[bakedGoodName!]!.residueNode.physicsBody!.applyForce(gravityForce, asImpulse: true)
        }
    }
    
    // We remove the robot and shut down a dummy robot in its place.  That way we don't 
    // have the problem of shutting it down and then trying to remove it from the dictionary
    // at the end of that shutdown, which can cause a crash as the the action tries to remove
    // the node while executing the action, even if it's at the end of that action.
    func shutdownAndRemoveRobot(robotToShutdown: Robot, pointOfImpact: SCNVector3, impactVelocity: SCNVector3, reasonForShutdown: ReasonForRobotShutdown) {
        // only shut down the robot if it wasn't already disabled
        if robotToShutdown.robotDisabled == false {
            robotToShutdown.robotDisabled = true     // immediately disable robot.  We know it's going down at this point so set this now.
            
            var knockOverForce = impactVelocity
            knockOverForce.y = 0.0  // just horizontal velocity is what we need.
            
            // Yes, we know velocity is not force but the baked good velocity is all we have to go by to determine how to knock over
            // the robot.  So we crudely just assign the velocity as a force and see what happens.  But we also have to cut it down as
            // it results in a way-too-powerful force.
            knockOverForce = multSCNVect3ByScalar(v: knockOverForce, s: 0.15)
            
            
            // no dummy robot level component type so we don't add it to the allDurableComponents quick reference dictionary in the level class.
            if robotToShutdown.robotNode.name == playerRobot.robotNode.name {
                // It makes sense to flag the robot as being disabled when it actually shuts down but we do it here immediately instead because
                // the ai robots will keep attacking the player robot after it has been disabled and we want them to immediately
                // stop.
                let shutdownAction = SCNAction.customAction(duration: 0.0, action: { _,_ in
                    robotToShutdown.shutdownRobot()
                })
                
                let waitAction = SCNAction.wait(duration: robotShutdownDuration + 1.0)
                // we make the player's robot invisible rather than removing it because ai robots may still
                // be trying to check its location for targeting.  If we removed the node, that could break
                // that targeting code.  So instead we make it invisible, which should be ok because the
                // dummy robot is still there.  Or maybe this is ridiculous.  If both are still in the same
                // spot it may not make much sense to put a dummy robot in the same spot.  Seems to work, though.
                let makeInvisibleAction = SCNAction.customAction(duration: 0.0, action: { _,_ in
                    robotToShutdown.robotNode.geometry?.firstMaterial?.diffuse.contents = UIColor.clear
                })
                let pauseAfterRemovalAction = SCNAction.wait(duration: 0.5)
                
                var removePlayerRobotAndGoToLevelSelectSequence: SCNAction!
                if reasonForShutdown == ReasonForRobotShutdown.fellIntoHole {
                    let fallAction = SCNAction.wait(duration: 1.0)
                    removePlayerRobotAndGoToLevelSelectSequence = SCNAction.sequence([fallAction, shutdownAction, waitAction, makeInvisibleAction, pauseAfterRemovalAction])
                    robotToShutdown.turnOnForceEffects()
                    robotToShutdown.robotNode.physicsBody!.collisionBitMask = 0  // clear the mask - we want it to fall so it shouldn't interact with the ground.
                    var fallOverForce = gravityAssistForDescentIntoHole
                    var velocity = playerRobot.currentVelocity
                    switch playerRobot.currentDirection {
                    case east:
                        fallOverForce.x = -forwardForceIntoHole
                        velocity.x = -fallingIntoHoleSpeed
                    case west:
                        fallOverForce.x = forwardForceIntoHole
                        velocity.x = fallingIntoHoleSpeed
                    case north:
                        fallOverForce.z = -forwardForceIntoHole
                        velocity.z = -fallingIntoHoleSpeed
                    case south:
                        fallOverForce.z = forwardForceIntoHole
                        velocity.z = fallingIntoHoleSpeed
                    default:
                        break
                    }
                    playerRobot.currentVelocity = velocity
                    playerRobot?.robotNode.physicsBody!.velocity = playerRobot.currentVelocity
                    //let fallIntoHoleSoundAction = SCNAction.playAudio(NodeSound.fallandcrash!, waitForCompletion: false)
                    // We use nearTopOfRobotNode here to avoid interfering with actions placed on the robotNode.  It would
                    // probably be ok if we just used robotNode but this is safer.
                    //robotToShutdown.nearTopOfRobotNode.runAction(fallIntoHoleSoundAction)
                    robotToShutdown.robotNode.physicsBody!.applyForce(fallOverForce, asImpulse: true)
                }
                else if reasonForShutdown == ReasonForRobotShutdown.hitByStaticDischarge {
                    let shortCircuiting = shortCircuitingParticleSystem
                    shortCircuiting!.particleColorVariation = SCNVector4(0.0, 0.0, 3.0, 0.0)
                    shortCircuiting!.birthRate = 20.0
                    shortCircuiting!.emissionDuration = 0.10
                    shortCircuiting!.particleSize = 0.10
                    shortCircuiting!.particleVelocity = 10.0
                    shortCircuiting!.particleVelocityVariation = 1.5
                    shortCircuiting!.spreadingAngle = 60.0
                    shortCircuiting!.isAffectedByGravity = true
                    shortCircuiting!.particleLifeSpan = 1.0  // the default is 1.0 second but we specify it here in case we want to change it later.
                    shortCircuiting!.particleLifeSpanVariation = 0.5    // vary the spark lifespan to make it look more realistic.
                    shortCircuiting!.stretchFactor = 0.5        // show streaks with this attribute
                    let staticDischargeSoundAction = SCNAction.playAudio(NodeSound.staticDischarge!, waitForCompletion: true)
                    robotToShutdown.nearTopOfRobotNode.addParticleSystem(shortCircuiting!)
                    removePlayerRobotAndGoToLevelSelectSequence = SCNAction.sequence([staticDischargeSoundAction, shutdownAction, waitAction, makeInvisibleAction, pauseAfterRemovalAction])
                }
                    // Right now the ai robots don't carry bunsen burners so this won't happen.  But we might change that later
                    // so we put it here for completeness. -- nlb, 2017-10-13
                else if reasonForShutdown == ReasonForRobotShutdown.hitByFlames {
                    let catchingFire = catchingFireParticleSystem
                    let burnSoundAction = SCNAction.playAudio(NodeSound.fry!, waitForCompletion: true)
                    robotToShutdown.nearTopOfRobotNode.addParticleSystem(catchingFire!)
                    robotToShutdown.nearTopOfRobotNode.runAction(burnSoundAction, forKey: burningSoundKey)
                    removePlayerRobotAndGoToLevelSelectSequence = SCNAction.sequence([shutdownAction, waitAction, makeInvisibleAction, pauseAfterRemovalAction])
                }
                else if reasonForShutdown == ReasonForRobotShutdown.tippedOver {
                    robotToShutdown.turnOnForceEffects()
                    removePlayerRobotAndGoToLevelSelectSequence = SCNAction.sequence([shutdownAction, waitAction, makeInvisibleAction, pauseAfterRemovalAction])
                }
                else if reasonForShutdown == ReasonForRobotShutdown.corroded {
                    let catchingFire = catchingFireParticleSystem
                    let burnSoundAction = SCNAction.playAudio(NodeSound.fry!, waitForCompletion: true)
                    robotToShutdown.nearTopOfRobotNode.addParticleSystem(catchingFire!)
                    robotToShutdown.nearTopOfRobotNode.runAction(burnSoundAction, forKey: burningSoundKey)
                    let fullyCorrodeAction = SCNAction.customAction(duration: 0.0, action: { _,_ in
                        robotToShutdown.goToMostCorrodedState()
                    })
                    let waitForCorrosionAction = SCNAction.wait(duration: 1.0)
                    removePlayerRobotAndGoToLevelSelectSequence = SCNAction.sequence([fullyCorrodeAction, waitForCorrosionAction, shutdownAction, waitAction, makeInvisibleAction, pauseAfterRemovalAction])
                }
                else { // Happens for the case of TippedOver.  In that case the condition already exists, the robot just needs to be shut down.
                    removePlayerRobotAndGoToLevelSelectSequence = SCNAction.sequence([shutdownAction, waitAction, makeInvisibleAction, pauseAfterRemovalAction])
                }
                
                robotToShutdown.robotNode.runAction(removePlayerRobotAndGoToLevelSelectSequence, completionHandler: {
                    // Remove the robot.
                    // remove from parent, applying to all of the children of robotNode and then to robotNode itself.
                    // We use enumerateHierarchy instead of enumerateChildNodes in case we have a tree structure of nodes instead
                    // of just a string of child nodes.
                    robotToShutdown.robotNode.enumerateHierarchy { (node, _) in
                        node.removeFromParentNode()
                    }

                    self.levelStatus = .levelNotCompleted
                    // Note: we should probably remove the player's robot here but let's see how it looks before we do it. If it doesn't look bad, or isn't
                    // to puzzling then we'll just leave the player's robot in the map.  After all, the exit from the level is happening anyway.
                    self.fadeOutScene()
                })
            }
            else {   // robot is an ai robot so we treat it differently.

                let robotToShutdownName = robotToShutdown.robotNode.name!
                
                // put dummy robot in its place and show it shutting down.
                let shutdownAction = SCNAction.customAction(duration: 0.0, action: { _,_ in
                    robotToShutdown.shutdownRobot()
                })
                
                let waitAction = SCNAction.wait(duration: robotShutdownDuration + 1.0)
                // remove the dummy robotNode, and its children, from the scene.
                let removeFromSceneAction = SCNAction.customAction(duration: 0.0, action: { _,_ in
                    robotToShutdown.robotNode.enumerateHierarchy { (node, _) in
                        node.removeFromParentNode()
                    }
                    self.currentLevel.removeRobotFromLevelGrid(robotName: robotToShutdownName, levelCoords: robotToShutdown.levelCoords)  // remove ai robot from level grid
                    self.aiRobots.removeValue(forKey: robotToShutdownName)   // remove ai robot from our list of ai robots
                    // Note: there is some danger of a race condition removing the robot here.  Need to make sure this works fine.
                })
                
                var removeRobotSequence: SCNAction!
                
                if reasonForShutdown == ReasonForRobotShutdown.hitByStaticDischarge {
                    let shortCircuiting = shortCircuitingParticleSystem
                    shortCircuiting!.particleColorVariation = SCNVector4(0.0, 0.0, 3.0, 0.0)
                    shortCircuiting!.birthRate = 20.0
                    shortCircuiting!.emissionDuration = 0.10
                    shortCircuiting!.particleSize = 0.10
                    shortCircuiting!.particleVelocity = 10.0
                    shortCircuiting!.particleVelocityVariation = 1.5
                    shortCircuiting!.spreadingAngle = 60.0
                    shortCircuiting!.isAffectedByGravity = true
                    shortCircuiting!.particleLifeSpan = 1.0  // the default is 1.0 second but we specify it here in case we want to change it later.
                    shortCircuiting!.particleLifeSpanVariation = 0.5    // vary the spark lifespan to make it look more realistic.
                    shortCircuiting!.stretchFactor = 0.5        // show streaks with this attribute
                    let staticDischargeSoundAction = SCNAction.playAudio(NodeSound.staticDischarge!, waitForCompletion: true)
                    robotToShutdown.nearTopOfRobotNode.addParticleSystem(shortCircuiting!)
                    removeRobotSequence = SCNAction.sequence([staticDischargeSoundAction, shutdownAction, waitAction, removeFromSceneAction])
                }
                else if reasonForShutdown == ReasonForRobotShutdown.hitByFlames {
                    let catchingFire = catchingFireParticleSystem
                    let burnSoundAction = SCNAction.playAudio(NodeSound.fry!, waitForCompletion: true)
                    robotToShutdown.nearTopOfRobotNode.addParticleSystem(catchingFire!)
                    robotToShutdown.nearTopOfRobotNode.runAction(burnSoundAction, forKey: burningSoundKey)
                    removeRobotSequence = SCNAction.sequence([shutdownAction, waitAction, removeFromSceneAction])
                }
                else if reasonForShutdown == ReasonForRobotShutdown.tippedOver {
                    robotToShutdown.turnOnForceEffects()
                    removeRobotSequence = SCNAction.sequence([shutdownAction, waitAction, removeFromSceneAction])
                }
                else if reasonForShutdown == ReasonForRobotShutdown.corroded {
                    // Always go to the fully corroded state before shutting down, but we do it quicker than the normal change
                    // in corrosion states to reduce the time imposed in front of the shutdown.  But we always want to show
                    // the robot going to the fully corroded state before shutting down and this ensures it.  Otherwise we see
                    // inconsistent behavior
                    let catchingFire = catchingFireParticleSystem
                    let burnSoundAction = SCNAction.playAudio(NodeSound.fry!, waitForCompletion: true)
                    robotToShutdown.nearTopOfRobotNode.addParticleSystem(catchingFire!)
                    robotToShutdown.nearTopOfRobotNode.runAction(burnSoundAction, forKey: burningSoundKey)
                    let fullyCorrodeAction = SCNAction.customAction(duration: 0.0, action: { _,_ in
                        robotToShutdown.goToMostCorrodedState()
                    })
                    let waitForCorrosionAction = SCNAction.wait(duration: 1.0)
                    removeRobotSequence = SCNAction.sequence([fullyCorrodeAction, waitForCorrosionAction, shutdownAction, waitAction, removeFromSceneAction])
                }
                else {  // Happens for the case of TippedOver.  In that case the condition already exists, the robot just needs to be shut down.
                    removeRobotSequence = SCNAction.sequence([shutdownAction, waitAction, removeFromSceneAction])
                }
                
                // create a pop node that plays the pop sound, nothing else, for now.  Later, if there's time we may try to add a bubble burst
                // type of look.  I have absolutely no idea why this works in the simulator but does not work on any device.  Neither the
                // iPad nor the iPhone SE will play the pop sound, yet I hear it in the simulator just fine.
                /*
                let popGeometry = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0.0)
                popGeometry.firstMaterial?.diffuse.contents = UIColor.clear
                
                let popNode = SCNNode(geometry: popGeometry)
                popNode.position = robotToShutdown.robotNode.position
                sceneView.scene?.rootNode.addChildNode(popNode)
                let popNodeRemovalAction = SCNAction.removeFromParentNode()
                let robotDestroyedPopSoundAction = SCNAction.playAudio(NodeSound.pop!, waitForCompletion: true)
                let waitForPopFinishAction = SCNAction.wait(duration: 0.1)
                
                let popNodeSequence = SCNAction.sequence([robotDestroyedPopSoundAction, waitForPopFinishAction, popNodeRemovalAction])
                */
                
                // It may not look quite right but it is more accurate and fairer to the player to update the destroyed
                // robots right when the robots are considered destroyed.  Otherwise we run the risk of the player going through
                // the exit before the last robot destroyed is removed from the scene, which would deny the player of the extra kill.
                self.playerLevelData.updateNumberOfRobotsDestroyed(numberOfRobots: 1) // Technically, the robot is destroyed, even if the player didn't cause it.
                self.controlPanel.updateDisplayedRobotsDestroyed(numRobotsDestroyed: self.playerLevelData.numberOfRobotsDestroyed, maxRobotsToDestroy: self.playerLevelData.maxRobotsToDestroy)
                robotToShutdown.robotNode.runAction(removeRobotSequence, completionHandler: {
                    //popNode.runAction(popNodeSequence)
                    // Don't forget to remove robot from map.
                    self.controlPanel.removeAIRobotFromMap(aiRobotName: robotToShutdownName)   // remove ai robot from map.
                })
            }
        }    // End of if check for robotDisabled == false
        // Note:  The dummyRobot should be automatically removed from the game once this function finishes.
    }
        
    // This covers both the special case where the robot created an EMP.
    // Note: The robot charging the emp will be destroyed in that process so we remove it just before the
    // electromagnetic pulse appears and expands.  Also, we continue to use the dummyRobot here whereas
    // we have removed its use everywhere else.  We use it here as to make the emp going off more realistic.
    // We we tried to remove the use of the dummy robot two things happened: a) the ai robot was often
    // removed before the emp went off and b) the emp went off where the ai robot was, not where wound up
    // when the emp went off.  Somehow keeping the use of the dummyRobot fixes that although I'm not sure
    // why.
    func chargeAndFireTheEMP(robotChargingEMP: Robot) {
        // set up electromagnetic pulse before we do anything with the robot.
        let electromagneticPulseGeometry = SCNSphere(radius: CGFloat(initialElectromagneticPulseRadius))
        let electromagneticPulseNode: SCNNode = SCNNode(geometry: electromagneticPulseGeometry)
        electromagneticPulseNode.position = robotChargingEMP.robotNode.presentation.position
        electromagneticPulseNode.geometry?.firstMaterial?.diffuse.contents = UIColor.cyan
        electromagneticPulseNode.geometry?.firstMaterial?.transparency = empTransparency
        
        let maximumEMPRadius = maximumAIRobotBlastRadius
        let electromagneticPulseScale = maximumEMPRadius / initialElectromagneticPulseRadius
        
        // Remove the real robot and shutdown a dummy lookalike in its place.  That way we can remove
        // the dummy robot later without any side effects.  If we do that with the real robot, like
        // at the end of the shutdown action, we risk an exception when at the end of the action the
        // robot tries to remove itself from the robots dictionary.
        robotChargingEMP.removeCollisionAndContactExceptForFloor()
        robotChargingEMP.robotNode.removeAllActions()
        robotChargingEMP.robotNode.removeFromParentNode()
        
        // Note: allModelsAndMaterials is global.  This was the only way we could think to load it only once instead of
        // at each instance of game play
        let dummyRobot = DestroyedRobot(robotNum: robotChargingEMP.robotNumber, playertype: robotChargingEMP.playerType, robottype: robotChargingEMP.robotType, location: robotChargingEMP.robotNode.presentation.position, zapperEnabled: robotChargingEMP.zapperEnabled, secondLauncherEnabled: robotChargingEMP.secondLauncherEnabled)

        
        // Note: we get these values here for empLocation and the emp effective radius because later we remove the robotChargingEMP not
        // just from the scene but also from the level entirely as part of cleanup.
        let empLocation = robotChargingEMP.robotNode.presentation.position
        let withinEMP100PercentEffectiveRadius = maximumEMPRadius       // For now we make 100% effective radius the same as maximum.  We have the code in place if
                                                                        // later we want to make the emp _not_ 100% effective at maximumEMPRadius.  
        
        // we set the names of the robotNode to include the DummyLabel so that
        // when we go to test for a hit we ignore robots that have the DummyLable in their names
        // because we know they've replaced the real nodes and are shutting down.
        dummyRobot.robotNode.name = dummyLabel
        dummyRobot.robotNode.eulerAngles = robotChargingEMP.robotNode.eulerAngles
        // remember: every time we update eulerAngles we have to reset the position to where it was.  Otherwise the robotNode is
        // put back to the origin each time.
        dummyRobot.robotNode.position = robotChargingEMP.robotNode.presentation.position
        // Don't forget to make the material the same as the original.  If the robot was corroded in any way
        // then the dummy should go from that corroded state to the shutdown state.
        dummyRobot.robotBodyNode.geometry?.firstMaterial?.diffuse.contents = robotChargingEMP.robotBodyNode.geometry?.firstMaterial?.diffuse.contents
        
        sceneView.scene?.rootNode.addChildNode(dummyRobot.robotNode)
        // no level component type for the dummy robot so we don't add it to the allDurableComponents dictionary for quick reference.
        aiRobots.removeValue(forKey: robotChargingEMP.robotNode.name!)
        let robotToRemoveFromMap = robotChargingEMP.robotNode.name!   // save the name of the robot because we need that to remove it from the map after the emp discharge.
        let chargeEMPAction = SCNAction.customAction(duration: 0.0, action: { _,_ in
            dummyRobot.chargeEMP()
        })
        
        let waitForEMPToFinishChargingAction = SCNAction.wait(duration: robotCreateEMPDuration + 0.10)
        let removeRobotFromSceneAction = SCNAction.removeFromParentNode()
        
        let expandEMPAction = SCNAction.scale(to: CGFloat(electromagneticPulseScale), duration: 0.8)
        let removeEMPAction = SCNAction.removeFromParentNode()
        let createEMPsequence = SCNAction.sequence([expandEMPAction, removeEMPAction])
        
        let addEMP = SCNAction.customAction(duration: 0.0, action: { _,_ in
            self.sceneView.scene?.rootNode.addChildNode(electromagneticPulseNode)
            // assign discharge sound to electromagnetic pulse to give the sensation of an emp going off.
            //let empDischargeSoundAction = SCNAction.playAudio(NodeSound.empDischarge!, waitForCompletion: false)
            //electromagneticPulseNode.runAction(empDischargeSoundAction, forKey: empDischargeSoundKey)

            // no level component type for the emp so we don't add it to the allDurableComponents list in the level class for quick reference.
            
            // Note: if we want the robots in range of the emp to be destroyed/shutdown we should do it at the
            // end of the emp to enable the player to see the effect.  We do that here as a completion handler.
            // Otherwise it happens simultaneously with the emp expanding and that doesn't look right.  Note that this
            // is different than the other destroyed robot tallies because in this case the ai robot is initiating the
            // destruction, not the player.  
            electromagneticPulseNode.runAction(createEMPsequence, completionHandler: {
                self.playerLevelData.updateNumberOfRobotsDestroyed(numberOfRobots: 1) // Technically, the robot is destroyed, even if the player didn't cause it.
                self.controlPanel.updateDisplayedRobotsDestroyed(numRobotsDestroyed: self.playerLevelData.numberOfRobotsDestroyed, maxRobotsToDestroy: self.playerLevelData.maxRobotsToDestroy)
                self.controlPanel.removeAIRobotFromMap(aiRobotName: robotToRemoveFromMap)    // we're removing the robot from the map early but it should be ok.  Right?
                // add code here to shut down any robots within range of the emp.  But remember, if they shut down in a special way, like the homing and
                // ghost robots creating emp on shutdown, then they should do that rather than just shutting down via a normal short-circuit shutdown.
                self.updateRobotHealthWithEMPEffect(robot: self.playerRobot, empLocation: empLocation, oneHundredPercentEMPEffectiveRadius: withinEMP100PercentEffectiveRadius, maximumEMPRadius: maximumEMPRadius)
                for (_,aRobot) in self.aiRobots {
                    self.updateRobotHealthWithEMPEffect(robot: aRobot, empLocation: empLocation, oneHundredPercentEMPEffectiveRadius: withinEMP100PercentEffectiveRadius, maximumEMPRadius: maximumEMPRadius)
                }
            })
        })
        
        var chargeAndFireEMPSequence: SCNAction!
        chargeAndFireEMPSequence = SCNAction.sequence([chargeEMPAction, waitForEMPToFinishChargingAction, addEMP, removeRobotFromSceneAction])
        dummyRobot.robotNode.runAction(chargeAndFireEMPSequence)

    }
    
    // The emp grenade goes through a timer fuse before detonating.  This is the function that does both of
    // those things for the emp grenade.
    func runDelayTimerAndDetonateEMPGrenade(empGrenade: EMPGrenade) {
        let maximumEMPRadius = maximumEMPGrenadeBlastRadius
        let electromagneticPulseScale = maximumEMPRadius / initialElectromagneticPulseRadius
        
        let withinEMP100PercentEffectiveRadius = maximumEMPRadius       // For now we make 100% effective radius the same as maximum.  We have the code in place if
        // later we want to make the emp _not_ 100% effective at maximumEMPRadius.
        
        // since no real contact detection is made between the emp grenade and anything in the level, other than
        // simple collision detection, we can just set off the emp using the real emp grenade instead a fake one
        // like we did with ai robots that create emp
        let chargeEMPAction = SCNAction.customAction(duration: 0.0, action: { _,_ in
            empGrenade.chargeEMP()
        })
        let waitForDelayFuseAction = SCNAction.wait(duration: empGrenadeTimeDelayFuseLength)
        let waitForEMPToFinishChargingAction = SCNAction.wait(duration: empGrenadeCreateEMPDuration + 0.10)
        let removeGrenadeFromSceneAction = SCNAction.removeFromParentNode()
        
        let expandEMPAction = SCNAction.scale(to: CGFloat(electromagneticPulseScale), duration: 0.80)
        let removeEMPAction = SCNAction.removeFromParentNode()
        let createEMPsequence = SCNAction.sequence([expandEMPAction, removeEMPAction])
        
        let addEMP = SCNAction.customAction(duration: 0.0, action: { _,_ in
            // set up electromagnetic pulse before we do anything with the robot.
            let electromagneticPulseGeometry = SCNSphere(radius: CGFloat(initialElectromagneticPulseRadius))
            let electromagneticPulseNode: SCNNode = SCNNode(geometry: electromagneticPulseGeometry)
            let empLocation = empGrenade.empGrenadeNode.presentation.position
            electromagneticPulseNode.position = empLocation
            electromagneticPulseNode.geometry?.firstMaterial?.diffuse.contents = UIColor.cyan
            electromagneticPulseNode.geometry?.firstMaterial?.transparency = empTransparency
            
            self.sceneView.scene?.rootNode.addChildNode(electromagneticPulseNode)
            // assign discharge sound to electromagnetic pulse to give the sensation of an emp going off.
            //let empDischargeSoundAction = SCNAction.playAudio(NodeSound.empDischarge!, waitForCompletion: false)
            //electromagneticPulseNode.runAction(empDischargeSoundAction, forKey: empDischargeSoundKey)

            // no level component type for the emp so we don't add it to the allDurableComponents list in the level class for quick reference.

            // Note: if we want the robots in range of the emp to be destroyed/shutdown we should do it at the
            // end of the emp to enable the player to see the effect.  We do that here as a completion handler.
            // Otherwise it happens simultaneously with the emp expanding and that wouldn't look right.
            electromagneticPulseNode.runAction(createEMPsequence, completionHandler: {
                self.updateRobotHealthWithEMPEffect(robot: self.playerRobot, empLocation: empLocation, oneHundredPercentEMPEffectiveRadius: withinEMP100PercentEffectiveRadius, maximumEMPRadius: maximumEMPRadius)
                for (_,aRobot) in self.aiRobots {
                    self.updateRobotHealthWithEMPEffect(robot: aRobot, empLocation: empLocation, oneHundredPercentEMPEffectiveRadius: withinEMP100PercentEffectiveRadius, maximumEMPRadius: maximumEMPRadius)
                }
            })
        })
        
        var chargeAndFireEMPSequence: SCNAction!
        chargeAndFireEMPSequence = SCNAction.sequence([waitForDelayFuseAction, chargeEMPAction, waitForEMPToFinishChargingAction, addEMP, removeGrenadeFromSceneAction])
        empGrenade.empGrenadeNode.runAction(chargeAndFireEMPSequence, completionHandler: {
            empGrenade.spent = true    // grenade has gone off.  It can now be removed from the scene, but only after actions are done.
        })
    }

    func updateRobotHealthWithEMPEffect(robot: Robot, empLocation: SCNVector3, oneHundredPercentEMPEffectiveRadius: Float, maximumEMPRadius: Float) {
        if calcDistance(p1: robot.robotNode.presentation.position, p2: empLocation) <= oneHundredPercentEMPEffectiveRadius {
            // 100% emp effect - unless the robot has boosted resistance (i.e. it's startingStaticDischargeResistance is greater than FullStaticDischargeResistance)
            robot.robotHealth.hitWithStaticDischarge(staticDischarge: fullStaticDischargeResistance)
            if robot.robotHealth.staticHealth() <= healthPrettyMuchGone {
                // robot destroyed by EMP
                if robot.robotType == .homing || robot.robotType == .ghost {
                    // create cascading effect where one robot setting off emp can set off other robots that have emp
                    chargeAndFireTheEMP(robotChargingEMP: robot)
                }
                else {
                    shutdownAndRemoveRobot(robotToShutdown: robot, pointOfImpact: SCNVector3(0.0, 0.0, 0.0), impactVelocity: SCNVector3(0.0, 0.0, 0.0), reasonForShutdown: ReasonForRobotShutdown.hitByStaticDischarge)
                }
            }
        }
        else if calcDistance(p1: robot.robotNode.presentation.position, p2: empLocation) <= maximumEMPRadius {
            // 50% emp effect
            robot.robotHealth.hitWithStaticDischarge(staticDischarge: fullStaticDischargeResistance * 0.50)
            if robot.robotHealth.staticHealth() <= healthPrettyMuchGone {
                // robot destroyed by EMP
                if robot.robotType == .homing || robot.robotType == .ghost {
                    // create cascading effect where one robot setting off emp can set off other robots that have emp
                    chargeAndFireTheEMP(robotChargingEMP: robot)
                }
                else {
                    shutdownAndRemoveRobot(robotToShutdown: robot, pointOfImpact: SCNVector3(0.0, 0.0, 0.0), impactVelocity: SCNVector3(0.0, 0.0, 0.0), reasonForShutdown: ReasonForRobotShutdown.hitByStaticDischarge)
                }
            }
        }
        
    }
    
    // Note: as of 10/31/2018 the first person and overhead view buttons have been
    // removed but we leave the "switchTo" functions for them just in case we need
    // to use them again someday.
    
    // temporary functions to change camera view when either the overhead view
    // or first person view buttons have been selected.  Once we're sure our
    // level creation is ok, we can remove those buttons.
    func switchToFirstPersonView() {
        cameraZOffset = cameraFirstPersonViewZOffset
        //cameraYOffset = cameraFirstPersonViewYOffset
        cameraXOffset = cameraFirstPersonViewXOffset
        
        primaryCam.position.y = 3.0
        primaryCam.position.z = cameraZOffset + playerRobot.robotNode.presentation.position.z
        primaryCam.position.x = cameraXOffset + playerRobot.robotNode.presentation.position.x
        primaryCam.eulerAngles = cameraFirstPersonViewAngle
        viewAngle = .firstpersonview
    }
    
    func switchToOverheadView() {
        primaryCam.position.y = cameraOverheadViewYOffset
        primaryCam.eulerAngles = SCNVector3(-Double.pi/2.0, 0.0, 0.0)
        viewAngle = .overheadview
    }
    
    func switchToTwoAndAHalfDView() {
        // we set the cameraX,Y,Z offsets here.  That way we can use them
        // generically throughout the class.  Otherwise we would use the
        // specific CameraTwoAndAHalfDViewX,Y,ZOffset and that makes the
        // code less flexible
        cameraZOffset = cameraTwoAndAHalfDViewZOffset
        cameraYOffset = cameraTwoAndAHalfDViewYOffset
        cameraXOffset = cameraTwoAndAHalfDViewXOffset
        
        primaryCam.position.y = cameraYOffset
        primaryCam.position.z = cameraZOffset + playerRobot.robotNode.position.z
        primaryCam.position.x = cameraXOffset + playerRobot.robotNode.position.x

        primaryCam.eulerAngles = cameraTwoAndAHalfDViewAngle
        viewAngle = .twoandahalfdview
    }
    
    // prepare for segue unwind by clearing out all the nodes from the scene and from
    // the control panel spritekit overlay.  This should free up memory.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        gameSounds.stopSound(soundToStop: .constantspeed)
        //gameSounds.stopSound(soundToStop: .levelentry)                  //  stop level entry sound just in case player is going back and forth quickly
                                                                        // between level select and game play.
        sceneView.scene!.rootNode.enumerateChildNodes { (node, _) in
            node.enumerateHierarchy { (cnode, _) in
                cnode.removeFromParentNode()
            }
        }
    }
    
    func fadeOutScene() {
        let currentTime = NSDate().timeIntervalSince1970
        timeFadeOutInitiated = currentTime
        controlPanel.fadeOutScene(duration: fadeOutTimeDelay)
        /*
        if levelStatus == .LevelNotCompleted {
            gameSounds.playSound(soundToPlay: .gameoverman)
        }
        */
    }
    
    // fade in scene/view/whatever
    func fadeIn(view: UIView, duration: Double, delay: Double = 0.0) {
        UIView.animate(withDuration: duration, delay: delay, options: [.curveEaseInOut], animations: {
            view.alpha = 1.0
        })
    }

        
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
