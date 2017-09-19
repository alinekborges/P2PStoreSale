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
    
    var manager: StoreMultipeerManager!
    var bossManager: StoreBossManager?
    
    var delegate: StoreDelegate?
    
    var name: String
    var ip: String?
    var port: Int?
    
    var peerInfo: PeerInfo!
    
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
        
        self.peerInfo = PeerInfo(name: name)
        
        
        self.products = products
        
        self.score = 0
        
        let key = Keys.allkeys.random()!
        
        publicKey = key.0
        privateKey = key.1
        
        super.init()
        self.manager = StoreMultipeerManager(peerID: name, didSetupListenSocket: { (ip, port) in
            self.peerInfo.ip = ip
            self.peerInfo.port = port
        })
        
        self.peerInfo.publicKey = self.publicKey
        self.manager.peerInfo = peerInfo
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
        let base = StoreBase(
             products: self.products,
             peerInfo: self.peerInfo)
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
        message.peerInfo = self.peerInfo
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
        message.peerInfo = self.peerInfo
        message.buyOrder = order
        
        self.manager.sendToBoss(message: message)
        self.buyOrder = order
    }
    
    func completeBuy(_ order: BuyOrder, peer: PeerInfo) {
        let message = Message()
        message.message = "I will buy \(order.emoji!) from \(peer.name!) and I have the key: \(peer.publicKey!)"
        message.type = .completeBuy
        message.buyOrder = order
        message.peerID = self.name
        message.peerInfo = self.peerInfo
        
        self.manager.sendEncrypted(message: message, withPublicKey: publicKey, toPeer: peer)
        
    }
    
    
    func announceStore() {
        let message = announceStoreMessage()
        self.manager.sendToBoss(message: message)
    }
    
}

extension Store: StoreMultipeerDelegate {
    func isSelectedAsBoss() {
        self.delegate?.isSelectedAsBoss()
        if self.bossManager == nil {
            self.bossManager = StoreBossManager(manager: self.manager)
        }
    }
    
    func selectedNewBoss(_ peer: PeerInfo) {
        //when new boss is selected, I send to him my products,
        announceStore()
    }
    
    func selectedPeerForBuy(_ peers: [PeerInfo], buyOrder: BuyOrder) {
        if (peers.isEmpty) { return }
        //TODO: Find correct peer to buy
        
        let peer = peers.first!
        
        
        self.completeBuy(buyOrder, peer: peer)
        

    }

    func decrypt(data: Data) -> String {
        let decrypted = try! RSAUtils.decryptWithRSAPrivateKey(encryptedData: data, privkeyBase64: self.privateKey)
        return String(data: decrypted!, encoding: .utf8)!
    }
    
    func sell(_ buyOrder: BuyOrder, toPeer peer: PeerInfo) {
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
        message.peerInfo = self.peerInfo
        
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
    
    
    func sendDiscovery() {
        let message = Message()
        message.type = .discovery
        message.message = "Hey guys! I'm \(self.name) and I'm new around here! Do you guys have a boss yet?"
        message.peerID = self.name
        message.peerInfo = self.peerInfo
        self.manager.sendBroadcast(message: message)
        
    }
}


