//
//  SplashController.swift
//  NewFannerCamWatch Extension
//
//  Created by Jaspal Singh on 21/05/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

#if !os(iOS)
import WatchKit
#endif
import Foundation
import WatchConnectivity

class SplashController: WKInterfaceController {

    @IBOutlet var labelSplash: WKInterfaceLabel!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        globalTiming = "00:00:00"
        globalTitleTop = "___ - ___"
        
         goToNextController()
    }
    
    func goToNextController() {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            //    Code to push/present new view controller
            
            if let isFirstTimeConnect = UserDefaults.standard.object(forKey: "FirstTime") as? Bool, isFirstTimeConnect == true {
                WKInterfaceController.reloadRootControllers(withNamesAndContexts: [(name: "RecordingController", context: [:] as AnyObject), (name:"GenericMarkerController", context: [:] as AnyObject), (name:"CollectiveMarkerController", context: [:] as AnyObject)])
                //WKInterfaceController.reloadRootControllers(withNames: ["RecordingController", "GenericMarkerController", "CollectiveMarkerController"], contexts: [])
            } else {
            self.getPhoneName()
            }
        }
    }
    
    func goToPageScreen() {
        WKInterfaceController.reloadRootControllers(withNamesAndContexts: [(name: "RecordingController", context: [:] as AnyObject), (name:"GenericMarkerController", context: [:] as AnyObject), (name:"CollectiveMarkerController", context: [:] as AnyObject)])

       //  WKInterfaceController.reloadRootControllers(withNames: ["RecordingController", "GenericMarkerController", "CollectiveMarkerController"], contexts: [])
    }
    
    func goToConnectController() {
        UserDefaults.standard.set(true, forKey: "FirstTime")
        UserDefaults.standard.synchronize()
        WKInterfaceController.reloadRootControllers(withNamesAndContexts: [(name: "ConnectController", context: [:] as AnyObject)])
       /* WKInterfaceController.reloadRootControllers(
            withNames: ["ConnectController"], contexts: []
        ) */
    }
    
    override func willActivate() {
        super.willActivate()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
            print("InterfaceController: Session Activated")
        }
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    //- Start
    func getPhoneName() {
        // Check Session is Reachable..
        if WCSession.default.isReachable {
            // Create dictionary to pass to iPhone
            let replyMessageDict : [String:Any] = ["Controller":"SplashController"]
            if WCSession.default.activationState == .activated {
                // When will be stopped/started from iPhone, delegates will get response
                WCSession.default.sendMessage(replyMessageDict, replyHandler:{ reply in
                    print("Getting reply from iOS app : \n \(reply as [String: Any])")
                    DispatchQueue.main.async() { [weak self] in
                        //  self?.handleiPhoneResponse(message: reply as [String: Any])
                        self?.updateUIIfNeeded(message: reply)
                    }
                }, errorHandler: { (error) in
                    print("Got an error sending to the phone: \(error)")
                    self.goToPageScreen()
                    // Show alert
                    let actionOK = WKAlertAction(title: "OK", style: .default, handler:{})
                    self.presentAlert(withTitle: "Error!", message: error.localizedDescription, preferredStyle: .actionSheet, actions: [actionOK])
                    // Hide indicator
                })
            }
            else
            {
                // Show alert
                self.goToPageScreen()
                let actionOK = WKAlertAction(title: "OK", style: .default, handler:{})
                self.presentAlert(withTitle: "Error!", message:"Session is not active" , preferredStyle: .actionSheet, actions: [actionOK])
            }
        }
        else
        {
            // Show alert
            self.goToPageScreen()
            let actionOK = WKAlertAction(title: "OK", style: .default, handler:{})
            self.presentAlert(withTitle: "Error!", message:"Your iPhone is unreachable." , preferredStyle: .actionSheet, actions: [actionOK])
        }
    }
    
    //- End
    
    func updateUIIfNeeded(message:[String:Any]) {
        if let _ =  message["Controller"], let deviceName = message["deviceName"] as? String {
            UserDefaults.standard.set(deviceName, forKey: "DeviceName")
            UserDefaults.standard.synchronize()
            self.goToConnectController()
        }
    }
}

extension SplashController : WCSessionDelegate {
    
    @available(watchOSApplicationExtension 2.2, *)
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("1. InterfaceController: ", "activationDidCompleteWith activationState") // first
        
        if activationState == WCSessionActivationState.activated {
            print("Activated")
        }
        
        if activationState == WCSessionActivationState.inactive {
            print("Inactive")
        }
        
        if activationState == WCSessionActivationState.notActivated {
            print("NotActivated")
        }
    }
    
    /** ------------------------- Interactive Messaging ------------------------- */
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        
        print("session (in state: \(session.activationState.rawValue)) received application context \(applicationContext)")
        
        DispatchQueue.main.async() {
            print(applicationContext)
        }
        // NOTE: The guard is here as `watchDirectoryURL` is only available on iOS and this class is used on both platforms.
        #if os(iOS)
        print("session watch directory URL: \(session.watchDirectoryURL?.absoluteString)")
        #endif
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        print("2. InterfaceController: ", "sessionReachabilityDidChange") // second
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        print("Getting reply from iOS app : \n \(message)")
        
        DispatchQueue.main.async() { [weak self] in
            self?.updateUIIfNeeded(message: message)
            replyHandler([:])
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("3. InterfaceController: ", "didReceiveMessage",message)
        
        DispatchQueue.main.async() { [weak self] in
            self?.updateUIIfNeeded(message: message)
        }
    }
    
    func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        print("5. InterfaceController: ", "didReceiveMessageData")
    }
}
