//
//  Templates.swift
//  NewFannerCam
//
//  Created by Jin on 2/22/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import Foundation

enum MediaType: String {
    case image                  = "Image archive"
    case sounds                 = "Soundtracks"
    case templates              = "Templates"
}

enum Purchased: String {
    case free                   = "Free"
    case purchased              = "Purchased"
    case unPurchased            = "Unpurchased"
}

enum ScoreboardType: Int {
    case first                  = 1
    case second                 = 2
}

let FreeKey = "__"

struct Template: Codable {
    
    var id                              : String!
    var name                            : String!
    var dirName                         : String!
    var des                             : String!
    var order                           : Int!
    var scoreboardType                  = ScoreboardType.first
    var nClrScore                       : String!
    var nClrName                        : String!
    var iapGroupName                    : String!
    
    var introBase                       : String!
    var introBaseHD                     : String!
    var periodBase                      : String!
    var periodBaseHD                    : String!
    var introExample                    : String!
    var scoreboardBase                  : String!
    var replayBumper                    : String!
    var replayBumperHD                  : String!
    
    var mediaType                       = MediaType.templates
    var purchasedType                   = Purchased.free
    var isSelected                      = false
    var isDownloaded                    = false
    
    enum TemplateKeys : String, CodingKey {
        case id                         = "Templates_id"
        case name                       = "Templates_name"
        case dirName                    = "Templates_dirName"
        case des                        = "Templates_des"
        case order                      = "Templates_order"
        case scoreboardType             = "Templates_scoreboardType"
        case nClrScore                  = "Templates_nClrScore"
        case nClrName                   = "Templates_nClrName"
        case iapGroupName               = "Templates_iapGroupName"
        
        case scoreboardBase             = "Templates_scoreboardBase.png"
        case introBase                  = "Templates_introBase.mov"
        case introBaseHD                = "Templates_introBaseHD.mov"
        case periodBase                 = "Templates_periodBase.mov"
        case periodBaseHD               = "Templates_periodBaseHD.mov"
        case introExample               = "Templates_introExample.mov"
        case replayBumper               = "Templates_replayBumper.mov"
        case replayBumperHD             = "Templates_replayBumperHD.mov"
        
        case mediaType                  = "Templates_mediaType"
        case purchasedType              = "Templates_purchasedType"
        case isSelected                 = "Templates_isSelected"
        case isDownloaded               = "Templates_isDownloaded"
    }
    
//MARK: - Main functions
    func templateDirPath() -> URL {
        return dirManager.generateSettingMeida(dirName, mediaType)
    }
    
    func filePath(of fileType: TemplateKeys) -> URL {
        return URL(fileURLWithPath: templateDirPath().path.combineDirPath(fileType.rawValue))
    }
    
    func nClrNameInt() -> Int {
        return Int(nClrName) ?? 0
    }
    
    func nClrScoreInt() -> Int {
        return Int(nClrScore) ?? 1
    }
    
    mutating func removeFiles() {
        if isDownloaded {
            dirManager.deleteItems(at: filePath(of: .scoreboardBase))
            dirManager.deleteItems(at: filePath(of: .introBase))
            dirManager.deleteItems(at: filePath(of: .introBaseHD))
            dirManager.deleteItems(at: filePath(of: .periodBase))
            dirManager.deleteItems(at: filePath(of: .periodBaseHD))
            dirManager.deleteItems(at: filePath(of: .introExample))
            dirManager.deleteItems(at: filePath(of: .replayBumper))
            dirManager.deleteItems(at: filePath(of: .replayBumperHD))
            isDownloaded = false
            isSelected = false
        }
    }
    
    mutating func saveFiles(_ completion: @escaping(Bool, String) -> Void) {
        if !isDownloaded {
            
            let urlCases = [
                TemplateKeys.scoreboardBase,
                TemplateKeys.introBase,
                TemplateKeys.introBaseHD,
                TemplateKeys.periodBase,
                TemplateKeys.periodBaseHD,
                TemplateKeys.introExample,
                TemplateKeys.replayBumper,
                TemplateKeys.replayBumperHD,
            ]
            
            let urls = [
                scoreboardBase,
                introBase,
                introBaseHD,
                periodBase,
                periodBaseHD,
                introExample,
                replayBumper,
                replayBumperHD
            ]
            
            var index = 0
            let queue = OperationQueue()
            queue.maxConcurrentOperationCount = 1
            
            for url in urls {
                
                guard url != nil else {
                    completion(false, "Empty Item, Please refresh the list to download files exactly!")
                    return
                }
               let semaphore = DispatchSemaphore(value: 0)
                
                downloadTemplates(from: url!, to: filePath(of: urlCases[index]), isEndIndex: index == urls.count - 1) { (success, resultDes, isEndIndex) in
                    if success {
                        if isEndIndex {
                            completion(true, resultDes)
                        } else {
                            print(index, "media file downloaded")
                        }
                    } else {
                        completion(false, resultDes)
                    }
                    semaphore.signal()
                }
                semaphore.wait()
                index += 1
            }
            
//            Downloader.fileDownload(from: scoreboardBase, to: filePath(of: .scoreboardBase), isMov: false)
//            Downloader.fileDownload(from: introBase, to: filePath(of: .introBase), isMov: true)
//            Downloader.fileDownload(from: introBaseHD, to: filePath(of: .introBaseHD), isMov: true)
//            Downloader.fileDownload(from: periodBase, to: filePath(of: .periodBase), isMov: true)
//            Downloader.fileDownload(from: periodBaseHD, to: filePath(of: .periodBaseHD), isMov: true)
//            Downloader.fileDownload(from: introExample, to: filePath(of: .introExample), isMov: true)
//            Downloader.fileDownload(from: replayBumper, to: filePath(of: .replayBumper), isMov: true)
//            Downloader.fileDownload(from: replayBumperHD, to: filePath(of: .replayBumperHD), isMov: true)
        } else {
            completion(true, "Already downloaded item!")
        }
    }
    
    func downloadTemplates(from: String, to: URL, isEndIndex: Bool, _ completion: @escaping(Bool, String, Bool) -> Void) {
        DispatchQueue.global().async {
            Downloader.mediaDownload(from: from, to: to) { (success, resultDes) in
                if success {
                    if isEndIndex {
                        completion(true, "Success", true)
                    } else {
                        completion(true, "Success", false)
                    }
                } else {
                    completion(false, resultDes, false)
                }
            }
        }
    }
    
    mutating func set(with other: Template) {
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
    
//MARK: - Init functions
    init(){ }
    
    init(_ jsonData: CustomJSON?) {
        id                              = jsonData?["id"] as? String
        name                            = jsonData?["title"] as? String
        dirName                         = "\(name ?? String())\(Date().uniqueNew())"
        des                             = jsonData?["description"] as? String
        order                           = jsonData?["order"] as? Int
        
        let scoreboardTypeData          = jsonData?["scoreboard-type"] as? String
        scoreboardType                  = ScoreboardType(rawValue: Int(scoreboardTypeData!)!) ?? ScoreboardType.first
        
        nClrScore                       = jsonData?["nClrScore"] as? String
        nClrName                        = jsonData?["nClrName"] as? String
        iapGroupName                    = jsonData?["iap_group_name"] as? String
        if iapGroupName.count == 0 {
            purchasedType = .free
            iapGroupName = FreeKey
        } else {
            purchasedType = .unPurchased
        }
        
        let paramData                   = jsonData?["params"] as? CustomJSON
        
        scoreboardBase                  = paramData?["image-base-scoreboard"] as? String
        
        let introData                   = paramData?["video-base-intro"] as? CustomJSON
        introBase                       = introData?["hd"] as? String
        introBaseHD                     = introData?["fullhd"] as? String
        
        let periodData                  = paramData?["video-base-period-bumper"] as? CustomJSON
        periodBase                      = periodData?["hd"] as? String
        periodBaseHD                    = periodData?["fullhd"] as? String
        
        introExample                    = paramData?["video-example-intro"] as? String
        
        let replayData                  = paramData?["video-replay-bumper"] as? CustomJSON
        replayBumper                    = replayData?["hd"] as? String
        replayBumperHD                  = replayData?["fullhd"] as? String
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: TemplateKeys.self)
        
        id                              = try container.decode(String.self, forKey: .id)
        name                            = try container.decode(String.self, forKey: .name)
        dirName                         = try container.decode(String.self, forKey: .dirName)
        des                             = try container.decode(String.self, forKey: .des)
        order                           = try container.decode(Int.self, forKey: .order)
        let scoreboardTypeData          = try container.decode(Int.self, forKey: .scoreboardType)
        scoreboardType                  = ScoreboardType(rawValue: Int(scoreboardTypeData)) ?? ScoreboardType.first
        nClrScore                       = try container.decode(String.self, forKey: .nClrScore)
        nClrName                        = try container.decode(String.self, forKey: .nClrName)
        iapGroupName                    = try container.decode(String.self, forKey: .iapGroupName)
        introBase                       = try container.decode(String.self, forKey: .introBase)
        introBaseHD                     = try container.decode(String.self, forKey: .introBaseHD)
        periodBase                      = try container.decode(String.self, forKey: .periodBase)
        periodBaseHD                    = try container.decode(String.self, forKey: .periodBaseHD)
        introExample                    = try container.decode(String.self, forKey: .introExample)
        scoreboardBase                  = try container.decode(String.self, forKey: .scoreboardBase)
        replayBumper                    = try container.decode(String.self, forKey: .replayBumper)
        replayBumperHD                  = try container.decode(String.self, forKey: .replayBumperHD)
        
        let mediaTypeStr                = try container.decode(String.self, forKey: .mediaType)
        mediaType                       = MediaType(rawValue: mediaTypeStr) ?? MediaType.image
        
        isSelected                      = try container.decode(Bool.self, forKey: .isSelected)
        isDownloaded                    = try container.decode(Bool.self, forKey: .isDownloaded)
        
        let purchasedStr                = try container.decode(String.self, forKey: .purchasedType)
        purchasedType                   = Purchased(rawValue: purchasedStr) ?? Purchased.free
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: TemplateKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(dirName, forKey: .dirName)
        try container.encode(des, forKey: .des)
        try container.encode(order, forKey: .order)
        try container.encode(scoreboardType.rawValue, forKey: .scoreboardType)
        try container.encode(nClrScore, forKey: .nClrScore)
        try container.encode(nClrName, forKey: .nClrName)
        try container.encode(iapGroupName, forKey: .iapGroupName)
        try container.encode(introBase, forKey: .introBase)
        try container.encode(introBaseHD, forKey: .introBaseHD)
        try container.encode(periodBase, forKey: .periodBase)
        try container.encode(periodBaseHD, forKey: .periodBaseHD)
        try container.encode(introExample, forKey: .introExample)
        try container.encode(scoreboardBase, forKey: .scoreboardBase)
        try container.encode(replayBumper, forKey: .replayBumper)
        try container.encode(replayBumperHD, forKey: .replayBumperHD)
        try container.encode(mediaType.rawValue, forKey: .mediaType)
        try container.encode(purchasedType.rawValue, forKey: .purchasedType)
        try container.encode(isSelected, forKey: .isSelected)
        try container.encode(isDownloaded, forKey: .isDownloaded)
    }
}
