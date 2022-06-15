//
//  SettingTemSouHeaderCell.swift
//  NewFannerCam
//
//  Created by Jin on 3/27/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import UIKit
import StoreKit

class SettingTemSouHeaderCell: UITableViewCell {
    
    @IBOutlet weak var titleLbl         : UILabel!
    @IBOutlet weak var purchaseBtn      : UIButton!
    @IBOutlet weak var descripLabel     : UILabel!
    
    var purchaseHandler : ((_ product: SKProduct) -> Void)?
    
    var viewMode = SettingsTemTraVCMode.soundTracks
    
    var product : SKProduct? {
        didSet {
            guard let product = product else { return }
            
            titleLbl?.text = product.localizedTitle
            descripLabel?.text = product.localizedDescription
            
            if self.viewMode == .soundTracks {
                if FannerCamProducts.soundtrackStore.isProductPurchased(product.productIdentifier) {
                    setPurchaseBtnTitle(nil)
                } else {
                    setPurchaseBtnTitle(product)
                }
            } else {
                if FannerCamProducts.templatesStore.isProductPurchased(product.productIdentifier) {
                    setPurchaseBtnTitle(nil)
                } else {
                    setPurchaseBtnTitle(product)
                }
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func setTitleBtn(btn: UIButton, str: String) {
        UIView.setAnimationsEnabled(false)
        btn.setTitle(str, for: .normal)
        UIView.setAnimationsEnabled(true)
    }
    
    func setPurchaseBtnTitle(_ productItem: SKProduct?) {
        if let product = productItem {
            if IAPService.canMakePayments() {
                setTitleBtn(btn: purchaseBtn, str: product.localizedPrice ?? "Free")
            } else {
                setTitleBtn(btn: purchaseBtn, str: "No purchase")
            }
        } else {
            setTitleBtn(btn: purchaseBtn, str: "")
            purchaseBtn.isHidden = true
        }
    }
    
//MARK: - IBAction
    @IBAction func onPurchaseBtn(_ sender: UIButton) {
        purchaseHandler?(product!)
    }

}
