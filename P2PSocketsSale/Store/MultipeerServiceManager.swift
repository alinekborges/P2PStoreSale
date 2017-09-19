//
//  MultipeerServiceManager.swift
//  P2PSocketsSale
//
//  Created by Aline Borges on 09/09/17.
//  Copyright © 2017 Aline Borges. All rights reserved.
//

import Foundation
import MultipeerConnectivity
import CocoaAsyncSocket


protocol ServiceManagerDelegate {
    
    func receiveMulticastData(manager : MultipeerServiceManager, string: String?, data: Data)
    func receivedUnicastData(manager: MultipeerServiceManager, string: String?, data: Data)
    
}

class MultipeerServiceManager: NSObject {
    
    static let multicastPort = UInt16(55555)
    static let multicastGroup = "239.239.0.1"
    
    fileprivate var myPeerID: String?
    
    fileprivate var multicastSocket: GCDAsyncUdpSocket?
    fileprivate var listenSocket: GCDAsyncSocket?
    fileprivate var connectSocket: GCDAsyncSocket?
    
    fileprivate var multicastQueue: DispatchQueue!
    fileprivate var listenSocketQueue: DispatchQueue!
    fileprivate var connectSocketQueue: DispatchQueue!
    
    fileprivate var multicastDelegateQueue: DispatchQueue!
    fileprivate var listenSocketDelegateQueue: DispatchQueue!
    fileprivate var connectSocketDelegateQueue: DispatchQueue!
    
    var connectedSockets: [GCDAsyncSocket] = []
    
    var delegate : ServiceManagerDelegate?
    
    var didSetupListenSocket: ((_ ip: String, _ port: UInt16) -> ())?
    
    var myIpAddress: String
    
    init(peerID: String,  didSetupListenSocket: @escaping ((_ ip: String, _ port: UInt16) -> ())) {
        self.didSetupListenSocket = didSetupListenSocket
        self.myPeerID = peerID
        myIpAddress = Network.getIFAddresses()!.first!
        super.init()
        initQueue(peerID: peerID)
        startMulticastSocket()
        startListenSocket()
        
    }
    
    func startMulticastSocket() {
        
        self.multicastSocket = GCDAsyncUdpSocket(delegate: self, delegateQueue: self.multicastDelegateQueue, socketQueue: self.multicastQueue)
        
        guard let multicastSocket = self.multicastSocket else {
            return
        }
        
        do {
            try multicastSocket.enableReusePort(true)
            try multicastSocket.bind(toPort: MultipeerServiceManager.multicastPort)
            try multicastSocket.enableBroadcast(true)
            try multicastSocket.joinMulticastGroup(MultipeerServiceManager.multicastGroup)
            try multicastSocket.beginReceiving()
            
            print("Started multicast socket for \(myPeerID) with success")
        } catch let error {
            print("error creating multicast socket: \(error.localizedDescription)")
        }
        
    }
    
    func startListenSocket() {
        self.listenSocket = GCDAsyncSocket(delegate: self, delegateQueue: listenSocketDelegateQueue, socketQueue: listenSocketQueue)
        
        guard let listenSocket = listenSocket else {
            return
        }
        
        do {
            try listenSocket.accept(onPort: 0)
            
            self.didSetupListenSocket?(self.myIpAddress, listenSocket.localPort)
        } catch let error {
            print("error creating listening socket: \(error.localizedDescription)")
        }
    }
    
    func initQueue(peerID: String) {
        multicastQueue = DispatchQueue(label: "p2pstore.multicast.\(peerID)")
        listenSocketQueue = DispatchQueue(label: "p2pstore.listen.\(peerID)")
        connectSocketQueue = DispatchQueue(label: "p2pstore.connect.\(peerID)")
        
        multicastDelegateQueue = DispatchQueue(label: "p2pstore.multicast.delegate.\(peerID)")
        listenSocketDelegateQueue = DispatchQueue(label: "p2pstore.listen.delegate.\(peerID)")
        connectSocketDelegateQueue = DispatchQueue(label: "p2pstore.connect.delegate.\(peerID)")
    }
    
    deinit {
        self.disconnect()
    }
    
    func disconnect() {
        self.multicastSocket?.close()
        self.listenSocket?.disconnect()
        self.connectSocket?.disconnect()
    }

}

extension MultipeerServiceManager {
    func sendBroadcast(data: Data) {
        self.multicastSocket?.send(data, toHost: MultipeerServiceManager.multicastGroup, port: MultipeerServiceManager.multicastPort, withTimeout: -1, tag: 0)
    }
    
    func send(data: Data, toHost host: String, onPort port: UInt16) {
        self.connectSocket = GCDAsyncSocket(delegate: self, delegateQueue: self.connectSocketDelegateQueue, socketQueue: self.connectSocketQueue)
        do {
            try connectSocket?.connect(toHost: host, onPort: port)
            connectSocket?.write(data, withTimeout: 5, tag: 0)
        } catch let error {
            print("error creating unicast socket: \(error.localizedDescription)")
        }
        
    }
}

extension MultipeerServiceManager: GCDAsyncUdpSocketDelegate {
    func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
        let string = String(data: data, encoding: .utf8)
        self.delegate?.receiveMulticastData(manager: self, string: string, data: data)
    }
}

extension MultipeerServiceManager : GCDAsyncSocketDelegate {
    
    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        let string = String(data: data, encoding: .utf8)
        self.delegate?.receivedUnicastData(manager: self, string: string, data: data)
    }
    
    func socket(_ sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {
        print("accepting new socket")
        self.connectedSockets.append(newSocket)
        newSocket.readData(withTimeout: 5, tag: 0)
    }
    
}
