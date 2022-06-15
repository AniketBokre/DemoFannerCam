//
//  HighlightsVC.swift
//  NewFannerCam
//
//  Created by Jin on 12/27/18.
//  Copyright © 2018 fannercam3. All rights reserved.
//

import UIKit

private let settingTxts = [
    ["Buy matches"], //"Youtube Live",
    ["Individual Marker", "Collective Marker", "Generic Marker"],
    ["Image archive", "Image archive 2", "Soundtracks", "Templates"],
    ["Log in Liverecap"]
]

private var settingTxtsWithLogin = [
    ["Buy matches"], //"Youtube Live",
    ["Individual Marker", "Collective Marker", "Generic Marker"],
    ["Image archive", "Image archive 2", "Soundtracks", "Templates"],
    [name + " Liverecap"]
]

class SettingsVC: UIViewController {

    @IBOutlet weak var mTableView: UITableView!
    @IBOutlet weak var batteryLvLbl: UILabel!
    @IBOutlet weak var storageLbl: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        settingTxtsWithLogin = [
            ["Buy matches"], //"Youtube Live",
            ["Individual Marker", "Collective Marker", "Generic Marker"],
            ["Image archive", "Image archive 2", "Soundtracks", "Templates"],
            [name + " Liverecap"]
        ]
        
        mTableView.reloadData()
        batteryLvLbl.text = "\(Int(Utiles.battery()))%"
        storageLbl.text = "\(Utiles.getFreeDiskspace() ?? 0) GB"
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constant.Segue.SettingMarkerSegueId {
            let vc = segue.destination as! SettingsMarkersVC
            if let indexPath = mTableView.indexPathForSelectedRow {
                vc.viewMode = indexPath.row.selectedType()
            }
        }
        else if segue.identifier == Constant.Segue.SettingsTemTraSegueId {
            let vc = segue.destination as! SettingsTemTraVC
            if let index = sender as? Int {
                vc.viewMode = index == 2 ? SettingsTemTraVCMode.soundTracks : SettingsTemTraVCMode.templates
            }
        }
        else if segue.identifier == Constant.Segue.SettingImgArchiveSeugueId {
            let vc = segue.destination as! SettingsImgArchiveVC
            vc.viewMode = .show
        }else if segue.identifier == Constant.Segue.SettingsLoginLiverecapSegueId {
            
        }
    }
    
    func showCreateNewMatchVC(_ mode: MatchType) {
        if let nvc = createMatchNVC(with: mode) {
            present(nvc, animated: true, completion: nil)
        }
    }
    
    @IBAction func onCreateImportBtn(_ sender: Any) {
        self.showCreateNewMatchVC(.importMatch)
    }
    
    @IBAction func onCreateRecordBtn(_ sender: Any) {
        self.showCreateNewMatchVC(.recordMatch)
    }
    
}

extension SettingsVC: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return customerId > 0 ? settingTxtsWithLogin.count : settingTxts.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return customerId > 0 ? settingTxtsWithLogin[section].count : settingTxts[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constant.Cell.SettingCell, for: indexPath)
        
        cell.selectionStyle = .none
        if let label = cell.viewWithTag(331) as? UILabel {
            label.text = customerId > 0 ? settingTxtsWithLogin[indexPath.section][indexPath.row] : settingTxts[indexPath.section][indexPath.row]
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if UI_USER_INTERFACE_IDIOM() == .phone {
            return 44
        } else {
            return 60
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let result = UIView()
        result.backgroundColor = Constant.Color.black
        return result
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 1
        }
        return 10
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
//            if indexPath.row == 0 {
//                // to youtube live setting page
//            }
//            else {
                performSegue(withIdentifier: Constant.Segue.SettingsSubscriptionSegueId, sender: nil)
//            }
        }
        else if indexPath.section == 1 {
            performSegue(withIdentifier: Constant.Segue.SettingMarkerSegueId, sender: nil)
        }
        else if indexPath.section == 2 {
            if indexPath.row == 0 {
                performSegue(withIdentifier: Constant.Segue.SettingImgArchiveSeugueId, sender: nil)
            } else if indexPath.row == 1 {
                performSegue(withIdentifier: Constant.Segue.SettingImgArchiveSeugueId2, sender: nil)
            } else {
                performSegue(withIdentifier: Constant.Segue.SettingsTemTraSegueId, sender: indexPath.row)
            }
        }else if indexPath.section == 3 {
            
            if customerId > 0 {
                self.performSegue(withIdentifier: Constant.Segue.SettingsLiverecapProfileSegueId, sender: nil)
            }
            else {
                performSegue(withIdentifier: Constant.Segue.SettingsLoginLiverecapSegueId, sender: nil)
            }
                
        }
    }
    
}

extension Int {
    func selectedType() -> SettingsMarkersViewMode {
        switch self {
        case 0:
            return SettingsMarkersViewMode.individual
        case 1:
            return SettingsMarkersViewMode.collective
        case 2:
            return SettingsMarkersViewMode.generic
        default:
            return SettingsMarkersViewMode.individual
        }
    }
}
