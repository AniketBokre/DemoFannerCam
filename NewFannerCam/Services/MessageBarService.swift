//
//  MessageBarService.swift
//  NewFannerCam
//
//  Created by Jin on 1/11/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import UIKit
import Foundation
import SwiftMessageBar

final class MessageBarService {
    
    static let shared = MessageBarService()
    
    init() {
        
    }
    
    func error(_ msg: String) {
        DispatchQueue.main.async {
            SwiftMessageBar.showMessage(withTitle: "Error!", message: msg, type: .error)
        }
    }
    
    func warning(_ msg: String) {
        DispatchQueue.main.async {
            SwiftMessageBar.showMessage(withTitle: "Warning!", message: msg, type: .info)
        }
    }
    
    func notify(_ msg: String) {
        DispatchQueue.main.async {
            SwiftMessageBar.showMessage(withTitle: "Information", message: msg, type: .success)
        }
    }
    
    func alert(title: String = "Alert", message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
        
        if var topController = UIApplication.shared.keyWindow?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            
            topController.present(alert, animated: true, completion: nil)
        }
    }
    
    typealias HandlerType = (UIAlertAction) -> Void
    
    func alertQuestion(title: String = "Alert", message: String,
                       yesString: String = "Yes", noString: String = "No",
                       onYes: HandlerType? = nil, onNo: HandlerType? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: yesString, style: UIAlertAction.Style.default, handler: onYes))
        alert.addAction(UIAlertAction(title: noString, style: UIAlertAction.Style.cancel, handler: onNo))
        
        if var topController = UIApplication.shared.keyWindow?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            
            topController.present(alert, animated: true, completion: nil)
        }
    }
}
