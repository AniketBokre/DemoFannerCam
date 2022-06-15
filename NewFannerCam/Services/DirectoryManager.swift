//
//  DirectoryManager.swift
//  NewFannerCam
//
//  Created by Jin on 1/15/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import Foundation
import UIKit

private let dirVideo                = "video"

private let dirSetting              = "settingAsset"
private let dirSettingSoundtrack    = "soundtrack"
private let dirSettingTemplate      = "template"
private let dirSettingImgArchive    = "ImgArchive"

private let dirMatches              = "match"
private let dirMatchesMainVideo     = "mainVideo"
private let dirMathcesClipVideo     = "clipVideo"

final class DirectoryManager {
    
    private var fileManager = FileManager.default
    
    // default directories in app
    private var documentDir : String {
        return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    }
    
    private var tempDir : URL {
        return self.fileManager.temporaryDirectory
    }
    
    // custom directories in app
    private var videoDir : String {
        return createCustomPath(nil, dirVideo)
    }
    
    private var settingDir : String {
        return createCustomPath(nil, dirSetting)
    }
    
    private var settingSoundDir : String {
        return createCustomPath(settingDir, dirSettingSoundtrack)
    }
    
    private var settingTemplateDir : String {
        return createCustomPath(settingDir, dirSettingTemplate)
    }
    
    private var settingImgArchiveDir : String {
        return createCustomPath(settingDir, dirSettingImgArchive)
    }
    
    private var matchesDir : String {
        return createCustomPath(nil, dirMatches)
    }
    
    // private functions
    func createCustomPath(_ main: String?, _ sub: String) -> String {
        var result = String()
        if let mainDir = main {
            result = mainDir.combineDirPath(sub)
        } else {
            result = documentDir.combineDirPath(sub)
        }
        var isDir : ObjCBool = true
        if !fileManager.fileExists(atPath: result, isDirectory: &isDir) {
            do {
                try fileManager.createDirectory(atPath: result, withIntermediateDirectories: false, attributes: nil)
            } catch {
                print(error.localizedDescription)
            }
        }
        
        return result
    }
    
    //MARK: - Directory functions
    
    // match directory
    
    func matchSubDirs(matchName: String) -> (mainVideoDir: String, clipVideoDir: String) {
        let thisMatchDir = matchDirectory(matchName)
        
        let main = createCustomPath(thisMatchDir, dirMatchesMainVideo)
        let clip = createCustomPath(thisMatchDir, dirMathcesClipVideo)
        return (mainVideoDir: main, clipVideoDir: clip)
    }
    
    func matchDirectory(_ matchName: String) -> String {
        return createCustomPath(matchesDir, matchName)
    }
    
    func matchLogosPaths(_ name: String, _ team: Team? = nil) -> URL {
        
        if let teamVal = team {
            if teamVal == .first {
                return URL(fileURLWithPath: matchDirectory(name).combineDirPath("FirstTeamLogo.png"))
            } else {
                return URL(fileURLWithPath: matchDirectory(name).combineDirPath("SecondTeamLogo.png"))
            }
        } else {
            return URL(fileURLWithPath: matchDirectory(name).combineDirPath("MatchLogo.png"))
        }
        
    }
    
    func matchPreClipPath(_ matchName: String) -> URL {
        return URL(fileURLWithPath: matchDirectory(matchName).combineDirPath("PreClip.mov"))
    }
    
    func generateMatch(_ matchName: String, _ fileName: String, isMainVideo: Bool) -> URL {
        
        var result : URL!
        if isMainVideo {
            result = URL(fileURLWithPath: matchSubDirs(matchName: matchName).mainVideoDir.combineDirPath(fileName))
        } else {
            result = URL(fileURLWithPath: matchSubDirs(matchName: matchName).clipVideoDir.combineDirPath(fileName))
        }
        return result
    }
    
    func tempSingleClipVideo() -> URL {
        let pathStr = tempDir.path.combineDirPath(Date().uniqueNew().setExtension(isMov: true))
        return URL(fileURLWithPath: pathStr)
    }
    
    // video directory
    func generateVideo(_ videoName: String) -> URL {
        return URL(fileURLWithPath: videoDir.combineDirPath(videoName))
    }
    
    func generateStopframeImage(_ videoDirName: String, _ imageName: String) -> URL {
        let videoDirectory = createCustomPath(videoDir, videoDirName)
        return URL(fileURLWithPath: videoDirectory.combineDirPath(imageName))
    }
    
    // setting media directory
    func generateSettingMeida(_ fileName: String, _ media: MediaType) -> URL {
        switch media {
        case .image:
            return URL(fileURLWithPath: settingImgArchiveDir.combineDirPath(fileName))
        case .sounds:
            return URL(fileURLWithPath: createCustomPath(settingSoundDir, fileName))
        case .templates:
            return URL(fileURLWithPath: createCustomPath(settingTemplateDir, fileName))
        }
    }
    
    //MARK: - file management
    func copyNewMainVideoFile(isCopy: Bool,  _ from: URL, _ to: URL, _ completion: (Bool, String) -> Void) {
        if fileManager.fileExists(atPath: from.path) {
            do {
                if isCopy {
                    try fileManager.copyItem(atPath: from.path, toPath:  to.path)
                } else {
                    try fileManager.moveItem(atPath: from.path, toPath:  to.path)
                }
                completion(true, "Success")
            } catch {
                print(error.localizedDescription)
                completion(false, error.localizedDescription)
            }
        } else {
            completion(false, "There is another file in destination url")
        }
    }
    
    func deleteItems(at url: URL) {
        if checkFileExist(url) {
            do {
                try fileManager.removeItem(at: url)
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func checkFileExist(_ url: URL) -> Bool {
        return fileManager.fileExists(atPath: url.path)
    }
    
    func checkFilesIn(_ dir: URL, _ action: ((URL) -> Void)? = nil) {
        guard let act = action else { return }
        do {
            let tmpFiles = try fileManager.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
            tmpFiles.forEach(act)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func clearTempDir() {
        do {
            let tmpFiles = try fileManager.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
            try tmpFiles.forEach { file in
                try FileManager.default.removeItem(at: file)
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func clearCacheDir() {
        if let cacheURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
            do {
                let directoryContents = try fileManager.contentsOfDirectory( at: cacheURL, includingPropertiesForKeys: nil, options: [])
                for file in directoryContents {
                    do {
                        try fileManager.removeItem(at: file)
                    }
                    catch let error as NSError {
                        debugPrint("Something went wrong with cache: \(error)")
                    }
                }
            } catch let error as NSError {
                print(error.localizedDescription)
            }
        } else {
            return
        }
    }
    
    func getFiles(in dir: URL) -> [URL] {
        do {
            return try fileManager.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
        } catch {
            print(error.localizedDescription)
        }
        return [URL]()
    }
    
    func getFolderSize(of dirUrl: URL) -> UInt64 {
        var resultSize : UInt64 = 0
        let files = getFiles(in: dirUrl)
        for file in files {
            resultSize += sizePerMB(url: file)
        }
        return resultSize
    }
    
    func sizePerMB(url: URL?) -> UInt64 {
        guard let filePath = url?.path else {
            return 0
        }
        do {
            let attribute = try fileManager.attributesOfItem(atPath: filePath)
            if let size = attribute[FileAttributeKey.size] as? NSNumber {
                return size.uint64Value
            }
        } catch {
            print("Error: \(error)")
        }
        return 0
    }
    
    func sizeToPrettyString(size: UInt64) -> String {
        let byteCounterFomatter = ByteCountFormatter()
        byteCounterFomatter.allowedUnits = .useMB
        byteCounterFomatter.countStyle = .file
        return byteCounterFomatter.string(fromByteCount: Int64(size))
    }
    
}

extension String {
    
    func combineDirPath(_ sub: String) -> String {
        return self.appending("/\(sub)")
    }
    
}
