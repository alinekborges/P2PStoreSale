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
    }
    
    var type: MessageType?
    var peerID: String?
    var message: String?
    
    init() {
        
    }
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        type    <- map["type"]
        peerID    <- map["peerID"]
        message    <- map["message"]
    }
    
    func toData() -> Data {
        let string = self.toJSONString()
        return string!.data(using: .utf8)!
    }
    
    
}
