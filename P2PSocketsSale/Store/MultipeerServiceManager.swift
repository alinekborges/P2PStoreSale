//
//  MultipeerServiceManager.swift
//  P2PSocketsSale
//
//  Created by Aline Borges on 09/09/17.
//  Copyright © 2017 Aline Borges. All rights reserved.
//

import Foundation
import MultipeerConnectivity


protocol ServiceManagerDelegate {
    
    func receiveData(manager : MultipeerServiceManager, user: String, string: String)
    func connectedDevicesChanged(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState)
    
}

class MultipeerServiceManager: NSObject {
    
    private let ServiceType = "emoji-amazon"
    var myPeerId: MCPeerID!
    private var serviceAdvertiser : MCNearbyServiceAdvertiser
    private let serviceBrowser : MCNearbyServiceBrowser
    
    var connectedPeers: [MCPeerID] = []
    
    var delegate : ServiceManagerDelegate?
    
    lazy var session : MCSession = {
        let session = MCSession(peer: self.myPeerId, securityIdentity: nil, encryptionPreference: .none)
        session.delegate = self
        return session
    }()
    
    init(peerID: String) {
        
        self.myPeerId = MCPeerID(displayName: peerID)
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: ServiceType)
        self.serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: ServiceType)
        
        super.init()
        
        self.serviceAdvertiser.delegate = self
        self.serviceAdvertiser.startAdvertisingPeer()
        
         self.serviceBrowser.delegate = self
         self.serviceBrowser.startBrowsingForPeers()
    }
    
    deinit {
        self.serviceAdvertiser.stopAdvertisingPeer()
        self.serviceBrowser.stopBrowsingForPeers()
    }
    
    func disconnect() {
        self.serviceAdvertiser.stopAdvertisingPeer()
        self.serviceBrowser.stopBrowsingForPeers()
        self.session.disconnect()
    }
}

extension MultipeerServiceManager: MCSessionDelegate, MCNearbyServiceBrowserDelegate, MCNearbyServiceAdvertiserDelegate  {
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        //SLog("%@", "didNotStartBrowsingForPeers: \(error)")
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        //print("found peer \(peerID)")
        browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 10)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        //NSLog("%@", "lostPeer: \(peerID)")
    }
    
    
    //MARK: MCNearbyServiceAdvertiser Delegates
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        //NSLog("%@", "didNotStartAdvertisingPeer: \(error)")
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        //NSLog("%@", "didReceiveInvitationFromPeer \(peerID)")
        invitationHandler(true, self.session)
    }
    
    
    
    //MARK: MCSession Delegates
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        
        
        let isInPeerList: Bool = self.connectedPeers.map({$0.displayName}).contains(peerID.displayName)
        
        if state == .connected && !isInPeerList {
            self.connectedPeers.append(peerID)
        } else if state == .notConnected && isInPeerList {
            if let index = self.connectedPeers.index(of: peerID) {
                self.connectedPeers.remove(at: index)
            } 
        }
        
        self.delegate?.connectedDevicesChanged(session, peer: peerID, didChange: state)
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        NSLog("%@", "didReceiveData: \(data)")
        NSLog("%@", "MCPeerID: \(peerID.displayName)")
        let str = String(data: data, encoding: .utf8)!
        self.delegate?.receiveData(manager : self, user: peerID.displayName, string: str)
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        //nothing
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        //nothing
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL, withError error: Error?) {
        //nothing
    }
    
}
