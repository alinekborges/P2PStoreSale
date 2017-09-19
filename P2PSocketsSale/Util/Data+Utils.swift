//
//  Data+Utils.swift
//  P2PSocketsSale
//
//  Created by Aline Borges on 18/09/17.
//  Copyright © 2017 Aline Borges. All rights reserved.
//

import Foundation
extension Data {
    func toIPString() -> String {
        let array = Array(self)
        
        let str1 = String(array[0])
        
        let str2 = String(array[1])
        
        let str3 = String(array[2])
        
        let str4 = String(array[3])
        
        return "\(str1).\(str2).\(str3).\(str4)"
    }
}
