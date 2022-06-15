//
//  ScoreboardSetting.swift
//  NewFannerCam
//
//  Created by Jin on 3/14/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import UIKit
import Foundation

struct ScoreboardSetting: Codable {
    
    var point1          = 1
    var point2          = 2
    var point3          = 3
    var period          = "1T"
    
    enum ScoreboardSettingKeys : String, CodingKey {
        case point1           = "ScoreboardSetting_point1"
        case point2           = "ScoreboardSetting_point2"
        case point3           = "ScoreboardSetting_point3"
        case period           = "ScoreboardSetting_period"
    }
    
    //MARK: - set functions
    mutating func set(_ point1: Int, _ point2: Int, _ point3: Int, _ period: String) -> Bool {
        
        if self.point1 == point1, self.point2 == point2, self.point3 == point3, self.period == period {
            return false
        } else {
            self.point1 = point1
            self.point2 = point2
            self.point3 = point3
            self.period = period
            
            return true
        }
    }
    
    //MARK: - Init functions
    init() {
        
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: ScoreboardSettingKeys.self)
        
        point1 = try container.decode(Int.self, forKey: .point1)
        point2 = try container.decode(Int.self, forKey: .point2)
        point3 = try container.decode(Int.self, forKey: .point3)
        period = try container.decode(String.self, forKey: .period)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: ScoreboardSettingKeys.self)
        try container.encode(point1, forKey: .point1)
        try container.encode(point2, forKey: .point2)
        try container.encode(point3, forKey: .point3)
        try container.encode(period, forKey: .period)
    }
    
}
