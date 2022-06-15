//
//  HTTPService.swift
//  NewFannerCam
//
//  Created by Jin on 2/16/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import Foundation
import UIKit

class Downloader {
    
    class func loadTemplateMeidas(from urlStr: String, at mode: SettingsTemTraVCMode, _ completion: @escaping (Bool, Any?, String) -> Void) {

        func fetchJsonData(_ urlStr: String, _ completion: @escaping(Response) -> Void) {
            DispatchQueue.global().async {
                let url = URL(string: urlStr)
                URLSession.shared.dataTask(with: url!, completionHandler: { (object, response, error) in
                    if let data = object {
                        do {
                            if let jsonData = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves) as? CustomJSON {
                                let result = Response(jsonData)
                                completion(result)
                            }
                        } catch(let err) {
                            var result = Response()
                            result.message = err.localizedDescription
                            completion(result)
                        }
                    } else {
                        var result = Response()
                        result.message = "Empty JSON!"
                        completion(result)
                    }
                }).resume()
            }
        }
        
        fetchJsonData(urlStr) { (response) in
            if response.success {
                if mode == .soundTracks {
                    let soundtracks = response.soundtracks                    
                    if soundtracks.count > 0 {
                        completion(true, soundtracks as Any, "Soundtrack medias!")
                    } else {
                        completion(false, nil, "No Soundtrack media files in server!")
                    }
                } else {
                    let templates = response.templates
                    if templates.count > 0 {
                        completion(true, templates as Any, "Template medias!")
                    } else {
                        completion(false, nil, "No Template media files in server!")
                    }
                }
            } else {
                completion(false, nil, response.message)
            }
        }
    }
    
    class func downloadFile(_ urlStr: String, _ completion: @escaping(Bool, String) -> Void) {
        
        guard let url = URL(string: urlStr) else {
            completion(false, "Invalid url!")
            return
        }
        
        URLSession.shared.downloadTask(with: url) { (resultURL, response, error) in
            guard let location = resultURL else {
                completion(false, "Failed!")
                return
            }
            let destinationTempURL = dirManager.tempSingleClipVideo()
            print(destinationTempURL)
            dirManager.copyNewMainVideoFile(isCopy: false, location, destinationTempURL, { (success, resultDes) in
                completion(success, resultDes)
            })
            
        }.resume()
    }
    
    class func fileDownload(from fromUrl: String, to toUrl: URL, isMov: Bool) {
        let downloadData = NSData(contentsOf: URL(string: fromUrl)!)
        if isMov {
            downloadData?.write(to: toUrl, atomically: true)
        } else {
            let img = UIImage(data: downloadData! as Data)
            ImageProcess.save(imgFile: img!, to: toUrl)
        }
    }
    
    class func audioDownload(from fromUrl: String, to toUrl: URL) { // , _ completion: @escaping (Bool, String) -> Void
        let soundData = NSData(contentsOf: URL(string: fromUrl)!)
        soundData?.write(to: toUrl, atomically: true)
    }
    
    class func mediaDownload(from fromUrl: String, to toUrl: URL, _ completion: @escaping(Bool, String) -> Void) {
        guard let url = URL(string: fromUrl) else {
            completion(false, "Invalid url!")
            return
        }
        
        URLSession.shared.downloadTask(with: url) { (resultURL, response, error) in
            guard let location = resultURL else {
                completion(false, "Failed!")
                return
            }

            dirManager.copyNewMainVideoFile(isCopy: false, location, toUrl, { (success, resultDes) in
                completion(success, resultDes)
            })
            
        }.resume()
    }
}
