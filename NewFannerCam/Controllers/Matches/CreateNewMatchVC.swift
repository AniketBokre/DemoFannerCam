//
//  CreateNewMatchVC.swift
//  NewFannerCam
//
//  Created by Jin on 12/27/18.
//  Copyright © 2018 fannercam3. All rights reserved.
//

import UIKit
import MobileCoreServices

class CreateNewMatchVC: UIViewController {

    //MARK: - IBOutlet
    @IBOutlet weak var fstTeamNameTF        : UITextField!
    @IBOutlet weak var fstTeamAbbNameTF     : UITextField!
    @IBOutlet weak var sndTeamNameTF        : UITextField!
    @IBOutlet weak var sndTeamAbbNameTF     : UITextField!
    
    @IBOutlet weak var eventLogoBtn         : UIButton!
    @IBOutlet weak var fstTeamLogoBtn       : UIButton!
    @IBOutlet weak var sndTeamLogoBtn       : UIButton!
    
    @IBOutlet weak var hdBtn                : UIButton!
    @IBOutlet weak var fhdBtn               : UIButton!
    
    var newMatchType = MatchType.recordMatch
    var activatedBtn : UIButton!
    var newMatch     = Match()
    
//MARK: - Override Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Create a new \(newMatchType.rawValue) match"
    }

//MARK: - main Functions
    func setImageFromLib(with image: UIImage) {
        var team : Team?
        if activatedBtn == fstTeamLogoBtn {
            team = .first
        } else if activatedBtn == sndTeamLogoBtn {
            team = .second
        }
        newMatch.setLogos(image, team) { (isDone, resultDes) in
            if isDone {
                DispatchQueue.main.async {
                    self.activatedBtn.setImage(image, for: .normal)
                }
            } else {
                MessageBarService.shared.error(resultDes)
                DispatchQueue.main.async {
                    self.activatedBtn.setImage(nil, for: .normal)
                }
            }
        }
    }
    
    func openPhotoLibrary(forAppLib: Bool) {
        
        func devGallery() {
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.sourceType =  UIImagePickerController.SourceType.savedPhotosAlbum
            picker.mediaTypes = [kUTTypeImage as String]
            present(picker, animated: true, completion: nil)
        }
        
        if forAppLib {
            let nav = appImgArchive()
            present(nav, animated: true, completion: nil)
        } else {
            devGallery()
        }
        
    }
    
//MARK: - IBActions
    @IBAction func onBackBtn(_ sender: Any) {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onImportImgBtn(_ sender: UIButton) {
        
        activatedBtn = sender
        
        presentImportImgSheet(sender, { (appLibAction) in
            self.openPhotoLibrary(forAppLib: true)
        }) { (deviceLibAction) in
            self.openPhotoLibrary(forAppLib: false)
        }
    }
    
    @IBAction func onCreateBtn(_sender: Any) {
        let fstName = (fstTeamNameTF.text)!
        let fstAbbName = (fstTeamAbbNameTF.text)!
        let sndName = (sndTeamNameTF.text)!
        let sndAbbName = (sndTeamAbbNameTF.text)!
        guard ValidationService.validateEmptyStrs([fstName, fstAbbName, sndName, sndAbbName]) else {
            MessageBarService.shared.error("Enter all information")
            return
        }
        newMatch.set(fstName, fstAbbName, sndName, sndAbbName, newMatchType)
        DataManager.shared.updateMatches(newMatch, 0, .new)
        DataManager.shared.updatePurchasedMatchCount(-1)
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onHDResolutionBtn(_ sender: UIButton) {
        newMatch.isResolution1280 = true
        sender.setImage(Constant.Image.CheckMarkWhite.image, for: .normal)
        fhdBtn.setImage(Constant.Image.UncheckMarkWhite.image, for: .normal)
    }
    
    @IBAction func onFHDBtn(_ sender: UIButton) {
        newMatch.isResolution1280 = false
        sender.setImage(Constant.Image.CheckMarkWhite.image, for: .normal)
        hdBtn.setImage(Constant.Image.UncheckMarkWhite.image, for: .normal)
    }
    
}
//MARK: - Alert Functions
extension CreateNewMatchVC {
    
}

//MARK: - SettingsImgArchiveVCDelegate
extension CreateNewMatchVC: SettingsImgArchiveVCDelegate {
    func didSelect(image img: UIImage) {
        setImageFromLib(with: img)
    }
}

//MARK: - UIImagePickerControllerDelegate & UINavigationControllerDelegate
extension CreateNewMatchVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let photoTaken = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            setImageFromLib(with: photoTaken)
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
}

//MARK: - UITextFieldDelegate
extension CreateNewMatchVC: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        guard let text = textField.text else { return false }
        let updatedText = text.string(range, string)
        
        return ValidationService.validateAbbreviation(updatedText)
    }
    
}

