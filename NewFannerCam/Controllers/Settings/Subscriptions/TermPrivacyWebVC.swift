//
//  TermPrivacyWebVC.swift
//  NewFannerCam
//
//  Created by dreamskymobi on 5/21/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//
import UIKit

class TermPrivacyWebVC: UIViewController {

    @IBOutlet weak var mainWebview: UIWebView!

    var viewType:Constant.ViewControllerType?
    var fileUrl = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        if self.viewType == .Terms{
            fileUrl = "https://d1a543h7yz12to.cloudfront.net/objects/privacy_and_terms/condizioni-duso.pdf"
            self.navigationItem.title = "Terms Of Use"
        }else{
            fileUrl = "https://d1a543h7yz12to.cloudfront.net/objects/privacy_and_terms/informativa-sulla-privacy.pdf"
            self.navigationItem.title = "Privacy"
        }
        let request = URLRequest(url: URL(string: fileUrl)!)
        mainWebview.loadRequest(request)

        // Do any additional setup after loading the view.
    }
    @IBAction func onBackBtn(_ sender: UIButton) {
        navigationController?.dismiss(animated: true, completion: nil)
    }

}
