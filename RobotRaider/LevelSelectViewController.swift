//
//  LevelSelectViewController.swift
//  RobotRaider
//
//  Created by Nathanael Bills on 5/26/17.
//  Copyright © 2017 invasivemachines. All rights reserved.
//

import Foundation
import UIKit
import SceneKit
import SpriteKit
import CoreData
import AVFoundation

class LevelSelectViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    var hasIntroPlayed: Bool = false
    var levelCollectionView: UICollectionView!
    
    let cellId = "LevelCell"
    var highlightInventorySelectButton: Bool = false
    var inventorySelectButton: UIButton!
    var tutorialButton: UIButton!
    
    var playerSelectedItem1ImageView: UIImageView!
    var playerSelectedItem2ImageView: UIImageView!
    var playerSelectedItem3ImageView: UIImageView!
    
    var screenSize: CGSize!
    
    var appDelegate: AppDelegate!
    var managedContext: NSManagedObjectContext!
    
    var levelNumber: Int = 1
    var lastCellSelected: IndexPath!                       // Keep track of the last level/cell selected so that we can clear it
                                                            // when a different level is selected to avoid confusing the player as to which
                                                            // level was the last one selected.
    var playerState: [NSManagedObject] = []
    
    var levelStates: [NSManagedObject] = []
    var levelStatesByLevelNum: [Int : NSManagedObject] = [ : ]
    
    var playerSelectedItem1: String = ""
    var playerSelectedItem2: String = ""
    var playerSelectedItem3: String = ""
    //var playerSelectedAmmo: String = ""
    var playerInventoryList: Inventory = Inventory()
    var firstNewPrizeUnlocked: String = ""                  // save the first new price unlocked each time the player unlocks a new prize
                                                            // there could be up to three unlocked at once but we only save the first one
                                                            // here to use as the one to center on when the player goes to inventory select.
    
    var partsList: [Int : Part] = [ : ]
    var partsListDbByPartNum: [Int : NSManagedObject] = [ : ]
    
    // simply create the random number generator with a fixed seed since we're using it just once in this class
    // to populate the parts[Start,End] and maxPowerUpsToFind entries in core data anyway.
    var randomNumGen: RandomNumberGenerator = RandomNumberGenerator(seed: 17)
    
    var lastLevelStatus: LevelStatus = .levelNotStarted        // A status of the last level.  Set to not started at the beginning
                                                                // Once we return to level selection we should have a status that it
                                                                // was either completed, with LevelCompleted, or not with LevelNotCompleted.
    // level statistics we track for a single level.  We use this to update the core data db
    // after the level ends and to show statistics in the popup to show the user how he/she did
    // after the level.
    var levelStats = LevelStats()
    
    var justBackFromInventorySelect: Bool = false               // we track whether or not the player has just come back from inventory select.
                                                                // in that case we _do_not_ want to center the collectionview at the last
                                                                // level selected.  We just want the collectionview to show where it was when
                                                                // the player entered inventory select.
    
    var isTutorialEnabled: Bool = false                            // Initially, the tutorial isn't enabled.  We enable if a) it's the first start
                                                                // of the game or if the player hasn't tapped the tutorial button to turn it on.
    var isFirstRunOfGame: Bool = false                          // if this is the first run of the game, we want to know that as we will bypass
                                                                // level selection in that case and go straight to the first level with the tutorial enabled.
    
    //var musicPlayer = AVAudioPlayer()                 // player for the background music/sound while player selects a level or selects equipment.
    
    var backButtonTappedInGamePlay: Bool = false                  // flag to let the view controller know if the back button was tapped in game play to
                                                        // go back.  This is to speed up display of levels rather than doing the fade in instead.
    
    var popUpActive: Bool = false                   // a flag that tells us if a popUp is currently in place.  This will be used to prevent
                                                    // the player from being able to tap on stuff in the background.  Unfortunately, this requires
                                                    // this class and the popup class to know about each other so information isolation isn't possible.
    
    // prefer to hide the status bar, which interferes with the experience.
    override var prefersStatusBarHidden: Bool {
        return true
    }

    func makeLabel(text: String, location: CGPoint) -> UILabel {
        let aLabel = UILabel(frame: CGRect(x: location.x, y: location.y, width: 0.20 * screenSize.width, height: 0.10 * screenSize.height))
        aLabel.textAlignment = NSTextAlignment.left
        aLabel.font = UIFont(name: aLabel.font.fontName, size: 20)
        aLabel.text = text
        aLabel.textColor = UIColor.yellow
        return aLabel
    }
    
    func makeInventoryButton(text: String) -> UIButton {
        let myButton = UIButton(type: UIButtonType.system)
        // set position and size of button
        myButton.frame = CGRect(x: 0.05 * screenSize.width, y: 0.75 * screenSize.height, width: 0.20 * screenSize.width, height: 0.10 * screenSize.height)
        // set background color for button
        myButton.backgroundColor = UIColor.purple
        // text on the button in its normal state
        myButton.layer.cornerRadius = 8                 // round the corners of the button
        myButton.layer.masksToBounds = true             // apply the rounding to the image on the button as well, if we ever use one.
        myButton.setTitle(text, for: .normal)
        
        myButton.setTitleColor(UIColor.white, for: .normal)
        myButton.titleLabel!.font = UIFont(name: myButton.titleLabel!.font.fontName, size: 20)
        myButton.titleLabel?.adjustsFontSizeToFitWidth = true
        myButton.addTarget(self, action: #selector(goToInventorySelect), for: .touchDown)
        return myButton
    }

    func makeTutorialButton() -> UIButton {
        let myButton = UIButton(type: UIButtonType.system)
        // set position and size of button
        // Note: we purposely use height instead of width when setting the width of the button to make a square button.
        // In landscape mode the height is the smaller dimension.
        myButton.frame = CGRect(x: 0.75 * screenSize.width, y: 0.85 * screenSize.height, width: 0.10 * screenSize.height, height: 0.10 * screenSize.height)
        myButton.backgroundColor = UIColor.purple
        myButton.layer.cornerRadius = 4                 // round the corners of the button
        myButton.layer.masksToBounds = true             // apply the rounding to the image on the button as well, if we ever use one.
        myButton.addTarget(self, action: #selector(toggleTutorial), for: .touchDown)
        return myButton
    }
    
    // crate imageviews for the image of something in the robot's arsenal.  We show that rather
    // then showing words because it's more compact and more immediately recognizable, at least after
    // a while.  It may not be that way initially.
    func makeItemImageView(item: String, location: CGPoint) -> UIImageView {
        let itemImageView: UIImageView = UIImageView()
        let itemImage = allModelsAndMaterials.inventoryImages[item]
        
        if itemImage != nil {
            itemImageView.image = itemImage
        }
        // Note: we use screen height in calculation the width and height in order to get a square image.
        // Our images are 512x512 px so we do this to avoid distortion.  Also, the height is the smaller dimension
        // in landscape mode so it works out better in most cases to use height rather than width as a base dimension.
        itemImageView.frame = CGRect(x: location.x, y: location.y, width: 0.10 * screenSize.height, height: 0.10 * screenSize.height)
        return itemImageView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
                
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: 0.25 * screenSize.width, height: 0.65 * screenSize.height)
        layout.scrollDirection = .horizontal
        
        levelCollectionView = UICollectionView(frame: CGRect(x: 0.0 , y: 0.05 * screenSize.height, width: screenSize.width, height: 0.65 * screenSize.height), collectionViewLayout: layout)
        levelCollectionView.dataSource = self
        levelCollectionView.delegate = self
        levelCollectionView.showsVerticalScrollIndicator = false
        levelCollectionView.showsHorizontalScrollIndicator = false
        levelCollectionView.backgroundColor = UIColor.gray
        levelCollectionView.register(LevelCollectionViewCell.self, forCellWithReuseIdentifier: cellId)
        self.view.addSubview(levelCollectionView)

        self.view.backgroundColor = UIColor.black
        inventorySelectButton = makeInventoryButton(text: "Equipment:")
        self.view.addSubview(inventorySelectButton)
        tutorialButton = makeTutorialButton()
        self.view.addSubview(tutorialButton)
        let tutorialLabelLocation = CGPoint(x: 0.84 * screenSize.width, y: 0.85 * screenSize.height)
        let tutorialLabelNode = makeLabel(text: "Tutorial", location: tutorialLabelLocation)
        tutorialLabelNode.font = UIFont.systemFont(ofSize: 20.0)
        tutorialLabelNode.textColor = UIColor.yellow
        tutorialLabelNode.adjustsFontSizeToFitWidth = true
        self.view.addSubview(tutorialLabelNode)
        
        createManagedContextForPersistentData() // set up our usage of persistent store.
        loadPlayerState()
        
        if playerState.isEmpty == true {
            // No player state means this is the start of the game.  In this case populate the database.
            
            createPlayer()
            createPartsList()
            createLevelStateData()
            isTutorialEnabled = true
            isFirstRunOfGame = true
        }
        
        loadPartsList()
        playerInventoryList.updateInventory(partsList: partsList, lastLevelStatus: self.lastLevelStatus, levelStats: &self.levelStats)  // don't forget to update the player's inventory after the parts list has
                                                                    // been loaded.  Then the list will be up-to-date when the player goes to
                                                                    // select an item.  This is needed for those times when the player quits the
                                                                    // game and comes back to it later. 

        
        loadLevelStates()
        refreshSelectedItem()
        
        if playerInventoryList.inventoryList[extraSlotLabel]?.unlocked == true && playerSelectedItem3.range(of: slot3DisabledLabel) != nil {
            enableThirdEquipmentSlot()
        }

        showSelectedItemLabels()
        
        playerInventoryList.showInventory()
        // scroll collection view until we get to where the player left off.
        let player = playerState[0]     // assume just one player
        playerSelectedItem1 = player.value(forKeyPath: PlayerDBKeys.playerSelectedItem1.rawValue) as! String
        // even though we update levelNumber when coming back from game play view controller, we also update it
        // here in case the player is restarting the game.  It's a bit redundant but safe.
        levelNumber = player.value(forKeyPath: PlayerDBKeys.lastLevelSelected.rawValue) as! Int
        
        // Add tap gesture recognizer for faster tap response than what the uicollectionview provides.
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(LevelSelectViewController.tapDetected))
        self.view.addGestureRecognizer(tapRecognizer)
        
        // Set up music to continuously play but don't play yet.  Wait until the view appears.  That way we
        // can fade it in or switch to intro without any sudden music stop, which wouldn't sound right.
        //let levelSelectMusicPath = Bundle.main.path(forResource: "levelselect2", ofType: "mp3")
        /*
        let levelSelectMusicPath = Bundle.main.path(forResource: "rhymingschemesynthsweep", ofType: "mp3")
        let levelSelectMusicURL = URL(fileURLWithPath: levelSelectMusicPath!)
        
        do {
            musicPlayer = try AVAudioPlayer(contentsOf: levelSelectMusicURL)
            musicPlayer.numberOfLoops = -1   // 0 = play once, >0 = play that many times, -1 = repeat over and over again.
            musicPlayer.volume = 0.3
        } catch {
            // could not load music.
        }
        */
    }

    override func viewWillAppear(_ animated: Bool) {
        if justBackFromInventorySelect != true && backButtonTappedInGamePlay != true {
            self.view.alpha = 0.0  // make it invisible if just coming back from game play or intro.  We will fade it in later.
                                    // But we don't do this if coming back from inventory select because we want instant display
                                    // for that as the player wants to get back into the action as soon as possible.

        }

        if isTutorialEnabled == false {
            tutorialButton.backgroundColor = UIColor.purple     // reset color of tutorial button if tutorial
                                                                // is not enabled.  We do it here because this
                                                                // function runs in the main thread and that's where
                                                                // we have to do anything with the uibutton.
        }
        // go right to where the player left off from last time.  Note: we only have one section
        // and sections start from 0 and go up, _not_ 1.
        // However, only do that if levelNumber is > 2 because we crash trying to scroll back beyond
        // level 1 if the game is starting at level 1 and we try to center that cell in the view.
        self.levelCollectionView.reloadData()  // refresh collection view after a return from level so we're up-to-date.
        if levelNumber > 2 && justBackFromInventorySelect == false {
            let selectedLevelIndexPath = IndexPath(item: levelNumber - 1, section: 0)
            levelCollectionView.scrollToItem(at: selectedLevelIndexPath, at: .centeredHorizontally, animated: true)
        }
        justBackFromInventorySelect = false  // no matter what it was before, we reset it here in preparation for the next time.
        
        // if prizes have just been unlocked, then change color of button to give player feedback that there's
        // a new item.  Note: prizesJustUnlocked will be cleared when stats are displayed so if we used this if
        // statement after the LevelStatsPopUpView is displayed, the button will never change color.  But since
        // viewWillAppear() runs before viewDidAppear() we don't have that problem.
        if levelStats.prizesJustUnlocked.isEmpty == false {
            highlightInventorySelectButton = true
            firstNewPrizeUnlocked = levelStats.prizesJustUnlocked[0]
            for aPrizeName in levelStats.prizesJustUnlocked {
                // If one of the prizes was the extra slot, then enable it.  Otherwise it won't be enabled until
                // the game is restarted.  Also, only enable the 3rd slot once.  If we just get back from the game play
                // view controller and immediately go to inventory select, when we get back from inventory select the
                // levelStats will not have changed so just looking for the ExtraSlotLabel isn't enough.  We need to
                // make sure that the player didn't select an item to put in that list already and so we look for both
                // that the extra slot was unlocked as a prize and also that the selected item had the default slot3
                // disabled label in it.  Then we know that it hadn't been enabled yet.
                if aPrizeName.range(of: extraSlotLabel) != nil && playerSelectedItem3.range(of: slot3DisabledLabel) != nil {
                    // These should only run once.  After that the condition above should no longer be true because the
                    // playerSelectedItem3 should have been changed to something else.
                    enableThirdEquipmentSlot()
                    addThirdSlotToView()
                }
            }
        }
        if highlightInventorySelectButton == true {
            inventorySelectButton.backgroundColor = UIColor.orange
            inventorySelectButton.blink()    // this is not part of UIButton but is our own extension.  See UIButtonExtensions.swift.
        }
        else {
            inventorySelectButton.backgroundColor = UIColor.purple
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        if hasIntroPlayed == false {
            performSegue(withIdentifier: "GoToIntro", sender: self)
        }
        else if isFirstRunOfGame == true {
            levelNumber = 1             // the level number set to zero in the beginning because we have unlock the levelNumber + 1 level at
                                        // the beginning of the game so we set the first level the player has finished to zero to make that
                                        // work.  However, that screws things up at the beginning of the game where we immediately go to the first
                                        // level and start the tutorial.  If we don't set levelNumber to 1 the game crashes because level 0 doesn't exist.
            isFirstRunOfGame = false   // clear this flag so we don't do this again during this session of game play.  After this
                                        // the databases for the game will already have been created so the default false will be the state
                                        // after this.
            performSegue(withIdentifier: "GoToGamePlay", sender: self)
        }
        else {
            //musicPlayer.currentTime = 0.0    // always rewind to the beginning of the music to avoid odd sounding behavior when player returns.
            //musicPlayer.play()              // we stopped the music when we went to a level or to the item select screen so now we have to turn it
            // back on.
            fadeIn(view: self.view, duration: 1.0)
        }
        if lastLevelStatus == .levelCompleted {
            // show popup with statistics on how the player did during the last level just completed.
            if levelNumber == highestLevelNumber {
                let vaultLevelCompletedPopUp = VaultLevelCompletionPopUpView(title: "Vault Opened!", parentViewSize: screenSize, levelStats: &self.levelStats)
                popUpActive = true
                vaultLevelCompletedPopUp.show(animated: true)
            }
            else {
                let levelStatsPopUp = LevelStatsPopUpView(title: "Level Statistics", parentViewSize: screenSize, levelStats: &self.levelStats, levelNum: levelNumber)
                popUpActive = true
                levelStatsPopUp.show(animated: true)
            }
        }
    }
    
    @IBAction func goToInventorySelect(sender: UIButton) {
        lastLevelStatus = .levelNotStarted   // we set this to prevent the popup from appearing if we go into the inventory
                                         // right after completing a level.
        performSegue(withIdentifier: "GoToInventorySelect", sender: self)
    }
    
    @IBAction func toggleTutorial(sender: UIButton) {
        if isTutorialEnabled == false {
            isTutorialEnabled = true
            tutorialButton.backgroundColor = UIColor.orange
        }
        else {
            isTutorialEnabled = false
            tutorialButton.backgroundColor = UIColor.purple
        }
        // play button tap sound when the tutorial button is toggled.
        gameSounds.playSound(soundToPlay: .buttontap)
    }
    
    func createManagedContextForPersistentData() {
        appDelegate = UIApplication.shared.delegate as? AppDelegate
        managedContext = appDelegate.persistentContainer.viewContext
    }
    
    func createPlayer() {
        let entity = NSEntityDescription.entity(forEntityName: EntityDBKeys.playerState.rawValue, in: managedContext)
        
        let player = NSManagedObject(entity: entity!, insertInto: managedContext)
        
        player.setValue("Player", forKeyPath: PlayerDBKeys.playerName.rawValue)
        player.setValue(defaultInventoryList[0].prizeName, forKeyPath: PlayerDBKeys.currentInventorySelected.rawValue)
        // TEMPORARY:  We set thee highestLevelSoFar to be the nth level.  That way we're pretty much garanteed that
        // the player can go to any level 1-61.  This is for testing purposes only.  Otherwise we reset to zero to
        // make the player start at level 1.
        //player.setValue(16, forKeyPath: PlayerDBKeys.highestLevelSoFar.rawValue)
        player.setValue(0, forKeyPath: PlayerDBKeys.highestLevelSoFar.rawValue)
        player.setValue(0, forKeyPath: PlayerDBKeys.lastLevelSelected.rawValue)
        player.setValue(false, forKeyPath: PlayerDBKeys.hasLedger.rawValue)
        player.setValue(false, forKeyPath: PlayerDBKeys.hasMap.rawValue)
        player.setValue(false, forKeyPath: PlayerDBKeys.hasRecipeBook.rawValue)
        player.setValue(0, forKeyPath: PlayerDBKeys.cryptocoin.rawValue)
        // set up our default SelectedItem1 and SelectedItem2 for player to be the lowest two selected items.
        player.setValue(defaultInventoryList[0].prizeName, forKeyPath: PlayerDBKeys.playerSelectedItem1.rawValue)
        player.setValue(noSelectionLabel, forKeyPath: PlayerDBKeys.playerSelectedItem2.rawValue)
        player.setValue(slot3DisabledLabel, forKeyPath: PlayerDBKeys.playerSelectedItem3.rawValue)
        
        do {
            try managedContext.save()
        //} catch let error as NSError {
        } catch {
            // could not save new player creation.
        }
        
        playerState = [player]  // lastly, make this the current state of the player in memory right now for our use
        // in things like selecting the level to go to, selecting items, etc.
    }
    
    // enable the third equipment slot--it is assumed that by the time this function is called that the player has
    // gathered all the parts to unlock the third slot prize.
    func enableThirdEquipmentSlot() {
        playerSelectedItem3 = slot3EnabledLabel
        
        // It is assumed that the managed context is already loaded when this function is called.  Maybe not
        // the best practice but it cuts down on loading the database again and again.
        let player = playerState[0]
        player.setValue(slot3EnabledLabel, forKeyPath: PlayerDBKeys.playerSelectedItem3.rawValue)
        
        do {
            try managedContext.save()
        //} catch let error as NSError {
        } catch {
            // could not third slot activation.
        }
    }
    
    // Create the parts list that will be used to place parts in the level and also used to keep track of what
    // parts the player has gathered.  
    func createPartsList() {
        let entity = NSEntityDescription.entity(forEntityName: EntityDBKeys.parts.rawValue, in: managedContext)
        
        var i: Int = 0
        var partNumber: Int = 0
        while i < prizesList.count {
            let numPartsInPrize = prizesList[i].requiredNumberOfParts
            for _ in 1...numPartsInPrize {
                partNumber += 1
                let part = NSManagedObject(entity: entity!, insertInto: managedContext)
                part.setValue(partNumber, forKeyPath: PartsDBKeys.partNumber.rawValue)
                part.setValue(prizesList[i].prizeName, forKeyPath: PartsDBKeys.prizeName.rawValue)
                // TEMPORARY:  we set the retrieved value to 'true' so that we can test every
                // prize without having to gather up all the parts each time.  Once we've tested all
                // the prizes, then we have to change this back to false.
                //part.setValue(true, forKeyPath: PartsDBKeys.retrieved.rawValue)
                /*
                if partNumber <= 46 {
                    part.setValue(true, forKeyPath: PartsDBKeys.retrieved.rawValue)
                }
                else {
                    part.setValue(false, forKeyPath: PartsDBKeys.retrieved.rawValue)
                }
                */
                part.setValue(false, forKeyPath: PartsDBKeys.retrieved.rawValue)
            }
            i += 1
        }
        
        do {
            try managedContext.save()
        //} catch let error as NSError {
        } catch {
            // Could not save new parts list creation. \(error), \(error.userInfo)")
        }

    }
    
    // create data that represents the state of the level, including state of prize parts in the level.
    func createLevelStateData() {
        var randomNum: Int = 0
        var minParts: Float = 4.0
        var partCount: Int = 1
        var numPermanentParts: Int = 0
        var numPowerUps: Int = 0
        
        var totalNumberOfParts: Int = 0
        for aPrize in prizesList {
            totalNumberOfParts += aPrize.requiredNumberOfParts
        }
        
        for aLevelNumber in 1...highestLevelNumber - 1 {
            let aLevelInfo = NSEntityDescription.insertNewObject(forEntityName: EntityDBKeys.levelInfo.rawValue, into: managedContext)
            aLevelInfo.setValue(aLevelNumber, forKey: LevelInfoDBKeys.levelNumber.rawValue)
            aLevelInfo.setValue(0, forKey: LevelInfoDBKeys.achievementStars.rawValue)
            aLevelInfo.setValue(0, forKey: LevelInfoDBKeys.numPartsFoundSoFar.rawValue)
            aLevelInfo.setValue(0, forKey: LevelInfoDBKeys.highestNumRobotsDestroyed.rawValue)
            aLevelInfo.setValue(0, forKey: LevelInfoDBKeys.lastNumRobotsDestroyed.rawValue)
            // TEMPORARY:  we set the value for level completed to 'true' to allow us to quickly
            // get to any level for testing.  For the real game, we set the initial value to 'false'
            // and the player has to go through each one to change that state.  We use an if-else
            // structure to allow us to set completion for specific levels so we can test beyond
            // that point.
            //aLevelInfo.setValue(true, forKey: LevelInfoDBKeys.levelCompleted.rawValue)
            /*
            if aLevelNumber < 17 {
                aLevelInfo.setValue(true, forKey: LevelInfoDBKeys.levelCompleted.rawValue)
            }
            else {
                aLevelInfo.setValue(false, forKey: LevelInfoDBKeys.levelCompleted.rawValue)
            }
            */
            aLevelInfo.setValue(false, forKey: LevelInfoDBKeys.levelCompleted.rawValue)
            aLevelInfo.setValue(0, forKey: LevelInfoDBKeys.highestNumPowerUpsFound.rawValue)
            aLevelInfo.setValue(0, forKey: LevelInfoDBKeys.lastNumPowerUpsFound.rawValue)
            
            // The number of robots has to be set later when the level is created.  But we give them default
            // values for now.
            aLevelInfo.setValue(0, forKey: LevelInfoDBKeys.maxRobotsToDestroy.rawValue)
            
            // Note: this code was originally written when we were anticipating 90 levels plus the 91st
            // level being the vault level.  Later we changed it to 60 regular levels with the 61st level
            // being the vault level.  However, we left the conditions as they were because changing them
            // changed the number of parts distributed throughout the levels.  We found that if we changed
            // 30 to 20 and 60 to 40 that the numer of parts at level 60 would be negative.  Rather than
            // try to change to 20 and 40 and then revamp the parts list throughout the game we just left
            // it this way.  Who knows?  Maybe we'll add 30 more levels to the game in an update or something.
            randomNum = randomNumGen.xorshift_randomgen()
            if aLevelNumber < 30 {
                numPermanentParts = Int(minParts) + randomNum % 4
                randomNum = randomNumGen.xorshift_randomgen()
                numPowerUps = Int(minParts) + randomNum % 5
            }
            else if aLevelNumber < 60 {
                numPermanentParts = Int(minParts) + randomNum % 8
                randomNum = randomNumGen.xorshift_randomgen()
                numPowerUps = Int(minParts) + randomNum % 7
            }
            else {
                numPermanentParts = Int(minParts) + randomNum % 12
                randomNum = randomNumGen.xorshift_randomgen()
                numPowerUps = Int(minParts) + randomNum % 10
            }
            let permanentPartsStart = partCount
            var permanentPartsEnd: Int = 0
            permanentPartsEnd = partCount + numPermanentParts
            
            // If we're at the last level just before the vault level, then make
            // the end of the part numbers equal to the very last part, which equals
            // the totalNumerOfParts.
            if aLevelNumber == highestLevelNumber - 1 {
                permanentPartsEnd = totalNumberOfParts
            }
            partCount = permanentPartsEnd + 1
            // add another part to find every so often
            if aLevelNumber % minPartNumIncreaseLevelInterval == 1 {
                minParts += 1.85
            }
            
            aLevelInfo.setValue(permanentPartsStart, forKey: LevelInfoDBKeys.partNumStart.rawValue)
            aLevelInfo.setValue(permanentPartsEnd, forKey: LevelInfoDBKeys.partNumEnd.rawValue)
            aLevelInfo.setValue(numPowerUps, forKey: LevelInfoDBKeys.maxPowerUpsToFind.rawValue)
            // show the part number range for a level.  This is for debugging purposes.  We would turn this
            // off for the production game.
            //print ("level# \(aLevelNumber): part# start: \(permanentPartsStart), end: \(permanentPartsEnd), powerups: \(numPowerUps)")
        }
        
        // set up data for vault level, the last level, the highestLevelNumber, here.
        let aLevelInfo = NSEntityDescription.insertNewObject(forEntityName: EntityDBKeys.levelInfo.rawValue, into: managedContext)
        aLevelInfo.setValue(highestLevelNumber, forKey: LevelInfoDBKeys.levelNumber.rawValue)
        aLevelInfo.setValue(0, forKey: LevelInfoDBKeys.achievementStars.rawValue)
        aLevelInfo.setValue(0, forKey: LevelInfoDBKeys.numPartsFoundSoFar.rawValue)
        aLevelInfo.setValue(0, forKey: LevelInfoDBKeys.highestNumRobotsDestroyed.rawValue)
        aLevelInfo.setValue(0, forKey: LevelInfoDBKeys.lastNumRobotsDestroyed.rawValue)
        aLevelInfo.setValue(false, forKey: LevelInfoDBKeys.levelCompleted.rawValue)
        aLevelInfo.setValue(0, forKey: LevelInfoDBKeys.highestNumPowerUpsFound.rawValue)
        aLevelInfo.setValue(0, forKey: LevelInfoDBKeys.lastNumPowerUpsFound.rawValue)
        
        // The number of robots has to be set later when the level is created.  But we give them default
        // values for now.
        aLevelInfo.setValue(0, forKey: LevelInfoDBKeys.maxRobotsToDestroy.rawValue)
        aLevelInfo.setValue(0, forKey: LevelInfoDBKeys.partNumStart.rawValue)
        aLevelInfo.setValue(0, forKey: LevelInfoDBKeys.partNumEnd.rawValue)
        // just use the same number of power ups as the penultimate (the one before) level.
        aLevelInfo.setValue(numPowerUps, forKey: LevelInfoDBKeys.maxPowerUpsToFind.rawValue)
        
        // save after everything has been created.  It's inefficient to save at every level info creation.
        do {
            try managedContext.save()
        } catch {
            // problem creating level info data
        }
    }
    
    func loadPlayerState() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: EntityDBKeys.playerState.rawValue)
        
        do {
            playerState = try managedContext.fetch(fetchRequest) as! [NSManagedObject]
        //} catch let error as NSError {
        } catch {
            // Could not fetch. \(error), \(error.userInfo)"
        }
        
    }
    
    // get the state of all the parts in the levels--whether or not they've been retrieved.
    func loadPartsList() {
        var partStates: [NSManagedObject] = []
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: EntityDBKeys.parts.rawValue)
        do {
            partStates = try managedContext.fetch(fetchRequest) as! [NSManagedObject]
        //} catch let error as NSError {
        } catch {
            // Could not fetch parts list. \(error), \(error.userInfo)"
        }
        
        if partStates.isEmpty == false {
            for i in 0...partStates.count - 1 {
                let partNum = partStates[i].value(forKey: PartsDBKeys.partNumber.rawValue) as! Int
                let prizeName = partStates[i].value(forKey: PartsDBKeys.prizeName.rawValue) as! String
                let retrieved = partStates[i].value(forKey: PartsDBKeys.retrieved.rawValue) as! Bool
                partsList[partNum] = Part()
                partsList[partNum]?.partNumber = partNum
                partsList[partNum]?.prizeName = prizeName
                partsList[partNum]?.retrieved = retrieved
                partsListDbByPartNum[partNum] = partStates[i]
            }
        }
        
    }
    
    func loadLevelStates() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: EntityDBKeys.levelInfo.rawValue)
        
        do {
            levelStates = try managedContext.fetch(fetchRequest) as! [NSManagedObject]
        //} catch let error as NSError {
        } catch {
            // Could not fetch. \(error), \(error.userInfo)"
        }
        if levelStates.isEmpty == false {
            // load level NSManagedObjects into a dictionary.  There might be a better way to do this
            // but this works.
            for i in 0...levelStates.count - 1 {
                let levelNum = levelStates[i].value(forKey: LevelInfoDBKeys.levelNumber.rawValue) as! Int
                levelStatesByLevelNum[levelNum] = levelStates[i]
            }
        }
        
    }
    
    // update the state of all the parts in the game
    func updatePartsList(partsStart: Int, partsEnd: Int, partsListFromLevel: [Int : Part]) {
        
        for aPartNumber in partsStart...partsEnd {
            if partsListFromLevel[aPartNumber]?.retrieved == true {
                partsList[aPartNumber]?.retrieved = (partsListFromLevel[aPartNumber]?.retrieved)!
                // update core data in memory
                partsListDbByPartNum[aPartNumber]?.setValue((partsListFromLevel[aPartNumber]?.retrieved)!, forKeyPath: PartsDBKeys.retrieved.rawValue)
            }
        }
        
        // Save to permanent store after we're done updating all the parts records that needed updating.
        do {
            try managedContext.save()
        } catch {
            // problem saving updates to parts list
        }
        
        // last but not least, update the player's inventory of locked/unlocked prizes
        playerInventoryList.updateInventory(partsList: partsList, lastLevelStatus: self.lastLevelStatus, levelStats: &self.levelStats)
    }
    
    func refreshSelectedItem() {
        let player = playerState[0]
        // assume we have player SelectedItem1,2 already defined.  It should be as we set defaults
        // when we create the player.  At any other time selections will be made.  There should
        // never be an instance where the selected item is "".
        playerSelectedItem1 = player.value(forKeyPath: PlayerDBKeys.playerSelectedItem1.rawValue) as! String
        playerSelectedItem2 = player.value(forKeyPath: PlayerDBKeys.playerSelectedItem2.rawValue) as! String
        playerSelectedItem3 = player.value(forKeyPath: PlayerDBKeys.playerSelectedItem3.rawValue) as! String
        // Note: we don't update playerSelectedAmmo here because this is primarily to show the selected
        // items updated after the player has selected new items to use.  playerSelectedAmmo should only
        // be updated at the very first run of the game and from selection passed back from game play.
    }
    
    // when view loads, show the player's first two selected items.  The third one is a special case and
    // only appears when the third slot is enabled.
    func showSelectedItemLabels() {
        let selectedItem1ImageLocation = CGPoint(x: 0.30 * screenSize.width, y: 0.75 * screenSize.height)
        playerSelectedItem1ImageView = makeItemImageView(item: playerSelectedItem1, location: selectedItem1ImageLocation)
        self.view.addSubview(playerSelectedItem1ImageView)
        
        let selectedItem2ImageLocation = CGPoint(x: 0.40 * screenSize.width, y: 0.75 * screenSize.height)
        playerSelectedItem2ImageView = makeItemImageView(item: playerSelectedItem2, location: selectedItem2ImageLocation)
        self.view.addSubview(playerSelectedItem2ImageView)

        addThirdSlotToView()
    }
    
    func updateSelectedItemLabels() {
        playerSelectedItem1ImageView.image = allModelsAndMaterials.inventoryImages[playerSelectedItem1]
        playerSelectedItem2ImageView.image = allModelsAndMaterials.inventoryImages[playerSelectedItem2]
        if playerSelectedItem3.range(of: slot3DisabledLabel) == nil {
            playerSelectedItem3ImageView.image = allModelsAndMaterials.inventoryImages[playerSelectedItem3]
        }
    }
    
    // Add the third slot to the screen, if it is enabled.
    func addThirdSlotToView() {
        if playerSelectedItem3.range(of: slot3DisabledLabel) == nil {
            let selectedItem3ImageLocation = CGPoint(x: 0.50 * screenSize.width, y: 0.75 * screenSize.height)
            playerSelectedItem3ImageView = makeItemImageView(item: playerSelectedItem3, location: selectedItem3ImageLocation)
            self.view.addSubview(playerSelectedItem3ImageView)
        }
    }
    
    // UICollectionView specific functions.
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1    // Only one section for now, just for the level selection
    }
    
    // The number of levels we have corresponds to the number of level states we have in our database.
    // Each level state represents what the player has done in that level. The count we return from
    // here tells the populate cells code how many levels to list out in the uncollectionview.
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // Note: we use levelStatesByLevelNum to reference each levelState but the number
        // of those levels should be exactly the same as what was in levelStates as we used
        // levelStates as the basis for creating levelStatesByLevelNum.  So this works fine but
        // we always need to remember this fact.  They must remain closely tied together.
        return levelStates.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let level = levelStatesByLevelNum[indexPath.item + 1] // cells start at 0 and our levels start at 1, hence the +1.
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! LevelCollectionViewCell
        let levelNum = level?.value(forKeyPath: LevelInfoDBKeys.levelNumber.rawValue) as! Int
        
        let partsFound = level?.value(forKeyPath: LevelInfoDBKeys.numPartsFoundSoFar.rawValue) as! Int
        let partStart = level?.value(forKeyPath: LevelInfoDBKeys.partNumStart.rawValue) as! Int
        let partEnd = level?.value(forKeyPath: LevelInfoDBKeys.partNumEnd.rawValue) as! Int
        var maxPartsToFind = partEnd - partStart + 1
        // This condition happens at the vault level, the last level, where there are no more parts
        // to find because on that level the objective is to open the vault, where a number of goodies are.
        if partEnd == 0 && partStart == 0 {
            maxPartsToFind = 0
        }
        let robotsDestroyed = level?.value(forKeyPath: LevelInfoDBKeys.highestNumRobotsDestroyed.rawValue) as! Int
        let maxRobotsToDestroy = level?.value(forKeyPath: LevelInfoDBKeys.maxRobotsToDestroy.rawValue) as! Int
        
        // There are max parts to find when the level is less than the highest one.  Only key parts are in
        // the highest level and those are all-or-nothing.  The player can't just get some of them like she can
        // in other levels.
        if maxPartsToFind > 0 {
            // Note: we have to always update the cell's contents because further below we might clear it out
            // if it is disabled and that is carried over to other cells because of reuse.  Because of that each cell must
            // be with current data.  Also note that we set the font size and adjust to fit the label size for each label
            // below even though testing shows it is not necessary on the iPad.  However, we found that we had to do that
            // in the InventorySelectViewController class so we do it here just in case there is a case we're not seeing
            // in our testing.
            if levelNum >= highestLevelNumber {
                cell.levelNumLabel.text = "Vault"
            }
            else {
                cell.levelNumLabel.text = String(describing: levelNum)
            }
            cell.levelNumLabel.textColor = UIColor.yellow
            cell.levelNumLabel.font = UIFont.systemFont(ofSize: 40.0)
            cell.levelNumLabel.adjustsFontSizeToFitWidth = true

            cell.robotTallyLabel.text = String(describing: robotsDestroyed) + "/" + String(describing: maxRobotsToDestroy)
            cell.robotTallyLabel.font = UIFont.systemFont(ofSize: 20.0)
            cell.robotTallyLabel.adjustsFontSizeToFitWidth = true

            cell.partTallyLabel.text = String(describing: partsFound) + "/" + String(describing: maxPartsToFind)
            cell.partTallyLabel.font = UIFont.systemFont(ofSize: 20.0)
            cell.partTallyLabel.adjustsFontSizeToFitWidth = true

            cell.robotImageView.image = allModelsAndMaterials.robotImage
            cell.partImageView.image = allModelsAndMaterials.partImage
            cell.genericRobotImageView.image = nil    // cell isn't grayed out in this case so we don't show the generic robot.
            let levelCompleted = level?.value(forKeyPath: LevelInfoDBKeys.levelCompleted.rawValue) as! Bool
            if levelCompleted == true {
                cell.star1ImageView.image = allModelsAndMaterials.filledStarImage
                cell.star1ImageView.contentMode = UIViewContentMode.scaleAspectFit
            }
            else {
                cell.star1ImageView.image = allModelsAndMaterials.emptyStarImage
                cell.star1ImageView.contentMode = UIViewContentMode.scaleAspectFit
            }
            if partsFound >= maxPartsToFind || (robotsDestroyed >= maxRobotsToDestroy && maxRobotsToDestroy > 0) {
                cell.star2ImageView.image = allModelsAndMaterials.filledStarImage
                cell.star2ImageView.contentMode = UIViewContentMode.scaleAspectFit
            }
            else {
                cell.star2ImageView.image = allModelsAndMaterials.emptyStarImage
                cell.star2ImageView.contentMode = UIViewContentMode.scaleAspectFit
            }
            if partsFound >= maxPartsToFind && (robotsDestroyed >= maxRobotsToDestroy && maxRobotsToDestroy > 0) {
                cell.star3ImageView.image = allModelsAndMaterials.filledStarImage
                cell.star3ImageView.contentMode = UIViewContentMode.scaleAspectFit
            }
            else {
                cell.star3ImageView.image = allModelsAndMaterials.emptyStarImage
                cell.star3ImageView.contentMode = UIViewContentMode.scaleAspectFit
            }
        }
        else {
            if levelNum >= highestLevelNumber {
                cell.levelNumLabel.text = "Vault"
            }
            else {
                cell.levelNumLabel.text = String(describing: levelNum)
            }

            cell.robotTallyLabel.text = ""
            cell.partTallyLabel.text = ""
            cell.star1ImageView.image = allModelsAndMaterials.emptyStarImage
            cell.star1ImageView.contentMode = UIViewContentMode.scaleAspectFit
            cell.star2ImageView.image = allModelsAndMaterials.emptyStarImage
            cell.star2ImageView.contentMode = UIViewContentMode.scaleAspectFit
            cell.star3ImageView.image = allModelsAndMaterials.emptyStarImage
            cell.star3ImageView.contentMode = UIViewContentMode.scaleAspectFit
        }
        
        let player = playerState[0]   // assume there is only one player
        let maxLevelToEnter = (player.value(forKey: PlayerDBKeys.highestLevelSoFar.rawValue) as? Int)! + 1   // player can enter all the levels achieved so far plus the next one.
        
        if levelNum > maxLevelToEnter {
            cell.backgroundColor = UIColor.darkGray
            //cell.levelLabel.textColor = UIColor.darkGray
            cell.isUserInteractionEnabled = false
            if levelNum >= highestLevelNumber {
                cell.levelNumLabel.text = "Vault"
            }
            else {
                cell.levelNumLabel.text = String(describing: levelNum)
            }
            cell.levelNumLabel.textColor = UIColor.gray
            // when grayed out, clear out everything.
            cell.robotTallyLabel.text = ""
            cell.partTallyLabel.text = ""
            cell.robotImageView.image = nil
            cell.partImageView.image = nil
            cell.star1ImageView.image = nil
            cell.star2ImageView.image = nil
            cell.star3ImageView.image = nil
            cell.genericRobotImageView.image = allModelsAndMaterials.genericRobotImage
        }
        else if levelNum == levelNumber {
            cell.backgroundColor = UIColor.purple
            cell.isUserInteractionEnabled = true
            lastCellSelected = indexPath
        }
        else {  // always have to enable the buttons just in case they get disabled but are still within maxLevelPlayerCanPlay
            cell.backgroundColor = UIColor(red: 0.25, green: 0.15, blue: 0.25, alpha: 1.0)
            cell.isUserInteractionEnabled = true
        }
        cell.layer.borderColor = UIColor.white.cgColor
        cell.layer.borderWidth = 1
        cell.layer.cornerRadius = 8
        return cell
    }
    
    // use tap gesture recognizer to control taps on levels rather than using the collectionview
    // touch code because that stuff is slooooow.  Note: we're not using GCD here as we did in
    // the GamePlayViewController because we don't need super, duper isolation as the taps here
    // will be fewer and farther between.
    @objc func tapDetected(recognizer: UITapGestureRecognizer) {
        // only allow the tap to go forward if a popup isn't in place because we don't want the player to
        // be able to accidentally be able to select a level behind the popup view.
        if popUpActive == false {
            if let indexPath = levelCollectionView?.indexPathForItem(at: recognizer.location(in: levelCollectionView)) {
                let cell = levelCollectionView?.cellForItem(at: indexPath)
                // only do something if the cell is active.  Otherwise just ignore the tap.
                if cell?.isUserInteractionEnabled == true {
                    // clear out last cell selected if one was selected earlier -- normally there would be one except
                    // possibly when the game starts for the first time.
                    if lastCellSelected != nil {
                        let previousCell = levelCollectionView.cellForItem(at: lastCellSelected)
                        previousCell?.backgroundColor = UIColor(red: 0.25, green: 0.15, blue: 0.25, alpha: 1.0)
                    }
                    
                    cell?.backgroundColor = UIColor(red: 0.5, green: 0.0, blue: 0.0, alpha: 1.0)
                    levelNumber = indexPath.item + 1
                    // fade out in 0.5 seconds and then segue.  Note: we do it explicitly here because it looks like adding completion
                    // to our own fadeOut function would be onerous.  Someday we need to fix that and move this to a fadeout function
                    // where a completion block is allowed.
                    gameSounds.playSound(soundToPlay: .buttontap)   // we _assume_ a button has been tapped to cause the transition.
                    UIView.animate(withDuration: 0.5, delay: 0.0, options: [.curveEaseInOut], animations: {
                        self.view.alpha = 0.0
                    }, completion: { (finished: Bool) in
                        self.performSegue(withIdentifier: "GoToGamePlay", sender: self)
                    })
                }
            }
        }
    }
    
    
    // Segue code - dealing with coming back from Level and also going to level
    
    // dealing with coming back from level.
    @IBAction func unwindToLevelSelect(unwindSegue: UIStoryboardSegue) {
        if let gamePlayViewController = unwindSegue.source as? GamePlayViewController {
            backButtonTappedInGamePlay = gamePlayViewController.backButtonTapped
            isTutorialEnabled = false // no matter what, disable tutorial after getting back from game play.
            lastLevelStatus = gamePlayViewController.levelStatus
            levelNumber = gamePlayViewController.levelNum  // even though levelNumber should be the last level
                                                            // the player was in we make sure of that by pulling
                                                            // that number from the game play view controller.
            
            let player = playerState[0]  // assume only one player
            player.setValue(levelNumber, forKeyPath: PlayerDBKeys.lastLevelSelected.rawValue)  // save the last level selected,
                                            // just in case.
            
            // whether or not the player has completed the level, save max robots to destroy and max parts to gather.  
            let levelJustCompleted = levelNumber
            let level = levelStatesByLevelNum[levelJustCompleted]
            levelStats.highestNumRobotsToDestroy = gamePlayViewController.playerLevelData.maxRobotsToDestroy
            level?.setValue(levelStats.highestNumRobotsToDestroy, forKeyPath: LevelInfoDBKeys.maxRobotsToDestroy.rawValue)
            let partStart = level?.value(forKeyPath: LevelInfoDBKeys.partNumStart.rawValue) as! Int
            let partEnd = level?.value(forKeyPath: LevelInfoDBKeys.partNumEnd.rawValue) as! Int
            var maxPartsToFind = partEnd - partStart + 1
            // This condition happens at the vault level, the last level, where there are no more parts
            // to find because on that level the objective is to open the vault, where a number of goodies are.
            if partEnd == 0 && partStart == 0 {
                maxPartsToFind = 0
            }
            levelStats.maxPartsToFind = maxPartsToFind

            // note: we only tally up parts gatherered, robots destroyed, etc., when the player
            // actually makes it throught the exit to complete the level, either the first time or any time
            // after that.  If the player's robot is destroyed before it makes it to the exit, then the player
            // gets nothing and has to try again for that level.
            if lastLevelStatus == .levelCompleted {
                //let levelJustCompleted = levelNumber   // we save this level number because we might increment levelNumber later
                                                       // if the level was just completed.
                let highestLevelSoFar = player.value(forKey: PlayerDBKeys.highestLevelSoFar.rawValue) as! Int
                let updatedPartsList = gamePlayViewController.entirePartsList
                
                let partsStart = level?.value(forKeyPath: LevelInfoDBKeys.partNumStart.rawValue) as! Int
                let partsEnd = level?.value(forKeyPath: LevelInfoDBKeys.partNumEnd.rawValue) as! Int

                updatePartsList(partsStart: partsStart, partsEnd: partsEnd, partsListFromLevel: updatedPartsList)
                
                level?.setValue(true, forKeyPath: LevelInfoDBKeys.levelCompleted.rawValue)
                if highestLevelSoFar < levelJustCompleted {
                    player.setValue(levelJustCompleted, forKeyPath: PlayerDBKeys.highestLevelSoFar.rawValue)
                }
                
                // updated in level info db the latest stats from the player.
                let numPartsFound = gamePlayViewController.playerLevelData.numberOfPartsFound
                levelStats.numRobotsDestroyed = gamePlayViewController.playerLevelData.numberOfRobotsDestroyed
                levelStats.highestNumRobotsDestroyedSoFar = level?.value(forKey: LevelInfoDBKeys.highestNumRobotsDestroyed.rawValue) as! Int
                
                level?.setValue(levelStats.numRobotsDestroyed, forKeyPath: LevelInfoDBKeys.lastNumRobotsDestroyed.rawValue)
                
                // Note: we don't save the managed context after updating the parts db because we do a general save at the
                // end of this function.

                // update the overall number of parts found.
                levelStats.numPartsFoundSoFar = level?.value(forKey: LevelInfoDBKeys.numPartsFoundSoFar.rawValue) as! Int
                levelStats.numNewPartsFound = numPartsFound - levelStats.numPartsFoundSoFar
                levelStats.numPartsFoundSoFar = numPartsFound
                level?.setValue(levelStats.numPartsFoundSoFar, forKeyPath: LevelInfoDBKeys.numPartsFoundSoFar.rawValue)
                
                if levelStats.highestNumRobotsDestroyedSoFar < levelStats.numRobotsDestroyed {
                    level?.setValue(levelStats.numRobotsDestroyed, forKeyPath: LevelInfoDBKeys.highestNumRobotsDestroyed.rawValue)
                    levelStats.highestNumRobotsDestroyedSoFar = levelStats.numRobotsDestroyed
                }
                
                // If we just finished the last level then update the player's state with the goodies just obtained.
                // We just check first to see if player has already picked up the ledger.  If so, then we know that
                // the player has completed the level before and we don't need to update Core Data again.
                let lastLevelCompletedBefore = player.value(forKey: PlayerDBKeys.hasLedger.rawValue) as! Bool
                if levelJustCompleted == highestLevelNumber && lastLevelCompletedBefore == false {
                    player.setValue(true, forKeyPath: PlayerDBKeys.hasLedger.rawValue)
                    player.setValue(true, forKeyPath: PlayerDBKeys.hasMap.rawValue)
                    player.setValue(true, forKeyPath: PlayerDBKeys.hasRecipeBook.rawValue)
                    player.setValue(valueOfLedgerAndRecipeBookCombined, forKeyPath: PlayerDBKeys.cryptocoin.rawValue)
                }
                
                playerInventoryList.showInventory()
            }
            gamePlayViewController.dismiss(animated: false, completion: nil)
        }
        else if let inventorySelectViewController = unwindSegue.source as? InventorySelect {
            let player = playerState[0]  // assume only one player
            playerSelectedItem1 = inventorySelectViewController.selectedItem1
            playerSelectedItem2 = inventorySelectViewController.selectedItem2
            playerSelectedItem3 = inventorySelectViewController.selectedItem3
            // save in permanent store for when the player quits and then gets back into the game.
            player.setValue(playerSelectedItem1, forKeyPath: PlayerDBKeys.playerSelectedItem1.rawValue)
            player.setValue(playerSelectedItem2, forKeyPath: PlayerDBKeys.playerSelectedItem2.rawValue)
            player.setValue(playerSelectedItem3, forKeyPath: PlayerDBKeys.playerSelectedItem3.rawValue)
            updateSelectedItemLabels()
            highlightInventorySelectButton = false  // unhighlight the button because the player has had a chance to see any new inventory items.
            firstNewPrizeUnlocked = ""              // clear out first new prize unlocked.  It is no longer the center of attention.
            inventorySelectViewController.dismiss(animated: false, completion: nil)
            justBackFromInventorySelect = true  // let the game know we just got back from inventory select.  Need this to stop the reposition of the collectionview
                                                // to the last level selected.  We want to go back to where the player scrolled in case the player scrolled to
                                                // a level to select it for play, then decided to change the robot inventory just before going into that level.
                                                // Also, this stops the fadeIn of the level select screen, bringing it back instantly instead.
        }
        else if let introViewController = unwindSegue.source as? IntroViewController {
            introViewController.dismiss(animated: false, completion: nil)
            hasIntroPlayed = true 
        }
        
        // Always save player or level state in permanent store.
        do {
            try managedContext.save()
        } catch {
            // problem saving update after level completion
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //musicPlayer.stop()              // stop level select music when going to another screen
        if segue.identifier == "GoToGamePlay" {

            // First thing to do, save level selected in case player quits game before getting
            // back to level select.
            let player = playerState[0]  // assume only one player
            player.setValue(levelNumber, forKeyPath: PlayerDBKeys.lastLevelSelected.rawValue)  // save the last level selected,
            do {
                try managedContext.save()
            } catch {
                // problem saving update after level completion
            }

            // Next, pass setup info to the level in prep for switching to it.
            let destViewController = segue.destination as? GamePlayViewController
            destViewController?.levelNum = levelNumber
            destViewController?.playerItem1 = playerSelectedItem1
            destViewController?.playerItem2 = playerSelectedItem2
            destViewController?.playerItem3 = playerSelectedItem3
            destViewController?.playerInventoryList = playerInventoryList
            let level = levelStatesByLevelNum[levelNumber]
            let partsStart = level?.value(forKeyPath: LevelInfoDBKeys.partNumStart.rawValue) as! Int
            let partsEnd = level?.value(forKeyPath: LevelInfoDBKeys.partNumEnd.rawValue) as! Int
            let numPowerUps = level?.value(forKeyPath: LevelInfoDBKeys.maxPowerUpsToFind.rawValue) as! Int
            let numPartsFound = level?.value(forKeyPath: LevelInfoDBKeys.numPartsFoundSoFar.rawValue) as! Int
            // prep for placing parts and powerups in the level.
            destViewController?.partsStart = partsStart
            destViewController?.partsEnd = partsEnd
            destViewController?.numPowerUps = numPowerUps
            destViewController?.entirePartsList = partsList
            destViewController?.preexistingNumPartsFound = numPartsFound
            destViewController?.isTutorialEnabled = isTutorialEnabled
        }
        else if segue.identifier == "GoToInventorySelect" {
            gameSounds.playSound(soundToPlay: .buttontap)   // we _assume_ a button has been tapped to cause the transition.  

            let destViewController = segue.destination as? InventorySelect
            destViewController?.selectedItem1 = playerSelectedItem1
            destViewController?.selectedItem2 = playerSelectedItem2
            destViewController?.selectedItem3 = playerSelectedItem3
            destViewController?.playerInventoryList = playerInventoryList
            destViewController?.itemToCenterOn = firstNewPrizeUnlocked
        }
    }
    
    // fade in scene/view/whatever
    func fadeIn(view: UIView, duration: Double, delay: Double = 0.0) {
        UIView.animate(withDuration: duration, delay: delay, options: [.curveEaseInOut], animations: {
            view.alpha = 1.0
        })
    }
}

