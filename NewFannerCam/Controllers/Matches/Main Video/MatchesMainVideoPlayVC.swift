//
//  MatchesMainVideoPlayVC.swift
//  NewFannerCam
//
//  Created by Jin on 1/6/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import UIKit
import AVFoundation

typealias SelectedMainVideo = (mainVideo: MainVideo, index: Int)

class MatchesMainVideoPlayVC: UIViewController {

    @IBOutlet weak var preview              : UIView!
    @IBOutlet weak var bottomBar            : UIView!
    @IBOutlet weak var togglePlayBtn        : UIButton!
    
    @IBOutlet weak var lTimeLbl             : UILabel!
    @IBOutlet weak var rTimeLbl             : UILabel!
    @IBOutlet weak var progressSlider       : UISlider!
    
    private var avplayerService             : AVPlayerService!
    private var fanGenService               : FanGenerationService!
    private var fanGenView                  : FanGenerationVideo!
    private var selectedMarkerType          : MarkerType = MarkerType.individual
    private var markerTags                  : [Marker] {
        return DataManager.shared.settingsMarkers[selectedMarkerType.rawValue] ?? [Marker]()
    }
    private var isLoaded                    : Bool = false
    
    var selectedMatch                       : SelectedMatch!
    var selectedMainVideo                   : SelectedMainVideo!            // main video play
    var selectedClip                        : Clip!                         // preview clip play
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Utiles.setHUD(true, view, .extraLight, "Configuring player...")
        if selectedClip == nil {
            fanGenService = FanGenerationService(selectedMatch, .mainVideo, selectedMainVideo.index)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !isLoaded {
            configAVPlayer()
            initLayout()
            isLoaded = true
        }
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    
//MARK: - Init functions
    func initLayout() {
        if selectedClip != nil {
            return
        }
        fanGenView = FanGenerationVideo.instanceFromNib(CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height))
        fanGenView.delegate = self
        fanGenView.dataSource = self
        fanGenView.initNib()
        fanGenView.setScoreboardUI(withSetting: selectedMatch.match.scoreboardSetting, selectedMainVideo
            .mainVideo.period, selectedMatch.match.fstAbbName, selectedMatch.match.sndAbbName)
        fanGenView.setCurrentMatchTime(fanGenService.matchTime(with: CMTime.zero, by: selectedMainVideo.index))
        fanGenView.setUndoBtn(enabled: fanGenService.checkScoreUndoAvailable().f, team: .first)
        fanGenView.setUndoBtn(enabled: fanGenService.checkScoreUndoAvailable().s, team: .second)
        fanGenView.topLeftView.isHidden = true
        fanGenView.topRightView.isHidden = true
        fanGenView.bottomLeftView.isHidden = true
        fanGenView.bottomRightView.isHidden = true
        fanGenView.bottomCenterView.isHidden = true
        view.addSubview(fanGenView)
        
        view.bringSubviewToFront(bottomBar)
    }
    
    func configAVPlayer() {
        if selectedClip != nil {
            avplayerService = AVPlayerService(preview, progressSlider, selectedClip.getFilePath(ofMainVideo: true), .part, selectedClip)
        } else {
            avplayerService = AVPlayerService(preview, progressSlider, selectedMainVideo.mainVideo.filePath(), .full)
        }
        
        avplayerService.delegate = self
        avplayerService.initPlayer()
        Utiles.setHUD(false)
    }
    
//MARK: - set layout functions
    
//MARK: - IBAction functions
    @IBAction func onBackBtn(_ sender: UIButton) {
        if avplayerService.isPlaying {
            avplayerService.setPlayer()
            avplayerService = nil
        }
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.myOrientation = .portrait
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onTogglePlayBtn(_ sender: UIButton) {
        avplayerService.setPlayer()
        if avplayerService.isPlaying {
            sender.setImage(Constant.Image.PauseWhite.image, for: .normal)
        } else {
            sender.setImage(Constant.Image.PlayWhite.image, for: .normal)
        }
    }
}

//MARK: - AVPlayerServiceDelegate
extension MatchesMainVideoPlayVC: AVPlayerServiceDelegate {
    
    func onPlayingAMinute(_ currentTime: CMTime) {
        fanGenView.setCurrentMatchTime(fanGenService.matchTime(with: currentTime, by: selectedMainVideo.index))
        
        
    }
    
    func avPlayerService(_ avPlayerService: AVPlayerService, didSlideUp played: String, rest restTime: String) {
        lTimeLbl.text = played
        rTimeLbl.text = restTime
    }
    
    func avPlayerService(didEndPlayVideo avPlayerService: AVPlayerService) {
        togglePlayBtn.setImage(Constant.Image.PlayWhite.image, for: .normal)
    }
    
    func avPlayerServiceSliderValueChanged() {
        if avplayerService != nil {
            var currentVideoTime : CMTime!
            if selectedClip != nil {
                currentVideoTime = selectedClip.getCurrentMatchTime(of: avplayerService.currentPlayerTime())
                return
            } else {
                currentVideoTime = selectedMainVideo.mainVideo.currentVideoTime(avplayerService.currentPlayerTime())
            }
            let fScore = fanGenService.selectedMatch.match.getScoreAt(time: currentVideoTime, of: .first)
            fanGenView.set(goal: fScore, .first)
            let sScore = fanGenService.selectedMatch.match.getScoreAt(time: currentVideoTime, of: .second)
            fanGenView.set(goal: sScore, .second)
        }
    }
}

//MARK: - FanGenerationVideoViewDelegate
extension MatchesMainVideoPlayVC: FanGenerationVideoDelegate, FanGenerationVideoDataSource {
    
    func undoScore(_ fanGenVideo: FanGenerationVideo, team: Team) {
        fanGenVideo.setUndoBtn(enabled: fanGenService.undoGoal(team), team: team)
        let fScore = fanGenService.selectedMatch.match.getScoreAt(of: .first)
        fanGenView.set(goal: fScore, .first)
        let sScore = fanGenService.selectedMatch.match.getScoreAt(of: .second)
        fanGenView.set(goal: sScore, .second)
    }    
    
    func didTapScoreboard(_ fanGenerationVideo: FanGenerationVideo) {
//        fanGenView.displayScoreboardSettingView(fanGenService.selectedMatch.match.scoreboardSetting)
//        view.bringSubviewToFront(fanGenView)
    }
    
    func didTapGoal(_ fanGenerationVideo: FanGenerationVideo, goals value: String, team: Team) {
        guard let scoreNum = Int(value) else { return }
        selectedMatch = fanGenService.setGoals(avplayerService.currentPlayerTime(), scoreNum, team)
        fanGenView.setUndoBtn(enabled: fanGenService.checkScoreUndoAvailable().f, team: .first)
        fanGenView.setUndoBtn(enabled: fanGenService.checkScoreUndoAvailable().s, team: .second)
    }
    
    func didTapMarker(_ markerView: MarkersView, _ marker: UIButton, _ type: FanGenMarker, _ team: Team, _ countPressed: Int) {
        if type == .individual || type == .collective {
            view.bringSubviewToFront(fanGenView)
        }
        selectedMarkerType = type.markerType
        fanGenService.didTapMarker(avplayerService.currentPlayerTime(), type, team, countPressed, true)
    }
    
    func didTapMarker(_ type: FanGenMarker, _ team: Team, _ countPressed: Int) {
        selectedMarkerType = type.markerType
        fanGenService.didTapMarker(avplayerService.currentPlayerTime(), type, team, countPressed, true)
    }
    
    func fanGenerationVideo(_ fanGenerationVideo: FanGenerationVideo, didSelectTagAt index: Int, _ type: FanGenMarker, _ countPressed: Int) {
        fanGenService.setNewClipMarker(markerTags[index], countPressed)
        if type == .collective {
            view.bringSubviewToFront(bottomBar)
        }
    }
    
    func fanGenerationVideo(_ fanGenerationVideo: FanGenerationVideo, heightForTagViewAt index: Int) -> CGFloat {
        return 50
    }
    
    func fanGenerationVideo(_ fanGenerationVideo: FanGenerationVideo, didClickedTagSave button: UIButton, tagNum value: String, countPressed: Int) {
        view.bringSubviewToFront(bottomBar)
        fanGenService.setNewClipTag(value, countPressed)
    }
    
    func didSaveScoreboardSetting(_ period: String?, _ point1: String?, _ point2: String?, _ point3: String?) {
//        if period != nil {
//            let isChanged = fanGenService.selectedMatch.match.scoreboardSetting.set(Int(point1!)!, Int(point2!)!, Int(point3!)!, period!)
//            if isChanged {
//                fanGenService.saveAction()
//                fanGenView.setScoreboardUI(withSetting: fanGenService.selectedMatch.match.scoreboardSetting, selectedMatch.match.fstAbbName, selectedMatch.match.sndAbbName)
//                MessageBarService.shared.notify("Successfully saved changed setting!")
//            } else {
//                MessageBarService.shared.warning("No changed setting")
//            }
//        }
//        view.bringSubviewToFront(bottomBar)
    }
    
    // FanGenerationVideoTagsDataSource
    func fanGenerationVideoMode() -> FanGenMode {
        return .mainVideo
    }
    
    func fanGenScoreValue(_ fanGenerationVideo: FanGenerationVideo, _ team: Team) -> Int? {
        return selectedMatch.match.getScoreAt(time: selectedMainVideo.mainVideo.startTime, of: team)
    }
    
    func numberOfTags(in fanGenerationVideo: FanGenerationVideo) -> Int {
        return markerTags.count
    }
    
    func fanGenerationVideo(_ fanGenerationVideo: FanGenerationVideo, tagCellAt index: Int) -> Marker {
        return markerTags[index]
    }
}
