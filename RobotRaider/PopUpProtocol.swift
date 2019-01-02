//
//  PopUpProtocol.swift
//  RobotRaider
//
//  Created by Nathanael Bills on 10/6/17.
//  Copyright © 2017 invasivemachines. All rights reserved.
//

import Foundation
import UIKit

protocol PopUp {
    func show(animated: Bool)
    func dismiss(animated: Bool)
    var backgroundView: UIView { get }
    var popupView: UIView { get set }
}

extension PopUp where Self: UIView {
    func show(animated:Bool) {
        self.backgroundView.alpha = 0
        self.popupView.center = CGPoint(x: self.center.x, y: self.frame.height + self.popupView.frame.height/2)
        UIApplication.shared.delegate?.window??.rootViewController?.view.addSubview(self)
        if animated {
            UIView.animate(withDuration: 1.0, animations: {
                self.backgroundView.alpha = 0.66
            })
            UIView.animate(withDuration: 1.0, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 10, options: UIViewAnimationOptions(rawValue: 0), animations: {
                self.popupView.center = self.center
            }, completion: { (completed) in
            })
        }
        else {
            self.backgroundView.alpha = 0.66
            self.popupView.center = self.center
        }
    }
    
    func dismiss(animated: Bool) {
        if animated {
            UIView.animate(withDuration: 0.33, animations: {
                self.backgroundView.alpha = 0
            }, completion: { (completed) in
            })
            UIView.animate(withDuration: 0.33, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 10, options: UIViewAnimationOptions(rawValue: 0), animations: {
                self.popupView.center = CGPoint(x: self.center.x, y: self.frame.height + self.popupView.frame.height/2)
            }, completion: { (completed) in
                self.removeFromSuperview()
            })
        }
        else {
            self.removeFromSuperview()
        }
    }

}
