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
        
        self.manager.messageDelegate = self

    }
    
    func sendKeepAlive() {
        
        self.manager.send(message: keepAlive)
       
    }
    
    func addStore(baseStore: StoreBase?) {
        guard let store = baseStore else { return }
        
        if !self.allStores.contains(store) {
            self.allStores.append(store)
        } else {
            let index = self.allStores.index(of: store)
            let oldStore = self.allStores[index!]
            oldStore.updateValues(store: store)
            
        }
        
        
        print("boss received products from \(baseStore?.description). Current store count: \(self.allStores.count)")
        self.postNotification(notificationName: "update_UI")
    }
    
    func processBuyOrder(order: BuyOrder, fromPeer peer: String) {
        print("boss received buy order from \(peer): \(order.description)")
        if let seller = sellerForOrder(order: order) {
        
            print("boss elected \(seller) to sell \(order.description)")
            let response = BuyOrderResponse(peerID: seller.name!, publicKey: seller.publicKey!)
            
            let message = Message()
            message.type = .buyOrderResponse
            message.message = "boss buy order response: should buy from seller \(seller.name!)"
            message.buyOrderResponse = response
            message.peerID = self.manager.peerID
            
            self.manager.send(message: message, toPeer: peer)
            
        } else {
            //TODO: SHow errror: no stores have this product
        }
    }
    
    func sellerForOrder(order: BuyOrder) -> StoreBase? {
        
        var possibleStores: [StoreBase] = []
        
        //Find all stores with item requested
        for store in self.allStores {
            if store.hasEmoji(emoji: order.emoji!, withQuantity: order.quantity!) {
                possibleStores.append(store)
            }
        }
        
        //if no stores have the product
        if possibleStores.isEmpty { return nil }
        
        //if there is only one, return
        if possibleStores.count == 1 { return possibleStores.first! }
        
        //if there is more, check lowest price
        return possibleStores
            .sorted(by: {$0.productForEmoji(emoji: order.emoji!)!.price! < $1.productForEmoji(emoji: order.emoji!)!.price!} )
            .first!
        
    }

}

extension StoreBossManager: PeerMessageDelegate {
    
    func didReceiveMessage(message: Message, fromUser user: String, string: String) {
        switch message.type! {
        case .announcingProducts:
            self.addStore(baseStore: message.baseStore)
        case .buyOrder:
            self.processBuyOrder(order: message.buyOrder!, fromPeer: user)
        default:
            break
        }
    }
}
