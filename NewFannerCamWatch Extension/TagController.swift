//
//  TagController.swift
//  NewFannerCamWatch Extension
//
//  Created by IE01 on 27/05/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

#if !os(iOS)
import WatchKit
#endif
import Foundation
import WatchConnectivity

class TagController: WKInterfaceController {

    @IBOutlet var tagPicker: WKInterfacePicker!
  
    var isFirst = Bool()
    var timer: Timer?
    var selectedIndex:Int = 0
    
//    var tagListIndividual : [String] = ["GOAL","TIRO","FUORIGIOCO","PARATA","FALLO","CANESTRO","CANESTRO DA 3","TIRO LIBERO","SCHIACCIATA"]
    var tagListCollective : [String] = ["GOAL","TIRO","FUORIGIOCO","PARATA","FALLO","CANESTRO","CANESTRO DA 3","TIRO LIBERO","SCHIACCIATA"]
//    var tagListCollective :  [(String, String)] = [("9", "PALLA PERSA"),("10", "PALLE RECUPERATA"),("11", "FUORIGIOCO"),("12", "VAR"),("13", "INGRESSO"),("14", "FINE GARA")]
    
    var tagListGeneric : [String] = ["Generic"]
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
    }
    
    func sessionActivate() {
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
            print("InterfaceController: Session Activated")
        }
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        self.setTitle("")
        sessionActivate()
//        let pickerItems: [WKPickerItem] = tagListCollective.map {
//            let pickerItem = WKPickerItem()
//            pickerItem.title = $0
//            pickerItem.caption = $0
//            return pickerItem
//        }
//        self.isFirst = true
//        tagPicker.setItems(pickerItems)
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    @IBAction func tagPickerAction(_ value: Int) {
        startTimer(selectedTag: value, name: "ABC")
        selectedIndex = value
    }

    func startTimer(selectedTag: Int, name : String) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 1.0,
                                     target: self,
                                     selector: #selector(eventWith(timer:)),
                                     userInfo: [ "SelectedTag" : selectedTag, "Name" : name],
                                     repeats: false)
    }
    
    override func pickerDidSettle(_ picker: WKInterfacePicker) {
        self.sendMessageToPhone(selectedTag: selectedIndex, name: "Collective")
        self.dismiss()
    }
    
    @objc func eventWith(timer: Timer!) {
        WKInterfaceDevice().play(.start)
        if isFirst == false {
          self.sendSecondMessageToPhone(selectedTag: 0, name: "Collective")
        }        
        let info : [String : Any] = timer.userInfo as Any as! [String : Any]
        self.sendMessageToPhone(selectedTag: info["SelectedTag"] as! Int, name: info["Name"] as! String)
        print(info)
    }
    
    //MARK : Send Message to iPhone
    
    func sendMessageToPhone(selectedTag: Int, name : String) {
        // Check Session is Reachable..
        print("Call here by picker")
        if WCSession.default.isReachable {
            // Create dictionary to pass to iPhone
          
            let replyMessageDict : [String:Any] = ["SelectedTag":selectedTag, "Name":name, "Controller":"TagController"]
            if WCSession.default.activationState == .activated {
                // When will be stopped/started from iPhone, delegates will get response
                self.isFirst = false
                WCSession.default.sendMessage(replyMessageDict, replyHandler:{ reply in
                    print("Getting Here : \n \(reply as [String: Any])")
                    DispatchQueue.main.async() {
                        //  self?.handleiPhoneResponse(message: reply as [String: Any])
                    }
                }, errorHandler: { (error) in
                    print("Got an error sending to the phone: \(error)")
                    
                    // Show alert
                    _ = WKAlertAction(title: "OK", style: .default, handler:{})
               //   self.presentAlert(withTitle: "Error!", message: error.localizedDescription, preferredStyle: .actionSheet, actions: [actionOK])
                    // Hide indicator
                })
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    //self.dismiss()
                }
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
    
    
    func sendSecondMessageToPhone(selectedTag: Int, name : String) {
        // Check Session is Reachable..
        print("Call here by picker")
        if WCSession.default.isReachable {
            // Create dictionary to pass to iPhone
            
            let replyMessageDict : [String:Any] = ["SelectedTag":selectedTag, "Name":name, "Controller":"CollectiveMarkerController"]
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
                    //self.presentAlert(withTitle: "Error!", message: error.localizedDescription, preferredStyle: .actionSheet, actions: [actionOK])
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
}

extension TagController : WCSessionDelegate {
    
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

        if(message.count == 1){
            if(message.keys.first == "CollectiveData"){
                let collectiveString = message["CollectiveData"] as? String
                let markerData = collectiveString!.data(using: .utf8)!
                let markers = try! JSONDecoder().decode([Marker].self, from: markerData)
                let pickerItems: [WKPickerItem] = markers.map({ (marker) -> WKPickerItem in
                                                           let pickerItem = WKPickerItem()
                                                           pickerItem.title = marker.name
                                                           pickerItem.caption = marker.id
                                                           return pickerItem
                                                       })
                 DispatchQueue.main.async() {
                    self.tagPicker.setItems(pickerItems)
                    self.isFirst = true
                }
            }
        }
        
        DispatchQueue.main.async() {
            replyHandler([:])
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("3. InterfaceController: ", "didReceiveMessage",message)
        
        DispatchQueue.main.async() {
            //           self?.handleiPhoneResponse(message: message)
        }
    }
    
    func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        print("5. InterfaceController: ", "didReceiveMessageData")
    }
}
