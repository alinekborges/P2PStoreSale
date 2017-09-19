//
//  PeerInfo.swift
//  P2PSocketsSale
//
//  Created by Aline Borges on 19/09/17.
//  Copyright © 2017 Aline Borges. All rights reserved.
//

import Foundation
import ObjectMapper

class PeerInfo : Mappable {
    
    var ip: String?
    var port: UInt16?
    var name: String?
    var publicKey: String?
    
    init(name: String) {
        self.name = name
    }
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        ip    <- map["ip"]
        port    <- map["port"]
        name    <- map["name"]
        publicKey    <- map["publicKey"]
    }
    
}

extension PeerInfo: Equatable {
    static func == (lhs: PeerInfo, rhs: PeerInfo) -> Bool {
        return
            lhs.port == rhs.port && lhs.ip == rhs.ip && lhs.name == rhs.name
    }
}
