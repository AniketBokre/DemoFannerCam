//
//  SettingsMarkersDetailVC.swift
//  NewFannerCam
//
//  Created by Jin on 12/28/18.
//  Copyright © 2018 fannercam3. All rights reserved.
//

import UIKit

enum SettingsMarkersDetailMode: String {
    case new            = "New tag"
    case edit           = "Edit tag"
}

class SettingsMarkersDetailVC: UIViewController {

    @IBOutlet weak var saveBtn              : UIBarButtonItem!
    @IBOutlet weak var tagNameTF            : UITextField!
    @IBOutlet weak var durationTF           : UITextField!
    
    var detailMode              = SettingsMarkersDetailMode.new
    var currentMarker           : Marker!
    var index                   : Int!
    
    var markerType              : MarkerType = MarkerType.individual
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = detailMode.rawValue
        if detailMode == .edit {
            tagNameTF.text = currentMarker.titleDescription()
            let duration = currentMarker.durationDescription()
            durationTF.text = String(duration.dropLast())
        }
    }

    @IBAction func onBackBtn(_ sender: Any) {
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onSaveBtn(_ sender: Any) {
        guard tagNameTF.text?.count != 0 else {
            MessageBarService.shared.warning("Tag name is required!")
            return
        }
        
        guard ValidationService.validateMarkerDuration(durationTF.text!) else {
            MessageBarService.shared.warning("Duration should be lower than 30!")
            return
        }
        
        if detailMode == .new {
            currentMarker = Marker(Date().uniqueNew(), tagNameTF.text!, markerType, Float64(durationTF.text ?? String())!)
            DataManager.shared.updateSettingMarkers(currentMarker, 0, .new)
        } else {
            currentMarker.name = tagNameTF.text
            currentMarker.duration = Float64(durationTF.text ?? String())
            DataManager.shared.updateSettingMarkers(currentMarker, index, .replace)
        }
        navigationController?.dismiss(animated: true, completion: nil)
    }
}

//MARK: - UITextFieldDelegate
extension SettingsMarkersDetailVC: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {        
        return true
    }
    
}
