# RobotRaider
A simple game where robots throw pies and other baked goods, zap bolts, and EMP grenades at each other

I created a game called RobotRaider, a simple game where robots through pies and other baked goods at each other.  It was created in Swift 4 using SceneKit, a SpriteKit overlay, and Core Data for tracking the player’s progress.  It’s free to for folks to use with a MIT license, although it is missing the sounds created with GarageBand.  To play the game with all of the sounds one would need to download the game from the App Store, where it is free.  Here’s sort of a simple intro for RobotRaider:

Take back control of trade by infiltrating the Bakery, a member of the artificially intelligent Conglomerate, and retrieving two things, the ledger and the Cookbook.

Obtaining the ledger and the Cookbook, the Conglomerate's most precious possessions that enables it to track activity and expand its empire, will not be easy.  The Bakery, one of its weaker members, keeps them in a vault deep within the building.  And the facility's AI has been warned to expect an attempt to steal them.

Only the company's autonomous robots can enter any of its buildings unchallenged.  Defiant humans who call themselves the People for the Eradication of Sinister Technologies (PEST) have created robots to look like company models to infiltrate the corporation and get back stolen trade secrets.  They call these robots Retrievers.

Disguised as an automated baker with credentials obtained from a discarded machine, Robot Retriever #3 is heading for the Bakery to complete its mission...

Guide Retriever #3 through the facility, make it to the vault and get that ledger and Cookbook.  Your robot has been enhanced to make baked goods and shoot them out at high velocity,  a possible defense against other robots if they detect the retriever’s presence and attack.

The retriever, built from junkyard parts, has a leaky nuclear power plant, creating radioactive waste that accelerates corrosion.  Other baked goods come out incredibly dense.  USB flash drives that have been dropped by the Bakery's workers have parts of recipes for other baked goods as well as reconfiguration instructions for creating weapons and equipment.

Some notes on the game:

1) I'm fully aware it is a silly game where robots throw pies at each other, which is the primary action that happens in this game.  This is also my first attempt at a real iOS app in Swift so the code is not as good as it could be.  For instance, the majority of the code is in three main files when the code should be in more, smaller files.  In large part this was a result of my learning the ropes of the model-view-controller model.

2) The levels are all automatically generated using the level number as the seed.  I knew I didn't have the artistic ability to create even one level, let alone sixty-one of them so I went with automatic generation instead.  Using the level number as the seed and using my own internal random number generator guaranteed consistent level generation.  In other words, level ten, while randomly generated, will appear the same every time the player enters that level.  The way the levels are created is shown in Maze.swift.

3) Robots and other items in the level are tracked via an invisible level grid.  The one major oddity is that the coordinates from 1...max level coord but in the -z direction.  In other words, while the level grid coordinates increase in number, the real coordinates get more and more negative, if that makes sense.  The reason for this is that in SceneKit the default orientation for the camera is in the -z direction and I didn't want to change that in case it wound up breaking something else.  There are two functions that deal with this.  One is called calculateLevelRowAndColumn(), which calculates the level grid row and column from the scene’s 3d coordinates and the second function is called calculateSceneCoordinatesFromLevelRowAndColumn(), which takes a level grid row and column and converts to scene 3d coordinates.  Both functions are in GlobalConstants.swift.

4) The enemy robots are referred to as the aiRobots in the code.  Real physics is used by those robots to launch pies at the player.  At first I looked for an exact equation that would do it and when I found it, I didn't follow it--my math skills were just too ancient.  So I went with the next best thing, an iterative method, which got me close to what I wanted.  Once I added a fudge factor, the accuracy was spot on and the aiRobots were accurately targeting the player, so accurately that I had to add code in there to make them 'miss' just to allow me to last more than five seconds in a level.

5) Note that the main ammo of the robots, baked goods, are turned invisible once they hit the robot and collision detection is removed to allow them to fall through the floor.  A residue node is created at the point of impact to show a sort of splattering effect.  Both the baked good and residue nodes are removed from the game once they have fallen a certain distance beneath the floor.  Obviously this isn’t the most efficient way to clean things up but we found that if we removed the baked good nodes upon impact the game would crash as the collision detection code would still be acting on the baked good node while it was being removed because the baked good was still in contact with the robot.  We tried replacing the geometry of the baked good node with a different one to show the residue and splatter but that also didn't seem to work.  Finally, making the baked good invisible and letting it fall through the floor and then letting the residue fall through the floor visibly seem to give the effect we wanted, without any crashes.

6) The game loop is actually performed by the renderer() function.  I'm not sure that that was the intent of that function but that appeared to be the only place where I could have some sort of game loop.  It worked fine, but only because the enemy robots were constantly moving.  A few times during testing I noticed that if no updates needed to be made to the scene the renderer() function would not be called; at least, that’s what it looked like to me.  With RobotRaider this did not seem to be a problem but it could be for some other game/project.

7) One should note that there is very little code in the gesture handler functions.  They primarily just record the action and return.  I'm not certain that it's true but it appeared that we caused race conditions to happen if we tried to do to much inside those gesture handlers.  So we opted to use a Grand Central Dispatch queue to save the action and then later in the renderer() function pull out the saved gesture and act on it.  That seemed to prevent race condition crashes.

8) The models, icon and some sounds are included.  The models I created myself in Blender.  The icon game artwork I made in Krita.  The sounds came from a combination of using GarageBand, Audacity and Bfxr.  I removed the GarageBand sounds because they can't be repackaged and resold.  While I doubt it would ever happen I figured it best to just remove those sounds and not worry about it.  I still left in the sounds I created using Bfxr, Audacity, and sounds I recorded, such as the crashing sound, which was me dropping a box of silverware onto the floor, the frying sound, which was me frying eggs sunny side up, and the launcher turning sound, which was the sound my electric drill made.  I also switched out the targettap and buttontap sounds with new ones made with Bfxr to make the game at least a little more playable without the GarageBand sounds.  You should be able to use any sounds and models I've included.  If you’re curious about using the GarageBand sounds, load up GarageBand in Mac OS X, start a new project, click on the loop browser at the top right of the window (it looks kind of like one of those loops one goes through on a rollercoaster).  Then select Instrument, which shows a list of instruments, one being ‘Sound Effects’.  If you select Sound Effects you’ll see a bunch of different sounds.  Unfortunately, some of those sounds are people counting from one to ten, in a number of different languages.  Aside from that, though, there are a bunch of neat sounds.  With GarageBand or Audacity they can be modified to make even more sounds.  

9) Core Data is used to track the state of the player and of each level in the game.  It may not be the best example but you're welcome to use what you see for your game or app.  Core Data is used heavily in the LevelSelectViewController.swift file.

10) The level selection and item selection are done with the use of a collectionview.  I started with the tableview but that seemed too limiting.  

11) Layout and sizing of the two-dimensional components such as buttons and status bars was done using percentages of the screen size rather than explicit pixel count.  I'm sure there was a better way to do this but this seemed to be the simplest way to go for consistency everywhere.  I tried using doing this in the storyboard but found it easier to do the layout in code, particularly if I wanted to review it weeks later.

12) There's bound to be a little cruft here and there.  I tried to keep it clean but towards the end it was getting tough.  Sorry.

13) swiftlint will show a lot of warnings and errors, particularly with line length.  Sadly, I do have a lot of lines 250 characters or longer.  I probably could have shortened the variable names.  Also, there are a number of 'Forced cast' violations.  Unfortunately, when I used forced cast it was unavoidable--Xcode wouldn't let the app compile without it.  And of course there's a huge number of trailing whitespace violations.  

14) I reference a few web pages in the comments of the code.  Those were mainly for my use in case I needed to go back to those pages again later but those maybe useful for figuring out how to do things, like automatically generating levels for example.

That's it.  These are just quick notes of the internals of the game.  I'm sure there’s a ton of stuff I've forgotten to mention.  A 'wc -l *.swift' of the swift files shows that there are 14,775 lines of code in the project (probably more like thirteen thousand if one excludes comment lines; I wouldn't, though, as some of those comments have saved me hours and hours of head-scratching.  Or cause more head-scratching.  You be the judge).  That's a lot, to be sure.  

In the unlikely event that you modify the game and make a lot of money with it, congratulations!  All I ask is that you mention my game, and maybe me, in the credits somewhere.  You don't have to, of course, but I would appreciate it.

Nathan Bills

bills.nathanael@gmail.com 

