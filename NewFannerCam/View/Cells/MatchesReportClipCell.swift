//
//  MatchesReportClipCell.swift
//  NewFannerCam
//
//  Created by Jin on 2/25/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import UIKit

protocol MatchesReportClipCellDelegate: class {
    func matchReportCell(_ cell: MatchesReportClipCell, didClickedCheckFor team: Team, _ isSelected: Bool, _ selectedReportClip: ReportClip)
}

class MatchesReportClipCell: UITableViewCell {

    @IBOutlet weak var titleLbl         : UILabel!
    @IBOutlet weak var fstCountLbl      : UILabel!
    @IBOutlet weak var sndCountLbl      : UILabel!
    @IBOutlet weak var fstCheckBtn      : UIButton!
    @IBOutlet weak var sndCheckBtn      : UIButton!
    
    weak var delegate                   : MatchesReportClipCellDelegate?
    var reportClip                      : ReportClip!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func initialize(_ target: MatchesDetailReportVC, _ clip: ReportClip) {
        delegate = target
        reportClip = clip
        let checkImgFst = reportClip.checkFst ? Constant.Image.CheckMarkWhite.image : Constant.Image.UncheckMarkWhite.image
        fstCheckBtn.setImage(checkImgFst, for: .normal)
        let checkImgSnd = reportClip.checkSnd ? Constant.Image.CheckMarkWhite.image : Constant.Image.UncheckMarkWhite.image
        sndCheckBtn.setImage(checkImgSnd, for: .normal)
        titleLbl.text = reportClip.clips[0].marker.name
        fstCountLbl.text = "\(reportClip.fstCount ?? 0)"
        sndCountLbl.text = "\(reportClip.sndCount ?? 0)"
    }
    
    @IBAction func onCheckBtn(_ sender: UIButton) {
        let team = sender == fstCheckBtn ? Team.first : Team.second
        if team == .first {
            if reportClip.fstCount != 0 {
                reportClip.checkFst = !reportClip.checkFst
                let checkImgFst = reportClip.checkFst ? Constant.Image.CheckMarkWhite.image : Constant.Image.UncheckMarkWhite.image
                fstCheckBtn.setImage(checkImgFst, for: .normal)
                delegate?.matchReportCell(self, didClickedCheckFor: team, reportClip.checkFst, reportClip)
            }
        } else {
            if reportClip.sndCount != 0 {
                reportClip.checkSnd = !reportClip.checkSnd
                let checkImgSnd = reportClip.checkSnd ? Constant.Image.CheckMarkWhite.image : Constant.Image.UncheckMarkWhite.image
                sndCheckBtn.setImage(checkImgSnd, for: .normal)
                delegate?.matchReportCell(self, didClickedCheckFor: team, reportClip.checkSnd, reportClip)
            }
        }
    }

}
