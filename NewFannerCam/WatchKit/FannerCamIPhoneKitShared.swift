//
//  FannerCamIPhoneKitShared.swift
//  NewFannerCam
//
//  Created by IE01 on 25/05/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import UIKit
import WatchConnectivity
#if !os(iOS)
import WatchKit
#endif

protocol FannerCamIPhoneKitSharedDelegate {
    func getDataFromPhone(phoneMessage:[String : Any])
}

class FannerCamIPhoneKitShared: NSObject, WCSessionDelegate {
    
    static let sharedManager = FannerCamIPhoneKitShared()
    // MARK:- Delegate
    var delegate:FannerCamIPhoneKitSharedDelegate?
    
    private override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        } else {
            print("Watch does not support WCSession")
        }
    }
    
    static func sendMessageToPhoneWithData(message:[String:Any] ,completion: @escaping () -> ()) {
        
        if WCSession.default.isReachable {
            //UserDefaults.standard.set("6", forKey: "testme")
            //UserDefaults.standard.synchronize()
            
            WCSession.default.sendMessage(message, replyHandler: { (reply) in
                print("Reply\(reply)")
                
            }, errorHandler: { (error) in
                print("SendMessageToWatchWithData\(message) \(error)")
                completion()
            })
        } else {
            
            UserDefaults.standard.set("7", forKey: "testme")
            UserDefaults.standard.synchronize()
            
            do {
                try WCSession.default.updateApplicationContext(message)
                
            } catch {
                print(error)
            }
        }
    }
    
    #if os(iOS)
    //MARK: WatchKit message send & receive Delegate
    @available(iOS 9.3, *)
    public func sessionDidBecomeInactive(_ session: WCSession) {
        print ("WatchKit error in sessionDidBecomeInactive")
    }
    @available(iOS 9.0, *)
    public func sessionDidDeactivate(_ session: WCSession) {
        print ("WatchKit error in SesssionDidDeactivate")
    }
    #endif
    
    @available(iOS 9.3, *)
    public func session(_ session: WCSession, activationDidCompleteWith    activationState: WCSessionActivationState, error: Error?) {
        print ("WatchKit in activationDidCompleteWith ")
    }
    
    @available(iOS 10.0, *)
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        
        print("session (in state: \(session.activationState.rawValue)) received application context \(applicationContext)")
        
        DispatchQueue.main.async() { [weak self] in
            print(applicationContext)
            self?.delegate?.getDataFromPhone(phoneMessage: applicationContext)
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        
        print(message)
        // foreground
        self.delegate?.getDataFromPhone(phoneMessage: message)
    }
    
}
