//
//  MainTabBC.swift
//  NewFannerCam
//
//  Created by Jin on 3/29/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import UIKit

extension Notification.Name {
    static let DidLeaveMatchTab = Notification.Name("MainTabBCDidLeaveMatchTab")
    static let DidEnterSettingTab = Notification.Name("MainTabBCDidEnterSettingTab")
}

class MainTabBC: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

}

extension MainTabBC: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        return true
    }
    
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        if selectedIndex == 0 {
            NotificationCenter.default.post(name: .DidLeaveMatchTab, object: nil)
        } else {
            if selectedIndex == 1 {
                
            }
            else if selectedIndex == 2 {
                NotificationCenter.default.post(name: .DidEnterSettingTab, object: nil)
            }
        }
    }
}
