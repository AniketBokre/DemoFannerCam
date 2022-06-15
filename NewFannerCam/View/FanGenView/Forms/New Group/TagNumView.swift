//
//  TagNumView.swift
//  NewFannerCam
//
//  Created by Jin on 1/23/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import UIKit

protocol TagNumViewDelegate: class {
    func tagNumView(_ tagNumView: TagNumView, didClickedSave btn: UIButton, tagNum value: String)
}

class TagNumView : UIView {
    
    @IBOutlet weak var saveBtn: UIButton!
    @IBOutlet weak var tagNumLbl : UILabel!
    @IBOutlet weak var saveBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var saveTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var numListTopConstraint: NSLayoutConstraint!
    
//MARK: - Properties
    weak var delegate : TagNumViewDelegate?
    
    class func instanceFromNib() -> TagNumView {
        let selfView = UINib(nibName: FanGenId.tagNumViewNib, bundle: nil).instantiate(withOwner: self, options: nil)[0] as! TagNumView
        selfView.initLayout()
        return selfView
    }
    
    required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
    }
    
}

//MARK: - IBActions
extension TagNumView {
    @IBAction func onNumBtn(_ sender: Any) {
        let btn = sender as! UIButton
        guard let btnTitle = btn.titleLabel?.text else {
            return
        }
        switch btnTitle {
        case FanGenTitles.symbol.rawValue:
            //TODO: - implement function when click "#" button
            break
        default:
            if let tagNum = tagNumLbl.text, tagNum.count < 2 {
                if tagNum == FanGenTitles.ten.rawValue {
                    tagNumLbl.text = "\(btnTitle)"
                } else {
                    tagNumLbl.text = "\(tagNum)\(btnTitle)"
                }
            }
            break
        }
    }
    
    @IBAction func onSaveBtn(_ sender: Any) {
        guard (tagNumLbl.text?.count)! > 0 else {
            return
        }
        let btn = sender as! UIButton
        delegate?.tagNumView(self, didClickedSave: btn, tagNum: tagNumLbl.text ?? FanGenTitles.empty.rawValue)
    }
    
    @IBAction func onUndoBtn(_ sender: Any) {
        if let tagNum = tagNumLbl.text, tagNum.count > 0 {
            tagNumLbl.text = String(tagNum.dropLast())
        }
    }
}

//MARK: - data for UI set functions
extension TagNumView {
    func initLayout() {
        
        if UI_USER_INTERFACE_IDIOM() != .phone {
            numListTopConstraint.constant = 40
            saveBottomConstraint.constant = -100
            saveTopConstraint.constant = 40
        }
        
        for index in 179..<190 {
            let btn = viewWithTag(index) as! UIButton
            btn.layer.cornerRadius = btn.bounds.height/2
            btn.maskToBounds = true
        }
    }
}
