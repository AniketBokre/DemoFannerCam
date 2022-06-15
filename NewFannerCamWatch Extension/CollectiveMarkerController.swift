//
//  CollectiveMarkerController.swift
//  NewFannerCamWatch Extension
//
//  Created by Jaspal Singh on 22/05/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

#if !os(iOS)
import WatchKit
#endif
import Foundation
import WatchConnectivity

class CollectiveMarkerController: WKInterfaceController{

    @IBOutlet var labelTop: WKInterfaceLabel!
    
    @IBOutlet var buttonTagList: WKInterfaceButton!
    
    @IBOutlet var labelTiming: WKInterfaceLabel!
  
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
            print("InterfaceController: Session Activated")
        }
        labelTiming.setText(globalTiming)
        labelTop.setText(globalTitleTop)
        checkRecordingStatus()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
 
    
    //MARK : Send Message to iPhone
    
    func sendMessageToPhone(selectedTag: Int, name : String, controller:String="CollectiveMarkerController") {
        // Check Session is Reachable..
        print("Call here by picker")
        if WCSession.default.isReachable {
            // Create dictionary to pass to iPhone
            
            let replyMessageDict : [String:Any] = ["SelectedTag":selectedTag, "Name":name, "Controller":controller]
            if WCSession.default.activationState == .activated {
                // When will be stopped/started from iPhone, delegates will get response
                WCSession.default.sendMessage(replyMessageDict, replyHandler:{ reply in
                    print("Getting Here : \n \(reply as [String: Any])")
                    DispatchQueue.main.async() {
                        //  self?.handleiPhoneResponse(message: reply as [String: Any])
                    }
                }, errorHandler: { (error) in
                    print("Got an error sending to the phone: \(error)")
                    // Show alert
                    _ = WKAlertAction(title: "OK", style: .default, handler:{})
                   // self.presentAlert(withTitle: "Error!", message: error.localizedDescription, preferredStyle: .actionSheet, actions: [actionOK])
                    // Hide indicator
                })
                //  self.dismiss()
            }
            else
            {
                // Show alert
                let actionOK = WKAlertAction(title: "OK", style: .default, handler:{})
                self.presentAlert(withTitle: "Error!", message:"Session is not active" , preferredStyle: .actionSheet, actions: [actionOK])
            }
        }
        else
        {
            // Show alert
            let actionOK = WKAlertAction(title: "OK", style: .default, handler:{})
            self.presentAlert(withTitle: "Error!", message:"Your iPhone is unreachable." , preferredStyle: .actionSheet, actions: [actionOK])
        }
    }
    
    //MARK : Send Message to iPhone
    
    func checkRecordingStatus() {
        
        // Check Session is Reachable..
        if WCSession.default.isReachable {
            // Create dictionary to pass to iPhone
            let replyMessageDict : [String:Any] = ["isStart":"check", "Controller":"GenericMarkerControllerCheck"]
            
            if WCSession.default.activationState == .activated {
                // When will be stopped/started from iPhone, delegates will get response
                WCSession.default.sendMessage(replyMessageDict, replyHandler:{ reply in
                    print("Getting reply from iOS app : \n \(reply as [String: Any])")
                    DispatchQueue.main.async() {
                        //  self?.handleiPhoneResponse(message: reply as [String: Any])
                    }
                }, errorHandler: { (error) in
                    print("Got an error sending to the phone: \(error)")
                    
                    // Show alert
                    _ = WKAlertAction(title: "OK", style: .default, handler:{})
                   // self.presentAlert(withTitle: "Error!", message: error.localizedDescription, preferredStyle: .actionSheet, actions: [actionOK])
                    // Hide indicator
                })
            }
            else
            {
                // Show alert
                let actionOK = WKAlertAction(title: "OK", style: .default, handler:{})
                self.presentAlert(withTitle: "Error!", message:"Session is not active" , preferredStyle: .actionSheet, actions: [actionOK])
            }
        }
        else
        {
            // Show alert
            let actionOK = WKAlertAction(title: "OK", style: .default, handler:{})
            self.presentAlert(withTitle: "Error!", message:"Your iPhone is unreachable." , preferredStyle: .actionSheet, actions: [actionOK])
        }
    }
    
    @IBAction func buttonTagListAction() {
        //WKInterfaceDevice().play(.click)
        WKInterfaceDevice().play(.stop)
        if (globalTiming == "00:00:00") {
            let actionOK = WKAlertAction(title: "OK", style: .default, handler:{})
            self.presentAlert(withTitle: "Error!", message:"Start recording first" , preferredStyle: .actionSheet, actions: [actionOK])
        } else {
            self.sendMessageToPhone(selectedTag: 0, name: "Collective")
            self.presentController(withName: "TagController", context:["TagController"])
        }
    }
}

extension CollectiveMarkerController : WCSessionDelegate {
    
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
        if message.count != 1 {
            if message.count == 2 {
                buttonTagList.setEnabled(false)
                buttonTagList.setAlpha(0.2)
            } else {
                labelTiming.setText(message["Time"] as? String)
                labelTop.setText(message["Title"] as? String)
                
                globalTiming = message["Time"] as! String
                globalTitleTop = message["Title"] as! String
            }
            DispatchQueue.main.async() {
                replyHandler([:])
            }
        } else {
            if(message.keys.first == "CollectiveData"){
                return
            }
            if (message["isStart"] as! Bool) == true {
                buttonTagList.setAlpha(1.0)
                buttonTagList.setEnabled(true)
            } else {
                buttonTagList.setAlpha(0.2)
                buttonTagList.setEnabled(false)
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("3. InterfaceController: ", "didReceiveMessage",message)
        
        DispatchQueue.main.async() {
            //            self?.handleiPhoneResponse(message: message)
        }
    }
    
    func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        print("5. InterfaceController: ", "didReceiveMessageData")
    }
}
