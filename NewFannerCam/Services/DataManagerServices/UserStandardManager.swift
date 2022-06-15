//
//  UserStandardManager.swift
//  NewFannerCam
//
//  Created by Jin on 1/16/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import Foundation

enum LocalDataType: String {
    case matches                = "Fan_Matches_Local_Key"
    case overlays               = "Fan_overlays_Local_Key"
    case scoreboardHidden       = "Fan_scoreboard_hidden"
    case videos                 = "Fan_Videos"
    case settingMarkers         = "Fan_Setting_Markers_Local_Key"
    case imgArchive             = "Fan_Setting_Medias"
    case imgArchive2             = "Fan_Setting_Medias2"
    case templates              = "Fan_Setting_templates"
    case soundtracks            = "Fan_Setting_soundtracks"
    
    case purchasedMatchCount    = "Fan_Purchased_Matches_Count"
    case productGroupData       = "Fan_Product_Group_Data"
}

final class UserStandardManager {
    
    let defaults = UserDefaults.standard
    
//MARK: - Main functions
    func saveObject(_ data: Any, _ type: LocalDataType) {
        
        do {
            var jsonData = Data()
            
            switch type {
            case .matches:
                let matchesArr = data as! [Match]
                jsonData = try JSONEncoder().encode(matchesArr)
                break
            case .overlays:
                let overlays = data as! [String: ImgArchive]
                jsonData = try JSONEncoder().encode(overlays)
                break
            case .scoreboardHidden:
                let scoreboardHidden = data as! Bool
                defaults.set(scoreboardHidden, forKey: type.rawValue)
                return
            case .videos:
                let videosArr = data as! [Video]
                jsonData = try JSONEncoder().encode(videosArr)
                break
            case .settingMarkers:
                let settingsMarkers = data as! [String: [Marker]]
                jsonData = try JSONEncoder().encode(settingsMarkers)
                break
            case .imgArchive:
                let imgs = data as! [ImgArchive]
                jsonData = try JSONEncoder().encode(imgs)
                break
            case .imgArchive2:
                let imgs = data as! [ImgArchive]
                jsonData = try JSONEncoder().encode(imgs)
                break
            case .templates:
                let templates = data as! [String: [Template]]
                jsonData = try JSONEncoder().encode(templates)
                break
            case .soundtracks:
                let soundtracks = data as! [String: [Soundtrack]]
                jsonData = try JSONEncoder().encode(soundtracks)
                break
            case .purchasedMatchCount:
                let matchCount = data as! Int
                defaults.set(matchCount, forKey: type.rawValue)
                return
            case .productGroupData:
                jsonData = data as! Data
                break
            }
            
            defaults.set(jsonData, forKey: type.rawValue)
        } catch {
            print(error)
        }
    }
    
    func deleteObject(_ type: LocalDataType) {
        defaults.removeObject(forKey: type.rawValue)
    }
    
    func loadObject(type: LocalDataType) -> Any? {
        if type == .scoreboardHidden {
            return defaults.bool(forKey: type.rawValue)
        } else if type == .purchasedMatchCount {
            return defaults.integer(forKey: type.rawValue)
        } else {
            return defaults.object(forKey: type.rawValue)
        }
    }
    
}
