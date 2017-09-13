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
    
    fileprivate var privateKey: String
    fileprivate var publicKey: String
    
    var buyOrder: BuyOrder?
    
    var isBoss:Bool {
        return bossManager != nil
    }
    
    init(name: String, products: [Product]) {
        self.name = name
        self.products = products
        self.manager = StoreMultipeerManager(peerID: name)
        self.score = 0
        
        let key = Keys.allkeys.random()!
        
        publicKey = key.0
        privateKey = key.1
        
        super.init()
        manager.delegate = self
        
    }
    
    /**
     * Sends keep alive (if current store is boss) or check if keep alive is being sent (if it isn't the boss
     */
    func onTick() {
        if self.isBoss {
            self.bossManager?.sendKeepAlive()
        } else {
            self.manager.onTick()
        }
    }
    
    /**
     * Forces disconnection of a store
     */
    func disconnect() {
        self.manager.disconnect()
    }
   
    /**
     * Converts store to a simpler object with all properties
     * 
     * - Returns: Base Store
     */
    func baseStore() -> StoreBase {
        let base = StoreBase(name: self.name,
             products: self.products,
             score: self.score,
             publicKey: self.publicKey)
        return base
    }
    
    /**
     * Creates message that announces all products for this store
     *
     * - Returns: message with store and products information
     */
    func announceStoreMessage() -> Message {
        let base = self.baseStore()
        let message = Message()
        
        message.type = .announcingProducts
        message.message = "Announcing products to boss for store \(self.name): \(self.products.map({$0.emoji!}).joined())"
        message.peerID = self.name
        message.baseStore = base
        return message
    }
    
    /**
     * Sends a buy order to the boss, that should choose from which peer I should buy the product from
     *
     * - Parameter order: Buy Order
     */
    func sendBuyOrder(_ order: BuyOrder) {
        let message = Message()
        message.type = .buyOrder
        message.message = "I'm \(self.name) and I want to buy \(order.quantity!) \(order.emoji!)"
        message.peerID = self.name
        message.buyOrder = order
        
        self.manager.sendToBoss(message: message)
        self.buyOrder = order
    }
    
    func completeBuy(_ order: BuyOrder, peerID: String, publicKey: String) {
        let message = Message()
        message.message = "I will buy \(order.emoji!) from \(peerID) and I have the key"
        message.type = .completeBuy
        message.buyOrder = order
        message.peerID = self.name
        
        self.manager.sendEncrypted(message: message, withPublicKey: publicKey, toPeer: peerID)
        
    }
    
    
    func announceStore() {
        let message = announceStoreMessage()
        self.manager.sendToBoss(message: message)
    }
    
}

extension Store: StoreMultipeerDelegate {
    func isSelectedAsBoss() {
        self.delegate?.isSelectedAsBoss()
        self.bossManager = StoreBossManager(manager: self.manager)
    }
    
    func selectedNewBoss(_ peerID: MCPeerID) {
        //when new boss is selected, I send to him my products,
        announceStore()
    }
    
    func selectedPeerForBuy(_ peerID: String?, publicKey: String?) {
        guard let peerID = peerID, let publicKey = publicKey, let buyOrder = self.buyOrder else {
            print("(boss) not enought parameters to complete buy")
            return
        }
        self.completeBuy(buyOrder, peerID: peerID, publicKey: publicKey)

    }

    func decrypt(data: Data) -> String {
        let decrypted = try! RSAUtils.decryptWithRSAPrivateKey(encryptedData: data, privkeyBase64: self.privateKey)
        return String(data: decrypted!, encoding: .utf8)!
    }
    
    func sell(_ buyOrder: BuyOrder, toPeer peer: String) {
        for (index, product) in self.products.enumerated() {
            if product.emoji == buyOrder.emoji {
                //this is the product, so remove quantity or delete
                if product.quantity! > buyOrder.quantity! {
                    product.quantity! -= buyOrder.quantity!
                } else {
                    self.products.remove(at: index)
                }
                break
            }
        }
        
        let message = Message()
        message.type = .sendingProduct
        message.message = "(boss) sending products to destination peer!"
        message.buyOrder = buyOrder
        message.peerID = self.name
        
        self.manager.send(message: message, toPeer: peer)
        
        announceStore()
        
        DispatchQueue.main.async {
            self.postNotification(notificationName: "update_UI")
        }
    }
    
    func receivedProduct(_ buyOrder: BuyOrder) {
        for product in self.products {
            if product.emoji == buyOrder.emoji {
                product.quantity! += buyOrder.quantity!
                return
            }
        }
        
        self.products.append(Product(emoji: buyOrder.emoji!, quantity: buyOrder.quantity!, price: 9.random()))
    }
    
}


