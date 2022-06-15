//
//  SettingImgActionCell.swift
//  NewFannerCam
//
//  Created by Jin on 2/18/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import UIKit

protocol SettingsImgActionCellDelegate: class {
    func actionCell(didClickedAction mode: SettingsImgArchiveVCMode)
}

class SettingImgActionCell: UICollectionViewCell {
    
    @IBOutlet weak var actionBtn            : UIButton!
    
    weak var delegate                       : SettingsImgActionCellDelegate?
    
    func initialization(_ target: SettingsImgArchiveVC, _ mode: SettingsImgArchiveVCMode) {
        delegate = target
        if mode == .show {
            actionBtn.borderWidth = 1
            actionBtn.borderColor = UIColor.lightGray
            actionBtn.setTitle("", for: .normal)
            actionBtn.setImage(UIImage(named: "ic_add_white"), for: .normal)
        } else {
            actionBtn.borderWidth = 0
            actionBtn.setTitle("Delete all", for: .normal)
            actionBtn.setImage(nil, for: .normal)
        }
    }
    
    func initialization1(_ target: SettingsImgArchive2VC, _ mode: SettingsImgArchiveVCMode) {
        delegate = target
        if mode == .show {
            actionBtn.borderWidth = 1
            actionBtn.borderColor = UIColor.lightGray
            actionBtn.setTitle("", for: .normal)
            actionBtn.setImage(UIImage(named: "ic_add_white"), for: .normal)
        } else {
            actionBtn.borderWidth = 0
            actionBtn.setTitle("Delete all", for: .normal)
            actionBtn.setImage(nil, for: .normal)
        }
    }
    
    @IBAction func onActionBtn(_ sender: UIButton) {
        if sender.titleLabel?.text == "Delete all" {
            delegate?.actionCell(didClickedAction: .edit)
        } else {
            delegate?.actionCell(didClickedAction: .show)
        }
    }
    
}
