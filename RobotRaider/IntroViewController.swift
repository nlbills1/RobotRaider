//
//  IntroViewController.swift
//  RobotRaider
//
//  Created by Nathanael Bills on 9/3/18.
//  Copyright © 2018 invasivemachines. All rights reserved.
//

import Foundation
import SceneKit

// Our intro scene is created here.  Note that we set up everything here from scratch
// because this is the only place where we use most of what's in this class.  The only exception
// to that will be the player robot.  Even the player robot's movement sound is just used here
// because we've found that playing continuous audio crashes the game when the node associated with
// that continuous sound is removed from the game (as a robot would be when destroyed).  That's
// not a problem here as everything is involved in an animation with a set beginning and end.
class IntroViewController: UIViewController {
    
    var introFadeSequenceOverlay: IntroFadeSequenceOverlay!
    var sceneView: SCNView!
    var screenSize: CGSize!
    var primaryCam: SCNNode!
    var ground: SCNNode!
    var road: SCNNode!
    var roadEdge: SCNNode!
    var bakeryModel: SCNNode!
    
    // player robot model
    var robotNode: SCNNode!
    var robotBodyNode: SCNNode!
    var launcherNode: SCNNode!
    var leftWheelNode: SCNNode!
    var rightWheelNode: SCNNode!

    var introRunTimer: Timer!               // timer for how long the intro runs until an end and then transition to
                                            // the level select screen if the player hasn't tapped on the screen to bypass the intro.
    
    // prefer to hide the status bar, which interferes with the experience.
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NodeSound.regularSpeed?.load()      // make sure to preload the regular speed audio to avoid lag.
        //gameSounds.sounds[.crickets]?.prepareToPlay()  // preload the sound just before playing to get rid of odd lag at beginning of intro.
        //gameSounds.playSound(soundToPlay: .crickets)
        createScene()
        introRunTimer = Timer.scheduledTimer(timeInterval: 12.0, target: self, selector: #selector(goToLevelSelect), userInfo: nil, repeats: false)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        sceneView.alpha = 1.0 
        introFadeSequenceOverlay.fadeOutName(wait: 3.0, duration: 3.0)
        introFadeSequenceOverlay.fadeOutInScreenBlackOut(outDuration: 0.5, wait: 7.0, inDuration: 3.0)
    }
    
    func createScene() {
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

        self.view.backgroundColor = UIColor.black       // we set the entire view's background to black because all the other subviews will fade in from black.

        sceneView = SCNView(frame: self.view.frame)
        sceneView.antialiasingMode = SCNAntialiasingMode.multisampling4X    // default is 'none' in iOS
        
        sceneView.alpha = 0.0               // invisible at the start but we fade it in later.
        sceneView.backgroundColor = UIColor.black
        sceneView.isUserInteractionEnabled = true  // make sure user interaction is enabled for the view.
        self.view.addSubview(sceneView)
        sceneView.scene = SCNScene()
        sceneView.overlaySKScene = IntroFadeSequenceOverlay(size: screenSize)
        introFadeSequenceOverlay = sceneView.overlaySKScene as? IntroFadeSequenceOverlay
        
        // Add tap gesture for handling a tap to skip the intro.
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(GamePlayViewController.tapDetected))
        sceneView.addGestureRecognizer(tapRecognizer)
        
        let camera = SCNCamera()
        camera.zFar = 2000
        camera.zNear = 0.1         // According to the documentation, zNear can't be zero.  But it doesn't say it can't be close.
        primaryCam = SCNNode()
        primaryCam.camera = camera
        primaryCam.camera?.fieldOfView = wideAngleCameraLens
        primaryCam.position = SCNVector3Zero
        primaryCam.position.y = 10.0
        
        sceneView.scene?.rootNode.addChildNode(primaryCam)
        createGround()
        sceneView.scene?.rootNode.addChildNode(ground)
        createRoad()
        sceneView.scene?.rootNode.addChildNode(road)
        sceneView.scene?.rootNode.addChildNode(roadEdge)
        
        let bakeryScene = SCNScene(named: "components.scnassets/bakery10.dae")
        bakeryModel = bakeryScene?.rootNode.childNodes[0]
        bakeryModel.position = SCNVector3(x: -0.8, y: 28.0, z: -150.0)
        sceneView.scene?.rootNode.addChildNode(bakeryModel)
        
        createRobot()
        robotNode.position = SCNVector3(x: 0.0, y: 2.5, z: 20.0)
        robotNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: nil)
        robotNode.physicsBody?.velocity = SCNVector3(x: 0.0, y: 0.0, z: -defaultPlayerRobotMovingSpeed)
        let goToBakeryAction = SCNAction.move(to: SCNVector3(x: 0.0, y: 2.5, z: -130.0), duration: 10.0)
        sceneView.scene?.rootNode.addChildNode(robotNode)
        robotNode.runAction(goToBakeryAction)
    }
    
    func fadeIn(view: UIView, duration: Double, delay: Double = 0.0) {
        UIView.animate(withDuration: duration, delay: delay, options: [.curveEaseInOut], animations: {
            view.alpha = 1.0
        })
    }
    
    func fadeOut(view: UIView, duration: Double, delay: Double = 0.0) {
        UIView.animate(withDuration: duration, delay: delay, options: [.curveEaseInOut], animations: {
            view.alpha = 0.0
        })
    }
    
    func createGround() {
        let groundGeometry = SCNFloor()
        groundGeometry.reflectivity = 0.0
        let groundMaterial = SCNMaterial()
        groundMaterial.diffuse.contents = UIColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1.0)
        groundMaterial.multiply.contents = UIColor.gray
        ground = SCNNode(geometry: groundGeometry)
        
        ground.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        ground.physicsBody!.categoryBitMask = collisionCategoryGround
        ground.physicsBody!.collisionBitMask =   collisionCategoryPlayerRobot
        ground.geometry?.firstMaterial = groundMaterial
        ground.name = groundLabel
        ground.position = SCNVector3Zero    // this is the default but we explicitly set it to be sure.
    }
    
    func createRoad() {
        let roadGeometry = SCNPlane(width: 6.0, height: 1000.0)
        let roadMaterial = SCNMaterial()
        roadMaterial.diffuse.contents = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        road = SCNNode(geometry: roadGeometry)
        road.geometry?.firstMaterial = roadMaterial
        road.position = SCNVector3Zero
        road.position.y += 0.2    // make it slightly higher than the road edge below so we can see it.
        road.position.z -= 450.0
        road.rotation = SCNVector4(1.0, 0.0, 0.0, -Double.pi/2.0)
        
        let roadEdgeGeometry = SCNPlane(width: 8.0, height: 1000.0)
        let roadEdgeMaterial = SCNMaterial()
        roadEdgeMaterial.diffuse.contents = UIColor.black
        roadEdge = SCNNode(geometry: roadEdgeGeometry)
        roadEdge.geometry?.firstMaterial = roadEdgeMaterial
        roadEdge.position = SCNVector3Zero
        roadEdge.position.y += 0.1    // make it slightly higher than the ground so we can see it.
        roadEdge.position.z -= 450.0
        roadEdge.rotation = SCNVector4(1.0, 0.0, 0.0, -Double.pi/2.0)
    }
    
    func createRobot() {
        robotNode = SCNNode()
        
        // create the player's robot but as a much simpler version of what we use in the game because we
        // don't need to do anything with it except run an animation -- no interactivity.
        launcherNode = allModelsAndMaterials.launcherModel.clone()
        launcherNode.geometry = allModelsAndMaterials.launcherModel.geometry?.copy() as? SCNGeometry
        launcherNode.geometry?.firstMaterial = allModelsAndMaterials.launcherModel.geometry?.firstMaterial?.copy() as? SCNMaterial
        
        robotBodyNode = allModelsAndMaterials.playerModel.clone()
        // Can't just clone a node. We also have to copy the geometry and material to make them independent
        // copies.  Otherwise what happens to one happens to all others of the same geometry and material.
        robotBodyNode.geometry = allModelsAndMaterials.playerModel.geometry?.copy() as? SCNGeometry
        robotBodyNode.geometry?.firstMaterial = allModelsAndMaterials.playerModel.geometry?.firstMaterial?.copy() as? SCNMaterial
        // Note: the robotNode is composed of the robot body, about 4.2 m in height and
        // the wheels, about 1.6 m in height.  However, because the center of the wheels
        // sit at the bottom of the body the combined height is actually 4.2m + 0.8m for
        // a total height of about 5m.
        robotBodyNode.position.y = 0.8
        launcherNode.position.y = 0.4
        robotNode.addChildNode(robotBodyNode)
        robotNode.addChildNode(launcherNode)
        addWheels(loc: SCNVector3(0.0, -1.4, 0.0))
    }
    
    // copied right from the addWheels() functin in the Robot class and modified for our purposes just for animation.
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
        
        robotNode.addChildNode(leftWheelNode)
        robotNode.addChildNode(rightWheelNode)
        
        turnWheelsAtNormalSpeed()       // just start turning those wheels now.
    }
    
    // get the wheels rolling.  It should happen for all the robots when they're moving.
    //
    func turnWheelsAtNormalSpeed() {
        let speed = CGFloat(defaultPlayerRobotMovingSpeed)
        
        // the normal calculations make the wheel turn too slowly so we fudge and multiply by 1.5
        let turningSpeed = 1.5 * speed / CGFloat(normalWheelCircumference)
        let leftWheelTurnAction = SCNAction.rotateBy(x: 0.0, y: -turningSpeed, z: 0.0, duration: 1.0)
        let leftWheelTurnActionForever = SCNAction.repeatForever(leftWheelTurnAction)
        let leftWheelTurnSequence = SCNAction.sequence([leftWheelTurnActionForever])
        let rightWheelTurnAction = SCNAction.rotateBy(x: 0.0, y: turningSpeed, z: 0.0, duration: 1.0)
        let rightWheelTurnActionForever = SCNAction.repeatForever(rightWheelTurnAction)
        let rightWheelTurnSequence = SCNAction.sequence([rightWheelTurnActionForever])
        
        leftWheelNode.runAction(leftWheelTurnSequence, forKey: leftWheelTurnActionKey)
        rightWheelNode.runAction(rightWheelTurnSequence, forKey: rightWheelTurnActionKey)
        
        let regularSpeedAudioAction = SCNAction.playAudio(NodeSound.regularSpeed!, waitForCompletion: true)
        let repeatSpeedSoundAction = SCNAction.repeat(regularSpeedAudioAction, count: 20)
        let waitAction = SCNAction.wait(duration: 1.5)
        let waitAction2 = SCNAction.wait(duration: 2.5)
        let repeatSoundSequence = SCNAction.sequence([waitAction, repeatSpeedSoundAction])
        let repeatSoundSequence2 = SCNAction.sequence([waitAction2, repeatSpeedSoundAction])
        
        // have to play three staggered auto clips to cover the gaps.  Even then we have to speed up the
        // robot movement to get the robot far away from the player to hid the gap sound.
        robotNode.runAction(repeatSpeedSoundAction, forKey: "1")
        robotNode.runAction(repeatSoundSequence, forKey: "2")
        robotNode.runAction(repeatSoundSequence2, forKey: "3")
    }
    
    @objc func tapDetected(recognizer: UITapGestureRecognizer) {
        // It doesn't matter where the player taps.  If a tap is made, we skip the intro, no matter
        // where we are in it.
        goToLevelSelect()
    }
    
    // go to level select screen now
    @objc func goToLevelSelect() {
        performSegue(withIdentifier: "unwindSegueToLevelSelect", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //gameSounds.stopSound(soundToStop: .crickets)
        sceneView.scene!.rootNode.enumerateChildNodes { (node, stop) in
            node.enumerateHierarchy { (cnode, stop) in
                cnode.removeFromParentNode()
            }
        }
    }
}
