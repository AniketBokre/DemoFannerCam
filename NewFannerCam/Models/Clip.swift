//
//  Clip.swift
//  NewFannerCam
//
//  Created by Jin on 1/15/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import UIKit
import AVFoundation

enum ClipTeam: String {
    case lsh            = "Left_team"
    case rsh            = "Right_team"
}

struct Clip: Codable {
    
    var id                  : String = Date().uniqueNew()
    var mainVideoStartTime  : CMTime!
    var endTime             : CMTime!
    var cmTimeScale         : Int32!
    var matchName           : String!
    var mainVideoFileName   : String!
    var marker              : Marker!
    var clipTag             : Int!
    var team                : Team = Team.first
    var period              : String!
    
    var isReplay            : Bool = false
    var isPost              : Bool = false
    var isSelected          : Bool = false
    
    var sliderMaxVal        : Float64 = 0.0
    var initTimeSlider      = CMTime.zero
    var lowValue            : Float64 = 0.0
    var highValue           : Float64 = 0.0
    var isReset             : Bool = false
    
//MARK: - Act functions
    func removeAllClipFiles() {
        removeClipFiles(true)
        removeClipFiles()
    }
    func removeClipFiles(_ shouldDeleteBanner: Bool = false) {
        if isExistClipFiles(isBanner: false) {
            dirManager.deleteItems(at: getFilePath(ofMainVideo: false))
        }
        if shouldDeleteBanner, isExistClipFiles(isBanner: true) {
            dirManager.deleteItems(at: getBannerImgPath())
        }
    }
    
//MARK: - Checking functions
    func isExistClipFiles(isBanner: Bool) -> Bool {
        if isBanner {
            return dirManager.checkFileExist(getBannerImgPath())
        } else {
            return dirManager.checkFileExist(getFilePath(ofMainVideo: false))
        }
    }
    
//MARK: - Get Functions
    // Get URL
    
    func getFilePath(ofMainVideo: Bool) -> URL {
        if ofMainVideo {
            return dirManager.generateMatch(matchName, mainVideoFileName, isMainVideo: true) // mainvideo file url
        } else {
            return dirManager.generateMatch(matchName, id.setExtension(isMov: true), isMainVideo: false)
        }
    }
    
    func getBannerImgPath() -> URL {
        return dirManager.generateMatch(matchName, "\(id)_banner.png", isMainVideo: false)
    }
    
    func getBannerImg() -> UIImage? {
        return UIImage(contentsOfFile: getBannerImgPath().path)
    }
    
    // Get Times
    func getClipDuration() -> CMTime {
        return CMTimeMakeWithSeconds(marker.duration, preferredTimescale: cmTimeScale)
    }
    
    func getStartTimeInMatch() -> CMTime {
        return CMTimeAdd(mainVideoStartTime, getClipStartTime())
    }
    
    func getEndTimeInMatch() -> CMTime {
        return CMTimeAdd(mainVideoStartTime, endTime)
    }
    
    func getClipStartTime() -> CMTime {
        return CMTimeMakeWithSeconds(CMTimeGetSeconds(endTime) - marker.duration, preferredTimescale: cmTimeScale)
    }
    
    // Get other data    
//    func getSliderLowVal() -> Float64 {
//        return CMTimeGetSeconds(endTime) - marker.duration - CMTimeGetSeconds(initTimeSlider)
//    }
    
//    func getSliderHighVal() -> Float64 {
//        return CMTimeGetSeconds(CMTimeSubtract(endTime, initTimeSlider))
//    }
    
    func getSliderMaxVal() -> Float64 {
        return sliderMaxVal
    }
    
    func titleDescription() -> String {
        var des = marker.titleDescription()
        if isPost {
            des = "\(des) Post"
        }
        if isReplay {
            des = "\(des) Replay"
        }
        return des
    }
    
    func durationDes() -> String {
        return "\(Int(marker.duration)) sec"
    }
    
    func getthumbCache(forKey: Float64) -> UIImage? {
        let cacheKey = "\(id)\(Int(forKey.rounded(.up)))"
        return DataManager.shared.getImageCache(forKey: cacheKey) 
    }
    
    func getCurrentMatchTime(of time: CMTime) -> CMTime {
        return CMTimeAdd(mainVideoStartTime, time)
    }
    
//MARK: - Set functions
    func set(cache image: UIImage, at time: Float64) {
        let cacheKey = "\(id)\(Int(time.rounded(.up)))"
        DataManager.shared.set(cache: image, for: cacheKey)
    }
    
    func setBannerImg(_ image: UIImage, _ completion: @escaping (Bool, String) -> Void) {
        if isExistClipFiles(isBanner: true) {
            removeClipFiles(true)
        }
        ImageProcess.save(imgFile: image, to: getBannerImgPath()) { (isSucceed, resultDes) in
            completion(isSucceed, resultDes)
        }
    }
    
    mutating func setEndTime(with float64Val: Float64) {
        endTime = CMTimeMakeWithSeconds(CMTimeGetSeconds(initTimeSlider) + float64Val, preferredTimescale: cmTimeScale)
    }
    
    mutating func set(isSelected val: Bool) {
        self.isSelected = val
    }
    
    mutating func set(marker val: Marker) {
        self.marker = val
    }
    
    mutating func set(duration val: Float64) {
        marker.set(val)
    }
    
    mutating func set(tagNumber val: Int) {
        clipTag = val
    }
    
    mutating func set(isReplay val: Bool) {
        self.isReplay = val
    }
    
    mutating func set(highValue: Float64) {
        self.highValue = highValue
        setEndTime(with: highValue)
        set(duration: highValue - lowValue)
    }
    
    mutating func set(lowValue: Float64) {
        self.lowValue = lowValue
        set(duration: highValue - lowValue)
    }
    
    
    mutating func reset() {
        
        let mainVideoDuration = AVAsset(url: getFilePath(ofMainVideo: true)).duration
        
        if CMTimeGetSeconds(endTime) >= CMTimeGetSeconds(mainVideoDuration) {
            marker.duration = CMTimeGetSeconds(mainVideoDuration) - CMTimeGetSeconds(getClipStartTime())
            endTime = mainVideoDuration
            let afterVal = 5.0 //((30 - marker.duration)/3)
            let eSliderLowVal = 10.0//30 - afterVal - marker.duration
            
            initTimeSlider = CMTimeMakeWithSeconds(CMTimeGetSeconds(getClipStartTime()) - eSliderLowVal, preferredTimescale: cmTimeScale)
            sliderMaxVal = CMTimeGetSeconds(CMTimeSubtract(endTime, initTimeSlider))
        } else {
            if marker.duration >= CMTimeGetSeconds(endTime) {                                         // 1, 2 cases
                marker.duration = CMTimeGetSeconds(endTime)
                initTimeSlider = CMTime.zero
                let afterVal = 5.0//((30 - marker.duration)/3)
                
                if CMTimeGetSeconds(endTime) + afterVal >= CMTimeGetSeconds(mainVideoDuration) {                // 2 case
                    sliderMaxVal = CMTimeGetSeconds(mainVideoDuration)
                } else {                                                                    // 1 case
                    sliderMaxVal = CMTimeGetSeconds(endTime) + afterVal
                }
            } else {                                                                        // 3, 4, 5, 6 cases
                let afterVal = 5.0//((30 - marker.duration)/3)
                let eSliderLowVal = 10.0// 30 - afterVal - marker.duration
                
                if CMTimeGetSeconds(endTime) + afterVal >= CMTimeGetSeconds(mainVideoDuration) {                // 5, 6 cases
                    if eSliderLowVal >= CMTimeGetSeconds(getClipStartTime()) {                        // 5 case
                        sliderMaxVal = CMTimeGetSeconds(mainVideoDuration)
                        //                        initTimeSlider = CMTime.zero
                    } else {                                                                // 6 case
                        initTimeSlider = CMTimeMakeWithSeconds(CMTimeGetSeconds(getClipStartTime()) - eSliderLowVal, preferredTimescale: cmTimeScale)
                        sliderMaxVal = CMTimeGetSeconds(CMTimeSubtract(mainVideoDuration, initTimeSlider))
                    }
                } else {                                                                    // 3, 4 cases
                    if eSliderLowVal >= CMTimeGetSeconds(getClipStartTime()) {              // 4 case
                        sliderMaxVal = CMTimeGetSeconds(endTime) + afterVal
                        initTimeSlider = CMTime.zero
                    } else {                                                                // 3 case
                        sliderMaxVal = marker.duration + 15.0
                        initTimeSlider = CMTimeMakeWithSeconds(CMTimeGetSeconds(getClipStartTime()) - eSliderLowVal, preferredTimescale: cmTimeScale)
                    }
                }
            }
        }
        lowValue = CMTimeGetSeconds(endTime) - marker.duration - CMTimeGetSeconds(initTimeSlider)
        highValue = CMTimeGetSeconds(CMTimeSubtract(endTime, initTimeSlider))
        isReset = true
    }

//MARK: - Init Functions    
    init(_ endTime: CMTime, _ mainVideoFileName: String, _ mainVideoStartTime: CMTime, _ matchName: String, _ team: Team, _ period: String, _ marker: Marker?, _ isReplay: Bool, _ isPost: Bool, _ clipTag: Int?) {
        self.mainVideoStartTime     = mainVideoStartTime
        self.endTime                = endTime
        self.cmTimeScale            = endTime.timescale
        self.matchName              = matchName
        self.mainVideoFileName      = mainVideoFileName
        self.team                   = team
        self.period                 = period
        if let realMarker = marker {
            self.marker = realMarker
        }
        self.isReplay = isReplay
        self.isPost = isPost
        if let tagNum = clipTag {
            self.clipTag = tagNum
        }
    }
    
    enum ClipKeys : String, CodingKey {
        case id                     = "Clip_id"
        case mainVideoStartTime     = "Clip_mainViewStartTime"
        case endTime                = "Clip_endTime"
        case cmTimeScale            = "Clip_cmTimeScale"
        case matchName              = "Clip_matchMame"
        case mainVideoFileName      = "Clip_mainVideoFileName"
        case marker                 = "Clip_marker"
        case clipTag                = "Clip_clipTag"
        case team                   = "Clip_team"
        case period                 = "Clip_period"
        case isReplay               = "Clip_isReplay"
        case isPost                 = "Clip_isPost"
        case isSelected             = "Clip_isSelected"
        case sliderMaxVal           = "Clip_sliderMaxVal"
        case initTimeSlider         = "Clip_initTimeSlider"
        case lowValue               = "Clip_lowValue"
        case highValue              = "Clip_highValue"
        case isReset                = "Clip_isReset"
        case isImageClip            = "Clip_isImageClip"
    }
    
    init(from decoder: Decoder) throws {
        let container       = try decoder.container(keyedBy: ClipKeys.self)
        id                  = try container.decode(String.self, forKey: .id)
        cmTimeScale         = try container.decode(Int32.self, forKey: .cmTimeScale)
        
        let mainVideoStartTimeSec = try container.decode(Float64.self, forKey: .mainVideoStartTime)
        mainVideoStartTime  = CMTimeMakeWithSeconds(mainVideoStartTimeSec, preferredTimescale: cmTimeScale)
        
        let endTimeSec      = try container.decode(Float64.self, forKey: .endTime)
        endTime             = CMTimeMakeWithSeconds(endTimeSec, preferredTimescale: cmTimeScale)
        
        matchName           = try container.decode(String.self, forKey: .matchName)
        mainVideoFileName   = try container.decode(String.self, forKey: .mainVideoFileName)
        
        marker              = try container.decode(Marker.self, forKey: .marker)
        
        let teamStr         = try container.decode(String.self, forKey: .team)
        team                = Team(rawValue: teamStr) ?? Team.first
        period              = try container.decode(String.self, forKey: .period)
        isReplay            = try container.decode(Bool.self, forKey: .isReplay)
        isPost              = try container.decode(Bool.self, forKey: .isPost)
        isSelected          = try container.decode(Bool.self, forKey: .isSelected)
        sliderMaxVal        = try container.decode(Float64.self, forKey: .sliderMaxVal)
        lowValue            = try container.decode(Float64.self, forKey: .lowValue)
        highValue           = try container.decode(Float64.self, forKey: .highValue)
        
        let initTimeSliderSecs      = try container.decode(Float64.self, forKey: .initTimeSlider)
        initTimeSlider = CMTimeMakeWithSeconds(initTimeSliderSecs, preferredTimescale: cmTimeScale)
        
        isReset             = try container.decode(Bool.self, forKey: .isReset)
        
        if marker.type == .individual {
            clipTag             = try container.decode(Int.self, forKey: .clipTag)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: ClipKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(CMTimeGetSeconds(mainVideoStartTime), forKey: .mainVideoStartTime)
        try container.encode(CMTimeGetSeconds(endTime), forKey: .endTime)
        try container.encode(cmTimeScale, forKey: .cmTimeScale)
        try container.encode(matchName, forKey: .matchName)
        try container.encode(mainVideoFileName, forKey: .mainVideoFileName)
        
        if let realMarker = marker {
            try container.encode(realMarker, forKey: .marker)
        }
        if let realClipTag = clipTag {
            try container.encode(realClipTag, forKey: .clipTag)
        }
        
        try container.encode(team.rawValue, forKey: .team)
        try container.encode(period, forKey: .period)
        try container.encode(isReplay, forKey: .isReplay)
        try container.encode(isPost, forKey: .isPost)
        try container.encode(isSelected, forKey: .isSelected)
        try container.encode(sliderMaxVal, forKey: .sliderMaxVal)
        try container.encode(lowValue, forKey: .lowValue)
        try container.encode(highValue, forKey: .highValue)
        try container.encode(CMTimeGetSeconds(initTimeSlider), forKey: .initTimeSlider)
        try container.encode(isReset, forKey: .isReset)
    } 
    
}

struct ReportClip {
    var clips        = [Clip]()
    var fstCount    : Int!
    var sndCount    : Int!
    var checkFst    : Bool = false
    var checkSnd    : Bool = false
    
    var isSelected  : Bool {
        return checkFst || checkSnd
    }
    
    init(_ clip: Clip, _ fstCount: Int, _ sndCount: Int) {
        self.clips.append(clip)
        self.fstCount = fstCount
        self.sndCount = sndCount
    }
}
