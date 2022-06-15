//
//  ImgArchive.swift
//  NewFannerCam
//
//  Created by Jin on 2/21/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import UIKit

struct ImgArchive: Codable {
    
    var fileName                = Date().uniqueNew().setExtension(isMov: false)
    
    enum ImgArchiveKeys : String, CodingKey {
        case fileName           = "ImgArchive_fileName"
    }
    
//MARK: - Main functions
    //getting functions
    func filePath() -> URL {
        return dirManager.generateSettingMeida(fileName, .image)
    }
    
    func removeFile() {
        dirManager.deleteItems(at: filePath())
    }
    
    func saveImageFile(_ image: UIImage, _ completion: @escaping (Bool, String) -> Void) {
        removeFile()
        
        ImageProcess.save(imgFile: image, to: filePath()) { (isSucceed, resultDes) in
            completion(isSucceed, resultDes)
        }
    }
    
    func image() -> UIImage? {
        return UIImage(contentsOfFile: filePath().path)
    }
    
//MARK: - Init functions
    init() {
        
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: ImgArchiveKeys.self)
        
        fileName = try container.decode(String.self, forKey: .fileName)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: ImgArchiveKeys.self)
        try container.encode(fileName, forKey: .fileName)
    }
    
}
