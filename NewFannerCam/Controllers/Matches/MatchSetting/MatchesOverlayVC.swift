//
//  MatchesOverlayVC.swift
//  NewFannerCam
//
//  Created by Jin on 1/4/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import UIKit
import MobileCoreServices

enum Overlays: String {
    case sx = "logoBottomSx"
    case dx = "logoBottomDx"
    case scoreboardHidden = "scoreboardHidden"
}

class MatchesOverlayVC: UIViewController {
    
    @IBOutlet weak var logoBottomSxAddBtn           : UIButton!
    @IBOutlet weak var logoBottomSxRemoveBtn        : UIButton!
    @IBOutlet weak var logoBottomDxAddBtn           : UIButton!
    @IBOutlet weak var logoBottomDxRemoveBtn        : UIButton!
    
    @IBOutlet weak var logoBottomSxImgView          : UIImageView!
    @IBOutlet weak var logoBottomDxImgView          : UIImageView!
    
    @IBOutlet weak var scoreboardCheckBtn           : UIButton!
    
    private var importMode                          = Overlays.sx

//MARK: - Override functions
    override func viewDidLoad() {
        super.viewDidLoad()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.myOrientation = .landscape
        
        if let sx = DataManager.shared.overlays[Overlays.sx.rawValue], let image = sx.image() {
            setVisibles(isAddHidden: true, on: .sx, with: image)
        } else {
            setVisibles(isAddHidden: false, on: .sx, with: nil)
        }
        
        if let dx = DataManager.shared.overlays[Overlays.dx.rawValue], let image = dx.image() {
            setVisibles(isAddHidden: true, on: .dx, with: image)
        } else {
            setVisibles(isAddHidden: false, on: .dx, with: nil)
        }
        
        let scoreboardHiddenCheckBtnImage = DataManager.shared.getScoreboardHidden() ? Constant.Image.UncheckMarkWhite.image : Constant.Image.CheckMarkWhite.image
        scoreboardCheckBtn.setImage(scoreboardHiddenCheckBtnImage, for: .normal)
    }
    
//MARK: - Other functions
    func presentSheet(_ sender: UIButton) {
        presentImportImgSheet(sender, { (appLibAction) in
            self.openPhotoLibrary(forAppLib: true)
        }) { (deviceLibAction) in
            self.openPhotoLibrary(forAppLib: false)
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
    
    func getOverlay(of mode: Overlays) -> ImgArchive {
        if let new = DataManager.shared.overlays[mode.rawValue] {
            return new
        } else {
            return ImgArchive()
        }
    }
    
    func setImages(_ image: UIImage) {
        
        let currentOverlay = getOverlay(of: importMode)
        
        currentOverlay.saveImageFile(image) { (isSuccess, resultDes) in
            if isSuccess {
                DispatchQueue.main.async {
                    self.setVisibles(isAddHidden: true, on: self.importMode, with: image)
                }
            } else {
                MessageBarService.shared.error(resultDes)
            }
        }
        DataManager.shared.updateOverlays(currentOverlay, importMode.rawValue, .new)
    }
    
    func removeLogos(mode: Overlays) {
        let currentOverlay = getOverlay(of: importMode)
        DataManager.shared.updateOverlays(currentOverlay, mode.rawValue, .delete)
        setVisibles(isAddHidden: false, on: mode, with: nil)
    }
    
    func setVisibles(isAddHidden: Bool, on mode: Overlays, with image: UIImage?) {
        if mode == .sx {
            logoBottomSxImgView.image = image
            logoBottomSxAddBtn.isHidden = isAddHidden
            logoBottomSxRemoveBtn.isHidden = !isAddHidden
        } else {
            logoBottomDxImgView.image = image
            logoBottomDxAddBtn.isHidden = isAddHidden
            logoBottomDxRemoveBtn.isHidden = !isAddHidden
        }
    }
    
//MARK: - IBAction functions
    @IBAction func onBackBtn(_ sender: Any) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.myOrientation = .portrait
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onLogoSxActionBtns(_ sender: UIButton) {
        importMode = .sx
        
        if sender == logoBottomSxAddBtn {
            presentSheet(sender)
        } else {
            removeLogos(mode: importMode)
        }
    }
    
    @IBAction func onLogoDxActionBtns(_ sender: UIButton) {
        importMode = .dx
        
        if sender == logoBottomDxAddBtn {
            presentSheet(sender)
        } else {
            removeLogos(mode: importMode)
        }
    }
    
    @IBAction func onScoreboardCheck(_ sender: UIButton) {
        let hidden = !DataManager.shared.getScoreboardHidden()
        let scoreboardHiddenCheckBtnImage = hidden ? Constant.Image.UncheckMarkWhite.image : Constant.Image.CheckMarkWhite.image
        scoreboardCheckBtn.setImage(scoreboardHiddenCheckBtnImage, for: .normal)
        DataManager.shared.updateScoreboardHidden(hidden)
    }

}

//MARK: - SettingsImgArchiveVCDelegate
extension MatchesOverlayVC: SettingsImgArchiveVCDelegate {
    
    func didSelect(image img: UIImage) {
        setImages(img)
    }
    
}

//MARK: - UIImagePickerControllerDelegate, UINavigationControllerDelegate
extension MatchesOverlayVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let photoTaken = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            setImages(photoTaken)
        } else {
            MessageBarService.shared.warning("Empty image file. Please select another image!")
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
}
