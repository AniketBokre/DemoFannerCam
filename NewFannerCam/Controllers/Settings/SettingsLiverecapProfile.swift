//
//  SettingsLiverecapProfile.swift
//  NewFannerCam
//
//  Created by Jin on 21/09/20.
//  Copyright © 2020 fannercam3. All rights reserved.
//

import UIKit

class SettingsLiverecapProfile: UIViewController {

    @IBOutlet weak var lblName: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        // Do any additional setup after loading the view.
        
        lblName.text = name
    }
    
    @IBAction func onBackBtn(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func onLogoutBtn(_ sender: Any) {
        UserDefaults.standard.removeObject(forKey: "customerId")
        UserDefaults.standard.synchronize()
        navigationController?.popViewController(animated: true)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
