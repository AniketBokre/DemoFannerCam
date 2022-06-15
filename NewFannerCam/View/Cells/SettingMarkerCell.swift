//
//  SettingMarkerCell.swift
//  NewFannerCam
//
//  Created by Jin on 2/16/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import UIKit

protocol SettingMarkerCellDelegate : class {
    func settingMarkerCell(didClickedMore settingMarkerCell: SettingMarkerCell)
}

class SettingMarkerCell: UITableViewCell {
    
    @IBOutlet weak var nameLbl          : UILabel!
    @IBOutlet weak var durationLbl      : UILabel!

    weak var delegate                   : SettingMarkerCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func initialize(_ marker: Marker, _ target: SettingsMarkersVC, _ isHightlighted: Bool) {
        delegate = target
        
        nameLbl.text = marker.titleDescription()
        durationLbl.text = "<<\(marker.durationDescription())"
        if isHightlighted {
            nameLbl.textColor = #colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 1)
            durationLbl.textColor = #colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 1)
            self.backgroundColor = #colorLiteral(red: 0.3333333433, green: 0.3333333433, blue: 0.3333333433, alpha: 1)
        } else {
            nameLbl.textColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            durationLbl.textColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            self.backgroundColor = #colorLiteral(red: 0.1298420429, green: 0.1298461258, blue: 0.1298439503, alpha: 1)
        }
    }
    
    @IBAction func onMoreBtn(_ sender: UIButton) {
        delegate?.settingMarkerCell(didClickedMore: self)
    }

}
