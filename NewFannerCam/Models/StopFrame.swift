//
//  StopFrame.swift
//  NewFannerCam
//
//  Created by Jin on 1/15/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import UIKit
import AVFoundation

struct StopFrame: Codable {
    
    var time                : CMTime!
    var cmtimeScale         : Int32!
    var duration            : Float64 = 3.0
    var fileName            : String!
    var tagNumber           : Int = Int(Date().timeIntervalSince1970)
    var stopImageFileName   : String = Date().uniqueNew()
    
    func videoPath() -> URL {
        return dirManager.generateVideo(fileName)
    }
    
    func imagePath() -> URL {
        return dirManager.generateStopframeImage("\(tagNumber)_stopframes", stopImageFileName.setExtension(isMov: false))
    }
    
    func stopVideoPath() -> URL {
        return dirManager.generateStopframeImage("\(tagNumber)_stopvideo", stopImageFileName.setExtension(isMov: true))
    }
    
    func isExistingImage() -> Bool {
        return dirManager.checkFileExist(imagePath())
    }
    
    func isExistingStopVideo() -> Bool {
        return dirManager.checkFileExist(stopVideoPath())
    }
    
    func removeStopVideo() {
        if isExistingStopVideo() {
            dirManager.deleteItems(at: stopVideoPath())
        }
    }
    
    func image() -> UIImage? {
        return UIImage(contentsOfFile: imagePath().path)
    }
    
    func endTime() -> CMTime {
        return CMTimeMakeWithSeconds(CMTimeGetSeconds(time) + duration, preferredTimescale: time.timescale)
    }
    
    func progressSliderValue() -> Float {
        let asset = AVAsset(url: videoPath())
        return Float(CMTimeGetSeconds(time)/CMTimeGetSeconds(asset.duration))
    }
    
//MARK: - Init functions
    init(_ fileName: String, _ time: CMTime) {
        self.fileName = fileName
        self.time = time
        cmtimeScale = time.timescale
    }
    
    enum StopFrameKeys : String, CodingKey {
        case time           = "StopFrame_time"
        case cmtimeScale    = "StopFrame_cmtimeScale"
        case duration       = "StopFrame_duration"
        case fileName       = "StopFrame_fileName"
        case tagNumber      = "StopFrame_tagNumber"
        case stopImageFileName = "StopFrame_stopImageFileName"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StopFrameKeys.self)
        cmtimeScale = try container.decode(Int32.self, forKey: .cmtimeScale)
        
        let timeSecs = try container.decode(Float64.self, forKey: .time)
        time = CMTimeMakeWithSeconds(timeSecs, preferredTimescale: cmtimeScale)
        
        duration = try container.decode(Float64.self, forKey: .duration)
        fileName = try container.decode(String.self, forKey: .fileName)
        tagNumber = try container.decode(Int.self, forKey: .tagNumber)
        stopImageFileName = try container.decode(String.self, forKey: .stopImageFileName)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StopFrameKeys.self)
        try container.encode(cmtimeScale, forKey: .cmtimeScale)
        try container.encode(CMTimeGetSeconds(time), forKey: .time)
        try container.encode(duration, forKey: .duration)
        try container.encode(fileName, forKey: .fileName)
        try container.encode(tagNumber, forKey: .tagNumber)
        try container.encode(stopImageFileName, forKey: .stopImageFileName)
    }
    
}
