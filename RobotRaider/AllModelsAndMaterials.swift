//
//  AllModelsAndMaterials.swift
//  RobotRaider
//
//  Created by Nathanael Bills on 2/20/18.
//  Copyright © 2018 invasivemachines. All rights reserved.
//

import Foundation
import SceneKit
import SpriteKit

// This class is for loading all the models and materials
// in the game to try to improve performance.  The idea is to
// load all the models and textures at the beginning of the
// game and then just copy them as needed.
class AllModelsAndMaterials {
    // Wall materials - at this point don't distinguish between
    // inner and outer wall materials.  This way we can randomly
    // chose any texture to be an inner or outer wall materials.
    // We use materials rather than textures to be more general.
    
    var wallMaterials: [SCNMaterial] = []
    
    // inner wall models - su - storage units, bc - big conveyors
    // 16-meter, 24-meter, and 40-meter storage units
    var storageunit16Model: SCNNode!
    var storageunit24Model: SCNNode!
    var storageunit40Model: SCNNode!
    
    // 20-meter, 36-meter and 44-meter big conveyors
    var bigconveyor20Model: SCNNode!
    var bigconveyor36Model: SCNNode!
    var bigconveyor44Model: SCNNode!
    
    // fixed level component models
    var tableModel: SCNNode!
    var refrigeratorModel: SCNNode!
    var rackModel: SCNNode!
    var conveyorModel: SCNNode!
    var mixerModel: SCNNode!
    var ovenModel: SCNNode!
    var deepfryerModel: SCNNode!
    
    // robot models - mainly the body
    var playerModel: SCNNode!
    var playerZapperModel: SCNNode!
    var workerModel: SCNNode!
    var bakerModel: SCNNode!
    var doublebakerModel: SCNNode!
    var zapperModel: SCNNode!
    var superworkerModel: SCNNode!
    var superbakerModel: SCNNode!
    var homingModel: SCNNode!
    var ghostModel: SCNNode!
    var pastrychefModel: SCNNode!
    var ammoPartModel: SCNNode!
    var equipmentPartModel: SCNNode!
    var weaponPartModel: SCNNode!
    var keyPartModel: SCNNode!
    var forcePowerUpModel: SCNNode!
    var reloadPowerUpModel: SCNNode!
    var speedPowerUpModel: SCNNode!
    var levelExitModel: SCNNode!
    var vaultModel: SCNNode!
    var duallaunchersModel: SCNNode!
    var launcherModel: SCNNode!
    var ailauncherModel: SCNNode!
    var wheelModel: SCNNode!
    var rightArmModel: SCNNode!
    var leftArmModel: SCNNode!
    var bunsenBurnerModel: SCNNode!
    var bunsenBurnerFlameModel: SCNNode!
    var threeDArrowModel: SCNNode!
    var puffOfSteamModel: SCNNode!
    
    // baked good models
    var custardPieModel: SCNNode!
    var pumpkinPieModel: SCNNode!
    var chocolateCupcakeModel: SCNNode!
    var raspberryPieModel: SCNNode!
    var keylimePieModel: SCNNode!
    var lemonJellyDonutModel: SCNNode!
    var residueModel: SCNNode!
    var stickyDoughMaterial: SCNMaterial!
    
    // The different stages of splatter
    var splatterModelLarge: SCNNode!
    
    // SpriteKit images, to be loaded for the icons underneath the status bars
    var launcherIcon: SKTexture!
    var flameIcon: SKTexture!
    var zapIcon: SKTexture!
    var backButtonIcon: SKTexture!          // for spritekit shape that is a button
    
    // textures for spritekit arrows
    var twoDUpArrowIcon: SKTexture!
    var twoDDownArrowIcon: SKTexture!
    var twoDLeftArrowIcon: SKTexture!
    var twoDRightArrowIcon: SKTexture!
    var twoDUpLeftArrowIcon: SKTexture!
    var twoDUpRightArrowIcon: SKTexture!
    
    var backButtonImage: UIImage!          // for UIButton image
    var zapperIconImage: UIImage!
    var bakedGoodIconImage: UIImage!
    
    // Images to be used in the Inventory Select screen
    var ammoTypeImage: UIImage!
    var equipmentTypeImage: UIImage!
    var weaponTypeImage: UIImage!
    
    var inventoryImages: [String:UIImage] = [ : ]
    
    // Images used in the Level Select screen
    var robotImage: UIImage!
    var partImage: UIImage!
    var emptyStarImage: UIImage!
    var filledStarImage: UIImage!
    var genericRobotImage: UIImage!
    
    init () {
        
        // load icons to go underneath status bars to show player which weapon is
        // being reloaded.
        launcherIcon = SKTexture(imageNamed: "components.scnassets/launchericon4.png")
        flameIcon = SKTexture(imageNamed: "components.scnassets/flameicon3.png")
        zapIcon = SKTexture(imageNamed: "components.scnassets/zapimage3.png")
        backButtonIcon = SKTexture(imageNamed: "components.scnassets/backbutton1.jpg")
        twoDUpArrowIcon = SKTexture(imageNamed: "components.scnassets/uparrow1.png")
        twoDDownArrowIcon = SKTexture(imageNamed: "components.scnassets/downarrow1.png")
        twoDLeftArrowIcon = SKTexture(imageNamed: "components.scnassets/leftarrow1.png")
        twoDRightArrowIcon = SKTexture(imageNamed: "components.scnassets/rightarrow1.png")
        twoDUpLeftArrowIcon = SKTexture(imageNamed: "components.scnassets/upleftarrow1.png")
        twoDUpRightArrowIcon = SKTexture(imageNamed: "components.scnassets/uprightarrow1.png")
        
        backButtonImage = UIImage(named: "components.scnassets/backbutton1.jpg")
        zapperIconImage = UIImage(named: "components.scnassets/zapimage3.png")
        bakedGoodIconImage = UIImage(named: "components.scnassets/secondlauncher1.png")
        
        robotImage = UIImage(named: "components.scnassets/robotimage1.png")
        partImage = UIImage(named: "components.scnassets/partimage1.png")
        genericRobotImage = UIImage(named: "components.scnassets/genericrobot1.png")
        
        ammoTypeImage = UIImage(named: "components.scnassets/genericammo1.png")
        equipmentTypeImage = UIImage(named: "components.scnassets/equipment1.png")
        weaponTypeImage = UIImage(named: "components.scnassets/zapimage3.png")
        
        // Note: these will be resized later to prevent aliasing as they are reduced in size to
        // much smaller than the original sizes.
        emptyStarImage = UIImage(named: "components.scnassets/emptystar2.png")
        filledStarImage = UIImage(named: "components.scnassets/star2.png")
        
        inventoryImages[custardPieLabel] = UIImage(named: "components.scnassets/custardpie2.png")
        inventoryImages[breadDoughLabel] = UIImage(named: "components.scnassets/breaddough1.png")
        inventoryImages[raspberryPieLabel] = UIImage(named: "components.scnassets/raspberrypie1.png")
        inventoryImages[keyLimePieLabel] = UIImage(named: "components.scnassets/keylimepie1.png")
        inventoryImages[motionDetectorLabel] = UIImage(named: "components.scnassets/motiondetector1.png")
        inventoryImages[pumpkinPieLabel] = UIImage(named: "components.scnassets/pumpkinpie1.png")
        inventoryImages[cookieDoughLabel] = UIImage(named: "components.scnassets/cookiedough1.png")
        inventoryImages[hoverUnitLabel] = UIImage(named: "components.scnassets/hoverunit1.png")
        inventoryImages[zapperWeaponLabel] = UIImage(named: "components.scnassets/zapimage3.png")
        inventoryImages[taffyLabel] = UIImage(named: "components.scnassets/taffy1.png")
        inventoryImages[anotherLauncherLabel] = UIImage(named: "components.scnassets/secondlauncher1.png")
        inventoryImages[lemonJellyDonutLabel] = UIImage(named: "components.scnassets/lemonjellydonut1.png")
        inventoryImages[chocolateCupcakeLabel] = UIImage(named: "components.scnassets/chocolatecupcake1.png")
        inventoryImages[bunsenBurnerLabel] = UIImage(named: "components.scnassets/bunsenburner1.png")
        inventoryImages[empGrenadeLabel] = UIImage(named: "components.scnassets/empgrenade1.png")
        // note: there is no image for the extra slot.
        
        // load all wall materials
        let wallMaterial1 = SCNMaterial()
        wallMaterial1.diffuse.contents = "components.scnassets/gravel.png"
        wallMaterials.append(wallMaterial1)
        let wallMaterial2 = SCNMaterial()
        wallMaterial2.diffuse.contents = "components.scnassets/concrete1.jpg"
        wallMaterials.append(wallMaterial2)
        
        // load all fixed level component models.  These will include their own
        // materials.  For now we assume that each .dae file only has one model in it.
        let tableScene = SCNScene(named: "components.scnassets/table2.dae")
        tableModel = tableScene?.rootNode.childNodes[0]
        let refrigeratorScene = SCNScene(named: "components.scnassets/refrigerator2.dae")
        refrigeratorModel = refrigeratorScene?.rootNode.childNodes[0]
        let rackScene = SCNScene(named: "components.scnassets/rack2.dae")
        rackModel = rackScene?.rootNode.childNodes[0]
        let conveyorScene = SCNScene(named: "components.scnassets/conveyor2.dae")
        conveyorModel = conveyorScene?.rootNode.childNodes[0]
        let mixerScene = SCNScene(named: "components.scnassets/mixer5.dae")
        mixerModel = mixerScene?.rootNode.childNodes[0]
        let ovenScene = SCNScene(named: "components.scnassets/oven6.dae")
        ovenModel = ovenScene?.rootNode.childNodes[0]
        let deepfryerScene = SCNScene(named: "components.scnassets/deepfryer2.dae")
        deepfryerModel = deepfryerScene?.rootNode.childNodes[0]
        
        // load all robot models.  These will also include their own materials.
        let playerScene = SCNScene(named: "components.scnassets/player9.dae")
        playerModel = playerScene?.rootNode.childNodes[0]
        let playerZapperScene = SCNScene(named: "components.scnassets/playerzapper4.dae")
        playerZapperModel = playerZapperScene?.rootNode.childNodes[0]

        // load launchers.
        let duallaunchersScene = SCNScene(named: "components.scnassets/duallaunchers7.dae")
        duallaunchersModel = duallaunchersScene?.rootNode.childNodes[0]
        let launcherScene = SCNScene(named: "components.scnassets/launcher2.dae")
        launcherModel = launcherScene?.rootNode.childNodes[0]
        let ailauncherScene = SCNScene(named: "components.scnassets/ailauncher2.dae")
        ailauncherModel = ailauncherScene?.rootNode.childNodes[0]

        // load wheel
        let wheelScene = SCNScene(named: "components.scnassets/wheel8.dae")
        wheelModel = wheelScene?.rootNode.childNodes[0]
        
        // load arm
        let leftArmScene = SCNScene(named: "components.scnassets/robotarmleft4.dae")
        leftArmModel = leftArmScene?.rootNode.childNodes[0]
        let rightArmScene = SCNScene(named: "components.scnassets/robotarmright4.dae")
        rightArmModel = rightArmScene?.rootNode.childNodes[0]
        
        // bunsen burner - for player only
        let bunsenBurnerScene = SCNScene(named: "components.scnassets/bunsenburner4.dae")
        bunsenBurnerModel = bunsenBurnerScene?.rootNode.childNodes[0]
        // bunsen burner flame
        let bunsenBurnerFlameScene = SCNScene(named: "components.scnassets/bunsenburnerflame2.dae")
        bunsenBurnerFlameModel = bunsenBurnerFlameScene?.rootNode.childNodes[0]
        // three dimensional arrow for the tutorial
        let threeDArrowScene = SCNScene(named: "components.scnassets/threedarrow2.dae")
        threeDArrowModel = threeDArrowScene?.rootNode.childNodes[0]
        
        let workerScene = SCNScene(named: "components.scnassets/worker7.dae")
        workerModel = workerScene?.rootNode.childNodes[0]
        let bakerScene = SCNScene(named: "components.scnassets/baker7.dae")
        bakerModel = bakerScene?.rootNode.childNodes[0]
        let doublebakerScene = SCNScene(named: "components.scnassets/doublebaker4.dae")
        doublebakerModel = doublebakerScene?.rootNode.childNodes[0]
        let zapperScene = SCNScene(named: "components.scnassets/zapper5.dae")
        zapperModel = zapperScene?.rootNode.childNodes[0]
        let superworkerScene = SCNScene(named: "components.scnassets/superworker7.dae")
        superworkerModel = superworkerScene?.rootNode.childNodes[0]
        let superbakerScene = SCNScene(named: "components.scnassets/superdoublebaker5.dae")
        superbakerModel = superbakerScene?.rootNode.childNodes[0]
        let homingScene = SCNScene(named: "components.scnassets/homing5.dae")
        homingModel = homingScene?.rootNode.childNodes[0]
        let ghostScene = SCNScene(named: "components.scnassets/homing5.dae")
        ghostModel = ghostScene?.rootNode.childNodes[0]
        let pastrychefScene = SCNScene(named: "components.scnassets/pastrychef5.dae")
        pastrychefModel = pastrychefScene?.rootNode.childNodes[0]
        let ammoPartScene = SCNScene(named: "components.scnassets/ammopart2.dae")
        ammoPartModel = ammoPartScene?.rootNode.childNodes[0]
        let equipmentPartScene = SCNScene(named: "components.scnassets/equipmentpart2.dae")
        equipmentPartModel = equipmentPartScene?.rootNode.childNodes[0]
        let weaponPartScene = SCNScene(named: "components.scnassets/weaponpart2.dae")
        weaponPartModel = weaponPartScene?.rootNode.childNodes[0]
        let keyPartScene = SCNScene(named: "components.scnassets/keypart2.dae")
        keyPartModel = keyPartScene?.rootNode.childNodes[0]
        let forcePowerUpScene = SCNScene(named: "components.scnassets/forcepowerup3.dae")
        forcePowerUpModel = forcePowerUpScene?.rootNode.childNodes[0]
        let reloadPowerUpScene = SCNScene(named: "components.scnassets/reloadpowerup3.dae")
        reloadPowerUpModel = reloadPowerUpScene?.rootNode.childNodes[0]
        let speedPowerUpScene = SCNScene(named: "components.scnassets/speedpowerup3.dae")
        speedPowerUpModel = speedPowerUpScene?.rootNode.childNodes[0]
        
        let custardPieScene = SCNScene(named: "components.scnassets/custardpie2.dae")
        custardPieModel = custardPieScene?.rootNode.childNodes[0]
        let pumpkinPieScene = SCNScene(named: "components.scnassets/pumpkinpie2.dae")
        pumpkinPieModel = pumpkinPieScene?.rootNode.childNodes[0]
        let chocolateCupcakeScene = SCNScene(named: "components.scnassets/chocolatecupcake2.dae")
        chocolateCupcakeModel = chocolateCupcakeScene?.rootNode.childNodes[0]
        let raspberryPieScene = SCNScene(named: "components.scnassets/raspberrypie3.dae")
        raspberryPieModel = raspberryPieScene?.rootNode.childNodes[0]
        let keylimePieScene = SCNScene(named: "components.scnassets/keylimepie2.dae")
        keylimePieModel = keylimePieScene?.rootNode.childNodes[0]
        let lemonJellyDonutScene = SCNScene(named: "components.scnassets/lemonjellydonut3.dae")
        lemonJellyDonutModel = lemonJellyDonutScene?.rootNode.childNodes[0]

        let residueScene = SCNScene(named: "components.scnassets/residue2.dae")
        residueModel = residueScene?.rootNode.childNodes[0]
        
        let splatterModelLargeScene = SCNScene(named: "components.scnassets/splattersphere6.dae")
        splatterModelLarge = splatterModelLargeScene?.rootNode.childNodes[0]
        
        // the stucco wall texture seems to make a good one for the sticky dough.
        stickyDoughMaterial = SCNMaterial()
        stickyDoughMaterial.diffuse.contents = "components.scnassets/stucco.jpg"

        let levelExitScene = SCNScene(named: "components.scnassets/levelexit3.dae")
        levelExitModel = levelExitScene?.rootNode.childNodes[0]
        let vaultScene = SCNScene(named: "components.scnassets/vault3.dae")
        vaultModel = vaultScene?.rootNode.childNodes[0]
        
        let storageunit16Scene = SCNScene(named: "components.scnassets/su16.6.dae")
        storageunit16Model = storageunit16Scene?.rootNode.childNodes[0]
        let storageunit24Scene = SCNScene(named: "components.scnassets/su24.6.dae")
        storageunit24Model = storageunit24Scene?.rootNode.childNodes[0]
        let storageunit40Scene = SCNScene(named: "components.scnassets/su40.8.dae")
        storageunit40Model = storageunit40Scene?.rootNode.childNodes[0]

        let bigconveyor20Scene = SCNScene(named: "components.scnassets/bc20.8.dae")
        bigconveyor20Model = bigconveyor20Scene?.rootNode.childNodes[0]
        let bigconveyor36Scene = SCNScene(named: "components.scnassets/bc36.6.dae")
        bigconveyor36Model = bigconveyor36Scene?.rootNode.childNodes[0]
        let bigconveyor44Scene = SCNScene(named: "components.scnassets/bc44.7.dae")
        bigconveyor44Model = bigconveyor44Scene?.rootNode.childNodes[0]
        
        let puffOfSteamScene = SCNScene(named: "components.scnassets/puffofsteam4.dae")
        puffOfSteamModel = puffOfSteamScene?.rootNode.childNodes[0]

    }
    
    func getBakedGoodModel(itemType: SpecificPrizeType, bakedGoodSizeRatio: Double, primaryEffect: PrizePrimaryEffectOnEnemyRobot) -> SCNNode {
        var bakedGoodNode: SCNNode!
        
        switch itemType {
        case .custardpie:
            bakedGoodNode = allModelsAndMaterials.custardPieModel.clone()
            bakedGoodNode.geometry = allModelsAndMaterials.custardPieModel.geometry?.copy() as? SCNGeometry
            bakedGoodNode.geometry?.firstMaterial = allModelsAndMaterials.custardPieModel.geometry?.firstMaterial?.copy() as? SCNMaterial
        case .breaddough:
            let pieGeometry = SCNSphere(radius: CGFloat(bakedGoodSizeRatio) * pieRadius)
            bakedGoodNode = SCNNode(geometry: pieGeometry)
            bakedGoodNode.geometry?.firstMaterial?.diffuse.contents = allModelsAndMaterials.stickyDoughMaterial.diffuse.contents
            bakedGoodNode.geometry?.firstMaterial?.multiply.contents = getColorForBakedGoodAndResidue(itemType: itemType)
        case .raspberrypie:
            bakedGoodNode = allModelsAndMaterials.raspberryPieModel.clone()
            bakedGoodNode.geometry = allModelsAndMaterials.raspberryPieModel.geometry?.copy() as? SCNGeometry
            bakedGoodNode.geometry?.firstMaterial = allModelsAndMaterials.raspberryPieModel.geometry?.firstMaterial?.copy() as? SCNMaterial
        case .keylimepie:
            bakedGoodNode = allModelsAndMaterials.keylimePieModel.clone()
            bakedGoodNode.geometry = allModelsAndMaterials.keylimePieModel.geometry?.copy() as? SCNGeometry
            bakedGoodNode.geometry?.firstMaterial = allModelsAndMaterials.keylimePieModel.geometry?.firstMaterial?.copy() as? SCNMaterial
        case .pumpkinpie:
            bakedGoodNode = allModelsAndMaterials.pumpkinPieModel.clone()
            bakedGoodNode.geometry = allModelsAndMaterials.pumpkinPieModel.geometry?.copy() as? SCNGeometry
            bakedGoodNode.geometry?.firstMaterial = allModelsAndMaterials.pumpkinPieModel.geometry?.firstMaterial?.copy() as? SCNMaterial
        case .taffy:
            let pieGeometry = SCNSphere(radius: CGFloat(bakedGoodSizeRatio) * pieRadius)
            bakedGoodNode = SCNNode(geometry: pieGeometry)
            bakedGoodNode.geometry?.firstMaterial?.diffuse.contents = allModelsAndMaterials.stickyDoughMaterial.diffuse.contents
            bakedGoodNode.geometry?.firstMaterial?.multiply.contents = getColorForBakedGoodAndResidue(itemType: itemType)
        case .cookiedough:
            let pieGeometry = SCNSphere(radius: CGFloat(bakedGoodSizeRatio) * pieRadius)
            bakedGoodNode = SCNNode(geometry: pieGeometry)
            bakedGoodNode.geometry?.firstMaterial?.diffuse.contents = allModelsAndMaterials.stickyDoughMaterial.diffuse.contents
            bakedGoodNode.geometry?.firstMaterial?.multiply.contents = getColorForBakedGoodAndResidue(itemType: itemType)
        case .lemonjellydonut:
            bakedGoodNode = allModelsAndMaterials.lemonJellyDonutModel.clone()
            bakedGoodNode.geometry = allModelsAndMaterials.lemonJellyDonutModel.geometry?.copy() as? SCNGeometry
            bakedGoodNode.geometry?.firstMaterial = allModelsAndMaterials.lemonJellyDonutModel.geometry?.firstMaterial?.copy() as? SCNMaterial
        case .chocolatecupcake:
            bakedGoodNode = allModelsAndMaterials.chocolateCupcakeModel.clone()
            bakedGoodNode.geometry = allModelsAndMaterials.chocolateCupcakeModel.geometry?.copy() as? SCNGeometry
            bakedGoodNode.geometry?.firstMaterial = allModelsAndMaterials.chocolateCupcakeModel.geometry?.firstMaterial?.copy() as? SCNMaterial
        default:
            let pieGeometry = SCNSphere(radius: CGFloat(bakedGoodSizeRatio) * pieRadius)
            bakedGoodNode = SCNNode(geometry: pieGeometry)
            bakedGoodNode.geometry?.firstMaterial?.diffuse.contents = allModelsAndMaterials.stickyDoughMaterial.diffuse.contents
        }
        return bakedGoodNode
    }    
}
