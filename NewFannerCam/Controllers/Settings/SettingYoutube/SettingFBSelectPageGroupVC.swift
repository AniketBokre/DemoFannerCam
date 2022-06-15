//
//  SettingFBSelectPageGroupVC.swift
//  NewFannerCam
//
//  Created by Jin on 4/6/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import UIKit

protocol SettingFBSelectPageGroupVCDelegate: class {
    func dismissedSelectVC(with selectedItem: Any)
}

class SettingFBSelectPageGroupVC: UIViewController {

    @IBOutlet weak var mTableView: UITableView!
    
//    var viewMode: FBSDKLiveVieoPermissionSet = .page
    
    private var selectedItem: Any!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        navigationItem.title = "Select your \(viewMode.rawValue.lowercased())"
    }
    
    //MARK: - IBAction functions
    @IBAction func onBackBtn(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }

}

//MARK: - table view data source & delegate
extension SettingFBSelectPageGroupVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if UI_USER_INTERFACE_IDIOM() != .phone {
            return 60
        } else {
            return 44
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        let text = "viewMode.rawValue.uppercased()"
        cell.textLabel?.text = "\(text) \(indexPath.row)"
        cell.backgroundColor = Constant.Color.defaultBlack
        cell.textLabel?.textColor = .white
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let text = "viewMode.rawValue.uppercased()"
        let printText = "\(text) \(indexPath.row)"
        print(printText)
    }
}
