//
//  GameNameOverlay.swift
//  RobotRaider
//
//  Created by Nathanael Bills on 9/5/18.
//  Copyright © 2018 invasivemachines. All rights reserved.
//

import Foundation
import SpriteKit

class IntroFadeSequenceOverlay: SKScene {
    var gameNameNode: SKSpriteNode = SKSpriteNode(imageNamed: "components.scnassets/intro3dtext1.png")
    var screenBlackOut: SKShapeNode!
    var screenSize: CGSize!
    
    override init(size: CGSize) {
        super.init(size: size)
        
        // Sigh.  It appears that setting the orientation to landscape doesn't change what iOS thinks is the width and height of the screen.  It still
        // treats it like it's in portrait mode in terms of width and height.  However, this only happens with some devices, like iPhones.  With iPads,
        // particularly the iPad Pro the values are correct after the switch to landscape orientation.  So rather than try to anticipate every
        // possible result we fudge and say that the larger value is always the width and the smaller value is always the height because the game
        // is only in landscape mode.

        self.scaleMode = .resizeFill   // automatically resize screen to whatever screen size the device has.
        // Still might need to adjust game logic and art assets to match different sizes.

        if size.height > size.width {
            screenSize = CGSize(width: size.height, height: size.width)
        }
        else {
            screenSize = size
        }
        
        gameNameNode.position = CGPoint(x: 0.50 * screenSize.width, y: screenSize.height - 0.30 * screenSize.height)
        gameNameNode.size = CGSize(width: 0.95 * screenSize.width, height: 0.45 * screenSize.height)
        self.addChild(gameNameNode)
        screenBlackOut = SKShapeNode(rectOf: CGSize(width: screenSize.width, height: screenSize.height))
        screenBlackOut.fillColor = SKColor.black
        screenBlackOut.strokeColor = SKColor.black
        screenBlackOut.position = CGPoint(x: 0.50 * screenSize.width, y: 0.50 * screenSize.height)
        screenBlackOut.alpha = 1.0
        self.addChild(screenBlackOut)
    
    }
    
    // fade name from the scene and remove it.
    func fadeOutName(wait: Double, duration: Double) {
        let waitAction = SKAction.wait(forDuration: wait)
        let fadeOutAction = SKAction.fadeOut(withDuration: duration)
        let removeAction = SKAction.removeFromParent()
        let fadeSequence = SKAction.sequence([waitAction, fadeOutAction, removeAction])
        gameNameNode.run(fadeSequence)
    }
    
    // fade out the black cover over the scene, wait, and then bring the black covering back as the
    // intro ends.
    func fadeOutInScreenBlackOut(outDuration: Double, wait: Double, inDuration: Double) {
        let fadeOutAction = SKAction.fadeOut(withDuration: outDuration)
        let waitAction = SKAction.wait(forDuration: wait)
        let fadeInAction = SKAction.fadeIn(withDuration: inDuration)
        let fadeSequence = SKAction.sequence([fadeOutAction, waitAction, fadeInAction])
        screenBlackOut.run(fadeSequence)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
