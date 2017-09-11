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
    var isBoss: Bool = false
    var bossIsAlive: Bool = true
    
    var delegate: StoreMultipeerDelegate?
    
    var timeAfterElection: Int = 0
    
    init(peerID: String) {
        self.peerID = peerID
        self.manager = MultipeerServiceManager(peerID: peerID)
        self.session = self.manager.session
        
        super.init()
        
        self.manager.delegate = self
    }
    
    //Election will happen in alphabetical order
    func newElection() {
        if (self.boss != nil) { return }
        
        var allPeers = self.session.connectedPeers
            .map( { $0.displayName} )
        
        allPeers.append(self.peerID) //include my own name in connected peers
        
        print("\(self.peerID) electing new boss from \(allPeers.description)")
        
        if let elected =
            allPeers.sorted(by: { $0 < $1 } )
            .first {
            
            //save the boss
            
            
            if (elected == self.peerID) {
                //call delegate letting store know it's the new boss
                print("I'm elected as boss: \(elected)")
                self.isBoss = true
                self.bossIsAlive = true
                self.timeAfterElection = 0
                self.delegate?.isSelectedAsBoss()
                self.boss = self.manager.myPeerId
            } else {
                self.boss = peerWithID(elected)
            }
            
        }
        
    }
    
    //every tick, we set boss as false
    //every keep alive, it will come back to true
    //if it's still false, boss is probably dead
    func onTick() {
        timeAfterElection += 1
        if boss == nil { return } //there is no boss to check!
        if timeAfterElection < 4 { return } //too soon!
        if self.isBoss { return } //boss is handled elsewhere
        if bossIsAlive == false {
            //TODO: Oh shit boss is dead! 
            print("boss is dead")
            
            self.boss = nil
            self.newElection()
        }
        
        bossIsAlive = false
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
        
        do {
            try self.session.send(message.toData(), toPeers: peers, with: MCSessionSendDataMode.reliable)
        } catch let error {
            print("boss: error sending message \(error.localizedDescription)")
        }
        
    }
    
    func disconnect() {
        self.manager.disconnect()
        print("disconnecting \(self.peerID)")
    }
    
}

extension StoreMultipeerManager: ServiceManagerDelegate {
    
    func receiveData(manager : MultipeerServiceManager, user: String, string: String) {
        
        let message = Message(JSONString: string)
        
        guard let type = message?.type else {
            return
        }
        
        print("\(self.peerID) message received type: \(type)")
        
        switch type {
        case .bossKeepAlive:
            self.bossIsAlive = true
            if (boss == nil) {
                boss = self.peerWithID(message!.peerID!)
                print("received message from new boss \(boss?.displayName)!")
            }
        default:
            break
        }
        
    }
    
    func connectedDevicesChanged(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        
        //if there is no current boss and connected peers is at least 3 (me + 3 = 4)
        //wait 5 seconds to see if a boss announces himself
        
        if state != .connected { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.timeInterval + 1.0) {
            if self.boss == nil && self.session.connectedPeers.count >= 3 {
                self.newElection()
            }
        }
        
        //TODO: Handle Boss disconnection
    }
}
