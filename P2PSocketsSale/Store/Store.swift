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
    
    var peerInfo: PeerInfo!
    
    var products: [Product]
    var score: Int
    
    fileprivate var privateKey: String
    fileprivate var publicKey: String
    
    fileprivate var peerReputations: [PeerReputation] = []
    
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
    
    /**
     * After boss answered from which peer we should buy and we pick the right one, it will encrypt the message with the seller public key and send as unicast to this specific seller
     *
     * - Parameter order: Buy Order, peer: Seller peer
     */
    func completeBuy(_ order: BuyOrder, peer: PeerInfo) {
        let message = Message()
        message.message = "I will buy \(order.emoji!) from \(peer.name!) and I have the key: \(peer.publicKey!)"
        message.type = .completeBuy
        message.buyOrder = order
        message.peerID = self.name
        message.peerInfo = self.peerInfo
        
        self.manager.sendEncrypted(message: message, withPublicKey: publicKey, toPeer: peer)
        
    }
    
    /**
     * Sends to boss all the info of this store products and public key for it to store at the index
     *
     */
    func announceStore() {
        let message = announceStoreMessage()
        self.manager.sendToBoss(message: message)
    }
    
    /**
     * Selects which peer I should buy from based on its reputation. Peer with most reputation (a.k.a I have already dealed with him) is preferred. If no peers have yet any reputation, just return any of them (random)
     *
     * - Parameter order: Buy Order, peer: Seller peer
     */
    func selectPeerFromReputation(peers: [PeerInfo]) -> PeerInfo {
        
        print("All of my peer reputations: \(self.peerReputations.map({$0.peerInfo.name! + ":" + "\($0.reputation)"}).description)")
        
        //filter all peer reputations with peers I might buy from
        let reputations = self.peerReputations.filter( {peers.contains($0.peerInfo)} )
        
        //if there is no reputation yet computed, just use a random peer for buying
        if reputations.isEmpty { return peers.random()! }
        
        //order list by higher reputation and return first peer
        return reputations.sorted(by: {$0.reputation > $1.reputation}).first!.peerInfo
        
    }
    
}

//MARK: Delegate implementation
extension Store: StoreMultipeerDelegate {
    
    /**
     * Selects which peer I should buy from based on its reputation. Peer with most reputation (a.k.a I have already dealed with him) is preferred. If no peers have yet any reputation, just return any of them (random)
     *
     */
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
        
        let peer = selectPeerFromReputation(peers: peers)
        
        
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
    
    func receivedProduct(_ buyOrder: BuyOrder, fromPeer peer: PeerInfo) {
        for product in self.products {
            if product.emoji == buyOrder.emoji {
                product.quantity! += buyOrder.quantity!
                return
            }
        }
        
        self.products.append(Product(emoji: buyOrder.emoji!, quantity: buyOrder.quantity!, price: 9.random()))
        
        //so I have some new products in store, let's announce it again to boss
        self.announceStore()
        
        //after receiving product, peer reputation will increse by one
        if let reputation = self.peerReputations.filter({$0.peerInfo == peer}).first {
            reputation.increaseReputation()
        } else {
            self.peerReputations.append(PeerReputation(peerInfo: peer))
        }
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


