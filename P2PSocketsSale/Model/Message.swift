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
        case newElection = "newElection"
        case bossKeepAlive = "bossKeepAlive"
        case announcingProducts = "announcingProducts"
        case buyOrder = "buyOrder"
        case buyOrderResponse = "buyOrderResponse"
        case completeBuy = "completeBuy"
    }
    
    var type: MessageType?
    var peerID: String?
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
        baseStore    <- map["baseStore"]
        buyOrderResponse    <- map["buyOrderResponse"]
    }
    
    func toData() -> Data {
        let string = self.toJSONString()
        return string!.data(using: .utf8)!
    }
    
    
    func encrypt(withPublicKey key: String) -> String {
        //TODO: Actually encrypt this
        //return self.toJSONString()!
        return "E7lU380okEnsV2rPVNh4idtkAKaRXbRQu7a2Atx9ePTmyeXO0x65daiNjCd2E4ePXfV1bpyp627KMQ4bxhGmiQ=="
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
    
    var peerID: String?
    var publicKey: String?
    
    init(peerID: String, publicKey: String) {
        self.peerID = peerID
        self.publicKey = publicKey
    }
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        peerID    <- map["peerID"]
        publicKey    <- map["publicKey"]
    }
}
