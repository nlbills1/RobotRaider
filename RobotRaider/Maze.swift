//
//  Maze.swift
//  MazeGen
//
//  Created by Nathanael Bills on 7/7/17.
//  Copyright © 2017 invasivemachines. All rights reserved.
//

import Foundation

// The maze is the detailed positioning of the walls and fixed level components of the level.
// The level coordinates in the maze is _exactly_ the same as the level coordinates in the level.
// The have to be to make it all work seamlessly.
class Maze {
    var height: Int = 0
    var width: Int = 0
    var theMaze: [[MazeElement]] = []           // the resulting maze we want
    var theMazeExpanded: [[MazeElement]] = []   // The resulting maze with expanded spaces to make navigating it easier.
                                                // IMPORTANT NOTE: What may not be clear is that the row, column in the maze
                                                // _exactly_ corresponds to the row, column in the levelGrid in the Level class.
                                                // the row, column in theMazeExpanded needs to match the row, column in the levelGrid.
                                                // Otherwise everything breaks down like a house of cards.
    
    var expandedMazeEntrance: [MazeElement] = []    // The maze dimensions change when it is expanded.  So we save copies of the entrance and
    var expandedMazeExit: [MazeElement] = []        // exit here for the expanded maze as reference for where we put the entrance and exit
                                                    // in the scene later.
    
    var chosenExitQuadrant: Int = -1                // default to no exit quadrant.  This is filled in as soon as the exit has been chosen.
                                                    // The chosen exit quadrant and the expanded maze exit will be combined to determine the
                                                    // size, orientation and location of the exit.  The maze entrance is always against the
                                                    // near wall so we only have to worry size and location for it.
    
    var elementCount: Int = 0
    var startPoint: MazeElement = MazeElement()
    var levelNum: Int = 0
    
    init (numRows: Int, numCols: Int, level: Int, randomGenerator: RandomNumberGenerator) {
        height = numRows * 2 + 1
        width = numCols * 2 + 1
        levelNum = level
        var blankMaze: [[MazeElement]] = []
        
        blankMaze = createBlankMaze(width: width, height: height)
        theMaze = carveOutMaze(randomGen: randomGenerator, blankMaze: blankMaze)
        convertNoWallToSpace()
        randomlyRemoveWalls(randomNumGen: randomGenerator)
        placeEntrance()
        placeExit(randomGen: randomGenerator)
        expandMazeSpacesAndPlaceFixedLevelComponents()
        adjustCoordinatesAfterMazeExpansionAndRecordEntranceAndExit()
        //showMaze(maze: theMaze, start: startPoint)
        //print ("Expanded final maze:")
        //print ("Size: #rows = \(theMazeExpanded.count), #cols = \(theMazeExpanded[0].count)")
        //showMaze2(maze: theMazeExpanded)  // Note: start point will not be shown, just the entrance.
    }
    
    // Create a blank maze of nothing but evenly spaced walls and spaces.  Later we carve through
    // the walls to create the maze.
    func createBlankMaze(width: Int, height: Int) -> [[MazeElement]] {
        var blankMaze: [[MazeElement]] = []
        
        blankMaze = Array(repeating: Array(repeating: MazeElement(), count: width), count: height)
        for row in 0...height - 1 {
            for col in 0...width - 1 {
                var mazeElement: MazeElement = MazeElement()
                mazeElement.coords = LevelCoordinates()
                mazeElement.status = MazeElementStatus.notConnected
                mazeElement.coords.row = row
                mazeElement.coords.column = col
                if row % 2 == 0 || col % 2 == 0 {
                    mazeElement.type = MazeElementType.wall
                }
                else {
                    mazeElement.type = MazeElementType.space
                }
                mazeElement.number = elementCount
                elementCount += 1
                blankMaze[row][col] = mazeElement
            }
        }
        return blankMaze
    }
    // We start out with a uniform grid of spaces and walls and 'carve' out our maze using
    // a modification of Prim's algorithm, as described at:
    // http://weblog.jamisbuck.org/2011/1/10/maze-generation-prim-s-algorithm
    func carveOutMaze(randomGen: RandomNumberGenerator, blankMaze: [[MazeElement]]) -> [[MazeElement]] {
        var iterations: Int = 0
        var maze: [[MazeElement]] = blankMaze // when this function is run, the blankMaze has yet to
                                              // be turned into a maze.  It starts off as a grid of spaces and walls
                                              // and this function will carve out the maze and return it ready to be used.
        
        let row = 1
        let rowOfSpacesWherePlayerStarts = getSpaces(rowInMaze: maze[row])
        let allSpacesSet = getAllSpacesSet(maze: maze)
        let startSpaceIndex = randomGen.xorshift_randomgen() % rowOfSpacesWherePlayerStarts.count
        var startSpace = rowOfSpacesWherePlayerStarts[startSpaceIndex]
        startSpace.status = .connected
        startPoint = startSpace             // save the starting point so we know where we started when the maze is displayed.
        maze[startPoint.coords.row][startPoint.coords.column] = startPoint    // always, always have to update the maze with any changes.
        //print("starting point: \(startPoint)")
        var frontierSpaces = getFrontierNeighbors(space: startSpace, maze: maze)
        var connectedSpacesSet: Set<Int> = [startSpace.number]
        
        while connectedSpacesSet != allSpacesSet {
            // find the neareast neighbor at the frontier where none are connected yet.
            let aNeighborIndex = randomGen.xorshift_randomgen() % frontierSpaces.count
            var aNeighbor = frontierSpaces[aNeighborIndex]
            aNeighbor.status = .connected
            // Let's not forget to update the maze element with the change in the neighbor's status.  Otherwise
            // nothing will change and we'll keep working with the same neighbors over and over again.
            maze[aNeighbor.coords.row][aNeighbor.coords.column] = aNeighbor
            frontierSpaces.remove(at: aNeighborIndex)  // Since aNeighbor is now connected, it's no longer a frontier space.
            let newFrontierSpaces = getFrontierNeighbors(space: aNeighbor, maze: maze)
            
            // in a roundabout way we merge newFrontierSpaces into frontierSpaces.
            var frontierSpacesSet = getSpacesSet(spacesArray: frontierSpaces)
            for aFrontierSpace in newFrontierSpaces {
                if !frontierSpacesSet.contains(aFrontierSpace.number) {
                    frontierSpaces += [aFrontierSpace]
                    frontierSpacesSet.insert(aFrontierSpace.number)
                }
            }
            
            // get the space already connected that connects to aNeighbor.  We will tie aNeighbor
            // to the maze by 'carving' out the wall between it and that space already connected to
            // the rest of the maze.  If we have more than one already connected that's the neighbor
            // of aNeighbor, then we randomly pick one.
            var connectedSpace: MazeElement = MazeElement()
            let connectedToANeighbor = getOnlyConnectedSpaces(space: aNeighbor, maze: maze)
            if connectedToANeighbor.count > 1 {
                let connectedSpaceIndex = randomGen.xorshift_randomgen() % connectedToANeighbor.count
                connectedSpace = connectedToANeighbor[connectedSpaceIndex]
            }
            else {
                connectedSpace = connectedToANeighbor[0]   // there's only one so we take that one.
            }
            
            // carve through wall by setting it to 'NoWall' instead of Space.  Later we will turn all NoWalls to Spaces
            // but for now we don't because we may inadvertently confuse the algorithm with a bunch of new spaces.
            // We already know they'll be connected so we can just label them as connected spaces later, when we change
            // them from NoWall to Space.
            var wall = getTheWallBetween(connectedSpace: connectedSpace, spaceToConnect: aNeighbor, maze: maze)
            wall.type = .noWall
            maze[wall.coords.row][wall.coords.column] = wall
            connectedSpacesSet.insert(aNeighbor.number)       // update the set of connected spaces set with the neighbor just connected.
            iterations += 1
            //print ("Iteration: \(iterations)")
            //showIntermediateMaze(maze: maze, start: startPoint, neighborChosen: aNeighbor, frontierNeighborsSet: frontierSpacesSet)
        }
        return maze
    }
    
    // show maze
    func showMaze(maze: [[MazeElement]], start: MazeElement) {
        print ("----------")
        for aRow in (0...maze.count - 1).reversed() {
            var rowStr: String = ""
            for aCol in 0...maze[0].count - 1 {
                if aRow == start.coords.row && aCol == start.coords.column {
                    rowStr += "S"
                }
                else if maze[aRow][aCol].type == .space {
                    rowStr += " "
                }
                else if maze[aRow][aCol].type == .noWall {
                    rowStr += "x"
                }
                else if maze[aRow][aCol].type == .wall {
                    if aRow % 2 == 0 {
                        rowStr += "-"
                    }
                    else {
                        rowStr += "|"
                    }
                }
                else if maze[aRow][aCol].type == .mazeEntrance {
                    rowStr += "E"
                }
                else if maze[aRow][aCol].type == .mazeExit {
                    rowStr += "X"
                }
            }
            print(rowStr)
        }
        print ("----------")
    }
    
    // show maze2 - note we don't show the starting point, just the
    // entrance.  We do this because we mark the entrance in the
    // maze but the starting point is a location, not a thing so when
    // we expanded the maze horizontally the starting point was in the 
    // wrong place.  So we don't show it.  When we go to place the
    // player in the level we will use the entrance as a guide since the
    // player should start where the player's robot has just entered
    // the level.
    func showMaze2(maze: [[MazeElement]]) {
        print ("----------")
        for aRow in (0...maze.count - 1).reversed() {
            var rowStr: String = ""
            for aCol in 0...maze[0].count - 1 {
                if maze[aRow][aCol].type == .space {
                    rowStr += " "
                }
                else if maze[aRow][aCol].type == .noWall {
                    rowStr += "x"
                }
                else if maze[aRow][aCol].type == .wall {
                    rowStr += "o"
                }
                else if maze[aRow][aCol].type == .mazeEntrance {
                    rowStr += "E"
                }
                else if maze[aRow][aCol].type == .mazeExit {
                    rowStr += "X"
                }
                else if maze[aRow][aCol].type == .fixedLevelComponent {
                    rowStr += "F"
                }
            }
            print(rowStr)
        }
        print ("----------")
    }

    // show snapshot of the maze as it's building.
    func showIntermediateMaze(maze: [[MazeElement]], start: MazeElement, neighborChosen: MazeElement, frontierNeighborsSet: Set<Int>) {
        print ("----------")
        for aRow in (0...maze.count - 1).reversed() {
            var rowStr: String = ""
            for aCol in 0...maze[0].count - 1 {
                if maze[aRow][aCol].number == neighborChosen.number {
                    rowStr += "N"
                }
                else if frontierNeighborsSet.contains(maze[aRow][aCol].number) {
                    rowStr += "F"
                }
                else if aRow == start.coords.row && aCol == start.coords.column {
                    rowStr += "S"
                }
                else if maze[aRow][aCol].type == .space {
                    rowStr += " "
                }
                else if maze[aRow][aCol].type == .noWall {
                    rowStr += "x"
                }
                else if maze[aRow][aCol].type == .wall {
                    if aRow % 2 == 0 {
                        rowStr += "-"
                    }
                    else {
                        rowStr += "|"
                    }
                }
            }
            print(rowStr)
        }
        print ("----------")
    }
    
    // return the maze element that represents the wall between the space we're trying to connect to the maze and the
    // the space already connected.
    func getTheWallBetween(connectedSpace: MazeElement, spaceToConnect: MazeElement, maze: [[MazeElement]]) -> MazeElement {
        var wall: MazeElement = MazeElement()
        
        let rowDelta = connectedSpace.coords.row - spaceToConnect.coords.row
        let colDelta = connectedSpace.coords.column - spaceToConnect.coords.column
        
        if rowDelta > 0 {
            wall = maze[connectedSpace.coords.row - 1][connectedSpace.coords.column]
        }
        else if rowDelta < 0 {
            wall = maze[connectedSpace.coords.row + 1][connectedSpace.coords.column]
        }
        else if colDelta > 0 {
            wall = maze[connectedSpace.coords.row][connectedSpace.coords.column - 1]
        }
        else if colDelta < 0 {
            wall = maze[connectedSpace.coords.row][connectedSpace.coords.column + 1]
        }
        else {
            print ("Error: connectedSpace and spaceToConnect are in the same place: row = \(connectedSpace.coords.row), col = \(connectedSpace.coords.column)")
        }
        return wall
    }
    
    // get all the spaces in a row -- in other words, return just spaces, no walls.
    // for now we use this just for getting our starting place for the maze but later
    // we may have other uses for it.
    func getSpaces(rowInMaze: [MazeElement]) -> [MazeElement] {
        var spaces: [MazeElement] = []
        for aLocInMaze in 0...rowInMaze.count - 1 {
            if rowInMaze[aLocInMaze].type == .space {
                spaces.append(rowInMaze[aLocInMaze])
            }
        }
        return spaces
    }
    
    // return a set of integers where each integer represents an element in the maze.
    // The number can also be used to reference the element.
    func getAllSpacesSet(maze: [[MazeElement]]) -> Set<Int> {
        var allSpacesSet: Set<Int> = []
        for aRow in 0...maze.count - 1 {
            for aCol in 0...maze[aRow].count - 1 {
                if maze[aRow][aCol].type == .space {
                    allSpacesSet.insert(maze[aRow][aCol].number)
                }
            }
        }
        return allSpacesSet
    }
    
    // return a set of integers where each integer represents an element in an array
    // of spaces.  This assumes that what is passed is an array of spaces.
    func getSpacesSet(spacesArray: [MazeElement]) -> Set<Int> {
        var spacesSet: Set<Int> = []
        
        for aSpace in spacesArray {
            spacesSet.insert(aSpace.number)
        }
        return spacesSet
    }
    
    // Get all of the neighboring spaces of a particular space in question.  Note:
    // we always look two elements away because the maze starts out with a wall 
    // between every space.  Even when the wall is removed, it has a temporary
    // status of 'NoWall' to avoid any confusion while we carve out the maze.  Once
    // the process is done, then we change the NoWall elements to Space elements.
    func getNeighbors(space: MazeElement, maze: [[MazeElement]]) -> [MazeElement] {
        var neighbors: [MazeElement] = []
        
        // make sure we stay in the bounds of the maze when getting neighbors.  Otherwise,
        // we get an 'Index out of range' error.
        if space.coords.row + 2 <= maze.count - 1 {
            neighbors.append(maze[space.coords.row + 2][space.coords.column])
        }
        if space.coords.row - 2 >= 0 {
            neighbors.append(maze[space.coords.row - 2][space.coords.column])
        }
        if space.coords.column + 2 <= maze[0].count - 1 {
            neighbors.append(maze[space.coords.row][space.coords.column + 2])
        }
        if space.coords.column - 2 >= 0 {
            neighbors.append(maze[space.coords.row][space.coords.column - 2])
        }
        
        return neighbors
    }
    
    // get all of the neighbors that are at the 'edge' of the space, meaning the 
    // elements that have not been included in the constructed maze yet.  The name
    // 'frontier' is something used in the article at:
    //
    // http://weblog.jamisbuck.org/2011/1/10/maze-generation-prim-s-algorithm
    // 
    // and it seems fitting here.
    func getFrontierNeighbors(space: MazeElement, maze: [[MazeElement]]) -> [MazeElement] {
        var neighbors: [MazeElement] = []
        var frontierNeighbors: [MazeElement] = []
        
        neighbors = getNeighbors(space: space, maze: maze)
        for aNeighbor in neighbors {
            if aNeighbor.status != .connected {
                frontierNeighbors.append(aNeighbor)
            }
        }
        return frontierNeighbors
    }
    
    // We want to get the connected spaces because we want to find which spaces are connected
    // to the one of interest.  When there are more than one then we have to decide which
    // one to actually connect to the other.
    func getOnlyConnectedSpaces(space: MazeElement, maze: [[MazeElement]]) -> [MazeElement] {
        var neighbors: [MazeElement] = []
        var connectedNeighbors: [MazeElement] = []
        
        neighbors = getNeighbors(space: space, maze: maze)
        for aNeighbor in neighbors {
            if aNeighbor.status == .connected {
                connectedNeighbors.append(aNeighbor)
            }
        }
        return connectedNeighbors
    }
    
    // We're done with the maze creation so change any 'NoWall' elements to 'Space' element.
    // The 'NoWall' was used in the maze carving out process to avoid confusing the algorithm.
    // If we had put in 'Space' in those places that would have been the correct final result but
    // it could have confused the algorithm, which looked for Space elements to treat as neighbors.
    func convertNoWallToSpace() {
        for aRow in 0...theMaze.count - 1 {
            for aCol in 0...theMaze[aRow].count - 1 {
                if theMaze[aRow][aCol].type == .noWall {
                    theMaze[aRow][aCol].type = .space
                }
            }
        }
    }
    
    // Actually, we don't randomly remove walls through the whole space but randomly in smaller
    // evenly-spaced chunks.  That way we get an even distribution of random wall removal.  Otherwise 
    // we might wind up with too many walls being removed in one place and not enough removed in 
    // another.
    func randomlyRemoveWalls(randomNumGen: RandomNumberGenerator) {
        
        // Constants we use only in this function so we don't bother to make them globally accessible.
        let groupsOfWalls = 5                   // we want to group the walls into this many groups
        let fractionOfWallsToRemove = 0.20      // The fraction of walls that we want to remove from a group - 0.20 = remove 20% of the walls.
        var wallsThatCanBeRemoved: [MazeElement] = []
        
        for aRow in 0...theMaze.count - 1 {
            for aCol in 0...theMaze[aRow].count - 1 {
                // consider only the inner walls to be viable candidates to remove.  The walls along the edge and anything not a wall are off
                // limits.
                if aRow > 0 && aRow < theMaze.count - 1 && aCol > 0 && aCol < theMaze[aRow].count - 1 && theMaze[aRow][aCol].type == .wall {
                    wallsThatCanBeRemoved.append(theMaze[aRow][aCol])
                }
            }
        }
        
        let maxWallsPerGroup = wallsThatCanBeRemoved.count / groupsOfWalls   // Maximum number of walls per group of walls from which we can choose randomly.
        let maxWallsPerGroupToRemove = Int(fractionOfWallsToRemove * Double(maxWallsPerGroup))
        
        for aGroup in 0...groupsOfWalls - 1 {
            var wallsToRemoveSet: Set<Int> = []
            let startOfGroup = aGroup * maxWallsPerGroup
            for _ in 0...maxWallsPerGroupToRemove - 1 {
                // Only randomly remove walls if there are at least maxWallsPerGroup from which to choose.
                // Otherwise we're toward the end of the list and there may not be that many from which to
                // remove.  In that case we don't remove any walls randomly as we don't want to remove a bunch 
                // of walls from an already small group.
                if wallsThatCanBeRemoved.count - startOfGroup > maxWallsPerGroup {
                    let wallToRemoveInGroup = randomNumGen.xorshift_randomgen() % maxWallsPerGroup
                    wallsToRemoveSet.insert(wallToRemoveInGroup)
                }
            }
            let wallsToRemoveList = Array(wallsToRemoveSet)
            for aWallNum in wallsToRemoveList {
                let wallToRemoveNum = startOfGroup + aWallNum
                let wallToRemove = wallsThatCanBeRemoved[wallToRemoveNum]
                theMaze[wallToRemove.coords.row][wallToRemove.coords.column].type = .space
            }
        }
    }
    
    // placing the exit is a bit trickier than placing the entrance.  Whereas the entrance is just behind 
    // the player once the player has entered the level, the exit can be along each of the three walls in
    // front of the player.  We choose to put the exit at least half way down the right or left walls or
    // on the far wall.  That way the player can see the exit from the entrance.  If we put the exit any 
    // closer than that along the left or right walls the player may not be able to see it because the
    // camera view doesn't cover to the far right or left close to the player.  We consider the forward half
    // of the left wall, two halves of the far wall and the forward half of the right wall each one of
    // four quadrants.  We randomly select a quandrant in which to place the exit.  Once that has been
    // selected we then randomly select a place within that quadrant to put the exit.  
    // Note: Normally we would keep track of which quadrant is chosen to prevent the same one from being
    // chosen too many times in rapid succession, which can happen even when we're choosing them randomly.
    // But we're not doing that because that would mean having a dependency from one level to the next.  We
    // try to avoid that because we want each level to be independent.  That way we can use the level number for
    // the seed to the random number generator and always get the same level layout each time we go to a level.
    // So instead we have to use the level number to keep the same quadrant from being chosen again and again.
    // Sadly, I have not figured out a way to really do that yet.  A quick test with 100 levels shows that we
    // do see the same quadrant chosen a lot of the time.
    // The quadrants are hard-coded below.  Although this is generally bad practice they won't be
    // used outside of this function.  And as big as the maze might get, at this point we don't see any
    // reason we should make the sections of walls smaller, or bigger.
    func placeExit(randomGen: RandomNumberGenerator) {
        
        var startRow: Int = 0
        var endRow: Int = 0
        var startCol: Int = 0
        var endCol: Int = 0
        
        var levelRandomNum: Int!
        
        // Our attempt to insert some measure to keep exits from being clumped as can happen when
        // randomly selecting numbers.  Even if the same number appears multiple times in a row, the
        // algorithm is still choosing numbers randomly.  They can just happen to be the same for a 
        // string of numbers.  It seems to work ok, although not great.
        if levelNum % 5 == 0 {
            levelRandomNum = randomGen.xorshift_randomgen() % (levelNum * 7)
        }
        else {
            levelRandomNum = randomGen.xorshift_randomgen() % levelNum
        }
        chosenExitQuadrant = levelRandomNum % 2

        switch chosenExitQuadrant {
        case farWallLeft:         // far border wall, left side.
            startRow = theMaze.count - 1
            endRow = theMaze.count - 1
            startCol = 1    // start off just to the right of the left wall to avoid the corner exit being placed just to the left of the left wall.
            endCol = theMaze[0].count / 2   // we assume the maze is a rectangle.  How could we change this for a more
                                            // generic shape?
        case farWallRight:         // far border wall, right side.
            startRow = theMaze.count - 1
            endRow = theMaze.count - 1
            startCol = theMaze[0].count / 2 + 1
            endCol = theMaze[0].count - 2        // start off to the left of the right wall to avoid the corner exit being placed just to the right of the right wall.
        default:
            break
        }
        
        let quadrantElements = getMazeElementsInQuadrant(startRow: startRow, endRow: endRow, startCol: startCol, endCol: endCol, exitQuadrant: chosenExitQuadrant)
        let exitMazeElement = quadrantElements[randomGen.xorshift_randomgen() % quadrantElements.count]
        theMaze[exitMazeElement.coords.row][exitMazeElement.coords.column].type = .mazeExit
        //print ("quadrantElements = \(quadrantElements)")
        //print ("Maze exit at location: \(exitMazeElement.coords.row), \(exitMazeElement.coords.column)")
    }
    
    func getMazeElementsInQuadrant(startRow: Int, endRow: Int, startCol: Int, endCol: Int, exitQuadrant: Int) -> [MazeElement] {
        var mazeElementsInQuadrant: [MazeElement] = []
        
        for row in startRow...endRow {
            for col in startCol...endCol {
                // The far wall has the potential to have a wall in front of where the exit might be
                // placed.  So if placement of the exit is to happen on the far wall, only add that
                // spot to the list of elements under consideration if there is not a wall element
                // in front of it.  Otherwise, access to the exit would be blocked.
                if exitQuadrant == farWallLeft || exitQuadrant == farWallRight {
                    if theMaze[row - 1][col].type != .wall {
                        mazeElementsInQuadrant.append(theMaze[row][col])
                    }
                }
                else {
                    mazeElementsInQuadrant.append(theMaze[row][col])
                }
            }
        }
        return mazeElementsInQuadrant
    }
    
    // place entrance to the maze just south of the player's starting point.  In essence, the
    // player just entered the maze through that entrance.
    func placeEntrance() {
        let mazeEntranceRow = startPoint.coords.row - 1  // The start is inside the maze so we want to create an entrance
                                                         // at the wall just south of that start point.
        let mazeEntranceColumn = startPoint.coords.column
        
        theMaze[mazeEntranceRow][mazeEntranceColumn].type = .mazeEntrance
    }
    
    
    // Note: We define the MazeRow structure here because this is the only place we use it.  It is
    // used in the expandMazeSpaces
    struct MazeRow {
        var rowOfMaze: [MazeElement] = []
        var rowOfEastWestWall: Bool = false
    }
    // Expand the maze to make the spaces larger to make it easier for the player to navigate 
    // the maze.  Otherwise the spaces are too cramped.  Also convert some of the walls to
    // fixed level components if they are not attached to any north-south (i.e. vertical) walls.
    func expandMazeSpacesAndPlaceFixedLevelComponents() {
        var intermediateExpandedMaze: [MazeRow] = []
        
        for aRow in 0...theMaze.count - 1 {
            // put the row into the expanded maze.
            var aMazeRow: MazeRow = MazeRow()
            aMazeRow.rowOfMaze = theMaze[aRow]
            
            // intermediateExpandedMaze.append(theMaze[aRow])
            
            if aRow % 2 == 0 {
                aMazeRow.rowOfEastWestWall = true
                intermediateExpandedMaze.append(aMazeRow)
            }
            else {
                aMazeRow.rowOfEastWestWall = false       // was set in declaration but we set it again here just to be safe
                intermediateExpandedMaze.append(aMazeRow)
                
                // copy more space rows into place, just three more for now.
                for _ in 0...2 {
                    aMazeRow.rowOfMaze = theMaze[aRow]
                    aMazeRow.rowOfEastWestWall = false
                    intermediateExpandedMaze.append(aMazeRow)
                }
            }
        }
        for aRow in 0...intermediateExpandedMaze.count - 1 {
            var aRowOfElements: [MazeElement] = []
            for aCol in 0...intermediateExpandedMaze[aRow].rowOfMaze.count - 1 {
                for _ in 0...2 {
                    aRowOfElements.append(intermediateExpandedMaze[aRow].rowOfMaze[aCol])
                }
            }
            intermediateExpandedMaze[aRow].rowOfMaze = aRowOfElements
        }
        // Assign fixed level components to locations along rows with 
        // walls running mostly east-west
        for aRow in 0...intermediateExpandedMaze.count - 1 {
            if intermediateExpandedMaze[aRow].rowOfEastWestWall && aRow > 0 && aRow < intermediateExpandedMaze.count - 1 {
                for aCol in 0...intermediateExpandedMaze[aRow].rowOfMaze.count - 1 {
                    // If the wall is just a east-west wall with no connecting north-west wall component, then we can
                    // safely change it to be a fixed level component instead.
                    if intermediateExpandedMaze[aRow].rowOfMaze[aCol].type == .wall && intermediateExpandedMaze[aRow - 1].rowOfMaze[aCol].type == .space && intermediateExpandedMaze[aRow + 1].rowOfMaze[aCol].type == .space {
                        intermediateExpandedMaze[aRow].rowOfMaze[aCol].type = .fixedLevelComponent
                    }
                }
            }
        }
        
        // Now that we've expanded the maze both vertically and horizontally and converted horizontal
        // walls not attached to vertical walls to fixed level components, we can finalize the maze
        // by copying it to its final destination.
        for aRow in 0...intermediateExpandedMaze.count - 1 {
            theMazeExpanded.append(intermediateExpandedMaze[aRow].rowOfMaze)
        }
    }
    
    // After the maze has been expanded the row, column coordinates may not be accurate since
    // the maze elements were just copied.  Here we revise those coordinates to match what they
    // really are after the maze was expanded.  We need this later when we go to populate the
    // maze with robots and parts for prizes and powerups.  Also, save the entrance and exit locations 
    // so that we can later put them in the scene without having to go through the whole maze 
    // looking for where they are.  Also, because we have expanded the maze, the unique number we
    // gave to each element is no longer unique so we create whole new unique numbers starting from
    // zero and going up.
    func adjustCoordinatesAfterMazeExpansionAndRecordEntranceAndExit() {
        var elementIdNumber: Int = 0
        
        for row in 0...theMazeExpanded.count - 1 {
            for col in 0...theMazeExpanded[0].count - 1 {
                theMazeExpanded[row][col].coords.row = row
                theMazeExpanded[row][col].coords.column = col
                theMazeExpanded[row][col].number = elementIdNumber
                elementIdNumber += 1
                if theMazeExpanded[row][col].type == .mazeEntrance {
                    expandedMazeEntrance.append(theMazeExpanded[row][col])
                }
                if theMazeExpanded[row][col].type == .mazeExit {
                    expandedMazeExit.append(theMazeExpanded[row][col])
                }

            }
        }
    }
}
