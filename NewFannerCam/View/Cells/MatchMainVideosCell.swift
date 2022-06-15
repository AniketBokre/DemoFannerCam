//
//  MatchMainVideosCell.swift
//  NewFannerCam
//
//  Created by Jin on 1/29/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import UIKit
import AVFoundation

protocol MatchMainVideosCellDelegate: class {
    func mainVideoCell(_ mainVideoCell: MatchMainVideosCell, didClickOnSaveToDisk button: UIButton)
    func mainVideoCell(_ mainVideoCell: MatchMainVideosCell, didUpdatemainVideoPreview mainVideo: MainVideo, at index: Int)
    func mainVideoCell(_ mainVideoCell: MatchMainVideosCell, didDelete btn: UIButton)
}

class MatchMainVideosCell: UITableViewCell {
    
    @IBOutlet weak var thumnailImgV : UIImageView!
    @IBOutlet weak var durationLbl  : UILabel!
    @IBOutlet weak var loadingView  : UIView!
    @IBOutlet weak var deleteBtn    : UIButton!
    
    weak var delegate: MatchMainVideosCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    @IBAction func onSaveToDiskBtn(_ sender: Any) {
        let btn = sender as! UIButton
        delegate?.mainVideoCell(self, didClickOnSaveToDisk: btn)
    }
    
    @IBAction func onDeleteBtn(_ sender: UIButton) {
        delegate?.mainVideoCell(self, didDelete: sender)
    }

    func initialize(_ data: MainVideo, _ target: MatchesDetailMainVideoVC, _ index: Int) {
        delegate = target
        let duration = Int(CMTimeGetSeconds(data.duration()))
        durationLbl.text = AVPlayerService.getTimeString(from: duration)
        self.loadingView.isHidden = false
        DispatchQueue.global().async {
            let preview = VideoProcess.previewImage(data.filePath(), at: CMTime.zero)
            DispatchQueue.main.async {
                self.thumnailImgV.image = preview
                self.loadingView.isHidden = true
            }
        }
    }
    
}
