//
//  StopFrameButton.swift
//  NewFannerCam
//
//  Created by Jin on 3/5/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import Foundation
import UIKit

class StopFrameButton: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

class FanLandscapeImagePicker: UIImagePickerController {

    var orientation             = UIInterfaceOrientationMask.landscape
    
//MARK: - Init functions
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }
    
}
