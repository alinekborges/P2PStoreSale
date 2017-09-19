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
    var score: Int?
    var publicKey: String?
    
    init(name: String, products: [Product], score: Int, publicKey: String) {
        self.peerInfo = PeerInfo(name: name)
        self.products = products
        self.score = score
        self.publicKey = publicKey
    }
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        products    <- map["products"]
        score    <- map["score"]
        publicKey    <- map["publicKey"]
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
        self.publicKey = store.publicKey
        self.score = store.score
    }
    
    var description: String {
        return "Store \(self.peerInfo!.name!): \(self.products!.map({$0.emoji!}).joined())"
    }
}

extension StoreBase: Equatable {
    static func == (lhs: StoreBase, rhs: StoreBase) -> Bool {
        return
            lhs.peerInfo!.port == rhs.peerInfo!.port
    }
}
