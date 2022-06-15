//
//  StorePurchaseVC.swift
//  NewFannerCam
//
//  Created by Qaiser on 5/25/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//
import UIKit
import StoreKit

protocol StorePurchaseDelegate: class {
    func purchasePuroduct(pendingProduct: SKProduct!)
}

class StorePurchaseVC: UIViewController {

    var delegate: StorePurchaseDelegate?
    var pendingProduct : SKProduct!
    var inSettingTab = true
    @IBOutlet weak var mainHeadingLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var mainDescLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        var priceText = ""
        if IAPService.canMakePayments() {
            priceText = pendingProduct.localizedPrice ?? "Free"
        } else {
            priceText = ""
        }
        mainHeadingLabel.text = "\(pendingProduct.localizedTitle) \(priceText) Per Month"
        mainDescLabel.text = "\(pendingProduct.localizedDescription)"

        descriptionLabel.text = "A \(priceText) per Month purchase will be applied to your iTunes account. Subscriptions will automatically renew unless canceled within 24-hours before the end of the current period. You can cancel anytime with your iTunes account settings. Any unused portion of a free trial will be forfeited if you purchase a subscription. For more information, see our"

        // Do any additional setup after loading the view.
    }
    // MARK: Button action
    @IBAction func termsButtonTap(_ sender: Any) {
        self.pushToTermsView()
    }
    @IBAction func privacyBittonTap(_ sender: Any) {
        self.pushToPrivacyView()
    }
    @IBAction func backButtonTap(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    @IBAction func purchaseButtonTap(_ sender: Any) {
        self.delegate?.purchasePuroduct(pendingProduct: pendingProduct)
        self.dismiss(animated: true, completion: nil)
    }



    // MARK: Show Privacy View
    func pushToPrivacyView() {
        let termPrivacyNVC = self.settingsTermsPrivacyNav()
        let vc = termPrivacyNVC.children[0] as! TermPrivacyWebVC
        vc.viewType = .Privacy
        self.present(termPrivacyNVC, animated: true, completion: nil)
    }

    // MARK: Show Terms View
    func pushToTermsView() {
        let termPrivacyNVC = self.settingsTermsPrivacyNav()
        let vc = termPrivacyNVC.children[0] as! TermPrivacyWebVC
        vc.viewType = .Terms
        self.present(termPrivacyNVC, animated: true, completion: nil)
    }

}
