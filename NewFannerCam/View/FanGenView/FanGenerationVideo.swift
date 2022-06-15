//
//  FanGenerationVideoView.swift
//  NewFannerCam
//
//  Created by Jin on 1/21/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import Foundation
import UIKit

enum FanGenMode {
    case record
    case importVideo
    case video
    case mainVideo
}

protocol FanGenerationVideoDataSource: class {
    func fanGenerationVideoMode() -> FanGenMode
    func fanGenScoreValue(_ fanGenerationVideo: FanGenerationVideo, _ team: Team) -> Int?
    
    func numberOfTags(in fanGenerationVideo: FanGenerationVideo) -> Int
    func fanGenerationVideo(_ fanGenerationVideo: FanGenerationVideo, tagCellAt index: Int) -> Marker
}

protocol FanGenerationVideoDelegate: class {
    func didTapMarker(_ markerView: MarkersView, _ marker: UIButton, _ type: FanGenMarker, _ team: Team, _ countPressed: Int)
    func didTapMarker(_ type: FanGenMarker, _ team: Team, _ countPressed: Int)
    func didTapGoal(_ fanGenerationVideo: FanGenerationVideo, goals value: String, team: Team)
    func undoScore(_ fanGenVideo: FanGenerationVideo, team: Team)
    func didTapScoreboard(_ fanGenerationVideo: FanGenerationVideo)
    func didSaveScoreboardSetting(_ period: String?, _ point1: String?, _ point2: String?, _ point3: String?)
    
    func fanGenerationVideo(_ fanGenerationVideo: FanGenerationVideo, didSelectTagAt index: Int, _ type: FanGenMarker, _ countPressed: Int)
    func fanGenerationVideo(_ fanGenerationVideo: FanGenerationVideo, heightForTagViewAt index: Int) -> CGFloat
    func fanGenerationVideo(_ fanGenerationVideo: FanGenerationVideo, didClickedTagSave button: UIButton, tagNum value: String, countPressed: Int)
}

class FanGenerationVideo: UIView {
    
    class func instanceFromNib(_ frame: CGRect) -> FanGenerationVideo {
        let selfView = UINib(nibName: FanGenId.faGenerationVideo, bundle: nil).instantiate(withOwner: self, options: nil)[0] as! FanGenerationVideo
        selfView.frame = frame
        return selfView
    }
    
    func loadView() -> UIView {
        let selfView = UINib(nibName: FanGenId.faGenerationVideo, bundle: nil).instantiate(withOwner: self, options: nil)[0] as! UIView
        return selfView
    }
    
//MARK: - IBOutlets
    @IBOutlet weak var middleView                   : UIView!
    @IBOutlet weak var gridView                     : UIView!
    
    // score points views
    @IBOutlet weak var ffscoreBtn                   : UIButton!
    @IBOutlet weak var fsscoreBtn                   : UIButton!
    @IBOutlet weak var ftscoreBtn                   : UIButton!
    @IBOutlet weak var fScoreUndoBtn                : UIButton!
    
    @IBOutlet weak var ffscoreView                   : UIView!
    @IBOutlet weak var fsscoreView                   : UIView!
    @IBOutlet weak var ftscoreView                   : UIView!
    
    @IBOutlet weak var sfscoreView                   : UIView!
    @IBOutlet weak var ssscoreView                   : UIView!
    @IBOutlet weak var stscoreView                   : UIView!
    
    @IBOutlet weak var sfcoreBtn                    : UIButton!
    @IBOutlet weak var ssscoreBtn                   : UIButton!
    @IBOutlet weak var stscoreBtn                   : UIButton!
    @IBOutlet weak var sScoreUndoBtn                : UIButton!
    
    //score board
    @IBOutlet weak var fGoalsLbl                    : UILabel!
    @IBOutlet weak var fPeriodLbl                   : UILabel!
    @IBOutlet weak var fTeamNameLbl                 : UILabel!
    
    @IBOutlet weak var sGoalsLbl                    : UILabel!
    @IBOutlet weak var sTeamNameLbl                 : UILabel!
    @IBOutlet weak var timeMatchLbl                 : UILabel!
    
    // scoreboard setting view
    @IBOutlet weak var scoreboardSettingView        : UIView!
    @IBOutlet weak var periodTF                     : UITextField!
    @IBOutlet weak var scoreTF1                     : UITextField!
    @IBOutlet weak var scoreTF2                     : UITextField!
    @IBOutlet weak var scoreTF3                     : UITextField!
    
    //constraints
    @IBOutlet weak var scoreBtnsHeight              : NSLayoutConstraint!
    @IBOutlet weak var scoreboardHeight             : NSLayoutConstraint!
    
    //gesture Views
    @IBOutlet weak var topLeftView                     : UIView!
    @IBOutlet weak var topRightView                    : UIView!
    @IBOutlet weak var bottomLeftView                  : UIView!
    @IBOutlet weak var bottomRightView                 : UIView!
    @IBOutlet weak var bottomCenterView                : UIView!
    @IBOutlet weak var imgViewImageArchive             : UIImageView!
    
    var imageArchiveSelected1 = -1
    var imageArchiveSelected2 = -1
    
    //@IBOutlet weak var viewLogo                 : UIImageView!
    
//MARK: - properties
    weak var delegate       : FanGenerationVideoDelegate?
    weak var dataSource     : FanGenerationVideoDataSource?
    
    private var genMode             = FanGenMode.record
    
    // sub views
    var markerView          : MarkersView!
    private var tagsView            : TagsView!
    
    private var currentCountPressed : Int!
    
    // access properties
    var isDisplayedSubViews : Bool = false
    
//MARK: - Override function
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
//MARK: - Main functions
    private func onGoalsBtn(on btn: UIButton, team: Team) {
        let value = btn.titleLabel?.text ?? FanGenTitles.empty.rawValue
        set(goalsLbl: value, team)
        delegate?.didTapGoal(self, goals: value, team: team)
    }
    
    private func set(goalsLbl val: String, _ team: Team) {
        func setGoalData(_ lbl: UILabel) {
            var num = Int(lbl.text!) ?? 0
            num += Int(val) ?? 0
            lbl.text = "\(num)"
        }
        
        if team == .first {
            setGoalData(fGoalsLbl)
        } else {
            setGoalData(sGoalsLbl)
        }
    }
    
    private func setEnabled(of btn: UIButton, to val: Bool) {
        btn.isEnabled = val
        btn.alpha = val ? 1 : 0.5
    }
    
}

//MARK: - Access functions
extension FanGenerationVideo {
    
    func setScoreboardUI(withSetting data: ScoreboardSetting, _ period: String?, _ fAbbName: String, _ sAbbName: String) {
        ffscoreBtn.setTitle("\(data.point1)", for: .normal)
        sfcoreBtn.setTitle("\(data.point1)", for: .normal)
        
        fsscoreBtn.setTitle("\(data.point2)", for: .normal)
        ssscoreBtn.setTitle("\(data.point2)", for: .normal)
        
        ftscoreBtn.setTitle("\(data.point3)", for: .normal)
        stscoreBtn.setTitle("\(data.point3)", for: .normal)
        
        if let periodStr = period {
            fPeriodLbl.text = periodStr
        } else {
            fPeriodLbl.text = data.period
        }
        fTeamNameLbl.text = fAbbName
        sTeamNameLbl.text = sAbbName
        
        let tap1 = UITapGestureRecognizer(target: self, action: #selector(leftTopSingleTap(_:)))
        tap1.numberOfTapsRequired = 1
        tap1.numberOfTouchesRequired = 1
        topLeftView.addGestureRecognizer(tap1)
        
        let tap2 = UITapGestureRecognizer(target: self, action: #selector(leftTopDoubleTap(_:)))
        tap2.numberOfTapsRequired = 2
        tap2.numberOfTouchesRequired = 1
        topLeftView.addGestureRecognizer(tap2)
        
        tap1.require(toFail: tap2)
        
        let tap3 = UITapGestureRecognizer(target: self, action: #selector(leftTopSingleTapTwoFinger(_:)))
        tap3.numberOfTapsRequired = 1
        tap3.numberOfTouchesRequired = 2
        topLeftView.addGestureRecognizer(tap3)
        
        let tap4 = UISwipeGestureRecognizer(target: self, action: #selector(leftTopSwipeRightToLeft(gesture:)))
        tap4.direction = .left
        topLeftView.addGestureRecognizer(tap4)
        
        let tap5 = UILongPressGestureRecognizer(target: self, action: #selector(leftTopLongPress(_:)))
        tap5.minimumPressDuration = 1
        topLeftView.addGestureRecognizer(tap5)
        
        let tap6 = UITapGestureRecognizer(target: self, action: #selector(rightTopSingleTap(_:)))
        tap6.numberOfTapsRequired = 1
        tap6.numberOfTouchesRequired = 1
        topRightView.addGestureRecognizer(tap6)
        
        let tap7 = UITapGestureRecognizer(target: self, action: #selector(rightTopDoubleTap(_:)))
        tap7.numberOfTapsRequired = 2
        tap7.numberOfTouchesRequired = 1
        topRightView.addGestureRecognizer(tap7)
        
        tap6.require(toFail: tap7)
        
        let tap8 = UITapGestureRecognizer(target: self, action: #selector(rightTopSingleTapTwoFinger(_:)))
        tap8.numberOfTapsRequired = 1
        tap8.numberOfTouchesRequired = 2
        topRightView.addGestureRecognizer(tap8)
        
        let tap9 = UISwipeGestureRecognizer(target: self, action: #selector(rightTopSwipeRightToLeft(gesture:)))
        tap9.direction = .right
        topRightView.addGestureRecognizer(tap9)
        
        let tap10 = UILongPressGestureRecognizer(target: self, action: #selector(rightTopLongPress(_:)))
        tap10.minimumPressDuration = 1
        topRightView.addGestureRecognizer(tap10)
        
        let tap11 = UITapGestureRecognizer(target: self, action: #selector(bottomCenterSingleTap(_:)))
        tap11.numberOfTapsRequired = 1
        tap11.numberOfTouchesRequired = 1
        bottomCenterView.addGestureRecognizer(tap11)
        
        let tap12 = UITapGestureRecognizer(target: self, action: #selector(bottomCenterDoubleTap(_:)))
        tap12.numberOfTapsRequired = 2
        tap12.numberOfTouchesRequired = 1
        bottomCenterView.addGestureRecognizer(tap12)
        
        tap11.require(toFail: tap12)
        
        let tap13 = UILongPressGestureRecognizer(target: self, action: #selector(bottomCenterLongPress(_:)))
        tap13.minimumPressDuration = 1
        bottomCenterView.addGestureRecognizer(tap13)
        
        let tap14 = UITapGestureRecognizer(target: self, action: #selector(bottomLeftSingleTap(_:)))
        tap14.numberOfTapsRequired = 1
        tap14.numberOfTouchesRequired = 1
        bottomLeftView.addGestureRecognizer(tap14)
//
//        let tap12 = UILongPressGestureRecognizer(target: self, action: #selector(bottomLeftLongPress(_:)))
//        tap12.minimumPressDuration = 1
//        bottomLeftView.addGestureRecognizer(tap12)
//
        let tap15 = UITapGestureRecognizer(target: self, action: #selector(bottomRightSingleTap(_:)))
        tap15.numberOfTapsRequired = 1
        tap15.numberOfTouchesRequired = 1
        bottomRightView.addGestureRecognizer(tap15)
//
//        let tap14 = UILongPressGestureRecognizer(target: self, action: #selector(bottomRightLongPress(_:)))
//        tap14.minimumPressDuration = 1
//        bottomRightView.addGestureRecognizer(tap14)
        
    }
    
    @objc func leftTopSingleTap(_ sender : UITapGestureRecognizer){
        print("left top single tap")
        //let value = btn.titleLabel?.text ?? FanGenTitles.empty.rawValue
        set(goalsLbl: "1", .first)
        delegate?.didTapGoal(self, goals: "1", team: .first)
        //set(goalsLbl: "1", .first)
        //delegate?.didTapGoal(self, goals: "1", team: .first)
    }
    
    @objc func leftTopDoubleTap(_ sender : UITapGestureRecognizer){
        print("left top double tap")
        set(goalsLbl: "2", .first)
        delegate?.didTapGoal(self, goals: "2", team: .first)
    }
    
    @objc func leftTopSingleTapTwoFinger(_ sender : UITapGestureRecognizer){
        print("left top single tap two finger")
        set(goalsLbl: "3", .first)
        delegate?.didTapGoal(self, goals: "3", team: .first)
    }
    
    @objc func leftTopSwipeRightToLeft(gesture: UIGestureRecognizer) {

        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            if swipeGesture.direction == .left {
                if fGoalsLbl.text != "0" {
                    set(goalsLbl: "-1", .first)
                    delegate?.didTapGoal(self, goals: "-1", team: .first)
                }
                print("left top swipe right to left")
            }
        }
    }
    
    @objc func leftTopLongPress(_ sender : UILongPressGestureRecognizer){
        if sender.state == .began {
            print("left top long press")
            if fScoreUndoBtn.isEnabled == true {
                delegate?.undoScore(self, team: .first)
            }
        }
    }
    
    @objc func rightTopSingleTap(_ sender : UITapGestureRecognizer){
        print("right top single tap")
        set(goalsLbl: "1", .second)
        delegate?.didTapGoal(self, goals: "1", team: .second)
    }
    
    @objc func rightTopDoubleTap(_ sender : UITapGestureRecognizer){
        print("right top double tap")
        set(goalsLbl: "2", .second)
        delegate?.didTapGoal(self, goals: "2", team: .second)
    }
    
    @objc func rightTopSingleTapTwoFinger(_ sender : UITapGestureRecognizer){
        print("left top single tap two finger")
        set(goalsLbl: "3", .second)
        delegate?.didTapGoal(self, goals: "3", team: .second)
    }
    
    @objc func rightTopSwipeRightToLeft(gesture: UIGestureRecognizer) {

        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            if swipeGesture.direction == .right {
                if sGoalsLbl.text != "0" {
                    set(goalsLbl: "-1", .second)
                    delegate?.didTapGoal(self, goals: "-1", team: .second)
                }
                
                print("left top swipe right to left")
            }
        }
    }
    
    @objc func rightTopLongPress(_ sender : UILongPressGestureRecognizer){
        if sender.state == .began {
            print("left top long press")
            if sScoreUndoBtn.isEnabled == true {
                delegate?.undoScore(self, team: .second)
            }
        }
    }
    
    @objc func bottomLeftSingleTap(_ sender : UITapGestureRecognizer){
        print("bottom left single tap")
        //self.viewLogo.isHidden = false
        //self.viewLogo.rotate()
        //self.rotateView(targetView: viewLogo, duration: 1.0)
        //self.runSpinAnimation(on: viewLogo, duration: 1.0, rotations: 1, repeatCount: 1)
        NotificationCenter.default.post(name: NSNotification.Name("LogoAnimationNotification"), object: nil)
        delegate?.didTapMarker(FanGenMarker.generic, Team.first, 1)
    }
    
    @objc func bottomLeftLongPress(_ sender : UILongPressGestureRecognizer){
        if sender.state == .began {
            print("bottom left long press")
            
        }
    }
    
    @objc func bottomRightSingleTap(_ sender : UITapGestureRecognizer){
        print("bottom right single tap")
        //self.viewLogo.isHidden = false
        //self.rotateView(targetView: viewLogo, duration: 1.0)
        NotificationCenter.default.post(name: NSNotification.Name("LogoAnimationNotification"), object: nil)
        delegate?.didTapMarker(FanGenMarker.generic, Team.second, 1)
    }
    
    @objc func bottomRightLongPress(_ sender : UILongPressGestureRecognizer){
        if sender.state == .began {
            print("bottom right long press")
        }
    }
    
    @objc func bottomCenterSingleTap(_ sender : UITapGestureRecognizer){
        print("bottom Center single tap")
        let imagesArchive1 = DataManager.shared.imgArchives
        if imageArchiveSelected1 == -1 {
            if imagesArchive1.count > 0 {
                imageArchiveSelected1 =  0
                imgViewImageArchive.isHidden = false
                if imagesArchive1[0].fileName.contains(".gif") {
                     
                    let data = FileManager.default.contents(atPath: imagesArchive1[0].filePath().path)
                    
                    imgViewImageArchive.image = UIImage.gifImageWithData(data!)
                }else {
                imgViewImageArchive.image = UIImage(contentsOfFile: imagesArchive1[0].filePath().path)
                }
            }
        } else {
            if (imageArchiveSelected1 + 1) == imagesArchive1.count {
                imageArchiveSelected1 =  0
                imgViewImageArchive.isHidden = false
                if imagesArchive1[0].fileName.contains(".gif") {
                     
                    let data = FileManager.default.contents(atPath: imagesArchive1[0].filePath().path)
                    
                    imgViewImageArchive.image = UIImage.gifImageWithData(data!)
                }else {
                imgViewImageArchive.image = UIImage(contentsOfFile: imagesArchive1[0].filePath().path)
                }
            } else {
                imageArchiveSelected1 += 1
                imgViewImageArchive.isHidden = false
                if imagesArchive1[imageArchiveSelected1].fileName.contains(".gif") {
                     
                    let data = FileManager.default.contents(atPath: imagesArchive1[imageArchiveSelected1].filePath().path)
                    
                    imgViewImageArchive.image = UIImage.gifImageWithData(data!)
                }else {
                imgViewImageArchive.image = UIImage(contentsOfFile: imagesArchive1[imageArchiveSelected1].filePath().path)
                }
            }
        }
        
    }
    
    @objc func bottomCenterDoubleTap(_ sender : UITapGestureRecognizer){
        print("bottom Center double tap")
        
        let imagesArchive2 = DataManager.shared.imgArchives2
        if imageArchiveSelected2 == -1 {
            if imagesArchive2.count > 0 {
                imageArchiveSelected2 =  0
                imgViewImageArchive.isHidden = false
                if imagesArchive2[0].fileName.contains(".gif") {
                     
                    let data = FileManager.default.contents(atPath: imagesArchive2[0].filePath().path)
                    
                    imgViewImageArchive.image = UIImage.gifImageWithData(data!)
                }else {
                imgViewImageArchive.image = UIImage(contentsOfFile: imagesArchive2[0].filePath().path)
                }
            }
        } else {
            if (imageArchiveSelected2 + 1) == imagesArchive2.count {
                imageArchiveSelected2 =  0
                imgViewImageArchive.isHidden = false
                if imagesArchive2[0].fileName.contains(".gif") {
                     
                    let data = FileManager.default.contents(atPath: imagesArchive2[0].filePath().path)
                    
                    imgViewImageArchive.image = UIImage.gifImageWithData(data!)
                }else {
                    imgViewImageArchive.image = UIImage(contentsOfFile: imagesArchive2[0].filePath().path)
                }
                
            } else {
                imageArchiveSelected2 += 1
                imgViewImageArchive.isHidden = false
                if imagesArchive2[imageArchiveSelected2].fileName.contains(".gif") {
                     
                    let data = FileManager.default.contents(atPath: imagesArchive2[imageArchiveSelected2].filePath().path)
                    
                    imgViewImageArchive.image = UIImage.gifImageWithData(data!)
                }else {
                imgViewImageArchive.image = UIImage(contentsOfFile: imagesArchive2[imageArchiveSelected2].filePath().path)
                }
            }
        }
    }
    
    @objc func bottomCenterLongPress(_ sender : UILongPressGestureRecognizer){
        if sender.state == .began {
            print("bottom center long press")
            imgViewImageArchive.isHidden = true
        }
    }
    
    private func rotateView(targetView: UIView, duration: Double = 1.0) {
        UIView.animate(withDuration: duration, delay: 0.0, options: .curveEaseIn, animations: {
            targetView.transform = targetView.transform.rotated(by: CGFloat(M_PI))
            targetView.transform = targetView.transform.rotated(by: CGFloat(M_PI))
        }) { finished in
            //self.viewLogo.isHidden = true
            //self.rotateView(targetView: targetView, duration: duration)
        }
    }
    
    func runSpinAnimation(on view: UIView?, duration: CGFloat, rotations: CGFloat, repeatCount: Float) {
        view?.isHidden = false
        var rotationAnimation: CABasicAnimation?
        rotationAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotationAnimation?.toValue = NSNumber(value: Float(.pi * 2.0 /* full rotation*/ * rotations * duration))
        rotationAnimation?.duration = CFTimeInterval(duration)
        rotationAnimation?.isCumulative = true
        rotationAnimation?.repeatCount = repeatCount

        view?.layer.add(rotationAnimation!, forKey: "rotationAnimation")
        view?.isHidden = true
    }
    
    func setUndoBtn(enabled: Bool, team: Team) {
        if team == .first {
            fScoreUndoBtn.isEnabled = enabled
            fScoreUndoBtn.alpha = enabled ? 1 : 0.5
        } else {
            sScoreUndoBtn.isEnabled = enabled
            sScoreUndoBtn.alpha = enabled ? 1 : 0.5
        }
    }
    
    func setCurrentMatchTime(_ val: String) {
        timeMatchLbl.text = val
    }
    
    func setGrid(hide: Bool) {
        gridView.isHidden = hide
    }
    
    func setIndColMarkers(hide: Bool) {
        markerView.setIndColMarkerBtns(hide: hide) 
    }
    
    func set(goal val: Int, _ team: Team) {
        if team == .first, fGoalsLbl.text != "\(val)" {
            fGoalsLbl.text = "\(val)"
        } else {
            sGoalsLbl.text = "\(val)"
        }
    }
    
    func setFangenViewElements(enabled val: Bool) {
        markerView.setMarkerBtns(enabled: val)
        
        setEnabled(of: ffscoreBtn, to: val)
        setEnabled(of: fsscoreBtn, to: val)
        setEnabled(of: ftscoreBtn, to: val)
        setEnabled(of: sfcoreBtn, to: val)
        setEnabled(of: ssscoreBtn, to: val)
        setEnabled(of: stscoreBtn, to: val)
    }
    
    func isDisplayedGrid() -> Bool {
        return !gridView.isHidden
    }
    
    func isDisplayedIndColMarkers() -> Bool {
        return !markerView.f_individualBtn.isHidden
    }
    
    func undoAnimation(_ marker: Marker, _ team: Team) {
        markerView.undoMarkerAnimation(marker, team)
    }
    
    // scoreboard setting
    func displayScoreboardSettingView(_ data: ScoreboardSetting) {
//        bringSubviewToFront(scoreboardSettingView)
        scoreboardSettingView.isHidden = false
        scoreTF1.text = "\(data.point1)"
        scoreTF2.text = "\(data.point2)"
        scoreTF3.text = "\(data.point3)"
        periodTF.text = "\(data.period)"
    }
}

//MARK: - IBAction functions
extension FanGenerationVideo {
    
    @IBAction func onScoreBoardSettingBtn(_ sender: UIButton) {
        delegate?.didTapScoreboard(self)
    }
    
    @IBAction func onFTeamGoalBtn(_ sender: UIButton) {
        onGoalsBtn(on: sender, team: .first)
    }
    
    @IBAction func onScoreUndoBtn(_ sender: UIButton) {
        if sender == fScoreUndoBtn {
            delegate?.undoScore(self, team: .first)
        } else {
            delegate?.undoScore(self, team: .second)
        }
    }
    
    @IBAction func onSTeamGoalBtn(_ sender: UIButton) {
        onGoalsBtn(on: sender, team: .second)
    }
    
    @IBAction func onCloseScoreboardSettingBtn(_ sender: UIButton) {
        scoreboardSettingView.isHidden = true
        delegate?.didSaveScoreboardSetting(nil, nil, nil, nil)
    }
    
    @IBAction func onSaveScoreboardSettingBtn(_ sender: UIButton) {
        
        let point1 = scoreTF1.text!
        let point2 = scoreTF2.text!
        let point3 = scoreTF3.text!
        let period = periodTF.text!
        
        let checkedStrs = [
            point1, point2, point3, period
        ]
        
        guard ValidationService.validateEmptyStrs(checkedStrs) else {
            MessageBarService.shared.warning("Input all setting information!")
            return
        }
        guard ValidationService.validateStringLength(str: period, lengCount: 4) else {
            MessageBarService.shared.warning("Period text length should be less than 4.")
            return
        }
        guard ValidationService.validateNumSize(compareVal: point1, vVal: 15) else {
            MessageBarService.shared.warning("The 1st score point should be less than 15.")
            return
        }
        guard ValidationService.validateNumSize(compareVal: point2, vVal: 30) else {
            MessageBarService.shared.warning("The 2nd score point should be less than 30.")
            return
        }
        guard ValidationService.validateNumSize(compareVal: point3, vVal: 45) else {
            MessageBarService.shared.warning("The 3rd score point should be less than 45.")
            return
        }
        
        delegate?.didSaveScoreboardSetting(period, point1, point2, point3)        
        scoreboardSettingView.isHidden = true
    }
}

//MARK: - MarkersViewDelegate
extension FanGenerationVideo: MarkersViewDelegate {
    
    func didTap(on view: MarkersView, btn: UIButton, type: FanGenMarker, team: Team, countPressed: Int) {
        
        currentCountPressed = countPressed
        
        delegate?.didTapMarker(view, btn, type, team, countPressed)
        
        if type == .individual || type == .collective {
            DispatchQueue.main.async {
                self.addTagsView()
                self.tagsView.set(type)
                
                if type == .collective{
                    let collectiveData = DataManager.shared.settingsMarkers[ MarkerType.collective.rawValue]
                    let jsonData = try! JSONEncoder().encode(collectiveData)
                    let jsonString = String(data: jsonData, encoding: .utf8)!
                    
                     let messageDict = ["CollectiveData":jsonString]
                    
                    FannerCamWatchKitShared.sendMessageToWatchWithData(message: messageDict) {
                    }
                }
            }
        }
    }
    
}

//MARK: - TagsView delegate & data source
extension FanGenerationVideo: TagsViewDelegate, TagsViewDataSource {
    
    func tagsView(_ tagNumView: TagNumView, didClickedSave button: UIButton, tagNum value: String) {
        delegate?.fanGenerationVideo(self, didClickedTagSave: button, tagNum: value, countPressed: currentCountPressed)
        tagsView.removeFromSuperview()
        isDisplayedSubViews = false
        markerView.markerEndAnimation()
    }
    
    func tagsView(_ tagsView: TagsView, didSelectTagAt index: Int, _ type: FanGenMarker) {
        delegate?.fanGenerationVideo(self, didSelectTagAt: index, type, currentCountPressed)
        if type == .collective {
            
            DispatchQueue.main.async {
                tagsView.removeFromSuperview()
                self.isDisplayedSubViews = false
                self.markerView.markerEndAnimation()
            }
        }
    }
    
    func tagsView(_ tagsView: TagsView, heightForTagViewAt index: Int) -> CGFloat {
        return delegate?.fanGenerationVideo(self, heightForTagViewAt: index) ?? 44
    }
    
    // TagsViewDataSource
    func numberOfTags(in tagView: TagsView) -> Int {
        return dataSource?.numberOfTags(in: self) ?? 0
    }
    
    func tagsView(_ tagsView: TagsView, tagMarkerAt index: Int) -> Marker {
        return (dataSource?.fanGenerationVideo(self, tagCellAt: index))!
    }
    
}

//MARK: - data for UI set functions
extension FanGenerationVideo {
    func initNib() {
        func initData() {
            genMode = dataSource?.fanGenerationVideoMode() ?? FanGenMode.record
            if let fScore = dataSource?.fanGenScoreValue(self, .first) {
                fGoalsLbl.text = "\(fScore)"
            }
            if let sScore = dataSource?.fanGenScoreValue(self, .second) {
                sGoalsLbl.text = "\(sScore)"
            }
        }
        
        func initLayout() {
            markerView = MarkersView.instanceFormNib()
            markerView.delegate = self
            markerView.frame = middleView.bounds
            middleView.addSubview(markerView)
        }
        
        initLayout()
        initData()
        
        //constratins fitting
        func initConstraintForiPad() {
            if UI_USER_INTERFACE_IDIOM() != .phone {
                scoreBtnsHeight.constant = 60
                scoreboardHeight.constant = 50
                let padFont = UIFont.systemFont(ofSize: 18)
                ffscoreBtn.titleLabel?.font = padFont
                fsscoreBtn.titleLabel?.font = padFont
                ftscoreBtn.titleLabel?.font = padFont
                sfcoreBtn.titleLabel?.font = padFont
                ssscoreBtn.titleLabel?.font = padFont
                stscoreBtn.titleLabel?.font = padFont
                
                fGoalsLbl.font = padFont
                fPeriodLbl.font = padFont
                fTeamNameLbl.font = padFont 
                
                sGoalsLbl.font = padFont
                sTeamNameLbl.font = padFont
                timeMatchLbl.font = padFont
            }
        }
        initConstraintForiPad()
    }
    
    func addTagsView() {
        tagsView = TagsView.instanceFromNib()
        tagsView.dataSource = self
        tagsView.delegate = self
        tagsView.frame = bounds
        addSubview(tagsView)
        isDisplayedSubViews = true
    }
}

extension UIView{
    func rotate() {
        let rotation : CABasicAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.toValue = NSNumber(value: Double.pi * 2)
        rotation.duration = 1
        rotation.isCumulative = true
        rotation.repeatCount = 1
        self.layer.add(rotation, forKey: "rotationAnimation")
    }
}

extension FileManager {
    func urls(for directory: FileManager.SearchPathDirectory, skipsHiddenFiles: Bool = true ) -> [URL]? {
        let documentsURL = urls(for: directory, in: .userDomainMask)[0]
        let fileURLs = try? contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil, options: skipsHiddenFiles ? .skipsHiddenFiles : [] )
        return fileURLs
    }
}
