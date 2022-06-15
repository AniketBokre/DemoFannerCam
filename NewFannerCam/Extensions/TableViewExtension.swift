//
//  TableViewExtension.swift
//  NewFannerCam
//
//  Created by Jin on 3/10/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import UIKit

extension UITableView {
    
    func update(row: IndexPath, for updater: Updater) {
        DispatchQueue.main.async {
            
            if updater == .new || updater == .old {
                self.reloadData()
            } else {
                self.beginUpdates()
                switch updater {
                case .replace:
                    self.reloadRows(at: [row], with: .none)
                case .delete:
                    self.deleteRows(at: [row], with: .right)
                default:
                    break
                }
                self.endUpdates()
            }
        }
    }
    
}
