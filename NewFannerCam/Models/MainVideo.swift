//
//  MainVideo.swift
//  NewFannerCam
//
//  Created by Jin on 1/20/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import UIKit
import AVFoundation

struct MainVideo: Codable {
    
    var startTime                   : CMTime!
    var cmTimeScale                 : Int32!
    var matchName                   : String!
    var fileName                    : String = Date().uniqueNew().setExtension(isMov: true)
    var period                      : String!
    
    //MARK: - mutating functions
    
    //MARK: - Init functions
    enum MainVideoKeys : String, CodingKey {
        case cmTimeScale        = "Mainvideo_cmTimeScale"
        case startTime          = "MainVideo_StartTime"
        case matchName          = "MainVideo_MatchName"
        case fileName           = "MainVideo_FileName"
        case period             = "MainVideo_Period"
    }
    
//MARK: - Main functions
    func filePath() -> URL {
        return dirManager.generateMatch(matchName, fileName, isMainVideo: true)
    }
    
    func endTime() -> CMTime {
        return CMTimeAdd(startTime, duration())
    }
    
    func duration() -> CMTime {
        let asset = AVAsset(url: filePath())
        return asset.duration
    }
    
    func currentVideoTime(_ time: CMTime) -> CMTime {
        return CMTimeAdd(startTime, time)
    }
    
//MARK: - Init functions
    init(_ matchName: String, _ startTime: CMTime, _ periodString: String) {
        self.matchName = matchName
        self.startTime = startTime
        self.cmTimeScale = startTime.timescale
        period = periodString
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: MainVideoKeys.self)
        
        cmTimeScale = try container.decode(Int32.self, forKey: .cmTimeScale)
        
        let startTimeSecs = try container.decode(Float64.self, forKey: .startTime)
        startTime = CMTimeMakeWithSeconds(startTimeSecs, preferredTimescale: cmTimeScale)
        
        matchName = try container.decode(String.self, forKey: .matchName)
        fileName = try container.decode(String.self, forKey: .fileName)
        period = try container.decode(String.self, forKey: .period)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: MainVideoKeys.self)
        try container.encode(cmTimeScale, forKey: .cmTimeScale)
        try container.encode(CMTimeGetSeconds(startTime), forKey: .startTime)
        try container.encode(matchName, forKey: .matchName)
        try container.encode(fileName, forKey: .fileName)
        try container.encode(period, forKey: .period)
    }
    
}
