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
    func selectedNewBoss(_ peer: PeerInfo)
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
    
    var peerID: String
    var peerInfo: PeerInfo?
    var manager: MultipeerServiceManager
    
    var boss: PeerInfo?
    var isBoss: Bool = false
    var bossIsAlive: Bool = true
    
    var delegate: StoreMultipeerDelegate?
    var messageDelegate: PeerMessageDelegate?
    
    var timeAfterElection: Int = 0
    
    var queue: DispatchQueue
    
    var timer: Timer?
    
    var connectedPeers:[PeerInfo] = []
    
    init(peerID: String, didSetupListenSocket: @escaping ((_ ip: String, _ port: UInt16) -> ())) {
        self.peerID = peerID
        self.manager = MultipeerServiceManager(peerID: peerID, didSetupListenSocket: didSetupListenSocket)
        
        queue = DispatchQueue(label: "com.peers.\(peerID)")
        super.init()
        
        self.manager.delegate = self
        
        
        queue.asyncAfter(deadline: .now() + 1) {
            self.delegate?.sendDiscovery()
        }
    }
    
    //Election will happen in alphabetical order
    func newElection() {
        
        if self.boss != nil { return }
        
        queue.async {
            
            let allPeers = self.connectedPeers.map({$0.name!})
            
            print("\(self.peerID) electing new boss from \(allPeers.description)")
            
            if let elected =
                allPeers.sorted(by: { $0 < $1 } )
                    .first {
                
                if (elected == self.peerID) {
                    //I'm the boss!!
                    self.isBoss = true
                    self.delegate?.isSelectedAsBoss()
                    
                } else {
                    //nothing, wait for boss contacting me
                }
            }
            
        }
        
    }
    
    //every tick, we set boss as false
    //every keep alive, it will come back to true
    //if it's still false, boss is probably dead
    func onTick() {
        if boss == nil { return } //there is no boss to check!
        if self.isBoss { return } //boss is handled elsewhere
        if bossIsAlive == false {
            print("\(self.peerID):: boss is dead")
            self.boss = nil

            if (self.connectedPeers.count >= 4) {
                queue.asyncAfter(deadline: .now() + Constants.timeInterval * 2) {
                    self.newElection()
                }
            }
        }
        
        bossIsAlive = false
    }
    
    func peerWithID(_ peerID: String) -> MCPeerID? {
        return nil
        //return self.connectedPeers.filter( {$0.displayName == peerID} ).first
    }
    
    func sendToBoss(message: Message) {
        if (self.boss == nil) { return }
        //self.send(message: message, toPeer: self.boss)
    }
    
    func send(message: Message, toPeer peer: String) {
        /*if let peerToSend = self.connectedPeers.filter({$0.displayName == peer}).first {
            send(message: message, toPeer: peerToSend)
        }*/
        
    }
    
    func sendBroadcast(message: Message) {
        let data = message.toData()
        print("BROADCAST::: \(message.message ?? "...")")
        self.manager.sendBroadcast(data: data)
    }
    
    func sendEncrypted(message: Message, withPublicKey publicKey: String, toPeer peer: String) {
        /*if let peerToSend = self.connectedPeers.filter({$0.displayName == peer}).first {
            let encrypted = message.encrypt(withPublicKey: publicKey)
            
            do {
                //try self.session.send(encrypted, toPeers: [peerToSend], with: MCSessionSendDataMode.reliable)
            } catch let error {
                print("boss: error sending encrypted message: \(error.localizedDescription) to peer: \(peer)")
            }
        } else {
            print("peer not connected: \(peer)")
        }*/
    }
    
    func send(message: Message, toPeer peer: MCPeerID? = nil) {
        return
        var peers:[MCPeerID]!
        if peer == nil {
            if (self.connectedPeers.isEmpty) {
                //peers = self.manager.session.connectedPeers
            } else {
                //peers = connectedPeers
            }
        } else {
            peers = [peer!]
        }
        
        if peers.isEmpty {
            print("no peers to send messages to! Connected peers: \(peers). Message: \(message.message)")
            return
        }
        
        do {
            //try self.session.send(message.toData(), toPeers: peers, with: MCSessionSendDataMode.reliable)
        } catch let error  {
            if (message.type == .bossKeepAlive) {
                print("error sending boss keepalive!")
                
            }
            print("boss: error sending message: \((error as! NSError).localizedDescription) to peers: \(peers.map( {$0.displayName} ).description)")
        }
        
    }
    
    func disconnect() {
        self.manager.disconnect()
        print("disconnecting \(self.peerID)")
    }
    
    func handleEnctryptedMessage(string: String) -> Message {
        return Message()
    }
    
    func addConnectedPeer(peerInfo: PeerInfo?) {
        guard let peerInfo = peerInfo else {
            print("oops! forgot to send me peer info")
            return
        }
        
        let isInPeerList: Bool = self.connectedPeers
            .contains(peerInfo)
        
        if !isInPeerList {
            self.connectedPeers.append(peerInfo)
            //print("\(self.peerID):::connectedPeers: \(self.connectedPeers.map({$0.name}))")
            checkNewElectionNeeded()
        }
        
    }
    
    func checkNewElectionNeeded() {
        if (self.connectedPeers.count >= 4 && self.boss == nil) {
            
            queue.asyncAfter(deadline: .now() + Constants.timeInterval * 2) {
                self.newElection()
            }
            
        }
    }

    func sendDiscoveryResponse() {
        let message = Message()
        message.type = .discoveryResponse
        message.message = "announcing myself to new peer: my name is \(self.peerID)"
        message.peerID = self.peerID
        message.peerInfo = self.peerInfo
        self.sendBroadcast(message: message)
    }
    
    func handleKeepAlive(message: Message) {
        self.bossIsAlive = true
        
        if (self.boss == nil) {
            if (message.peerInfo == self.peerInfo) { return }
            self.boss = message.peerInfo
            self.delegate?.selectedNewBoss(self.boss!)
            print("\(self.peerID) received message from boss \(self.boss!.name)! He is the boss!")
        }
    }
    
}

extension StoreMultipeerManager: ServiceManagerDelegate {
    func receiveMulticastData(manager: MultipeerServiceManager, string: String?, data: Data) {
        
        let message = Message(JSONString: string!)
        
        guard let type = message?.type else {
            return
        }
        
        switch type {
        case .discovery:
            addConnectedPeer(peerInfo: message?.peerInfo)
            sendDiscoveryResponse()
        case .discoveryResponse:
            addConnectedPeer(peerInfo: message?.peerInfo)
        case .bossKeepAlive:
            handleKeepAlive(message: message!)
        default:
            break
        }
    }

    
    func receiveData(manager : MultipeerServiceManager, peerID:MCPeerID, string: String?, data: Data) {
        
        queue.async {
            
        
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
        
        if type != .bossKeepAlive {
          
        //print("(boss) \(self.peerID) connectedPeers: \(self.manager.session.connectedPeers.map({$0.displayName}).joined(separator: " | "))")
        }
        
        switch type {
        case .discovery:
            break
            //self.addConnectedPeer(peerID)
            //self.sendDiscoveryResponse(peerID: peerID)
        case .discoveryResponse:
            break
            //self.addConnectedPeer(peerID)
        case .bossKeepAlive:
            break
            
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
        
    }
    
    func connectedDevicesChanged(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        
        //if there is no current boss and connected peers is at least 3 (me + 3 = 4)
        //wait 5 seconds to see if a boss announces himself
        if self.boss == nil && session.connectedPeers.count >= 3 {
            self.queue.async {
                self.newElection()
            }
        }
        
        
    }
}
