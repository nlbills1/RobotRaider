//
//  VaultLevelCompletionPopUpView.swift
//  RobotRaider
//
//  Created by Nathanael Bills on 5/22/18.
//  Copyright © 2018 invasivemachines. All rights reserved.
//

import Foundation

import UIKit

class VaultLevelCompletionPopUpView: UIView, PopUp {
    var backgroundView = UIView()
    var popupView = UIView()
    var okButton = UIButton()
    
    func makeButton(text: String, buttonFrame: CGRect) -> UIButton {
        let myButton = UIButton(type: UIButtonType.system)
        // set position and size of button
        myButton.frame = buttonFrame
        myButton.layer.cornerRadius = 8                 // round the corners of the button
        myButton.layer.masksToBounds = true             // apply the rounding to the image on the button as well, if we ever use one.
        // set background color for button
        myButton.backgroundColor = UIColor.blue
        // text on the button in its normal state
        myButton.setTitle(text, for: .normal)
        myButton.setTitleColor(UIColor.white, for: .normal)
        return myButton
    }
    
    func makeLabel(text: String, labelFrame: CGRect, alignment: NSTextAlignment, fontSize: CGFloat) -> UILabel {
        let aLabel = UILabel(frame: labelFrame)
        // set position and size of label
        aLabel.frame = labelFrame
        // set no background color for label
        aLabel.backgroundColor = UIColor.clear
        // set text in label
        aLabel.textAlignment = alignment
        aLabel.font = UIFont(name: aLabel.font.fontName, size: fontSize)
        aLabel.text = text
        aLabel.textColor = UIColor.yellow
        aLabel.adjustsFontSizeToFitWidth = true
        return aLabel
    }
    
    convenience init(title: String, parentViewSize: CGSize, levelStats: inout LevelStats) {
        self.init(frame: UIScreen.main.bounds)
        
        backgroundView.frame = frame
        backgroundView.backgroundColor = UIColor.black
        backgroundView.alpha = 0.6
        addSubview(backgroundView)
        
        let popupViewWidth = parentViewSize.width - 0.40 * parentViewSize.width
        let popupViewHeight = parentViewSize.height - 0.20 * parentViewSize.height
        let okButtonWidth = 0.20 * popupViewWidth
        let okButtonHeight = 0.10 * popupViewHeight
        let okButtonXorigin = popupViewWidth / 2.0 - okButtonWidth / 2.0
        let okButtonYorigin = popupViewHeight - 0.10 * popupViewHeight - okButtonHeight / 2.0
        
        let descriptionLabelWidth = 0.40 * popupViewWidth
        let descriptionLabelHeight = 0.10 * popupViewHeight
        let numberLabelWidth = 0.10 * popupViewWidth
        let numberLabelHeight = 0.10 * popupViewHeight
        let totalsLabelWidth = 0.20 * popupViewWidth
        let totalsLabelHeight = 0.10 * popupViewHeight
        let prizeLabelWidth = 0.85 * popupViewWidth
        let prizeLabelHeight = 0.05 * popupViewHeight
        
        let heightSeparation = 0.05 * popupViewHeight
        let widthSeparation = 0.10 * popupViewWidth
        let topLabelXorigin = 0.10 * popupViewWidth
        let topLabelYorigin = 0.10 * popupViewHeight
        
        let vaultOpenedLabel = makeLabel(text: "Vault Opened!", labelFrame: CGRect(x: topLabelXorigin, y: topLabelYorigin, width: descriptionLabelWidth, height: descriptionLabelHeight), alignment: NSTextAlignment.left, fontSize: 30.0)
        
        let robotsLabel = makeLabel(text: "Bots destroyed:", labelFrame: CGRect(x: topLabelXorigin, y: topLabelYorigin + descriptionLabelHeight + heightSeparation, width: descriptionLabelWidth, height: descriptionLabelHeight), alignment: NSTextAlignment.left, fontSize: 20.0)
        let numRobotsLabel = makeLabel(text: String(levelStats.numRobotsDestroyed), labelFrame: CGRect(x: topLabelXorigin + descriptionLabelWidth + widthSeparation, y: topLabelYorigin + descriptionLabelHeight + heightSeparation, width: numberLabelWidth, height: numberLabelHeight), alignment: NSTextAlignment.center, fontSize: 20.0)
        let totalRobotsLabel = makeLabel(text: String(levelStats.highestNumRobotsDestroyedSoFar) + "/" + String(levelStats.highestNumRobotsToDestroy), labelFrame: CGRect(x: topLabelXorigin + descriptionLabelWidth + 2.0 * widthSeparation + numberLabelWidth, y: topLabelYorigin + descriptionLabelHeight + heightSeparation, width: totalsLabelWidth, height: totalsLabelHeight), alignment: NSTextAlignment.center, fontSize: 20.0)
                
        let prize1String = "1 Ledger: 100,000 cryptocoins"
        let prize2String = "1 Cookbook: 200,000 cryptocoins"
        let prize3String = "1 Map to Secret Facility"
        
        let insideVaultLabel = makeLabel(text: "Items retrieved:", labelFrame: CGRect(x: topLabelXorigin, y: topLabelYorigin + descriptionLabelHeight + 0.5 * heightSeparation + numberLabelHeight + totalsLabelHeight, width: prizeLabelWidth, height: prizeLabelHeight), alignment: NSTextAlignment.left, fontSize: 12.0)

        let prize1Label = makeLabel(text: prize1String, labelFrame: CGRect(x: topLabelXorigin, y: topLabelYorigin + descriptionLabelHeight + 2.5 * heightSeparation + numberLabelHeight + totalsLabelHeight, width: prizeLabelWidth, height: prizeLabelHeight), alignment: NSTextAlignment.left, fontSize: 15.0)
        let prize2Label = makeLabel(text: prize2String, labelFrame: CGRect(x: topLabelXorigin, y: topLabelYorigin + descriptionLabelHeight + 3.5 * heightSeparation + numberLabelHeight + totalsLabelHeight + prizeLabelHeight, width: prizeLabelWidth, height: prizeLabelHeight), alignment: NSTextAlignment.left, fontSize: 15.0)
        let prize3Label = makeLabel(text: prize3String, labelFrame: CGRect(x: topLabelXorigin, y: topLabelYorigin + descriptionLabelHeight + 4.5 * heightSeparation + numberLabelHeight + totalsLabelHeight + 2.0 * prizeLabelHeight, width: prizeLabelWidth, height: prizeLabelHeight), alignment: NSTextAlignment.left, fontSize: 15.0)
        
        popupView.frame.size = CGSize(width: popupViewWidth, height: popupViewHeight)
        popupView.backgroundColor = UIColor.purple
        popupView.layer.cornerRadius = 8
        popupView.clipsToBounds = true
        okButton = makeButton(text: "Ok", buttonFrame: CGRect(x: okButtonXorigin, y: okButtonYorigin, width: okButtonWidth, height: okButtonHeight))
        okButton.addTarget(self, action: #selector(tappedOkButton), for: .touchDown)
        popupView.addSubview(vaultOpenedLabel)
        popupView.addSubview(robotsLabel)
        popupView.addSubview(numRobotsLabel)
        popupView.addSubview(totalRobotsLabel)
        popupView.addSubview(prize1Label)
        popupView.addSubview(prize2Label)
        popupView.addSubview(prize3Label)
        popupView.addSubview(insideVaultLabel)
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
