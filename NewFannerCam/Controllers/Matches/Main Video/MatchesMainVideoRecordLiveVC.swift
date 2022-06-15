//
//  MatchesMainVideoRecordLiveVC.swift
//  NewFannerCam
//
//  Created by Komal on 17/03/21.
//  Copyright © 2021 fannercam3. All rights reserved.
//

import UIKit
import AVFoundation
import AudioToolbox

class MatchesMainVideoRecordLiveVC: UIViewController {
    
    //MARK: - IBOutlets & Properties
    @IBOutlet weak var lfPreview                : UIView!   // LFLivePreview
    @IBOutlet weak var preview                  : UIView!
    @IBOutlet weak var bottomBar                : UIView!
    @IBOutlet weak var videoDurationCenterView  : UIView!
    @IBOutlet weak var viewCircle               : UIView!
    
    @IBOutlet weak var timeLbl                  : UILabel!
    @IBOutlet weak var toggleRecordBtn          : UIButton!
    @IBOutlet weak var exitBtn                  : UIButton!
    @IBOutlet weak var undoBtn                  : UIButton!
    @IBOutlet weak var toggleFlipBtn            : UIButton!
    @IBOutlet weak var zoomFactorBtn            : UIButton!
    @IBOutlet weak var settingBtn               : UIButton!
    @IBOutlet weak var imgFannerView            : UIImageView!
    //@IBOutlet weak var viewLeftTop  : UIView!
    
    // properties
    private var cameraService           : CameraService!
    private var fanGenService           : FanGenerationService!
    private var fanGenView              : FanGenerationVideo!
    private var selectedMarkerType      : MarkerType = MarkerType.individual
    private var isLoaded                : Bool = false
    private var isFrontCamera           : Bool = false
    private var markerTags              : [Marker] {
        return DataManager.shared.settingsMarkers[selectedMarkerType.rawValue] ?? [Marker]()
    }
    
    // live properties
    var output                          : YouTubeLiveVideoOutput!
    var scheduledStartTime              : NSDate?
    private var liveTimer               : Timer!
    private var liveTime                = 0
    
    var selectedMatch                   : SelectedMatch!
    
    var titleForWatch                   : String = ""
    var isRecorded                      : Bool = false
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    
    //MARK: - override functions
    override func viewDidLoad() {
        super.viewDidLoad()
        bottomBar.isHidden = true
        
        //        bottomBar.isHidden = false
        //        undoBtn.isHidden = true
        //        toggleFlipBtn.isHidden = true
        //        settingBtn.isHidden = true
        //        videoDurationCenterView.isHidden = true
        //        zoomFactorBtn.isHidden = true
        //        exitBtn.isHidden = true
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.myOrientation = .landscape
        fanGenService = FanGenerationService(selectedMatch, .record)
        
        
        //        var logoTeam1 : UIImage?
        //        if let img = VideoProcess.loadImg(from: self.selectedMatch.match.matchLogoPath(.first)) {
        //            logoTeam1 = img
        //            imgViewTeam1.image = logoTeam1
        //            imgViewTeam1.isHidden = false
        //
        //        } else {
        //            imgViewTeam1.isHidden = true
        //            //logoTeam1 = Constant.Image.DefaultTeamLogo.image
        //        }
        //
        //        var logoTeam2 : UIImage?
        //        if let img = VideoProcess.loadImg(from: self.selectedMatch.match.matchLogoPath(.second)) {
        //            logoTeam2 = img
        //            imgViewTeam2.image = logoTeam2
        //            imgViewTeam2.isHidden = false
        //        } else {
        //            imgViewTeam2.isHidden = true
        //            //logoTeam2 = Constant.Image.DefaultTeamLogo.image
        //        }
               
        zoomFactorBtn.layer.cornerRadius = zoomFactorBtn.frame.size.height/2
        zoomFactorBtn.layer.borderColor = UIColor.white.cgColor
        zoomFactorBtn.layer.borderWidth = 1.5
        zoomFactorBtn.layer.masksToBounds = true
        
        FannerCamWatchKitShared.sharedManager.delegate =  self
        //as! FannerCamWatchKitSharedDelegate
        
        view.isUserInteractionEnabled = false
        
        Utiles.setHUD(true, view, .extraLight, "Configuring camera...")
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterdBG), name: Notification.Name("enterdBG"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterdFG), name: Notification.Name("enterdFG"), object: nil)
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(animateFannerLogo), name: Notification.Name("LogoAnimationNotification"), object: nil)
        
    }
    
    @objc func animateFannerLogo(){
        imgFannerView.image = UIImage.gifImageWithName("fanner-logo-gift")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.imgFannerView.image = UIImage(named: "fanner_logo")
        }
    }
    
    
    @objc func bottomLeftSingleTap(_ sender : UITapGestureRecognizer){
        print("bottom left single tap")
        //self.viewLogo.isHidden = false
        self.imgFannerView.rotate()
        //self.rotateView(targetView: viewLogo, duration: 1.0)
        //self.runSpinAnimation(on: viewLogo, duration: 1.0, rotations: 1, repeatCount: 1)
    }
    
    @objc func bottomLeftLongPress(_ sender : UILongPressGestureRecognizer){
        if sender.state == .began {
            print("bottom left long press")
            if self.cameraService.isRecording {
                if self.fanGenService.getFirstTeamMarkers() == nil {
                    return
                }
                MessageBarService.shared.alertQuestion(title: "Warning!", message: "Are you sure you want to remove the last clip?", yesString: "Yes", noString: "No", onYes: { (yesAction) in
                    if let currentclip = self.fanGenService.getFirstTeamMarkers()  {
                        //self.fanGenView.undoAnimation(currentclip.marker, currentclip.team)
                        self.setUndoBtnEnabled(self.fanGenService.undoAction())
                    }
                }, onNo: nil)
            }
        }
    }
    
    @objc func bottomRightSingleTap(_ sender : UITapGestureRecognizer){
        print("bottom right single tap")
        //self.viewLogo.isHidden = false
        self.imgFannerView.rotate()
    }
    
    @objc func bottomRightLongPress(_ sender : UILongPressGestureRecognizer){
        if sender.state == .began {
            print("bottom right long press")
            if self.cameraService.isRecording {
                if self.fanGenService.getSecondTeamMarkers() == nil {
                    return
                }
                MessageBarService.shared.alertQuestion(title: "Warning!", message: "Are you sure you want to remove the last clip?", yesString: "Yes", noString: "No", onYes: { (yesAction) in
                    if let currentclip = self.fanGenService.getSecondTeamMarkers()  {
                        //self.fanGenView.undoAnimation(currentclip.marker, currentclip.team)
                        self.setUndoBtnEnabled(self.fanGenService.undoAction())
                    }
                    
                }, onNo: nil)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let matches = DataManager.shared.matches
        for currentMatch in matches {
            if currentMatch.id == selectedMatch.match.id {
                selectedMatch.match = currentMatch
                break
            }
        }
        isControllerActive = true
        //        DispatchQueue.main.async {
        //            if self.isLiveMatch() {
        //                self.lfPreview.prepareForUsing()
        //            }
        //        }
        // Setting the Title
        let messageDict : [String:Any] = ["isStart":false, "Time": self.timeLbl.text ?? "", "Title":titleForWatch, "StartDate":Date()]
        FannerCamWatchKitShared.sendMessageToWatchWithData(message: messageDict) {}
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !isLoaded {
            if !isLiveMatch() {
                configCamera()
            } else {
                preview.isHidden = true
                perform(#selector(self.setEnabledElements), with: nil, afterDelay: 1.0)
                Utiles.setHUD(false)
            }
            initLayout()
            isLoaded = true
            self.view.isUserInteractionEnabled = true
        }
        
    }
    
    @objc func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            
            switch swipeGesture.direction {
            case .right:
                
                if !cameraService.isRecording {
                    print("Swiped right")
                }
            case .down:
                print("Swiped down")
            case .left:
                
                if !cameraService.isRecording {
                    print("Swiped left")
                }
            case .up:
                print("Swiped up")
            default:
                break
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cameraService.removeAddedInputs()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if !isLiveMatch() {
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVCaptureDeviceSubjectAreaDidChange, object: cameraService.currentCameraInput!.device)
        }
        isControllerActive = false
        let messageDict : [String:Any] = ["isStart":false,"isControllerActive":false]
        FannerCamWatchKitShared.sendMessageToWatchWithData(message: messageDict) {}
    }
    
    override var shouldAutorotate: Bool {
        if cameraService != nil && cameraService.isRecording {
            return false
        }else{
            return true
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        if UIDevice.current.orientation.isLandscape{
            cameraService.updatePreviewOrientation()
        }
    }
    
    //    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    //        let touchPer = touchPercent(touch: touches.first! as UITouch)
    //        cameraService.updateDeviceSettings(focusValue: Float(touchPer.x), isoValue: Float(touchPer.y))
    //    }
    //
    //    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    //        let touchPer = touchPercent(touch: touches.first! as UITouch)
    //        cameraService.updateDeviceSettings(focusValue: Float(touchPer.x), isoValue: Float(touchPer.y))
    //    }
    
    //     func supportedInterfaceOrientations() -> Int {
    //        print("supportedInterfaceOrientations")
    //        return Int(UIInterfaceOrientationMask.landscapeLeft.rawValue)
    //    }
    //
    //     func preferredInterfaceOrientationForPresentation() -> UIInterfaceOrientation {
    //        return UIInterfaceOrientation.landscapeLeft
    //    }
    
    //MARK: - init functions
    
    func initLayout() {
        fanGenView = FanGenerationVideo.instanceFromNib(CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height))
        fanGenView.delegate = self
        fanGenView.dataSource = self
        fanGenView.initNib()
        fanGenView.setScoreboardUI(withSetting: selectedMatch.match.scoreboardSetting, nil, selectedMatch.match.fstAbbName, selectedMatch.match.sndAbbName)
        fanGenView.setCurrentMatchTime(fanGenService.matchTime(with: CMTime.zero))
        fanGenView.setUndoBtn(enabled: fanGenService.checkScoreUndoAvailable().f, team: .first)
        fanGenView.setUndoBtn(enabled: fanGenService.checkScoreUndoAvailable().s, team: .second)
        fanGenView.ffscoreBtn.isHidden = true
        fanGenView.fsscoreBtn.isHidden = true
        fanGenView.ftscoreBtn.isHidden = true
        fanGenView.fScoreUndoBtn.isHidden = true
        fanGenView.sfcoreBtn.isHidden = true
        fanGenView.ssscoreBtn.isHidden = true
        fanGenView.stscoreBtn.isHidden = true
        fanGenView.sScoreUndoBtn.isHidden = true
        fanGenView.ffscoreView.isHidden = true
        fanGenView.fsscoreView.isHidden = true
        fanGenView.ftscoreView.isHidden = true
        fanGenView.sfscoreView.isHidden = true
        fanGenView.ssscoreView.isHidden = true
        fanGenView.stscoreView.isHidden = true
        fanGenView.markerView.f_genericBtn.isHidden = true
        fanGenView.markerView.f_individualBtn.isHidden = true
        fanGenView.markerView.f_collectiveBtn.isHidden = true
        fanGenView.markerView.s_genericBtn.isHidden = true
        fanGenView.markerView.s_individualBtn.isHidden = true
        fanGenView.markerView.s_collectiveBtn.isHidden = true
        fanGenView.fPeriodLbl.isHidden = true
        fanGenView.timeMatchLbl.isHidden = true
        fanGenView.topLeftView.isHidden = false
        fanGenView.topRightView.isHidden = false
        fanGenView.bottomLeftView.isHidden = false
        fanGenView.bottomRightView.isHidden = false
        fanGenView.bottomCenterView.isHidden = false
        fanGenView.bottomLeftView.isUserInteractionEnabled = false
        fanGenView.bottomRightView.isUserInteractionEnabled = false
        fanGenView.topLeftView.isUserInteractionEnabled = false
        fanGenView.topRightView.isUserInteractionEnabled = false
        
        validatesLayouts()
        view.addSubview(fanGenView)
        view.bringSubviewToFront(fanGenView)
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(focusTap(gesture:)))
        fanGenView.addGestureRecognizer(gesture)
        
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(self.handlePinchToZoomRecognizer(pinchRecognizer:) ))
        pinchGesture.delegate = self
        fanGenView.addGestureRecognizer(pinchGesture)
        
        view.bringSubviewToFront(bottomBar)
        
        //        let tap11 = UITapGestureRecognizer(target: self, action: #selector(bottomLeftSingleTap(_:)))
        //        tap11.numberOfTapsRequired = 1
        //        tap11.numberOfTouchesRequired = 1
        //            fanGenView.bottomLeftView.addGestureRecognizer(tap11)
        
        let tap12 = UILongPressGestureRecognizer(target: self, action: #selector(bottomLeftLongPress(_:)))
        tap12.minimumPressDuration = 1
        fanGenView.bottomLeftView.addGestureRecognizer(tap12)
        
        //        let tap13 = UITapGestureRecognizer(target: self, action: #selector(bottomRightSingleTap(_:)))
        //        tap13.numberOfTapsRequired = 1
        //        tap13.numberOfTouchesRequired = 1
        //        fanGenView.bottomRightView.addGestureRecognizer(tap13)
        
        let tap14 = UILongPressGestureRecognizer(target: self, action: #selector(bottomRightLongPress(_:)))
        tap14.minimumPressDuration = 1
        fanGenView.bottomRightView.addGestureRecognizer(tap14)
        
        let tap15 = UISwipeGestureRecognizer(target: self, action: #selector(bottomCenterSwipe(gesture:)))
        //tap15.direction = .right
        fanGenView.bottomCenterView.addGestureRecognizer(tap15)
        
        self.view.bringSubviewToFront(toggleRecordBtn)
        self.view.bringSubviewToFront(viewCircle)
        self.view.bringSubviewToFront(imgFannerView)
        
    }
    
    @objc func bottomCenterSwipe(gesture: UIGestureRecognizer) {
        
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            if swipeGesture.direction == .left || swipeGesture.direction == .right {
                print("bottom center swipe left or right")
                if !cameraService.isRecording {
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    appDelegate.myOrientation = .landscape
                    if (isRecorded)
                    {
                        self.appDelegate.isSwiped = true
                        isRecorded = false
                    }
                    dismiss(animated: true, completion: nil)
                }
            }
        }
    }
    
    // in recording mode
    func configCamera() {
        
        cameraService = CameraService(preview, timeLbl, selectedMatch.match.isResolution1280)
        cameraService.delegate = self
        
        cameraService.checkDeviceAuthorizationStatus { (isGranted, error) in
            if isGranted {
                self.cameraService.prepare(isFrontCamera: self.isFrontCamera, completionHandler: { (errorStr) in
                    if let err = errorStr {
                        MessageBarService.shared.error(err.localizedDescription)
                    } else {
                        do {
                            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVCaptureDeviceSubjectAreaDidChange, object: self.cameraService.currentCameraInput!.device)
                            try self.cameraService.displayPreview()
                            NotificationCenter.default.addObserver(self, selector: #selector(self.subjectAreaDidChange(notification:)), name: NSNotification.Name.AVCaptureDeviceSubjectAreaDidChange, object: self.cameraService.currentCameraInput!.device)
                            self.lfPreview.isHidden = true
                        } catch {
                            MessageBarService.shared.error(error.localizedDescription)
                        }
                    }
                    Utiles.setHUD(false)
                    self.perform(#selector(self.setEnabledElements), with: nil, afterDelay: 1.0)
                })
            } else {
                MessageBarService.shared.error(error)
                Utiles.setHUD(false)
            }
        }
    }
    
    @objc func setEnabledElements() {
        view.isUserInteractionEnabled = true
    }
    
    @objc func subjectAreaDidChange(notification: NSNotification) {
        cameraService.subjectAreaDidChange(notification: notification)
    }
    
    @objc func handlePinchToZoomRecognizer(pinchRecognizer: UIPinchGestureRecognizer) {
        bottomBar.isHidden = false
        undoBtn.isHidden = true
        toggleFlipBtn.isHidden = true
        settingBtn.isHidden = true
        videoDurationCenterView.isHidden = true
        zoomFactorBtn.isHidden = false
        exitBtn.isHidden = true
        if !fanGenView.isDisplayedSubViews {
            let pinchVelocityDividerFactor : Float = 50.0
            
            if pinchRecognizer.state == UIGestureRecognizer.State.changed {
                cameraService.pinchToZoom(pinchRecognizer, pinchVelocityDividerFactor)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.bottomBar.isHidden = true
                }
            }
        }
    }
    
    //MARK: - set layout functions
    func validatesLayouts() {
        if isLiveMatch() {
            exitBtn.isEnabled = liveTimer == nil
            fanGenView.setFangenViewElements(enabled: !exitBtn.isEnabled)
        } else {
            fanGenView.setFangenViewElements(enabled: cameraService.isRecording)
            exitBtn.isEnabled = !cameraService.isRecording
        }
        exitBtn.alpha = exitBtn.isEnabled ? 1 : 0.5
    }
    
    func setUndoBtnEnabled(_ val: Bool) {
        DispatchQueue.main.async {
            self.undoBtn.isEnabled = val
            self.undoBtn.alpha = 0
        }
    }
    
    func setToggleBtnImage(isStarted: Bool) {
        
        if isStarted == true {
            viewCircle.backgroundColor = UIColor.red
            fanGenView.bottomLeftView.isUserInteractionEnabled = true
            fanGenView.bottomRightView.isUserInteractionEnabled = true
            fanGenView.topLeftView.isUserInteractionEnabled = true
            fanGenView.topRightView.isUserInteractionEnabled = true
        } else {
            viewCircle.backgroundColor = UIColor.white
            fanGenView.bottomLeftView.isUserInteractionEnabled = false
            fanGenView.bottomRightView.isUserInteractionEnabled = false
            fanGenView.topLeftView.isUserInteractionEnabled = false
            fanGenView.topRightView.isUserInteractionEnabled = false
        }
        
        //let image = isStarted ? Constant.Image.ToggleStop.image : Constant.Image.ToggleRecord.image
        //toggleRecordBtn.setBackgroundImage(image, for: .normal)
    }
    
    //MARK: - main fucntions
    func isLiveMatch() -> Bool {
        return selectedMatch.match.type == .liveMatch
    }
    
    func startRecording() {
        DispatchQueue.main.async{
            Utiles.setHUD(true, self.view, .extraLight, "Release recording...")
            self.toggleRecordBtn.isEnabled = false
            self.toggleFlipBtn.isEnabled = false
            self.isRecorded = true
            self.cameraService.startRecording(self.fanGenService.createNewMainVideo(CMTIMESCALE, self.appDelegate.isSwiped))
        }
    }
    
    func stopRecording() {
        DispatchQueue.main.async {
            Utiles.setHUD(true, self.view, .extraLight, "Saving recorded video...")
            
            if self.cameraService.isRecording {
                self.cameraService.stopRecording()
            }
            self.toggleFlipBtn.isEnabled = true
            self.toggleRecordBtn.isEnabled = false
        }
    }
    
    // LIVE
    func startStreaming() {
        Utiles.setHUD(true, view, .extraLight, "Release a streaming...")
        toggleRecordBtn.isEnabled = false
        
        //        output?.startPublishing() { streamURL, streamName in
        //            if let streamURL = streamURL, let streamName = streamName {
        //                let streamUrl = "\(streamURL)/\(streamName)"
        //                self.lfPreview.startPublishing(withStreamURL: streamUrl, localVideoPath: self.fanGenService.createNewMainVideo(CMTIMESCALE))
        //            }
        //        }
    }
    
    func stopStreaming() {
        Utiles.setHUD(true, view, .extraLight, "Saving streamed video...")
        toggleRecordBtn.isEnabled = false
        
        //        lfPreview.stopPublishing()
        output?.finishPublishing()
        
        if liveTimer != nil {
            liveTimer.invalidate()
            liveTimer = nil
            liveTime = 0
            
        }
        
        validatesLayouts()
        setToggleBtnImage(isStarted: false)
        perform(#selector(endStreamingReaction), with: nil, afterDelay: 1.0)
    }
    
    @objc func liveTimerAction() {
        liveTime += 1
        let timeNow = String( format :"%02d:%02d:%02d", liveTime/3600, (liveTime%3600)/60, liveTime%60)
        self.timeLbl.text = timeNow
        
        print("By liveTimerAction")
    }
    
    @objc func endStreamingReaction() {
        Utiles.setHUD(false)
        toggleRecordBtn.isEnabled = true
    }
    
    func touchPercent(touch : UITouch) -> CGPoint {
        // Get the dimensions of the screen in points
        let screenSize = UIScreen.main.bounds.size
        
        // Create an empty CGPoint object set to 0, 0
        var touchPer = CGPoint.zero
        
        // Set the x and y values to be the value of the tapped position, divided by the width/height of the screen
        touchPer.x = touch.location(in: self.view).x / screenSize.width
        touchPer.y = touch.location(in: self.view).y / screenSize.height
        
        // Return the populated CGPoint
        return touchPer
    }
    
    //MARK: - IBActions
    
    @objc func focusTap(gesture: UIGestureRecognizer) {
        if !fanGenView.isDisplayedSubViews, !isLiveMatch() {
            cameraService.focusAndExposeTap(gestureRecognizer: gesture)
        }
    }
    
    @IBAction func onToggleRecordBtn(_ sender: UIButton) {
        if isLiveMatch() {
            if sender.isSelected {
                sender.isSelected = false
                fanGenView.bottomLeftView.isUserInteractionEnabled = false
                fanGenView.bottomRightView.isUserInteractionEnabled = false
                fanGenView.topLeftView.isUserInteractionEnabled = false
                fanGenView.topRightView.isUserInteractionEnabled = false
                stopStreaming()
            } else {
                sender.isSelected = true
                fanGenView.bottomLeftView.isUserInteractionEnabled = true
                fanGenView.bottomRightView.isUserInteractionEnabled = true
                fanGenView.topLeftView.isUserInteractionEnabled = true
                fanGenView.topRightView.isUserInteractionEnabled = true
                startStreaming()
            }
        } else {
            if cameraService.isRecording {
                viewCircle.backgroundColor = UIColor.white
                fanGenView.bottomLeftView.isUserInteractionEnabled = false
                fanGenView.bottomRightView.isUserInteractionEnabled = false
                fanGenView.topLeftView.isUserInteractionEnabled = false
                fanGenView.topRightView.isUserInteractionEnabled = false
                stopRecording()
                // For watch Need to call here
                // let sendingData: [String : [String : Any]] = ["Data" : ["message":"Get + stopRecording", "Time":self.timeLbl.text ?? "", "Title":"AA:BB"]]
                DispatchQueue.main.async {
                    let messageDict : [String:Any] = ["isStart":false, "Time": self.timeLbl.text ?? "", "Title":self.titleForWatch, "StartDate":Date()]
                    FannerCamWatchKitShared.sendMessageToWatchWithData(message: messageDict) {}
                    print("Call  StopRecording")
                }
                if isControllerActive == true {
                    let messageDict : [String:Any] = ["isStart":false]
                    FannerCamWatchKitShared.sendMessageToWatchWithData(message: messageDict) {}
                }
            } else {
                viewCircle.backgroundColor = UIColor.red
                fanGenView.bottomLeftView.isUserInteractionEnabled = true
                fanGenView.bottomRightView.isUserInteractionEnabled = true
                fanGenView.topLeftView.isUserInteractionEnabled = true
                fanGenView.topRightView.isUserInteractionEnabled = true
                startRecording()
                //  let sendingData: [String : [String : Any]] = ["Data" : ["message":"Get+startRecording", "Time":self.timeLbl.text ?? "", "Title":"AA:BB"]]
                DispatchQueue.main.async {
                    let messageDict : [String:Any] = ["isStart":true, "Time": self.timeLbl.text ?? "", "Title":self.titleForWatch, "StartDate":Date()]
                    FannerCamWatchKitShared.sendMessageToWatchWithData(message: messageDict) {}
                }
                print("Call StartRecording")
                if isControllerActive == true {
                    let messageDict : [String:Any] = ["isStart":true]
                    FannerCamWatchKitShared.sendMessageToWatchWithData(message: messageDict) {}
                }
            }
            //            if isControllerActive == true {
            //                if cameraService.isRecording {
            //                    let messageDict : [String:Any] = ["isStart":true]
            //                    FannerCamWatchKitShared.sendMessageToWatchWithData(message: messageDict) {}
            //                } else {
            //                    let messageDict : [String:Any] = ["isStart":false]
            //                    FannerCamWatchKitShared.sendMessageToWatchWithData(message: messageDict) {}
            //                }
            //                print(5)
            //            }
        }
    }
    
    @IBAction func onSettingBtn(_ sender: UIButton) {
        let sheetController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        sheetController.modalPresentationStyle = .popover
        
        let gridAction = UIAlertAction(title: ActionTitle.grid.rawValue, style: .default, handler: { (gridAction) in
            self.fanGenView.setGrid(hide: self.fanGenView.isDisplayedGrid() ? true : false)
        })
        gridAction.setValue(fanGenView.isDisplayedGrid(), forKey: SheetKeys.isChecked.rawValue)
        sheetController.addAction(gridAction)
        
        let sndAction = UIAlertAction(title: ActionTitle.indiCollMarkers.rawValue, style: .default, handler: { (incolMarkerAction) in
            self.fanGenView.setIndColMarkers(hide: self.fanGenView.isDisplayedIndColMarkers() ? true : false)
        })
        
        sndAction.setValue(fanGenView.isDisplayedIndColMarkers(), forKey: SheetKeys.isChecked.rawValue)
        sheetController.addAction(sndAction)
        
        let trdAction = UIAlertAction(title: ActionTitle.autoFocus.rawValue, style: .default) { (focusAction) in
            self.cameraService.autoFocus = !self.cameraService.autoFocus
            self.cameraService.changeAutoFocus()
        }
        
        trdAction.setValue(cameraService.autoFocus, forKey: SheetKeys.isChecked.rawValue)
        sheetController.addAction(trdAction)
        sheetController.addAction(UIAlertAction(title: ActionTitle.cancel.rawValue, style: .cancel, handler: nil))
        if let presenter = sheetController.popoverPresentationController {
            presenter.sourceView = sender
            presenter.sourceRect = sender.bounds
        }
        present(sheetController, animated: true, completion: nil)
    }
    
    @IBAction func onUndoBtn(_ sender: UIButton) {
        MessageBarService.shared.alertQuestion(title: "Warning!", message: "Are you sure you want to remove the last clip?", yesString: "Yes", noString: "No", onYes: { (yesAction) in
            let (undoMarker, undoTeam) = self.fanGenService.getLastClipInfo()
            self.fanGenView.undoAnimation(undoMarker, undoTeam)
            self.setUndoBtnEnabled(self.fanGenService.undoAction())
        }, onNo: nil)
    }
    
    @IBAction func onBackBtn(_ sender: Any) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.myOrientation = .landscape
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onFlipCameraBtn(_ sender: Any) {
        if !isLiveMatch(){
            Utiles.setHUD(true, view, .extraLight, "Load camera...")
            isFrontCamera = !isFrontCamera
            self.cameraService.removeAddedInputs()
            configCamera()
        }
    }
}

//MARK: - UIGestureRecognizerDelegate

extension MatchesMainVideoRecordLiveVC: UIGestureRecognizerDelegate {
    
}

//MARK: - CameraServiceDelegate

extension MatchesMainVideoRecordLiveVC: CameraServiceDelegate {
    
    func onChangeZoomFactor(_ zoomFactor: CGFloat?) {
        guard zoomFactor == nil else {
            var zoomvalue : CGFloat = zoomFactor!
            if #available(iOS 13.0, *) {
                if let device = AVCaptureDevice.default(.builtInTripleCamera, for: .video, position: .back) {
                    zoomvalue = zoomFactor! - 0.5
                }
                else if let device = AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back) {
                    zoomvalue = zoomFactor! - 0.5
                }
            }          
            
            var roundValue :String = zoomvalue.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0fx", zoomvalue) : String(format: "%.1fx", zoomvalue)
            roundValue = roundValue.replacingOccurrences(of: ".0", with: "")
            DispatchQueue.main.async {
                UIView.performWithoutAnimation {
                    self.zoomFactorBtn.setTitle(roundValue, for: .normal)
                    self.zoomFactorBtn.layoutIfNeeded()
                }
            }
            return
        }
    }
    
    func onRecordingAMinute(_ currentTime: CMTime) {
        // For watch Need to call here
        let messageDict : [String:Any] = ["isStart":true, "Time": self.timeLbl.text ?? "", "Title":titleForWatch]
        //  let sendingData: [String : [String : Any]] = ["Data" : ["message":"Get+startRecording", "Time":self.timeLbl.text ?? "", "Title":"AA:BB"]]
        FannerCamWatchKitShared.sendMessageToWatchWithData(message: messageDict) {
        }
        
        print("Call : onRecordingAMinute")
        // -- For watch End --
        
        fanGenView.setCurrentMatchTime(fanGenService.matchTime(with: currentTime))
    }
    
    func cameraService(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        validatesLayouts()
        
        toggleRecordBtn.isEnabled = true
        setToggleBtnImage(isStarted: true)
        
        Utiles.setHUD(false)
    }
    
    func cameraService(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        validatesLayouts()
        fanGenService.resetAllNewClips()
        
        toggleRecordBtn.isEnabled = true
        setToggleBtnImage(isStarted: false)
        
        Utiles.setHUD(false)
    }
}

//MARK: - FannerCamWatchKitSharedDelegate

extension MatchesMainVideoRecordLiveVC : FannerCamWatchKitSharedDelegate {
    func getDataFromWatch(watchMessage: [String : Any]) {
        
        print(watchMessage)
        
        let controller : String = watchMessage["Controller"] as! String
        
        if controller == "RecordingController" {
            self.onToggleRecordBtn(toggleRecordBtn)
        } else if controller == "GenericMarkerController" {
            if isControllerActive == true {
                
                isFromWatch = true
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "TapOnGeneric"), object: nil)
                print(2)
            }
        }  else if controller == "CollectiveMarkerController" {
            //S
            if isControllerActive == true {
                
                isFromWatch = true
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "TapOnCollective"), object: nil)
                
                //E
                DispatchQueue.main.async {
                    //                self.fanGenService.setNewClipMarker(self.markerTags[0], 0)
                    //                self.view.bringSubviewToFront(self.fanGenView)
                    //                self.selectedMarkerType = .collective
                    //                self.fanGenService.didTapMarker(self.cameraService.currentRecordedTime, .collective, .second, 0)
                    //                self.setUndoBtnEnabled(true)
                }
                print(3)
            }
        }  else if controller == "TagController" {
            if isControllerActive == true {
                
                
                isFromWatch = true
                
                let selectedTag = watchMessage["SelectedTag"] as! Int
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "TapOnCollectiveTag"), object: nil, userInfo: ["SelectedTag" : selectedTag])
                
                //            DispatchQueue.main.async {
                //                self.fanGenService.setNewClipMarker(self.markerTags[selectedTag], 0)
                //                self.view.bringSubviewToFront(self.bottomBar)
                //            }
                
                //   view.bringSubviewToFront(bottomBar)
                //let selectedTag : (String, String) = watchMessage["selectedTag"] as! (String, String)
                
                print(4)
            }
        } else if controller == "RecordingControllerCheck" {
            if isControllerActive == true {
                if cameraService.isRecording {
                    DispatchQueue.main.async {
                        let messageDict : [String:Any] = ["isStart":true, "Time": self.timeLbl.text ?? "", "Title":self.titleForWatch, "StartDate":Date()]
                        FannerCamWatchKitShared.sendMessageToWatchWithData(message: messageDict) {}
                    }
                } else {
                    
                    DispatchQueue.main.async {
                        let messageDict : [String:Any] = ["isStart":false, "Time": self.timeLbl.text ?? "", "Title":self.titleForWatch, "StartDate":Date()]
                        
                        FannerCamWatchKitShared.sendMessageToWatchWithData(message: messageDict) {}
                    }
                    
                }
                print(5)
            } else {
                let messageDict : [String:Any] = ["isStart":false, "isControllerActive":false]
                FannerCamWatchKitShared.sendMessageToWatchWithData(message: messageDict) {}
                
            }
        } else if controller == "GenericMarkerControllerCheck" {
            if isControllerActive == true {
                if cameraService.isRecording {
                    let messageDict : [String:Any] = ["isStart":true]
                    FannerCamWatchKitShared.sendMessageToWatchWithData(message: messageDict) {}
                } else {
                    let messageDict : [String:Any] = ["isStart":false]
                    FannerCamWatchKitShared.sendMessageToWatchWithData(message: messageDict) {}
                }
                print(5)
            } else {
                let messageDict : [String:Any] = ["isStart":false, "isControllerActive":false]
                FannerCamWatchKitShared.sendMessageToWatchWithData(message: messageDict) {}
            }
        } else {
            let messageDict : [String:Any] = ["isStart":false, "isControllerActive":false]
            FannerCamWatchKitShared.sendMessageToWatchWithData(message: messageDict) {}
        }
    }
    
    //MARK: - Background & forground notifications
    
    @objc func didEnterdBG(notification: NSNotification){
        isControllerActive = false
        let messageDict : [String:Any]
        if cameraService.isRecording {
            messageDict = ["isStart":true,"isControllerActive":false]
        } else {
            messageDict = ["isStart":false,"isControllerActive":false]
        }
        FannerCamWatchKitShared.sendMessageToWatchWithData(message: messageDict) {}
    }
    
    @objc func didEnterdFG(notification: NSNotification) {
        isControllerActive = true
        let messageDict : [String:Any]
        if cameraService.isRecording {
            messageDict = ["isStart":true,"isControllerActive":true]
        } else {
            messageDict = ["isStart":false,"isControllerActive":true]
        }
        FannerCamWatchKitShared.sendMessageToWatchWithData(message: messageDict) {}
    }
}


//MARK: - FanGenerationVideoViewDelegate

extension MatchesMainVideoRecordLiveVC: FanGenerationVideoDelegate, FanGenerationVideoDataSource {
    
    func undoScore(_ fanGenVideo: FanGenerationVideo, team: Team) {
        fanGenVideo.setUndoBtn(enabled: fanGenService.undoGoal(team), team: team)
        let fScore = fanGenService.selectedMatch.match.getScoreAt(of: .first)
        fanGenView.set(goal: fScore, .first)
        let sScore = fanGenService.selectedMatch.match.getScoreAt(of: .second)
        fanGenView.set(goal: sScore, .second)
    }
    
    func didTapScoreboard(_ fanGenerationVideo: FanGenerationVideo) {
        if cameraService.isRecording {
            return
        }
        print("ok")
        //fanGenView.displayScoreboardSettingView(fanGenService.selectedMatch.match.scoreboardSetting)
        //view.bringSubviewToFront(fanGenView)
        //view.bringSubviewToFront(viewLeftTop)
    }
    
    func didTapGoal(_ fanGenerationVideo: FanGenerationVideo, goals value: String, team: Team) {
        _ = fanGenService.setGoals(cameraService.currentRecordedTime, Int(value) ?? 0, team)
        fanGenView.setUndoBtn(enabled: fanGenService.checkScoreUndoAvailable().f, team: .first)
        fanGenView.setUndoBtn(enabled: fanGenService.checkScoreUndoAvailable().s, team: .second)
    }
    
    func didTapMarker(_ markerView: MarkersView, _ marker: UIButton, _ type: FanGenMarker, _ team: Team, _ countPressed: Int) {
        if type == .individual || type == .collective {
            DispatchQueue.main.async {
                if isFromWatch == true {
                    self.view.bringSubviewToFront(self.fanGenView)
                    //self.view.bringSubviewToFront(self.viewLeftTop)
                } else {
                    self.view.bringSubviewToFront(self.fanGenView)
                    //self.view.bringSubviewToFront(self.viewLeftTop)
                }
            }
        }
        selectedMarkerType = type.markerType
        fanGenService.didTapMarker(cameraService.currentRecordedTime, type, team, countPressed)
        setUndoBtnEnabled(true)
    }
    
    func didTapMarker(_ type: FanGenMarker, _ team: Team, _ countPressed: Int) {
        selectedMarkerType = type.markerType
        fanGenService.didTapMarker(cameraService.currentRecordedTime, type, team, countPressed)
        //setUndoBtnEnabled(true)
    }
    
    func fanGenerationVideo(_ fanGenerationVideo: FanGenerationVideo, didSelectTagAt index: Int, _ type: FanGenMarker, _ countPressed: Int) {
        fanGenService.setNewClipMarker(markerTags[index], countPressed)
        if type == .collective {
            
            DispatchQueue.main.async {
                if (isFromWatch == true) {
                    self.view.bringSubviewToFront(self.bottomBar)
                } else {
                    self.view.bringSubviewToFront(self.bottomBar)
                }
            }
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
        if period != nil {
            let isChanged = fanGenService.selectedMatch.match.scoreboardSetting.set(Int(point1!)!, Int(point2!)!, Int(point3!)!, period!)
            if isChanged {
                fanGenService.saveAction()
                fanGenView.setScoreboardUI(withSetting: fanGenService.selectedMatch.match.scoreboardSetting, nil, selectedMatch.match.fstAbbName,  selectedMatch.match.sndAbbName)
                MessageBarService.shared.notify("Successfully saved changed setting!")
            } else {
                MessageBarService.shared.warning("No changed setting")
            }
        }
        view.bringSubviewToFront(bottomBar)
    }
    
    func fanGenerationVideoMode() -> FanGenMode {
        return .record
    }
    
    func fanGenScoreValue(_ fanGenerationVideo: FanGenerationVideo, _ team: Team) -> Int? {
        return selectedMatch.match.getScoreAt(of: team)
    }
    
    func numberOfTags(in fanGenerationVideo: FanGenerationVideo) -> Int {
        return markerTags.count
    }
    
    func fanGenerationVideo(_ fanGenerationVideo: FanGenerationVideo, tagCellAt index: Int) -> Marker {
        return markerTags[index]
    }
}

// Live
//extension MatchesMainVideoRecordVC: PresenterDelegate {
//    func didStartLive() {
//        liveTimer = Timer(timeInterval: 1.0, target: self, selector: #selector(liveTimerAction), userInfo: nil, repeats: true)
//        validatesLayouts()
//        setToggleBtnImage(isStarted: true)
//
//        perform(#selector(endStreamingReaction), with: nil, afterDelay: 1.0)
//    }
//
//    func didChangedLiveStatus() {
//        perform(#selector(endStreamingReaction), with: nil, afterDelay: 1.0)
//    }
//}
