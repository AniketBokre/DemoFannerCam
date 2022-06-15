//
//  Utiles.swift
//  NewFannerCam
//
//  Created by Jin on 1/21/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import Foundation
import UIKit
import JGProgressHUD

class Utiles {
    
    class func screenWidth() -> CGFloat {
        return UIScreen.main.bounds.width
    }
    
    class func screenHeight() -> CGFloat {
        return UIScreen.main.bounds.height
    }
    
    class func videoCellHeight() -> CGFloat {
        return (screenWidth()/16) * 9 + 34
    }
    
    //HUD functions
    static var hud : JGProgressHUD!
    
    class func HUDDisplayed() -> Bool {
        if hud == nil {
            return false
        } else {
            return hud.isVisible
        }
    }
    
    class func setHUD(_ visible: Bool, _ view: UIView = DataManager.shared.tabberView, _ style: JGProgressHUDStyle? = nil, _ message: String? = nil) { // _ target: UIView? = nil,
        DispatchQueue.main.async {
            if visible {
                guard let type = style, let content = message else {
                    return
                }
                hud = JGProgressHUD(style: type)
                hud.indicatorView = JGProgressHUDIndeterminateIndicatorView()
                hud.textLabel.text = content
                hud.show(in: view)
            } else {
                if hud != nil {
                    hud.dismiss(animated: true)
                }
            }
        }
    }
    
    class func setHUD(_ message: String) {
        DispatchQueue.main.async {
            guard hud != nil, hud.isVisible else {
                return
            }
            hud.textLabel.text = message
        }
    }
    
    // Date    
    class func dateAfter(_ date: Date, after: (hour: NSInteger, minute: NSInteger, second: NSInteger)) -> Date {
        let calendar = Calendar.current
        if let date = (calendar as NSCalendar).date(byAdding: .hour, value: after.hour, to: date, options: []) {
            if let date = (calendar as NSCalendar).date(byAdding: .minute, value: after.minute, to: date, options: []) {
                if let date = (calendar as NSCalendar).date(byAdding: .second, value: after.second, to: date, options: []) {
                    return date
                }
            }
        }
        return date
    }
    
    // Device utile functions
    class func getUniqueDeviceID() -> String {
        var uuidString = String()
        if let idForVendor = UIDevice.current.identifierForVendor {
            print(idForVendor.uuidString)
            uuidString = idForVendor.uuidString
        }
        return uuidString
    }
    
    class func getDeviceName() -> String {
        return UIDevice.current.name
    }
    
    class func getDeviceModel() -> String {
        return UIDevice.current.model
    }
    
    class func getDeviceOS() -> String {
        return "\(UIDevice.current.systemVersion) \(UIDevice.current.systemName)"
    }
    
    class func battery() -> Float {
        let myDevice = UIDevice.current
        myDevice.isBatteryMonitoringEnabled = true
        
        let batLeft = myDevice.batteryLevel * 100
        
        return batLeft
    }
    
    class func batteryStatus() -> Int {
        let myDevice = UIDevice.current
        myDevice.isBatteryMonitoringEnabled = true
        
        let state = myDevice.batteryState
        //        NSLog(@"battery status: %d",state); // 0 unknown, 1 unplegged, 2 charging, 3 full
        return state.rawValue
    }
    
    class func getFreeDiskspace() -> Int64? {
        let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last!
        guard
            let systemAttributes = try? FileManager.default.attributesOfFileSystem(forPath: documentDirectory),
            let freeSize = systemAttributes[.systemFreeSize] as? NSNumber
            else {
                // something failed
                return nil
        }
        return ((freeSize.int64Value/1024)/1024)/1024
    }
    
}
