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
    
    var name: String?
    var products: [Product]?
    var score: Int?
    var publicKey: String?
    
    init(name: String, products: [Product], score: Int, publicKey: String) {
        self.name = name
        self.products = products
        self.score = score
        self.publicKey = publicKey
    }
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        name    <- map["name"]
        products    <- map["products"]
        score    <- map["score"]
        publicKey    <- map["publicKey"]
    }
    
}
