//
//  NodeSound.swift
//  RobotRaider
//
//  Created by Nathanael Bills on 8/9/18.
//  Copyright © 2018 invasivemachines. All rights reserved.
//

import Foundation
import SceneKit
import AudioToolbox.AudioServices

class NodeSound {
    static let launcherturn = SCNAudioSource(fileNamed: "launcherturn3.wav")
    static let puffOfSteam = SCNAudioSource(fileNamed: "puffofsteam.wav")
    //static let zap = SCNAudioSource(fileNamed: "zap4.wav")
    //static let bigZap = SCNAudioSource(fileNamed: "zap5.wav")
    //static let soakUpImpact = SCNAudioSource(fileNamed: "soakimpact.wav")
    //static let recoverFromImpact = SCNAudioSource(fileNamed: "recover3.wav")
    static let splat = SCNAudioSource(fileNamed: "splat4.wav")
    static let fry = SCNAudioSource(fileNamed: "fry1.wav")
    //static let fallandcrash = SCNAudioSource(fileNamed: "fallandcrash.wav")
    //static let pop = SCNAudioSource(fileNamed: "bubblepop3.wav")
    //static let empDischarge = SCNAudioSource(fileNamed: "emp2.wav")
    static let regularSpeed = SCNAudioSource(fileNamed: "regularspeed2.wav")
    //static let bounce = SCNAudioSource(fileNamed: "bounce.wav")
    static let staticDischarge = SCNAudioSource(fileNamed: "static6.wav")
    static let crash = SCNAudioSource(fileNamed: "crash.mp3")
    //static let targetTap = SCNAudioSource(fileNamed: "targettap.mp3")
    static let targetTap = SCNAudioSource(fileNamed: "targettap2.wav")
    
}
