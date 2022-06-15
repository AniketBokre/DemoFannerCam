//
//  ImageClip.swift
//  NewFannerCam
//
//  Created by Jin on 3/11/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import UIKit
import AVFoundation

struct ImageClip: Codable {
    
    var id                      = Date().uniqueNew()
    var matchName               : String!
    var isSelected              : Bool = false
    
    enum ImageClipKeys : String, CodingKey {
        case id                 = "ImageClip_id"
        case matchName          = "ImageClip_matchName"
        case isSelected         = "ImageClip_isSelected"
    }
    
//MARK: - Main functions
    //getting functions
    func filePath() -> URL {
        return dirManager.generateSettingMeida(id, .image)
    }
    
    func getPreClipPath() -> URL {
        return dirManager.matchPreClipPath(matchName)
    }
    
    func isExistingPreClipFile() -> Bool {
        return dirManager.checkFileExist(getPreClipPath())
    }
    
    func removePreClip() {
        dirManager.deleteItems(at: getPreClipPath())
    }
    
    // setting functions
    mutating func setSelected(val: Bool) {
        isSelected = val
    }
    
//MARK: - Main Functions
    func setPreClip(from fromUrl: URL, quality: String, _ completion: @escaping (Bool, String) -> Void) {
        backgroundQueue.async {            
            VideoProcess().saveVideoFromGallery(inputURL: fromUrl, imgClip: self, quality: quality, { (isSuccess, resultDes) in 
                completion(isSuccess, resultDes)
            })
        }
    }
    
//MARK: - Init functions
    init(_ matchName: String) {
        self.matchName = matchName
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: ImageClipKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        matchName = try container.decode(String.self, forKey: .matchName)
        isSelected = try container.decode(Bool.self, forKey: .isSelected)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: ImageClipKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(matchName, forKey: .matchName)
        try container.encode(isSelected, forKey: .isSelected)
    }
    
}
