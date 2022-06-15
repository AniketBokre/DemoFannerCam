//
//  Match.swift
//  NewFannerCam
//
//  Created by Jin on 1/15/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import UIKit
import AVFoundation

enum MatchType : String {
    case importMatch    = "import"
    case recordMatch    = "record"
    case liveMatch      = "live"
}

struct Match : Codable {
    
    var id                              : String = Date().uniqueNew()
    var type                            : MatchType = .recordMatch
    var isPurchased                     : Bool = false
    
    var fstName                         : String!
    var fstAbbName                      : String!
    
    var sndName                         : String!
    var sndAbbName                      : String!
    
    var createdDate                     : Date = Date()
    var isResolution1280                : Bool = true
    var mainVideos                      : [MainVideo] = [MainVideo]()
    var preClip                         : ImageClip!
    var clips                           : [Clip] = [Clip]()
    var scores                          : [Score] = [Score]()
    var scoreboardSetting               = ScoreboardSetting()
    
    // filter properties
    var currentFilter : Filter = Filter.noFilter
    var currentMarker : Marker!
    
    enum MatchKeys : String, CodingKey {
        case id                         = "Match_id"
        case index                      = "Match_index"
        case type                       = "Match_type"
        case isPurchased                = "Match_IsPurchased"
        case fstName                    = "Match_FstName"
        case fstAbbName                 = "Match_FstAbbName"
        case sndName                    = "Match_SndName"
        case sndAbbName                 = "Match_SndAbbName"
        case createdDate                = "Match_CreatedDate"
        case resolution1280             = "Match_resolution1280"
        case mainVideos                 = "Match_MainVideos"
        case preClip                    = "Match_preClip"
        case clips                      = "Match_Clips"
        case scores                     = "Match_scores"
        case scoreboardSetting          = "Match_scoreboardSetting"
    }
    
//MARK: - MAIN functions
    //MARK: other functions
    func quality() -> String {
        if isResolution1280 {
            return AVAssetExportPreset1280x720
        } else {
            return AVAssetExportPreset1920x1080
        }
    }
    
    func namePresentation() -> String {
        return fstName.combine(adding: sndName, with: " VS ")
    }
    
    func matchTime(by i: Int? = nil) -> Float64 {
        if let index = i {
            var sumSecs : Float64 = 0
            for (indexNum, value) in mainVideos.enumerated() {
                if indexNum == index {
                    break
                } else {
                    sumSecs += CMTimeGetSeconds(value.duration())
                }
            }
            return sumSecs
        } else {
            return mainVideos.lazy.map{ CMTimeGetSeconds($0.duration()) }.reduce(0, +)
        }
    }
    
    func matchDescription() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMM YYYY"
        let dateStr = dateFormatter.string(from: createdDate)
        let quality = isResolution1280 ? " | HD" : " | FHD"
        let matchType = type == .recordMatch ? "Recorded on" : "Imported on"
        let result = "\(matchType) \(dateStr) | \(getMatchSize())\(quality)"
        return result
    }
    
    func matchPath() -> URL {
        return URL(fileURLWithPath: dirManager.matchDirectory(id))
    }
    
    func mainVideoPath() -> URL {
        return URL(fileURLWithPath: dirManager.matchSubDirs(matchName: id).mainVideoDir)
    }
    
    func clipsPath() -> URL {
        return URL(fileURLWithPath: dirManager.matchSubDirs(matchName: id).clipVideoDir)
    }
    
    func getMatchDuration() -> Float64 {
        return mainVideos.compactMap{ CMTimeGetSeconds(AVAsset(url: $0.filePath()).duration) }.reduce(0, +)
    }
    
    func getMatchSize() -> String {
        var size : UInt64 = 0
        size += dirManager.getFolderSize(of: mainVideoPath())
        size += dirManager.getFolderSize(of: clipsPath())
        
        if preClip.isExistingPreClipFile() {
            size += dirManager.sizePerMB(url: preClip.getPreClipPath())
        }
        return dirManager.sizeToPrettyString(size: size)
    }
    
//MARK: MAINVIDEOS
    func isExceededLimitMatchTime() -> Bool {
        return matchTime()/60 >= 180
    }
    
    mutating func update(newMainVideo item: MainVideo, updater: Updater, index: Int) {
        if updater == .new {
            mainVideos.append(item)
        }
        else if updater == .replace {
            mainVideos[index] = item
        }
        else if updater == .delete {
            mainVideos.remove(at: index)
            
            if mainVideos.count == 0 {
                for clip in clips {
                    update(newClip: clip, updater: .delete)
                }
            } else {
                /*  - removing related clips - */
                let removeableClips = clips.filter { $0.mainVideoFileName == item.fileName }
                for removeClip in removeableClips {
                    update(newClip: removeClip, updater: .delete)
                }
                
                /*- resetting mainvideo startTime & clip mainVideoStartTime -*/
                if index == mainVideos.count {
                    return
                }
                resetMainVideoStartTimes()
            }
        }
    }
    
    mutating func sortMainVideos() {
        mainVideos.sort { $0.fileName < $1.fileName }
    }
    
    mutating func resetMainVideoStartTimes() {
        for (i, _) in mainVideos.enumerated() {
            if i == 0 {
                mainVideos[0].startTime = CMTime.zero
            } else {
                mainVideos[i].startTime = mainVideos[i - 1].endTime()
            }
        }
    }
    
    func newMainVideoStartTime(_ timeScale: Int32) -> CMTime {
        if isEmptyMainVideos() {
            return CMTimeMakeWithSeconds(0.0, preferredTimescale: timeScale)
        } else {
            return mainVideos[lastMainVideoIndex()].endTime()
        }
    }
    
    func lastMainVideoIndex() -> Int {
        return mainVideos.count - 1
    }
    
    func isEmptyMainVideos() -> Bool {
        return mainVideos.isEmpty
    }
    
    //MARK: CLIPS
    mutating func update(newClip item: Clip, updater: Updater, index: Int? = nil) {
        var indexNum = 0
        if let i = index {
            indexNum = i
        } else {
            let indexObj = clips.firstIndex { $0.id == item.id }
            if let i = indexObj {
                indexNum = i
            } 
        }
        
        if updater == .new {
            clips.append(item)
        }
        else if updater == .replace {
            clips[indexNum] = item
        }
        else if updater == .delete {
            item.removeAllClipFiles()
            clips.remove(at: indexNum)
        }
    }
    
    mutating func sortClips() {
        clips.sort { CMTimeGetSeconds($0.getStartTimeInMatch()) < CMTimeGetSeconds($1.getStartTimeInMatch()) }
    }
    
    func isEmptyClips() -> Bool {
        return clips.isEmpty
    }
    
    func lastClipIndex() -> Int {
        return clips.count - 1
    }
    
    func isLastClip(_ clip: Clip, of clips: [Clip]) -> Bool {
        if let last = clips.last {
            if last.id == clip.id {
                return true
            } else {
                return false
            }
        } else {
            return false
        }
    }
    
    func get(clipIndexBy id: String) -> Int {
        return clips.lazy.firstIndex { $0.id == id } ?? 0
    }
    
     mutating func set(replayClip clip: Clip) {
        let indexObj = clips.firstIndex { $0.id == clip.id }
        guard let index = indexObj else { return }
        var new = Clip(clip.endTime, clip.mainVideoFileName, clip.mainVideoStartTime, clip.matchName, clip.team, clip.period, clip.marker, true, clip.isPost, clip.clipTag)
        new.reset()
        let newIndex = index + 1
        clips.insert(new, at: newIndex)
    }
    
    //MARK: SCORES
    mutating func update(newScore item: Score, updater: Updater, index: Int) {
        if updater == .new {
            scores.append(item)
        }
        else if updater == .replace {
            scores[index] = item
        }
        else if updater == .delete {
            scores.remove(at: index)
        }
    }
    
    mutating func sortScores() {
        scores.sort { CMTimeGetSeconds( $0.startTimeInMatch()) < CMTimeGetSeconds($1.startTimeInMatch()) }
    }
    
    func isEmptyScores() -> Bool {
        return scores.isEmpty
    }
    
    func isLastScore(_ score: Score, of scores: [Score]) -> Bool {
        if let last = scores.last {
            if CMTimeGetSeconds(last.time) == CMTimeGetSeconds(score.time) {
                return true
            } else {
                return false
            }
        } else {
            return false
        }
    }
    
    func getNextScore(to score: Score, of scores: [Score]) -> Score? {
        let indexObj = scores.firstIndex { CMTimeGetSeconds($0.time) == CMTimeGetSeconds(score.time) }
        if let index = indexObj {
            if index + 1 <= scores.count - 1 {
                return scores[index + 1]
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    func lastScoreIndex() -> Int {
        return scores.count - 1
    }
    
    func scoreDescription(_ time: CMTime) -> String {
        return "\(getScoreAt(time: time, of: .first)) - \(getScoreAt(time: time, of: .second))" 
    }
    
    func getScores(in duration: Float64, from startTime: CMTime) -> [Score] {
        return scores.filter { $0.startTimeInMatch() >= startTime && CMTimeGetSeconds($0.startTimeInMatch()) <= CMTimeGetSeconds(startTime) + duration }.sorted { $0.startTimeInMatch() < $1.startTimeInMatch() }
    }
    
    func getScoreAt(time: CMTime? = nil, of team: Team) -> Int {
        if let rTime = time {
            return scores.lazy.filter{ $0.team == team && rTime >= $0.startTimeInMatch() }.compactMap { $0.scoreNum }.reduce(0, +)
        } else {
            return get(lastScoreOf: team)
        }
    }
    
    func get(lastScoreOf team: Team) -> Int {
        return scores.lazy.filter{ $0.team == team }.compactMap { $0.scoreNum }.reduce(0, +)
    }
    
    //MARK: TEAM FUNCTIONS
    func matchLogoPath(_ team: Team? = nil) -> URL {
        if let tempTeam = team {
            if tempTeam == .first {
                return dirManager.matchLogosPaths(id, .first)
            } else {
                return dirManager.matchLogosPaths(id, .second)
            }
        } else {
            return dirManager.matchLogosPaths(id)
        } 
    }
    
    func setLogos(_ image: UIImage, _ team: Team? = nil, _ completion: @escaping (Bool, String) -> Void) {
        let toUrl = matchLogoPath(team)
        
        dirManager.deleteItems(at: toUrl)
        
        ImageProcess.save(imgFile: image, to: toUrl) { (isSucceed, resultDes) in
            completion(isSucceed, resultDes)
        }
    }
    
//MARK: - Init functions
    init() {
        preClip = ImageClip(id)
    }
    
    mutating func set(_ fstName: String, _ fstAbbName: String, _ sndName: String, _ sndAbbName: String, _ matchType: MatchType) {
        self.fstName                = fstName
        self.fstAbbName             = fstAbbName
        self.sndName                = sndName
        self.sndAbbName             = sndAbbName
        self.type                   = matchType
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: MatchKeys.self)
        id = try container.decode(String.self, forKey: .id)
        let typeRawVal = try container.decode(String.self, forKey: .type)
        type = MatchType(rawValue: typeRawVal) ?? MatchType.recordMatch
        isPurchased = try container.decode(Bool.self, forKey: .isPurchased)
        
        fstName = try container.decode(String.self, forKey: .fstName)
        fstAbbName = try container.decode(String.self, forKey: .fstAbbName)
        
        sndName = try container.decode(String.self, forKey: .sndName)
        sndAbbName = try container.decode(String.self, forKey: .sndAbbName)
        
        createdDate = try container.decode(Date.self, forKey: .createdDate)
        isResolution1280 = try container.decode(Bool.self, forKey: .resolution1280)
        mainVideos = try container.decode([MainVideo].self, forKey: .mainVideos)
        preClip = try container.decode(ImageClip.self, forKey: .preClip)
        clips = try container.decode([Clip].self, forKey: .clips)
        scores = try container.decode([Score].self, forKey: .scores)
        scoreboardSetting = try container.decode(ScoreboardSetting.self, forKey: .scoreboardSetting)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: MatchKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type.rawValue, forKey: .type)
        try container.encode(isPurchased, forKey: .isPurchased)
        
        try container.encode(fstName, forKey: .fstName)
        try container.encode(fstAbbName, forKey: .fstAbbName)
        
        try container.encode(sndName, forKey: .sndName)
        try container.encode(sndAbbName, forKey: .sndAbbName)
        
        try container.encode(createdDate, forKey: .createdDate)
        try container.encode(isResolution1280, forKey: .resolution1280)
        try container.encode(mainVideos, forKey: .mainVideos)
        try container.encode(preClip, forKey: .preClip)
        try container.encode(clips, forKey: .clips)
        try container.encode(scores, forKey: .scores)
        try container.encode(scoreboardSetting, forKey: .scoreboardSetting)
    }
    
}

//MARK: - Clip filters
enum Filter: String {
    case marker
    case selected       = "Selected Clips"
    case noFilter       = "No filters"
}

extension Match {
    
    func getSelectedMarker(with title: String) -> Marker {
        return getFilterMarkers().filter { $0.name == title }[0]
    }
    
    mutating func setFilter(_ filter: Filter, _ title: String? = nil) {
        currentFilter = filter
        if let markerName = title {
            currentMarker = getSelectedMarker(with: markerName)
        }
    }
    
    func getFilteredClips() -> [Clip] {
        if currentFilter == .noFilter {
            return clips.lazy.filter { $0.isReset }
        }
        else if currentFilter == .selected {
            return clips.lazy.filter { $0.isSelected }
        }
        else {
            return clips.lazy.filter{ $0.marker.id == currentMarker.id }
        }
    }
    
    func getFilterList() -> [ActionTitleData] {
        var result = [ActionTitleData]()
        
        for marker in getFilterMarkers() {
            var actionTitleItem : ActionTitleData!
            if currentFilter == .marker {
                actionTitleItem = ActionTitleData(actionImage: marker.type.actionImage, imgTintColor: Constant.Color.red, isChecked: currentMarker.id == marker.id, title: marker.name)
            } else {
                actionTitleItem = ActionTitleData(actionImage: marker.type.actionImage, imgTintColor: Constant.Color.red, isChecked: false, title: marker.name)
            }
            result.append(actionTitleItem)
        }
        result.append(ActionTitleData(actionImage: nil, imgTintColor: nil, isChecked: currentFilter == .selected, title: Filter.selected.rawValue))
        result.append(ActionTitleData(actionImage: nil, imgTintColor: nil, isChecked: currentFilter == .noFilter, title: Filter.noFilter.rawValue))
        
        return result
    }
    
    func getFilterMarkers() -> [Marker] {
        var result = [Marker]()
        
        for clip in clips {
            let isContain = result.map { $0.id }.contains(clip.marker.id)
            if !isContain {
                result.append(clip.marker)
            }
        }
        
        return result
    }
    
}
