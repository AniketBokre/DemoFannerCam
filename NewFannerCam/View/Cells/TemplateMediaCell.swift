//
//  TemplateMediaCell.swift
//  NewFannerCam
//
//  Created by Jin on 2/22/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import UIKit

protocol TemplateMediaCellDelegate: class {
    func templateMediaCell(_ cell: TemplateMediaCell, didClickCheck btn: UIButton, item: Any)
    func templateMediaCell(_ cell: TemplateMediaCell, didClickPlay item: Any, _ isPlay: Bool)
}

class TemplateMediaCell: UITableViewCell {

    @IBOutlet weak var titleLbl             : UILabel!
    @IBOutlet weak var checkBtn             : UIButton!
    @IBOutlet weak var playBtn              : UIButton!
    
    weak var delegate                       : TemplateMediaCellDelegate?
    var template                            : Template!
    var soundtrack                          : Soundtrack!
    
    var viewMode                            = SettingsTemTraVCMode.soundTracks
    
//MARK: - Override functions
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
//MARK: - main functions
    func initialzie(_ target: SettingsTemTraVC, _ data: Any, _ mode: SettingsTemTraVCMode, _ isPlaying: Bool = false) {
        delegate = target
        viewMode = mode
        
        var title : String!
        var purchasedType = Purchased.free
        var checkImg : UIImage!
        
        if mode == .soundTracks {
            soundtrack = data as? Soundtrack
            title = soundtrack.name
            purchasedType = soundtrack.purchasedType
            checkImg = soundtrack.isSelected ? Constant.Image.CheckMarkWhite.image : Constant.Image.UncheckMarkWhite.image
            
            if isPlaying {
                playBtn.setImage(Constant.Image.PauseWhite.image, for: .normal)
            } else {
                playBtn.setImage(Constant.Image.PlayWhite.image, for: .normal)
            }
        } else {
            template = data as? Template
            title = template.name
            purchasedType = template.purchasedType
            checkImg = template.isSelected ? Constant.Image.CheckMarkWhite.image : Constant.Image.UncheckMarkWhite.image
        }
        
        titleLbl.text = title
        checkBtn.setImage(checkImg, for: .normal)
        switch purchasedType {
        case .free, .purchased:
            setVisibles(isPurchased: true)
            break
        case .unPurchased:
            setVisibles(isPurchased: false)
            break
        }
    }
    
    func setVisibles(isPurchased: Bool) {
        //TODO: - should be enabled by purchased
        checkBtn.isHidden = !isPurchased
    }
    
//MARK: - IBAction functions
    @IBAction func onCheckBtn(_ sender: UIButton) {
        if viewMode == .soundTracks {
            soundtrack.isSelected = !soundtrack.isSelected
            delegate?.templateMediaCell(self, didClickCheck: sender, item: soundtrack as Any)
        } else {
            if !template.isSelected {
                template.isSelected = true
                delegate?.templateMediaCell(self, didClickCheck: sender, item: template as Any)
            }
        }
    }
    
    var isPlayingAudio = false
    
    @IBAction func onPlayBtn(_ sender: UIButton) {
        if soundtrack != nil {
            isPlayingAudio = !isPlayingAudio
            
            if isPlayingAudio {
                sender.setImage(Constant.Image.PauseWhite.image, for: .normal)
            } else {
                sender.setImage(Constant.Image.PlayWhite.image, for: .normal)
            }
            delegate?.templateMediaCell(self, didClickPlay: soundtrack as Any, isPlayingAudio)
        } else {
            delegate?.templateMediaCell(self, didClickPlay: template as Any, true)
        }
    }

}
