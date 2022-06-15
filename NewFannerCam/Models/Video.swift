//
//  Video.swift
//  NewFannerCam
//
//  Created by Jin on 1/15/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import UIKit
import AVFoundation

struct Video: Codable {
    
    var fileName                    : String = Date().uniqueNew().setExtension(isMov: true)
    var title                       : String!
    var stopframes                  = [StopFrame]()
    var quality                     : String!
    var highBitrate                 : Bool = false
    
    enum VideoKeys : String, CodingKey {
        case fileName               = "Video_FileName"
        case title                  = "Video_title"
        case stopframes             = "Video_stopframes"
        case quality                = "Video_quality"
        case highBitrate            = "Video_highBitrate"
    }
    
//MARK: - Main function
    func filePath() -> URL {
        return dirManager.generateVideo(fileName)
    }
    
    func duration() -> Int {
        let asset = AVAsset(url: filePath())
        return Int(CMTimeGetSeconds(asset.duration))
    }
    
    mutating func update(stopframe item: StopFrame, updater: Updater) {
        let index = stopframes.firstIndex { $0.tagNumber == item.tagNumber } ?? stopframes.count - 1
        
        if updater == .new {
            stopframes.append(item)
        }
        else if updater == .replace {
            stopframes[index] = item
        }
        else if updater == .delete {
            stopframes.remove(at: index)
        }
    }
    
//MARK: - Init functions
    init(_ title: String, _ highBitrate: Bool, _ quality: String) {
        self.title = title
        self.highBitrate = highBitrate
        self.quality = quality
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: VideoKeys.self)
        
        fileName        = try container.decode(String.self, forKey: .fileName)
        title           = try container.decode(String.self, forKey: .title)
        stopframes      = try container.decode([StopFrame].self, forKey: .stopframes)
        highBitrate     = try container.decode(Bool.self, forKey: .highBitrate)
        quality         = try container.decode(String.self, forKey: .quality)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: VideoKeys.self)
        try container.encode(fileName, forKey: .fileName)
        try container.encode(title, forKey: .title)
        try container.encode(stopframes, forKey: .stopframes)
        try container.encode(highBitrate, forKey: .highBitrate)
        try container.encode(quality, forKey: .quality)
    }
    
}
