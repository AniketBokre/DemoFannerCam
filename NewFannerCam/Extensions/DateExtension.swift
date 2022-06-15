//
//  DateExtension.swift
//  NewFannerCam
//
//  Created by Jin on 1/17/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import Foundation

extension Date {
    
    func uniqueNew() -> String {
        let names = String(timeIntervalSince1970).components(separatedBy: ".")
        return "\(names[0])\(names[1])"
    }
    
}
