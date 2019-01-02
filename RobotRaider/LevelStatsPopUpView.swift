//
//  LevelStatsPopUpView.swift
//  RobotRaider
//
//  Created by Nathanael Bills on 10/6/17.
//  Copyright © 2017 invasivemachines. All rights reserved.
//

import Foundation
import UIKit

class LevelStatsPopUpView: UIView, PopUp {
    var backgroundView = UIView()
    var popupView = UIView()
    var okButton = UIButton()
    
    let congratsMessages = [ "Good Work!", "Excellent!", "Awesome!", "Nicely Done!", "Congratulations!", "Way To Go!" ]
    let snideMessages = [ "Now You're Slackin'", "No Guts, No Glory", "What?  Taking a Break?", "Go Back and Face the Peril" ]
    
    func makeButton(text: String, buttonFrame: CGRect) -> UIButton {
        let myButton = UIButton(type: UIButtonType.system)
        // set position and size of button
        myButton.frame = buttonFrame
        myButton.layer.cornerRadius = 8                 // round the corners of the button
        myButton.layer.masksToBounds = true             // apply the rounding to the image on the button as well, if we ever use one.
        myButton.backgroundColor = UIColor.blue
        myButton.setTitle(text, for: .normal)
        myButton.setTitleColor(UIColor.white, for: .normal)
        return myButton
    }
    
    func makeLabel(text: String, textSize: CGFloat, labelFrame: CGRect, alignment: NSTextAlignment) -> UILabel {
        let aLabel = UILabel(frame: labelFrame)
        // set position and size of label
        aLabel.frame = labelFrame
        aLabel.backgroundColor = UIColor.clear
        aLabel.textAlignment = alignment
        aLabel.font = UIFont(name: aLabel.font.fontName, size: textSize)
        aLabel.text = text
        aLabel.textColor = UIColor.yellow
        aLabel.adjustsFontSizeToFitWidth = true
        return aLabel
    }

    convenience init(title: String, parentViewSize: CGSize, levelStats: inout LevelStats, levelNum: Int) {
        self.init(frame: UIScreen.main.bounds)
        
        backgroundView.frame = frame
        backgroundView.backgroundColor = UIColor.black
        backgroundView.alpha = 0.6
        addSubview(backgroundView)
        
        let popupViewWidth = parentViewSize.width - 0.40 * parentViewSize.width
        let popupViewHeight = parentViewSize.height - 0.40 * parentViewSize.height
        let okButtonWidth = 0.20 * popupViewWidth
        let okButtonHeight = 0.15 * popupViewHeight
        let okButtonXorigin = popupViewWidth / 2.0 - okButtonWidth / 2.0
        let okButtonYorigin = popupViewHeight - 0.10 * popupViewHeight - okButtonHeight / 2.0
        
        let fromHQLabelWidth = 0.50 * popupViewWidth
        let fromHQLabelHeight = 0.15 * popupViewHeight
        let messageLabelWidth = 0.80 * popupViewWidth
        let descriptionLabelWidth = 0.35 * popupViewWidth
        let descriptionLabelHeight = 0.15 * popupViewHeight
        let numberLabelWidth = 0.15 * popupViewWidth
        let numberLabelHeight = 0.15 * popupViewHeight
        let totalsLabelWidth = 0.25 * popupViewWidth
        let totalsLabelHeight = 0.15 * popupViewHeight
        let prizeLabelWidth = 0.70 * popupViewWidth
        let prizeLabelHeight = 0.15 * popupViewHeight
        
        let heightSeparation = 0.12 * popupViewHeight
        let widthSeparation = 0.07 * popupViewWidth
        
        let topLabelXorigin = 0.10 * popupViewWidth
        let topLabelYorigin = 0.07 * popupViewHeight
        
        let messageLabelXorigin = topLabelXorigin
        let messageLabelYorigin = topLabelYorigin + heightSeparation + 0.05 * popupViewHeight
        
        let partsLabelXorigin = topLabelXorigin
        let partsLabelYorigin = messageLabelYorigin + heightSeparation + 0.05 * popupViewHeight
        
        var messageNumber: Int = 0
        var message: String = ""
        
        // if the player didn't get any new parts or destroy any robots, replay with a snide remark.
        // Otherwise, congratulate the player.
        if levelStats.numNewPartsFound == 0 && levelStats.numRobotsDestroyed == 0 {
            messageNumber = levelNum % snideMessages.count
            message = snideMessages[messageNumber]
        }
        else {
            messageNumber = levelNum % congratsMessages.count
            message = congratsMessages[messageNumber]
        }
        
        let fromHQLabel = makeLabel(text: "Message from HQ:", textSize: 14.0, labelFrame: CGRect(x: topLabelXorigin, y: topLabelYorigin, width: fromHQLabelWidth, height: fromHQLabelHeight), alignment: NSTextAlignment.left)
        let messageLabel = makeLabel(text: message, textSize: 30.0, labelFrame: CGRect(x: messageLabelXorigin, y: messageLabelYorigin, width: messageLabelWidth, height: descriptionLabelHeight), alignment: NSTextAlignment.left)
        let partsLabel = makeLabel(text: "Parts retrieved:", textSize: 20.0, labelFrame: CGRect(x: partsLabelXorigin, y: partsLabelYorigin, width: descriptionLabelWidth, height: descriptionLabelHeight), alignment: NSTextAlignment.left)
        let numPartsLabel = makeLabel(text: String(levelStats.numNewPartsFound), textSize: 20.0, labelFrame: CGRect(x: partsLabelXorigin + descriptionLabelWidth + widthSeparation, y: partsLabelYorigin, width: numberLabelWidth, height: numberLabelHeight), alignment: NSTextAlignment.center)
        let totalPartsLabel = makeLabel(text: String(levelStats.numPartsFoundSoFar) + "/" + String(levelStats.maxPartsToFind), textSize: 20.0, labelFrame: CGRect(x: partsLabelXorigin + descriptionLabelWidth + 2.0 * widthSeparation + numberLabelWidth, y: partsLabelYorigin, width: totalsLabelWidth, height: totalsLabelHeight), alignment: NSTextAlignment.center)
        
        let robotsLabel = makeLabel(text: "Bots destroyed:", textSize: 20.0, labelFrame: CGRect(x: topLabelXorigin, y: partsLabelYorigin + heightSeparation, width: descriptionLabelWidth, height: descriptionLabelHeight), alignment: NSTextAlignment.left)
        let numRobotsLabel = makeLabel(text: String(levelStats.numRobotsDestroyed), textSize: 20.0, labelFrame: CGRect(x: topLabelXorigin + descriptionLabelWidth + widthSeparation, y: partsLabelYorigin + heightSeparation, width: numberLabelWidth, height: numberLabelHeight), alignment: NSTextAlignment.center)
        let totalRobotsLabel = makeLabel(text: String(levelStats.highestNumRobotsDestroyedSoFar) + "/" + String(levelStats.highestNumRobotsToDestroy), textSize: 20.0, labelFrame: CGRect(x: topLabelXorigin + descriptionLabelWidth + 2.0 * widthSeparation + numberLabelWidth, y: partsLabelYorigin + heightSeparation, width: totalsLabelWidth, height: totalsLabelHeight), alignment: NSTextAlignment.center)

        var prize1String: String = ""
        
        if levelStats.prizesJustUnlocked.count >= 1 {
            prize1String = levelStats.prizesJustUnlocked[0] + " complete!"
        }
        
        levelStats.prizesJustUnlocked = []   // clear out the just unlocked list -- we just show what has just been unlocked at the point
                                            // where it is unlocked.  We don't need to show it again later.

        let prize1Label = makeLabel(text: prize1String, textSize: 14.0, labelFrame: CGRect(x: topLabelXorigin, y: topLabelYorigin + 2.0 * (descriptionLabelHeight + heightSeparation), width: prizeLabelWidth, height: prizeLabelHeight), alignment: NSTextAlignment.left)

        popupView.frame.size = CGSize(width: popupViewWidth, height: popupViewHeight)
        popupView.backgroundColor = UIColor(red: 0.0, green: 0.3, blue: 0.3, alpha: 1.0)
        popupView.layer.cornerRadius = 8
        popupView.clipsToBounds = true
        okButton = makeButton(text: "Ok", buttonFrame: CGRect(x: okButtonXorigin, y: okButtonYorigin, width: okButtonWidth, height: okButtonHeight))
        okButton.addTarget(self, action: #selector(tappedOkButton), for: .touchDown)
        popupView.addSubview(fromHQLabel)
        popupView.addSubview(messageLabel)
        popupView.addSubview(partsLabel)
        popupView.addSubview(numPartsLabel)
        popupView.addSubview(totalPartsLabel)
        popupView.addSubview(robotsLabel)
        popupView.addSubview(numRobotsLabel)
        popupView.addSubview(totalRobotsLabel)
        popupView.addSubview(prize1Label)
        popupView.addSubview(okButton)
        
        addSubview(popupView)
    }
    
    override init(frame: CGRect) {
        super.init (frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func tappedOkButton() {
        gameSounds.playSound(soundToPlay: .buttontap)
        let levelSelectViewController = self.findParentViewController() as? LevelSelectViewController
        levelSelectViewController?.popUpActive = false      // reset popup flag before dismissal to enable interaction in the view controller again.
        
        dismiss(animated: true)
    }
    
}
