//
//  SettingImgCell.swift
//  NewFannerCam
//
//  Created by Jin on 2/21/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import UIKit

protocol SettingImgCellDelegate: class {
    func didClickDelete(_ cell: SettingImgCell)
}

class SettingImgCell: UICollectionViewCell {
    @IBOutlet weak var imgView          : UIImageView!
    @IBOutlet weak var deleteBtn        : UIButton!
    
    weak var delegate                   : SettingImgCellDelegate?
    
    func initialization(_ target: SettingsImgArchiveVC, _ mode: SettingsImgArchiveVCMode, _ mediaItem: ImgArchive) {
        delegate = target
        deleteBtn.isHidden = mode != .edit
        
        if mediaItem.fileName.contains(".gif") {
            let data = FileManager.default.contents(atPath: mediaItem.filePath().path)
            
            imgView.image = UIImage.gifImageWithData(data!)
        } else {
            imgView.image = UIImage(contentsOfFile: mediaItem.filePath().path)
        }
        
        
    }
    
    func initialization1(_ target: SettingsImgArchive2VC, _ mode: SettingsImgArchiveVCMode, _ mediaItem: ImgArchive) {
        delegate = target
        deleteBtn.isHidden = mode != .edit
        if mediaItem.fileName.contains(".gif") {
            let data = FileManager.default.contents(atPath: mediaItem.filePath().path)
            
            imgView.image = UIImage.gifImageWithData(data!)
        } else {
            imgView.image = UIImage(contentsOfFile: mediaItem.filePath().path)
        }
    }
    
    @IBAction func onDeleteBtn(_ sender: UIButton) {
        delegate?.didClickDelete(self)
    }
    
}
