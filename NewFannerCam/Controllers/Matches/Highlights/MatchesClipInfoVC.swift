//
//  MatchesClipInfoVC.swift
//  NewFannerCam
//
//  Created by Jin on 1/3/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import UIKit

protocol MatchesClipInfoVCDelegate: class {
    func onDismissClipInfoVC(with editedClip: Clip)
}

class MatchesClipInfoVC: UIViewController {
    
    @IBOutlet weak var nameTF           : UITextField!
    
    weak var delegate                   : MatchesClipInfoVCDelegate?
    var selectedClip                    : Clip!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nameTF.text = selectedClip.marker.name
    }

    //MARK: - IBAction functions
    @IBAction func onSaveBtn(_ sender: UIButton) {
        guard nameTF.text!.count > 0 else {
            MessageBarService.shared.warning("Input a new name for the selected highlight!")
            return
        }
        selectedClip.marker.name = nameTF.text
        delegate?.onDismissClipInfoVC(with: selectedClip)
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onBackBtn(_ sender: UIButton) {
        navigationController?.dismiss(animated: true, completion: nil)
    }
}
