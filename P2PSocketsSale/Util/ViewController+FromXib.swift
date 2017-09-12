//
//  ViewController+FromXib.swift
//  P2PSocketsSale
//
//  Created by Aline Borges on 10/09/17.
//  Copyright © 2017 Aline Borges. All rights reserved.
//

import Foundation
import UIKit

class UIViewControllerFromXib: UIViewController {
    
    override func loadView() {
        let string = String(describing: type(of: self).classForCoder())
        
        self.view = Bundle.main.loadNibNamed(string, owner: self, options: nil)?.first! as! UIView
        
        view.bounds = UIScreen.main.bounds
        view.frame = UIScreen.main.bounds
    }
    
}
