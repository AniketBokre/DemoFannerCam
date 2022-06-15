//
//  StopFramePopupVC.swift
//  NewFannerCam
//
//  Created by Jin on 1/13/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import UIKit
import MobileCoreServices

protocol StopFramePopupVCDelegte: class {
    func dismissEditPopup(with stopframe: StopFrame)
    func onPopupAddedImage(with stopframe: StopFrame)
    func onPopupDeleteBtn(with stopframe: StopFrame)
}

class StopFramePopupVC: UIViewController {
    
    @IBOutlet weak var editBtn      : UIButton!
    @IBOutlet weak var addBtn       : UIButton!

    var stopframe                   : StopFrame!
    weak var delegate               : StopFramePopupVCDelegte?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setLayout()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constant.Segue.VideoStopframeEditSegueId {
            let vc = segue.destination as! StopFrameEditVC
            vc.delegate = self
            vc.stopframe = stopframe
        }
    }
    
    //MARK: - Main functions
    func setLayout() {
        if stopframe.isExistingImage() {
            editBtn.isEnabled = true
            editBtn.alpha = 1
            let image = ImageProcess.resize(image: stopframe.image() ?? UIImage(), scaledToSize: CGSize(width: 100, height: 150))
            addBtn.setBackgroundImage(image, for: .normal)
            addBtn.setImage(nil, for: .normal)
        }
    }
    
//MARK: - IBAction
    @IBAction func onEditBtn(_ sender: Any) {
        performSegue(withIdentifier: Constant.Segue.VideoStopframeEditSegueId, sender: stopframe)
    }
    
    @IBAction func onPlusBtn(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType =  UIImagePickerController.SourceType.savedPhotosAlbum
        picker.mediaTypes = [kUTTypeImage as String]
        present(picker, animated: true, completion: nil)
    }
    
    @IBAction func onDeleteBtn(_ sender: Any) {
        dismiss(animated: true, completion: nil)
        delegate?.onPopupDeleteBtn(with: stopframe)
    }

}

//MARK: - StopFrameEditVCDelegate
extension StopFramePopupVC: StopFrameEditVCDelegate {
    func dismiss(with stopframe: StopFrame) {
        self.stopframe = stopframe
        delegate?.dismissEditPopup(with: stopframe)
    }
}

//MARK: - UIImagePickerControllerDelegate & UINavigationControllerDelegate
extension StopFramePopupVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let photoTaken = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            ImageProcess.save(imgFile: photoTaken, to: stopframe.imagePath()) { (isSucceed, resultDes) in
                if isSucceed {
                    DispatchQueue.main.async {
                        self.setLayout()
                    }
                } else {
                    DispatchQueue.main.async {
                        MessageBarService.shared.error(resultDes)
                    }
                }
            }
        }
        delegate?.onPopupAddedImage(with: stopframe)
        picker.dismiss(animated: true, completion: nil)
    }
}
