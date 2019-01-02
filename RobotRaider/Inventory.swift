//
//  Inventory.swift
//  RobotRaider
//
//  Created by Nathanael Bills on 8/22/17.
//  Copyright © 2017 invasivemachines. All rights reserved.
//

import Foundation
import SceneKit

class Inventory {
    var inventoryList: [String : PrizeListElement] = [ : ]
    
    // Create the inventory by combining the default two entries that every player
    // has at the beginning of the game along with the prize list that the player has
    // to earn along the way.  The reference is generally by the item's name but we also
    // save an index number just in case we want to reference it that way, which we do
    // when we go to create a list for a table view.
    init () {
        var i = 0
        while i < defaultInventoryList.count {
            let itemName = defaultInventoryList[i].prizeName
            inventoryList[itemName] = defaultInventoryList[i]
            inventoryList[itemName]?.indexNum = i
            i += 1
        }
        // Note: after the while loop above, i = 2, which breaks it out of that loop.  Thus,
        // j+i starts at 2, not 1.  It can be confusing if we ignore that in order to
        // get out of the loop above i has to be > 1.  When we look at the code, we may not
        // think of it so I'm mentioning it here.  I was confused when I went to look back at
        // this code because I kept thinking that i was 1 at the end of the while loop because that's
        // what i was the last time through the loop. -- nlb
        var j = 0
        while j < prizesList.count {
            let itemName = prizesList[j].prizeName
            inventoryList[itemName] = prizesList[j]
            inventoryList[itemName]?.indexNum = j+i
            j += 1
        }
    }
    
    // get the parts list and update the inventory from all the retrieved flag states
    func updateInventory(partsList: [Int : Part], lastLevelStatus: LevelStatus, levelStats: inout LevelStats) {
        let partNumbers = partsList.keys
        var prizePartCounts: [String : Int] = [ : ]

        // Note: we have to clear out the partsGatheredSoFar because we recalculate that with each update.
        for aPrizeName in inventoryList.keys {
            inventoryList[aPrizeName]?.partsGatheredSoFar = 0
        }
        
        for aPartNumber in partNumbers {
            // if prize isn't currently in our prizePartCounts dictionary, initialize it to zero.
            if prizePartCounts.index(forKey: (partsList[aPartNumber]?.prizeName)!) == nil {
                prizePartCounts[(partsList[aPartNumber]?.prizeName)!] = 0
            }
            if partsList[aPartNumber]?.retrieved == true {
                prizePartCounts[(partsList[aPartNumber]?.prizeName)!]! += 1  // Note: we force the unwrapping here because we know that it will have
                // been assigned zero before this statement has been reached.
            }
        }

        // Always, always unlock the default choices.
        for aDefaultItem in 0...defaultInventoryList.count - 1 {
            inventoryList[defaultInventoryList[aDefaultItem].prizeName]?.unlocked = true
        }
        
        for aPrizeName in prizePartCounts.keys {
            inventoryList[aPrizeName]?.partsGatheredSoFar = prizePartCounts[aPrizeName]!
            if prizePartCounts[aPrizeName]! >= (inventoryList[aPrizeName]?.requiredNumberOfParts)! {
                // Make sure the prize wasn't unlocked before, and that the level was just completed, before we add it
                // to our list of prizes to show in the popup as just being unlocked.
                if inventoryList[aPrizeName]?.unlocked == false && lastLevelStatus == .levelCompleted {
                    levelStats.prizesJustUnlocked.append(aPrizeName)
                }
                inventoryList[aPrizeName]?.unlocked = true
            }
        }
    }
    
    func showInventory() {
        var inventoryByIndexNum: [Int : String] = [ : ]
        for aPrizeName in inventoryList.keys {
            inventoryByIndexNum[(inventoryList[aPrizeName]?.indexNum)!] = aPrizeName
        }
    }
    
    // We may want to return the inventory as a sequential list.  For example, when we go to put the
    // inventory in a tableview.
    func getListByIndexNum() -> [PrizeListElement] {
        var inventoryByIndexNum: [Int : String] = [ : ]
        var inventoryAsSequentialList: [PrizeListElement] = []
        for aPrizeName in inventoryList.keys {
            inventoryByIndexNum[(inventoryList[aPrizeName]?.indexNum)!] = aPrizeName
        }
        let indexNums = inventoryByIndexNum.keys.sorted()
        for aNum in indexNums {
            inventoryAsSequentialList.append(inventoryList[inventoryByIndexNum[aNum]!]!)
        }
        return inventoryAsSequentialList
    }
    
    // get the list of ammo that the player can use and set that back as a list of names.
    // This is also needed by the ai robots, which can use the same ammo that the player can.
    func getUnlockedAmmoListByName() -> [String] {
        let ascendingOrderedList = getListByIndexNum()
        var unlockedAmmoList: [String] = []
        
        for i in 0...ascendingOrderedList.count - 1 {
            if ascendingOrderedList[i].partType == .ammoPart && ascendingOrderedList[i].unlocked == true {
                unlockedAmmoList.append(ascendingOrderedList[i].prizeName)
            }
        }
        return unlockedAmmoList
    }
    
}
