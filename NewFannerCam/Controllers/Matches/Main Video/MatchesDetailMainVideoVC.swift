//
//  MatchesDetailMainVideoVC.swift
//  NewFannerCam
//
//  Created by Jin on 1/3/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import UIKit
import MobileCoreServices

class MatchesDetailMainVideoVC: UIViewController {

    @IBOutlet weak var mTableView       : UITableView!
    @IBOutlet weak var recordSV         : UIStackView!
    @IBOutlet weak var importBtn        : UIButton!
    @IBOutlet weak var startLiveBtn     : UIButton!
    @IBOutlet weak var noVideoLbl       : UILabel!
    
    var selectedMatch                   : SelectedMatch!
    var fanGenService                   : FanGenerationService!
    
    private var recoveryVC              : MatchRecoveryVC!
    
    // Google Auth
//    var liveHandler                     : Presenter!
    
//MARK: - Override functions
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == Constant.Segue.MatchesRecordSegueId {
            let vc = segue.destination as! MatchesMainVideoRecordVC
            vc.selectedMatch = selectedMatch
            vc.titleForWatch = self.navigationController?.navigationBar.topItem?.title ?? "" //  self.navigationItem.title ?? ""
//            if selectedMatch.match.type == .liveMatch {
//                vc.output = liveHandler
//                liveHandler.delegate = vc
//            }
        }
        if segue.identifier == Constant.Segue.MatchesVideoPlaySegueId {
            let vc = segue.destination as! MatchesMainVideoPlayVC
            let index = sender as! Int
            let mainVideo = selectedMatch.match.mainVideos[index]
            vc.selectedMainVideo = SelectedMainVideo(mainVideo: mainVideo, index: index)
            vc.selectedMatch = selectedMatch
        }
        
        if segue.identifier == Constant.Segue.MatchRecoverySegueId {
            let vc = segue.destination as! MatchRecoveryVC
            vc.delegate = self
            vc.selectedMatch = selectedMatch
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        if selectedMatch.match.type == .liveMatch {
//            let dependencies = Dependencies()
//            dependencies.configure(self)
//        }
        
        fanGenService = FanGenerationService(selectedMatch, .importVideo)
        setLayouts()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        mTableView.reloadData()
    }
    
//MARK: - Init funcitons
    func setLayouts() {
        recordSV.isHidden = selectedMatch.match.type != .recordMatch
        importBtn.isHidden = selectedMatch.match.type != .importMatch
        startLiveBtn.isHidden = selectedMatch.match.type != .liveMatch
        
        noVideoLbl.isHidden = !selectedMatch.match.mainVideos.isEmpty
    }
    
    func updateMainVideoList(_ newMatch: Match) {
        DispatchQueue.main.async {
            self.selectedMatch.match = newMatch
            self.fanGenService.selectedMatch = self.selectedMatch
            self.mTableView.reloadData()
            self.setLayouts()
        }
    }
    
    func saveMatch() {
        DataManager.shared.updateMatches(selectedMatch.match, selectedMatch.index, .replace)
    }
    
    // publick funciton
    func startActivity() {
        Utiles.setHUD(true, DataManager.shared.tabberView, .extraLight, "Authenticating...")
    }
    
    func stopActivity() {
        Utiles.setHUD(false)
    }
    
//    func creadeBroadcast() {
//        let alert = UIAlertController(title: APP_NAME, message: "You really want to create a new Live broadcast video?", preferredStyle: UIAlertController.Style.alert)
//        let confirmAction = UIAlertAction(title: "Confirm", style: .default) { (confirmAction) in
//            self.liveHandler.createBroadcast({ (error) in
//                if let err = error {
//                    MessageBarService.shared.alert(message: "Error: \(err.localizedDescription)")
//                } else {
//                    self.liveHandler.launchReloadData()
//                }
//            })
//        }
//        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
//        alert.addAction(confirmAction)
//        alert.addAction(cancel)
//        present(alert, animated: true, completion: nil)
//    }
    
    func goToRecordVC() {
        Utiles.setHUD(false)
        setOrientation(isPortrait: false)
        if selectedMatch.match.isExceededLimitMatchTime() {
            MessageBarService.shared.alert(title: "Warning", message: "Match time is limited at 180 minutes! Cannot record more!")
        } else {
            performSegue(withIdentifier: Constant.Segue.MatchesRecordSegueId, sender: MatchType.liveMatch)
        }
    }

//MARK: - IBActions
    @IBAction func onRecordBtn(_ sender: UIButton) {
        goToRecordVC()
        
    }
    
    @IBAction func onStartLiveBtn(_ sender: UIButton) {
//        liveHandler.launchShow()
    }
    
    @IBAction func onRecoveryBtn(_ sender: UIButton) {
        performSegue(withIdentifier: Constant.Segue.MatchRecoverySegueId, sender: nil)
    }
    
    @IBAction func onImportBtn(_ sender: Any) {
        if selectedMatch.match.isExceededLimitMatchTime() {
            MessageBarService.shared.alert(title: "Warning", message: "Match time is limited at 180 minutes! Cannot record more!")
        } else {
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.sourceType =  UIImagePickerController.SourceType.savedPhotosAlbum
            picker.mediaTypes = [kUTTypeMovie as String]
            picker.videoQuality = .typeHigh
            present(picker, animated: false, completion: nil)
        }
    }
}

//MARK: - UIImagePickerControllerDelegate
extension MatchesDetailMainVideoVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let videoUrl = info[UIImagePickerController.InfoKey.mediaURL] as! URL
        let newUrl = fanGenService.createNewMainVideo()
        
        Utiles.setHUD(true, DataManager.shared.tabberView, .extraLight, "Adjusting this video for the match...")
        
        dirManager.copyNewMainVideoFile(isCopy: true, videoUrl, newUrl) { (isSuccess, resultDes) in
            if isSuccess {
                self.mTableView.reloadData()
            } else {
                MessageBarService.shared.error(resultDes)
            }
            Utiles.setHUD(false)
        }
        picker.dismiss(animated: true, completion: nil)
    }
}

//MARK: - MatchRecoveryVCDelegate
extension MatchesDetailMainVideoVC: MatchRecoveryVCDelegate {
    func dismissRecoveryVC(withLostMainVideos lostMainVideos: [MainVideo]?) {
        if let newItems = lostMainVideos {
            selectedMatch.match.mainVideos.append(contentsOf: newItems)
            selectedMatch.match.sortMainVideos()
            selectedMatch.match.resetMainVideoStartTimes()
            saveMatch()
        }
    }
}

//MARK: - MatchMainVideosCellDelegate
extension MatchesDetailMainVideoVC: MatchMainVideosCellDelegate {
    
    func mainVideoCell(_ mainVideoCell: MatchMainVideosCell, didClickOnSaveToDisk button: UIButton) {
        let indexPath = mTableView.indexPath(for: mainVideoCell)!
        let mainVideo = selectedMatch.match.mainVideos[indexPath.row]
        Utiles.setHUD(true, DataManager.shared.tabberView, .extraLight, "Saving video...")
        
        PhotoGalleryService().saveVideo(of: mainVideo.filePath()) { (isSucceed, resultDes) in
            if isSucceed {
                MessageBarService.shared.notify("Saved successfully!")
            } else {
                MessageBarService.shared.error(resultDes)
            }
            Utiles.setHUD(false)
        }
    }
    
    func mainVideoCell(_ mainVideoCell: MatchMainVideosCell, didUpdatemainVideoPreview mainVideo: MainVideo, at index: Int) {
        selectedMatch.match.update(newMainVideo: mainVideo, updater: .replace, index: index)
        saveMatch()
    }
    
    func mainVideoCell(_ mainVideoCell: MatchMainVideosCell, didDelete btn: UIButton) {
        let index = mTableView.indexPath(for: mainVideoCell)!
        MessageBarService.shared.alertQuestion(title: "Warning!", message: "All clips relating to this main video file will be deleted and cannot be restored! Are you sure you want to delete this main video?", yesString: "Yes", noString: "No", onYes: { (yesAction) in

            self.selectedMatch.match.update(newMainVideo: self.selectedMatch.match.mainVideos[index.row], updater: .delete, index: index.row)
            self.saveMatch()
            
        }, onNo: nil)
    }
    
}

//MARK: - Table view delegate & data source
extension MatchesDetailMainVideoVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return selectedMatch.match.mainVideos.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if UI_USER_INTERFACE_IDIOM() == .phone {
            return Utiles.videoCellHeight()
        } else {
            return Utiles.videoCellHeight() + 30
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constant.Cell.MatchMainVideoCellId, for: indexPath) as! MatchMainVideosCell
        cell.initialize(selectedMatch.match.mainVideos[indexPath.row], self, indexPath.row)
        cell.deleteBtn.isHidden = selectedMatch.match.type == .recordMatch
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.myOrientation = .landscape
        performSegue(withIdentifier: Constant.Segue.MatchesVideoPlaySegueId, sender: indexPath.row)
    }
    
}
