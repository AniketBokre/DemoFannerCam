//
//  RecoveryCell.swift
//  NewFannerCam
//
//  Created by Jin on 3/13/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import UIKit

class RecoveryCell: UITableViewCell {

    @IBOutlet weak var thumbnailImgView         : UIImageView!
    @IBOutlet weak var descriptionLbl           : UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
