//
//  StoreBase.swift
//  P2PSocketsSale
//
//  Created by Aline Borges on 10/09/17.
//  Copyright © 2017 Aline Borges. All rights reserved.
//

import Foundation
import ObjectMapper

class StoreBase: Mappable {
    
    var peerInfo: PeerInfo?
    var products: [Product]?
    
    init(products: [Product], peerInfo: PeerInfo) {
        self.peerInfo = peerInfo
        self.products = products
    }
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        products    <- map["products"]
        peerInfo    <- map["peerInfo"]
    }
    
    func hasEmoji(emoji: String, withQuantity quantity: Int) -> Bool {
        for product in self.products! {
            if (product.emoji! == emoji && product.quantity! >= quantity ) {
                return true
            }
        }
        
        return false
    }
    
    func productForEmoji(emoji: String) -> Product? {
        for product in self.products! {
            if (product.emoji! == emoji) {
                return product
            }
        }
        
        return nil
    }
    
    func updateValues(store: StoreBase) {
        self.products = store.products
        self.peerInfo = store.peerInfo
    }
    
    var description: String {
        return "Store \(self.peerInfo!.name!): \(self.products!.map({$0.emoji!}).joined())"
    }
}

extension StoreBase: Equatable {
    static func == (lhs: StoreBase, rhs: StoreBase) -> Bool {
        return
            lhs.peerInfo == rhs.peerInfo
    }
}
