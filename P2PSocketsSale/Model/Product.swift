//
//  Product.swift
//  P2PSocketsSale
//
//  Created by Aline Borges on 10/09/17.
//  Copyright © 2017 Aline Borges. All rights reserved.
//

import Foundation
import ObjectMapper

class Product: Mappable {
    
    var emoji: String?
    var quantity: Int?
    var price: Int?
    
    init(emoji: String, quantity: Int, price: Int) {
        self.emoji = emoji
        self.quantity = quantity
        self.price = price
    }
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        emoji    <- map["emoji"]
        quantity    <- map["quantity"]
        price    <- map["price"]
    }
    
    
}
