//
//  Notification+NSObject.swift
//  HitGo
//
//  Created by Aline Borges on 29/05/17.
//  Copyright © 2017 plugapps. All rights reserved.
//

import Foundation
import ObjectiveC

private var queueAssociationKey: UInt8 = 0

public extension NSObject {
    
    
    //MARK: - Notifications
    
    public func registerNotification(notificationName: String, withSelector selector: Selector) {
        NotificationUtils.registerNotification(notificationName: notificationName, withSelector: selector, fromObserver: self)
    }
    
    public func unregisterNotification(notificationName: String) {
        NotificationUtils.unregisterNotification(notificationName: notificationName, fromObserver: self)
    }
    
    public func unregisterAllNotifications() {
        NotificationUtils.unregisterAllNotificationsFromObserver(observer: self)
    }
    
    public func postNotification(notificationName: String, withObject object: AnyObject? = nil, userInfo: [AnyHashable : Any]? = nil) {
        NotificationUtils.postNotification(notificationName: notificationName, withObject: object, userInfo: userInfo)
    }
    
    public func postNotification(notification: Foundation.Notification) {
        NotificationUtils.postNotification(notification: notification)
    }
}

open class NotificationUtils {
    
    //MARK: - Register
    
    static open func registerNotification(notificationName: String, withSelector selector: Selector, fromObserver observer: AnyObject) {
        NotificationCenter.default.addObserver(observer, selector: selector, name: NSNotification.Name(rawValue: notificationName), object: nil)
    }
    
    //MARK: - Unregister
    
    static open func unregisterNotification(notificationName: String, fromObserver observer: AnyObject) {
        NotificationCenter.default.removeObserver(observer, name: NSNotification.Name(rawValue: notificationName), object: nil)
    }
    
    static open func unregisterAllNotificationsFromObserver(observer: AnyObject) {
        NotificationCenter.default.removeObserver(observer)
    }
    
    //MARK: - Post
    
    static open func postNotification(notificationName: String, withObject object: AnyObject? = nil, userInfo: [AnyHashable : Any]? = nil) {
        NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: notificationName), object: object, userInfo: userInfo)
    }
    
    static open func postNotification(notification: Foundation.Notification, withObject object: AnyObject? = nil, userInfo: [AnyHashable : Any]? = nil) {
        //NotificationCenter.default.post(name: notification.name, object: object)
        NotificationCenter.default.post(name: notification.name, object: object, userInfo: userInfo)
    }
}
