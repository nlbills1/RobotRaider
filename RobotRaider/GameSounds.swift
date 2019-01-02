//
//  GameSound.swift
//  RobotRaider
//
//  Created by Nathanael Bills on 8/7/18.
//  Copyright © 2018 invasivemachines. All rights reserved.
//

import Foundation
import SceneKit
import AVFoundation

// general game sounds either played once, in the background or used with
// the player robot in certain circumstances, like when it is rammed by an ai
// robot or when player picks up a power up or part.
class GameSounds {
    
    var sounds: [GameSoundType : AVAudioPlayer] = [ : ]
    
    init () {
        
        // load galactic echo sound that we got from GarageBand
        /*
        let levelIntroGalacticEchoPath = Bundle.main.path(forResource: "levelentry1", ofType: "mp3")
        let levelIntroGalacticEchoURL = URL(fileURLWithPath: levelIntroGalacticEchoPath!)
        do {
            sounds[.levelentry] = try AVAudioPlayer(contentsOf: levelIntroGalacticEchoURL)
        } catch {
            // failed to load galactic echo sound.
        }
        */

        //let buttonTapPath = Bundle.main.path(forResource: "buttontap", ofType: "mp3")
        let buttonTapPath = Bundle.main.path(forResource: "buttontap2", ofType: "wav")
        let buttonTapURL = URL(fileURLWithPath: buttonTapPath!)
        do {
            sounds[.buttontap] = try AVAudioPlayer(contentsOf: buttonTapURL)
        } catch {
            // failed to load button tap sound.
        }
        
        // it's not really game over, just that the player's robot was destroyed but this
        // was the only name we could think to give it.  It's from the movie Aliens.
        /*
        let gameOverManPath = Bundle.main.path(forResource: "gameoverman", ofType: "mp3")
        let gameOverManURL = URL(fileURLWithPath: gameOverManPath!)
        do {
            sounds[.gameoverman] = try AVAudioPlayer(contentsOf: gameOverManURL)
        } catch {
            // failed to load the game over man sound.
        }
        
        let bowlingStrikePath = Bundle.main.path(forResource: "bowlingstrike", ofType: "mp3")
        let bowlingStrikeURL = URL(fileURLWithPath: bowlingStrikePath!)
        do {
            sounds[.bowlingstrike] = try AVAudioPlayer(contentsOf: bowlingStrikeURL)
        } catch {
            // failed to laod the bowling strike sound for ramming the player robot.
        }
        */
        
        let powerUpPath = Bundle.main.path(forResource: "Powerup6", ofType: "wav")
        let powerUpURL = URL(fileURLWithPath: powerUpPath!)
        do {
            sounds[.powerup] = try AVAudioPlayer(contentsOf: powerUpURL)
        } catch {
            // failed to load powerup sound.
        }
        
        /*
        let partPickUpPath = Bundle.main.path(forResource: "partpickup", ofType: "mp3")
        let partPickUpURL = URL(fileURLWithPath: partPickUpPath!)
        do {
            sounds[.partpickup] = try AVAudioPlayer(contentsOf: partPickUpURL)
        } catch {
            // failed to load part pickup sound.
        }
        
        let bunsenBurnerPath = Bundle.main.path(forResource: "bunsenburner", ofType: "wav")
        let bunsenBurnerURL = URL(fileURLWithPath: bunsenBurnerPath!)
        do {
            sounds[.bunsenburner] = try AVAudioPlayer(contentsOf: bunsenBurnerURL)
        } catch {
            // failed to load bunsen burner sound.
        }
        
        let levelExitPath = Bundle.main.path(forResource: "levelexit", ofType: "mp3")
        let levelExitURL = URL(fileURLWithPath: levelExitPath!)
        do {
            sounds[.levelexit] = try AVAudioPlayer(contentsOf: levelExitURL)
        } catch {
            // failed to load exit congratulations sound
        }

        let cricketsPath = Bundle.main.path(forResource: "crickets", ofType: "mp3")
        let cricketsURL = URL(fileURLWithPath: cricketsPath!)
        do {
            sounds[.crickets] = try AVAudioPlayer(contentsOf: cricketsURL)
        } catch {
            // failed to load crickets sound
        }
        */
        
        let constantRobotSpeedPath = Bundle.main.path(forResource: "regularspeed4", ofType: "wav")
        let constantRobotSpeedURL = URL(fileURLWithPath: constantRobotSpeedPath!)
        do {
            sounds[.constantspeed] = try AVAudioPlayer(contentsOf: constantRobotSpeedURL)            
        } catch {
            // failed to load constant robot speed sound
        }
    }
    
    // play a general sound like the bong at the beginning of the level, or a tap on a button,
    // or a tap on a target.
    func playSound(soundToPlay: GameSoundType) {
        
        // Note: we rewind the currentTime to 0.0 for all sounds in case the sound was cut off
        // due to an action.  Otherwise it picks up where it left off if played again.  We certainly
        // don't want that with bong because we are using that also as a timing mechanism to keep robots
        // still until that sound is just about done playing.
        switch soundToPlay {
        case .buttontap:
            if sounds[.buttontap] != nil {
                sounds[.buttontap]!.currentTime = 0.0        // be sure to rewind to the beginning before playing.
                sounds[.buttontap]!.volume = 0.2
                sounds[.buttontap]!.play()
            }
        /*
        case .levelentry:
            if sounds[.levelentry] != nil {
                sounds[.levelentry]!.currentTime = 0.0          // be sure to rewind to the beginning before playing.
                sounds[.levelentry]!.play()
            }
        case .gameoverman:
            if sounds[.gameoverman] != nil {
                sounds[.gameoverman]!.currentTime = 0.0        // be sure to rewind to the beginning before playing.
                sounds[.gameoverman]!.play()
            }
        case .bowlingstrike:
            if sounds[.bowlingstrike] != nil {
                sounds[.bowlingstrike]!.currentTime = 0.0        // be sure to rewind to the beginning before playing.
                sounds[.bowlingstrike]!.play()
            }
        */
        case .powerup:
            if sounds[.powerup] != nil {
                sounds[.powerup]!.currentTime = 0.0        // be sure to rewind to the beginning before playing.
                sounds[.powerup]!.play()
            }
        /*
        case .partpickup:
            if sounds[.partpickup] != nil {
                sounds[.partpickup]!.currentTime = 0.0        // be sure to rewind to the beginning before playing.
                sounds[.partpickup]!.volume = 0.3
                sounds[.partpickup]!.play()
            }
        case .bunsenburner:
            if sounds[.bunsenburner] != nil {
                sounds[.bunsenburner]!.currentTime = 0.0        // be sure to rewind to the beginning before playing.
                sounds[.bunsenburner]!.play()
            }
        case .levelexit:
            if sounds[.levelexit] != nil {
                sounds[.levelexit]!.currentTime = 0.0        // be sure to rewind to the beginning before playing.
                sounds[.levelexit]!.play()
            }
        case .crickets:
            if sounds[.crickets] != nil {
                sounds[.crickets]!.currentTime = 0.0        // be sure to rewind to the beginning before playing.
                sounds[.crickets]!.numberOfLoops = -1       // 0 = play once, >0 = play that many times, -1 = repeat over and over again.
                sounds[.crickets]!.volume = 0.2
                sounds[.crickets]!.play()
            }
        */
        case .constantspeed:
            if sounds[.constantspeed] != nil {
                sounds[.constantspeed]!.currentTime = 0.0        // be sure to rewind to the beginning before playing.
                sounds[.constantspeed]!.numberOfLoops = -1       // 0 = play once, >0 = play that many times, -1 = repeat over and over again.
                sounds[.constantspeed]!.volume = 0.3
                sounds[.constantspeed]!.play()
            }
        }
    }
    
    func stopSound (soundToStop: GameSoundType) {
        if sounds[soundToStop] != nil {
            sounds[soundToStop]!.stop()
        }
    }    
}
