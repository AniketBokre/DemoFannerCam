//
//  MatchesVC.swift
//  NewFannerCam
//
//  Created Jin on 12/24/18.
//  Copyright © 2018 fannercam3. All rights reserved.
//

import UIKit

class MatchesVC: UIViewController {

    @IBOutlet weak var purchasedMatchCountBtn           : UIButton!
    @IBOutlet weak var initialCreateBtnsStackView       : UIStackView!
    @IBOutlet weak var mTableView                       : UITableView!
    
//MARK: - override functions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        DataManager.shared.matchCountDelegate = self
        DataManager.shared.tabberView = navigationController?.tabBarController?.view
        DataManager.shared.setData()
        
        
        mTableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        DataManager.shared.matchesDelegate = self
        
        mTableView.reloadData()
        
        switchTB()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let detailVC = segue.destination as! MatchesDetailVC
        let index = sender as! Int
        let selectedMatch = DataManager.shared.matches[index]
        detailVC.selectedMatch = SelectedMatch(match: selectedMatch, index: index)
    }
    
//MARK: - initial functions
    func switchTB() {
        mTableView.isHidden = DataManager.shared.matches.isEmpty
        initialCreateBtnsStackView.isHidden = !DataManager.shared.matches.isEmpty
    }
    
//MARK: - Main functions
    func showCreateNewMatchVC(_ mode: MatchType) {
        if let nvc = createMatchNVC(with: mode) {
            present(nvc, animated: true, completion: nil)
        }
    }

//MARK: - IBActions & @objc functions
    @IBAction func createRecordMatch(_ sender: UIButton) {
        self.showCreateNewMatchVC(.recordMatch)
    }
    
    @IBAction func createImportMatchBtn(_ sender: UIButton) {
        self.showCreateNewMatchVC(.importMatch)
    }
    
    @IBAction func createLiveMatchBtn(_ sender: UIButton) {
        self.showCreateNewMatchVC(.liveMatch) 
    }
    
    @IBAction func onPurchasedMatchCountBtn(_ sender: UIButton) {
        let settingsSubscriptionsNVC = settingsSubscriptionNav()
        present(settingsSubscriptionsNVC, animated: true, completion: nil)
    }

}

//MARK: - MatchCellDelegate
extension MatchesVC : MatchCellDelegate {
    func matchCell(_ matchCell: MatchCell, didTapMore button: UIButton, selectedItem: Match) {
        guard let index = mTableView.indexPath(for: matchCell) else {
            MessageBarService.shared.error("Selected wrong match item!")
            return
        }
        
        let sheetController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        sheetController.modalPresentationStyle = .popover
        
        sheetController.addAction(UIAlertAction(title: ActionTitle.deleteMatch.rawValue, style: .destructive) { (deleteMatchAction) in
            
            MessageBarService.shared.alertQuestion(title: "Warning!", message: "Are you sure to delete this \"\(DataManager.shared.matches[index.row].namePresentation())\" match?", yesString: "Yes", noString: "No", onYes: { (yesAction) in
                
                DataManager.shared.updateMatches(selectedItem, index.row, .delete)
                
            }, onNo: nil)
            
        })
        
        sheetController.addAction(UIAlertAction(title: ActionTitle.cancel.rawValue, style: .cancel, handler: nil))
        if let presenter = sheetController.popoverPresentationController {
            presenter.sourceView = button
            presenter.sourceRect = button.bounds
        }
        self.present(sheetController, animated: true, completion: nil)
    }
}

//MARK: - DataManagerDelegate
extension MatchesVC : DataManagerMatchesDelegate, DataManagerMatchCountDelegate {
    func didUpdateMatches(_ updateMode: Updater, _ updatedItem: Match?, _ index: Int?) {
        
        var row : IndexPath!
        
        if let rowIndex = index {
            row = IndexPath(row: rowIndex, section: 0)
        } else {
            row = IndexPath(row: 0, section: 0)
        }
        
        mTableView.update(row: row, for: updateMode)
        
        if DataManager.shared.matches.isEmpty {
            switchTB()
        }
    }
    
    func didUpdateMatchCount() {
        DispatchQueue.main.async {
            self.purchasedMatchCountBtn.setTitle("\(DataManager.shared.purchasedMatchCount) matches purchased", for: .normal)
        }
    }
}

//MARK: - Table view data source & delegate
extension MatchesVC : UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if UI_USER_INTERFACE_IDIOM() == .phone {
            return 70
        } else {
            return 100
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return DataManager.shared.matches.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constant.Cell.MatchCellId, for: indexPath) as! MatchCell
        
        cell.initialize(DataManager.shared.matches[indexPath.row], self)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: Constant.Segue.MatchesHighlightsSegueId, sender: indexPath.row)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if tableView.indexPathsForVisibleRows?.last?.row == indexPath.row {
            switchTB()
        }
    }
}
