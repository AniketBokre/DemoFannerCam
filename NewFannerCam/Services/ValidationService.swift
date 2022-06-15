//
//  ValidationService.swift
//  NewFannerCam
//
//  Created by Jin on 1/18/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import Foundation

class ValidationService {
    
    public static func validateAbbreviation(_ text: String) -> Bool {
        guard text.count > 3 else { return true}
        return false
    }
    
    public static func validateEmptyStrs(_ texts: [String]) -> Bool {
        return texts.reduce(true) { $0 && $1.count > 0 }
    }
    
    public static func validateMarkerDuration(_ text: String) -> Bool {
        if let val = Float64(text), val <= 60 {
            return true
        } else {
            return false
        }
    }
    
    public static func validateNumSize(compareVal: String, vVal: Int) -> Bool {
        if let val = Int(compareVal) {
            return val <= vVal
        } else {
            return false
        }
    }
    
    public static func validateStringLength(str: String, lengCount: Int) -> Bool {
        return str.count <= lengCount
    }
    
    public static func validateBattery() -> Bool {
        let batteryLevel = Utiles.battery()
        let batteryStatus = Utiles.batteryStatus()
        if batteryLevel <= 7, batteryStatus != 2 {
            return false
        } else {
            return true
        }
    }
    
}
