//
//  FanGenViewEx.swift
//  NewFannerCam
//
//  Created by Jin on 1/22/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import Foundation
import UIKit

enum Team: String {
    case first              = "First_Left"
    case second             = "Second_Right"
}

enum FanGenMarker : String {
    case individual         = "ic_individual_red"
    case collective         = "ic_collective_red"
    case generic            = "ic_generic_red"
    
    var image : UIImage? {
        return UIImage(named: self.rawValue)
    }
    
    var tagTitle : String {
        switch self {
        case .individual:
            return FanGenTitles.individual.rawValue
        case .generic:
            return FanGenTitles.generic.rawValue
        case .collective:
            return FanGenTitles.collective.rawValue
        }
    }
    
    var markerType: MarkerType {
        switch self {
        case .individual:
            return MarkerType.individual
        case .generic:
            return MarkerType.generic
        case .collective:
            return MarkerType.collective
        }
    }
}

enum FanGenTitles: String {
    case individual = "Individual Tag"
    case generic    = "Generic Tag"
    case collective = "Collective Tag"
    
    case one        = "1"
    case two        = "2"
    case thr        = "3"
    case four       = "4"
    case five       = "5"
    case six        = "6"
    case seven      = "7"
    case eight      = "8"
    case nine       = "9"
    case ten        = "0"
    case symbol     = "#"
    
    case empty      = ""
}

struct FanGenColor {
    static let white = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    static let black = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
    static let clear = UIColor.clear
}

struct FanGenId {
    static let faGenerationVideo = "FanGenerationVideo"
    static let markersViewNib = "MarkersView"
    
    static let tagsViewNib = "TagsView"
    
    static let fanGenCellNib = "TagListViewCell"
    static let cellId = "TagListViewCell"
    
    static let tagNumViewNib = "TagNumView"
}
