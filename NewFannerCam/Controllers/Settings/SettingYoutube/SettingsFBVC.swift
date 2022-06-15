//
//  SettingsAccountVC.swift
//  NewFannerCam
//
//  Created by Jin on 12/30/18.
//  Copyright © 2018 fannercam3. All rights reserved.
//

import UIKit

class SettingsFBVC: UIViewController {
    
    @IBOutlet weak var continueFBView: UIView!
    @IBOutlet weak var loggedView: UIView!
    
    //privacy setting elements
    @IBOutlet weak var privacySettingView: UIView!
    @IBOutlet weak var everyOneBtn: UIButton!
    @IBOutlet weak var onlyMeBtn: UIButton!
    @IBOutlet weak var myFriendBtn: UIButton!
    @IBOutlet weak var friendsBtn: UIButton!
    
    //select btn
    @IBOutlet weak var streamOptionBtn: UIButton!
    @IBOutlet weak var selectBtn: UIButton!
    
    //properties
//    private var streamOption : FBSDKLiveVieoPermissionSet = .timeline {
//        didSet {
//            setUIStreamOption()
//        }
//    }
    
//MARK: - override functions
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        if let accessToken = FBSDKAccessToken.current() {
            setUIVisibleForLogin(isLoggedIn: true)
//        } else {
//
//        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        let vc = segue.destination as! SettingFBSelectPageGroupVC
//        vc.viewMode = streamOption
    }
    
//MARK: - set functions
    // UI Set
    func setUIStreamOption() {
        streamOptionBtn.setTitle("rawvalue", for: .normal)
        
//        switch streamOption {
//        case .timeline:
//            setUIVisibleByStreamOption(isTimeline: true)
//            break
//        case .page, .group:
//            setUIVisibleByStreamOption(isTimeline: false)
//            selectBtn.setTitle("Select Groups", for: .normal)
//            break
//        }
    }
    
    func setUIVisibleByStreamOption(isTimeline: Bool) {
        privacySettingView.isHidden = !isTimeline
        selectBtn.isHidden = isTimeline
    }
    
    func setUIVisibleForLogin(isLoggedIn: Bool) {
        loggedView.isHidden = !isLoggedIn
        continueFBView.isHidden = isLoggedIn
    }
    
    func setUIPrivacyBtns(with selectedBtn: UIButton) {
        everyOneBtn.backgroundColor = .darkGray
        onlyMeBtn.backgroundColor = .darkGray
        myFriendBtn.backgroundColor = .darkGray
        friendsBtn.backgroundColor = .darkGray
    }
    
    //Data Set
//    func setStreamOption(with option: FBSDKLiveVieoPermissionSet) {
//        if streamOption.rawValue == option.rawValue {
//            return
//        }
//        streamOption = option
//    }
    
//IBAction functions
    @IBAction func onBackBtn(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func onLoginFBBtn(_ sender: UIButton) {
        self.setUIVisibleForLogin(isLoggedIn: true)
    }
    
    @IBAction func onLogOutBtn(_ sender: UIButton) {
        setUIVisibleForLogin(isLoggedIn: false)
    }
    
    @IBAction func onSelectBtn(_ sender: UIButton) {
//        performSegue(withIdentifier: Constants.Segue.SettingFBSelectVCSegueId, sender: nil)
    }
    
    @IBAction func onStreamToBtn(_ sender: UIButton) {
        let sheetController = UIAlertController(title: "Stream to", message: nil, preferredStyle: .actionSheet)
        sheetController.modalPresentationStyle = .popover
        let timelineAction = UIAlertAction(title: "Timeline", style: .default) { (timelineAction) in
//            self.setStreamOption(with: .timeline)
        }
        let pageAction = UIAlertAction(title: "Page", style: .default) { (pageAction) in
//            self.setStreamOption(with: .page)
        }
        let groupAction = UIAlertAction(title: "Group", style: .default) { (pageAction) in
//            self.setStreamOption(with: .group)
        }
        sheetController.addAction(timelineAction)
        sheetController.addAction(pageAction)
        sheetController.addAction(groupAction)
        if let presenter = sheetController.popoverPresentationController {
            presenter.sourceView = sender
            presenter.sourceRect = sender.bounds
        }
        present(sheetController, animated: true, completion: nil)
    }
    
    @IBAction func onPrivacyBtns(_ sender: UIButton) {
        setUIPrivacyBtns(with: sender)
        
        if sender == everyOneBtn {
            print("every one")
        }
        if sender == onlyMeBtn {
            print("only me")
        }
        if sender == myFriendBtn {
            print("my friends")
        }
        if sender == friendsBtn {
            print("friend of friends")
        }
    }

}
