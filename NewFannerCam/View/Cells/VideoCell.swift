//
//  VideoCell.swift
//  NewFannerCam
//
//  Created by Jin on 2/15/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import UIKit
import AVFoundation
import MarqueeLabel

protocol VideoCellDelegate: class {
    func videoCell(_ cell: VideoCell, didClickedMore btn: UIButton)
}

class VideoCell: UITableViewCell {

    @IBOutlet weak var thumbnailImgView         : UIImageView!
    @IBOutlet weak var durationLbl              : MarqueeLabel!
    @IBOutlet weak var nameLbl                  : UILabel!
    @IBOutlet weak var purchaseIcon             : UIImageView!
    @IBOutlet weak var loadingView              : UIView!
    
    weak var delegate                           : VideoCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func initialize(_ data: Video, _ target: VideosVC) {
        delegate = target
        durationLbl.text = AVPlayerService.getTimeString(from: data.duration())
        nameLbl.text = data.title
        loadingView.isHidden = false
        
        backgroundQueue.async {
            var thumbnail: UIImage!
            if let cacheImage = DataManager.shared.getImageCache(forKey: data.fileName) {
                thumbnail = cacheImage
            } else {
                let preview = ImageProcess.getFrame(url: data.filePath(), fromTime: 4.0)
                thumbnail = ImageProcess.resize(image: preview, scaledToSize: CGSize(width: Utiles.screenWidth(), height: (Utiles.screenWidth()/16)*9))
                DataManager.shared.set(cache: thumbnail, for: data.fileName)
            }
            
            DispatchQueue.main.async {
                self.thumbnailImgView.image = thumbnail
                self.loadingView.isHidden = true
            }
        }
    }
    
    @IBAction func onMoreBtn(_ sender: UIButton) {
        delegate?.videoCell(self, didClickedMore: sender)
    }

}
