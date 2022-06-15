//
//  SettingsMarkersDetailDropDownCell.swift
//  NewFannerCam
//
//  Created by Jin on 12/28/18.
//  Copyright © 2018 fannercam3. All rights reserved.
//

import UIKit
import DropDown

protocol SettingsMarkersDetailDropDownCellDelegate : class {
    func onEdit(_ cell: SettingsMarkersDetailDropDownCell)
    func onDelete(_ cell: SettingsMarkersDetailDropDownCell)
    func onChangeDurationBtn(_ cell: SettingsMarkersDetailDropDownCell, selectedDuration: Float64)
}

class SettingsMarkersDetailDropDownCell: DropDownCell {
    
//    @IBOutlet weak var optionLabel: UILabel!
    
//    @IBOutlet override weak var optionLabel: UILabel!
    
    @IBOutlet  weak var onDeleteBtn : UIButton!
    
    weak var delegate               : SettingsMarkersDetailDropDownCellDelegate?
    var marker                      : Marker!
    var index                       : Int!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func initialize(_ target: SettingsMarkersVC, _ data: Marker, _ index: Int) {
        delegate = target
        marker = data
        self.index = index
        
        if marker.type == .generic {
            onDeleteBtn.isEnabled = false
            onDeleteBtn.alpha = 0.5
        }
    }
    
    @IBAction func onEditBtn(_ sender: UIButton) {
        delegate?.onEdit(self)
    }
    
    @IBAction func onDeleteBtn(_ sender: UIButton) {
        delegate?.onDelete(self)
    }
    
    @IBAction func onChangeDurationBtn(_ sender: UIButton) {
        if (sender.titleLabel?.text?.contains("30"))! {
            delegate?.onChangeDurationBtn(self, selectedDuration: 30.0)
        }
        else if (sender.titleLabel?.text?.contains("20"))! {
            delegate?.onChangeDurationBtn(self, selectedDuration: 20.0)
        }
        else {
            delegate?.onChangeDurationBtn(self, selectedDuration: 10.0)
        }
    }
    
}
