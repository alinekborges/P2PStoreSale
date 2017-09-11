//
//  MultipeerManager.swift
//  P2PSocketsSale
//
//  Created by Aline Borges on 10/09/17.
//  Copyright © 2017 Aline Borges. All rights reserved.
//

import Foundation
import MultipeerConnectivity

protocol StoreMultipeerDelegate {
    
    func isSelectedAsBoss()
    
}

class StoreMultipeerManager: NSObject {
    //TODO: Have a queue for each manager
    var peerID: String
    var manager: MultipeerServiceManager
    var session: MCSession
    
    var boss: MCPeerID?
    
    var delegate: StoreMultipeerDelegate?
    
    init(peerID: String) {
        self.peerID = peerID
        self.manager = MultipeerServiceManager(peerID: peerID)
        self.session = self.manager.session
        
        super.init()
        
        self.manager.delegate = self
    }
    
    //Election will happen in alphabetical order
    func newElection() {
        var allPeers = self.session.connectedPeers
            .map( { $0.displayName} )
        
        allPeers.append(self.peerID) //include my own name in connected peers
        
        if let elected =
            allPeers.sorted(by: { $0 < $1 } )
            .first {
            
            if (elected == self.peerID) {
                //call delegate letting store know it's the new boss
                self.delegate?.isSelectedAsBoss()
            } else {
                //not elected, save new boss
                self.boss = peerWithID(elected)
            }
            
        }
        
    }
    
    func peerWithID(_ peerID: String) -> MCPeerID? {
        return self.session.connectedPeers.filter( {$0.displayName == peerID} ).first
    }
    
    func send(message: Message, toPeer peer: MCPeerID? = nil) {
        var peers:[MCPeerID]!
        if peer == nil {
            peers = session.connectedPeers
        } else {
            peers = [peer!]
        }
        
        let data = messageToData(message: message)
        
        try! self.session.send(data, toPeers: peers, with: MCSessionSendDataMode.reliable)
        
        
    }
    
    func messageToData(message: Message) -> Data {
        
        let string = message.toJSONString()
        print("sending: \(string)")
        return string!.data(using: .utf8)!
        
    }
}

extension StoreMultipeerManager: ServiceManagerDelegate {
    
    func receiveData(manager : MultipeerServiceManager, user: String, message: String) {
        
    }
    
    func connectedDevicesChanged(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        
        print("connected peers: \(session.connectedPeers.count) -- \(session.connectedPeers.map( { $0.displayName } ))")
        //if there is no current boss and connected peers is at least 3 (me + 3 = 4)
        if boss == nil && session.connectedPeers.count >= 3 {
            self.newElection()
        }
        
        //TODO: Handle Boss disconnection
    }
}
