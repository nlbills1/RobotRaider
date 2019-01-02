//
//  ControlPanelOverlay.swift
//  RobotRaider
//
//  Created by Nathanael Bills on 11/1/16.
//  Copyright © 2016 invasivemachines. All rights reserved.
//

import Foundation
import SceneKit
import SpriteKit

class ControlPanelOverlay: SKScene {
    var levelNode: SKLabelNode!
    var numPartsFoundNode: SKLabelNode!
    var numRobotsDestroyedNode: SKLabelNode!
    
    var screenSize: CGSize!

    var selectLevelButtonNode: SKShapeNode!
    
    var stopRobotButtonNode: SKShapeNode!
    var stopRobotButtonLabel: SKLabelNode!

    // map-specific stuff, for drawing anything in the small map area in the
    // top right corner of the screen
    var playerNodeInMap: SKShapeNode!
    var ringAroundPlayer: SKShapeNode!
    var mapHeight: CGFloat!
    var mapWidth: CGFloat!
    var mapOriginX: CGFloat!
    var mapOriginY: CGFloat!
    var mapRowSize: CGFloat!
    var mapColSize: CGFloat!
    
    var partsInMap: [String:SKShapeNode] = [:]
    
    var aiRobotsInMap: [String:SKShapeNode] = [:]
    var aiRobotsAddedToMap: Bool = false
    
    var statusBarNodes: [SKShapeNode] = []      // status bar nodes to let the player know the status of the reloads of each launcher.
    var zapUpdateStatusBarNode: SKShapeNode!     // the status bar for the zapper.
    var bunsenBurnerUpdateStatusBarNode: SKShapeNode!       // the status bar for the bunsen burner.
    
    var tutorialStepLabel: SKLabelNode!             // a label telling the player what to do.
    var tutorialStep2DArrow: SKShapeNode!           // the arrow that goes with the label, if the the tutorial step is a direction.
    
    var screenCover: SKShapeNode!
    
    override init(size: CGSize) {
        super.init(size: size)
        
        // Sigh.  It appears that setting the orientation to landscape doesn't change what iOS thinks is the width and height of the screen.  It still
        // treats it like it's in portrait mode in terms of width and height.  However, this only happens with some devices, like iPhones.  With iPads,
        // particularly the iPad Pro the values are correct after the switch to landscape orientation.  So rather than try to anticipate every
        // possible result we fudge and say that the larger value is always the width and the smaller value is always the height because the game
        // is only in landscape mode.
        
        if size.height > size.width {
            screenSize = CGSize(width: size.height, height: size.width)
        }
        else {
            screenSize = size
        }
        self.scaleMode = .resizeFill   // automatically resize screen to whatever screen size the device has.
                                       // Still might need to adjust game logic and art assets to match different sizes.
        
        levelNode = SKLabelNode(fontNamed: "AvenirNext-Bold")
        levelNode.text = "Level: 1"
        levelNode.fontColor = SKColor.yellow
        levelNode.fontSize = 10
        levelNode.horizontalAlignmentMode = .left
        levelNode.verticalAlignmentMode = .bottom
        levelNode.position = CGPoint(x: 0.15 * screenSize.width, y: screenSize.height - 0.05 * screenSize.height)
        levelNode.name = "Level"
        self.addChild(levelNode)
        
        numPartsFoundNode = SKLabelNode(fontNamed: "AvenirNext-Bold")
        numPartsFoundNode.text = "Parts Found: 0"
        numPartsFoundNode.fontColor = SKColor.yellow
        numPartsFoundNode.fontSize = 10
        numPartsFoundNode.horizontalAlignmentMode = .left
        numPartsFoundNode.verticalAlignmentMode = .bottom
        numPartsFoundNode.position = CGPoint(x: 0.30 * screenSize.width, y: screenSize.height - 0.05 * screenSize.height)
        numPartsFoundNode.name = "numPartsFound"
        self.addChild(numPartsFoundNode)
       
        numRobotsDestroyedNode = SKLabelNode(fontNamed: "AvenirNext-Bold")
        numRobotsDestroyedNode.text = "Robots Destroyed: 0"
        numRobotsDestroyedNode.fontColor = SKColor.yellow
        numRobotsDestroyedNode.fontSize = 10
    
        numRobotsDestroyedNode.horizontalAlignmentMode = .left
        numRobotsDestroyedNode.verticalAlignmentMode = .bottom
        numRobotsDestroyedNode.position = CGPoint(x: 0.50 * screenSize.width, y: screenSize.height - 0.05 * screenSize.height)
        numRobotsDestroyedNode.name = "numRobotsDestroyed"
        self.addChild(numRobotsDestroyedNode)
        
        // The code to show the first person view and overhead view is temporary it will be removed once we see our level layout is correct.
        //createFirstPersonViewButton(CGPoint(x: 0.05 * screenSize.width, y: screenSize.height - 0.25 * screenSize.height))
        //createOverheadViewButton(CGPoint(x: 0.05 * screenSize.width, y: screenSize.height - 0.35 * screenSize.height))
        createSelectLevelButton(CGPoint(x: 0.05 * screenSize.width, y: screenSize.height - 0.05 * screenSize.height))
        createStopRobotButton(CGPoint(x: 0.05 * screenSize.width, y: screenSize.height - 0.90 * screenSize.height))
        
        screenCover = SKShapeNode(rectOf: CGSize(width: screenSize.width, height: screenSize.height))
        screenCover.fillColor = SKColor.black
        screenCover.strokeColor = SKColor.black
        screenCover.position = CGPoint(x: 0.50 * screenSize.width, y: 0.50 * screenSize.height)
        screenCover.alpha = 0.0
        self.addChild(screenCover)

    }
    
    // Note: we use this to change the text color if the background is too light, as in the case of levels where
    // the fog is white.
    func makeTopTextColorDark() {
        levelNode.fontColor = SKColor.brown
        numPartsFoundNode.fontColor = SKColor.brown
        numRobotsDestroyedNode.fontColor = SKColor.brown
    }
    
    func createSelectLevelButton(_ location: CGPoint) {
        let levelSelectButtonTexture = allModelsAndMaterials.backButtonIcon
        selectLevelButtonNode = SKShapeNode(rectOf: CGSize(width: screenSize.width * 0.10, height: screenSize.height * 0.10), cornerRadius: backButtonCornerRadius)
        selectLevelButtonNode.position = location
        selectLevelButtonNode.strokeColor = SKColor.black
        selectLevelButtonNode.glowWidth = 0.5
        selectLevelButtonNode.fillTexture = levelSelectButtonTexture
        // still have to put in a white fill color to get the texture to show.  That's odd.  Ran across this requirement in
        // a google search.
        selectLevelButtonNode.fillColor = SKColor.white
        self.addChild(selectLevelButtonNode)
    }
    
    func showSelectLevelButtonTapped() {
        // we change the background fill color to show the button being tapped.  It changes
        // the color of the whole button.
        selectLevelButtonNode.fillColor = SKColor.yellow
    }

    func createStopRobotButton(_ location: CGPoint) {
        stopRobotButtonNode = SKShapeNode(circleOfRadius: screenSize.width * 0.05)
        stopRobotButtonNode.position = location
        stopRobotButtonNode.strokeColor = SKColor.black
        stopRobotButtonNode.glowWidth = 1.0
        stopRobotButtonNode.fillColor = SKColor.red
        stopRobotButtonLabel = SKLabelNode(fontNamed: "Damascus")
        stopRobotButtonLabel.text = "Stop"
        stopRobotButtonLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.center
        stopRobotButtonLabel.verticalAlignmentMode = SKLabelVerticalAlignmentMode.center
        stopRobotButtonLabel.fontSize = 15
        stopRobotButtonLabel.fontColor = SKColor.white
        stopRobotButtonLabel.position = location
        self.addChild(stopRobotButtonNode)
        self.addChild(stopRobotButtonLabel)
    }
    
    func setUpTutorial() {
        createTutorialLabel()
        createTutorial2DArrow()
    }
    
    func createTutorialLabel() {
        // set up tutorial step label but don't use it yet.  It is used later in showTutorialStep()
        // where it is added to the scene and then removed as part of its actions.
        tutorialStepLabel = SKLabelNode(fontNamed: "Damascus")
        tutorialStepLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.center
        tutorialStepLabel.verticalAlignmentMode = SKLabelVerticalAlignmentMode.center
        tutorialStepLabel.fontSize = 15
        tutorialStepLabel.fontColor = SKColor.white
        tutorialStepLabel.text = ""
    }
    
    func createTutorial2DArrow() {
        // set up a pointing arrow in cases of direction.  But don't use it yet.
        let twoDArrowTexture = allModelsAndMaterials.twoDUpArrowIcon    // to start use the up arrow.  This will be changed when the arrow is actually put in scene
        // we use screen height to calculate both height and width because a) it's the smaller dimension, the smallest common denominator, essentially, and b) we
        // want the arrow to reside in a square so it is not distorted.
        tutorialStep2DArrow = SKShapeNode(rectOf: CGSize(width: screenSize.height * 0.15, height: screenSize.height * 0.15))
        tutorialStep2DArrow.strokeColor = SKColor.clear
        tutorialStep2DArrow.fillTexture = twoDArrowTexture
        // still have to put in a white fill color to get the texture to show.  That's odd.  Ran across this requirement in
        // a google search.
        tutorialStep2DArrow.fillColor = SKColor.white
    }
    
    // check to see if a button on the control panel has been selected.
    // If so, return true; otherwise, return false.
    func buttonSelected(location: CGPoint) -> SelectedButton {
        var tappedLocation = location
        var isButtonSelected = SelectedButton.noButtonSelected
        tappedLocation.y = screenSize.height - location.y
        
        if selectLevelButtonNode.contains(tappedLocation) {
            isButtonSelected = .selectLevelSelected
        }
        else if stopRobotButtonNode.contains(tappedLocation) {
            isButtonSelected = .stopRobotSelected
        }
        
        return isButtonSelected
    }

    
    func updateDisplayedPartsFound (numPartsFound: Int, maxPartsToFind: Int) {
        let partsFoundString = String(numPartsFound)
        let partsToFindString = String(maxPartsToFind)
        numPartsFoundNode.text = "Parts Found: " + partsFoundString + "/" + partsToFindString
    }
    
    func updateDisplayedRobotsDestroyed (numRobotsDestroyed: Int, maxRobotsToDestroy: Int) {
        let robotsDestroyedString = String(numRobotsDestroyed)
        let robotsToDestroyString = String(maxRobotsToDestroy)
        numRobotsDestroyedNode.text = "Robots Destroyed: " + robotsDestroyedString + "/" + robotsToDestroyString
    }
    
    func updateDisplayedLevelNumber (num: Int) {
        let levelString = String(num)
        levelNode.text = "Level: " + levelString
    }
    
    // highlight where the player taps if it is not the robot or a button.
    // This gives feedback to the player that where he/she taps is where the
    // baked good is likely to go.
    func highlightLocationTapped(twoDLocation: CGPoint, colorToUse: UIColor) {
        
        // Note: for some odd reason the SpriteKit y coordinate is always the
        // _opposite_ of the UIView y coordinate.
        var location = twoDLocation
        location.y = screenSize.height - twoDLocation.y
        
        let targetingCircle = SKShapeNode(circleOfRadius: 5)
        targetingCircle.position = location
        targetingCircle.fillColor = UIColor.clear
        targetingCircle.strokeColor = colorToUse
        let scaleAction = SKAction.scale(to: 5.0, duration: 0.2)
        let removeAction = SKAction.removeFromParent()
        let scaleAndRemoveSequence = SKAction.sequence([scaleAction, removeAction])
        self.addChild(targetingCircle)
        targetingCircle.run(scaleAndRemoveSequence)
    }
    
    func highlightNonItemButton(_ whichButton: SelectedButton) {
        let waitAction = SKAction.wait(forDuration: 0.2)
        let waitSequence = SKAction.sequence([waitAction])

        switch whichButton {
        case .stopRobotSelected:
                stopRobotButtonNode.fillColor = SKColor.orange
                stopRobotButtonNode.run(waitSequence, completion: {
                    self.stopRobotButtonNode.fillColor = SKColor.red
                })
        case .selectLevelSelected:
            selectLevelButtonNode.fillColor = SKColor.yellow
        default:
            break
        }
    }
    
    // reloading status bars for the player.  Note: We just draw the outline and leave
    // it on the screen.  It will be the updateReloadingStatusBar() function that will
    // fill them in by overlaying a node that's filled on top of these nodes.  Thus, we
    // don't need to track these nodes since they're like empty buckets that just sit there.
    func drawAndInitReloadingStatusBar(numberOfBars: Int) {
        let statusBarHeight = screenSize.height * fractionOfScreenUsedForReloadStatusBar
        let statusBarWidth = screenSize.width / screenSize.height * statusBarHeight / 3.0
        let statusIconHeight = screenSize.height * fractionOfScreenUsedForStatusIcon
        let statusIconWidth = statusBarWidth
        
        for n in 0...numberOfBars - 1 {
            // distanceBetweenBars is the distance between their centers.
            let distanceBetweenBars = (CGFloat(n) * 1.5) * statusBarWidth
            let statusBarCenterX = screenSize.width - distanceBetweenBars - 0.05 * screenSize.width
            let statusBarCenterY = 0.5 * statusBarHeight + 0.10 * screenSize.height
            let statusIconCenterX = statusBarCenterX
            let statusIconCenterY = 0.5 * statusIconHeight
            
            let statusBarNode = SKShapeNode(rectOf: CGSize(width: statusBarWidth, height: statusBarHeight))
            statusBarNode.fillColor = UIColor.clear
            statusBarNode.strokeColor = UIColor.black
            statusBarNode.position.x = statusBarCenterX
            statusBarNode.position.y = statusBarCenterY
            self.addChild(statusBarNode)
            let updateStatusBar = SKShapeNode()
            statusBarNodes.append(updateStatusBar)
            
            let statusIconNode = SKSpriteNode(texture: allModelsAndMaterials.launcherIcon)
            statusIconNode.position = CGPoint(x: statusIconCenterX, y: statusIconCenterY)
            statusIconNode.size = CGSize(width: statusIconWidth, height: statusIconHeight)
            self.addChild(statusIconNode)
        }
    }
    
    func drawAndInitZapStatusBar() {
        let statusBarHeight = screenSize.height * fractionOfScreenUsedForReloadStatusBar
        let statusBarWidth = screenSize.width / screenSize.height * statusBarHeight / 3.0
        let statusIconHeight = screenSize.height * fractionOfScreenUsedForStatusIcon
        let statusIconWidth = statusBarWidth

        // draw zap status bar as the 3rd one from the right, always, hence the 2*3 below.
        // We could just use 6 but we want to show it being the third.
        let distanceBetweenBars = (CGFloat(2) * 1.5) * statusBarWidth
        let statusBarCenterX = screenSize.width - distanceBetweenBars - 0.05 * screenSize.width
        let statusBarCenterY = 0.5 * statusBarHeight + 0.10 * screenSize.height
        let statusIconCenterX = statusBarCenterX
        let statusIconCenterY = 0.5 * statusIconHeight
        
        let statusBarNode = SKShapeNode(rectOf: CGSize(width: statusBarWidth, height: statusBarHeight))
        statusBarNode.fillColor = UIColor.clear
        statusBarNode.strokeColor = UIColor.black
        statusBarNode.position.x = statusBarCenterX
        statusBarNode.position.y = statusBarCenterY
        self.addChild(statusBarNode)
        zapUpdateStatusBarNode = SKShapeNode()
        
        let statusIconNode = SKSpriteNode(texture: allModelsAndMaterials.zapIcon)
        statusIconNode.position = CGPoint(x: statusIconCenterX, y: statusIconCenterY)
        statusIconNode.size = CGSize(width: statusIconWidth, height: statusIconHeight)
        self.addChild(statusIconNode)
    }
    
    func drawAndInitBunsenBurnerStatusBar() {
        let statusBarHeight = screenSize.height * fractionOfScreenUsedForReloadStatusBar
        let statusBarWidth = screenSize.width / screenSize.height * statusBarHeight / 3.0
        let statusIconHeight = screenSize.height * fractionOfScreenUsedForStatusIcon
        let statusIconWidth = statusBarWidth
        
        // draw bunsen burner status bar as the 4th one from the right, always, hence the 2*4 below.
        // We could just use 8 but we want to show it being the fourth this way.
        let distanceBetweenBars = (CGFloat(3) * 1.5) * statusBarWidth
        let statusBarCenterX = screenSize.width - distanceBetweenBars - 0.05 * screenSize.width
        let statusBarCenterY = 0.5 * statusBarHeight + 0.10 * screenSize.height
        let statusIconCenterX = statusBarCenterX
        let statusIconCenterY = 0.5 * statusIconHeight

        let statusBarNode = SKShapeNode(rectOf: CGSize(width: statusBarWidth, height: statusBarHeight))
        statusBarNode.fillColor = UIColor.clear
        statusBarNode.strokeColor = UIColor.black
        statusBarNode.position.x = statusBarCenterX
        statusBarNode.position.y = statusBarCenterY
        self.addChild(statusBarNode)
        bunsenBurnerUpdateStatusBarNode = SKShapeNode()
        
        let statusIconNode = SKSpriteNode(texture: allModelsAndMaterials.flameIcon)
        statusIconNode.position = CGPoint(x: statusIconCenterX, y: statusIconCenterY)
        statusIconNode.size = CGSize(width: statusIconWidth, height: statusIconHeight)
        self.addChild(statusIconNode)
    }
    
    // We're not really updating a status bar.  We're essentially creating
    // another node on top of it filled instead of clear.
    func updateReloadingStatusBar(currentTime: Double, reloadStartTimes: [Double], timeReloadTakes: Double) {
        let statusBarHeight = screenSize.height * fractionOfScreenUsedForReloadStatusBar
        let statusBarWidth = screenSize.width / screenSize.height * statusBarHeight / 3.0
        
        for n in 0...reloadStartTimes.count - 1 {
            // distanceBetweenBars is the distance between their centers.
            let distanceBetweenBars = (CGFloat(n) * 1.5) * statusBarWidth
            let statusBarCenterX = screenSize.width - distanceBetweenBars - 0.05 * screenSize.width
            var reloadCompletionFraction = (currentTime - reloadStartTimes[n]) / timeReloadTakes
            // status can't exceed 1.0 or 100%
            if reloadCompletionFraction > 1.0 {
                reloadCompletionFraction = 1.0
            }
            let statusBarCompletionHeight = statusBarHeight * CGFloat(reloadCompletionFraction)
            let statusBarCenterY = 0.5 * statusBarCompletionHeight + 0.10 * screenSize.height
            let statusBarNode = SKShapeNode(rectOf: CGSize(width: statusBarWidth, height: statusBarCompletionHeight))
            if reloadCompletionFraction < 1.0 {
                statusBarNode.fillColor = UIColor.yellow
            }
            else {
                statusBarNode.fillColor = UIColor.green
            }
            statusBarNode.strokeColor = UIColor.clear
            statusBarNode.position.x = statusBarCenterX
            statusBarNode.position.y = statusBarCenterY
            // remove old status bar update from screen and add new update.
            statusBarNodes[n].removeFromParent()
            // does this cause a possible retain cycle problem?  When we replace
            // an object with a different one, that should set the retain count to zero, shouldn't it?
            // Particularly if we've removed it from the scene, was we just did with removeFromParent().
            statusBarNodes[n] = statusBarNode
            self.addChild(statusBarNode)
        }
    }
    
    // create bunsen burner status bar, leaving it partially charged when not all zaps have been shot
    // before reload and then showing a yellow bar when it is reloading.  Note that this behavior is
    // different than that of the baked good launcher, which immediately shows a yellow bar because
    // it immediately starts reloading after a throw.
    func updateZapStatusBar(currentTime: Double, zapCount: Int, zapReloadStartTime: Double, timeZapReloadTakes: Double, zapperFinishedReloading: Bool) {
        let statusBarHeight = screenSize.height * fractionOfScreenUsedForReloadStatusBar
        let statusBarWidth = screenSize.width / screenSize.height * statusBarHeight / 3.0

        // start zap status bar always at 3rd from the right.
        let distanceBetweenBars = (CGFloat(2) * 1.5) * statusBarWidth
        let statusBarCenterX = screenSize.width - distanceBetweenBars - 0.05 * screenSize.width
        var statusBarCompletionFraction: Double = 0.0
    
        if zapCount == 0 && zapperFinishedReloading == true {
            statusBarCompletionFraction = 1.0
        }
        else if zapCount > 0 {
            statusBarCompletionFraction = Double(maxZapCountForPlayerZapperWeapon - zapCount)/Double(maxZapCountForPlayerZapperWeapon)
        }
        else if zapCount == 0 && zapperFinishedReloading != true {
            statusBarCompletionFraction = (currentTime - zapReloadStartTime)/timeZapReloadTakes
        }
        let statusBarCompletionHeight = statusBarHeight * CGFloat(statusBarCompletionFraction)
        let statusBarCenterY = 0.5 * statusBarCompletionHeight + 0.10 * screenSize.height
        let statusBarNode = SKShapeNode(rectOf: CGSize(width: statusBarWidth, height: statusBarCompletionHeight))
        if statusBarCompletionFraction < 1.0 && zapCount == 0 {
            statusBarNode.fillColor = UIColor.yellow
        }
        else {
            statusBarNode.fillColor = UIColor.green
        }
        statusBarNode.strokeColor = UIColor.clear
        statusBarNode.position.x = statusBarCenterX
        statusBarNode.position.y = statusBarCenterY
        // remove old status bar update from screen and add new update.
        zapUpdateStatusBarNode.removeFromParent()
        // does this cause a possible retain cycle problem?  When we replace
        // an object with a different one, that should set the retain count to zero, shouldn't it?
        // Particularly if we've removed it from the scene, was we just did with removeFromParent().
        zapUpdateStatusBarNode = statusBarNode
        self.addChild(statusBarNode)
    }
    
    // create bunsen burner status bar, leaving it partially charged when not all flames have been shot
    // before reload and then showing a yellow bar when it is reloading.  Note that this behavior is
    // different than that of the baked good launcher, which immediately shows a yellow bar because
    // it immediately starts reloading after a throw.
    func updateBunsenBurnerStatusBar(currentTime: Double, flameCount: Int, bunsenBurnerReloadStartTime: Double, timeBunsenBurnerReloadTakes: Double, bunsenBurnerFinishedReloading: Bool) {
        let statusBarHeight = screenSize.height * fractionOfScreenUsedForReloadStatusBar
        let statusBarWidth = screenSize.width / screenSize.height * statusBarHeight / 3.0
        
        // start bunsen burner always at the 4th from the right.
        let distanceBetweenBars = (CGFloat(3) * 1.5) * statusBarWidth
        let statusBarCenterX = screenSize.width - distanceBetweenBars - 0.05 * screenSize.width
        var statusBarCompletionFraction: Double = 0.0
        
        if flameCount == 0 && bunsenBurnerFinishedReloading == true {
            statusBarCompletionFraction = 1.0
        }
        else if flameCount > 0 {
            statusBarCompletionFraction = Double(maxFlameCountForBunsenBurner - flameCount)/Double(maxFlameCountForBunsenBurner)
        }
        else if flameCount == 0 && bunsenBurnerFinishedReloading != true {
            statusBarCompletionFraction = (currentTime - bunsenBurnerReloadStartTime)/timeBunsenBurnerReloadTakes
        }
        let statusBarCompletionHeight = statusBarHeight * CGFloat(statusBarCompletionFraction)
        let statusBarCenterY = 0.5 * statusBarCompletionHeight + 0.10 * screenSize.height
        let statusBarNode = SKShapeNode(rectOf: CGSize(width: statusBarWidth, height: statusBarCompletionHeight))
        if statusBarCompletionFraction < 1.0 && flameCount == 0 {
            statusBarNode.fillColor = UIColor.yellow
        }
        else {
            statusBarNode.fillColor = UIColor.cyan
        }
        statusBarNode.strokeColor = UIColor.clear
        statusBarNode.position.x = statusBarCenterX
        statusBarNode.position.y = statusBarCenterY
        // remove old status bar update from screen and add new update.
        bunsenBurnerUpdateStatusBarNode.removeFromParent()
        // does this cause a possible retain cycle problem?  When we replace
        // an object with a different one, that should set the retain count to zero, shouldn't it?
        // Particularly if we've removed it from the scene, was we just did with removeFromParent().
        bunsenBurnerUpdateStatusBarNode = statusBarNode
        self.addChild(statusBarNode)
    }
    // Draw the map that helps the player find the exit in the level.
    // This assumes that the level is rectangular.
    func drawMap(theLevel: Level, playerLoc: LevelCoordinates, parts: [String : PartInLevel]) {
        let numRows = theLevel.levelMaze.theMazeExpanded.count - 1
        let numCols = theLevel.levelMaze.theMazeExpanded[0].count - 1
        
        mapHeight = screenSize.height * fractionOfScreenUsedForMap
        mapWidth = screenSize.width / screenSize.height * mapHeight
        
        mapRowSize = mapHeight / CGFloat(numRows)
        mapColSize = mapWidth / CGFloat(numCols)
        
        let playerRowSize = mapRowSize
        let playerColSize = mapColSize
        
        let mapNode = SKShapeNode(rectOf: CGSize(width: mapWidth, height: mapHeight))
        playerNodeInMap = SKShapeNode(rectOf: CGSize(width: playerColSize!, height: playerRowSize!))
        playerNodeInMap.fillColor = UIColor.green

        mapNode.fillColor = UIColor.black
        mapNode.lineWidth = mapColSize
        mapNode.strokeColor = UIColor.brown
        
        let mapCenterX = screenSize.width - 0.5 * mapWidth - 0.05 * screenSize.width
        let mapCenterY = screenSize.height - 0.5 * mapHeight - 0.05 * screenSize.height
        mapOriginX = screenSize.width - mapWidth - 0.05 * screenSize.width
        mapOriginY = screenSize.height - mapHeight - 0.05 * screenSize.height
        
        mapNode.position.x = mapCenterX
        mapNode.position.y = mapCenterY
        
        self.addChild(mapNode)
        
        playerNodeInMap.position.x = mapOriginX + mapColSize * CGFloat(playerLoc.column)
        playerNodeInMap.position.y = mapOriginY + mapRowSize * CGFloat(playerLoc.row)
        self.addChild(playerNodeInMap)
        ringAroundPlayer = SKShapeNode(circleOfRadius: mapHeight * 0.10)
        ringAroundPlayer.position.x = playerNodeInMap.position.x
        ringAroundPlayer.position.y = playerNodeInMap.position.y
        ringAroundPlayer.fillColor = UIColor.clear
        ringAroundPlayer.strokeColor = UIColor.white
        self.addChild(ringAroundPlayer)
        
        // add all the parts in the scene to the map to give the player a layout of the objectives.
        let partRowSize = mapRowSize
        let partColSize = mapColSize
        for (aPartName, aPart) in parts {
            partsInMap[aPartName] = SKShapeNode(rectOf: CGSize(width: partColSize!, height: partRowSize!))
            partsInMap[aPartName]?.position.x = mapOriginX + mapColSize * CGFloat(aPart.levelCoords.column)
            partsInMap[aPartName]?.position.y = mapOriginY + mapRowSize * CGFloat(aPart.levelCoords.row)
            partsInMap[aPartName]?.name = aPartName
            partsInMap[aPartName]?.fillColor = UIColor.yellow
            partsInMap[aPartName]?.strokeColor = UIColor.yellow
            self.addChild(partsInMap[aPartName]!)
        }
        
        if theLevel.levelNumber < highestLevelNumber {
            addExitToMap(theLevel: theLevel)
        }
        else {
            addVaultToMap(theLevel: theLevel)
        }
    }
 
    // Note: mapRowSize, mapColSize, mapOriginX, mapOriginY must be set before this function is called.  Otherwise
    // we get a screwed up placement and size for the vault.
    func addVaultToMap(theLevel: Level) {
        let vaultRowSize = mapRowSize
        let vaultColSize = mapColSize
        // make the vault big
        let vaultWidth = CGFloat(vaultColSize! * 10.0)
        let vaultHeight = CGFloat(vaultRowSize! * 3.0)

        let vaultNode = SKShapeNode(rectOf: CGSize(width: vaultWidth, height: vaultHeight))
        vaultNode.fillColor = UIColor.yellow
        
        // We put the vault in a fixed position, right in the middle of the far wall.
        vaultNode.position.x = mapOriginX + 0.5 * mapWidth
        vaultNode.position.y = mapOriginY + mapHeight
        self.addChild(vaultNode)
    }
    
    // Note: mapRowSize, mapColSize, mapOriginX, mapOriginY must be set before this function is called.  Otherwise
    // we get a screwed up placement and size for the exit.
    func addExitToMap(theLevel: Level) {
        let exitRowSize = mapRowSize
        let exitColSize = mapColSize
        var exitWidth: CGFloat = exitColSize!
        var exitHeight: CGFloat = exitRowSize!
        // make the exit twice the size of the row or column, depending on whether it is on the right/left wall or
        // in the far wall.  We do this to make it easier to see on the map.
        exitWidth *= 4.0
        exitHeight *= 2.0
        let exitNode = SKShapeNode(rectOf: CGSize(width: exitWidth, height: exitHeight))
        exitNode.fillColor = UIColor.yellow
        
        exitNode.position.x = mapOriginX + mapColSize * CGFloat(theLevel.levelExitPoint.column)
        
        // No need to offset in the y direction since the near and far walls are only one row thick.
        exitNode.position.y = mapOriginY + mapRowSize * CGFloat(theLevel.levelExitPoint.row)     // The 0.5 * rowSize is the middle of the exit
        self.addChild(exitNode)
    }
    
    func updatePlayerInMap(playerLoc: LevelCoordinates) {
        playerNodeInMap.position.x = mapOriginX + mapColSize * CGFloat(playerLoc.column)
        playerNodeInMap.position.y = mapOriginY + mapRowSize * CGFloat(playerLoc.row)
        ringAroundPlayer.position.x = playerNodeInMap.position.x
        ringAroundPlayer.position.y = playerNodeInMap.position.y
    }
    
    // Remove a part--for when a player has picked it up.
    func removePartFromMap(partName: String) {
        partsInMap[partName]?.removeFromParent()
    }
    
    // show power up achieved by showing the player what he/she has just picked up.
    func showPowerUpAchieved(powerUp: PowerUp) {
        let powerUpLoc: CGPoint = CGPoint(x: CGFloat(screenSize.width * powerUpMessageXOffsetFromScreenCenter), y: CGFloat(screenSize.height * powerUpMessageYOffsetFromScreenCenter))
        
        let powerUpLabelNode = SKLabelNode(fontNamed: "Damascus")
        powerUpLabelNode.text = powerUp.powerUpText
        powerUpLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.center
        powerUpLabelNode.verticalAlignmentMode = SKLabelVerticalAlignmentMode.center
        powerUpLabelNode.fontSize = 15
        powerUpLabelNode.fontColor = SKColor.white
        powerUpLabelNode.position = powerUpLoc
        
        let fadeAction = SKAction.fadeOut(withDuration: 3.0)
        let removeAction = SKAction.removeFromParent()
        let fadeSequence = SKAction.sequence([fadeAction, removeAction])
        self.addChild(powerUpLabelNode)
        powerUpLabelNode.run(fadeSequence)
    }
    
    // show part gathered by showing the player what he/she has just picked up.
    func showPartGathered(part: PartInLevel) {
        let partName = part.prizeAssociatedWithPart.prizeName
        let partLoc: CGPoint = CGPoint(x: CGFloat(screenSize.width * partMessageXOffsetFromScreenCenter), y: CGFloat(screenSize.height * partMessageYOffsetFromScreenCenter))
        let partLabelNode = SKLabelNode(fontNamed: "Damascus")
        partLabelNode.text = partName + " " + partLabel
        partLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.center
        partLabelNode.verticalAlignmentMode = SKLabelVerticalAlignmentMode.center
        partLabelNode.fontSize = 15
        partLabelNode.fontColor = SKColor.yellow
        partLabelNode.position = partLoc
        
        let fadeAction = SKAction.fadeOut(withDuration: 3.0)
        let removeAction = SKAction.removeFromParent()
        let fadeSequence = SKAction.sequence([fadeAction, removeAction])
        self.addChild(partLabelNode)
        partLabelNode.run(fadeSequence)
    }

    func showTutorialStep(step: TutorialStep, playerX: Float, exitX: Float) {
        // the tutorialStepLabel should have been set up elsewhere so if it doesn't exist
        // then we don't do anything.  If it does, we use it to display the tutorial step.
        if tutorialStepLabel != nil {
            if step.stepType != .notype {
                let location = CGPoint(x: CGFloat(screenSize.width * step.loc2D.x), y: CGFloat(screenSize.height * step.loc2D.y))
                tutorialStepLabel.position = location
                tutorialStepLabel.text = step.stepName
                tutorialStepLabel.fontColor = SKColor.white
                tutorialStepLabel.alpha = 1.0       // after a run of this function the alpha is set to 0.0 because of the
                // fadeOut action so if we want to to actually display another label,
                // and we do, we need to reset the alpha to 1.0
                
                let fadeAction = SKAction.fadeOut(withDuration: step.durationOfStep)
                let removeAction = SKAction.removeFromParent()
                let fadeSequence = SKAction.sequence([fadeAction, removeAction])
                self.addChild(tutorialStepLabel)
                
                // note: we set a 'hasArrow' flag to true in the Tutorial initiation.  Here we determine the arrow direction
                // and placement around text.
                switch step.stepType {
                case .swipeup:
                    tutorialStep2DArrow.alpha = 1.0   // after a run of this function the alpha is set to 0.0 because of the fadeOut function.
                                                      // so we have to set it each time
                    tutorialStep2DArrow.position = tutorialStepLabel.position
                    tutorialStep2DArrow.position.y += screenSize.height * 0.15
                    tutorialStep2DArrow.fillTexture = allModelsAndMaterials.twoDUpArrowIcon
                    self.addChild(tutorialStep2DArrow)
                    tutorialStep2DArrow.run(fadeSequence)
                case .swipeleft:
                    tutorialStep2DArrow.alpha = 1.0   // after a run of this function the alpha is set to 0.0 because of the fadeOut function.
                    // so we have to set it each time
                    tutorialStep2DArrow.position = tutorialStepLabel.position
                    tutorialStep2DArrow.position.x -= screenSize.width * 0.15
                    tutorialStep2DArrow.fillTexture = allModelsAndMaterials.twoDLeftArrowIcon
                    self.addChild(tutorialStep2DArrow)
                    tutorialStep2DArrow.run(fadeSequence)
                case .swipedown:
                    tutorialStep2DArrow.alpha = 1.0   // after a run of this function the alpha is set to 0.0 because of the fadeOut function.
                    // so we have to set it each time
                    tutorialStep2DArrow.position = tutorialStepLabel.position
                    tutorialStep2DArrow.position.y -= screenSize.height * 0.15
                    tutorialStep2DArrow.fillTexture = allModelsAndMaterials.twoDDownArrowIcon
                    self.addChild(tutorialStep2DArrow)
                    tutorialStep2DArrow.run(fadeSequence)
                case .swiperight:
                    tutorialStep2DArrow.alpha = 1.0   // after a run of this function the alpha is set to 0.0 because of the fadeOut function.
                    // so we have to set it each time
                    tutorialStep2DArrow.position = tutorialStepLabel.position
                    tutorialStep2DArrow.position.x += screenSize.width * 0.15
                    tutorialStep2DArrow.fillTexture = allModelsAndMaterials.twoDRightArrowIcon
                    self.addChild(tutorialStep2DArrow)
                    tutorialStep2DArrow.run(fadeSequence)
                case .gotoexit:
                    tutorialStep2DArrow.alpha = 1.0   // after a run of this function the alpha is set to 0.0 because of the fadeOut function.
                    // so we have to set it each time
                    tutorialStep2DArrow.position = tutorialStepLabel.position
                    if abs(exitX - playerX) <= exitXNearPlayerX {
                        tutorialStep2DArrow.position.y += screenSize.height * 0.15
                        tutorialStep2DArrow.fillTexture = allModelsAndMaterials.twoDUpArrowIcon
                    }
                    else if exitX - playerX <= exitXUpRightOfPlayerX && exitX - playerX > exitXNearPlayerX {
                        tutorialStep2DArrow.position.y += screenSize.height * 0.10
                        tutorialStep2DArrow.position.x += screenSize.width * 0.10
                        tutorialStep2DArrow.fillTexture = allModelsAndMaterials.twoDUpRightArrowIcon
                    }
                    else if exitX - playerX > exitXUpRightOfPlayerX {
                        tutorialStep2DArrow.position.x += screenSize.width * 0.15
                        tutorialStep2DArrow.fillTexture = allModelsAndMaterials.twoDRightArrowIcon
                    }
                    else if exitX - playerX >= exitXUpLeftOfPlayerX && exitX - playerX < -exitXNearPlayerX {
                        tutorialStep2DArrow.position.y += screenSize.height * 0.10
                        tutorialStep2DArrow.position.x -= screenSize.width * 0.10
                        tutorialStep2DArrow.fillTexture = allModelsAndMaterials.twoDUpLeftArrowIcon
                    }
                    else if exitX - playerX < exitXUpLeftOfPlayerX {
                        tutorialStep2DArrow.position.x -= screenSize.width * 0.15
                        tutorialStep2DArrow.fillTexture = allModelsAndMaterials.twoDLeftArrowIcon
                    }
                    self.addChild(tutorialStep2DArrow)
                    tutorialStep2DArrow.run(fadeSequence)
                default:
                    break
                }
                
                tutorialStepLabel.run(fadeSequence)
            }
            // else the step should be a go to location type step and we handle that in the 3D scene, not in this 2D
            // control panel.
        }
    }
    
    // show the collect parts tutorial step explicitly.  Note: the step is essentially the first
    // gotopart step.  Whether or not it is completed doesn't matter as we just need the type and the location
    // as all of the part steps will have the same for those.
    func showCollectPartsTutorialStep() {
        if tutorialStepLabel != nil {
            //let location = CGPoint(x: CGFloat(screenSize.width * step.loc2D.x), y: CGFloat(screenSize.height * step.loc2D.y))
            // explicitly set the location here.  Yes, it's hardcoded but we set it just once for all the part.
            let location = CGPoint(x: CGFloat(screenSize.width * defaultStepLoc2D.x), y: CGFloat(screenSize.height * defaultStepLoc2D.y))
            tutorialStepLabel.position = location
            // special case - we replace the text wtih a specific text because if it's a part then the part number
            // will be the text for the step name.
            tutorialStepLabel.text = "Collect parts"
            tutorialStepLabel.fontColor = SKColor.white
            tutorialStepLabel.alpha = 1.0       // after a run of this function the alpha is set to 0.0 because of the
            // fadeOut action so if we want to to actually display another label,
            // and we do, we need to reset the alpha to 1.0
            
            let fadeAction = SKAction.fadeOut(withDuration: defaultStepDuration)    // also hardcoded.  Didn't want to do it, but this is the simplest way to finish this.
            let removeAction = SKAction.removeFromParent()
            let fadeSequence = SKAction.sequence([fadeAction, removeAction])
            self.addChild(tutorialStepLabel)
            tutorialStepLabel.run(fadeSequence)
        }

    }
    
    func isShowTutorialStepInProgress () -> Bool {
        var isInProgress: Bool = false

        // note: the condition below handles both tap and non-tap tutorial steps because by
        // definition the tutorialTapTargetAreaNode will not have any actions if the step is not
        // a tap.
        if tutorialStepLabel?.hasActions() == true || tutorialStep2DArrow?.hasActions() == true {
            isInProgress = true
        }
        return isInProgress
    }
    
    func showVaultBarrierOffMessage() {
        // put vault opened message in the center of the screen.
        let vaultOpenedMessageLoc: CGPoint = CGPoint(x: CGFloat(screenSize.width / 2.0), y: CGFloat(screenSize.height / 2.0))
        
        let vaultOpenedMessageNode = SKLabelNode(fontNamed: "Damascus")
        vaultOpenedMessageNode.text = "Vault Force Field off!"
        vaultOpenedMessageNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.center
        vaultOpenedMessageNode.verticalAlignmentMode = SKLabelVerticalAlignmentMode.center
        vaultOpenedMessageNode.fontSize = 20
        vaultOpenedMessageNode.fontColor = SKColor.yellow
        vaultOpenedMessageNode.position = vaultOpenedMessageLoc
        let fadeAction = SKAction.fadeOut(withDuration: showVaultUnlockedMessageDuration)
        let removeAction = SKAction.removeFromParent()
        let fadeSequence = SKAction.sequence([fadeAction, removeAction])
        self.addChild(vaultOpenedMessageNode)
        vaultOpenedMessageNode.run(fadeSequence)
    }
    
    // If the player has selected the motion detector then we want to display the ai robots in
    // the map and make them red.
    func addAIRobotsToMap(theLevel: Level, aiRobots: [String : Robot], motionDetectorUsed: Bool) {
        // Before adding robots, double check that the player actually selected the motion detector to use in the level
        // It's a little inefficient because we've likely checked before calling this function but it doesn't hurt much
        // to check again.
        if motionDetectorUsed == true {
            for (name, robot) in aiRobots {
                // Assume mapRowSize and mapColSize were already assigned when the drawMap() function
                // was called, which should have happened before this function was ever called.
                
                let aiRobotRowSize = mapRowSize
                let aiRobotColSize = mapColSize
                
                let oneAIRobotNodeInMap = SKShapeNode(rectOf: CGSize(width: aiRobotColSize!, height: aiRobotRowSize!))
                
                oneAIRobotNodeInMap.fillColor = UIColor.red
                oneAIRobotNodeInMap.strokeColor = UIColor.red
                oneAIRobotNodeInMap.position.x = mapOriginX + mapColSize * CGFloat(robot.levelCoords.column)
                oneAIRobotNodeInMap.position.y = mapOriginY + mapRowSize * CGFloat(robot.levelCoords.row)
                aiRobotsInMap[name] = oneAIRobotNodeInMap
                self.addChild(oneAIRobotNodeInMap)

            }
        }
        aiRobotsAddedToMap = true  // let control panel know that the robots were added.  That way we know that they can be updated later.
    }
    
    func updateAIRobotsInMap(aiRobots: [String : Robot], motionDetectorUsed: Bool) {
        // Before updating robots, double check that the player actually selected the motion detector to use in the level
        // It's a little inefficient because we've likely checked before calling this function but it doesn't hurt much
        // to check again.
        if motionDetectorUsed == true && aiRobotsAddedToMap == true {
            for (name, robot) in aiRobots {
                aiRobotsInMap[name]?.position.x = mapOriginX + mapColSize * CGFloat(robot.levelCoords.column)
                aiRobotsInMap[name]?.position.y = mapOriginY + mapRowSize * CGFloat(robot.levelCoords.row)
            }
        }
    }
    
    // Remover a robot from the map - presumably when it has been destroyed.
    func removeAIRobotFromMap(aiRobotName: String) {
        aiRobotsInMap[aiRobotName]?.removeFromParent()
    }
    
    func fadeOutScene(duration: Double) {
        // It seems weired but we're actually fading 'in' the screenCover, which is black but has 0.0 alpha.
        // Fading it in means changing the alpha to 1.0, essentially making the whole screen black.
        let fadeInAction = SKAction.fadeIn(withDuration: duration)
        screenCover.run(fadeInAction)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}
