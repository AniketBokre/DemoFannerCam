//
//  FanGenerationService.swift
//  NewFannerCam
//
//  Created by Jin on 2/5/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import UIKit
import AVFoundation

typealias SelectedMatch = (match: Match, index: Int)

class FanGenerationService {
    
//MARK: - Properties
    var selectedMatch           : SelectedMatch!
    var fanGenMode              = FanGenMode.record
    
    // Private properties
    private var currentMainVideoIndex       : Int!
    private var currentMainVideo    : MainVideo! {
        if fanGenMode == .record {
            return selectedMatch.match.mainVideos.last
        } else {
            return selectedMatch.match.mainVideos[currentMainVideoIndex]
        }
    }
    
    private var newClips             = [Clip]()

//MARK: - Init Functions
    init(_ match: SelectedMatch, _ mode: FanGenMode, _ mainVideoIndex: Int? = nil) {
        selectedMatch = match
        fanGenMode = mode
        if mainVideoIndex != nil {
            currentMainVideoIndex = mainVideoIndex
        }
    }
    
//MARK: - Private functions
    func saveAction() {
        DataManager.shared.updateMatches(selectedMatch.match, selectedMatch.index, .replace)
    }
    
//MARK: - Generation Functions
    // Main video Generation
    func createNewMainVideo(_ timeScale: Int32 = CMTIMESCALE, _ isCameraChanged : Bool = false) -> URL {
        if isCameraChanged {
            refreshSelectedMatch()
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.isSwiped = false
        }
        let new = MainVideo(selectedMatch.match.id, selectedMatch.match.newMainVideoStartTime(timeScale), selectedMatch.match.scoreboardSetting.period)
        selectedMatch.match.update(newMainVideo: new, updater: .new, index: selectedMatch.match.lastMainVideoIndex())
        saveAction()
        return new.filePath()
    }
    
    // Goal Generation
    func setGoals(_ time: CMTime, _ scoreNum: Int, _ team: Team) -> SelectedMatch {
        let newScore = Score(currentMainVideo.startTime, time, scoreNum, currentMainVideo.fileName, team)
        
        selectedMatch.match.update(newScore: newScore, updater: .new, index: selectedMatch.match.lastScoreIndex())
        if fanGenMode == .mainVideo {
            selectedMatch.match.sortScores()
        }
        saveAction()
        return selectedMatch
    }
    
    func undoGoal(_ team: Team) -> Bool {
        var scoresForTeam = selectedMatch.match.scores.filter { $0.team == team }
        if scoresForTeam.count > 0 {
            let undoScore = scoresForTeam.popLast()
            let index = selectedMatch.match.scores.firstIndex { $0.id == undoScore!.id }
            selectedMatch.match.update(newScore: undoScore!, updater: .delete, index: index!)
            saveAction()
            if scoresForTeam.count > 0 {
                return true
            } else {
                return false
            }
        } else {
            return false
        }
    }
    
    func checkScoreUndoAvailable() -> (f: Bool, s: Bool) {
        let fScores = selectedMatch.match.scores.filter { $0.team == .first }
        let sScores = selectedMatch.match.scores.filter { $0.team == .second }
        if fScores.count > 0 {
            if sScores.count > 0 {
                return (f: true, s: true)
            } else {
                return (f: true, s: false)
            }
        } else {
            if sScores.count > 0 {
                return (f: false, s: true)
            } else {
                return (f: false, s: false)
            }
        }
    }
    
    // Clip Generation
    func didTapMarker(_ currentTime: CMTime, _ type: FanGenMarker, _ team: Team, _ countPressed: Int, _ isPost: Bool = false) {
        var new : Clip!
        
        if type == .generic {
            var settingMarker = DataManager.shared.settingsMarkers[type.markerType.rawValue]![0]
            
            if countPressed > 1 {
                settingMarker.set(Float64(countPressed))
            }
            
            new = Clip(currentTime, currentMainVideo.fileName, currentMainVideo.startTime, currentMainVideo.matchName, team, currentMainVideo.period, settingMarker, false, isPost, nil)
            
            saveNewClip(new)
        } else {
            new = Clip(currentTime, currentMainVideo.fileName, currentMainVideo.startTime, currentMainVideo.matchName, team, currentMainVideo.period, nil, false, isPost, nil)
        }
        
        newClips.append(new)
    }
    
    func setNewClipMarker(_ marker: Marker, _ countPressed: Int) {
        if var new = newClips.last {
            new.set(marker: marker)
            newClips[newClips.count - 1] = new
            
            if new.marker.type == .collective {
                if countPressed > 1 {
                    new.set(duration: Float64(countPressed))
                }
                saveNewClip(new)
            }
        }
    }
    
    func setNewClipTag(_ tagNum: String, _ countPressed: Int) {
        if let num = Int(tagNum), var new = newClips.last {
            new.set(tagNumber: num)
            
            if countPressed > 1 {
                new.set(duration: Float64(countPressed))
            }
            
            newClips[newClips.count - 1] = new
            
            saveNewClip(new)
        }
    }
    
    func saveNewClip(_ newClip: Clip) {
        var new = newClip
        
        if fanGenMode == .mainVideo {
            new.reset()
        }
        
        selectedMatch.match.update(newClip: new, updater: .new)
        
        if fanGenMode == .mainVideo {
            selectedMatch.match.sortClips()
        }
        
        saveAction()
    }
    
//MARK: - Other functions
    func resetAllNewClips() {
        for clip in newClips {
            if clip.marker != nil{
                var temp = clip
                temp.reset()
                selectedMatch.match.update(newClip: temp, updater: .replace)
            }
        }
        saveAction()
    }
    
    func undoAction() -> Bool {
        if let lastOne = newClips.popLast() {
            selectedMatch.match.update(newClip: lastOne, updater: .delete)
            saveAction()
            if newClips.count == 0 {
                return false
            } else {
                return true
            }
        } else {
            return false
        }
    }
    
    func getLastClipInfo() -> (Marker, Team) {
        return (newClips.last!.marker, newClips.last!.team)
    }
    
    func getFirstTeamMarkers() -> Clip? {
        var currentClip : Clip? = nil
        for clip in newClips {
            if clip.team == Team.first {
                currentClip = clip
            }
        }
        return currentClip
    }
    
    func getSecondTeamMarkers() -> Clip? {
        var currentClip : Clip? = nil
        for clip in newClips {
            if clip.team == Team.second {
                currentClip = clip
            }
        }
        return currentClip
    }
    
    func matchTime(with currentTime: CMTime, by index: Int? = nil) -> String {
        if let indexNum = index {
            let currentMatchTime = selectedMatch.match.matchTime(by: indexNum) + CMTimeGetSeconds(currentTime)
            return "\(Int(currentMatchTime/60))'"
        } else {
            let currentMatchTime = selectedMatch.match.matchTime() + CMTimeGetSeconds(currentTime)
            return "\(Int(currentMatchTime/60))'"
        }
    }
    
    public func refreshSelectedMatch()  {
        let matches = DataManager.shared.matches
        for currentMatch in matches {
            if currentMatch.id == selectedMatch.match.id {
                self.selectedMatch.match = currentMatch                
                break
            }
        }
    }
}
