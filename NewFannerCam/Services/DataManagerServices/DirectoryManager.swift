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
    
    static let shared = DirectoryManager()
    
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
    private func createCustomPath(_ main: String?, _ sub: String) -> String {
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
    
    // other functions 
    func createNewMatchDirectory(matchName sub: String) -> String {
        let result = matchesDir.combineDirPath(sub)
        try? fileManager.createDirectory(atPath: result, withIntermediateDirectories: false, attributes: nil)
        _ = createCustomPath(result, dirMatchesMainVideo)
        _ = createCustomPath(result, dirMathcesClipVideo)
        
        return result
    }
    
    func matchSubDirs(matchName: String) -> (mainVideoDir: URL, clipVideoDir: URL) {
        let thisMatchDir = createCustomPath(matchesDir, matchName)
        
        let main = createCustomPath(thisMatchDir, dirMatchesMainVideo)
        let clip = createCustomPath(thisMatchDir, dirMathcesClipVideo)
        return (mainVideoDir: URL(string: main)!, clipVideoDir: URL(string: clip)!)
    }
    
    func clearTempDir() {
        do {
            let tmpFiles = try fileManager.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
            try tmpFiles.forEach { file in
                try FileManager.default.removeItem(atPath: file.absoluteString)
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
    
    // file management
    func copyNewMainVideoFile(_ from: URL, _ to: URL) {
        if fileManager.fileExists(atPath: from.path) {
            do {
                try fileManager.moveItem(atPath: from.path, toPath: to.path)
            } catch {
                print(error.localizedDescription)
            }
        } else {
            print("This operation couldn't be performed.")
        }
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
    
}

extension String {
    
    func combineDirPath(_ sub: String) -> String {
        return self.appending("/\(sub)")
    }
    
}
