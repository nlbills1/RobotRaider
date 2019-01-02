//
//  EmptySpacesList.swift
//  RobotRaider
//
//  Created by Nathanael Bills on 7/19/17.
//  Copyright © 2017 invasivemachines. All rights reserved.
//

import Foundation

// store all the empty spaces in the maze in a list that we virtually
// break up into regions.  The list remains whole but we use region
// numbers to skip around throughout the list.
class EmptySpacesList {
    var emptySpaces: [MazeElement] = []
    var regionSize: Int = 0
    var numRegions: Int = 0
    var indexByIdNumber: [Int : Int] = [ : ]
    
    init(numRegions: Int, maze: [[MazeElement]]) {
        let numRows = maze.count
        let numCols = maze[0].count      // assumes that the maze is rectangle
        
        self.numRegions = numRegions
        
        // save just the elements in the maze that are of type .Space
        for row in 0...numRows - 1 {
            for col in 0...numCols - 1 {
                if maze[row][col].type == .space {
                    emptySpaces.append(maze[row][col])
                }
            }
        }
        self.regionSize = emptySpaces.count / numRegions
        
        // set up indexing by unique id number.  This makes it easy to find
        // and update elements in emptySpaces
        for i in 0...emptySpaces.count - 1 {
            indexByIdNumber[emptySpaces[i].number] = i
        }

    }
    

}
