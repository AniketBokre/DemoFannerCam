//
//  StopFrameEditVC.swift
//  NewFannerCam
//
//  Created by Jin on 1/14/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import UIKit

protocol StopFrameEditVCDelegate: class {
    func dismiss(with stopframe: StopFrame)
}

class StopFrameEditVC: UIViewController {
    
    @IBOutlet weak var previewImgView   : UIImageView!
    @IBOutlet weak var slider           : AORangeSlider!
    @IBOutlet weak var timeLbl          : UILabel!

    var stopframe                       : StopFrame!
    weak var delegate                   : StopFrameEditVCDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        previewImgView.image = stopframe.image()
        initSlider()
    }
    
    func initSlider() {
        let handleImg = ImageProcess.image(solidColor: .yellow, size: CGSize(width: 8, height: slider.bounds.height/2))
        slider.highHandleImageNormal = handleImg
        slider.stepValue = 0.1
        slider.minimumDistance = 3.0
        slider.maximumValue = 30.0
        slider.stepValueContinuously = true
        slider.minimumValue = 0
        slider.isLowHandleHidden = true
        slider.lowValue = 0
        slider.highValue = stopframe.duration
        let size = slider.bounds.size
        let newImg = ImageProcess.resize(image: stopframe.image() ?? UIImage(), scaledToSize: size)
        slider.trackBackgroundImage = ImageProcess.blurImage(of: newImg)
        slider.trackImage = newImg
        
        slider.valuesChangedHandler = { [weak self] in
            guard let `self` = self else {
                return
            }
            self.setTimeLbl(with: self.slider.highValue)
        }
    }
    
    func setTimeLbl(with duration: Float64) {
        let duration = Int(duration)
        let times = AVPlayerService.getTimeString(from: duration).split(separator: ":")
        timeLbl.text = "\(times[1]):\(times[2])"
    }
    
    @IBAction func onSaveBtn(_ sender: UIButton) {
        stopframe.duration = slider.highValue
        delegate?.dismiss(with: stopframe)
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onExitBtn(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }

}
