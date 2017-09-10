//
//  UIView+Utils.swift
//  P2PSocketsSale
//
//  Created by Aline Borges on 10/09/17.
//  Copyright © 2017 Aline Borges. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    
    func pinEdgesToSuperview() {
        guard let superview = self.superview else {
            return
        }
        self.leftAnchor.constraint(equalTo: superview.leftAnchor).isActive = true
        self.rightAnchor.constraint(equalTo: superview.rightAnchor).isActive = true
        self.bottomAnchor.constraint(equalTo: superview.bottomAnchor).isActive = true
        self.topAnchor.constraint(equalTo: superview.topAnchor).isActive = true
    }
    
    func centerVerticallyInSuperview() {
        guard let superview = self.superview else {
            return
        }
        self.centerYAnchor.constraint(equalTo: superview.centerYAnchor).isActive = true
    }
    
    func centerHorizontallyInSuperview() {
        guard let superview = self.superview else {
            return
        }
        self.centerXAnchor.constraint(equalTo: superview.centerXAnchor).isActive = true
    }
    
    func pinLeftEdgeToSuperview(withOffset offset: CGFloat = 0.0) {
        guard let superview = self.superview else {
            return
        }
        self.leftAnchor.constraint(equalTo: superview.leftAnchor, constant: offset).isActive = true
    }
    
    func pinRightEdgeToSuperview(withOffset offset: CGFloat = 0.0) {
        guard let superview = self.superview else {
            return
        }
        self.rightAnchor.constraint(equalTo: superview.rightAnchor, constant: -offset).isActive = true
    }
    
    func pinTopEdgeToSuperview(withOffset offset: CGFloat = 0.0) {
        guard let superview = self.superview else {
            return
        }
        self.topAnchor.constraint(equalTo: superview.topAnchor, constant: offset).isActive = true
    }
    
    func pinBottomEdgeToSuperview(withOffset offset: CGFloat = 0.0) {
        guard let superview = self.superview else {
            return
        }
        self.bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: offset).isActive = true
    }
    
    func constraintHeight(toConstant: CGFloat) {
        self.heightAnchor.constraint(equalToConstant: toConstant).isActive = true
    }
    
    func constraintWidth(toConstant: CGFloat) {
        self.widthAnchor.constraint(equalToConstant: toConstant).isActive = true
    }
    
    func roundView() {
        self.layer.cornerRadius = self.frame.height / 2
        self.clipsToBounds = true
    }
    
}
