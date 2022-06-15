//
//  UIViewControllerExtension.swift
//  NewFannerCam
//
//  Created by Jin on 1/19/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
    
    func setOrientation(isPortrait: Bool) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if isPortrait {
            appDelegate.myOrientation = .portrait
        } else {
            appDelegate.myOrientation = .landscape
        }
    }
    
    func createMatchNVC(with mode: MatchType) -> UINavigationController? {
        
        if DataManager.shared.purchasedMatchCount == 0 {
            MessageBarService.shared.alertQuestion(title: APP_NAME, message: "Please buy at least one match before creating a new one!", yesString: "Buy", noString: "Cancel", onYes: { (yesAction) in
                let settingsSubscriptionsNVC = self.settingsSubscriptionNav()
                self.present(settingsSubscriptionsNVC, animated: true, completion: nil)
            }, onNo: nil)
            return nil
        }
        
        let matchStoryboard = UIStoryboard(name: Constant.Storyboard.Matches, bundle: nil)
        let nvc = matchStoryboard.instantiateViewController(withIdentifier: Constant.StoryboardIds.CreateMatchNvc) as! UINavigationController
        let vc = nvc.children[0] as! CreateNewMatchVC
        vc.newMatchType = mode
        return nvc
    }
    
    func appImgArchive() -> UINavigationController {
        let storyboard = UIStoryboard(name: Constant.Storyboard.Setting, bundle: nil)
        let nav = storyboard.instantiateViewController(withIdentifier: Constant.StoryboardIds.AppLibNavController) as! UINavigationController
        let dvc = nav.children[0] as! SettingsImgArchiveVC
        if let createMatchVC = self as? CreateNewMatchVC {
            dvc.delegate = createMatchVC
            dvc.viewMode = .appLib
        }
        if let matchHighlightVC = self as? MatchesDetailHighlightsVC {
            dvc.delegate = matchHighlightVC
            dvc.viewMode = .appLib
        }
        if let overlayVC = self as? MatchesOverlayVC {
            dvc.delegate = overlayVC
            dvc.viewMode = .appLib
        }
        
        return nav
    }
    
    func settingsSubscriptionNav() -> UINavigationController {
        let storyboard = UIStoryboard(name: Constant.Storyboard.Setting, bundle: nil)
        let nvc = storyboard.instantiateViewController(withIdentifier: Constant.StoryboardIds.SettingsSubscriptionsNVC) as! UINavigationController
        let vc = nvc.children[0] as! SettingsSubscriptionsVC
        vc.inSettingTab = false
        return nvc
    }
    
    func settingsTermsPrivacyNav() -> UINavigationController {
        let storyboard = UIStoryboard(name: Constant.Storyboard.Setting, bundle: nil)
        let nvc = storyboard.instantiateViewController(withIdentifier: Constant.StoryboardIds.TermPrivacyWebVC) as! UINavigationController
        let vc = nvc.children[0] as! TermPrivacyWebVC
        vc.viewType = .Terms
        return nvc
    }
    
    func settingsStorePurchaseNav() -> UINavigationController {
        let storyboard = UIStoryboard(name: Constant.Storyboard.Setting, bundle: nil)
        let nvc = storyboard.instantiateViewController(withIdentifier: Constant.StoryboardIds.StorePurchaseVC) as! UINavigationController
        let vc = nvc.children[0] as! StorePurchaseVC
        vc.inSettingTab = false
        return nvc
    }
    
    func settingsTemTraNav() -> UINavigationController {
        let storyboard = UIStoryboard(name: Constant.Storyboard.Setting, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: Constant.StoryboardIds.SettingsTemTraNav) as! UINavigationController
        return vc
    }
    
    func showShareView(url : URL, _ sender: UIButton) {
        
        DispatchQueue.main.async {
            let dataToShare = [url] as [Any]
            
            let activityVC = UIActivityViewController(activityItems: dataToShare, applicationActivities: nil)
            activityVC.excludedActivityTypes = [UIActivity.ActivityType.print, UIActivity.ActivityType.copyToPasteboard, UIActivity.ActivityType.assignToContact]
            activityVC.popoverPresentationController?.sourceRect = sender.bounds
            activityVC.popoverPresentationController?.sourceView = sender
            
            self.present(activityVC, animated: true) {
                //                self.dismissViewController()
            }
        }
        
    }
    
    typealias SheetActionHandler = (UIAlertAction) -> Void
    
    func presentImportImgSheet(_ sender: UIButton, _ applibAction: SheetActionHandler? = nil, _ deviceLibAction: SheetActionHandler? = nil) {
        let sheetController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        sheetController.modalPresentationStyle = .popover
        let fstData = ActionTitleData(actionImage: nil, imgTintColor: nil, isChecked: nil, title: ActionTitle.selectFromAppLib.rawValue)
        sheetController.addAction(fanSheetAction(titleData: fstData, handler: applibAction))
        let sndData = ActionTitleData(actionImage: nil, imgTintColor: nil, isChecked: nil, title: ActionTitle.selectFromDeviveLib.rawValue)
        sheetController.addAction(fanSheetAction(titleData: sndData, handler: deviceLibAction))
        sheetController.addAction(UIAlertAction(title: ActionTitle.cancel.rawValue, style: .cancel, handler: nil))
        if let presenter = sheetController.popoverPresentationController {
            presenter.sourceView = sender
            presenter.sourceRect = sender.bounds
        }
        self.present(sheetController, animated: true, completion: nil)
    }
    
}

extension UIImagePickerController {
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.myOrientation
    }
}
