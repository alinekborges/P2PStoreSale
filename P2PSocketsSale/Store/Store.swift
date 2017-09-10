//
//  Store.swift
//  P2PSocketsSale
//
//  Created by Aline Borges on 08/09/17.
//  Copyright © 2017 Aline Borges. All rights reserved.
//

import Foundation
import Dispatch

protocol SocketDelegate {
    func didReceiveMessage(_ message: String, fromHost host: String)
}

class Store: NSObject {
    
    var manager: MultipeerServiceManager!
    var name: String
    
    var products: [Product]
    
    init(name: String, products: [Product]) {
        self.name = name
        self.products = products
        self.manager = MultipeerServiceManager(peerID: name)
        
        super.init()
        
    }
    
    func send(message: String, products: [Product]) {
        self.manager.send(colorName: message)
    }
   
}

extension Store: ServiceManagerDelegate {
    
    func connectedDevicesChanged(manager: MultipeerServiceManager, connectedDevices: [String]) {
        print("new connected device")
    }
    
    func receiveData(manager: MultipeerServiceManager, user: String, message: String) {
        print("message received: \(message)")
    }
    
}
    

