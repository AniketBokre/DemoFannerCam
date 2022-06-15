//
//  TagListViewCell.swift
//  NewFannerCam
//
//  Created by Jin on 1/24/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import UIKit

protocol TagListViewCellDelegate: class {
    func tagListViewCell(_ cell: TagListViewCell, didTapTagBtn btn: UIButton)
}

class TagListViewCell: UITableViewCell {

    @IBOutlet weak var tagBtn               : UIButton!
    
    @IBOutlet weak var heightCons           : NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    weak var delegate                       : TagListViewCellDelegate?

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func initData(_ marker: Marker, _ target: TagsView) {
        delegate = target
        tagBtn.setTitle("#\(marker.name ?? String())", for: .normal)
        
        if UI_USER_INTERFACE_IDIOM() != .phone {
            heightCons.constant = 40
            tagBtn.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        }
    }
    
    @IBAction func onTagBtn(_ sender: UIButton) {
        delegate?.tagListViewCell(self, didTapTagBtn: sender)
    }
    
    
    
    
}
