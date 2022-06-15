//
//  VideoPlayerVC.swift
//  NewFannerCam
//
//  Created by Jin on 1/9/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import UIKit
import MobileCoreServices
import AVFoundation
import MediaPlayer

enum VideoPlayVCMode {
    case play
    case edit
}

class VideoPlayerVC: UIViewController {

    @IBOutlet weak var frameBtn : UIButton!
    @IBOutlet weak var progressSlider : UISlider!
    @IBOutlet weak var blackView : UIView!
    @IBOutlet weak var editBtn              : UIButton!
    
    @IBOutlet weak var preview              : UIView!
    @IBOutlet weak var playBtnView          : UIView!
    @IBOutlet weak var togglePlayBtn        : UIButton!
    
    @IBOutlet weak var lTimeLbl             : UILabel!
    @IBOutlet weak var rTimeLbl             : UILabel!
    
    private var avplayerService             : AVPlayerService!
    private var isLoaded                    : Bool = false
    private var stopframeBtns               = [UIButton]()
    
    var currentVideo                        : Video!
    var previewClip                         : Clip!
    var mediaUrl                            : String!
    
//MARK: - Override functions
    override func viewDidLoad() {
        super.viewDidLoad()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.myOrientation = .landscape
        
        UIScreen.main.addObserver(self, forKeyPath: "captured", options: .new, context: nil)
        Utiles.setHUD(true, view, .extraLight, "Configuring player...")
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func setUpAudioSession() {
        UIApplication.shared.beginReceivingRemoteControlEvents()
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback, mode: AVAudioSession.Mode.moviePlayback, options: []) // changes

            self.becomeFirstResponder()
                        
            do {
                try AVAudioSession.sharedInstance().setActive(true)
                print("AVAudioSession is Active")
            } catch let error as NSError {
                print(error.localizedDescription)
                
            }
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
    
    func setupLockScreen(){
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.addTarget(self, action:#selector(skipTrack))
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [MPMediaItemPropertyTitle: "TESTING"]
    }
    
    @objc func skipTrack() {
        print("audio lock screen control")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !isLoaded {
            initLayout()
            configAVPlayer()
            isLoaded = true
            
//            setUpAudioSession()
//            setupLockScreen()
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if (keyPath == "captured")  {
            if #available(iOS 11.0, *) {
                let isCaptured = UIScreen.main.isCaptured
                if (isCaptured) {
                    self.blackView.isHidden = false
                } else {
                    self.blackView.isHidden = true
                }
            } else {
                // Fallback on earlier versions
            }
        }
    }
    
//MARK: - Main functions
    func initLayout() {
        playBtnView.layer.cornerRadius = playBtnView.bounds.height/2
        playBtnView.layer.borderColor = Constant.Color.white.cgColor
        playBtnView.layer.borderWidth = 2
        playBtnView.layer.masksToBounds = true
        
        if previewClip != nil {
            editBtn.isHidden = true
        }
    }
    
    func configAVPlayer() {
        if previewClip != nil {
            avplayerService = AVPlayerService(preview, progressSlider, previewClip.getFilePath(ofMainVideo: true), .part, previewClip)
        }
        else if currentVideo != nil {
            avplayerService = AVPlayerService(preview, progressSlider, currentVideo.filePath(), .full)
        }
        else {
            avplayerService = AVPlayerService(preview, progressSlider, URL(string: mediaUrl)!, .full)
        }
        avplayerService.delegate = self
        avplayerService.initPlayer()
        Utiles.setHUD(false)
    }
    
    //TODO: - stop frames processing
    func initStopframes() {
        for item in currentVideo.stopframes {
            let btn = setStopframeBtn(of: item)
            stopframeBtns.append(btn)
        }
    }
    
    func removeStopframeBtns() {
        for btn in stopframeBtns {
            btn.removeFromSuperview()
        }
        stopframeBtns.removeAll()
    }
    
    func setStopframeBtn(of stopframe: StopFrame) -> UIButton {
        let rect = progressSlider.thumbRect(forBounds: progressSlider.bounds, trackRect: progressSlider.trackRect(forBounds: progressSlider.bounds), value: stopframe.progressSliderValue())
        print(rect)
        var x = rect.origin.x + rect.size.width/2 - 22/2
        if x > (progressSlider.frame.width - 22) {
            x = progressSlider.frame.width - 22
        }
        let stopFrameBtn = UIButton(frame: CGRect(x: x, y: progressSlider.frame.height/2 - 11, width: 22, height: 22))
        
        if stopframe.isExistingImage() {
            stopFrameBtn.backgroundColor = Constant.Color.yellow
        } else {
            stopFrameBtn.backgroundColor = Constant.Color.red
        }
        stopFrameBtn.tag = stopframe.tagNumber
        stopFrameBtn.layer.cornerRadius = stopFrameBtn.frame.height / 2
        stopFrameBtn.maskToBounds = true
        stopFrameBtn.addTarget(self, action: #selector(onStopFrameBtnToShowPopup(_:)), for: .touchUpInside)
        
        progressSlider.addSubview(stopFrameBtn)
        return stopFrameBtn
    }
    
    @objc func onStopFrameBtnToShowPopup(_ sender: UIButton) {
        showPopUpView(sourceBtn: sender)
    }
    
    func showPopUpView(sourceBtn: UIButton) {
        print(sourceBtn.tag)
        let clickedItem = currentVideo.stopframes.filter { $0.tagNumber == sourceBtn.tag }
        guard clickedItem.count == 1 else {
            MessageBarService.shared.error("Something went wrong! Please delete this stopframe!")
            return
        }
        let stopFramePopupViewController = storyboard?.instantiateViewController(withIdentifier: "StopFramePopupVC") as! StopFramePopupVC
        var popUpSize : CGSize!
        if UI_USER_INTERFACE_IDIOM() == .phone {
            popUpSize = CGSize(width: 120.0, height: 150.0)
        } else {
            popUpSize = CGSize(width: 150.0, height: 200.0)
        }
        
        stopFramePopupViewController.preferredContentSize = popUpSize
        stopFramePopupViewController.modalPresentationStyle = .popover
        stopFramePopupViewController.popoverPresentationController?.delegate = self
        stopFramePopupViewController.popoverPresentationController?.permittedArrowDirections = .any
        stopFramePopupViewController.popoverPresentationController?.sourceView = progressSlider
        stopFramePopupViewController.popoverPresentationController?.sourceRect = sourceBtn.frame
        stopFramePopupViewController.delegate = self
        stopFramePopupViewController.stopframe = clickedItem[0]
        
        present(stopFramePopupViewController, animated: true, completion: nil)
    }
    
//MARK: - IBAction functions
    @IBAction func onTogglePlayBtn(_ sender: UIButton) {
        avplayerService.setPlayer()
        if avplayerService.isPlaying {
            sender.setImage(Constant.Image.PauseWhite.image, for: .normal)
        } else {
            sender.setImage(Constant.Image.PlayWhite.image, for: .normal)
        }
    }
    
    @IBAction func onBackBtn(_ sender: Any) {
        if avplayerService.isPlaying {
            avplayerService.setPlayer()
            avplayerService = nil
        }
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.myOrientation = .portrait
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onEditBtn(_ sender: UIButton) {
        if frameBtn.isHidden {
            sender.setTitle("Save", for: .normal)
            sender.setTitleColor(Constant.Color.blue, for: .normal)
            initStopframes()
        } else {
            let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            sheet.modalPresentationStyle = .popover
            sheet.addAction(UIAlertAction(title: "Replace the video", style: .default) { (replaceAction) in
                self.generate(isReplace: true)
            })
            sheet.addAction(UIAlertAction(title: "Create a new video", style: .default) { (createAction) in
                self.generate(isReplace: false)
            })
            sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            if let presenter = sheet.popoverPresentationController {
                presenter.sourceView = sender
                presenter.sourceRect = sender.bounds
            }
            present(sheet, animated: true, completion: nil)
            
            sender.setTitle("Edit", for: .normal)
            sender.setTitleColor(Constant.Color.white, for: .normal)
            
            DataManager.shared.updateVideos(currentVideo, .replace)
            removeStopframeBtns()
        }
        frameBtn.isHidden = !frameBtn.isHidden
    }
    
    @IBAction func onFrameBtn(_ sender: Any) {
        let newStopframe = StopFrame(currentVideo.fileName, avplayerService.currentPlayerTime())
        currentVideo.update(stopframe: newStopframe, updater: .new)
        let newStopframeBtn = setStopframeBtn(of: newStopframe)
        stopframeBtns.append(newStopframeBtn)
        
        backgroundQueue.async {
            let frame = ImageProcess.getFrame(url: self.currentVideo.filePath(), fromTime: CMTimeGetSeconds(self.avplayerService.currentPlayerTime()))
            UIImageWriteToSavedPhotosAlbum(frame, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
        }
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        if let err = error {
            MessageBarService.shared.error(err.localizedDescription)
        }
    }

}

//MARK: - AVPlayerServiceDelegate
extension VideoPlayerVC: AVPlayerServiceDelegate {
    
    func onPlayingAMinute(_ currentTime: CMTime) {
        
    }
    
    func avPlayerService(_ avPlayerService: AVPlayerService, didSlideUp played: String, rest restTime: String) {
        lTimeLbl.text = played
        rTimeLbl.text = restTime
    }
    
    func avPlayerService(didEndPlayVideo avPlayerService: AVPlayerService) {
        togglePlayBtn.setImage(Constant.Image.PlayWhite.image, for: .normal)
    }
    
    func avPlayerServiceSliderValueChanged() {
    
    }
}

//MARK: - VideoProcessing
extension VideoPlayerVC {
    func generate(isReplace: Bool) {
        
        let loadingMessage = isReplace ? "Replac" : "Sav"
        let newVideo = Video("\(currentVideo.title ?? String()) - Stopframed", currentVideo.highBitrate, currentVideo.quality)
        
        Utiles.setHUD(true, view, .extraLight, "\(loadingMessage)ing a new video...")
        let generator = VideoProcess([Clip](), Match())
        generator.generateVideoWithStopframes(self.currentVideo, newVideo.filePath()) { (isDone, resultDes) in
            if isDone {
                if isReplace {
                    DataManager.shared.updateVideos(self.currentVideo, .replace, newVideo)
                } else {
                    DataManager.shared.updateVideos(newVideo, .new)
                }
                MessageBarService.shared.notify("\(loadingMessage)ed a new video!")
            } else {
                MessageBarService.shared.error(resultDes)
            }
            Utiles.setHUD(false)
        }
    }
}


//MARK: - StopFramePopupVCDelegte
extension VideoPlayerVC: StopFramePopupVCDelegte {
    func dismissEditPopup(with stopframe: StopFrame) {
        currentVideo.update(stopframe: stopframe, updater: .replace)
    }
    
    func onPopupAddedImage(with stopframe: StopFrame) {
        stopframeBtns.filter { $0.tag == stopframe.tagNumber }[0].backgroundColor = Constant.Color.yellow
    }
    
    func onPopupDeleteBtn(with stopframe: StopFrame) {
        let index = stopframeBtns.firstIndex { $0.tag == stopframe.tagNumber } ?? 0
        stopframeBtns[index].removeFromSuperview()
        stopframeBtns.remove(at: index)
        currentVideo.update(stopframe: stopframe, updater: .delete)
    }
}

//MARK: UIPopoverPresentationControllerDelegate
extension VideoPlayerVC: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}
