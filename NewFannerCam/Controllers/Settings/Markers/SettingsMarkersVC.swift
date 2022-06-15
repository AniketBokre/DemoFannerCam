//
//  SettingsMarkersVC.swift
//  NewFannerCam
//
//  Created by Jin on 12/28/18.
//  Copyright © 2018 fannercam3. All rights reserved.
//

import UIKit
import DropDown

enum SettingsMarkersViewMode: String {
    case individual         = "Individual Markers"
    case collective         = "Collective Markers"
    case generic            = "Generic Markers"
    
    var markerType : MarkerType {
        switch self {
        case .individual:
            return MarkerType.individual
        case .generic:
            return MarkerType.generic
        case .collective:
            return MarkerType.collective
        }
    }
}

typealias MarkerDetailData = (mode: SettingsMarkersDetailMode, marker: Marker?, index: Int?)

class SettingsMarkersVC: UIViewController {

    @IBOutlet weak var mTableView   : UITableView!
    @IBOutlet weak var addBtn       : UIBarButtonItem!
    
    var dropDown : DropDown?
    
    var viewMode = SettingsMarkersViewMode.individual
    
    var droppedCellIndex : IndexPath?
    
//MARK: - Override functions
    override func viewDidLoad() {
        super.viewDidLoad()
        DataManager.shared.settingsDelegate = self
        navigationItem.title = viewMode.rawValue
        if viewMode == .generic {
            navigationItem.rightBarButtonItem = nil
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constant.Segue.SettingsMarkersDetailSegueId {
            let nvc = segue.destination as! UINavigationController
            let vc = nvc.children[0] as! SettingsMarkersDetailVC
            if let data = sender as? MarkerDetailData {
                vc.detailMode = data.mode
                vc.currentMarker = data.marker
                vc.index = data.index
                vc.markerType = viewMode.markerType
            }
        }
    }
    
//MARK: - Other functions
    func checkIsHighlighted(_ index: IndexPath) -> Bool {
        if droppedCellIndex == nil {
            return false
        } else {
            if droppedCellIndex!.row == index.row {
                return true
            } else {
                return false
            }
        }
    }
    
//MARK: - IBAction functions
    @IBAction func onAddBtn(_ sender: Any) {
        performSegue(withIdentifier: Constant.Segue.SettingsMarkersDetailSegueId, sender: MarkerDetailData(mode: SettingsMarkersDetailMode.new, marker: nil, index: nil))
    }
    
    @IBAction func onBackBtn(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
}

//MARK: - DataManagerSettingsDelegate
extension SettingsMarkersVC: DataManagerSettingsDelegate {
    func didUpdateaMarker(_ updateMode: Updater, _ updatedItem: Marker, _ index: Int) {
        print("updated setting markers")
        mTableView.update(row: IndexPath(row: index, section: 0), for: updateMode)
    }
}

//MARK: - SettingMarkerCellDelegate
extension SettingsMarkersVC: SettingMarkerCellDelegate {
    func settingMarkerCell(didClickedMore settingMarkerCell: SettingMarkerCell) {
        guard let indexPath = mTableView.indexPath(for: settingMarkerCell) else { return }
        
        self.droppedCellIndex = indexPath
        dropDown = DropDown()
        dropDown?.backgroundColor = #colorLiteral(red: 0.3333333433, green: 0.3333333433, blue: 0.3333333433, alpha: 1)
        dropDown?.anchorView = settingMarkerCell.contentView
        dropDown?.direction = .any
        dropDown?.bottomOffset = CGPoint(x: 0, y:(dropDown?.anchorView?.plainView.bounds.height)!)
        dropDown?.dataSource = [EMPTY_STRING]
        dropDown?.cellNib = UINib(nibName: Constant.Cell.SettingsMarkerDropCell, bundle: nil)
        dropDown?.customCellConfiguration = { (index: Index, item: String, cell: DropDownCell) -> Void in
            guard let c = cell as? SettingsMarkersDetailDropDownCell else { return }
            let marker = DataManager.shared.settingsMarkers[self.viewMode.markerType.rawValue]?[indexPath.row]
            c.initialize(self, marker!, indexPath.row)
        }
        dropDown?.dismissMode = .onTap
        
        dropDown?.cancelAction = {
            self.cancel()
        }
        dropDown?.selectionAction = { (i, val) in
            self.cancel()
        }
        dropDown?.show()
        
        mTableView.reloadData()
    }
    
    func cancel() {
        self.droppedCellIndex = nil
        self.mTableView.reloadData()
    }
}

//MARK: - SettingsMarkersDetailDropDownCellDelegate
extension SettingsMarkersVC: SettingsMarkersDetailDropDownCellDelegate {
    func onEdit(_ cell: SettingsMarkersDetailDropDownCell) {
        dropDown?.hide()
        cancel()
        performSegue(withIdentifier: Constant.Segue.SettingsMarkersDetailSegueId, sender: MarkerDetailData(mode: SettingsMarkersDetailMode.edit, marker: cell.marker, index: cell.index))
    }
    
    func onDelete(_ cell: SettingsMarkersDetailDropDownCell) {
        dropDown?.hide()
        cancel()
        
        if DataManager.shared.settingsMarkers[viewMode.markerType.rawValue]?.count == 1 {
            MessageBarService.shared.warning("It should keep at least one!")
            return
        }
        
        MessageBarService.shared.alertQuestion(title: "Warning!", message: "Are you sure to delete this marker?", yesString: "Yes", noString: "No", onYes: { (yesAction) in
            DataManager.shared.updateSettingMarkers(cell.marker, cell.index, .delete)
        }, onNo: nil)
    }
    
    func onChangeDurationBtn(_ cell: SettingsMarkersDetailDropDownCell, selectedDuration: Float64) {
        dropDown?.hide()
        cancel()
        cell.marker.duration = selectedDuration
        DataManager.shared.updateSettingMarkers(cell.marker, cell.index, .replace)
    }
}

//MARK: - UITableViewDelegate & data source
extension SettingsMarkersVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return DataManager.shared.settingsMarkers[viewMode.markerType.rawValue]?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constant.Cell.SettingsMarkersCell, for: indexPath) as! SettingMarkerCell
        
        let marker = DataManager.shared.settingsMarkers[viewMode.markerType.rawValue]?[indexPath.row]
        
        cell.initialize(marker!, self, checkIsHighlighted(indexPath))
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if UI_USER_INTERFACE_IDIOM() == .phone {
            return 44
        } else {
            return 60
        }
    }
    
}
