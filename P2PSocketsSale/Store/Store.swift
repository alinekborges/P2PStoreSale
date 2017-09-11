//
//  Store.swift
//  P2PSocketsSale
//
//  Created by Aline Borges on 08/09/17.
//  Copyright © 2017 Aline Borges. All rights reserved.
//

import Foundation
import Dispatch

protocol StoreDelegate {
    
    func isSelectedAsBoss()
    
}

class Store: NSObject {
    
    var manager: StoreMultipeerManager
    var bossManager: StoreBossManager?
    
    var delegate: StoreDelegate?
    
    var name: String
    
    var products: [Product]
    
    var isBoss:Bool {
        return bossManager != nil
    }
    
    init(name: String, products: [Product]) {
        self.name = name
        self.products = products
        self.manager = StoreMultipeerManager(peerID: name)
        
        super.init()
        manager.delegate = self
    }
   
}

extension Store: StoreMultipeerDelegate {
    func isSelectedAsBoss() {
        self.delegate?.isSelectedAsBoss()
        self.bossManager = StoreBossManager(manager: self.manager)
    }
}
    

