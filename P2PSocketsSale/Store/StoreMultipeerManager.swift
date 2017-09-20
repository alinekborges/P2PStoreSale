//
//  MultipeerManager.swift
//  P2PSocketsSale
//
//  Created by Aline Borges on 10/09/17.
//  Copyright © 2017 Aline Borges. All rights reserved.
//

import Foundation

protocol StoreMultipeerDelegate {
    
    func isSelectedAsBoss()
    func selectedNewBoss(_ peer: PeerInfo)
    func selectedPeerForBuy(_ peers: [PeerInfo], buyOrder: BuyOrder)
    func decrypt(data: Data) -> String
    func sell(_ buyOrder: BuyOrder, toPeer peer: PeerInfo)
    func receivedProduct(_ buyOrder: BuyOrder, fromPeer peer: PeerInfo)
    func sendDiscovery()
}

protocol PeerMessageDelegate {
    func didReceiveMessage(message: Message, string: String?)
}

class StoreMultipeerManager: NSObject {
    
    var peerID: String
    var peerInfo: PeerInfo?
    var manager: MultipeerServiceManager
    
    var boss: PeerInfo? {
        didSet{
            if (boss != nil) {
                self.postNotification(notificationName: "end_election.\(self.peerInfo!.name!)")
            }
        }
    }
    var isBoss: Bool = false
    var bossIsAlive: Bool = true
    
    var delegate: StoreMultipeerDelegate?
    var messageDelegate: PeerMessageDelegate?
    
    var isElecting: Bool = false
    
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
        
        if (isElecting) { return }
        
        if self.boss != nil { return }
        
        print("NEW ELECTION PROCESS STARTED")
        
        self.postNotification(notificationName: "start_election.\(self.peerInfo!.name!)")
        
        isElecting = true
        //remove all current connected peers
        self.connectedPeers.removeAll()
        
        queue.asyncAfter(deadline: .now() + Constants.timeInterval * 2) {
            if self.boss != nil { return }
            //send discovery again to check connected peers
            print("sending discovery")
            self.delegate?.sendDiscovery()
        }
        
        queue.asyncAfter(deadline: .now() + Constants.timeInterval * 3) {
            if self.boss != nil { return }
            
            //get all unique names (name + port)
            let allPeers = self.connectedPeers.map({$0.uniqueName})
            
            
            
            print("\(self.peerID) electing new boss from \(allPeers.description)")
            
            if let elected =
                allPeers.sorted(by: { $0 < $1 } )
                    .first {
                self.isElecting = false
                
                if (elected == self.peerInfo?.uniqueName) {
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
    
    func sendToBoss(message: Message) {
        guard let boss = self.boss else { return }
        self.send(message: message, toPeer: boss)
    }
    
    func sendBroadcast(message: Message) {
        let data = message.toData()
        //print("BROADCAST::: \(message.message ?? "...")")
        self.manager.sendBroadcast(data: data)
    }
    
    func send(message: Message, toPeer peer: PeerInfo) {
        let data = message.toData()
        self.manager.send(data: data, toHost: peer.ip!, onPort: peer.port!)
    }
    
    func sendEncrypted(message: Message, withPublicKey publicKey: String, toPeer peer: PeerInfo) {
        
        let data = message.encrypt(withPublicKey: publicKey)
        self.manager.send(data: data, toHost: peer.ip!, onPort: peer.port!)
        
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
        if (self.connectedPeers.count >= 4 && self.boss == nil && self.isBoss == false) {
            
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
        
        self.postNotification(notificationName: "keep_alive")
    }
    
    func handleBuyOrderResponse(message: Message) {
        guard let peers = message.buyOrderResponse?.peers else {
            print("boss did not send complete message!")
            return
        }
        self.delegate?.selectedPeerForBuy(peers, buyOrder: message.buyOrder!)
    }
    
    func postNotification(notificationName: String) {
        DispatchQueue.main.async {
            self.postNotification(notificationName: notificationName, withObject: nil, userInfo: nil)
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
    
    func receivedUnicastData(manager: MultipeerServiceManager, string: String?, data: Data) {
        var msg: Message?
        
        if string != nil  {
            msg = Message(JSONString: string!)
        } else {
        print("\(self.peerID) ENCRYPTED MESSAGE::: \(String(data: data, encoding: .ascii) ?? "...")")
            let str = self.delegate?.decrypt(data: data)
            msg = Message(JSONString: str!)
        }
        
        guard let message = msg, let type = message.type else {
            return
        }
        
        self.messageDelegate?.didReceiveMessage(message: message, string: string)
        
        if type != .bossKeepAlive {
            print("\(self.peerID) unicast received: \(message.message ?? "nil")")
        }
        
        switch type {
        case .buyOrderResponse:
            handleBuyOrderResponse(message: message)
        case .completeBuy:
            self.delegate?.sell(message.buyOrder!, toPeer: message.peerInfo!)
        case .sendingProduct:
            self.delegate?.receivedProduct(message.buyOrder!, fromPeer: message.peerInfo!)
        default:
            break
        }
        
    }

}
