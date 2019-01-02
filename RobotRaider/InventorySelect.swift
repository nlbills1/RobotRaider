//
//  InventorySelect.swift
//  RobotRaider
//
//  Created by Nathanael Bills on 5/26/17.
//  Name changed to InventorySelect on 08/22/2017
//  Copyright © 2017 invasivemachines. All rights reserved.
//

import Foundation
import UIKit
//import SceneKit
//import SpriteKit

class InventorySelect: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    var itemCollectionView: UICollectionView!
    var goBackButton: UIButton!
    var selectedItem1Button: UIButton!
    var selectedItem2Button: UIButton!
    var selectedItem3Button: UIButton!
    var screenSize: CGSize!
    var selectedItem1: String = ""
    var selectedItem2: String = ""
    var selectedItem3: String = ""
    var itemSelected: String = ""
    var itemTypeSelected: PartType = .noPart
    
    var lastItemSelected: IndexPath!
    
    var itemToCenterOn: String = ""     // this should be a newly unlocked item.  We want to center on it
                                        // to draw the player's attention to it.
    
    var playerInventoryList: Inventory = Inventory()
    
    let initialSelectionColor = UIColor(red: 0.4, green: 0.8, blue: 0.4, alpha: 1.0)
    let successfullyAssignedColor = UIColor.green
    let failedAssignColor = UIColor.yellow
    
    var failedAssignColorImage: UIImage!
    var succeededAssignColorImage: UIImage!
    
    // prefer to hide the status bar, which interferes with the experience.
    override var prefersStatusBarHidden: Bool {
        return true
    }

    // functions to create our selectedItem1, selectedItem2, selectedItem3 and Back buttons
    func makeBackButton(text: String) -> UIButton {
        let myButton = UIButton(type: UIButtonType.custom)
        // set position and size of button
        myButton.frame = CGRect(x: 0.02 * screenSize.width, y: 0.02 * screenSize.height, width: 0.10 * screenSize.width, height: 0.10 * screenSize.height)
        myButton.layer.cornerRadius = 4                 // round the corners of the button
        myButton.layer.masksToBounds = true             // apply the rounding to the image on the button as well.
        let backButtonImage = allModelsAndMaterials.backButtonImage
        myButton.setImage(backButtonImage, for: UIControlState.normal)
        
        myButton.addTarget(self, action: #selector(goBack), for: .touchDown)
        return myButton
    }

    func makeSelectedItem1Button(text: String) -> UIButton {
        let myButton = UIButton(type: UIButtonType.custom)
        // set position and size of button
        myButton.frame = CGRect(x: 0.20 * screenSize.width, y: 0.15 * screenSize.height, width: 0.15 * screenSize.height, height: 0.15 * screenSize.height)
        // set background color for button
        myButton.backgroundColor = initialSelectionColor
        myButton.setTitleColor(UIColor.black, for: .normal)
        myButton.setBackgroundImage(allModelsAndMaterials.inventoryImages[text], for: .normal)
        myButton.layer.borderWidth = 4.0
        myButton.layer.borderColor = UIColor.purple.cgColor
        myButton.addTarget(self, action: #selector(setSelectedItem1), for: .touchDown)
        return myButton
    }

    func makeSelectedItem2Button(text: String) -> UIButton {
        let myButton = UIButton(type: UIButtonType.custom)
        // set position and size of button
        myButton.frame = CGRect(x: 0.20 * screenSize.width, y: 0.45 * screenSize.height, width: 0.15 * screenSize.height, height: 0.15 * screenSize.height)
        // set background color for button
        myButton.backgroundColor = initialSelectionColor
        myButton.setTitleColor(UIColor.black, for: .normal)
        myButton.setBackgroundImage(allModelsAndMaterials.inventoryImages[text], for: .normal)
        myButton.layer.borderWidth = 4.0
        myButton.layer.borderColor = UIColor.purple.cgColor
        myButton.addTarget(self, action: #selector(setSelectedItem2), for: .touchDown)
        return myButton
    }

    func makeSelectedItem3Button(text: String) -> UIButton {
        let myButton = UIButton(type: UIButtonType.custom)
        // set position and size of button
        myButton.frame = CGRect(x: 0.20 * screenSize.width, y: 0.70 * screenSize.height, width: 0.15 * screenSize.height, height: 0.15 * screenSize.height)
        // set background color for button
        myButton.backgroundColor = initialSelectionColor
        myButton.setTitleColor(UIColor.black, for: .normal)
        myButton.setBackgroundImage(allModelsAndMaterials.inventoryImages[text], for: .normal)
        myButton.layer.borderWidth = 4.0
        myButton.layer.borderColor = UIColor.purple.cgColor
        myButton.addTarget(self, action: #selector(setSelectedItem3), for: .touchDown)
        return myButton
    }

    func makeAllowedSelectionTypeImage(itemType: PartType , location: CGPoint) -> UIImageView {
        let itemTypeImage: UIImageView = UIImageView()
        // Note: we use the part type interchangably with item type.  In essence the item is
        // just the parts accumulated.
        switch itemType {
        case .ammoPart:
            itemTypeImage.image = allModelsAndMaterials.ammoTypeImage
        case .weaponPart:
            itemTypeImage.image = allModelsAndMaterials.weaponTypeImage
        case .equipmentPart:
            itemTypeImage.image = allModelsAndMaterials.equipmentTypeImage
        default:
            break
        }
        // Note: we use the height for both dimensions as that is the smaller dimension in landscape mode.
        itemTypeImage.frame = CGRect(x: location.x, y: location.y, width: 0.15 * screenSize.height, height: 0.15 * screenSize.height)
        return itemTypeImage
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        modalTransitionStyle = UIModalTransitionStyle.crossDissolve   // use a quick fade in rather than the default bottom-up transition.
        
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

        // Before doing anything else, set up the image of a failed assigment to be applied to
        // a button when the player tries to assign the wrong item to a slot.
        // From: https://stackoverflow.com/questions/38562379/uibutton-background-color-for-highlighted-selected-state-issue/38566083
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        UIGraphicsGetCurrentContext()!.setFillColor(failedAssignColor.cgColor)
        UIGraphicsGetCurrentContext()!.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        failedAssignColorImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        UIGraphicsGetCurrentContext()!.setFillColor(successfullyAssignedColor.cgColor)
        UIGraphicsGetCurrentContext()!.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        succeededAssignColorImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        goBackButton = makeBackButton(text: "Back")
        selectedItem1Button = makeSelectedItem1Button(text: selectedItem1)
        selectedItem2Button = makeSelectedItem2Button(text: selectedItem2)
        let ammoImage = makeAllowedSelectionTypeImage(itemType: .ammoPart, location: CGPoint(x: 0.05 * screenSize.width, y: 0.17 * screenSize.height))
        let weaponImage = makeAllowedSelectionTypeImage(itemType: .weaponPart, location: CGPoint(x: 0.02 * screenSize.width, y: 0.47 * screenSize.height))
        let equipmentImage = makeAllowedSelectionTypeImage(itemType: .equipmentPart, location: CGPoint(x: 0.10 * screenSize.width, y: 0.47 * screenSize.height))
        let weaponImage2 = makeAllowedSelectionTypeImage(itemType: .weaponPart, location: CGPoint(x: 0.02 * screenSize.width, y: 0.72 * screenSize.height))
        let equipmentImage2 = makeAllowedSelectionTypeImage(itemType: .equipmentPart, location: CGPoint(x: 0.10 * screenSize.width, y: 0.72 * screenSize.height))
        
        self.view.addSubview(goBackButton)
        self.view.addSubview(ammoImage)
        self.view.addSubview(weaponImage)
        self.view.addSubview(weaponImage2)
        self.view.addSubview(equipmentImage)
        self.view.addSubview(equipmentImage2)
        self.view.addSubview(selectedItem1Button)
        self.view.addSubview(selectedItem2Button)
        
        selectedItem3Button = makeSelectedItem3Button(text: selectedItem3)
        if selectedItem3.range(of: slot3DisabledLabel) == nil {
            self.view.addSubview(selectedItem3Button)
        }
        
        self.view.backgroundColor = UIColor(red: 0.2, green: 0.0, blue: 0.2, alpha: 1.0)
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: 0.62 * screenSize.width, height: 0.15 * screenSize.height)
        layout.scrollDirection = .vertical
        
        
        itemCollectionView = UICollectionView(frame: CGRect(x: 0.35 * screenSize.width, y: 0.10 * screenSize.height, width: 0.62 * screenSize.width, height: 0.80 * screenSize.height), collectionViewLayout: layout)
        itemCollectionView.register(ItemCollectionViewCell.self, forCellWithReuseIdentifier: "ItemCell")
        
        itemCollectionView.dataSource = self
        itemCollectionView.delegate = self
        itemCollectionView.layer.cornerRadius = backButtonCornerRadius
        itemCollectionView.backgroundColor = UIColor.cyan
        itemCollectionView.showsVerticalScrollIndicator = false
        itemCollectionView.showsHorizontalScrollIndicator = false 
        
        self.view.addSubview(itemCollectionView)

    }
    
    // if there's a new item unlocked we want to center the collection on that new item.  If several items were
    // unlocked we only center on one, obviously.  It should be the first one unlocked in that case.
    override func viewWillAppear(_ animated: Bool) {
        if itemToCenterOn != "" {
            let itemNumber = playerInventoryList.inventoryList[itemToCenterOn]!.indexNum
            let itemsList = playerInventoryList.getListByIndexNum()
            // center only when the item is +2 form the top of the list or -2 from the bottom to avoid trying
            // to center past the list.  We cap the index, idx, at -3 from the end.  That way we don't try
            // to go past the end of the list but still show the bottom of the list.
            if itemNumber > 1 {
                var idx: Int = itemNumber
                if idx > itemsList.count - 3 {
                    idx = itemsList.count - 3
                }
                let indexPath = NSIndexPath(item: idx, section: 0)
                itemCollectionView.scrollToItem(at: indexPath as IndexPath, at: UICollectionViewScrollPosition.centeredVertically, animated: true)
            }
        }
    }
    
    // actions to go with the selectedItem1, selectedItem2, selectedItem3 and Back buttons
    @objc func goBack () {
        gameSounds.playSound(soundToPlay: .buttontap)
        self.performSegue(withIdentifier: "unwindSegueToLevelSelect", sender: self)
    }
    
    @objc func setSelectedItem1() {
        // Make sure selected item is ammo.  Also, leftover code from earlier when we allowed all selections
        // to go to any button but excluded duplicates.  We leave it in place here just in case.
        if selectedItem2 != itemSelected && selectedItem3 != itemSelected && itemTypeSelected == .ammoPart {
            //selectedItem1Button.setTitle(itemSelected, for: .normal)
            //selectedItem1Button.titleLabel?.font = UIFont(name: (selectedItem1Button.titleLabel?.font.fontName)!, size: 8)
            selectedItem1Button.backgroundColor = successfullyAssignedColor
            selectedItem1Button.setBackgroundImage(succeededAssignColorImage, for: .highlighted)
            selectedItem1Button.setBackgroundImage(allModelsAndMaterials.inventoryImages[itemSelected], for: .normal)
            selectedItem1 = itemSelected
            itemCollectionView.reloadData()
        }
        else if itemTypeSelected != .ammoPart {
            selectedItem1Button.setBackgroundImage(failedAssignColorImage, for: .highlighted)
        }
    }
    
    @objc func setSelectedItem2() {
        // Make sure selected item is equipment or weapon.  Also, leftover code from earlier when we allowed all selections
        // to go to any button but excluded duplicates.  We leave it in place here just in case.
        if selectedItem1 != itemSelected && selectedItem3 != itemSelected && (itemTypeSelected == .equipmentPart || itemTypeSelected == .weaponPart) {
            selectedItem2Button.backgroundColor = successfullyAssignedColor
            selectedItem2Button.setBackgroundImage(succeededAssignColorImage, for: .highlighted)
            selectedItem2Button.setBackgroundImage(allModelsAndMaterials.inventoryImages[itemSelected], for: .normal)
            selectedItem2 = itemSelected
            itemCollectionView.reloadData()
        }
        else if itemTypeSelected != .equipmentPart && itemTypeSelected != .weaponPart {
            selectedItem2Button.setBackgroundImage(failedAssignColorImage, for: .highlighted)
        }
    }
    
    @objc func setSelectedItem3() {
        // Make sure selected item is equipment or weapon.  Also, leftover code from earlier when we allowed all selections
        // to go to any button but excluded duplicates.  We leave it in place here just in case.
        if selectedItem1 != itemSelected && selectedItem2 != itemSelected && (itemTypeSelected == .equipmentPart || itemTypeSelected == .weaponPart) {
            selectedItem3Button.backgroundColor = successfullyAssignedColor
            selectedItem3Button.setBackgroundImage(succeededAssignColorImage, for: .highlighted)
            selectedItem3Button.setBackgroundImage(allModelsAndMaterials.inventoryImages[itemSelected], for: .normal)

            selectedItem3 = itemSelected
            itemCollectionView.reloadData()
        }
        else if itemTypeSelected != .equipmentPart && itemTypeSelected != .weaponPart {
            selectedItem3Button.setBackgroundImage(failedAssignColorImage, for: .highlighted)
        }
    }
    
    // collection view specific functions.
    
    // We should only have one section in our collection view, just for listing levels.
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    // The number of items we have corresponds to the number of items we have in the
    // player's inventory.  The count we return from here tells the populate cells
    // code how many inventory items to list out in the collectionview.
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return playerInventoryList.inventoryList.count
    }

    // Get selected item
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let inventory = playerInventoryList.getListByIndexNum()
        itemSelected = inventory[indexPath.row].prizeName
        itemTypeSelected = inventory[indexPath.row].partType
    }
    
    func collectionView(_ collectionView: UICollectionView, titleForHeaderInSection section: Int) -> String? {
        return "Ammo/Weapon/Equipment"
    }

    // collection view method to populate the cells
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let inventory = playerInventoryList.getListByIndexNum()
        let item = inventory[indexPath.row].prizeName
        let numPartsGathered = inventory[indexPath.row].partsGatheredSoFar
        let numPartsRequired = inventory[indexPath.row].requiredNumberOfParts
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ItemCell", for: indexPath) as! ItemCollectionViewCell
        
        cell.itemLabel.numberOfLines = 1   // default to just one line per cell.  Change it below if item is ammo.
        
        var ammoCharacteristics: String = ""
        switch inventory[indexPath.row].partType {
        case .ammoPart:
            cell.itemTypeImage.image = allModelsAndMaterials.ammoTypeImage
            switch inventory[indexPath.row].primaryEffect {
            case .impact:
                if inventory[indexPath.row].mass == large {
                    ammoCharacteristics = "\n(very dense)"
                }
                else {
                    ammoCharacteristics = "\n(dense)"
                }
                // set #lines to 0 to make label multi-line so two lines fit in cell.
                cell.itemLabel.numberOfLines = 0
            case .corrosive:
                if inventory[indexPath.row].corrosiveness == large {
                    ammoCharacteristics = "\n(very corrosive)"
                }
                else {
                    ammoCharacteristics = "\n(corrosive)"
                }
                // set #lines to 0 to make label multi-line so two lines fit in cell.
                cell.itemLabel.numberOfLines = 0
            case .sticky:
                if inventory[indexPath.row].stickiness == large {
                    ammoCharacteristics = "\n(very sticky)"
                }
                else {
                    ammoCharacteristics = "\n(sticky)"
                }
                // set #lines to 0 to make label multi-line so two lines fit in cell.
                cell.itemLabel.numberOfLines = 0
            case .staticDischarge:
                ammoCharacteristics = "\n(static discharge)"
                // set #lines to 0 to make label multi-line so two lines fit in cell.
                cell.itemLabel.numberOfLines = 0
            default:
                break
            }
        case .equipmentPart:
            cell.itemTypeImage.image = allModelsAndMaterials.equipmentTypeImage
        case .weaponPart:
            cell.itemTypeImage.image = allModelsAndMaterials.weaponTypeImage
        default:
            break
        }
        cell.itemSpecificImage.image = allModelsAndMaterials.inventoryImages[item]
        // note: from the above code, ammoCharacteristics is "" unless specific ammo primary effects are true.
        cell.itemLabel.text = item + "    " + String(numPartsGathered) + "/" + String(numPartsRequired) + ammoCharacteristics
        // I don't get it.  We have to always update the font and size to fit to get it to work here
        // but we don't have to do that with the level select screen.  Yet they're both using uicollectionview.
        cell.itemLabel.font = UIFont.systemFont(ofSize: 20.0)
        cell.itemLabel.adjustsFontSizeToFitWidth = true
        
        cell.backgroundColor = UIColor.yellow
        
        // If not unlocked, then gray out the item.  But if it is unlocked, be sure to enable it.  Always
        // gray out the ability to select the third slot.  That will automatically appear once it has been unlocked.
        if (playerInventoryList.inventoryList[item]?.unlocked)! == false || item == selectedItem1 || item == selectedItem2 || item == selectedItem3 || item == extraSlotLabel {
            cell.isUserInteractionEnabled = false
            cell.itemLabel.isEnabled = false
        }
        else {
            cell.isUserInteractionEnabled = true
            cell.itemLabel.isEnabled = true
        }
        return cell
    }
    
    // change background color when user touches cell
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.backgroundColor = UIColor.green
        if lastItemSelected != nil && lastItemSelected != indexPath {
            let cellToUnHighlight = collectionView.cellForItem(at: lastItemSelected)
            cellToUnHighlight?.backgroundColor = UIColor.yellow
        }
        lastItemSelected = indexPath
    }

}
