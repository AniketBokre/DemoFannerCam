//
//  MatchesHighlightsVC.swift
//  NewFannerCam
//
//  Created by Jin on 1/3/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import UIKit

class MatchesDetailVC: UIViewController {

    @IBOutlet weak var highlightRedLineView : UIView!
    @IBOutlet weak var mainvideoRedLineView : UIView!
    @IBOutlet weak var highlightContainerView: UIView!
    @IBOutlet weak var mainvideoContainerView: UIView!
    @IBOutlet weak var blackView : UIView!
    @IBOutlet weak var topTapHeight: NSLayoutConstraint!
    
    var selectedMatch : SelectedMatch!
    
    weak var mainVideosVC : MatchesDetailMainVideoVC?
    weak var hightlightsVC : MatchesDetailHighlightsVC?
    
//MARK: - Override Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UIScreen.main.addObserver(self, forKeyPath: Constant.ObserverKey.Captured, options: .new, context: nil)
        
        DataManager.shared.matchesDelegate = self
        
        setLayouts()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if (keyPath == Constant.ObserverKey.Captured)  {
            if #available(iOS 11.0, *) {
                let isCaptured = UIScreen.main.isCaptured
                if (isCaptured) {
                    self.blackView.isHidden = false
                } else {
                    self.blackView.isHidden = true
                }
            } else {
                // Fallback on earlier versions
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constant.StoryboardIds.MainVideo {
            let vc = segue.destination as! MatchesDetailMainVideoVC
            vc.selectedMatch = selectedMatch
            mainVideosVC = vc
        }
        else if segue.identifier == Constant.StoryboardIds.Highlights {
            let vc = segue.destination as! MatchesDetailHighlightsVC
            vc.selectedMatch = selectedMatch
            hightlightsVC = vc
        }
        else if segue.identifier == Constant.StoryboardIds.RecapListVC {
            let vc = segue.destination as! RecapListVC
            vc.selectedMatch = selectedMatch
        }
        
    }
    
//MARK: - Init functions
    func setLayouts() {
        DispatchQueue.main.async {
            self.title = self.selectedMatch.match.namePresentation()
            if self.selectedMatch.match.isEmptyMainVideos() || self.selectedMatch.match.isEmptyClips() {
                self.topTapHeight.constant = 0
                self.switchClipMainVideo(isMainVideo: true)
            } else {
                self.topTapHeight.constant = 40
                self.switchClipMainVideo(isMainVideo: false)
            }
        }
    }
    
    func switchClipMainVideo(isMainVideo: Bool) {
        DispatchQueue.main.async {
            self.highlightRedLineView.isHidden   = isMainVideo
            self.highlightContainerView.isHidden = isMainVideo
            self.mainvideoRedLineView.isHidden   = !isMainVideo
            self.mainvideoContainerView.isHidden = !isMainVideo
            
            if self.highlightContainerView.isHidden {
                NotificationCenter.default.post(name: .DidLeaveMatchTab, object: nil)
            }
        }
    }
    
    func openSettingTemSoundVC(_ mode: SettingsTemTraVCMode) {
        let nav = settingsTemTraNav()
        let vc = nav.children[0] as! SettingsTemTraVC
        vc.viewMode = mode
        vc.inSettingTab = false
        present(nav, animated: true, completion: nil)
    }
    
//MARK: - Main Functions
    func showShareSheet(_ sender: UIBarButtonItem) {
        let sheetController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        sheetController.modalPresentationStyle = .popover
        let selectRecap = UIAlertAction(title: "Select Recap", style: .default) { (selectRecapAction) in
            
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
        let template = UIAlertAction(title: "Template", style: .default) { (templateAction) in
            self.openSettingTemSoundVC(.templates)
        }
        let soundtrack = UIAlertAction(title: "Soundtrack", style: .default) { (soundtrackAction) in
            self.openSettingTemSoundVC(.soundTracks)
        }
        let overlayAction = UIAlertAction(title: "Graphic overlays", style: .default) { (overlayAction) in
            self.performSegue(withIdentifier: "MatchesOverlaySegue", sender: nil)
        }
        let delAction = UIAlertAction(title: "Delete Match", style: .destructive) { (delAction) in
            
            MessageBarService.shared.alertQuestion(title: "Warning!", message: "Are you sure to delete this \"\(self.selectedMatch.match.namePresentation())\" match?", yesString: "Yes", noString: "No", onYes: { (yesAction) in
                
                DataManager.shared.updateMatches(self.selectedMatch.match, self.selectedMatch.index, .delete)
                self.onBackBtn(nil)
                
            }, onNo: nil)
            
        }
        
        sheetController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        sheetController.addAction(selectRecap)
        sheetController.addAction(template)
        sheetController.addAction(soundtrack)
        sheetController.addAction(overlayAction)
        sheetController.addAction(delAction)
        if let presenter = sheetController.popoverPresentationController {
            presenter.barButtonItem = sender
        }
        present(sheetController, animated: true, completion: nil)
    }

//MARK: - IBActions
    @IBAction func onMoreBtn(_ sender: UIBarButtonItem) {
        showShareSheet(sender)
    }
    
    @IBAction func onBackBtn(_ sender: UIButton?) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func switchViews(_ sender: UIButton?) {
        if let btn = sender {
            if btn.titleLabel?.text == "Main Video" {
                switchClipMainVideo(isMainVideo: true)
            } else {
                switchClipMainVideo(isMainVideo: false)
            }
        }
    }
}

extension MatchesDetailVC: DataManagerMatchesDelegate {
    func didUpdateMatches(_ updateMode: Updater, _ updatedItem: Match?, _ index: Int?) {
        if let matchItem = updatedItem {
            selectedMatch.match = matchItem
            mainVideosVC?.updateMainVideoList(matchItem)
            hightlightsVC?.updateHighlights(matchItem)
            
            setLayouts()
        }
    }
}
