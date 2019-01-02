//
//  Tutorial.swift
//  RobotRaider
//
//  Created by Nathanael Bills on 7/30/18.
//  Copyright © 2018 invasivemachines. All rights reserved.
//

import Foundation
import UIKit
import SceneKit

// game tutorial.  This is created in the game play view controller for every level.  However, it is only created when
// the player has turned it on in level select.  Thus, it doesn't exist unless the player either turns the tutorial
// on or the game is starting for the very first time.
class Tutorial {
    
    let gestureSteps = [
        // Note: the loc2D is actually in terms of percentages rather than actual point locations because the 2D screen
        // can be different sizes on different devices.  By using percentages we eliminate the problem of having to keep
        // track of where to place something in different sized screens.  For the loc3D this isn't a problem as the 3D world
        // is a virtual world and the scene gets translated automatically to the 2D screen without our needing to do any
        // sort of compensating for screen size.  Also note that while UIKit uses a coordinate system where x=0,y=0 is the top
        // left corner of the screen, SpriteKit uses a coordinate system where x=0,y=0 is the bottom left corner of the screen.
        // Why they're different, I have no idea.  The coordinates below are based on the SpriteKit coordinate system.  So
        // y = 0.40 is y = 40% the screen height above 0, or y = screenHeight * 0.40.
        TutorialStep(number: 0, name: "Swipe Up", type: .swipeup, duration: defaultStepDuration, state: .hasnotstartedyet, loc2D: defaultStepLoc2D, loc3D: defaultStepLoc3D, hasArrow: true),
        TutorialStep(number: 1, name: "Swipe Left", type: .swipeleft, duration: defaultStepDuration, state: .hasnotstartedyet, loc2D: defaultStepLoc2D, loc3D: defaultStepLoc3D, hasArrow: true),
        TutorialStep(number: 2, name: "Swipe Down", type: .swipedown, duration: defaultStepDuration, state: .hasnotstartedyet, loc2D: CGPoint(x: 0.70, y: 0.70), loc3D: defaultStepLoc3D, hasArrow: true),
        TutorialStep(number: 3, name: "Swipe Left", type: .swipeleft, duration: defaultStepDuration, state: .hasnotstartedyet, loc2D: defaultStepLoc2D, loc3D: defaultStepLoc3D, hasArrow: true),
        TutorialStep(number: 4, name: "Tap Stop Button", type: .tapstop, duration: defaultStepDuration, state: .hasnotstartedyet, loc2D: CGPoint(x: 0.20, y: 0.20), loc3D: defaultStepLoc3D, hasArrow: false),
        TutorialStep(number: 5, name: "Swipe Right", type: .swiperight, duration: defaultStepDuration, state: .hasnotstartedyet, loc2D: defaultStepLoc2D, loc3D: defaultStepLoc3D, hasArrow: true),
        TutorialStep(number: 6, name: "Tap Anywhere to Fire", type: .taptarget1, duration: defaultStepDuration, state: .hasnotstartedyet, loc2D: CGPoint(x: 0.35, y: 0.40), loc3D: defaultStepLoc3D, hasArrow: false),
    ]
    
    // Note: we give the go to exit step an initial number that must be changed later to accommodate it being
    // the last step, after all the parts have been picked up.  But we have to give it a number here to initialize
    // it.
    
    var allTutorialSteps: [TutorialStep] = []
    var allTutorialStepsByName: [String : TutorialStep] = [ : ]
    
    var partTutorialStepNodes: [String : SCNNode] = [ : ]
    
    var currentStepInTutorial: Int = 0          // this keeps track of where the player is in the tutorial.
    
    var partsTutorialStepsAddedToScene: Bool = false        // track whether or not the steps to pick up parts have been added to the scene.  This is used
                                                            // to prevent us from adding them into the scene multiple times.
    
    init (parts: [String : PartInLevel], exitLoc: SCNVector3) {
        // Note: these are the steps in order.  First we want the player to go through the gesture steps, then
        // the steps to pick up all the parts, and finally the go to exit step.  If we want, we could later add
        // steps to pick up power ups but at this point we will let the player discover those.
        addGestureStepsToAllTutorialSteps()
        addPartsPickupStepsToAllTutorialSteps(parts: parts)
        addGoToExitStep(exitLoc: exitLoc)
        currentStepInTutorial = 0       // this is the default start but we also set it here just to be safe.
    }
    
    func addGestureStepsToAllTutorialSteps() {
        for stepNum in 0...gestureSteps.count - 1 {
            allTutorialSteps.append(gestureSteps[stepNum])
            allTutorialStepsByName[gestureSteps[stepNum].stepName] = gestureSteps[stepNum]
        }
    }
    
    func addPartsPickupStepsToAllTutorialSteps(parts: [String : PartInLevel]) {
        var currentStepNumber: Int = gestureSteps.count     // note: for gestures, the numbers go 0 - gestureSteps.count - 1.
        
        for (partName,part) in parts {
            let step = TutorialStep(number: currentStepNumber, name: partName, type: .gotopart, duration: defaultStepDuration, state: .hasnotstartedyet, loc2D: CGPoint(x: 0.0, y: 0.0), loc3D: part.partNode.position, hasArrow: true)
            allTutorialSteps.append(step)
            allTutorialStepsByName[step.stepName] = step
            currentStepNumber += 1
        }
    }
    
    // Add to the scene the tutorial steps to pick up the parts.  Also mark those steps as being in progress, because
    // they are at this point.
    func addPartsPickupStepsToSceneOnlyOnceAndSetStateToInProgress(sceneView: SCNView, parts: [String : PartInLevel]) {
        if partsTutorialStepsAddedToScene == false {
            for step in allTutorialSteps {
                if step.stepType == .gotopart {
                    // if player has picked up some parts already, which can happen even accidentally, mark those steps as already completed.
                    if parts[step.stepName]?.partAlreadyPickedUp == true {
                        let stepNum = getStepNumberByName(stepName: step.stepName)
                        allTutorialSteps[stepNum].stepState = .completed
                    }
                    else {  // otherwise, add pointer to part to pick up and mark as .inprogress
                        let partTutorialArrowNode = allModelsAndMaterials.threeDArrowModel.clone()
                        partTutorialArrowNode.geometry = allModelsAndMaterials.threeDArrowModel.geometry?.copy() as? SCNGeometry
                        partTutorialArrowNode.geometry?.firstMaterial = allModelsAndMaterials.threeDArrowModel.geometry?.firstMaterial?.copy() as? SCNMaterial
                        partTutorialArrowNode.position = step.loc3D
                        partTutorialArrowNode.position.y += 3.0
                        partTutorialArrowNode.name = tutorialLabel + " " + step.stepName
                        
                        let makeArrowVisible = SCNAction.customAction(duration: 0.0, action: { _,_ in
                            partTutorialArrowNode.opacity = 1.0    // make it visible -- it will fade over and over again so we need to make it visible over and over again.
                        })
                        let fadeArrow = SCNAction.fadeOut(duration: step.durationOfStep)
                        let fadeSequence = SCNAction.sequence([makeArrowVisible, fadeArrow])
                        let repeatFadeSquence = SCNAction.repeatForever(fadeSequence)
                        
                        sceneView.scene?.rootNode.addChildNode(partTutorialArrowNode)
                        partTutorialStepNodes[step.stepName] = partTutorialArrowNode
                        partTutorialArrowNode.runAction(repeatFadeSquence)
                        // don't forget to mark each gotopart step as in progress.  We're doing this enmass because at this
                        // point picking up all the parts is one big tutorial step, chopped up into pieces.
                        let stepNum = getStepNumberByName(stepName: step.stepName)
                        allTutorialSteps[stepNum].stepState = .inprogress
                    }
                }
            }
            partsTutorialStepsAddedToScene = true
        }
    }
    
    func removePartPickupStepFromSceneAndMarkStepDone(stepName: String) {
        if partTutorialStepNodes[stepName] != nil {
            partTutorialStepNodes[stepName]?.removeFromParentNode()
            let stepNum = getStepNumberByName(stepName: stepName)
            allTutorialSteps[stepNum].stepState = .completed
        }
    }
    
    //Going to the exit is always the last step of the tutorial.  Always.
    func addGoToExitStep(exitLoc: SCNVector3) {
        let lastStep = allTutorialSteps.count - 1
        let goToExitStep: TutorialStep = TutorialStep(number: lastStep, name: goToExitLabel, type: .gotoexit, duration: defaultStepDuration, state: .hasnotstartedyet, loc2D: defaultStepLoc2D, loc3D: exitLoc, hasArrow: true)
        allTutorialSteps.append(goToExitStep)
        allTutorialStepsByName[goToExitStep.stepName] = goToExitStep
    }
    
    func getCurrentTutorialStep() -> TutorialStep {
        if currentStepInTutorial >= allTutorialSteps.count {
            currentStepInTutorial = allTutorialSteps.count - 1      // cap the steps at the last step, always, to prevent crash.  Since that is the go-to-exit step,
                                                                    // this reasonably makes sense.
        }
        let currentTutorialStep = allTutorialSteps[currentStepInTutorial]
        return currentTutorialStep
    }
    
    // The name and type are what non-tutorial functions will use as reference.  For example,
    // a function in the game play view controller class would update the tutorial by sending
    // the name and maybe the type of tutorial step just performed.  Then based on where that
    // step is in the sequence, the tutorial will either advance to the next step, or not, if
    // it turns out that that step is out of sequence, or is repeated again.
    func getStepNumberByName(stepName: String) -> Int {
        let stepNum = allTutorialStepsByName[stepName]!.stepNumber
        
        return stepNum
    }
    
    // we need this to tell us when we can start pointing out parts to pick up.  Before
    // we can do that all the gesture steps have to be done.
    func areAllTheGestureStepsDone() -> Bool {
        var allGesturesDone: Bool = true
        for aTutorialStep in allTutorialSteps {
            if aTutorialStep.stepType != .gotopart && aTutorialStep.stepType != .gotoexit && aTutorialStep.stepType != .notype && aTutorialStep.stepState != .completed {
                allGesturesDone = false
            }
        }
        return allGesturesDone
    }
    
    // check to see if all the parts have been gathered.  We need this to be able to
    // tell if the player should go to the exit next.
    func haveAllPartsBeenGathered() -> Bool {
        var allPartsGathered: Bool = true
        
        for aTutorialStep in allTutorialSteps {
            if aTutorialStep.stepType == .gotopart && aTutorialStep.stepState != .completed {
                allPartsGathered = false
            }
        }
        return allPartsGathered
    }
    
    // we use this to set a specific state, most often the inprogress state.
    func setCurrentStepState(state: TutorialStepState) {
        allTutorialSteps[currentStepInTutorial].stepState = state
    }
    
    func completedGestureStep(type: TutorialStepType) {
        // gesture steps must be completed step-by-step so if the step doesn't match the current step, we do nothing.
        if currentStepInTutorial < gestureSteps.count && type == allTutorialSteps[currentStepInTutorial].stepType {
            allTutorialSteps[currentStepInTutorial].stepState = .completed
            currentStepInTutorial += 1
        }
    }

    func completedGoToStep(type: TutorialStepType, stepName: String) {
        let stepNum = getStepNumberByName(stepName: stepName)
        // gesture steps must be completed step-by-step
        
        if type == .gotoexit {
            // the go to exit step is done.  Realistically, this probably will never be executed as the game will
            // already be on its way back to the level select screen but we put it here for completeness, and
            // in case we actually do use it for something.
            allTutorialSteps[allTutorialSteps.count - 1].stepState = .completed
        }
        else if type == .gotopart {  // otherwise if the type is a gotopart, then it's a part that was just picked up.
            // if step is any step below the exit step, then mark it as completed.
            if stepNum < allTutorialSteps.count - 1 {
                // mark part has having been picked up; that means marking that step
                // as having been done.
                allTutorialSteps[stepNum].stepState = .completed
            }
        }
        // else do nothing - this should never be the case if this function is called.
    }
    
    // use this fast foward function when all the parts have been gathered.  Since the parts
    // can be gathered in a haphazard fashion we have to fast forward to the last step once
    // they have all been collected.  Otherwise the current step is wrong.
    func fastForwardToGoToExitStep() {
        currentStepInTutorial = allTutorialSteps.count - 1
    }
}
