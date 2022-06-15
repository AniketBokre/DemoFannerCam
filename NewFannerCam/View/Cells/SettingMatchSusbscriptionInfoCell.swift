//
//  SettingMatchSusbscriptionInfoCell.swift
//  NewFannerCam
//
//  Created by dreamskymobi on 5/21/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//
import UIKit

class SettingMatchSusbscriptionInfoCell: UITableViewCell {

    @IBOutlet weak var titleLbl         : UILabel!
    @IBOutlet weak var termBtn          : UIButton!
    @IBOutlet weak var privacyBtn       : UIButton!

    //MARK: - Properties
    var termButtonHandler : (() -> Void)?
    var privacyButtonHandler : (() -> Void)?

    //MARK: - Override functions
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        textLabel?.text = ""
    }

    //MARK: - IBAction functions
    @IBAction func onTermBtn(_ sender: UIButton) {
        termButtonHandler?()
    }
    @IBAction func onPrivacyBtn(_ sender: UIButton) {
        privacyButtonHandler?()
    }


}
