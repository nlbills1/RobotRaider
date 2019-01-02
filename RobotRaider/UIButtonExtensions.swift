//
//  UIButtonExtensions.swift
//  RobotRaider
//
//  Created by Nathanael Bills on 9/1/18.
//  Copyright © 2018 invasivemachines. All rights reserved.
//

import Foundation
import UIKit

// Adopted from https://stackoverflow.com/questions/34666136/how-to-make-a-button-flash-or-blink
// to show a blinking button.
extension UIButton {
    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        return self.bounds.contains(point) ? self : nil
    }
    // Note: this is specific to showing the equipment/inventory blinking in the level select
    // Right now that's the only place where we use a blinking button.  If we need to do so again
    // later we'll make this more general.
    func blink() {
        UIView.animate(withDuration: 0.5, delay: 0.0, options: [.curveEaseInOut, .autoreverse, .repeat], animations: {
            self.backgroundColor = UIColor.purple
        }, completion: nil)
    }
}
