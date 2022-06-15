//
//  MatchCell.swift
//  NewFannerCam
//
//  Created by Jin on 1/19/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import UIKit

protocol MatchCellDelegate: class {
    func matchCell(_ matchCell: MatchCell, didTapMore button: UIButton, selectedItem: Match)
}

class MatchCell: UITableViewCell {

    @IBOutlet weak var matchNameLbl: UILabel!
    @IBOutlet weak var matchTypeIV: UIImageView!
    @IBOutlet weak var purchasedIV: UIImageView!
    @IBOutlet weak var descriptionLbl: UILabel!
    
    weak var delegate: MatchCellDelegate?
    
    var selfItem : Match?
    
    //MARK: - override functions
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    //MARK: - main functions
    func initialize(_ item: Match, _ target: MatchesVC) {
        delegate = target
        
        selfItem = item
        matchNameLbl.text = item.namePresentation()
        descriptionLbl.text = item.matchDescription()
        purchasedIV.isHidden = !item.isPurchased
        if item.type == .importMatch {
            matchTypeIV.image = Constant.Image.ImportMatch.image
        } else {
            matchTypeIV.image = Constant.Image.RecordMatch.image
        }
    }
    
    @IBAction func onMoreBtn(_ sender: Any) {
        let btn = sender as! UIButton
        delegate?.matchCell(self, didTapMore: btn, selectedItem: selfItem!)
    }

}
