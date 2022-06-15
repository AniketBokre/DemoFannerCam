//
//  Score.swift
//  NewFannerCam
//
//  Created by Jin on 2/7/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import UIKit
import AVFoundation

struct Score: Codable {
    
    var id                      = Date().uniqueNew()
    var time                    : CMTime!
    var mainVideoStartTime      : CMTime!
    var cmTimeScale             : Int32!
    var scoreNum                : Int!
    var mainVideoFileName       : String!
    var team                    : Team = Team.first
    
    enum ScoreKeys : String, CodingKey {
        case id                 = "Score_id"
        case time               = "Score_time"
        case mainVideoStartTime = "Score_mainVideoStartTime"
        case cmTimeScale        = "Score_cmTimeScale"
        case scoreNum           = "Score_scoreNum"
        case mainVideoFileName  = "Score_mainVideoFileName"
        case team               = "Score_team"
    }
    
//MARK: - Main functions
    func startTimeInMatch() -> CMTime {
        return CMTimeAdd(mainVideoStartTime, time)
    }
    
//MARK: - Init functions
    init(_ mainVideoStartTime: CMTime, _ time: CMTime, _ score: Int, _ mainVideoName: String, _ team: Team) {
        self.time = time
        self.mainVideoStartTime = mainVideoStartTime
        cmTimeScale = time.timescale
        scoreNum = score
        mainVideoFileName = mainVideoName
        self.team = team
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: ScoreKeys.self)
        id = try container.decode(String.self, forKey: .id)
        cmTimeScale = try container.decode(Int32.self, forKey: .cmTimeScale)
        
        let timeSecs = try container.decode(Float64.self, forKey: .time)
        time = CMTimeMakeWithSeconds(timeSecs, preferredTimescale: cmTimeScale)
        
        let mainTimeSecs = try container.decode(Float64.self, forKey: .mainVideoStartTime)
        mainVideoStartTime = CMTimeMakeWithSeconds(mainTimeSecs, preferredTimescale: cmTimeScale)
        
        scoreNum = try container.decode(Int.self, forKey: .scoreNum)
        mainVideoFileName = try container.decode(String.self, forKey: .mainVideoFileName)
        let teamStr = try container.decode(String.self, forKey: .team)
        team = Team(rawValue: teamStr) ?? Team.first
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: ScoreKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(CMTimeGetSeconds(time), forKey: .time)
        try container.encode(CMTimeGetSeconds(mainVideoStartTime), forKey: .mainVideoStartTime)
        try container.encode(cmTimeScale, forKey: .cmTimeScale)
        try container.encode(scoreNum, forKey: .scoreNum)
        try container.encode(mainVideoFileName, forKey: .mainVideoFileName)
        try container.encode(team.rawValue, forKey: .team)
    }
    
}
