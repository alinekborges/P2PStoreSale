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
    func selectedNewBoss(_ peerID: MCPeerID)
    func selectedPeerForBuy(_ peerID: MCPeerID?, publicKey: String?)
    
}

protocol PeerMessageDelegate {
    func didReceiveMessage(message: Message, fromUser user: String, string: String)
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
    var messageDelegate: PeerMessageDelegate?
    
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
        
        var allPeers = self.manager.connectedPeers
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
                //self.boss = peerWithID(elected)
                
            }
            
        }
        
    }
    
    func newBoss(_ peerID: MCPeerID) {
        self.delegate?.selectedNewBoss(peerID)
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
            if (self.manager.connectedPeers.count >= 4) {
                self.newElection()
            }
        }
        
        bossIsAlive = false
    }
    
    func peerWithID(_ peerID: String) -> MCPeerID? {
        return self.manager.connectedPeers.filter( {$0.displayName == peerID} ).first
    }
    
    func sendToBoss(message: Message) {
        self.send(message: message, toPeer: self.boss)
    }
    
    func send(message: Message, toPeer peer: String) {
        if let peerToSend = self.manager.connectedPeers.filter({$0.displayName == peer}).first {
            send(message: message, toPeer: peerToSend)
        }
    }
    
    //func sendEncryptedMessage(
    
    func send(message: Message, toPeer peer: MCPeerID? = nil) {
        var peers:[MCPeerID]!
        if peer == nil {
            peers = manager.connectedPeers
        } else {
            peers = [peer!]
        }
        
        if peers.isEmpty {
            print("no peers to send messages to! Connected peers: \(self.manager.connectedPeers). Message: \(message.message)")
            return
        }
        
        do {
            try self.session.send(message.toData(), toPeers: peers, with: MCSessionSendDataMode.reliable)
        } catch let error {
            print("boss: error sending message: \(error.localizedDescription) to peers: \(peers.map( {$0.displayName} ).description)")
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
        
        self.messageDelegate?.didReceiveMessage(message: message!, fromUser: user, string: string)
        
        print("\(self.peerID) message received: \(message!.message!)")
        
        switch type {
        case .bossKeepAlive:
            self.bossIsAlive = true
            if (boss == nil) {
                boss = self.peerWithID(message!.peerID!)
                print("received message from boss \(boss?.displayName)! He is the boss!")
                newBoss(self.boss!)
            }
        case .buyOrderResponse:
            guard let peer = message?.buyOrderResponse?.peerID else {
                return
            }
            
            let peerID = MCPeerID(displayName: peer)
                
            self.delegate?.selectedPeerForBuy(peer, publicKey: message?.buyOrderResponse?.publicKey)
        default:
            break
        }
        
    }
    
    func connectedDevicesChanged(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        
        //if there is no current boss and connected peers is at least 3 (me + 3 = 4)
        //wait 5 seconds to see if a boss announces himself
        
        if state != .connected { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.timeInterval + 1.0) {
            if self.boss == nil && self.manager.connectedPeers.count >= 3 {
                self.newElection()
            }
        }
        
        //TODO: Handle Boss disconnection
    }
}
