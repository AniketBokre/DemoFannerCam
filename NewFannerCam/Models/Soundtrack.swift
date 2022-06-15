//
//  Soundtrack.swift
//  NewFannerCam
//
//  Created by Cat on 2/28/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import Foundation

struct Soundtrack: Codable {
    
    var id                              : String!
    var name                            : String!
    var dirName                         : String!
    var des                             : String!
    var order                           : Int!
    var iapGroupName                    : String!
    var audioUrl                        : String!
    
    var mediaType                       = MediaType.sounds
    var purchasedType                   = Purchased.free
    var isSelected                      = false
    var isDownloaded                    = false
    
    enum SoundtrackKeys : String, CodingKey {
        case id                         = "Soundtrack_id"
        case name                       = "Soundtrack_name"
        case dirName                    = "Soundtrack_dirName"
        case des                        = "Soundtrack_des"
        case order                      = "Soundtrack_order"
        case iapGroupName               = "Soundtrac_iapGroupName"
        case audioUrl                   = "Soundtrack_audioUrl.m4v"
        
        case mediaType                  = "Soundtrack_mediaType"
        case purchasedType              = "Soundtrack_purchasedType"
        case isSelected                 = "Soundtrack_isSelected"
        case isDownloaded               = "Soundtrack_isDownloaded"
    }
    
    //MARK: - Main functions
    func templateDirPath() -> URL {
        return dirManager.generateSettingMeida(dirName, mediaType)
    }
    
    func filePath() -> URL {
        return URL(fileURLWithPath: templateDirPath().path.combineDirPath(SoundtrackKeys.audioUrl.rawValue))
    }
    
    mutating func removeFiles() {
        if isDownloaded {
            dirManager.deleteItems(at: filePath())
            isDownloaded = false
            isSelected = false
        }
    }
    
    mutating func saveFiles(_ completion: @escaping(Bool, String) -> Void) {
        if !isDownloaded {
//            Downloader.audioDownload(from: audioUrl, to: filePath())
            if(audioUrl != nil){
                Downloader.mediaDownload(from: audioUrl, to: filePath()) { (success, resultDes) in
                    completion(success, resultDes)
                }
            }
            isDownloaded = true
        } else {
            completion(true, "Already downloaded item!")
        }
    }
    
    mutating func set(with other: Soundtrack) {
        mediaType = other.mediaType
        purchasedType = other.purchasedType
        isSelected = other.isSelected
        isDownloaded = other.isDownloaded
        dirName = other.dirName
    }
    
    //MARK: - Mutating function
    mutating func set(_ purchasedType: Purchased) {
        self.purchasedType = purchasedType
    }
    
    mutating func set(_ selected: Bool) {
        isSelected = selected
    }
    
    mutating func set(isDownloaded: Bool) {
        self.isDownloaded = isDownloaded
    }
    
    //MARK: - Init functions
    init(){ }
    
    init(_ jsonData: CustomJSON?) { 
        id                              = jsonData?["id"] as? String
        name                            = jsonData?["title"] as? String
        dirName                         = "\(name ?? String())\(Date().uniqueNew())"
        des                             = jsonData?["description"] as? String
        order                           = jsonData?["order"] as? Int
        iapGroupName                    = jsonData?["iap_group_name"] as? String
        if iapGroupName.count == 0 {
            purchasedType = .free
            iapGroupName = FreeKey
        } else {
            purchasedType = .unPurchased
        }
        audioUrl                        = jsonData?["object-url"] as? String
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: SoundtrackKeys.self)
        
        id                              = try container.decode(String.self, forKey: .id)
        name                            = try container.decode(String.self, forKey: .name)
        dirName                         = try container.decode(String.self, forKey: .dirName)
        des                             = try container.decode(String.self, forKey: .des)
        order                           = try container.decode(Int.self, forKey: .order)
        iapGroupName                    = try container.decode(String.self, forKey: .iapGroupName)
        audioUrl                        = try container.decode(String.self, forKey: .audioUrl)
        
        let mediaTypeStr                = try container.decode(String.self, forKey: .mediaType)
        mediaType                       = MediaType(rawValue: mediaTypeStr) ?? MediaType.image
        
        isSelected                      = try container.decode(Bool.self, forKey: .isSelected)
        isDownloaded                    = try container.decode(Bool.self, forKey: .isDownloaded)
        
        let purchasedStr                = try container.decode(String.self, forKey: .purchasedType)
        purchasedType                   = Purchased(rawValue: purchasedStr) ?? Purchased.free
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: SoundtrackKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(dirName, forKey: .dirName)
        try container.encode(des, forKey: .des)
        try container.encode(order, forKey: .order)
        try container.encode(iapGroupName, forKey: .iapGroupName)
        try container.encode(audioUrl, forKey: .audioUrl)
        try container.encode(mediaType.rawValue, forKey: .mediaType)
        try container.encode(purchasedType.rawValue, forKey: .purchasedType)
        try container.encode(isSelected, forKey: .isSelected)
        try container.encode(isDownloaded, forKey: .isDownloaded)
    }
}
