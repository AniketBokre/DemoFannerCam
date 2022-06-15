//
//  AVPlayerService.swift
//  NewFannerCam
//
//  Created by Jin on 2/11/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import UIKit
import AVFoundation

private let AVPLAYER_DURATION_KEY_PATH = "duration"

enum PlayMode {
    case full
    case part
    case partPreview
}

protocol AVPlayerServiceDelegate : class {
    func onPlayingAMinute(_ currentTime: CMTime)
    func avPlayerService(_ avPlayerService: AVPlayerService, didSlideUp played: String, rest restTime: String)
    func avPlayerService(didEndPlayVideo avPlayerService: AVPlayerService)
    func avPlayerServiceSliderValueChanged()
}

class AVPlayerService : NSObject {

    private var asset                               : AVAsset!
    private var avPlayerItem                        : AVPlayerItem!
    private var avQueuePlayer                       : AVQueuePlayer!
    private var avPlayerLayer                       : AVPlayerLayer!
    
    private var preview                             : UIView!
    private var progressBar                         : UISlider!

    private var mTimeObserver                       : Any!
    private var selectedClip                        : Clip!
    
    weak var delegate                               : AVPlayerServiceDelegate?
    var playMode                                    = PlayMode.full
    
    var isPlaying                                   : Bool = false
    var isPlayEnded                                 : Bool = false
    private var shouldPlayAfterSliding              : Bool = true
    private var onSliding                           : Bool = false
    
//MARK: - Other Functions
    func currentPlayerTime() -> CMTime {
        return avQueuePlayer.currentTime()
    }
    
    func setPlayer() {
        if isPlaying {
            avQueuePlayer.pause()
            shouldPlayAfterSliding = false
        } else {
            if isPlayEnded {
                avQueuePlayer.remove(avPlayerItem)
                avQueuePlayer.insert(avPlayerItem, after: nil)
                if let clip = selectedClip {
                    seekPlayer(clip.getClipStartTime())
                } else {
                    seekPlayer(CMTime.zero)
                }
            }
            avQueuePlayer.play()
            isPlayEnded = false
            shouldPlayAfterSliding = true
        }
        isPlaying = !isPlaying
    }
    
    func removePlayerTimeObserver() {
        if let timeObserver = mTimeObserver {
            avQueuePlayer.removeTimeObserver(timeObserver)
            mTimeObserver = nil
        }
    }
    
//MARK: - Initial Functions
    init(_ preview: UIView, _ progressBar: UISlider, _ fileURL: URL, _ mode: PlayMode, _ clip: Clip? = nil) {
        avPlayerItem = AVPlayerItem(url: fileURL)
        avQueuePlayer = AVQueuePlayer(items: [avPlayerItem])
        
        asset = AVAsset(url: fileURL)
        self.preview = preview
        self.preview.frame = preview.frame
        self.progressBar = progressBar
        selectedClip = clip
        playMode = mode
    }
    
    func initPlayer() {
        try! AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback, mode: AVAudioSession.Mode.default, options: [])
        
        avQueuePlayer.addObserver(self, forKeyPath: AVPLAYER_DURATION_KEY_PATH, options: .new, context: nil)
        addTimeObserver()
        
        if let clip = selectedClip {
            seekPlayer(clip.getClipStartTime())
        }
        
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: avQueuePlayer.currentItem, queue: .main) { _ in
            self.delegate?.avPlayerService(didEndPlayVideo: self)
            self.isPlayEnded = true
            self.isPlaying = false
        }
        
        initPreview()
        
        if playMode != .partPreview {
            initSlider()
            setPlayer()
        }
    }
    
    func initSlider() {
        progressBar.maximumValue = 1.0
        progressBar.minimumValue = 0.0
        progressBar.value = 0.0
        progressBar.isContinuous = false
        progressBar.addTarget(self, action: #selector(endSliding(_:)), for: .valueChanged)
        progressBar.addTarget(self, action: #selector(onSliding(_:)), for: .touchDragInside)
        progressBar.addTarget(self, action: #selector(startedSliding(_:)), for: .touchDown)
    }
    
    func initPreview(_ viewItem: UIView? = nil) {
        guard avQueuePlayer != nil else { return }
        if let previewItem = viewItem {
            preview = previewItem
        }
        avPlayerLayer = AVPlayerLayer(player: avQueuePlayer)
        avPlayerLayer.frame = preview.bounds
        preview.layer.addSublayer(avPlayerLayer)
    }
    
    func setClip(_ clip: Clip, with viewItem: UIView? = nil) {
        selectedClip = clip
        avQueuePlayer.remove(avPlayerItem)
        asset = AVAsset(url: clip.getFilePath(ofMainVideo: true))
        avPlayerItem = AVPlayerItem(url: clip.getFilePath(ofMainVideo: true))
        avQueuePlayer.insert(avPlayerItem, after: nil)
        
        if let previewItem = viewItem {
            initPreview(previewItem)
        }
        seekPlayer(clip.getClipStartTime())
    }
    
    func setOnlyClip(_ clip: Clip) {
        selectedClip = clip
        seekPlayer(clip.getClipStartTime())
    }
    
}

//MARK: - Private Functions
extension AVPlayerService {
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == AVPLAYER_DURATION_KEY_PATH {
            self.isPlaying = true
            
            if let clip = self.selectedClip {
                delegate?.avPlayerService(self, didSlideUp: AVPlayerService.getTimeString(from: 0), rest: AVPlayerService.getTimeString(from: Int(clip.marker.duration)))
            } else {
                let duration = CMTimeGetSeconds(asset.duration)
                delegate?.avPlayerService(self, didSlideUp: AVPlayerService.getTimeString(from: 0), rest: AVPlayerService.getTimeString(from: Int(duration)))
            }
        }
    }
    
    @objc private func onSliding(_ sender: UISlider) {
        var currentTime : CMTime!
        
        if let clip = selectedClip {
            let currentSecs = clip.marker.duration * Float64(progressBar.value)
            currentTime = CMTimeMakeWithSeconds(CMTimeGetSeconds(clip.getClipStartTime()) + currentSecs, preferredTimescale: CMTIMESCALE)
        } else {
            let currentSecs = CMTimeGetSeconds(asset.duration) * Float64(progressBar.value)
            currentTime = CMTimeMakeWithSeconds(currentSecs, preferredTimescale: CMTIMESCALE)
        }
        
        seekPlayer(currentTime)
        
        delegate?.avPlayerServiceSliderValueChanged()
    }
    
    @objc private func endSliding(_ sender: UISlider) {
        if shouldPlayAfterSliding {
            avQueuePlayer.play()
            isPlaying = true
        }
        onSliding = false
    }
    
    @objc private func startedSliding(_ sender: UISlider) {
        if isPlaying {
            shouldPlayAfterSliding = true
            isPlaying = false
        } else {
            shouldPlayAfterSliding = false
        }
        avQueuePlayer.pause()
        
        if isPlayEnded {
            avQueuePlayer.remove(avPlayerItem)
            avQueuePlayer.insert(avPlayerItem, after: nil)
        }
        onSliding = true
    }
    
    private func addTimeObserver() {
        let interval = CMTime(seconds: 0.01, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        
        _ = avQueuePlayer.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main) { (progressTime) in
            
            let currentSecs = CMTimeGetSeconds(progressTime)
            
            if let clip = self.selectedClip {
                if self.playMode == .part {
                    let current = CMTimeGetSeconds(CMTimeSubtract(progressTime, clip.getClipStartTime()))
                    print(current)
                    if !self.onSliding {
                        self.progressBar.setValue(Float(current/clip.marker.duration), animated: true)
                    }
                    
                    self.delegate?.avPlayerService(self, didSlideUp: AVPlayerService.getTimeString(from: Int(current)), rest: AVPlayerService.getTimeString(from: Int(clip.marker.duration) - Int(current)))
                }
                
                if CMTimeGetSeconds(progressTime) >= CMTimeGetSeconds(clip.endTime) {
                    self.isPlayEnded = true
                    self.isPlaying = false
                    self.avQueuePlayer.pause()
                    self.shouldPlayAfterSliding = false
                    self.delegate?.avPlayerService(didEndPlayVideo: self)
                }
            } else {
                if let duration = self.avQueuePlayer.currentItem?.duration {
                    let currentTime = AVPlayerService.getTimeString(from: Int(currentSecs))
                    guard !(CMTimeGetSeconds(duration).isNaN || CMTimeGetSeconds(duration).isInfinite) else {
                        return
                    }
                    let rest = Int(CMTimeGetSeconds(duration)) - Int(currentSecs)
                    
                    self.delegate?.avPlayerService(self, didSlideUp: currentTime, rest: AVPlayerService.getTimeString(from: rest))
                    
                    if !self.onSliding {
                        let sliderValue = currentSecs / CMTimeGetSeconds(duration)
                        self.progressBar.setValue(Float(sliderValue), animated: true)
                    }
                }
            }
            
            self.delegate?.avPlayerServiceSliderValueChanged()
            
//            if Int(currentSecs/60)%60 == 0 {
                self.delegate?.onPlayingAMinute(progressTime)
//            }
        }
    }
}

//MARK: - Access functions
extension AVPlayerService {
    
    func seekPlayer(_ time: CMTime) {
        avQueuePlayer.seek(to: time, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero) { (success) in
            print("Seek : succeed? : ", success)
        }
    }
    
    class func getTimeString(from secs: Int) -> String {
        let hours = secs/3600
        let mins = (secs/60)%60
        let sec = secs%60
        return String(format: "%02i:%02i:%02i", hours, mins, sec)
    }
}
