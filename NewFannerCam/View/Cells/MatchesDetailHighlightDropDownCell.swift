//
//  MatchesDetailHighlightDropDownCell.swift
//  NewFannerCam
//
//  Created by Jin on 1/3/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import UIKit
import DropDown

protocol MatchesDetailHighlightDropDownCellDelegate: class {
    func clipDropCell(_ clipIndex: Int, _ clipCell: MatchClipCell, didClickedDelete clip: Clip)
    func clipDropCell(_ clipIndex: Int, didClickedInfo clip: Clip)
    func clipDropCell(_ clipIndex: Int, didClickedReplay clip: Clip)
    func clipDropCell(_ clipIndex: Int, didClickedBanner clip: Clip, _ sender: UIButton)
    func clipDropCell(_ clipIndex: Int, didClickedShare clip: Clip, _ sender: UIButton)
}

class MatchesDetailHighlightDropDownCell: DropDownCell {
    
    @IBOutlet weak var replayBtn        : UIButton!

    private var clip                    : Clip!
    private weak var delegate           : MatchesDetailHighlightDropDownCellDelegate?
    private var clipIndex               : Int = 0
    private var selectedClipCell        : MatchClipCell!
    private var senderBtn               : UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func initialize(_ data: Clip, _ target: MatchesDetailHighlightsVC, _ index: Int, _ cell: MatchClipCell, _ sender: UIButton) {
        clip = data
        if clip.isReplay {
            replayBtn.isEnabled = false
            replayBtn.alpha = 0.5
        } else {
            replayBtn.isEnabled = true
            replayBtn.alpha = 1
        }
        delegate = target
        clipIndex = index
        selectedClipCell = cell
        senderBtn = sender
    }
    
    //MARK: - IBActions
    @IBAction func onDeleteBtn(_ sender: UIButton) {
        delegate?.clipDropCell(clipIndex, selectedClipCell, didClickedDelete: clip)
    }
    
    @IBAction func onInfoBtn(_ sender: UIButton) {
        delegate?.clipDropCell(clipIndex, didClickedInfo: clip)
    }
    
    @IBAction func onReplayBtn(_ sender: UIButton) {
        delegate?.clipDropCell(clipIndex, didClickedReplay: clip)
    }
    
    @IBAction func onBannerBtn(_ sender: UIButton) {
        delegate?.clipDropCell(clipIndex, didClickedBanner: clip, senderBtn)
    }
    
    @IBAction func onShareBtn(_ sender: UIButton) {
        delegate?.clipDropCell(clipIndex, didClickedShare: clip, senderBtn)
    }
    
}
