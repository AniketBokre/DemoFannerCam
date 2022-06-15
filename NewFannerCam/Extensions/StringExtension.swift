//
//  StringExtension.swift
//  NewFannerCam
//
//  Created by Jin on 1/18/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import Foundation
import UIKit

extension String {
    
    func toImage() -> UIImage? {
        return UIImage(named: self)
    }
    
    func string(_ range: NSRange, _ string: String) -> String {
        guard let textRange = Range(range, in: self) else { return String() }
        return self.replacingCharacters(in: textRange, with: string)
    }
    
    func combine(adding text: String, with midString: String) -> String {
        return "\(self)\(midString)\(text)"
    }
    
    func setExtension(isMov: Bool) -> String {
        return isMov ? self.appending(".mov") : self.appending(".png")
    }
    
}
