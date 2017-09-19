//
//  PeerReputation.swift
//  P2PSocketsSale
//
//  Created by Aline Borges on 19/09/17.
//  Copyright © 2017 Aline Borges. All rights reserved.
//

import Foundation

class PeerReputation {
    
    var peerInfo: PeerInfo
    var reputation = 1
    
    init(peerInfo: PeerInfo) {
        self.peerInfo = peerInfo
    }
    
    func increaseReputation() {
        self.reputation += 1
    }
    
}
