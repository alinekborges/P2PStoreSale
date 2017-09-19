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
        keepAlive.peerInfo = self.manager.peerInfo
        keepAlive.peerID = self.manager.peerID
        
        super.init()
        
        self.manager.messageDelegate = self

    }
    
    func sendKeepAlive() {
        
        self.manager.sendBroadcast(message: keepAlive)
        
       
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
        
        
        print("boss received products from \(baseStore?.description ?? "..."). Current store count: \(self.allStores.count)")
        DispatchQueue.main.async {
            self.postNotification(notificationName: "update_UI")
        }
    }
    
    func processBuyOrder(order: BuyOrder, fromPeer peer: PeerInfo) {
        print("boss received buy order from \(peer.description): \(order.description)")
        
        let sellers = sellerForOrder(order: order, fromPeer: peer)
        
        if sellers.isEmpty {
            print("boss error finding a store to sell: \(order.emoji)")
            return
        }
        
        print("boss elected \(sellers) to sell \(order.description)")
        
        
        let response = BuyOrderResponse(peers: sellers)
            
        let message = Message()
        message.type = .buyOrderResponse
        message.message = "buy order response: should buy from seller \(sellers)"
        message.buyOrderResponse = response
        message.peerID = self.manager.peerID
        message.peerInfo = self.manager.peerInfo
        message.buyOrder = order
            
        self.manager.send(message: message, toPeer: peer)
            
        
    }
    
    func sellerForOrder(order: BuyOrder, fromPeer peer: PeerInfo) -> [PeerInfo] {
        
        var possibleStores: [StoreBase] = []
        
        //Find all stores with item requested
        //Remove from list store that is asking for the product
        for store in self.allStores.filter({$0.peerInfo != peer}) {
            if store.hasEmoji(emoji: order.emoji!, withQuantity: order.quantity!) {
                possibleStores.append(store)
            }
        }
        
        //if no stores have the product
        if possibleStores.isEmpty { return [] }
        
        //if there is only one, return
        if possibleStores.count == 1 { return possibleStores.map({$0.peerInfo!}) }
        
        //if there is more, check lowest price
        let sortedStores = possibleStores
            .sorted(by: {$0.productForEmoji(emoji: order.emoji!)!.price! < $1.productForEmoji(emoji: order.emoji!)!.price!} )
        
        let lowestPrice = sortedStores.first!.productForEmoji(emoji: order.emoji!)?.price!
        
        return sortedStores
            .filter({$0.productForEmoji(emoji: order.emoji!)?.price! == lowestPrice})
            .map({$0.peerInfo!})
        
    }

}

extension StoreBossManager: PeerMessageDelegate {
    
    func didReceiveMessage(message: Message, string: String?) {
        switch message.type! {
        case .announcingProducts:
            self.addStore(baseStore: message.baseStore)
        case .buyOrder:
            self.processBuyOrder(order: message.buyOrder!, fromPeer: message.peerInfo!)
        default:
            break
        }
    }
}
