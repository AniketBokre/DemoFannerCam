//
//  MatchClipCell.swift
//  NewFannerCam
//
//  Created by Jin on 2/5/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import UIKit
import MarqueeLabel
import AVFoundation

typealias ClipCellData = (scores: String, teamName: String, clipItem: Clip, isHighlighted: Bool)

protocol MatchClipCellDelegate: class {
    func matchClipCell(_ cell: MatchClipCell, didClickMore btn: UIButton)
    func matchClipCell(_ cell: MatchClipCell, didClickCheckButton isChecked: Bool)
    func matchClipCell(_ cell: MatchClipCell, onImageBtn isPreClip: Bool)
}

class MatchClipCell: UITableViewCell {

    @IBOutlet weak var durationBtn          : UIButton!
    @IBOutlet weak var scoreLbl             : MarqueeLabel!
    @IBOutlet weak var highlightedView      : UIView!
    @IBOutlet weak var checkMarkBtn         : UIButton!
    @IBOutlet weak var moreBtn              : UIButton!
    @IBOutlet weak var timeLbl              : UILabel!
    
    @IBOutlet weak var imgCellView          : UIView!
    @IBOutlet weak var imageButton          : UIButton!
    
    @IBOutlet weak var generalCellView      : UIView!
    
    weak var delegate                       : MatchClipCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func initialize(_ data: Any, _ target: MatchesDetailHighlightsVC) {
        
        if let imageClip = data as? ImageClip {             /// image clips such as pre clip
            setLayouts(generalClip: false)
            setImageButton(imageClip: imageClip)
            delegate = target
            highlightedView.isHidden = true
            let checkImg = imageClip.isSelected ? Constant.Image.CheckMarkWhite.image : Constant.Image.UncheckMarkWhite.image
            checkMarkBtn.setImage(checkImg, for: .normal)
            
        }
        
        if let clipData = data as? ClipCellData {           /// general clip
            
            setLayouts(generalClip: true)
            
            let clipItem = clipData.clipItem
            if !clipItem.isReset {
                self.isHidden = true
                return
            } else {
                self.isHidden = false
            }
            
            delegate = target
            highlightedView.isHidden = !clipData.isHighlighted
            
            
            if clipItem.isSelected {
                checkMarkBtn.setImage(Constant.Image.CheckMarkWhite.image, for: .normal)
            } else {
                checkMarkBtn.setImage(Constant.Image.UncheckMarkWhite.image, for: .normal)
            }
            
            if let marker = clipItem.marker {
                durationBtn.setTitle(marker.durationDescription(), for: .normal)
                
                var clipTag = ""
                if let tag = clipItem.clipTag{
                    clipTag = String(describing: tag)
                }
                scoreLbl.text = "\(clipData.scores) \(clipItem.titleDescription()) \(clipTag)"
                
                let startTime = Int(CMTimeGetSeconds(clipItem.getStartTimeInMatch()))
                let timeStr = AVPlayerService.getTimeString(from: startTime)
                timeLbl.text = "\(clipData.teamName) \(clipItem.period ?? "1T") - \(timeStr)"
            }
        }
    }
    
//MARK: - Main functions
    func setLayouts(generalClip: Bool) {
        generalCellView.isHidden = !generalClip
        imgCellView.isHidden = generalClip
        moreBtn.isHidden = !generalClip
    }
    
    func setImageButton(imageClip: ImageClip) {
        if imageClip.isExistingPreClipFile() {
            imageButton.setImage(nil, for: .normal)
            var img : UIImage!
            if let cacheImg = DataManager.shared.getImageCache(forKey: imageClip.id) {
                img = cacheImg
            } else {
                let preview = ImageProcess.getFrame(url: imageClip.getPreClipPath(), fromTime: 0.0)
                img = ImageProcess.resize(image: preview, scaledToSize: imageButton.bounds.size)
                DataManager.shared.set(cache: img, for: imageClip.id)
            }
            imageButton.setBackgroundImage(img, for: .normal)
        } else {
            imageButton.setBackgroundImage(nil, for: .normal)
            imageButton.setImage(Constant.Image.AddWhite.image, for: .normal)
        }
    }
    
//MARK: - IBAction functions
    @IBAction func onMoreBtn(_ sender: UIButton) {
        delegate?.matchClipCell(self, didClickMore: sender)
    }
    
    @IBAction func onCheckMarkBtn(_ sender: UIButton) {
        if sender.currentImage == Constant.Image.UncheckMarkWhite.image {
            checkMarkBtn.setImage(Constant.Image.CheckMarkWhite.image, for: .normal)
            delegate?.matchClipCell(self, didClickCheckButton: true)
        } else {
            checkMarkBtn.setImage(Constant.Image.UncheckMarkWhite.image, for: .normal)
            delegate?.matchClipCell(self, didClickCheckButton: false)
        }
    }
    
    @IBAction func onImageButton(_ sender: UIButton) {
        delegate?.matchClipCell(self, onImageBtn: true)
    }

}
