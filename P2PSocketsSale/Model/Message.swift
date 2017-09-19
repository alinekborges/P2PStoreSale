//
//  File.swift
//  P2PSocketsSale
//
//  Created by Aline Borges on 10/09/17.
//  Copyright © 2017 Aline Borges. All rights reserved.
//

import Foundation
import ObjectMapper

class Message: Mappable {
    
    enum MessageType: String {
        case discovery = "discovery"
        case discoveryResponse = "discoveryResponse"
        case newElection = "newElection"
        case bossKeepAlive = "bossKeepAlive"
        case announcingProducts = "announcingProducts"
        case buyOrder = "buyOrder"
        case buyOrderResponse = "buyOrderResponse"
        case completeBuy = "completeBuy"
        case sendingProduct = "sendingProduct"
    }
    
    var type: MessageType?
    var peerID: String?
    var peerInfo: PeerInfo?
    var message: String?
    var baseStore: StoreBase?
    var buyOrder: BuyOrder?
    var buyOrderResponse: BuyOrderResponse?
    
    init() {
        
    }
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        type    <- map["type"]
        peerID    <- map["peerID"]
        message    <- map["message"]
        buyOrder    <- map["buyOrder"]
        peerInfo    <- map["peerInfo"]
        baseStore    <- map["baseStore"]
        buyOrderResponse    <- map["buyOrderResponse"]
    }
    
    func toData() -> Data {
        let string = self.toJSONString()
        return string!.data(using: .utf8)!
    }
    
    
    func encrypt(withPublicKey key: String) -> Data {
        let json = self.toJSONString()
        return try! RSAUtils.encryptWithRSAPublicKey(str: json!, pubkeyBase64: key)!
    }
}

class BuyOrder: Mappable {
    
    var emoji: String?
    var quantity: Int?
    
    init(emoji: String, quantity: Int) {
        self.emoji = emoji
        self.quantity = quantity
    }
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        emoji    <- map["emoji"]
        quantity    <- map["quantity"]
    }
    
    var description: String {
        return "\(quantity!) \(emoji!)"
    }
}


class BuyOrderResponse: Mappable {
    
    var peers: [PeerInfo]?
    
    init(peers: [PeerInfo]) {
        self.peers = peers
    }
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        peers    <- map["peers"]
    }
}
