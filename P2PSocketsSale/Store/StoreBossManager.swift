//
//  StoreBossManager.swift
//  P2PSocketsSale
//
//  Created by Aline Borges on 10/09/17.
//  Copyright © 2017 Aline Borges. All rights reserved.
//

import Foundation

class StoreBossManager: NSObject {
    
    var allStores: [StoreBase] = []
    var manager: StoreMultipeerManager
    
    
    let keepAlive = Message()
    
    init(manager: StoreMultipeerManager) {
        self.manager = manager
        
        keepAlive.type = .bossKeepAlive
        keepAlive.message = "I'm the boss and I'm alive"
        keepAlive.peerID = self.manager.peerID
        
        super.init()

    }
    
    func sendKeepAlive() {
        
        self.manager.send(message: keepAlive)
       
    }

    
    
}
