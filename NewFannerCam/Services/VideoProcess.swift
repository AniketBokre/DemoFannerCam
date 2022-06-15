//
//  VideoProcess.swift
//  NewFannerCam
//
//  Created by Jin on 1/29/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import UIKit
import AVFoundation
import AssetsLibrary
import MobileCoreServices
import CoreGraphics
import CoreImage
import Photos

let CMTIMESCALE : Int32 = 1000000000

protocol VideoProcessDelegate: class {
    
}

class VideoProcess: NSObject {
    
    var match                   : Match!
    var clips                           = [Clip]()
    
    weak var delegate                   : VideoProcessDelegate?
    
    override init() {
        
    }
    
    init(_ clips: [Clip], _ match: Match) {
        self.clips = clips
        self.match = match
    }
    
    func generateNewVideo(_ highBitrate: Bool, _ newVideo: Video, _ completion: @escaping (Bool, String) -> Void) {
        guard let template = DataManager.shared.getSelectedTemplate() else { return }
        let selectedSoundtrack = DataManager.shared.getSelectedSoundtrack()
        
        dirManager.clearTempDir()
        
        DispatchQueue.main.async {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        
        clips.sort { $0.getStartTimeInMatch() < $1.getStartTimeInMatch() }
        
        let mixComposition = AVMutableComposition()
        var videoTrack = mixComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        var audioTrack = mixComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        var timeToMerge = CMTime.zero
        var timeToInitClip = CMTime.zero
        
        var introVideoFilePath : URL!
        if self.match.isResolution1280 {
            introVideoFilePath = template.filePath(of: .introBase)
        } else {
            introVideoFilePath = template.filePath(of: .introBaseHD)
        }
        let assetIntro = AVAsset(url: introVideoFilePath)
        let assetTrackVideo = assetIntro.tracks(withMediaType: .video)[0]
        let introRange = CMTimeRangeMake(start: CMTime.zero, duration: assetIntro.duration)
        videoTrack = insertMergeVideo(assetIntro, timeToMerge, introRange, videoTrack)
        
        if assetIntro.tracks(withMediaType: AVMediaType.audio).count > 0 {
            audioTrack = insertMergeAudio(assetIntro, timeToMerge, introRange, audioTrack)
        }
        
        timeToInitClip = assetIntro.duration
        timeToMerge = assetIntro.duration
        
        // - pre clip video
        if match.preClip.isExistingPreClipFile(), match.preClip.isSelected {
            let assetPreclip = AVAsset(url: match.preClip.getPreClipPath())
            let preClipRange = CMTimeRangeMake(start: CMTime.zero, duration: assetPreclip.duration)
            videoTrack = insertMergeVideo(assetPreclip, timeToMerge, preClipRange, videoTrack)
            
            if assetPreclip.tracks(withMediaType: AVMediaType.audio).count > 0 {
                audioTrack = insertMergeAudio(assetPreclip, timeToMerge, preClipRange, audioTrack)
            }
            
            timeToMerge = CMTimeAdd(timeToMerge, assetPreclip.duration)
            timeToInitClip = CMTimeAdd(timeToInitClip, assetPreclip.duration)
        }
        
        var periodTimes = [CMTime]()
        var periodDurations = [CMTime]()
        var period = clips[0].period
        for clip in clips {
            if !dirManager.checkFileExist(clip.getFilePath(ofMainVideo: true)) {
                continue
            }
            
            // period template
            if period != clip.period {
                period = clip.period
                
                var periodVideoFilePath : URL!
                if match.isResolution1280 {
                    periodVideoFilePath = template.filePath(of: .periodBase)
                } else {
                    periodVideoFilePath = template.filePath(of: .periodBaseHD)
                }
                let periodAsset = AVAsset(url: periodVideoFilePath)
                let periodRange = CMTimeRangeMake(start: CMTime.zero, duration: periodAsset.duration)
                videoTrack = insertMergeVideo(periodAsset, timeToMerge, periodRange, videoTrack)
                
                if selectedSoundtrack == nil {
                    if periodAsset.tracks(withMediaType: AVMediaType.audio).count > 0 {
                        audioTrack = insertMergeAudio(periodAsset, timeToMerge, periodRange, audioTrack)
                    }
                }
                
                periodTimes.append(timeToMerge)
                periodDurations.append(periodAsset.duration)
                timeToMerge = CMTimeAdd(timeToMerge, periodAsset.duration)
            }
            
            // replay template
            if clip.isReplay {
                var replayVideoFilePath : URL!
                if match.isResolution1280 {
                    replayVideoFilePath = template.filePath(of: .replayBumper)
                } else {
                    replayVideoFilePath = template.filePath(of: .replayBumperHD)
                }
                let replayAsset = AVAsset(url: replayVideoFilePath)
                let replayRange = CMTimeRangeMake(start: CMTime.zero, duration: replayAsset.duration)
                videoTrack = insertMergeVideo(replayAsset, timeToMerge, replayRange, videoTrack)
                
                if selectedSoundtrack == nil {
                    if replayAsset.tracks(withMediaType: AVMediaType.audio).count > 0 {
                        audioTrack = insertMergeAudio(replayAsset, timeToMerge, replayRange, audioTrack)
                    }
                }
                
                timeToMerge = CMTimeAdd(timeToMerge, replayAsset.duration)
            }
            
            /// clip
            let assetClip = AVAsset(url: clip.getFilePath(ofMainVideo: false))
            let clipRange = CMTimeRange(start: CMTime.zero, duration: assetClip.duration)
            videoTrack = insertMergeVideo(assetClip, timeToMerge, clipRange, videoTrack)
            
            if selectedSoundtrack == nil {
                if clip.isReplay {
                    //                audioTrack?.insertEmptyTimeRange(CMTimeRange(start: CMTimeMakeWithSeconds(timeToMerge, preferredTimescale: clip.cmTimeScale), duration: assetClip.duration))
                } else {
                    audioTrack = insertMergeAudio(assetClip, timeToMerge, clipRange, audioTrack)
                }
            }
            
            timeToMerge = CMTimeAdd(timeToMerge, assetClip.duration)
            
            // replay template
            if clip.isReplay {
                var replayVideoFilePath : URL!
                if match.isResolution1280 {
                    replayVideoFilePath = template.filePath(of: .replayBumper)
                } else {
                    replayVideoFilePath = template.filePath(of: .replayBumperHD)
                }
                let replayAsset = AVAsset(url: replayVideoFilePath)
                let replayRange = CMTimeRangeMake(start: CMTime.zero, duration: replayAsset.duration)
                videoTrack = insertMergeVideo(replayAsset, timeToMerge, replayRange, videoTrack)
                
                if selectedSoundtrack == nil {
                    if replayAsset.tracks(withMediaType: AVMediaType.audio).count > 0 {
                        audioTrack = insertMergeAudio(replayAsset, timeToMerge, replayRange, audioTrack)
                    }
                }
                
                timeToMerge = CMTimeAdd(timeToMerge, replayAsset.duration)
            }
        }
        
        if let soundtrack = selectedSoundtrack {                        //------- insert soundtrack audio -------
            let soundAsset = AVAsset(url: soundtrack.filePath())
            
            var differSecs = CMTimeSubtract(timeToMerge, timeToInitClip)
            if CMTimeGetSeconds(soundAsset.duration) >= CMTimeGetSeconds(differSecs) {
                let soundRange = CMTimeRangeMake(start: CMTime.zero, duration: differSecs)
                audioTrack = insertMergeAudio(soundAsset, timeToInitClip, soundRange, audioTrack)
            } else {
                
                var multiNum = Int((CMTimeGetSeconds(differSecs)/CMTimeGetSeconds(soundAsset.duration)))
                
                repeat {
                    let soundRange = CMTimeRangeMake(start: CMTime.zero, duration: soundAsset.duration)
                    audioTrack = insertMergeAudio(soundAsset, timeToInitClip, soundRange, audioTrack)
                    timeToInitClip = CMTimeAdd(timeToInitClip, soundAsset.duration)
                    differSecs = CMTimeSubtract(differSecs, soundAsset.duration)
                    multiNum -= 1
                } while multiNum > 0
                
                
                let soundRange = CMTimeRangeMake(start: CMTime.zero, duration: differSecs)
                audioTrack = insertMergeAudio(soundAsset, timeToInitClip, soundRange, audioTrack)
            }
        }
        
        var (mainCompositionInst, naturalSize) = videoInstruction(mixComposition, videoTrack!, assetTrackVideo, match.quality())
        
         DispatchQueue.main.async {
            mainCompositionInst = self.applyTeamLogoAndNameLabel(mainCompositionInst, naturalSize, periodTimes.map{ CMTimeGetSeconds($0) }, periodDurations.map{ CMTimeGetSeconds($0) })
            
            self.exportComposition(mixComposition, self.match.quality(), highBitrate, newVideo.filePath(), mainCompositionInst) { (isSuccess, resultDescription) in
            completion(isSuccess, resultDescription)
        }
        }
    }
    
    // share clip and merged video
    func generateSingleMediaFile(_ quality: String, _ highBitrate: Bool, _ videoData: Any, preclipMediaUrl: URL? = nil, _ completion: @escaping (Bool, String) -> Void) {
        
        guard let template = DataManager.shared.getSelectedTemplate() else {
            completion(false, "Please download templates from settings page and select your favorite before creating a video.")
            return
        }
        
        DispatchQueue.main.async {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        
        let mixComposition = AVMutableComposition()
        var videoTrack = mixComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        var audioTrack = mixComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        var range : CMTimeRange!
        
        if let clip = videoData as? Clip {
            clip.removeClipFiles()
            
            let assetMainVideo = AVAsset(url: clip.getFilePath(ofMainVideo: true))
            
            let tempURL = dirManager.tempSingleClipVideo()
            
            let exportSession = AVAssetExportSession(asset: assetMainVideo, presetName: quality)
            exportSession?.outputURL = tempURL
            exportSession?.outputFileType = AVFileType.mov
            
            let timeRange = CMTimeRange(start: clip.getClipStartTime(), duration: clip.getClipDuration())
            exportSession?.timeRange = timeRange
            exportSession?.exportAsynchronously{
                switch exportSession!.status {
                case .completed:
                    let sTempURL = dirManager.tempSingleClipVideo()
                    self.convertVideoToLowQuailty(inputURL: tempURL, outputUrl: sTempURL, quality: quality, { (isDone, resultDes) in
                        if isDone {
                            let tempAsset = AVAsset(url: sTempURL )
                            let assetTrackVideo = tempAsset.tracks(withMediaType: .video)[0]
                            
                            range = CMTimeRange(start: CMTime.zero, duration: tempAsset.duration)
                            
                            videoTrack = self.insertMergeVideo(tempAsset, CMTime.zero, range, videoTrack, clip.isReplay)
                            audioTrack = self.insertMergeAudio(tempAsset, CMTime.zero, range, audioTrack, clip.isReplay)
                            
                            var (mainCompositionInst, naturalSize) = self.videoInstruction(mixComposition, videoTrack!, assetTrackVideo, quality)
                            
                            mainCompositionInst = self.applyScoreboard(mainCompositionInst, naturalSize, clip)
                            self.exportComposition(mixComposition, quality, highBitrate, clip.getFilePath(ofMainVideo: false), mainCompositionInst) { (isSuccess, resultDescription) in
                                completion(isSuccess, resultDescription)
                            }
                        } else {
                            completion(false, resultDes)
                        }
                    })
                case .failed:
                    completion(false, "The operation was failed!")
                case .cancelled:
                    completion(false, "The operation was canceled!")
                default:
                    completion(false, "Something went wrong!")
                }
            }
            
        }
        
        if let imgClip = videoData as? ImageClip, let preClipFile = preclipMediaUrl {
            imgClip.removePreClip()
            let assetImportedVideo = AVAsset(url: preClipFile)
            range = CMTimeRange(start: CMTime.zero, duration: CMTimeMakeWithSeconds(10.0, preferredTimescale: CMTIMESCALE))
            
            videoTrack = insertMergeVideo(assetImportedVideo, CMTime.zero, range, videoTrack)
            audioTrack = insertMergeAudio(assetImportedVideo, CMTime.zero, range, audioTrack)
            
            let assetIntro = AVAsset(url: template.filePath(of: .introBaseHD))
            let assetTrackVideo = assetIntro.tracks(withMediaType: .video)[0]
            let (mainCompositionInst, _) = videoInstruction(mixComposition, videoTrack!, assetTrackVideo, quality)
            
            exportComposition(mixComposition, quality, highBitrate, imgClip.getPreClipPath(), mainCompositionInst) { (isSuccess, resultDescription) in
                completion(isSuccess, resultDescription)
            }
        }
        
        if let video = videoData as? Video {
            let videoAsset = AVAsset(url: video.filePath())
            let assetTrackVideo = videoAsset.tracks(withMediaType: .video)[0]
            
            range = CMTimeRange(start: CMTime.zero, duration: videoAsset.duration)
            
            videoTrack = insertMergeVideo(videoAsset, CMTime.zero, range, videoTrack)
            audioTrack = insertMergeAudio(videoAsset, CMTime.zero, range, audioTrack)
            
            let mainCompositionInst = videoInstruction(mixComposition, videoTrack!, assetTrackVideo, quality).0
            
            exportComposition(mixComposition, quality, highBitrate, dirManager.tempSingleClipVideo(), mainCompositionInst) { (isSuccess, resultDescription) in
                completion(isSuccess, resultDescription)
            }
        }
    }
    
    func generateSingleMediaFileForLiverecap(_ quality: String, _ highBitrate: Bool, _ videoData: Any, preclipMediaUrl: URL? = nil, _ completion: @escaping (Bool, String) -> Void) {
        
        DispatchQueue.main.async {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        
        let mixComposition = AVMutableComposition()
        var videoTrack = mixComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        var audioTrack = mixComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        var range : CMTimeRange!
        
        if let clip = videoData as? Clip {
            clip.removeClipFiles()
            
            let assetMainVideo = AVAsset(url: clip.getFilePath(ofMainVideo: true))
            
            let tempURL = dirManager.tempSingleClipVideo()
            
            let exportSession = AVAssetExportSession(asset: assetMainVideo, presetName: quality)
            exportSession?.outputURL = tempURL
            exportSession?.outputFileType = AVFileType.mov
            
            let timeRange = CMTimeRange(start: clip.getClipStartTime(), duration: clip.getClipDuration())
            exportSession?.timeRange = timeRange
            exportSession?.exportAsynchronously{
                switch exportSession!.status {
                case .completed:
                    let sTempURL = dirManager.tempSingleClipVideo()
                    self.convertVideoToLowQuailty(inputURL: tempURL, outputUrl: sTempURL, quality: quality, { (isDone, resultDes) in
                        if isDone {
                            let tempAsset = AVAsset(url: sTempURL )
                            let assetTrackVideo = tempAsset.tracks(withMediaType: .video)[0]
                            
                            range = CMTimeRange(start: CMTime.zero, duration: tempAsset.duration)
                            
                            videoTrack = self.insertMergeVideo(tempAsset, CMTime.zero, range, videoTrack, clip.isReplay)
                            audioTrack = self.insertMergeAudio(tempAsset, CMTime.zero, range, audioTrack, clip.isReplay)
                            
                            var (mainCompositionInst, naturalSize) = self.videoInstruction(mixComposition, videoTrack!, assetTrackVideo, quality)
                            
                            mainCompositionInst = self.applyScoreboard(mainCompositionInst, naturalSize, clip)
                            self.exportComposition(mixComposition, quality, highBitrate, clip.getFilePath(ofMainVideo: false), mainCompositionInst) { (isSuccess, resultDescription) in
                                completion(isSuccess, resultDescription)
                            }
                        } else {
                            completion(false, resultDes)
                        }
                    })
                case .failed:
                    completion(false, "The operation was failed!")
                case .cancelled:
                    completion(false, "The operation was canceled!")
                default:
                    completion(false, "Something went wrong!")
                }
            }
            
        }
        
        if let imgClip = videoData as? ImageClip, let preClipFile = preclipMediaUrl {
            imgClip.removePreClip()
            let assetImportedVideo = AVAsset(url: preClipFile)
            range = CMTimeRange(start: CMTime.zero, duration: CMTimeMakeWithSeconds(10.0, preferredTimescale: CMTIMESCALE))
            
            videoTrack = insertMergeVideo(assetImportedVideo, CMTime.zero, range, videoTrack)
            audioTrack = insertMergeAudio(assetImportedVideo, CMTime.zero, range, audioTrack)
        }
        
        if let video = videoData as? Video {
            let videoAsset = AVAsset(url: video.filePath())
            let assetTrackVideo = videoAsset.tracks(withMediaType: .video)[0]
            
            range = CMTimeRange(start: CMTime.zero, duration: videoAsset.duration)
            
            videoTrack = insertMergeVideo(videoAsset, CMTime.zero, range, videoTrack)
            audioTrack = insertMergeAudio(videoAsset, CMTime.zero, range, audioTrack)
            
            let mainCompositionInst = videoInstruction(mixComposition, videoTrack!, assetTrackVideo, quality).0
            
            exportComposition(mixComposition, quality, highBitrate, dirManager.tempSingleClipVideo(), mainCompositionInst) { (isSuccess, resultDescription) in
                completion(isSuccess, resultDescription)
            }
        }
    }
    
    func saveVideoFromGallery(inputURL: URL, imgClip: ImageClip, quality: String, _ completion: @escaping (Bool, String) -> Void) {
        imgClip.removePreClip()
        
        let tempURL = dirManager.tempSingleClipVideo()
        
        convertVideoToLowQuailty(inputURL: inputURL, outputUrl: tempURL, quality: quality) { (isSuccess, resultDes) in
            if isSuccess {
                self.trimVideo(of: tempURL, outputUrl: imgClip.getPreClipPath(), quality: quality, defaultDuration: 10.0, { (isSuccess, resultDes) in
                    completion(isSuccess, resultDes)
                })
            } else {
                completion(false, resultDes)
            }
        }
    }
    
    func trimVideo(of url: URL, outputUrl: URL, quality: String, defaultDuration: Float64? = nil, _ completion: @escaping (Bool, String) -> Void) {
        let asset = AVAsset(url: url)
        let length = Float64(asset.duration.value)/Float64(asset.duration.timescale)
        var duration : Float64!
        
        if let defaultDur = defaultDuration {
            duration = defaultDur
            if duration >= length {
                duration = length
            }
        } else {
            duration = length
        }
        
        let exportSession = AVAssetExportSession(asset: asset, presetName: quality)
        exportSession?.outputURL = outputUrl
        exportSession?.outputFileType = AVFileType.mov
        
        let timeRange = CMTimeRange(start: CMTime.zero, end: CMTimeMakeWithSeconds(duration, preferredTimescale: CMTIMESCALE))
        exportSession?.timeRange = timeRange
        exportSession?.exportAsynchronously{
            switch exportSession!.status {
            case .completed:
                completion(true, "Success")
            case .failed:
                completion(false, "The operation was failed!")
            case .cancelled:
                completion(false, "The operation was canceled!")
            default:
                completion(false, "Something went wrong!")
            }
        }
    }
    
    // generate a video with image
    func generateVideoWithStopframes(_ sampleVideo: Video, _ outputUrl: URL, _ completion: @escaping (Bool, String) -> Void) {
        let stopframes = sampleVideo.stopframes.filter { $0.isExistingImage() }.sorted { CMTimeGetSeconds($0.time) < CMTimeGetSeconds($1.time) }
        guard stopframes.count > 0 else {
            completion(false, "No inserted stopframe images!")
            return
        }
        
        DispatchQueue.main.async {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        
        let videoAsset = AVAsset(url: sampleVideo.filePath())
        let assetTrackVideo = videoAsset.tracks(withMediaType: .video)[0]
        let mixComposition = AVMutableComposition()
        var videoTrack = mixComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        var audioTrack = mixComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        var timeToMerge = CMTime.zero
        var sampleVideoSplitTime = CMTime.zero
        
        for item in stopframes {
            item.removeStopVideo()
            generateVideoWithImage(item.image()!, item.duration, item.stopVideoPath(), sampleVideo.quality)
            
            var range = CMTimeRange(start: sampleVideoSplitTime, duration: CMTimeSubtract(item.time, sampleVideoSplitTime))
            
            videoTrack = insertMergeVideo(videoAsset, timeToMerge, range, videoTrack)
            audioTrack = insertMergeAudio(videoAsset, timeToMerge, range, audioTrack)
            
            sampleVideoSplitTime = item.time
            timeToMerge = item.time
            
            let stopVideoAsset = AVAsset(url: item.stopVideoPath())
            range = CMTimeRange(start: CMTime.zero, duration: stopVideoAsset.duration)
            videoTrack = insertMergeVideo(stopVideoAsset, timeToMerge, range, videoTrack)
            audioTrack = insertMergeAudio(stopVideoAsset, timeToMerge, range, audioTrack)
            
            timeToMerge = item.endTime()
        }
        
        let lastDuration = CMTimeSubtract(videoAsset.duration, sampleVideoSplitTime)
        let range = CMTimeRange(start: sampleVideoSplitTime, duration: lastDuration)
        
        videoTrack = insertMergeVideo(videoAsset, timeToMerge, range, videoTrack)
        audioTrack = insertMergeAudio(videoAsset, timeToMerge, range, audioTrack)
        
        timeToMerge = CMTimeAdd(timeToMerge, lastDuration)
        
        let mainCompositionInst = videoInstruction(mixComposition, videoTrack!, assetTrackVideo, sampleVideo.quality).0
        
        exportComposition(mixComposition, sampleVideo.quality, true, outputUrl, mainCompositionInst) { (isSuccess, resultDescription) in
            completion(isSuccess, resultDescription)
        }
    }
    
}

//MARK: - Tool Functions
extension VideoProcess {
    
    class func previewImage(_ url: URL, at timeData: Any) -> UIImage {
        var roundedTime : CMTime!
        if let float64Val = timeData as? Float64 {
            roundedTime = CMTime(value: Int64(float64Val.rounded(.up)), timescale: CMTIMESCALE)
        }
        if let cmTime = timeData as? CMTime {
            roundedTime = cmTime
        }
        let asset = AVURLAsset(url: url, options: nil)
        let gen = AVAssetImageGenerator(asset: asset)
        gen.appliesPreferredTrackTransform = true
        let image: CGImage
        do {
            image = try gen.copyCGImage(at: roundedTime, actualTime: nil)
            let thumb = UIImage(cgImage: image)
            return ImageProcess.resize(image: thumb, scaledToSize: CGSize(width: Utiles.screenWidth(), height: (Utiles.screenWidth()/16)*9))
        } catch {
            print(error)
        }
        return UIImage()
    }
    
    func generateVideoWithImage(_ image: UIImage, _ duration: Float64, _ outputUrl: URL, _ resolution: String) {
        
        var size = CGSize(width: 1280, height: 720)
        if resolution == AVAssetExportPreset1920x1080 {
            size = CGSize(width: 1920, height: 1080)
        }
        
        var imgVideoWriter: AVAssetWriter!
        do {
            imgVideoWriter = try AVAssetWriter(outputURL: outputUrl, fileType: AVFileType.mov)
        } catch let error as NSError {
            print("failed to create AssetWriter: \(error.description)")
        }
        
        let videoSettings = [
            AVVideoCodecKey: AVVideoCodecH264 as AnyObject,
            AVVideoWidthKey: size.width as AnyObject,
            AVVideoHeightKey: size.height as AnyObject
            ] as [String: Any]
        
        let writerInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoSettings)
        imgVideoWriter.add(writerInput)
        
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput, sourcePixelBufferAttributes: nil )
        
        //Start a session:
        let start = imgVideoWriter.startWriting()
        if !start {
            print("failed writing")
        }
        imgVideoWriter.startSession(atSourceTime: CMTime.zero)
        
        //Write samples:
        guard let buffer = pixelBufferFromCGImage(image: image.cgImage!, size:size) else {
            return
        }
        adaptor.append(buffer, withPresentationTime: CMTime.zero)
        adaptor.append(buffer, withPresentationTime: CMTimeMakeWithSeconds(duration, preferredTimescale: CMTIMESCALE))
        
        //Finish the session:
        writerInput.markAsFinished()
        
        imgVideoWriter.endSession(atSourceTime: CMTimeMakeWithSeconds(duration, preferredTimescale: CMTIMESCALE) )
        imgVideoWriter.finishWriting { () -> Void in
            switch imgVideoWriter.status {
            case .cancelled:
                print("cancelled")
            case .completed:
                print("completed")
            case .failed:
                print("failed")
            case .unknown:
                print("unknown")
            case .writing:
                print("writing")
            @unknown default:
                print("Unknown")
            }
            print("Finish writing")
        }
    }
    
    func pixelBufferFromCGImage(image: CGImage, size:CGSize) -> CVPixelBuffer? {
        let options =
            [
                kCVPixelBufferCGImageCompatibilityKey : true,
                kCVPixelBufferCGBitmapContextCompatibilityKey: true
                ] as CFDictionary
        var pxbuffer    : CVPixelBuffer? = nil
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(size.width), Int(size.height), kCVPixelFormatType_32ARGB, options, &pxbuffer)
        
        guard let buffer = pxbuffer, status == kCVReturnSuccess else { return nil }
        CVPixelBufferLockBaseAddress(buffer, [])
        guard let pxdata = CVPixelBufferGetBaseAddress(buffer) else { return nil }
        let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: pxdata, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
            else { return nil }
        context.concatenate(CGAffineTransform(rotationAngle: 0))
        context.draw(image, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        
        CVPixelBufferUnlockBaseAddress(buffer, [])
        
        return buffer
    }
    
    //MARK: setting score point
    func setScorePoint(_ rectBar: CGRect, _ pos: ScoreboardPosition, _ template: Template, _ score: Int, _ team: Team, _ font: Int) -> CATextLayer {
        let result = CATextLayer()
        
        if team == .first {
            result.frame = CGRect(x: rectBar.origin.x + rectBar.size.width * pos.rtScore1.origin.x, y: rectBar.origin.y + rectBar.size.height * pos.rtScore1.origin.y, width: rectBar.size.width * pos.rtScore1.size.width, height: rectBar.size.height * pos.rtScore1.size.height)
            result.alignmentMode = template.scoreboardType == .first ? CATextLayerAlignmentMode.right : CATextLayerAlignmentMode.center
        } else {
            result.frame = CGRect(x: rectBar.origin.x + rectBar.size.width * pos.rtScore2.origin.x, y: rectBar.origin.y + rectBar.size.height * pos.rtScore2.origin.y, width: rectBar.size.width * pos.rtScore2.size.width, height: rectBar.size.height * pos.rtScore2.size.height)
            result.alignmentMode = template.scoreboardType == .first ? CATextLayerAlignmentMode.left : CATextLayerAlignmentMode.center
        }
        
        if template.nClrScoreInt() == 0 {
            result.string = attributeText(with: .black, of: "\(score)", fontSize: CGFloat(font))
        } else if template.nClrScoreInt() == 1 {
            result.string = attributeText(with: .white, of: "\(score)", fontSize: CGFloat(font))
        } else {
            result.string = attributeText(with: .blue, of: "\(score)", fontSize: CGFloat(font))
        }
        
        return result
    }
    
    func attributeText(with color: UIColor, of text: String, fontSize: CGFloat) -> NSAttributedString {
        let attributes = [
            NSAttributedString.Key.font: UIFont(name: "Helvetica-Bold", size: fontSize)! ,      // font
            NSAttributedString.Key.foregroundColor: color                                       // text color
        ]
        
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        return attributedString
    }
    
    //MARK: merge video composition
    func insertMergeVideo(_ asset: AVAsset, _ timeToMerge: CMTime, _ range: CMTimeRange, _ videoTrack: AVMutableCompositionTrack?, _ isReplay: Bool = false) -> AVMutableCompositionTrack? {
        try! videoTrack?.insertTimeRange(range, of: asset.tracks(withMediaType: .video)[0], at: timeToMerge)
        if isReplay {
            videoTrack?.scaleTimeRange(CMTimeRangeMake(start: timeToMerge, duration: range.duration), toDuration: CMTimeMakeWithSeconds(CMTimeGetSeconds(range.duration) * 2, preferredTimescale: range.duration.timescale))
        }
        
        return videoTrack
    }
    
    func insertMergeAudio(_ asset: AVAsset, _ timeToMerge: CMTime, _ range: CMTimeRange, _ audioTrack: AVMutableCompositionTrack?, _ isReplay: Bool = false) -> AVMutableCompositionTrack? {
        //        if isReplay {
        //            audioTrack?.insertEmptyTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: CMTimeAdd(range.duration, CMTimeAdd(range.duration, range.duration))))
        //        } else {
        if asset.tracks(withMediaType: .audio).count > 0 {
            try! audioTrack?.insertTimeRange(range, of: asset.tracks(withMediaType: .audio)[0], at: timeToMerge)
        }
        //        }
        return audioTrack
    }
    
    func videoInstruction(_ mixComposition: AVMutableComposition, _ videoTrack: AVMutableCompositionTrack, _ assetTrackVideo: AVAssetTrack, _ quality: String) -> (AVMutableVideoComposition, CGSize) {
        let mainInstruction = AVMutableVideoCompositionInstruction()
        mainInstruction.timeRange = CMTimeRange(start: CMTime.zero, duration: mixComposition.duration)
        
        // 3.2 - Create an AVMutableVideoCompositionLayerInstruction for the video track and fix the orientation.
        let videolayerInstruction   = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        //        var isVideoAssetPortrait    = false
        //        let videoTransform : CGAffineTransform = assetTrackVideo.preferredTransform
        //        if (videoTransform.a == 0 && videoTransform.b == 1.0 && videoTransform.c == -1.0 && videoTransform.d == 0) {
        //            //    videoAssetOrientation = UIImageOrientation.right
        //            isVideoAssetPortrait = true
        //        }
        //        if (videoTransform.a == 0 && videoTransform.b == -1.0 && videoTransform.c == 1.0 && videoTransform.d == 0) {
        //            //    videoAssetOrientation =  UIImageOrientation.left
        //            isVideoAssetPortrait = true
        //        }
        //        if (videoTransform.a == 1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == 1.0) {
        //            //    videoAssetOrientation =  UIImageOrientation.up
        //        }
        //        if (videoTransform.a == -1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == -1.0) {
        //            //    videoAssetOrientation = UIImageOrientation.down
        //        }
        videolayerInstruction.setTransform(assetTrackVideo.preferredTransform, at: CMTime.zero)
        videolayerInstruction.setOpacity(0.0, at:mixComposition.duration)
        
        // 3.3 - Add instructions
        mainInstruction.layerInstructions = [ videolayerInstruction ]
        
        let mainCompositionInst = AVMutableVideoComposition()
        
        //        var naturalSize = CGSize()
        //        if isVideoAssetPortrait {
        //            print(assetTrackVideo.naturalSize.height, assetTrackVideo.naturalSize.width)
        //            naturalSize = CGSize(width: assetTrackVideo.naturalSize.height, height: assetTrackVideo.naturalSize.width)
        //        } else {
        //            naturalSize = assetTrackVideo.naturalSize
        //        }
        
        //        if assetTrackVideo.naturalSize.height > assetTrackVideo.naturalSize.width {
        //            naturalSize = CGSize(width: assetTrackVideo.naturalSize.height, height: assetTrackVideo.naturalSize.width)
        //        } else {
        //            naturalSize = assetTrackVideo.naturalSize
        //        }
        
        var renderWidth : CGFloat = 0.0, renderHeight : CGFloat = 0.0
        if quality == AVAssetExportPreset1920x1080 {
            renderWidth = 1920
            renderHeight = 1080
        } else {
            renderWidth = 1280
            renderHeight = 720
        }
        //        let t1 = CGAffineTransform(rotationAngle: CGFloat(Double.pi/2))
        //        let t3 = CGAffineTransform(scaleX: renderWidth/naturalSize.width, y: renderHeight/naturalSize.height)
        //        let transformer = AVMutableVideoCompositionLayerInstruction(assetTrack: assetTrackVideo)
        //        transformer.setTransform(t1, at: CMTime.zero)
        //        transformer.setTransform(t3, at: CMTime.zero)
        //        mainInstruction.layerInstructions = [transformer]
        
        //        renderWidth = Double(naturalSize.width)
        //        renderHeight = Double(naturalSize.height)
        
        mainCompositionInst.renderSize = CGSize(width: renderWidth, height: renderHeight)
        mainCompositionInst.instructions = [ mainInstruction ]
        mainCompositionInst.frameDuration = CMTimeMake(value: 1, timescale: 30)
        
        return (mainCompositionInst, CGSize(width: renderWidth, height: renderHeight))
    }
    
    func exportComposition(_ composition: AVMutableComposition, _ quality: String, _ highBitrate: Bool, _ outputUrl: URL, _ compositionInst: AVMutableVideoComposition,
                           completion: @escaping (Bool, String) -> Void) {
        let tempURL = highBitrate ? outputUrl : dirManager.tempSingleClipVideo()
        let exporter = AVAssetExportSession(asset: composition, presetName: quality)
        exporter?.outputURL = tempURL
        exporter?.outputFileType = .mov
        exporter?.shouldOptimizeForNetworkUse = true
        exporter?.videoComposition = compositionInst
        
        
        exporter?.exportAsynchronously(completionHandler: {
            DispatchQueue.main.async {
                UIApplication.shared.isIdleTimerDisabled = false
            }
            
            switch exporter!.status {
            case .completed:
                if highBitrate {
                    completion(true, tempURL.path)
                } else {
                    self.convertVideoToLowQuailty(inputURL: tempURL, outputUrl: outputUrl, quality: quality, { (isSuccess, resultDes) in
                        completion(isSuccess, outputUrl.path)
                    })
                }
                break
            case .failed:
                print(exporter?.error ?? Error.self)
                completion(false, exporter?.error?.localizedDescription ?? String())
                break
            default:
                completion(false, "Valid operation!")
                break
            }
        })
    }
    
    func convertVideoToLowQuailty(inputURL: URL, outputUrl: URL, quality: String, _ completion: @escaping (Bool, String) -> Void ) {
        //setup video writer
        let videoAsset = AVURLAsset(url: inputURL, options: nil)
        let videoTrack = videoAsset.tracks(withMediaType: AVMediaType.video)[0]
        
        var videoSize = CGSize.zero
        
        if quality == AVAssetExportPreset1280x720 {
            videoSize = CGSize(width: 1280, height: 720)
        } else {
            videoSize = CGSize(width: 1920, height: 1080)
        }
        
        // 2300000, 128000, 125000
        let videoWriterCompressionSettings = [
            AVVideoAverageBitRateKey : Int(2300000)
        ]
        
        let videoWriterSettings = [
            AVVideoCodecKey: AVVideoCodecH264 as AnyObject,
            AVVideoWidthKey: videoSize.width as AnyObject,
            AVVideoHeightKey: videoSize.height as AnyObject,
            AVVideoCompressionPropertiesKey: videoWriterCompressionSettings as AnyObject
            ] as [String: Any]
        
        let videoWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoWriterSettings)
        
        videoWriterInput.expectsMediaDataInRealTime = true
        videoWriterInput.transform = videoTrack.preferredTransform
        
        var videoWriter: AVAssetWriter!
        do {
            videoWriter = try AVAssetWriter(outputURL: outputUrl, fileType: AVFileType.mov)
        } catch let error as NSError {
            print("failed to create AssetWriter: \(error.description)")
        }
        
        videoWriter.add(videoWriterInput)
        
        //setup video reader
        let videoReaderOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings:
            [kCVPixelBufferPixelFormatTypeKey as String : kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange])
        let videoReader = try! AVAssetReader(asset: videoAsset)
        videoReader.add(videoReaderOutput)
        
        //setup audio writer
        let audioWriterInput = AVAssetWriterInput(mediaType: AVMediaType.audio, outputSettings: nil)
        audioWriterInput.expectsMediaDataInRealTime = false
        videoWriter.add(audioWriterInput)
        
        var audioReaderOutput : AVAssetReaderTrackOutput? = nil
        var audioReader : AVAssetReader?
        //setup audio reader
        if videoAsset.tracks(withMediaType: AVMediaType.audio).count == 0 {
            completion(false, "This video has no audio!")
        }else{
            let audioTrack = videoAsset.tracks(withMediaType: AVMediaType.audio)[0]
            audioReaderOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: nil)
            audioReader = try! AVAssetReader(asset: videoAsset)
            audioReader!.add(audioReaderOutput!)
        }
        
        videoWriter.startWriting()
        
        //start writing from video reader
        videoReader.startReading()
        videoWriter.startSession(atSourceTime: CMTime.zero)
        
        let processingQueue1 = DispatchQueue(label: "processingQueue1")
        videoWriterInput.requestMediaDataWhenReady(on: processingQueue1, using: {
            
            while (videoWriterInput.isReadyForMoreMediaData) {
                
                let sampleBuffer1 = videoReaderOutput.copyNextSampleBuffer()
                
                if videoReader.status == AVAssetReader.Status.reading && sampleBuffer1 != nil {
                    videoWriterInput.append(sampleBuffer1!)
                } else {
                    videoWriterInput.markAsFinished()
                    //                    videoWriter.endSession(atSourceTime: videoAsset.duration)
                    
                    if ( videoReader.status == AVAssetReader.Status.completed ) {
                        
                        //start writing from audio reader
                        if audioReader?.status != AVAssetReader.Status.reading {
                            audioReader?.startReading()
                        }
                        
                        videoWriter.startSession(atSourceTime: CMTime.zero)
                        
                        let processingQueue2 = DispatchQueue(label: "processingQueue2")
                        audioWriterInput.requestMediaDataWhenReady(on: processingQueue2, using: {
                            
                            while (audioWriterInput.isReadyForMoreMediaData) {
                                
                                let sampleBuffer2 = audioReaderOutput?.copyNextSampleBuffer()
                                
                                if audioReader?.status == AVAssetReader.Status.reading && sampleBuffer2 != nil {
                                    audioWriterInput.append(sampleBuffer2!)
                                } else {
                                    audioWriterInput.markAsFinished()
                                    //                                    videoWriter.endSession(atSourceTime: videoAsset.duration)
                                    if audioReader?.status == AVAssetReader.Status.completed {
                                        
                                        videoWriter.finishWriting(completionHandler: {
                                            completion(true, "Success")
                                        })
                                    }
                                }
                            }
                        })
                    }
                }
            }
        })
    }
    
    func convertVideoSize(inputURL: URL, outputUrl: URL, quality: String, _ completion: @escaping (Bool, String) -> Void ) {
        //setup video writer
        let videoAsset = AVURLAsset(url: inputURL, options: nil)
        let videoTrack = videoAsset.tracks(withMediaType: AVMediaType.video)[0]
        
        var videoSize = CGSize.zero
        
        if quality == AVAssetExportPreset1280x720 {
            videoSize = CGSize(width: 1280, height: 720)
        } else {
            videoSize = CGSize(width: 1920, height: 1080)
        }
        
        // 2300000, 128000, 125000
        let videoWriterCompressionSettings = [
            AVVideoAverageBitRateKey : Int(2300000)
        ]
        
        let videoWriterSettings = [
            AVVideoCodecKey: AVVideoCodecH264 as AnyObject,
            AVVideoWidthKey: videoSize.width as AnyObject,
            AVVideoHeightKey: videoSize.height as AnyObject,
            AVVideoCompressionPropertiesKey: videoWriterCompressionSettings as AnyObject
            ] as [String: Any]
        
        let videoWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoWriterSettings)
        
        videoWriterInput.expectsMediaDataInRealTime = true
        videoWriterInput.transform = videoTrack.preferredTransform
        
        var videoWriter: AVAssetWriter!
        do {
            videoWriter = try AVAssetWriter(outputURL: outputUrl, fileType: AVFileType.mov)
        } catch let error as NSError {
            print("failed to create AssetWriter: \(error.description)")
        }
        
        videoWriter.add(videoWriterInput)
        
        //setup video reader
        let videoReaderOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings:
            [kCVPixelBufferPixelFormatTypeKey as String : kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange])
        let videoReader = try! AVAssetReader(asset: videoAsset)
        videoReader.add(videoReaderOutput)
        
        //setup audio writer
        let audioWriterInput = AVAssetWriterInput(mediaType: AVMediaType.audio, outputSettings: nil)
        audioWriterInput.expectsMediaDataInRealTime = false
        videoWriter.add(audioWriterInput)
        
        var audioReaderOutput : AVAssetReaderTrackOutput? = nil
        var audioReader : AVAssetReader?
        //setup audio reader
        if videoAsset.tracks(withMediaType: AVMediaType.audio).count == 0 {
            completion(false, "This video has no audio!")
        }else{
            let audioTrack = videoAsset.tracks(withMediaType: AVMediaType.audio)[0]
            audioReaderOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: nil)
            audioReader = try! AVAssetReader(asset: videoAsset)
            audioReader!.add(audioReaderOutput!)
        }
        videoWriter.startWriting()
        
        //start writing from video reader
        videoReader.startReading()
        videoWriter.startSession(atSourceTime: CMTime.zero)
        
        let processingQueue1 = DispatchQueue(label: "processingQueue1")
        videoWriterInput.requestMediaDataWhenReady(on: processingQueue1, using: {
            
            while (videoWriterInput.isReadyForMoreMediaData) {
                
                let sampleBuffer1 = videoReaderOutput.copyNextSampleBuffer()
                
                if videoReader.status == AVAssetReader.Status.reading && sampleBuffer1 != nil {
                    videoWriterInput.append(sampleBuffer1!)
                } else {
                    videoWriterInput.markAsFinished()
                    videoWriter.endSession(atSourceTime: videoAsset.duration)
                    
                    if ( videoReader.status == AVAssetReader.Status.completed ) {
                        
                        //start writing from audio reader
                        if audioReader?.status != AVAssetReader.Status.reading {
                            audioReader?.startReading()
                        }
                        
                        videoWriter.startSession(atSourceTime: CMTime.zero)
                        
                        let processingQueue2 = DispatchQueue(label: "processingQueue2")
                        audioWriterInput.requestMediaDataWhenReady(on: processingQueue2, using: {
                            
                            while (audioWriterInput.isReadyForMoreMediaData) {
                                
                                let sampleBuffer2 = audioReaderOutput?.copyNextSampleBuffer()
                                
                                if audioReader?.status == AVAssetReader.Status.reading && sampleBuffer2 != nil {
                                    audioWriterInput.append(sampleBuffer2!)
                                } else {
                                    audioWriterInput.markAsFinished()
                                    videoWriter.endSession(atSourceTime: videoAsset.duration)
                                    if audioReader?.status == AVAssetReader.Status.completed {
                                        
                                        videoWriter.finishWriting(completionHandler: {
                                            completion(true, "Success")
                                        })
                                    }
                                }
                            }
                        })
                    }
                }
            }
        })
    }
    
}

//MARK: - Overlay layout processing functions
extension VideoProcess {
    
    func animationEvent(layer: CALayer, time: Float64? = nil, dur: Float64? = nil) {
        
        let animationInitial:CABasicAnimation = CABasicAnimation.init(keyPath: "opacity")
        
        animationInitial.fromValue = NSNumber(value: 1.0)
        animationInitial.toValue = NSNumber(value: 1.0)
        
        let group = CAAnimationGroup()
        
        if let duration = dur {
            animationInitial.duration = CFTimeInterval(duration * 0.65)
            group.duration = duration
        } else {
            animationInitial.duration = 4.2
            group.duration = 6.0
        }
        
        group.repeatCount = 1
        group.autoreverses = false
        group.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut )
        group.animations = [animationInitial]
        
        if let atTime = time {
            group.beginTime = AVCoreAnimationBeginTimeAtZero + atTime
        } else {
            group.beginTime = AVCoreAnimationBeginTimeAtZero + 1.2
        }
        
        layer.add(group, forKey: "allMyAnimations" )
        
        // Change the actual data value in the layer to the final value.
        layer.opacity = 0.0
    }
    
   /* func eventPosition() -> EventPosition {
        var result      = EventPosition()
        result.rtLogo1  = CGRect(x: 0.30, y: 0.37,  width: 0.45-0.25, height: 0.58-0.28)
        result.rtLogo2  = CGRect(x: 0.52, y: 0.90,  width: 0.75-0.55, height: 0.58-0.28)
        result.rtTeam1  = CGRect(x: 0.30, y: 0.50,  width: 0.45-0.25, height: 0.64-0.6)
        result.rtTeam2  = CGRect(x: 0.52, y: 0.50,  width: 0.75-0.55, height: 0.64-0.6)
        result.rtEvent1 = CGRect(x: 0.53, y: 0.57,  width: 0.20-0.25, height: 0.96-0.78)
        result.rtEvent2 = CGRect(x: 0.42, y: 0.7,   width: 0.58-0.42, height: 0.7-0.32)
        return result
    }*/
        func eventPosition() -> EventPosition {
         var result      = EventPosition()
            result.rtLogo1  = CGRect(x: 0.25, y: 0.55,  width: 0.45-0.25, height: 0.58-0.28)
            result.rtLogo2  = CGRect(x: 0.55, y: 0.55,  width: 0.75-0.55, height: 0.58-0.28)
            result.rtTeam1  = CGRect(x: 0.25, y: 0.64,  width: 0.45-0.25, height: 0.64-0.6)
            result.rtTeam2  = CGRect(x: 0.55, y: 0.64,  width: 0.75-0.55, height: 0.64-0.6)
            result.rtEvent1 = CGRect(x: 0.45, y: 0.96,  width: 0.55-0.45, height: 0.96-0.78)
            result.rtEvent2 = CGRect(x: 0.42, y: 0.7,   width: 0.58-0.42, height: 0.7-0.32)
         return result
        }
    
    
    func animationScore(_ layer: CALayer, _ startTime: Float64, _ duration: Float64) {
        let animationInitial = CABasicAnimation(keyPath: "opacity")
        // animate from fully visible to invisible
        animationInitial.fromValue = NSNumber(value: 1.0 )
        animationInitial.toValue =  NSNumber(value:  1.0 )
        animationInitial.duration  = CFTimeInterval(duration)
        
        let group = CAAnimationGroup()
        group.duration = CFTimeInterval(duration)
        group.repeatCount = 1
        group.autoreverses  = false
        group.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut) //kCAMediaTimingFunctionEaseInEaseOut
        group.animations = [animationInitial]
        group.beginTime = AVCoreAnimationBeginTimeAtZero + startTime
        
        layer.add( group, forKey: "allMyAnimations" )
        
        // Change the actual data value in the layer to the final value.
        layer.opacity = 0.0;
    }
    
    class func loadImg(from url: URL) -> UIImage? {
        //        do {
        //            let imageData = try Data(contentsOf: url)
        //            return UIImage(data: imageData)
        //        } catch {
        //            print("Error loading image : \(error)")
        //        }
        //        return nil
        //        if let data = NSData(contentsOf: url) {
        //            return UIImage(data: data as Data)
        //        } else {
        //            return nil
        //        }
        return UIImage(contentsOfFile: url.path)
    }
    
    func applyTeamLogoAndNameLabel(_ composition: AVMutableVideoComposition, _ size: CGSize, _ periodTimes: [Float64], _ periodDurations: [Float64]) -> AVMutableVideoComposition {
        let grid = Grid(Float(size.width), Float(size.height), 4, 4)
        
        let parentLayer = CALayer()
        parentLayer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        
        let nfont = match.isResolution1280 ? 20 : 30
        
        let videoLayer = CALayer()
        videoLayer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        parentLayer.addSublayer(videoLayer)
        
        let team1Logo = CALayer()
        if let img = VideoProcess.loadImg(from: match.matchLogoPath(.first)) {
            team1Logo.contents = img.cgImage
            print(img.cgImage as Any)
        } else {
            team1Logo.contents = Constant.Image.DefaultTeamLogo.image?.cgImage
        }
        
        team1Logo.contentsGravity = CALayerContentsGravity.resizeAspect
        let eventPos = eventPosition()
        var square = grid.squares[9]
        team1Logo.frame = CGRect(x: size.width * eventPos.rtLogo1.origin.x, y: size.height * (1 -  eventPos.rtLogo1.origin.y), width: size.width * eventPos.rtLogo1.size.width, height: size.height * eventPos.rtLogo1.size.height)
        team1Logo.masksToBounds = true
        team1Logo.cornerRadius = CGFloat(square.width/(1.46 * 2))
        team1Logo.isGeometryFlipped = true
        parentLayer.addSublayer(team1Logo)
        animationEvent(layer: team1Logo)
        
        let team2Logo = CALayer()
        if let img = VideoProcess.loadImg(from: match.matchLogoPath(.second)) {
            team2Logo.contents = img.cgImage
            print(img.cgImage as Any)
        } else {
            team2Logo.contents = Constant.Image.DefaultTeamLogo.image?.cgImage
        }
        team2Logo.contentsGravity = CALayerContentsGravity.resizeAspect
        square = grid.squares[10]
        team2Logo.frame = CGRect(x: size.width * eventPos.rtLogo2.origin.x, y: size.height * (1 - eventPos.rtLogo2.origin.y), width: size.width * eventPos.rtLogo2.size.width, height: size.height * eventPos.rtLogo2.size.height)
        team2Logo.masksToBounds = true
        team2Logo.cornerRadius = CGFloat(square.width/(1.46 * 2))
        team2Logo.contentsGravity = CALayerContentsGravity.resizeAspect
        team2Logo.isGeometryFlipped = true
        parentLayer.addSublayer(team2Logo)
        
        animationEvent(layer: team2Logo)
        
        /*hb event logo*/
        let eventLogo = CALayer()
        if let img = VideoProcess.loadImg(from: match.matchLogoPath()) {
            eventLogo.contents = img.cgImage as AnyObject
        } else {
            eventLogo.contents = Constant.Image.DefaultTeamLogo.image?.cgImage
        }
        
        eventLogo.contentsGravity = CALayerContentsGravity.resizeAspect
        eventLogo.frame = CGRect(x: size.width * eventPos.rtEvent1.origin.x, y: size.height * (1 - eventPos.rtEvent1.origin.y), width: size.width * eventPos.rtEvent1.size.width, height: size.height * eventPos.rtEvent1.size.height)
        eventLogo.contentsGravity = CALayerContentsGravity.resizeAspect
        eventLogo.isGeometryFlipped = true
        parentLayer.addSublayer(eventLogo)
        animationEvent(layer: eventLogo)
        
        /////////////////////////////////////
        let team1 = CATextLayer()
        let myAttributes = [
            NSAttributedString.Key.font: UIFont(name: "Helvetica-Bold", size: CGFloat(nfont))!,
            NSAttributedString.Key.foregroundColor: UIColor.white
        ]
        team1.frame = CGRect(x: size.width * eventPos.rtTeam1.origin.x, y: size.height * (1 - eventPos.rtTeam1.origin.y), width: size.width * eventPos.rtTeam1.size.width , height: size.height * eventPos.rtTeam1.size.height)
        team1.string = NSAttributedString(string: match.fstName.uppercased(), attributes: myAttributes)
        team1.alignmentMode = CATextLayerAlignmentMode.center
        team1.foregroundColor = UIColor.white.cgColor
        
        parentLayer.addSublayer(team1)
        animationEvent(layer: team1)
        
        let team2 = CATextLayer()
        let myAttributes1 = [
            NSAttributedString.Key.font: UIFont(name: "Helvetica-Bold", size: CGFloat(nfont))!,
            NSAttributedString.Key.foregroundColor: UIColor.white
        ]
        team2.frame = CGRect(x: size.width * eventPos.rtTeam2.origin.x, y: size.height * (1 - eventPos.rtTeam2.origin.y), width: size.width * eventPos.rtTeam2.size.width, height: size.height * eventPos.rtTeam2.size.height)
        team2.string = NSAttributedString(string: match.sndName.uppercased(), attributes: myAttributes1 )
        team2.alignmentMode = CATextLayerAlignmentMode.center
        team2.foregroundColor = UIColor.white.cgColor
        
        parentLayer.addSublayer(team2)
        animationEvent(layer: team2)
        
        for  n in  0 ..< periodTimes.count {
            let eventLogo1 = CALayer()
            let overlayEvenet1: UIImage!
            
            if let img = VideoProcess.loadImg(from: match.matchLogoPath()) {
                overlayEvenet1 = img
            } else {
                overlayEvenet1 = Constant.Image.DefaultTeamLogo.image
            }
            
            eventLogo1.contents = overlayEvenet1.cgImage
            eventLogo1.contentsGravity = CALayerContentsGravity.resizeAspect
            square = grid.squares[10]
            eventLogo1.frame = CGRect(x: size.width * eventPos.rtEvent2.origin.x , y: size.height * 0.5 -  size.width * eventPos.rtEvent2.size.height * 0.5, width: size.width * eventPos.rtEvent2.size.width, height: size.width * eventPos.rtEvent2.size.height)
            eventLogo1.contentsGravity = CALayerContentsGravity.resizeAspect
            parentLayer.addSublayer(eventLogo1)
            animationEvent(layer: eventLogo1, time: periodTimes[n], dur: periodDurations[n])
        }
        
        composition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentLayer)
        return composition
    }
    
    func cgImageCreate(with img: UIImage) {
        //        let callbacks = CGDataProviderSequentialCallbacks()
        //        callbacks.getBytes = getBytes;
        //
        //        CGDataProviderRef provider = CGDataProviderCreateSequential(NULL, &callbacks);
        //        CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
        //        CGImageRef img = CGImageCreate(64,                         // width
        //            64,                         // height
        //            8,                          // bitsPerComponent
        //            24,                         // bitsPerPixel
        //            64*3,                       // bytesPerRow
        //            space,                      // colorspace
        //            kCGBitmapByteOrderDefault,  // bitmapInfo
        //            img.cgImage?.dataProvider,                   // CGDataProvider
        //            NULL,                       // decode array
        //            NO,                         // shouldInterpolate
        //            kCGRenderingIntentDefault); // intent
        //
        //        CGColorSpaceRelease(space);
        //        CGDataProviderRelease(provider);
        
        // use the created CGImage
        //        CGImageRelease(img);
        //        if let sample = img.cgImage {
        //            let result = CGImage(width: sample.width, height: sample.height, bitsPerComponent: sample.bitsPerComponent, bitsPerPixel: sample.bitsPerPixel, bytesPerRow: sample.bytesPerRow, space: sample.colorSpace, bitmapInfo: [CGBitmapInfo.alphaInfoMask..kCGImageAlphaNoneSkipLast], provider: sample.dataProvider, decode: nil, shouldInterpolate: false, intent: kCGRenderingIntentDefault)
        //        }
    }
    
    /* hb add scoreboard to main video */
    func applyScoreboard(_ composition: AVMutableVideoComposition, _ size: CGSize, _ clip: Clip) -> AVMutableVideoComposition {
        
        let grid = Grid(Float(size.width), Float(size.height), 4, 4)
        
        // parent layer
        let parentLayer = CALayer()
        parentLayer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        
        // video layer
        let videoLayer = CALayer()
        videoLayer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        parentLayer.addSublayer(videoLayer)
        
        var square: Square!
        
        let nfont = match.isResolution1280 ? 18 : 28
        let scoreboardHidden = DataManager.shared.getScoreboardHidden()
        
        var rectBar = CGRect()
        // BARRA PUNTEGGIO
        guard let template = DataManager.shared.getSelectedTemplate() else { return composition }
        
        let arrScorePositions = setScoreboardPositions()
        let pos = arrScorePositions[template.scoreboardType.rawValue - 1]
        
        /*hb scoreboard image */
        if clip.isReplay {
            let barLayer = CALayer()
            let overlayImage = Constant.Image.BannerReplay.image
            barLayer.contents = overlayImage?.cgImage
            let pos2 = arrScorePositions[1]
            barLayer.frame = CGRect(x: size.width * pos2.rect.origin.x, y: size.height * (1 - pos2.rect.origin.y), width: size.width * pos2.rect.size.width, height: size.width * pos2.rect.size.width * 0.2317)
            rectBar = barLayer.frame
            parentLayer.addSublayer(barLayer)
        } else {
            if scoreboardHidden == false {
                let barLayer = CALayer()
                let filePath = template.filePath(of: .scoreboardBase)
                
                let overlayImage = UIImage(contentsOfFile: filePath.path)
                barLayer.contents = overlayImage?.cgImage
                barLayer.frame = CGRect(x: size.width * pos.rect.origin.x, y: size.height * (1 - pos.rect.origin.y), width: size.width * pos.rect.size.width, height: size.width * pos.rect.size.width * pos.rect.size.height)
                
                rectBar = barLayer.frame
                parentLayer.addSublayer(barLayer)
            }
            
            // hb fanner logo at the right top
            let iconFannerLayer = CALayer()
            let iconaFanner = Constant.Image.FannerLogo.image
            iconFannerLayer.contents = iconaFanner?.cgImage
            iconFannerLayer.opacity = 0.8
            
            square = grid.squares[15]
            let offsetLogo = size.width * pos.rect.size.width * pos.rect.size.height - size.height * 0.06
            iconFannerLayer.frame = CGRect(x: size.width * 0.83, y: size.height * (1 - pos.rect.origin.y) + offsetLogo, width: size.width * 0.13, height: size.height * 0.06)
            parentLayer.addSublayer(iconFannerLayer)
        }
        
        if clip.isExistClipFiles(isBanner: true) {
            let imageBanner = UIImage(contentsOfFile: clip.getBannerImgPath().path)!
            let barBanner = CALayer()
            barBanner.contents = imageBanner.cgImage
            barBanner.contentsGravity = CALayerContentsGravity.resizeAspect
            barBanner.opacity = 1.0
            let bannerSquare = grid.squares[1]
            barBanner.frame = CGRect(x: CGFloat(bannerSquare.x), y: CGFloat(bannerSquare.y), width: CGFloat(bannerSquare.width * 2.0), height: CGFloat(bannerSquare.height))
            parentLayer.addSublayer(barBanner)
        }
        
        //graphic overlay setting
        if let sx = DataManager.shared.getOverlay(of: .sx), let logoBottomSx = sx.image() {
            let logoSx = CALayer()
            
            let barlogoBottomSx = CALayer()
            barlogoBottomSx.contents = logoBottomSx.cgImage
            logoSx.contents = logoBottomSx.cgImage
            logoSx.opacity = 1.0
            
            square = grid.squares[0]
            logoSx.frame = CGRect(x: CGFloat(square.x), y: CGFloat(square.y), width: CGFloat(square.width), height: CGFloat(square.height))
            parentLayer.addSublayer(logoSx)
        }
        
        /* hb add score value, team name, logo */
        
        if !clip.isReplay && scoreboardHidden == false {
            var imageTeamLogo1: UIImage!
            if let img = VideoProcess.loadImg(from:  match.matchLogoPath(.first)) {
                imageTeamLogo1 = img
            } else {
                imageTeamLogo1 = Constant.Image.DefaultTeamLogo.image
            }
            
            let teamLayer1 = CALayer()
            teamLayer1.contents = imageTeamLogo1.cgImage
            teamLayer1.contentsGravity = CALayerContentsGravity.resizeAspect
            
            teamLayer1.frame = CGRect(x: rectBar.origin.x + rectBar.size.width * pos.rtLogo1.origin.x , y: rectBar.origin.y + rectBar.size.height * pos.rtLogo1.origin.y, width: rectBar.size.width * pos.rtLogo2.size.width , height: rectBar.size.width * pos.rtLogo2.size.width )
            parentLayer.addSublayer(teamLayer1)
            
            var imageTeamLogo2: UIImage!
            if let img = VideoProcess.loadImg(from:  match.matchLogoPath(.second)) {
                imageTeamLogo2 = img
            } else {
                imageTeamLogo2 = Constant.Image.DefaultTeamLogo.image
            }
            
            let teamLayer2 = CALayer()
            teamLayer2.contents = imageTeamLogo2.cgImage
            teamLayer2.contentsGravity = CALayerContentsGravity.resizeAspect
            teamLayer2.frame = CGRect(x: rectBar.origin.x + rectBar.size.width * pos.rtLogo2.origin.x , y: rectBar.origin.y  + rectBar.size.height * pos.rtLogo2.origin.y,width: rectBar.size.width * pos.rtLogo2.size.width, height: rectBar.size.width * pos.rtLogo2.size.width)
            
            parentLayer.addSublayer(teamLayer2)
            
            let team1 = CATextLayer()
            
            //hb change point
            team1.frame = CGRect( x: rectBar.origin.x + rectBar.size.width * pos.rtName1.origin.x , y: rectBar.origin.y + rectBar.size.height * pos.rtName1.origin.y, width: rectBar.size.width * pos.rtName1.size.width, height: rectBar.size.height * pos.rtName1.size.height ) // 100
            
            if template.nClrNameInt() == 0 {
                team1.string = attributeText(with: .black, of: match.fstAbbName.uppercased(), fontSize: CGFloat(nfont))
            } else if template.nClrNameInt() == 1 {
                team1.string = attributeText(with: .white, of: match.fstAbbName.uppercased(), fontSize: CGFloat(nfont))
            } else if template.nClrNameInt() == 2 {
                let color = UIColor(red: 0.0/255.0, green: 115.0/255.0, blue: 185.0/255.0, alpha: 1)
                team1.string = attributeText(with: color, of: match.fstAbbName.uppercased(), fontSize: CGFloat(nfont))
            } else if template.nClrNameInt() == 3 {
                let color = UIColor(red: 53.0/255.0, green: 87.0/255.0, blue: 190.0/255.0, alpha: 1)
                team1.string = attributeText(with: color, of: match.fstAbbName.uppercased(), fontSize: CGFloat(nfont))
            } else {
                team1.string = attributeText(with: .blue, of: match.fstAbbName.uppercased(), fontSize: CGFloat(nfont))
            }
            
            team1.alignmentMode =  CATextLayerAlignmentMode.center
            parentLayer.addSublayer(team1)
            
            /*hb add score animation */
            let scoresInClip = match.getScores(in: clip.marker.duration, from: clip.getStartTimeInMatch())
            
            if scoresInClip.count > 0 {
                
                let eScoreduration = CMTimeSubtract(scoresInClip[0].startTimeInMatch(), clip.getStartTimeInMatch())
                
                let fstEScore = match.getScoreAt(time: clip.getStartTimeInMatch(), of: .first)
                let fEResult = setScorePoint(rectBar, pos, template, fstEScore, .first, nfont)
                parentLayer.addSublayer(fEResult)
                animationScore(fEResult, 0.0, CMTimeGetSeconds(eScoreduration))
                
                /////////////////////////////
                
                let sndEScore = match.getScoreAt(time: clip.getStartTimeInMatch(), of: .second)
                let sEResult = setScorePoint(rectBar, pos, template, sndEScore, .second, nfont)
                parentLayer.addSublayer(sEResult)
                animationScore(sEResult, 0.0, CMTimeGetSeconds(eScoreduration))
                
                for score in scoresInClip {
                    
//                    var scoreDuration : CMTime!
//                    if match.isLastScore(score, of: scoresInClip) {
//                        scoreDuration = CMTimeSubtract(clip.endTime, score.time)
//
////                        scoreDuration = CMTimeAdd(scoreDuration, CMTime(value: 1, timescale: 1))
//                        scoreDuration = CMTimeAdd(scoreDuration, CMTime(value: 1, timescale: clip.cmTimeScale))
//                    } else {
//                        if let nextScore = match.getNextScore(to: score, of: scoresInClip) {
//                            scoreDuration = CMTimeSubtract(nextScore.time, score.time)
//                        } else {
//                            scoreDuration = CMTime.zero
//                        }
//                    }
//                    let scoreStartTime = CMTimeSubtract(score.startTimeInMatch(), clip.getStartTimeInMatch())
                    
                    var scoreDuration : CMTime!
                    if match.isLastScore(score, of: scoresInClip) {
                        scoreDuration = CMTimeSubtract(clip.endTime, score.time)
                        scoreDuration = CMTimeAdd(scoreDuration, CMTime(value: 1, timescale: clip.cmTimeScale))
                    } else {
                        if let nextScore = match.getNextScore(to: score, of: scoresInClip) {
                            scoreDuration = CMTimeSubtract(nextScore.time, score.time)
                        } else {
                            scoreDuration = CMTime.zero
                        }
                    }
                    let scoreStartTime = CMTimeSubtract(score.startTimeInMatch(), clip.getStartTimeInMatch())
                    
                    /////////////////////////////
                    
                    let fstScore = match.getScoreAt(time: score.startTimeInMatch(), of: .first)
                    let fResult = setScorePoint(rectBar, pos, template, fstScore, .first, nfont)
                    parentLayer.addSublayer(fResult)
                    
                    
                    animationScore(fResult, CMTimeGetSeconds(scoreStartTime), CMTimeGetSeconds(scoreDuration))
                    
                    /////////////////////////////
                    
                    let sndScore = match.getScoreAt(time: score.startTimeInMatch(), of: .second)
                    let sResult = setScorePoint(rectBar, pos, template, sndScore, .second, nfont)
                    parentLayer.addSublayer(sResult)
                    animationScore(sResult, CMTimeGetSeconds(scoreStartTime), CMTimeGetSeconds(scoreDuration))
                }
                
            } else {
                let fstScore = match.getScoreAt(time: clip.getStartTimeInMatch(), of: .first)
                let fResult = setScorePoint(rectBar, pos, template, fstScore, .first, nfont)
                parentLayer.addSublayer(fResult)
                
                let sndScore = match.getScoreAt(time: clip.getStartTimeInMatch(), of: .second)
                let sResult = setScorePoint(rectBar, pos, template, sndScore, .second, nfont)
                parentLayer.addSublayer(sResult)
            }
            
            if template.scoreboardType == .first {
                let result2 = CATextLayer()
                result2.frame = CGRect(x: rectBar.origin.x + rectBar.size.width * pos.rtSign.origin.x, y: rectBar.origin.y + rectBar.size.height * pos.rtSign.origin.y, width: rectBar.size.width * pos.rtSign.size.width, height: rectBar.size.height * pos.rtSign.size.height)
                
                result2.alignmentMode = CATextLayerAlignmentMode.center
                
                if template.nClrScoreInt() == 0 {
                    result2.foregroundColor = UIColor.black.cgColor
                    result2.string = attributeText(with: .blue, of: "-", fontSize: CGFloat(nfont))
                } else if template.nClrScoreInt() == 1 {
                    result2.string = attributeText(with: .white, of: "-", fontSize: CGFloat(nfont))
                } else {
                    result2.string = attributeText(with: .blue, of: "-", fontSize: CGFloat(nfont))
                }
                
                parentLayer.addSublayer(result2)
            }
            
            let team2 = CATextLayer()
            team2.frame = CGRect(x: rectBar.origin.x + rectBar.size.width * pos.rtName2.origin.x, y: rectBar.origin.y + rectBar.size.height * pos.rtName2.origin.y, width: rectBar.size.width * pos.rtName2.size.width, height: rectBar.size.height * pos.rtName2.size.height)
            
            if template.nClrNameInt() == 0 {
                team2.string = attributeText(with: .black, of: match.sndAbbName.uppercased(), fontSize: CGFloat(nfont))
            } else if template.nClrNameInt() == 1 {
                team2.string = attributeText(with: .white, of: match.sndAbbName.uppercased(), fontSize: CGFloat(nfont))
            } else if template.nClrNameInt() == 2 {
                let color = UIColor(red: 0.0/255.0, green: 115.0/255.0, blue: 185.0/255.0, alpha: 1)
                team2.string = attributeText(with: color, of: match.sndAbbName.uppercased(), fontSize: CGFloat(nfont))
            } else if template.nClrNameInt() == 3 {
                let color = UIColor(red: 53.0/255.0, green: 87.0/255.0, blue: 190.0/255.0, alpha: 1)
                team2.string = attributeText(with: color, of: match.sndAbbName.uppercased(), fontSize: CGFloat(nfont))
            } else {
                team2.string = attributeText(with: .blue, of: match.sndAbbName.uppercased(), fontSize: CGFloat(nfont))
            }
            team2.alignmentMode = CATextLayerAlignmentMode.center
            
            parentLayer.addSublayer(team2)
        }
        
        if let dx = DataManager.shared.getOverlay(of: .dx), let logoBottomDx = dx.image() {
            let legaLayer = CALayer()
            
            let barlogoBottomDx = CALayer()
            barlogoBottomDx.contents = logoBottomDx.cgImage
            
            legaLayer.contents = logoBottomDx.cgImage
            legaLayer.opacity = 1.0
            
            square = grid.squares[3]
            legaLayer.frame = CGRect(x: CGFloat(square.x), y: CGFloat(square.y), width: CGFloat(square.width), height: CGFloat(square.height))
            parentLayer.addSublayer(legaLayer)
        }
        
        // 3 - apply magic
        composition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentLayer)
        return composition
    }
    
}

//MARK: - Scoreboard processing
extension VideoProcess {
    func  setScoreboardPositions() -> [ScoreboardPosition] {
        
        var result = [ScoreboardPosition]()
        
        //   nClrName  // 0: black, 1: white, 2: custom blue, other: blue
        //   nClrScore
        
        // dreamsky
        var rate            = 42.0 / 456.0
        var offY            = 0.05
        var pos1            = ScoreboardPosition()
        pos1.rect           = CGRect(x: 0.045,  y: 0.045 + offY,    width: 0.38 - 0.045,    height: rate)
        pos1.rtLogo1        = CGRect(x: 0.025,  y: 0.2,             width: 0.08-0.02,       height: 0.8-0.2)
        pos1.rtLogo2        = CGRect(x: 0.915,  y: 0.2,             width: 0.98-0.92,       height: 0.8-0.2)
        pos1.rtName1        = CGRect(x: 0.12,   y: 0.2,             width: 0.35-0.12,       height: 0.8-0.2)
        pos1.rtName2        = CGRect(x: 0.65,   y: 0.2,             width: 0.88-0.65,       height: 0.8-0.2)
        pos1.rtScore1       = CGRect(x: 0.37,   y: 0.2,             width: 0.485-0.37,      height: 0.8-0.2)
        pos1.rtScore2       = CGRect(x: 0.51,   y: 0.2,             width: 0.63-0.51,       height: 0.8-0.2)
        pos1.rtSign         = CGRect(x: 0.485,  y: 0.2,             width: 0.51-0.485,      height: 0.8-0.2)
        result.append(pos1)
        
        //Round
        offY                = 0.1
        rate                = 77.0 / 249.0
        var pos2            = ScoreboardPosition()
        pos2.rect           = CGRect(x: 0.04 ,  y: 0.05 + offY,     width: 0.25-0.04,   height: rate )
        pos2.rtLogo1        = CGRect(x: 0.77,   y: 0.175,           width: 0.88-0.77,   height: 0.5-0.175)
        pos2.rtLogo2        = CGRect(x: 0.77,   y: 0.5,             width: 0.88-0.77,   height: 0.82-0.5)
        pos2.rtName1        = CGRect(x: 0.085,  y: 0.175,           width: 0.43-0.085,  height: 0.5-0.175)
        pos2.rtName2        = CGRect(x: 0.085,  y: 0.5,             width: 0.43-0.085,  height: 0.82-0.5)
        pos2.rtScore1       = CGRect(x: 0.53,   y: 0.175,           width: 0.71-0.53,   height: 0.5-0.175)
        pos2.rtScore2       = CGRect(x: 0.53,   y: 0.5,             width: 0.71-0.53,   height: 0.82-0.5)
        result.append(pos2)
        
        //Iron
        var pos3            = ScoreboardPosition()
        pos3.rect           = pos1.rect
        pos3.rtLogo1        = CGRect(x: 0.035,  y: 0.15,    width: 0.09-0.03,   height: 0.6)
        pos3.rtLogo2        = CGRect(x: 0.905,  y: 0.15,    width: 0.975-0.91,  height: 0.6)
        pos3.rtName1        = CGRect(x: 0.21,   y: 0.2,     width: 0.38-0.21,   height: 0.6)
        pos3.rtName2        = CGRect(x: 0.63,   y: 0.2,     width: 0.79-0.63,   height: 0.6)
        pos3.rtScore1       = CGRect(x: 0.435,  y: 0.2,     width: 0.5-0.435,   height: 0.6)
        pos3.rtScore2       = CGRect(x: 0.515,  y: 0.2,     width: 0.58-0.515,  height: 0.6)
        pos3.rtSign         = CGRect(x: 0.5,    y: 0.2,     width: 0.515-0.5,   height: 0.6)
        result.append(pos3)
        
        //Field
        var pos4            = ScoreboardPosition()
        pos4.rect           = pos1.rect
        pos4.rtLogo1        = CGRect(x: 0.05,   y: 0.15,    width :0.115 - 0.05,    height: 0.6)
        pos4.rtLogo2        = CGRect(x: 0.88,   y: 0.15,    width: 0.95 - 0.88,     height: 0.6)
        pos4.rtName1        = CGRect(x: 0.18,   y: 0.2,     width: 0.38-0.18,       height: 0.6)
        pos4.rtName2        = CGRect(x: 0.63,   y: 0.2,     width: 0.83-0.63,       height: 0.6)
        pos4.rtScore1       = CGRect(x: 0.38,   y: 0.2,     width: 0.5-0.38,        height: 0.6)
        pos4.rtScore2       = CGRect(x: 0.52,   y: 0.2,     width: 0.63-0.52,       height: 0.6)
        pos4.rtSign         = CGRect(x: 0.5,    y: 0.2,     width: 0.515-0.5,       height: 0.6)
        result.append(pos4)
        
        // legacalcioa8
        var pos5            = ScoreboardPosition()
        pos5.rect           = pos1.rect
        pos5.rtLogo1        = CGRect(x: 0.025,  y: 0.2,     width: 0.08-0.02,   height: 0.8-0.2)
        pos5.rtLogo2        = CGRect(x: 0.915,  y: 0.2,     width: 0.98-0.92,   height: 0.8-0.2)
        pos5.rtName1        = CGRect(x: 0.12,   y: 0.2,     width: 0.35-0.12,   height: 0.8-0.2)
        pos5.rtName2        = CGRect(x: 0.65,   y: 0.2,     width: 0.88-0.65,   height: 0.8-0.2)
        pos5.rtScore1       = CGRect(x: 0.37,   y: 0.2,     width: 0.485-0.37,  height: 0.8-0.2)
        pos5.rtScore2       = CGRect(x: 0.51,   y: 0.2,     width: 0.63-0.51,   height: 0.8-0.2)
        pos5.rtSign         = CGRect(x: 0.485,  y: 0.2,     width: 0.51-0.485,  height: 0.8-0.2)
        result.append(pos5)
        
        return result
    }
}


