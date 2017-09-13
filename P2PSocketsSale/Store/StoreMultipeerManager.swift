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
    func selectedPeerForBuy(_ peerID: String?, publicKey: String?)
    func decrypt(data: Data) -> String
    func sell(_ buyOrder: BuyOrder, toPeer peer: String)
    func receivedProduct(_ buyOrder: BuyOrder)
    func sendDiscovery()
}

protocol PeerMessageDelegate {
    func didReceiveMessage(message: Message, fromUser user: String, string: String?)
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
    
    var queue: DispatchQueue
    
    var connectedPeers:[MCPeerID] = []
    
    init(peerID: String) {
        self.peerID = peerID
        self.manager = MultipeerServiceManager(peerID: peerID)
        self.session = self.manager.session
        queue = DispatchQueue(label: "com.peers.\(peerID)")
        super.init()
        
        self.manager.delegate = self
        
        
        queue.asyncAfter(deadline: .now() + 2) {
            self.delegate?.sendDiscovery()
        }
    }
    
    
    
    //Election will happen in alphabetical order
    func newElection() {
        if (self.boss != nil) { return }
        
        queue.asyncAfter(deadline: .now() + Constants.timeInterval * 2) {
            if self.boss != nil { return }
            
            var allPeers = self.manager.session.connectedPeers
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
            print("\(self.peerID):: boss is dead")
            
            self.boss = nil
            if (self.connectedPeers.count >= 4) {
                self.newElection()
            }
        }
        
        bossIsAlive = false
    }
    
    func peerWithID(_ peerID: String) -> MCPeerID? {
        return self.connectedPeers.filter( {$0.displayName == peerID} ).first
    }
    
    func sendToBoss(message: Message) {
        if (self.boss == nil) { return }
        self.send(message: message, toPeer: self.boss)
    }
    
    func send(message: Message, toPeer peer: String) {
        if let peerToSend = self.connectedPeers.filter({$0.displayName == peer}).first {
            send(message: message, toPeer: peerToSend)
        }
    }
    
    func sendEncrypted(message: Message, withPublicKey publicKey: String, toPeer peer: String) {
        if let peerToSend = self.connectedPeers.filter({$0.displayName == peer}).first {
            let encrypted = message.encrypt(withPublicKey: publicKey)
            
            do {
                try self.session.send(encrypted, toPeers: [peerToSend], with: MCSessionSendDataMode.reliable)
            } catch let error {
                print("boss: error sending encrypted message: \(error.localizedDescription) to peer: \(peer)")
            }
        } else {
            print("peer not connected: \(peer)")
        }
    }
    
    func send(message: Message, toPeer peer: MCPeerID? = nil) {
        var peers:[MCPeerID]!
        if peer == nil {
            if (self.connectedPeers.isEmpty) {
                peers = self.manager.session.connectedPeers
            } else {
                peers = connectedPeers
            }
        } else {
            peers = [peer!]
        }
        
        if peers.isEmpty {
            print("no peers to send messages to! Connected peers: \(peers). Message: \(message.message)")
            return
        }
        
        do {
            try self.session.send(message.toData(), toPeers: peers, with: MCSessionSendDataMode.reliable)
        } catch let error {
            if (message.type == .bossKeepAlive) {
                print("error sending boss keepalive!")
                
            }
            print("boss: error sending message: \(error.localizedDescription) to peers: \(peers.map( {$0.displayName} ).description)")
        }
        
    }
    
    func disconnect() {
        self.manager.disconnect()
        print("disconnecting \(self.peerID)")
    }
    
    func handleEnctryptedMessage(string: String) -> Message {
        return Message()
    }
    
    func addConnectedPeer(_ peerID: MCPeerID) {
        let isInPeerList: Bool = self.connectedPeers.map({$0.displayName}).contains(peerID.displayName)
        
        if !isInPeerList {
            self.connectedPeers.append(peerID)
        }
        
        if self.boss == nil && self.connectedPeers.count >= 3 {
            self.queue.async {
                self.newElection()
            }
        }
    }
    
    

    func sendDiscoveryResponse(peerID: MCPeerID) {
        let message = Message()
        message.type = .discoveryResponse
        message.message = "(boss) announcing myself to new peer: my name is \(self.peerID)"
        message.peerID = self.peerID
        self.send(message: message, toPeer: peerID)
    }
    
}

extension StoreMultipeerManager: ServiceManagerDelegate {
    
    func receiveData(manager : MultipeerServiceManager, peerID:MCPeerID, string: String?, data: Data) {
        
        var msg: Message?
        
        if string != nil  {
            msg = Message(JSONString: string!)
        } else {
            let str = self.delegate?.decrypt(data: data)
            msg = Message(JSONString: str!)
            print("(boss) decrypting message with my PRIVATE KEY: \(msg?.message ?? "no message")")
        }
        
        guard let message = msg, let type = message.type else {
            print("(boss) string received: \(string)")
            return
        }
        
        self.messageDelegate?.didReceiveMessage(message: message, fromUser: peerID.displayName, string: string)
        
        //if type != .bossKeepAlive {
            //print("\(self.peerID) message received: \(message.message ?? "")")
        print("(boss) \(self.peerID) connectedPeers: \(self.manager.session.connectedPeers.map({$0.displayName}).joined(separator: " | "))")
        //}
        
        switch type {
        case .discovery:
            self.addConnectedPeer(peerID)
            self.sendDiscoveryResponse(peerID: peerID)
        case .discoveryResponse:
            self.addConnectedPeer(peerID)
        case .bossKeepAlive:
            self.bossIsAlive = true
            if (boss == nil) {
                if let newboss = self.peerWithID(message.peerID!) {
                    self.boss = newboss
                    print("\(self.peerID) received message from boss \(boss!.displayName)! He is the boss!")
                    newBoss(self.boss!)
                }
            }
        case .buyOrderResponse:
            guard let peer = message.buyOrderResponse?.peerID else {
                print("boss did not send complete message!")
                return
            }
            self.delegate?.selectedPeerForBuy(peer, publicKey: message.buyOrderResponse?.publicKey)
        case .completeBuy:
            self.delegate?.sell(message.buyOrder!, toPeer: message.peerID!)
        case .sendingProduct:
            self.delegate?.receivedProduct(message.buyOrder!)
        default:
            break
        }
        
    }
    
    func connectedDevicesChanged(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        
        //if there is no current boss and connected peers is at least 3 (me + 3 = 4)
        //wait 5 seconds to see if a boss announces himself
        
        
        
    }
}
