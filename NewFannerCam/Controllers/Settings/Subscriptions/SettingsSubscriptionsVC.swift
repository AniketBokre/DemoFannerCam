//
//  SettingsSubscriptionsVC.swift
//  NewFannerCam
//
//  Created by Jin on 12/30/18.
//  Copyright © 2018 fannercam3. All rights reserved.
//

import UIKit
import StoreKit

private let pCellId = "SettingsSubscriptionsPCell"
private let aCellId = "SettingsSubscriptionsACell"
private let iCellId = "SettingMatchSusbscriptionInfoCell"
private let subscriptionKey = "Fan_Subscription_Key"

class SettingsSubscriptionsVC: UITableViewController {
    
    private var products: [SKProduct] = []
    private var pendingProduct : SKProduct!
    
    // access properties by other classes.
    var inSettingTab = true

    override func viewDidLoad() {
        super.viewDidLoad()

        DataManager.shared.userInfoDelegate = self
        
        reloadProducts()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handlePurchaseNotification(_:)), name: .IAPServicePurchaseNotification, object: nil)
    }
    
    //MARK: - Initial functions
    func reloadProducts(onRefreshing: Bool = false) {
        
        func loadProducts() {
            FannerCamProducts.matchStores.requestProducts{ [weak self] success, products in //
                guard let self = self else { return }
                if success {
                    self.products = products ?? []
                    self.products.sort { $0.price.floatValue < $1.price.floatValue }
                    DataManager.shared.matchProducts = self.products
                    DispatchQueue.main.async { self.tableView.reloadData() }
                } else {
                    MessageBarService.shared.error("No available purchase items.")
                }
                Utiles.setHUD(false)
            }
        }
        let loadingView = inSettingTab ? DataManager.shared.tabberView : view
        Utiles.setHUD(true, loadingView!, .extraLight, "")
        if onRefreshing {
            loadProducts()
        } else {
            if DataManager.shared.matchProducts.count > 0 {
                products = DataManager.shared.matchProducts
                tableView.reloadData()
                Utiles.setHUD(false)
            } else {
                loadProducts()
            }
        }
    }
    
    @objc func handlePurchaseNotification(_ notification: Notification) {
        guard pendingProduct != nil else { return }
        let productID = pendingProduct.productIdentifier
        guard let index = products.firstIndex(where: { product -> Bool in
            product.productIdentifier == productID
        }) else { return }
        
        let title = products[index].localizedTitle
        let coms = title.components(separatedBy: " ")
        print(coms)
        if let count = Int(coms[0]) {
            DataManager.shared.updatePurchasedMatchCount(count)
        } else {
            if index == 0 {
                DataManager.shared.updatePurchasedMatchCount(10)
            } else if index == 1 {
                DataManager.shared.updatePurchasedMatchCount(20)
            } else {
                DataManager.shared.updatePurchasedMatchCount(30)
            }
        }
        
        DispatchQueue.main.async {
            self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .fade)
        }
        pendingProduct = nil
        Utiles.setHUD(false)
    }
    
    func startedPurchasing() {
        let loadingView = inSettingTab ? DataManager.shared.tabberView : view
        Utiles.setHUD(true, loadingView!, .extraLight, "")
    }

//MARK: - IBAction
    @IBAction func onRefreshBtn(_ sender: UIButton) {
        reloadProducts(onRefreshing: true)
    }
    
    @IBAction func onBackBtn(_ sender: Any) {
        navigationController?.popViewController(animated: true)
        dismiss(animated: true, completion: nil)
    }
    
// MARK: - Table view data source
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if UI_USER_INTERFACE_IDIOM() == .phone {
            return 50
        } else {
            return 70
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return products.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: pCellId, for: indexPath) as! SettingMatchSusbscriptionCell
        cell.product = products[indexPath.row]
        cell.buyButtonHandler = { product in
            self.pendingProduct = product
            FannerCamProducts.matchStores.buyProduct(product)
            self.startedPurchasing()
        }
        
        
        var dialogMessage = UIAlertController(title: "Information", message: "\(DataManager.shared.purchasedMatchCount) matches available", preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
        print("Ok button tapped")
        })
        dialogMessage.addAction(ok)
        self.present(dialogMessage, animated: true, completion: nil)
        
        
        cell.selectionStyle = .none
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }

}

extension SettingsSubscriptionsVC: DataManagerUserInfoDelegate {
    func didUpdateUserInfo(_ updater: Updater) {
        self.tableView.reloadData()
    }
}
