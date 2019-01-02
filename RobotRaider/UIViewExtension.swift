//
//  UIViewExtension.swift
//  RobotRaider
//
//  Created by Nathanael Bills on 9/11/18.
//  Copyright © 2018 invasivemachines. All rights reserved.
//

import Foundation
import UIKit

// We modeled this extension after that found at
// url https://www.hackingwithswift.com/example-code/uikit/how-to-find-the-view-controller-responsible-for-a-view
extension UIView {
    func findParentViewController() -> UIViewController? {
        if let nextResponder = self.next as? UIViewController {
            return nextResponder
        }
        else if let nextResponder = self.next as? UIView {
            return nextResponder.findParentViewController()
        }
        else {
            return nil
        }
    }
}

