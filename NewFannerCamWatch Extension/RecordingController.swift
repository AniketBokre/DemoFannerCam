//
//  RecordingController.swift
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

var globalTiming : String = "00:00:00"
var globalTitleTop : String = "___ - ___"

class RecordingController: WKInterfaceController {
    
    @IBOutlet var labelTitleTop: WKInterfaceLabel!
    @IBOutlet var labelTiming: WKInterfaceLabel!
    @IBOutlet var buttonPlayPause: WKInterfaceButton!
    
    var scheduledStartTime   : Date?
    private var liveTimer    : Timer!
    private var liveTime     = 0
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        // Configure interface objects here.
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        labelTiming.setText(globalTiming)
        labelTitleTop.setText(globalTitleTop)
        managedSessionDelegate()
    }
    
    func managedSessionDelegate() {
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
            print("InterfaceController: Session Activated")
        }
    }

    override func didAppear() {
        managedSessionDelegate()
        self.checkRecordingStatus()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    @IBAction func playButtonAction() {
        managedSessionDelegate()
        self.sendMessageToPhone(isStart:false)
    }
    
    //MARK : Send Message to iPhone
    func sendMessageToPhone(isStart:Bool) {
      
        // Check Session is Reachable..
        if WCSession.default.isReachable {
            // Create dictionary to pass to iPhone
            let replyMessageDict : [String:Any] = ["isStart":isStart, "Controller":"RecordingController"]
            
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
                  //  self.presentAlert(withTitle: "Error!", message: error.localizedDescription, preferredStyle: .actionSheet, actions: [actionOK])
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
    
    //MARK : Send Message to iPhone
    
    func checkRecordingStatus() {
        
        // Check Session is Reachable..
        if WCSession.default.isReachable {
            // Create dictionary to pass to iPhone
            let replyMessageDict : [String:Any] = ["isStart":"check", "Controller":"RecordingControllerCheck"]
            
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
                  //  self.presentAlert(withTitle: "Error!", message: error.localizedDescription, preferredStyle: .actionSheet, actions: [actionOK])
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
}

extension RecordingController : WCSessionDelegate {
    
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
                buttonPlayPause.setEnabled(false)
                buttonPlayPause.setAlpha(0.2)
            } else {
                buttonPlayPause.setEnabled(true)
                buttonPlayPause.setAlpha(1.0)
                labelTiming.setText(message["Time"] as? String)
                labelTitleTop.setText(message["Title"] as? String)
                scheduledStartTime = message["StartDate"] as? Date
                globalTiming = message["Time"] as! String
                globalTitleTop = message["Title"] as! String
                if message.count == 4 {
                    self.setToggleBtnImage(isStarted: message["isStart"] as! Bool)
                }
            }
            DispatchQueue.main.async() {
                replyHandler([:])
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
    
    //MARK:- Update Image Toggle
    
    func setToggleBtnImage(isStarted: Bool) {
        if isStarted == true {
            WKInterfaceDevice().play(.start)
        } else {
            WKInterfaceDevice().play(.start)
           //WKInterfaceDevice().play(.stop)
        }
        let imageName = isStarted ?   "pauseIcon":"recordIcon"
        buttonPlayPause.setBackgroundImageNamed(imageName)
    }
    
   /* func startTimer() {
        if liveTimer != nil {
            liveTimer.invalidate()
            liveTimer = nil
            liveTime = 0
            labelTiming.setText("00:00:00")
        }
    }
    
    @objc func liveTimerAction() {
        liveTime += 1
        let timeNow = String( format :"%02d:%02d:%02d", liveTime/3600, (liveTime%3600)/60, liveTime%60)
        labelTiming.setText(timeNow)
        print("Recording : - By liveTimerAction")
    }*/
}
