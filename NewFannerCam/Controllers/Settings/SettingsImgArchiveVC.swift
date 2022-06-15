//
//  SettingsImgArchiveVC.swift
//  NewFannerCam
//
//  Created by Jin on 12/30/18.
//  Copyright © 2018 fannercam3. All rights reserved.
//

import UIKit
import MobileCoreServices
import Photos

enum SettingsImgArchiveVCMode {
    case edit
    case show
    case appLib
}

private let actionCellID = "SettingsImgArchiveActionCell"
private let imgCellID = "SettingsImgArchiveImgCell"

protocol SettingsImgArchiveVCDelegate: class {
    func didSelect(image img: UIImage)
}

class SettingsImgArchiveVC: UICollectionViewController, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var editBtn: UIButton!
    
    weak var delegate : SettingsImgArchiveVCDelegate?
    
    var viewMode = SettingsImgArchiveVCMode.show
    
//MARK: - Override functions
    override func viewDidLoad() {
        super.viewDidLoad()

        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 20, left: 0, bottom: 10, right: 0)
        layout.itemSize = CGSize(width: view.bounds.width/4, height: view.bounds.width/4)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        collectionView.collectionViewLayout = layout
        
        editBtn.isHidden = viewMode == .appLib
    }
    
//MARK: - main functions
    func switchAction() {
        switch viewMode {
        case .show:
            viewMode = .edit
            editBtn.setTitle("Cancel", for: .normal)
            break
        case .edit:
            viewMode = .show
            editBtn.setTitle("Edit", for: .normal)
            break
        default:
            break
        }
        collectionView.reloadData()
    }
    
    func delete(all: Bool, index: Int?) {
        guard DataManager.shared.imgArchives.count > 0 else { return }
        
        var message : String!
        if all {
            message = "Are you sure to delete all images?"
        } else {
            message = "Are you sure to delete the selected image?"
        }
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "No", style: .default, handler: nil))
        let yesAction = UIAlertAction(title: "Yes", style: .default) { (yesAction) in
            if all {
                DataManager.shared.updateImgArchives(ImgArchive(), 0, .delete, true)
            } else {
                DataManager.shared.updateImgArchives(DataManager.shared.imgArchives[index!], index!, .delete)
            }
            self.collectionView.reloadData()
        }
        alert.addAction(yesAction)
        present(alert, animated: true, completion: nil)
    }

//MARK: - IBAction functions
    @IBAction func onBackBtn(_ sender: Any) {
        if viewMode == .appLib {
            dismiss(animated: true, completion: nil)
        } else {
            navigationController?.popViewController(animated: true)
        }
        
    }
    
    @IBAction func onEditBtn(_ sender: Any) {
        switchAction()
    }
    
// MARK: - UICollectionViewDataSource & Delegate
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewMode == .appLib ? DataManager.shared.imgArchives.count : DataManager.shared.imgArchives.count + 1
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if viewMode != .appLib, indexPath.row == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: actionCellID, for: indexPath) as! SettingImgActionCell
            cell.initialization(self, viewMode)
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: imgCellID, for: indexPath) as! SettingImgCell
            let index = viewMode == .appLib ? indexPath.item : indexPath.item - 1
            cell.initialization(self, viewMode, DataManager.shared.imgArchives[index])
            return cell
        }
    }

    // MARK: UICollectionViewDelegate
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if viewMode == .appLib {
            delegate?.didSelect(image: UIImage(contentsOfFile: DataManager.shared.imgArchives[indexPath.item].filePath().path) ?? UIImage())
            dismiss(animated: true, completion: nil)
        }
    }

}

//MARK: - SettingsImgActionCellDelegate
extension SettingsImgArchiveVC: SettingsImgActionCellDelegate {
    func actionCell(didClickedAction mode: SettingsImgArchiveVCMode) {
        if viewMode == .show {
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.sourceType =  UIImagePickerController.SourceType.savedPhotosAlbum
            picker.mediaTypes = [kUTTypeImage as String]
            present(picker, animated: true, completion:nil )
        } else {
            delete(all: true, index: nil)
        }
    }
}

//MARK: - SettingImgCellDelegate
extension SettingsImgArchiveVC: SettingImgCellDelegate {
    func didClickDelete(_ cell: SettingImgCell) {
        let index = self.collectionView.indexPath(for: cell)!
        delete(all: false, index: index.item - 1)
    }
}

//MARK: - UIImagePickerControllerDelegate & UINavigationControllerDelegate
extension SettingsImgArchiveVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let imageUrl = info[UIImagePickerController.InfoKey.referenceURL] as? URL {

                let asset = PHAsset.fetchAssets(withALAssetURLs: [imageUrl], options: nil)
                if let image = asset.firstObject {
                    PHImageManager.default().requestImageData(for: image, options: nil) { (imageData, _, _, _) in
                        if let currentImageData = imageData {
                            let isImageAnimated = isAnimatedImage(currentImageData)
                            
                            if isImageAnimated == true {

                                    var newImg = ImgArchive()
                                    newImg.fileName = newImg.fileName.replacingOccurrences(of: ".png", with: ".gif")
                                    ImageProcess.saveGif(imgFile: currentImageData, to: newImg.filePath()) { (isSucceed, resultDes) in
                                        if isSucceed {
                                            DataManager.shared.updateImgArchives(newImg, 0, .new)
                                            DispatchQueue.main.async {
                                                self.collectionView.reloadData()
                                            }
                                        } else {
                                            DispatchQueue.main.async {
                                                MessageBarService.shared.error(resultDes)
                                            }
                                        }
                                    }
                                
                            } else {
                                if let photoTaken = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                                    var newImg = ImgArchive()
                                    ImageProcess.save(imgFile: photoTaken, to: newImg.filePath()) { (isSucceed, resultDes) in
                                        if isSucceed {
                                            DataManager.shared.updateImgArchives(newImg, 0, .new)
                                            DispatchQueue.main.async {
                                                self.collectionView.reloadData()
                                            }
                                        } else {
                                            DispatchQueue.main.async {
                                                MessageBarService.shared.error(resultDes)
                                            }
                                        }
                                    }
                                }
                            }
                            print("isAnimated: \(isImageAnimated)")
                        }
                        
                    }
                }


            }
        
//        if let photoTaken = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
//            let newImg = ImgArchive()
//            ImageProcess.save(imgFile: photoTaken, to: newImg.filePath()) { (isSucceed, resultDes) in
//                if isSucceed {
//                    DataManager.shared.updateImgArchives(newImg, 0, .new)
//                    DispatchQueue.main.async {
//                        self.collectionView.reloadData()
//                    }
//                } else {
//                    DispatchQueue.main.async {
//                        MessageBarService.shared.error(resultDes)
//                    }
//                }
//            }
//        }
        picker.dismiss(animated: true, completion: nil)
    }
    
}
