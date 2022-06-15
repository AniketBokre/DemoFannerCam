//
//  MatchesDetailHighlightsVC.swift
//  NewFannerCam
//
//  Created by Jin on 1/3/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import UIKit
import DropDown
import MobileCoreServices
import AVFoundation
import StoreKit

private let cellId = "MatchesHighlightsCell"

enum ImportType: String {
    case banner
    case preClip
}

class MatchesDetailHighlightsVC: UIViewController {

    @IBOutlet weak var mTableView           : UITableView!
    @IBOutlet weak var clipSliderView       : UIView!
    @IBOutlet weak var clipDurationLbl      : UILabel!
    @IBOutlet weak var previewContainer     : UIView!
    @IBOutlet weak var previewLoadingView   : UIView!
    @IBOutlet weak var previewPlayBtn       : UIButton!
    @IBOutlet weak var bannerRemoveBtn      : UIButton!
    @IBOutlet weak var fullScreenModeBtn    : UIButton!
    @IBOutlet weak var clipBannerImgView    : UIImageView!
    @IBOutlet weak var btnSelectAll    : UIButton!

    
    private var dropDown                    : DropDown? 
    private var highlightedClipIndex        = 0
    
    var selectedMatch                       : SelectedMatch!
    
    private var activatedClipWithMoreOption : Clip!
    private var clipSlider                  : AORangeSlider!
    private var avplayerService             : AVPlayerService!
    private var previewPlayView             : UIView!
    
//MARK: - Override functions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        checkResetClips()
        
        NotificationCenter.default.addObserver(self, selector: #selector(didLeaveMatchTab(_:)), name: .DidLeaveMatchTab, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        setLayout()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constant.Segue.MatchesReportSegueId {
            let nav = segue.destination as! UINavigationController
            let vc = nav.children[0] as! MatchesDetailReportVC
            vc.selectedMatch = selectedMatch
        }
        else if segue.identifier == Constant.Segue.MatchesDetailClipInfoSegueId {
            let nav = segue.destination as! UINavigationController
            let vc = nav.children[0] as! MatchesClipInfoVC
            vc.delegate = self
            let selectedClip = sender as! Clip
            vc.selectedClip = selectedClip
        }
        else if segue.identifier == Constant.StoryboardIds.RecapListVC {
            let vc = segue.destination as! RecapListVC
            vc.selectedMatch = selectedMatch
        }
    }
    
//MARK: - Layout functions
    @objc func didLeaveMatchTab(_ notification: Notification) {
        if avplayerService != nil, avplayerService.isPlaying {
            avplayerService.setPlayer()
            previewPlayBtn.setImage(Constant.Image.PlayWhite.image, for: .normal)
        }
    }
    
    func setLayout() {
        if selectedMatch.match.isEmptyClips() {
            
        } else {
            initClipSlider()
            setClipPreview(with: selectedMatch.match.getFilteredClips()[highlightedClipIndex])
        }
    }
    
    func initClipSlider() {
        
        if clipSlider != nil {
            clipSlider.removeFromSuperview()
            clipSlider = nil
        }
        
        clipSlider = AORangeSlider(frame: clipSliderView.bounds)
        clipSliderView.addSubview(clipSlider)
        clipSliderView.bringSubviewToFront(clipDurationLbl)
        
        clipSlider.highHandleImageNormal = DataManager.shared.clipSliderHandleImage
        clipSlider.lowHandleImageNormal = DataManager.shared.clipSliderHandleImage
        clipSlider.stepValue = 0.1
        clipSlider.minimumDistance = 1.0
        clipSlider.stepValueContinuously = true
        clipSlider.minimumValue = 0
        clipSlider.maskToBounds = true
        
        clipSlider.valuesChangedHandler = { [weak self] in
            guard let `self` = self else {
                return
            }
            
            if self.avplayerService != nil, self.avplayerService.isPlaying {
                self.avplayerService.setPlayer()
                self.previewPlayBtn.setImage(Constant.Image.PlayWhite.image, for: .normal)
            }
            
            var temp = self.selectedMatch.match.getFilteredClips()[self.highlightedClipIndex]
            
            if !self.clipSlider.isTracking {
                self.setDurationLbl(with: temp)
                return
            }
            
            if self.clipSlider.lowValue >= self.clipSlider.highValue {
                return
            }
            
//            if (temp.getSliderHighVal()).rounded(digits: 1) != (self.clipSlider.highValue).rounded(digits: 1) {
            if temp.highValue != Float64(self.clipSlider.highValue) {
                temp.set(highValue: Float64(self.clipSlider.highValue))
                self.setTrackBgImageToSlider(of: temp, isNeededSetClipSlider: false, isLowValue: false)
            } else if temp.lowValue != Float64(self.clipSlider.lowValue) {
                temp.set(lowValue: Float64(self.clipSlider.lowValue))
                self.setTrackBgImageToSlider(of: temp, isNeededSetClipSlider: false, isLowValue: true)
            } else {
                return
            }
//            if temp.getSliderLowVal().rounded(digits: 1) != self.clipSlider.lowValue.rounded(digits: 1) {
            
            print("slider : ", Float64(self.clipSlider.highValue) - Float64(self.clipSlider.lowValue))
            
            self.selectedMatch.match.update(newClip: temp, updater: .replace)
            self.save(requiredDelegate: false)
            
            self.setDurationLbl(with: temp)
            self.staticReload()
        }
    }
    
    func setClipPreview(with clip: Clip) {
        initClipSlider()
        onloading(loading: true)
        
        setPreviewPlayView(add: true)
        
        if avplayerService == nil {
            avplayerService = AVPlayerService(previewPlayView, UISlider(), clip.getFilePath(ofMainVideo: true), .partPreview, clip)
            avplayerService.delegate = self
            avplayerService.initPlayer()
        } else {
            avplayerService.setClip(clip, with: previewPlayView)
        }
        
        previewPlayView.isHidden = false
        
        setTrackBgImageToSlider(of: clip, isNeededSetClipSlider: true, isLowValue: true)
    }
    
    func onloading(loading: Bool) {
        previewLoadingView.isHidden = !loading
        clipSlider.isHidden = loading
        clipDurationLbl.isHidden = loading
        previewPlayBtn.isHidden = loading
        if loading {
            clipBannerImgView.isHidden = loading
            bannerRemoveBtn.isHidden = loading
        }
    }
    
    func setTrackBgImageToSlider(of clip: Clip, isNeededSetClipSlider: Bool, isLowValue: Bool) {
        
        if isLowValue {
            avplayerService.seekPlayer(clip.getClipStartTime())
        } else {
            avplayerService.seekPlayer(clip.endTime)
        }
        
        func getPreviewImage(at time: Float64, of clipItem: Clip) -> UIImage {
            if let cacheImg = clipItem.getthumbCache(forKey: time) {
                return cacheImg
            } else {
                let frame = ImageProcess.getFrame(url: clipItem.getFilePath(ofMainVideo: true), fromTime: time.rounded(.up))  // when changed clipSlider.lowValue
                let resized = ImageProcess.resize(image: frame, scaledToSize: clipSlider.bounds.size)
                clipItem.set(cache: resized, at: time)
                return resized
            }
        }
        
        DispatchQueue.main.async {
            if isNeededSetClipSlider {
                let preview = getPreviewImage(at: CMTimeGetSeconds(clip.getClipStartTime()), of: clip)
                self.setClipSlider(preview, with: clip)
            }
        }
    }
    
    func setClipSlider(_ previewImg: UIImage, with clip: Clip) {
        onloading(loading: false)
        
        clipSlider.maximumValue = clip.getSliderMaxVal()
//        clipSlider.highValue = clip.getSliderHighVal()
//        clipSlider.lowValue = clip.getSliderLowVal()
        clipSlider.highValue = clip.highValue
        clipSlider.lowValue = clip.lowValue
        
        clipSlider.trackBackgroundImage = ImageProcess.blurImage(of: previewImg)
        clipSlider.trackImage = previewImg
        setDurationLbl(with: clip)
        setBannerImage(clip)
    }
    
    func setDurationLbl(with clip: Clip) {
        if clipSlider.lowValue >= clipSlider.highValue {
            clipDurationLbl.text = "0 sec"
        }
        clipDurationLbl.sizeToFit()
        clipDurationLbl.center = CGPoint(x: (clipSlider.highCenter.x - clipSlider.lowCenter.x ) * 0.5 + clipSlider.lowCenter.x, y: clipSlider.lowCenter.y * 0.5 + 10)
        clipDurationLbl.text = clip.durationDes()
    }
    
    func setBannerImage(_ clip: Clip) {
        if let bannerImg = clip.getBannerImg(), selectedMatch.match.getFilteredClips()[highlightedClipIndex].id == clip.id {
            let eWidth = (clipBannerImgView.bounds.size.height/bannerImg.size.height) * bannerImg.size.width
            let banner = ImageProcess.resize(image: bannerImg, scaledToSize: CGSize(width: eWidth, height: clipBannerImgView.bounds.height))
            clipBannerImgView.image = banner
            clipBannerImgView.isHidden = false
            bannerRemoveBtn.isHidden = false
        } else {
            clipBannerImgView.isHidden = true
            bannerRemoveBtn.isHidden = true
        }
        
//        clipBannerImgView.isHidden = false
//
//        if let img = VideoProcess.loadImg(from:  selectedMatch.match.matchLogoPath(.first)) {
//            clipBannerImgView.image = img
//        }
        
    }
    
    func setPreviewPlayView(add: Bool) {
        if add {
            previewPlayView = UIView(frame: previewLoadingView.bounds)
            previewContainer.addSubview(previewPlayView)
            previewPlayView.isHidden = true
            
            previewContainer.bringSubviewToFront(clipBannerImgView)
            previewContainer.bringSubviewToFront(bannerRemoveBtn)
            previewContainer.bringSubviewToFront(fullScreenModeBtn)
            previewContainer.bringSubviewToFront(previewPlayBtn)
            previewContainer.bringSubviewToFront(previewLoadingView)
        } else {
            previewPlayView.removeFromSuperview()
        }
    }
    
    func updateHighlights(_ newMatch: Match) {
        selectedMatch.match = newMatch
        DispatchQueue.main.async {
            self.mTableView.reloadData()
        }
    }
    
    @objc func willResignActive() {
        UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
    }
    
//MARK: - Present functions
    func openPhotoLibrary(forAppLib: Bool, isVideo: Bool = false) {
        func devGallery() {
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.sourceType =  UIImagePickerController.SourceType.savedPhotosAlbum
            if isVideo {
                picker.mediaTypes = [kUTTypeMovie as String]
            } else {
                picker.mediaTypes = [kUTTypeImage as String]
            }
            present(picker, animated: true, completion: nil)
        }
        
        if forAppLib {
            let nav = appImgArchive()
            present(nav, animated: true, completion: nil)
        } else {
            devGallery()
        }
        
    }
    
//MARK: - Data functions
    func checkResetClips() {
        let resetClips = selectedMatch.match.clips.filter { !$0.isReset }
        var reset = false
        for resetClip in resetClips {
            var item = resetClip
            item.reset()
            selectedMatch.match.update(newClip: item, updater: .replace)
            reset = true
        }
        if reset {
            save()
        }
    }
    
    func save(requiredDelegate: Bool = true) {
        DataManager.shared.updateMatches(selectedMatch.match, selectedMatch.index, .replace, requiredDelegate)
    }
    
    func staticReload() {
        let offset = mTableView.contentOffset
        mTableView.reloadData()
        mTableView.setContentOffset(offset, animated: false)
    }
    
//MARK: - IBAction functions
    @IBAction func onShareBtn(_ sender: UIButton) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.modalPresentationStyle = .popover
        let createVideoAction = UIAlertAction(title: ActionTitle.createVideo.rawValue, style: .default) { (createVideoAction) in
            self.createVideoSelection(sender: sender)
        }
        let sendToLiverecapAction = UIAlertAction(title: ActionTitle.sendToLiverecap.rawValue, style: .default) { (sendToLiverecapAction) in
            
            if customerId != 0
            {
                self.sendToLiverecapVideoSelection(sender: sender)
            }
            else {
                let alert = UIAlertController(title: "Alert", message: "Please sign in before continue.", preferredStyle: UIAlertController.Style.alert)
                
                let okButtonAction = UIAlertAction(title: "Ok", style: .default) { (okButtonAction) in
                    self.tabBarController?.selectedIndex = 2
                }
                alert.addAction(okButtonAction)
                self.present(alert, animated: true, completion: nil)
            }
            
        }
        alert.addAction(UIAlertAction(title: ActionTitle.cancel.rawValue, style: .cancel, handler: nil))
        alert.addAction(createVideoAction)
        alert.addAction(sendToLiverecapAction)
        if let presenter = alert.popoverPresentationController {
            presenter.sourceView = sender
            presenter.sourceRect = sender.bounds
        }
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func onFilterBtn(_ sender: UIButton) {
        let sheetController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        sheetController.modalPresentationStyle = .popover
        
        let titles = selectedMatch.match.getFilterList()
        
        titles.forEach { (param) in
            let action = self.fanSheetAction(titleData: param, handler: { (sheetAction) in
                if let selectedFilter = Filter(rawValue: sheetAction.title ?? EMPTY_STRING) {
                    self.selectedMatch.match.setFilter(selectedFilter)
                } else {
                    self.selectedMatch.match.setFilter(.marker, sheetAction.title!)
                }
                if self.selectedMatch.match.getFilteredClips().count == 0 {
                    self.onloading(loading: true)
                } else {
                    self.highlightedClipIndex = 0
                    self.setClipPreview(with: self.selectedMatch.match.getFilteredClips()[0])
                }
                self.mTableView.reloadData()
            })
            sheetController.addAction(action)
        }
        
        sheetController.addAction(UIAlertAction(title: ActionTitle.cancel.rawValue, style: .cancel, handler: nil))
        if let presenter = sheetController.popoverPresentationController {
            presenter.sourceView = sender
            presenter.sourceRect = sender.bounds
        }
        present(sheetController, animated: true, completion: nil)
    }
    
    @IBAction func onReportBtn(_ sender: UIButton) {
        performSegue(withIdentifier: Constant.Segue.MatchesReportSegueId, sender: nil)
    }
    
    @IBAction func onPreviewPlayBtn(_ sender: UIButton) {
        if avplayerService.isPlaying {
            previewPlayBtn.setImage(Constant.Image.PlayWhite.image, for: .normal)
        } else {
            avplayerService.setOnlyClip(selectedMatch.match.getFilteredClips()[highlightedClipIndex])
            
            previewPlayBtn.setImage(Constant.Image.PauseWhite.image, for: .normal)
        }
        avplayerService.setPlayer()
    }
    
    @IBAction func onFullModeBtn(_ sender: UIButton) {
        
        if avplayerService != nil {
            if avplayerService.isPlaying {
                avplayerService.setPlayer()
                previewPlayBtn.setImage(Constant.Image.PlayWhite.image, for: .normal)
            }
        }
        
        let storyboard = UIStoryboard(name: Constant.Storyboard.Vidoes, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: Constant.StoryboardIds.VideoPlayerVC) as! VideoPlayerVC
        vc.previewClip = selectedMatch.match.getFilteredClips()[highlightedClipIndex]
        vc.modalTransitionStyle = .flipHorizontal
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true, completion: nil)
    }
    
    @IBAction func onBannerRemoveBtn(_ sender: UIButton) {
        selectedMatch.match.getFilteredClips()[highlightedClipIndex].removeClipFiles(true)
        sender.isHidden = true
        clipBannerImgView.isHidden = true
    }
    
    @IBAction func onSelectAllBtn(_ sender: UIButton) {
        if(btnSelectAll.titleLabel?.text == "SELECTALL"){
            resetClipSelection(isSelected: true)
        }else{
            resetClipSelection(isSelected: false)
        }
    }
    
    func resetClipSelection(isSelected: Bool){
        if(isSelected){
            btnSelectAll.setTitle("DESELECTALL", for: .normal)
        }else{
            btnSelectAll.setTitle("SELECTALL", for: .normal)
        }
        for origClip in selectedMatch.match.getFilteredClips() {
            var checkedClip = origClip
            checkedClip.set(isSelected: isSelected)
            selectedMatch.match.update(newClip: checkedClip, updater: .replace)
        }
        save()
    }
    
    func createVideoSelection(sender: UIButton) {
        let selectedClips = selectedMatch.match.clips.filter { $0.isSelected }
        guard selectedClips.count > 0 else {
            MessageBarService.shared.warning("No selected highlights!")
            return
        }
        
        let generator = VideoProcess(selectedClips, selectedMatch.match)
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.modalPresentationStyle = .popover
        let highAction = UIAlertAction(title: ActionTitle.standarQuality.rawValue, style: .default) { (highAction) in
            self.createVideo(true, generator)
        }
        let meAction = UIAlertAction(title: ActionTitle.webQuality.rawValue, style: .default) { (meAction) in
            self.createVideo(false, generator)
        }
        alert.addAction(UIAlertAction(title: ActionTitle.cancel.rawValue, style: .cancel, handler: nil))
        alert.addAction(highAction)
        alert.addAction(meAction)
        if let presenter = alert.popoverPresentationController {
            presenter.sourceView = sender
            presenter.sourceRect = sender.bounds
        }
        present(alert, animated: true, completion: nil)
    }
    
    func sendToLiverecapVideoSelection(sender: UIButton) {
        let selectedClips = selectedMatch.match.clips.filter { $0.isSelected }
        guard (selectedClips.count > 0) || (self.selectedMatch.match.preClip.isExistingPreClipFile() && self.selectedMatch.match.preClip.isSelected) else {
            MessageBarService.shared.warning("No selected highlights!")
            return
        }
        
        let recapId = UserDefaults.standard.integer(forKey: selectedMatch.match.id)
        if recapId == 0
        {
            let alert = UIAlertController(title: "Alert", message: "Please select the Recap on setting match.", preferredStyle: UIAlertController.Style.alert)
            
            alert.modalPresentationStyle = .popover
            let selectRecapAction = UIAlertAction(title: "Select Recap", style: .default) { (selectRecapAction) in
                if customerId != 0
                {
                    self.performSegue(withIdentifier: "RecapListVC", sender: nil)
                }
                else {
                    let alert = UIAlertController(title: "Alert", message: "Please sign in before continue.", preferredStyle: UIAlertController.Style.alert)
                    
                    let okButtonAction = UIAlertAction(title: "Ok", style: .default) { (okButtonAction) in
                        self.tabBarController?.selectedIndex = 2
                    }
                    alert.addAction(okButtonAction)
                    self.present(alert, animated: true, completion: nil)
                }
            }
            
            alert.addAction(UIAlertAction(title: ActionTitle.cancel.rawValue, style: .cancel, handler: nil))
            alert.addAction(selectRecapAction)
            if let presenter = alert.popoverPresentationController {
                presenter.sourceView = sender
                presenter.sourceRect = sender.bounds
            }
            present(alert, animated: true, completion: nil)
            
            return;
        }
        
        let generator = VideoProcess(selectedClips, selectedMatch.match)
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.modalPresentationStyle = .popover
        let highAction = UIAlertAction(title: ActionTitle.standarQuality.rawValue, style: .default) { (highAction) in
            self.createClipsForLiverecap(true, generator)
        }
        let meAction = UIAlertAction(title: ActionTitle.webQuality.rawValue, style: .default) { (meAction) in
            self.createClipsForLiverecap(false, generator)
        }
        alert.addAction(UIAlertAction(title: ActionTitle.cancel.rawValue, style: .cancel, handler: nil))
        alert.addAction(highAction)
        alert.addAction(meAction)
        if let presenter = alert.popoverPresentationController {
            presenter.sourceView = sender
            presenter.sourceRect = sender.bounds
        }
        present(alert, animated: true, completion: nil)
    }

}

//MARK: - AVPlayerServiceDelegate
extension MatchesDetailHighlightsVC: AVPlayerServiceDelegate {
    func onPlayingAMinute(_ currentTime: CMTime) {
        // nothing to do
    }
    
    func avPlayerService(_ avPlayerService: AVPlayerService, didSlideUp played: String, rest restTime: String) {
        // nothing to do
    }
    
    func avPlayerService(didEndPlayVideo avPlayerService: AVPlayerService) {
        previewPlayBtn.setImage(Constant.Image.PlayWhite.image, for: .normal)
    }
    
    func avPlayerServiceSliderValueChanged() {
        // nothing to do
    }
}

//MARK: - UIImagePickerControllerDelegate                           // importing video from app or device gallery
extension MatchesDetailHighlightsVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let photoTaken = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            activatedClipWithMoreOption.setBannerImg(photoTaken) { (isSucceed, resultDes) in
                if isSucceed {
                    DispatchQueue.main.async {
                        self.setBannerImage(self.activatedClipWithMoreOption)
                    }
                } else {
                    MessageBarService.shared.error(resultDes)
                }
            }
        }
        if let videoUrl = info[UIImagePickerController.InfoKey.mediaURL] as? URL {
            Utiles.setHUD(true, DataManager.shared.tabberView, .extraLight, "Adjusting a selected video for pre clip...")
            selectedMatch.match.preClip.setPreClip(from: videoUrl, quality: selectedMatch.match.quality()) { (isDone, resultDes) in
                if isDone {
                    self.save()
                } else {
                    MessageBarService.shared.error(resultDes)
                }
                Utiles.setHUD(false)
            }
        }
        picker.dismiss(animated: true, completion: nil)
    }
}

//MARK: - SettingsImgArchiveVCDelegate                              /// import images from app directory
extension MatchesDetailHighlightsVC: SettingsImgArchiveVCDelegate {
    func didSelect(image img: UIImage) {
        activatedClipWithMoreOption.setBannerImg(img) { (isSucceed, resultDes) in
            if isSucceed {
                self.selectedMatch.match.update(newClip: self.activatedClipWithMoreOption, updater: .replace)
                self.save()
            } else {
                MessageBarService.shared.error(resultDes)
            }
        }
    }
}

//MARK: - MatchesClipInfoVCDelegate                             /// clip information Controller delegate to edit clip name
extension MatchesDetailHighlightsVC: MatchesClipInfoVCDelegate {
    func onDismissClipInfoVC(with editedClip: Clip) {
        let indexObj = selectedMatch.match.clips.firstIndex { $0.id == editedClip.id }
        if let index = indexObj {
            selectedMatch.match.update(newClip: editedClip, updater: .replace, index: index)
            save()
        }
    }
}

//MARK: - MatchClipCellDelegate                                 /// all clips will interact with these functions
extension MatchesDetailHighlightsVC: MatchClipCellDelegate {
    
    func matchClipCell(_ cell: MatchClipCell, didClickCheckButton isChecked: Bool) {
        if let index = mTableView.indexPath(for: cell) {
            
            if index.row == 0 {
                selectedMatch.match.preClip.setSelected(val: isChecked)
            } else {
                var checkedClip = selectedMatch.match.getFilteredClips()[index.row - 1]
                checkedClip.set(isSelected: isChecked)
                selectedMatch.match.update(newClip: checkedClip, updater: .replace)
            }
//            var Selected = false;
//            for origClip in selectedMatch.match.getFilteredClips() {
//                if(!origClip.isSelected){
//                    Selected = false;
//                }
//            }
            
            let a = selectedMatch.match.getFilteredClips().filter { (Clip) -> Bool in Clip.isSelected == true
            };
            
            if(a.count == selectedMatch.match.getFilteredClips().count){
                btnSelectAll.setTitle("DESELECTALL", for: .normal)
            }else{
                btnSelectAll.setTitle("SELECTALL", for: .normal)
            }
            
            save()
        }
    }
    
    func matchClipCell(_ cell: MatchClipCell, didClickMore btn: UIButton) {
        let clipCell = cell
        guard let clipIndex = mTableView.indexPath(for: cell)?.row else { return }
        
        activatedClipWithMoreOption = selectedMatch.match.getFilteredClips()[clipIndex - 1]
        dropDown = DropDown()
        dropDown?.backgroundColor = #colorLiteral(red: 0.3333333433, green: 0.3333333433, blue: 0.3333333433, alpha: 1)
        dropDown?.anchorView = cell.contentView
        dropDown?.direction = .any
        dropDown?.bottomOffset = CGPoint(x: 0, y:(dropDown?.anchorView?.plainView.bounds.height)!)
        dropDown?.dataSource = [EMPTY_STRING]
        dropDown?.cellNib = UINib(nibName: Constant.Cell.MatchDetailClipDropCell, bundle: nil)
        dropDown?.customCellConfiguration = { (index: Index, item: String, cell: DropDownCell) -> Void in
            guard let cell = cell as? MatchesDetailHighlightDropDownCell else { return }
            cell.initialize(self.selectedMatch.match.getFilteredClips()[clipIndex - 1], self, clipIndex - 1, clipCell, btn)
        }
        dropDown?.dismissMode = .onTap
        dropDown?.cancelAction = {
            print("cancelled dropdown view")
        }
        dropDown?.show()
    }
    
    func matchClipCell(_ cell: MatchClipCell, onImageBtn isPreClip: Bool) {
        openPhotoLibrary(forAppLib: false, isVideo: true)
    }
    
}

//MARK: - MatchesDetailHighlightDropDownCellDelegate                /// general clips have these options functions
extension MatchesDetailHighlightsVC: MatchesDetailHighlightDropDownCellDelegate { 
    func clipDropCell(_ clipIndex: Int, _ clipCell: MatchClipCell, didClickedDelete clip: Clip) {
        dropDown?.hide()
        MessageBarService.shared.alertQuestion(title: "Warning!", message: "Are you sure to delete this clip?", yesString: "Yes", noString: "No", onYes: { (yesAction) in
            self.selectedMatch.match.update(newClip: self.selectedMatch.match.getFilteredClips()[clipIndex], updater: .delete)
            self.save()
            
//            self.mTableView.update(row: IndexPath(row: clipIndex + 1, section: 0), for: .delete)
            
            if self.selectedMatch.match.getFilteredClips().count != 0 {
                self.highlightedClipIndex = 0
                self.setClipPreview(with: self.selectedMatch.match.getFilteredClips()[0])
//                self.mTableView.update(row: IndexPath(row: 0, section: 0), for: .replace)
            } else {
                
            }
        }, onNo: nil)
    }
    
    func clipDropCell(_ clipIndex: Int, didClickedInfo clip: Clip) {
        dropDown?.hide()
        performSegue(withIdentifier: Constant.Segue.MatchesDetailClipInfoSegueId, sender: clip)
    }
    
    func clipDropCell(_ clipIndex: Int, didClickedReplay clip: Clip) {
        selectedMatch.match.set(replayClip: clip)
        save()
    }
    
    func clipDropCell(_ clipIndex: Int, didClickedBanner clip: Clip, _ sender: UIButton) {
        dropDown?.hide()
        
        presentImportImgSheet(sender, { (appLibAction) in
            self.openPhotoLibrary(forAppLib: true)
        }) { (deviceLibAction) in
            self.openPhotoLibrary(forAppLib: false)
        }
    }
    
    func clipDropCell(_ clipIndex: Int, didClickedShare clip: Clip, _ sender: UIButton) {
        dropDown?.hide()
        
        let sheetController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        sheetController.modalPresentationStyle = .popover
        let standardAction = UIAlertAction(title: ActionTitle.shareStandardQuality.rawValue, style: .default) { (highAction) in
            self.createVideo(for: clip, true, sender)
        }
        let lowAction = UIAlertAction(title: ActionTitle.shareWebQuality.rawValue, style: .default) { (lowAction) in
            self.createVideo(for: clip, false, sender)
        }
        sheetController.addAction(UIAlertAction(title: ActionTitle.cancel.rawValue, style: .cancel, handler: nil))
        sheetController.addAction(standardAction)
        sheetController.addAction(lowAction)
        if let presenter = sheetController.popoverPresentationController {
            presenter.sourceView = sender
            presenter.sourceRect = sender.bounds
        }
        present(sheetController, animated: true, completion: nil)
    }
}

//MARK: - table view data source & delegate                                 /// all clips will be shown in this tableview
extension MatchesDetailHighlightsVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return selectedMatch.match.getFilteredClips().count + 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if UI_USER_INTERFACE_IDIOM() == .phone {
            return 60
        } else {
            return 80
        }
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! MatchClipCell
        
        if indexPath.row == 0 {
            cell.initialize(selectedMatch.match.preClip as Any, self)
        } else {
            let clip = selectedMatch.match.getFilteredClips()[indexPath.row - 1]
            let teamName = clip.team == .first ? selectedMatch.match.fstName : selectedMatch.match.sndName
            let cellData = ClipCellData(scores: selectedMatch.match.scoreDescription(clip.getEndTimeInMatch()), teamName: teamName!, clipItem: clip, isHighlighted: indexPath.row - 1 == highlightedClipIndex)
            cell.initialize(cellData, self)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? MatchClipCell, cell.highlightedView.isHidden, indexPath.row != 0 {
            if avplayerService != nil {
                if avplayerService.isPlaying {
                    avplayerService.setPlayer()
                }
                setPreviewPlayView(add: false)
                previewPlayBtn.setImage(Constant.Image.PlayWhite.image, for: .normal)
            }
            highlightedClipIndex = indexPath.row - 1
            setClipPreview(with: selectedMatch.match.getFilteredClips()[highlightedClipIndex])
            tableView.reloadData()
        }
    }
}

//MARK: - Video Process functions
extension MatchesDetailHighlightsVC {
    
    func createVideo(_ highBitrate: Bool, _ generator: VideoProcess) {
        let selectedTemplate = DataManager.shared.getSelectedTemplate()
        if selectedTemplate == nil {
            showDownloadTemplateMsg()
            return
        }else{
            var templateProducts : [SKProduct]? = DataManager.shared.templateProducts
            var soundtrackProducts : [SKProduct]? = DataManager.shared.soundtrackProducts
    
            func validateDownloadedProduct()->Bool{
                let templateProduct = templateProducts!.filter { $0.localizedTitle == selectedTemplate?.iapGroupName }.first
                if templateProduct == nil{
                    return false
                } else {
                    let isPurchase = checkProductSubscriptionPurchase(productIdentifier: templateProduct!.productIdentifier)
                    updateTemplate(product: templateProduct!)
                    self.updateSoundtrack(soundtrackProducts: soundtrackProducts!)
                    if(isPurchase){
                        return true
                    }else{
                        return false
                    }
                }
            }
            
            func generatingVideoClip(){
                Utiles.setHUD(true, DataManager.shared.tabberView, .extraLight, "Generating each clips...")
                
                dirManager.clearTempDir()
                DispatchQueue.global().async {
                    let newVideo = Video(self.selectedMatch.match.namePresentation(), highBitrate, self.selectedMatch.match.quality())
                    self.clipVideos(highBitrate, newVideo, 0, generator)
                }
            }
            
            func processProducts(){
                Utiles.setHUD(false)
                if validateDownloadedProduct() == false{
                    self.showDownloadTemplateMsg()
                    return
                }else{
                    generatingVideoClip()
                }
            }
            
            if(templateProducts != nil && templateProducts!.count > 0){
                if validateDownloadedProduct() == false{
                    showDownloadTemplateMsg()
                    return
                }else{
                    generatingVideoClip()
                }
            }else{
                Utiles.setHUD(true, DataManager.shared.tabberView, .extraLight, "Fetching products...")
                getTemplateProducts { (products) in
                    templateProducts = products
                    if(soundtrackProducts != nil && soundtrackProducts!.count > 0){
                        processProducts()
                    }else{
                        self.getSoundtrackProducts { (soundtrackGroup) in
                            soundtrackProducts = soundtrackGroup
                            processProducts()
                        }
                    }
                }
            }
        }
    }
    
    func createClipsForLiverecap(_ highBitrate: Bool, _ generator: VideoProcess) {
        
        func generatingVideoClip(){
            Utiles.setHUD(true, DataManager.shared.tabberView, .extraLight, "Generating each clips...")
            
            dirManager.clearTempDir()
            DispatchQueue.global().async {
                let newVideo = Video(self.selectedMatch.match.namePresentation(), highBitrate, self.selectedMatch.match.quality())
                
                // - pre clip video
                if self.selectedMatch.match.preClip.isExistingPreClipFile(), self.selectedMatch.match.preClip.isSelected {
                    self.clipVideosForLiverecap(highBitrate, newVideo, 0, generator, true)
                }
                else
                {
                    self.clipVideosForLiverecap(highBitrate, newVideo, 0, generator, false)
                }
            }
        }
        
        generatingVideoClip()
    }
    
    func showDownloadTemplateMsg(){
        MessageBarService.shared.warning("Please download templates from settings page  and select your favorite before creating a video.")
    }

    func checkProductSubscriptionPurchase(productIdentifier:String)->Bool{
        if let productGroupData : [String : NSDictionary] = DataManager.shared.getProductGroupData() {
            let selectedProductInfo : NSDictionary = productGroupData[productIdentifier]!
            var expireDateProduct = Date()
            if let expiresDate = selectedProductInfo["expires_date_ms"] as? String {
                expireDateProduct = Date(timeIntervalSince1970: TimeInterval(expiresDate)!/1000)
            }
            let isPurchase = expireDateProduct > Date()
            UserDefaults.standard.set(isPurchase, forKey: productIdentifier)
            UserDefaults.standard.synchronize()
            return isPurchase
        }else{
            return false
        }
    }

    func getTemplateProducts(_ completion: @escaping([SKProduct]) -> Void){
        FannerCamProducts.templatesStore.requestProducts{ [weak self] success, products in
            guard self != nil else { return }
            
            if success {
                var templateProducts = products!
                templateProducts.sort { $0.localizedTitle < $1.localizedTitle }
                DataManager.shared.templateProducts = templateProducts
                completion(templateProducts)
            }
        }
    }
    
    func getSoundtrackProducts(_ completion: @escaping([SKProduct]) -> Void){
        FannerCamProducts.soundtrackStore.requestProducts{ [weak self] success, products in
            guard self != nil else { return }
            
            if success {
                var soundtrackProducts = products!
                soundtrackProducts.sort { $0.localizedTitle < $1.localizedTitle }
                DataManager.shared.soundtrackProducts = soundtrackProducts
                completion(soundtrackProducts)
            }
        }
    }
    
    func updateTemplate(product: SKProduct){
        var templateItems = DataManager.shared.templates[product.localizedTitle] ?? [Template]()
        let purchaseType : Purchased = FannerCamProducts.templatesStore.isProductPurchased(product.productIdentifier) ? .purchased : .unPurchased
        for (index, item) in templateItems.enumerated() {
            var temp = item
            temp.purchasedType = purchaseType
            if purchaseType == .unPurchased{
                temp.removeFiles()
            }
            templateItems[index] = temp
        }
        DataManager.shared.templates[product.localizedTitle] = templateItems
        DataManager.shared.saveTemplates()
    }
    
    func updateSoundtrack(soundtrackProducts:[SKProduct]){
        let selectedSoundtrack = DataManager.shared.getSelectedSoundtrack()
        if selectedSoundtrack == nil {
            return
        }
        let soundtrackProduct = soundtrackProducts.filter { $0.localizedTitle == selectedSoundtrack?.iapGroupName }.first
        if soundtrackProduct == nil{
            return
        }
        let _ = checkProductSubscriptionPurchase(productIdentifier: soundtrackProduct!.productIdentifier)
        var soundtrackItems = DataManager.shared.soundtracks[soundtrackProduct!.localizedTitle] ?? [Soundtrack]()
        let purchaseType : Purchased = FannerCamProducts.soundtrackStore.isProductPurchased(soundtrackProduct!.productIdentifier) ? .purchased : .unPurchased
        for (index, item) in soundtrackItems.enumerated() {
            var temp = item
            temp.purchasedType = purchaseType
            if purchaseType == .unPurchased{
                temp.removeFiles()
            }
            soundtrackItems[index] = temp
        }
        DataManager.shared.soundtracks[soundtrackProduct!.localizedTitle] = soundtrackItems
        DataManager.shared.saveTemplates()
    }
    
    func createVideo(for singleClip: Clip, _ highBitrate: Bool, _ sender: UIButton) {
        let generator = VideoProcess([Clip](), selectedMatch.match)
        Utiles.setHUD(true, DataManager.shared.tabberView, .extraLight, "Generating a single clip video...")
        DispatchQueue.global().async {
            generator.generateSingleMediaFile(self.selectedMatch.match.quality(), highBitrate, singleClip) { (isSucceed, result) in
                if isSucceed {
                    print(result)
                    DispatchQueue.main.async {
                        self.showShareView(url: URL(fileURLWithPath: result), sender)
                    }
                } else {
                    MessageBarService.shared.error(result)
                }
                Utiles.setHUD(false)
            }
        }
    }
    
    func clipVideos(_ highBitrate: Bool, _ newVideo: Video, _ index: Int, _ generator: VideoProcess) {
        Utiles.setHUD("Generating the \(index.sequenth()) clip...")
        generator.generateSingleMediaFile(selectedMatch.match.quality(), highBitrate, generator.clips[index]) { (isSuccess, resultDes) in
            if isSuccess {
                if index == generator.clips.count - 1 {
                    Utiles.setHUD("Final step for generating...")
                    generator.generateNewVideo(highBitrate, newVideo, { (done, str) in
                        if done {
                            DataManager.shared.updateVideos(newVideo, .new)
                            MessageBarService.shared.notify("Successfully created a video!")
                        } else {
                            MessageBarService.shared.error(resultDes)
                        }
                        Utiles.setHUD(false)
                    })
                } else {
                    self.clipVideos(highBitrate, newVideo, index + 1, generator)
                }
            } else {
                MessageBarService.shared.error(resultDes)
                Utiles.setHUD(false)
            }
        }
    }
    
    func clipVideosForLiverecap(_ highBitrate: Bool, _ newVideo: Video, _ index: Int, _ generator: VideoProcess, _ isPreClip: Bool) {
        
        func UploadVideoToServer(_ videoURL: URL, _ isPreClip: Bool) {
            do {
                let videoData = try NSData(contentsOf: videoURL as URL, options: .mappedIfSafe)
                
                let base64Encoded = videoData.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
                
                var clip : Clip!
                
                let recapId = UserDefaults.standard.integer(forKey: self.selectedMatch.match.id)
                
                var teamName = ""
                var clipTag = ""
                var tagName = ""
                var duration : Float64!
                
                if !isPreClip
                {
                    clip = generator.clips[index]
                    
                    teamName = clip.team == .first ? self.selectedMatch.match.fstName : self.selectedMatch.match.sndName

                    if let tag = clip.clipTag{
                        clipTag = String(describing: tag)
                    }
                    tagName = "\(clip.titleDescription()) \(clipTag)"
                    
                    if let marker = clip.marker {
                        duration = marker.duration
                    }
                }
                
                // API call
                let strUrl: String = getServerBaseUrl() + getCreateClipURL()
                

                var logoTeam1 : UIImage?
                if let img = VideoProcess.loadImg(from: self.selectedMatch.match.matchLogoPath(.first)) {
                    logoTeam1 = img
                } else {
                    logoTeam1 = Constant.Image.DefaultTeamLogo.image
                }
                
                var logoTeam2 : UIImage?
                if let img = VideoProcess.loadImg(from: self.selectedMatch.match.matchLogoPath(.second)) {
                    logoTeam2 = img
                } else {
                    logoTeam2 = Constant.Image.DefaultTeamLogo.image
                }
                
                var logoEvent : UIImage?
                if let img = VideoProcess.loadImg(from: self.selectedMatch.match.matchLogoPath()) {
                    logoEvent = img
                } else {
                    logoEvent = Constant.Image.DefaultTeamLogo.image
                }
                    
                var Tags : [String]!
                /*if isPreClip
                {
                    Tags = ["#preclip"]
                }
                else {
                    Tags = ["#\(teamName)", "#\(tagName)"]
                }*/
                
                let postParam = [
                    "team1": generator.match.fstName ?? "",
                    "team2": generator.match.sndName ?? "",
                    "logoTeam1": self.convertImageToBase64String(img: logoTeam1!),
                    "logoTeam2": self.convertImageToBase64String(img: logoTeam2!),
                    "eventName": self.selectedMatch.match.namePresentation(),
                    "logoEvent": self.convertImageToBase64String(img: logoEvent!),
                    "score": !isPreClip ? self.selectedMatch.match.scoreDescription(clip.getEndTimeInMatch()) : "",
                    "minutesOfTheMatch": !isPreClip ? clip.period ?? "" : "",
                    "tags": Tags ?? [],
                    "duration": duration ?? 0,
                    "resolution": self.selectedMatch.match.quality() == AVAssetExportPreset1280x720 ? "720" : "1080",
                    "frameRate": 0,
                    "bitRate": 0,
                    "device": "",
                    "geoLocation": "",
                    "isRecapMain": false,
                    "recapId": recapId,
                    "customerId": customerId,
                    "clipTitle": !isPreClip ? "\(teamName), \(tagName)" : "Pre clip",
                    "clipDescription": !isPreClip ? "\(teamName), \(tagName)" : "Pre clip",
                    "clipFile": base64Encoded
                ] as [String : Any]
                
                let oWebManager: AlamofireManager = AlamofireManager()
                oWebManager.requestPost(strUrl, parameters: postParam) { (jsonResult) in
                    
                    if let errorMessage = jsonResult["errorMessage"] as? String
                    {
                        if errorMessage.isEmpty
                        {
                            if isPreClip
                            {
                                self.clipVideosForLiverecap(highBitrate, newVideo, 0, generator, false)
                            }
                            else
                            {
                                if index == generator.clips.count - 1 {
                                    Utiles.setHUD("Finished uploading...")
                                    Utiles.setHUD(false)
                                    
                                } else {
                                    self.clipVideosForLiverecap(highBitrate, newVideo, index + 1, generator, false)
                                }
                            }
                        }
                        else
                        {
                            
                            Utiles.setHUD("Finished uploading...")
                            Utiles.setHUD(false)
                            
                            MessageBarService.shared.error("Failed to upload clip. The reason: " + errorMessage)
                        }
                    }
                }
                
            } catch {
                print(error)
                return
            }
        }
        
        if isPreClip
        {
            Utiles.setHUD("Uploading the PreClip...")
            let assetPreclip = selectedMatch.match.preClip.getPreClipPath()
            UploadVideoToServer(assetPreclip, true)
        }
        else
        {
            let selectedClips = selectedMatch.match.clips.filter { $0.isSelected }
            guard (selectedClips.count > 0) else {
                Utiles.setHUD("Finished uploading...")
                Utiles.setHUD(false)
                
                return
            }
            
            Utiles.setHUD("Uploading the \(index.sequenth()) clip...")
            generator.generateSingleMediaFileForLiverecap(selectedMatch.match.quality(), highBitrate, generator.clips[index]) { (isSuccess, resultDes) in
                if isSuccess {
                    let videoURL = URL(fileURLWithPath: resultDes)
                    UploadVideoToServer(videoURL, false)
                } else {
                    MessageBarService.shared.error(resultDes)
                    Utiles.setHUD(false)
                }
            }
        }
    }
    
    func convertImageToBase64String (img: UIImage) -> String {
        return img.jpegData(compressionQuality: 1)?.base64EncodedString() ?? ""
    }
    
}


extension Float64 {
    func rounded(digits: Int) -> Float64 {
        let multiplier = pow(10.0, Float64(digits))
        return (self * multiplier).rounded() / multiplier
    }
}
