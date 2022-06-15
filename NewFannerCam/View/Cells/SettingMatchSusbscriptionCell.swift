//
//  SettingMatchSusbscriptionCell.swift
//  NewFannerCam
//
//  Created by Jin on 3/25/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import UIKit
import StoreKit

class SettingMatchSusbscriptionCell: UITableViewCell {

    @IBOutlet weak var purchaseBtn      : UIButton!
    @IBOutlet weak var titleLbl         : UILabel!
    
    //MARK: - Properties
    var buyButtonHandler : ((_ product: SKProduct) -> Void)?
    
    var product: SKProduct? {
        didSet {
            guard let product = product else { return }
            
            titleLbl?.text = product.localizedTitle

            if IAPService.canMakePayments() {
                self.purchaseBtn.setTitle(product.localizedPrice ?? "Free", for: .normal)
            } else {
                self.purchaseBtn.isHidden = true
                detailTextLabel?.text = "Not available"
            }
        }
    }
    
//MARK: - Override functions
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        textLabel?.text = ""
        detailTextLabel?.text = ""
        accessoryView = nil
    }
    
//MARK: - Main functions
    
//MARK: - IBAction functions
    @IBAction func onPurchaseBtn(_ sender: UIButton) {
        buyButtonHandler?(product!)
    }

}

extension SKProduct {
    
    var localizedPrice: String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currencyAccounting
        formatter.locale = priceLocale
        return formatter.string(from: price)
    }
    
    func getSymbol(forCurrencyCode code: String) -> String? {
        let locale = NSLocale(localeIdentifier: code)
        if locale.displayName(forKey: .currencySymbol, value: code) == code {
            let newlocale = NSLocale(localeIdentifier: code.dropLast() + "_en")
            return newlocale.displayName(forKey: .currencySymbol, value: code)
        }
        return locale.displayName(forKey: .currencySymbol, value: code) ?? "€"
    }
    
}
