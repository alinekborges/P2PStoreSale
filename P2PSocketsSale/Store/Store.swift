//
//  Store.swift
//  P2PSocketsSale
//
//  Created by Aline Borges on 08/09/17.
//  Copyright © 2017 Aline Borges. All rights reserved.
//

import Foundation
import Dispatch
import MultipeerConnectivity

protocol StoreDelegate {
    
    func isSelectedAsBoss()
    
}

class Store: NSObject {
    
    var manager: StoreMultipeerManager
    var bossManager: StoreBossManager?
    
    var delegate: StoreDelegate?
    
    var name: String
    
    var products: [Product]
    var score: Int
    
    var privateKey: String
    
    var buyOrder: BuyOrder?
    
    var isBoss:Bool {
        return bossManager != nil
    }
    
    
    
    init(name: String, products: [Product]) {
        self.name = name
        self.products = products
        self.manager = StoreMultipeerManager(peerID: name)
        self.score = 0
        
        privateKey = name + products.first!.emoji! //create random privateKey using name + emoji
        
        super.init()
        manager.delegate = self
    }
    
    func onTick() {
        if self.isBoss {
            self.bossManager?.sendKeepAlive()
        } else {
            self.manager.onTick()
        }
    }
    
    func disconnect() {
        self.manager.disconnect()
    }
   
    func baseStore() -> StoreBase {
        let base = StoreBase(name: self.name,
             products: self.products,
             score: self.score,
             publicKey: self.name) //for now, public key is my name
        return base
    }
    
    func announceStoreMessage() -> Message {
        let base = self.baseStore()
        let message = Message()
        
        message.type = .announcingProducts
        message.message = "Announcing products to boss for store \(self.name): \(self.products.map({$0.emoji!}).joined())"
        message.peerID = self.name
        message.baseStore = base
        return message
    }
    
    func sendBuyOrder(_ order: BuyOrder) {
        let message = Message()
        message.type = .buyOrder
        message.message = "I'm \(self.name) and I want to buy \(order.quantity!) \(order.emoji!)"
        message.peerID = self.name
        message.buyOrder = order
        
        self.manager.sendToBoss(message: message)
        self.buyOrder = order
    }
    
    func completeBuy(_ order: BuyOrder, peerID: MCPeerID, publicKey: String) {
        let message = Message()
        message.message = "I will buy \(order.emoji!) from \(peerID) and I have the key"
        message.type = .completeBuy
        message.buyOrder = order
        
        
        //encrypt message with public key
        let encrypted = message.encrypt(withPublicKey: publicKey)
        
        self.manager.send(message: message, toPeer: peerID)
    }
}

extension Store: StoreMultipeerDelegate {
    func isSelectedAsBoss() {
        self.delegate?.isSelectedAsBoss()
        self.bossManager = StoreBossManager(manager: self.manager)
    }
    
    func selectedNewBoss(_ peerID: MCPeerID) {
        //when new boss is selected, I send to him my products,
        let message = announceStoreMessage()
        self.manager.send(message: message, toPeer: peerID)
    }
    
    func selectedPeerForBuy(_ peerID: MCPeerID?, publicKey: String?) {
        guard let peerID = peerID, let publicKey = publicKey, let buyOrder = self.buyOrder else {
            print("(boss) not enought parameters to complete buy")
            return
        }
        
        self.completeBuy(buyOrder, peerID: peerID, publicKey: publicKey)

    }
}


