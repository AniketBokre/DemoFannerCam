//
//  FanSheet.swift
//  NewFannerCam
//
//  Created by Jin on 1/12/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import UIKit
import AVFoundation

enum ActionImage: String {
    case individual = "sheet_individual"
    case collective = "sheet_collective"
    case generic = "sheet_generic"
    
    var image : UIImage? {
        return UIImage(named: self.rawValue)
    }
}

enum ActionTitle : String {
    case cancel                     = "Cancel"
    
    case standarQuality             = "Standard quality"
    case webQuality                 = "Web quality"
    
    case createVideo                = "Create Video"
    case sendToLiverecap            = "Send to Liverecap"
    
    case shareStandardQuality       = "Share standard quality"
    case shareWebQuality            = "Share web quality"
    
    case selectFromAppLib           = "Select image from app library"
    case selectFromDeviveLib        = "Select image from device library"
    
    case deleteMatch                = "Delete Match"
    case deleteHighlights           = "Delete Highlights"
    
    case onlySelected               = "Only selected"
    
    case grid                       = "Grid"
    case indiCollMarkers            = "Individual/Collective markers"
    case autoFocus                  = "Focus Auto"
    
    var style : UIAlertAction.Style {
        switch self {
        case .cancel:
            return .cancel
        case .deleteMatch, .deleteHighlights:
            return .destructive
            
        default:
            return .default
        }
    }
}

enum SheetKeys : String {
    case imageTintColor = "imageTintColor"
    case isChecked      = "checked"
    case image          = "image"
    case titleTextColor = "titleTextColor"
}

typealias ActionHandler = (UIAlertAction) -> Void
typealias ActionTitleData = (actionImage: ActionImage?, imgTintColor: UIColor?, isChecked: Bool?, title: String)

extension UIViewController {
    
    func fanSheetAction(titleData: ActionTitleData, handler: ActionHandler? = nil) -> UIAlertAction {
        var actionStyle = UIAlertAction.Style.default
        var titleStr = String()
        
        if let title = ActionTitle(rawValue: titleData.title) {
            actionStyle = title.style
            titleStr = title.rawValue
        } else {
            titleStr = titleData.title
        }
        
        let action = UIAlertAction(title: titleStr, style: actionStyle, handler: handler)
        if let color = titleData.imgTintColor {
            action.setValue(color, forKey: SheetKeys.imageTintColor.rawValue)
        }
        if let checkData = titleData.isChecked {
            action.setValue(checkData, forKey: SheetKeys.isChecked.rawValue)
        }
        if let imageData = titleData.actionImage {
            action.setValue(imageData.image, forKey: SheetKeys.image.rawValue)
        }
        
        return action
    }
    
}
