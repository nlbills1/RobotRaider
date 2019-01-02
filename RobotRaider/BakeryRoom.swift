//
//  BakeryRoom.swift
//  RobotRaider
//
//  Created by Nathanael Bills on 10/13/16.
//  Copyright © 2016 invasivemachines. All rights reserved.
//

import Foundation
import SceneKit

class BakeryRoom {
    
    struct DimensionsOfAWallInLevelCoordinates {
        var rowStart: Int = 0
        var rowEnd: Int = 0
        var colStart: Int = 0
        var colEnd: Int = 0
    }
    
    var walls: [String: Wall] = [:]     // All of the walls in the room, including the four outer walls and all the ones in between.
    var farWallFloorStrip: SCNNode!      // floor strip in front of far wall to hide the fact that the exit sticks out from the wall, which doesn't look right.
    var leftWallName: String = ""
    var rightWallName: String = ""
    var farWallName: String = ""
    var nearWallName: String = ""
    
    init (maze: [[MazeElement]], levelGrid: inout [[[String]]], levelNum: Int) {
        // Note: we assume that the maze is rectangular, hence our use of maze[0].count.  All rows should be the same width so
        // it shouldn't matter which we use to get the number of columns in a row.
        
        // textures for outer and inner walls.
        let outerWallMaterial = SCNMaterial()
        outerWallMaterial.diffuse.contents = allModelsAndMaterials.wallMaterials[outerWallMaterialIndex].diffuse.contents
        let innerWallMaterial = SCNMaterial()
        innerWallMaterial.diffuse.contents = allModelsAndMaterials.wallMaterials[innerWallMaterialIndex].diffuse.contents
        
        // first get the four outer walls: left, right, near and far.
        let leftWall = Wall(maze: maze, levelGrid: &levelGrid, rowStart: 0, rowEnd: maze.count - 1, colStart: 0, colEnd: 2, wallHeight: outerWallHeight, wallMaterial: outerWallMaterial, wallType: .leftwall)
        walls[leftWall.name] = leftWall
        leftWallName = leftWall.name   // note: the official name is something like 'wall_r_c' where r and c are the row and column starts of the wall.
        let rightWall = Wall(maze: maze, levelGrid: &levelGrid, rowStart: 0, rowEnd: maze.count - 1, colStart: maze[0].count - 3, colEnd: maze[0].count - 1, wallHeight: outerWallHeight, wallMaterial: outerWallMaterial, wallType: .rightwall)
        walls[rightWall.name] = rightWall
        rightWallName = rightWall.name
        // Note: we make the wall height for the near wall shorter than the others to prevent the player from tapping on it when he/she
        // should be tapping on some other part of the level.  We also remove the transparency to make it show up clearly so the player
        // can see it.
        let nearWall = Wall(maze: maze, levelGrid: &levelGrid, rowStart: 0, rowEnd: 0, colStart: 3, colEnd: maze[0].count - 4, wallHeight: nearWallHeight, wallMaterial: outerWallMaterial, wallType: .nearwall)
        walls[nearWall.name] = nearWall
        nearWallName = nearWall.name
        // Somehow we have slightly miscalculated the far wall and so we start the far wall at row maze.count -2 rather than maze.count -1.  
        // That seemed to fix the problem.  No time to really figure out what went wrong there.
        let farWall = Wall(maze: maze, levelGrid: &levelGrid, rowStart: maze.count - 2, rowEnd: maze.count - 1, colStart: 3, colEnd: maze[0].count - 4, wallHeight: outerWallHeight, wallMaterial: outerWallMaterial, wallType: .farwall)
        walls[farWall.name] = farWall
        farWallName = farWall.name
        
        var floorStripLength: CGFloat!
        
        // The vault is much larger than a normal exit so we make the floor strip longer to cover the vault floor.
        if levelNum == highestLevelNumber {
            floorStripLength = 8.0
        }
        else {
            floorStripLength = 5.0
        }
        let farWallFloorStripGeometry = SCNBox(width: farWall.width, height: 0.1, length: floorStripLength, chamferRadius: 0.0)
        farWallFloorStrip = SCNNode(geometry: farWallFloorStripGeometry)
        // place the floor strip just above the floor and just in front of the far wall.
        farWallFloorStrip.position.x = farWall.wallNode.position.x
        farWallFloorStrip.position.y = 0.05
        farWallFloorStrip.position.z = farWall.wallNode.position.z + Float(farWall.length) / 2.0
        // make floor strip dark gray to mask the bottom of the exit from view.
        farWallFloorStrip.geometry?.firstMaterial?.diffuse.contents = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        
        // Next, get the inner walls, the ones in the middle of the level or maze.
        let innerWallStarts = findInnerWallsStartingPoints(maze: maze)
        
        // Finally, create all those inner walls.
        for anInnerWallStart in innerWallStarts {
            let wallDim = getWallDimensions(maze: maze, wallStart: anInnerWallStart)
            let innerWall = Wall(maze: maze, levelGrid: &levelGrid, rowStart: wallDim.rowStart, rowEnd: wallDim.rowEnd, colStart: wallDim.colStart, colEnd: wallDim.colEnd, wallHeight: innerWallHeight, wallMaterial: innerWallMaterial, wallType: .innerwall)
            walls[innerWall.name] = innerWall
        }
    }
    
    // Find the starting bottom left corner of each inner wall. A separate function will get the wall dimensions.
    func findInnerWallsStartingPoints(maze: [[MazeElement]]) -> [LevelCoordinates]{
        var newWallStarts: [LevelCoordinates] = []
        
        // look at only the area inside the outer walls for any row,column where it is a wall
        // yet the row, column to the left and just below are not wall blocks.  If that is the
        // case then we have a start of a new wall.
        // Remember: walls are +1 in row direction but +3 in column direction
        for row in 1...maze.count - 2 {
            for col in 3...maze[0].count - 4 {
                // Note: row - 1 = 0 is a special case where the inner wall is connected to the near wall.  In that case we want
                // to ignore the check for the the location below the starting point to make sure it is not .Wall.  Otherwise we
                // would never see a wall build close to the near wall.
                if maze[row][col].type == .wall && (maze[row - 1][col].type != .wall || row - 1 == 0) && maze[row][col - 1].type != .wall {
                    newWallStarts.append(LevelCoordinates(row: row, column: col))
                }
            }
        }
        return newWallStarts
    }
    
    // Get the wall dimensions for one wall.  We can then use that to build the wall with the Wall class.
    func getWallDimensions(maze: [[MazeElement]], wallStart: LevelCoordinates) -> DimensionsOfAWallInLevelCoordinates {
        var row = wallStart.row
        var col = wallStart.column
        var wallDimensions: DimensionsOfAWallInLevelCoordinates = DimensionsOfAWallInLevelCoordinates()
        
        // Remember: walls are +1 in row direction but +3 in column direction
        while row < maze.count - 2 && maze[row][wallStart.column].type == .wall {
            row += 1
        }
        while col < maze[wallStart.row].count - 4 && maze[wallStart.row][col].type == .wall {
            col += 1
        }

        wallDimensions.rowStart = wallStart.row
        wallDimensions.rowEnd = row - 1
        wallDimensions.colStart = wallStart.column
        wallDimensions.colEnd = col - 1
        
        return wallDimensions
    }
}
